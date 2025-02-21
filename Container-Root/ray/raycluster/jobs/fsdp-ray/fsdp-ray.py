import ray

# Initialize Ray with runtime environment
ray.init(
    runtime_env={
        "pip": [
            "datasets",
            "evaluate",
            "transformers>=4.26.0",
            "torch>=1.12.0",
            "pytorch_lightning>=2.1.0",
        ]
    }
)


import torch
import numpy as np
import pytorch_lightning as pl
import torch.nn.functional as F
from torch.utils.data import DataLoader, random_split
from transformers import AutoTokenizer, AutoModelForSequenceClassification
# from datasets import load_dataset, load_metric
from datasets import load_dataset
from evaluate import load as load_metric
import ray.train
from ray.train.lightning import (
    prepare_trainer,
    RayFSDPStrategy,
    RayLightningEnvironment,
    RayTrainReportCallback,
)
from ray.train.torch import TorchTrainer
from ray.train import RunConfig, ScalingConfig, CheckpointConfig, DataConfig
tokenizer = AutoTokenizer.from_pretrained("bert-base-cased")



# Tokenize
def tokenize_sentence(batch):
    outputs = tokenizer(
        batch["sentence"].tolist(),
        max_length=128,
        truncation=True,
        padding="max_length",
        return_tensors="np",
    )
    outputs["label"] = batch["label"]
    return outputs


# Define Model
class SentimentModel(pl.LightningModule):
    def __init__(self, lr=2e-5, eps=1e-8):
        super().__init__()
        self.lr = lr
        self.eps = eps
        self.num_classes = 2
        self.model = AutoModelForSequenceClassification.from_pretrained(
            "bert-base-cased", num_labels=self.num_classes
        )
        self.metric = load_metric("glue", "cola")
        self.predictions = []
        self.references = []

    def forward(self, batch):
        input_ids, attention_mask = batch["input_ids"], batch["attention_mask"]
        outputs = self.model(input_ids, attention_mask=attention_mask)
        logits = outputs.logits
        return logits

    def training_step(self, batch, batch_idx):
        labels = batch["label"]
        logits = self.forward(batch)
        loss = F.cross_entropy(logits.view(-1, self.num_classes), labels)
        self.log("train_loss", loss)
        return loss

    def validation_step(self, batch, batch_idx):
        labels = batch["label"]
        logits = self.forward(batch)
        preds = torch.argmax(logits, dim=1)
        self.predictions.append(preds)
        self.references.append(labels)

    def on_validation_epoch_end(self):
        predictions = torch.concat(self.predictions).view(-1)
        references = torch.concat(self.references).view(-1)
        matthews_correlation = self.metric.compute(
            predictions=predictions, references=references
        )

        # self.metric.compute() returns a dictionary:
        # e.g. {"matthews_correlation": 0.53}
        self.log_dict(matthews_correlation, sync_dist=True)
        self.predictions.clear()
        self.references.clear()

    def configure_optimizers(self):
        return torch.optim.AdamW(self.parameters(), lr=self.lr, eps=self.eps)


# Train Function
def train_func(config):
    # Unpack the input configs passed from `TorchTrainer(train_loop_config)`
    lr = config["lr"]
    eps = config["eps"]
    batch_size = config["batch_size"]
    max_epochs = config["max_epochs"]

    # Fetch the Dataset shards
    train_ds = ray.train.get_dataset_shard("train")
    val_ds = ray.train.get_dataset_shard("validation")

    # Create a dataloader for Ray Datasets
    train_ds_loader = train_ds.iter_torch_batches(batch_size=batch_size)
    val_ds_loader = val_ds.iter_torch_batches(batch_size=batch_size)

    # Model
    model = SentimentModel(lr=lr, eps=eps)

    trainer = pl.Trainer(
        max_epochs=max_epochs,
        accelerator="auto",
        devices="auto",
        strategy=RayFSDPStrategy(),
        plugins=[RayLightningEnvironment()],
        callbacks=[RayTrainReportCallback()],
        enable_progress_bar=False,
    )

    trainer = prepare_trainer(trainer)

    trainer.fit(model, train_dataloaders=train_ds_loader, val_dataloaders=val_ds_loader)


# Main function
def main():

    # Load Dataset
    dataset = load_dataset("glue", "cola")
    train_dataset = ray.data.from_huggingface(dataset["train"])
    validation_dataset = ray.data.from_huggingface(dataset["validation"])

    # Tokenize
    train_dataset = train_dataset.map_batches(tokenize_sentence, batch_format="numpy")
    validation_dataset = validation_dataset.map_batches(tokenize_sentence, batch_format="numpy")

    # Train Config
    train_func_config = {
    "lr": 1e-5,
    "eps": 1e-8,
    "batch_size": 16,
    "max_epochs": 5,
    }

    # Save the top-2 checkpoints according to the evaluation metric
    # The checkpoints and metrics are reported by `RayTrainReportCallback`
    run_config = RunConfig(
        name="ptl-sent-classification",
        storage_path="/fsx/fsdp",  # Replace with your bucket
        checkpoint_config=CheckpointConfig(
            num_to_keep=2,
            checkpoint_score_attribute="matthews_correlation",
            checkpoint_score_order="max",
        ),
    )

    # Schedule four workers for FSDP training (1 GPU/worker by default)
    scaling_config = ScalingConfig(num_workers=2, use_gpu=True)

    trainer = TorchTrainer(
        train_loop_per_worker=train_func,
        train_loop_config=train_func_config,
        scaling_config=scaling_config,
        run_config=run_config,
        datasets={"train": train_dataset, "validation": validation_dataset}, # <- Feed the Ray Datasets here
    )

    result = trainer.fit()

if __name__ == "__main__":
    main()