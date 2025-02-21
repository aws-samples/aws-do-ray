import argparse
import datetime
import json
import logging
import math
from pathlib import Path
import time

# RAY
import ray
from ray import air
from ray.air import session
from ray.air.config import ScalingConfig
from ray.train import RunConfig, CheckpointConfig, FailureConfig
import ray.train.torch
from ray.train.torch import TorchTrainer
from ray.data import Dataset

import evaluate
import torch
from torch.nn.parallel import DistributedDataParallel as DDP

import os
import tempfile
import ray.train

from datasets import load_dataset
from datasets import load_from_disk
from torch.utils.data import DataLoader
from torchvision.transforms import (
    CenterCrop,
    Compose,
    Normalize,
    RandomHorizontalFlip,
    RandomResizedCrop,
    Resize,
    ToTensor,
)
from tqdm.auto import tqdm
from transformers import AutoConfig, AutoImageProcessor, AutoModelForImageClassification, SchedulerType, get_scheduler


### implementation - optional
# from smart_sifting.data_model.data_model_interface import SiftingBatch, SiftingBatchTransform
# from smart_sifting.data_model.list_batch import ListBatch
# from smart_sifting.sift_config.sift_configs import RelativeProbabilisticSiftConfig, LossConfig, SiftingBaseConfig


#### interface
# from smart_sifting.dataloader.sift_dataloader import SiftingDataloader
# from smart_sifting.loss.abstract_sift_loss_module import Loss


from typing import Any

logging.basicConfig(level=logging.INFO)
    




def parse_args():

    parser = argparse.ArgumentParser(description="Fine-tune a Transformers model on an image classification dataset")
    
    parser.add_argument(
        "--dataset_name",
        type=str,
        default="cifar10",
        help=(
            "The name of the Dataset (from the HuggingFace hub) to train on (could be your own, possibly private,"
            " dataset)."
        ),
    )
    # parser.add_argument("--train_dir", type=str, default=os.environ["SM_CHANNEL_TRAIN"], help="A folder containing the training data.")
    parser.add_argument("--validation_dir", type=str, default=None, help="A folder containing the validation data.")
    parser.add_argument(
        "--max_train_samples",
        type=int,
        default=None,
        help=(
            "For debugging purposes or quicker training, truncate the number of training examples to this "
            "value if set."
        ),
    )
    parser.add_argument(
        "--max_eval_samples",
        type=int,
        default=None,
        help=(
            "For debugging purposes or quicker training, truncate the number of evaluation examples to this "
            "value if set."
        ),
    )
    parser.add_argument(
        "--train_val_split",
        type=float,
        default=0.15,
        help="Percent to split off of train for validation",
    )
    parser.add_argument(
        "--model_name_or_path",
        type=str,
        help="Path to pretrained model or model identifier from huggingface.co/models.",
        default="google/vit-base-patch16-224-in21k",
    )
    parser.add_argument(
        "--per_device_train_batch_size",
        type=int,
        default=64,
        help="Batch size (per device) for the training dataloader.",
    )
    parser.add_argument(
        "--per_device_eval_batch_size",
        type=int,
        default=64,
        help="Batch size (per device) for the evaluation dataloader.",
    )
    parser.add_argument(
        "--learning_rate",
        type=float,
        default=5e-5,
        help="Initial learning rate (after the potential warmup period) to use.",
    )
    parser.add_argument("--weight_decay", type=float, default=0.0, help="Weight decay to use.")
    parser.add_argument("--num_train_epochs", type=int, default=3, help="Total number of training epochs to perform.")
    parser.add_argument(
        "--max_train_steps",
        type=int,
        default=None,
        help="Total number of training steps to perform. If provided, overrides num_train_epochs.",
    )
    parser.add_argument(
        "--gradient_accumulation_steps",
        type=int,
        default=1,
        help="Number of updates steps to accumulate before performing a backward/update pass.",
    )
    parser.add_argument(
        "--lr_scheduler_type",
        type=SchedulerType,
        default="linear",
        help="The scheduler type to use.",
        choices=["linear", "cosine", "cosine_with_restarts", "polynomial", "constant", "constant_with_warmup"],
    )
    parser.add_argument(
        "--num_warmup_steps", type=int, default=0, help="Number of steps for the warmup in the lr scheduler."
    )
    parser.add_argument("--output_dir", type=str, default="/fsx/models/test4", help="Where to store the final model.")
    parser.add_argument("--seed", type=int, default=None, help="A seed for reproducible training.")

    parser.add_argument(
        "--checkpointing_steps",
        type=str,
        default=None,
        help="Whether the various states should be saved at the end of every n steps, or 'epoch' for each epoch.",
    )
    parser.add_argument(
        "--resume_from_checkpoint",
        type=str,
        default=None,
        help="If the training should continue from a checkpoint folder.",
    )

    parser.add_argument(
        "--ignore_mismatched_sizes",
        action="store_false",
        help="Whether or not to enable to load a pretrained model whose head dimensions are different.",
    )

    parser.add_argument(
        "--num_workers",
        type=int,
        default=2,
        help="Number of Ray workers you want to have working"
    )

    parser.add_argument(
        "--num_gpu_per_worker",
        type=int,
        default=4,
        help="Number of GPUs you want each worker to have"
    )

    args, unknown = parser.parse_known_args()
    # Sanity checks
    if args.dataset_name is None and args.train_dir is None and args.validation_dir is None:
        raise ValueError("Need either a dataset name or a training/validation folder.")
    
    return args







def train_loop_per_worker(config):
    args = parse_args()



    # If passed along, set the training seed now.
    if args.seed is not None:
        torch.manual_seed(args.seed)


    # dataset = load_from_disk(args.train_dir)
    dataset = load_dataset(args.dataset_name)




    # If we don't have a validation split, split off a percentage of train as validation.
    # and if dataset has dataset.keys()
    args.train_val_split = None if "validation" in dataset.keys() else args.train_val_split
    if isinstance(args.train_val_split, float) and args.train_val_split > 0.0:
        split = dataset["train"].train_test_split(args.train_val_split)
        dataset["train"] = split["train"]
        dataset["validation"] = split["test"]


    # Prepare label mappings.
    # We'll include these in the model's config to get human readable labels in the Inference API.
    labels = dataset["train"].features["label"].names
    label2id = {label: str(i) for i, label in enumerate(labels)}
    id2label = {str(i): label for i, label in enumerate(labels)}

    # Load pretrained model and image processor
    #
    # In distributed training, the .from_pretrained methods guarantee that only one local process can concurrently
    # download model & vocab.
    config = AutoConfig.from_pretrained(
        args.model_name_or_path,
        num_labels=len(labels),
        id2label=id2label,
        label2id=label2id,
        finetuning_task="image-classification",
    )
    
    image_processor = AutoImageProcessor.from_pretrained(args.model_name_or_path)
    model = AutoModelForImageClassification.from_pretrained(
        args.model_name_or_path,
        from_tf=bool(".ckpt" in args.model_name_or_path),
        config=config,
        ignore_mismatched_sizes=args.ignore_mismatched_sizes,
    )
    # model = ray.train.torch.prepare_model(model, parallel_strategy='ddp')
    model = ray.train.torch.prepare_model(model, parallel_strategy='ddp')

    # print(model.device)

    # Preprocessing the datasets

    # Define torchvision transforms to be applied to each image.
    if "shortest_edge" in image_processor.size:
        size = image_processor.size["shortest_edge"]
    else:
        size = (image_processor.size["height"], image_processor.size["width"])
    normalize = Normalize(mean=image_processor.image_mean, std=image_processor.image_std)
    train_transforms = Compose(
        [
            RandomResizedCrop(size),
            RandomHorizontalFlip(),
            ToTensor(),
            normalize,
        ]
    )
    val_transforms = Compose(
        [
            Resize(size),
            CenterCrop(size),
            ToTensor(),
            normalize,
        ]
    )

    def preprocess_train(example_batch):
        """Apply _train_transforms across a batch."""
        example_batch["pixel_values"] = [train_transforms(image.convert("RGB")) for image in example_batch["img"]]
        return example_batch

    def preprocess_val(example_batch):
        """Apply _val_transforms across a batch."""
        example_batch["pixel_values"] = [val_transforms(image.convert("RGB")) for image in example_batch["img"]]
        return example_batch

    #with accelerator.main_process_first():
    if args.max_train_samples is not None:
        dataset["train"] = dataset["train"].shuffle(seed=args.seed).select(range(args.max_train_samples))
    # Set the training transforms
    train_dataset = dataset["train"].with_transform(preprocess_train)
    if args.max_eval_samples is not None:
        dataset["validation"] = dataset["validation"].shuffle(seed=args.seed).select(range(args.max_eval_samples))
    # Set the validation transforms
    eval_dataset = dataset["validation"].with_transform(preprocess_val)

    # DataLoaders creation:
    def collate_fn(examples):
        pixel_values = torch.stack([example["pixel_values"] for example in examples])
        labels = torch.tensor([example["label"] for example in examples])
        return {"pixel_values": pixel_values, "labels": labels}

    train_dataloader = DataLoader(
        train_dataset,
        shuffle=True,
        collate_fn=collate_fn,
        batch_size=args.per_device_train_batch_size,
        num_workers=48
        # num_workers=args.num_workers
    )
    train_dataloader = ray.train.torch.prepare_data_loader(train_dataloader)


    num_update_steps_per_epoch = math.ceil(len(train_dataloader) / args.gradient_accumulation_steps)
    num_training_steps = args.num_train_epochs * len(train_dataloader)   
       
    eval_dataloader = DataLoader(
        eval_dataset,
        collate_fn=collate_fn,
        batch_size=args.per_device_eval_batch_size,
        shuffle=True,
        num_workers=48
        # num_workers=args.num_workers
    )
    eval_dataloader = ray.train.torch.prepare_data_loader(eval_dataloader)

    global_batch_size = args.per_device_train_batch_size * ray.train.get_context().get_world_size()


    # Optimizer
    # Split weights in two groups, one with weight decay and the other not.
    no_decay = ["bias", "LayerNorm.weight"]
    optimizer_grouped_parameters = [
        {
            "params": [p for n, p in model.named_parameters() if not any(nd in n for nd in no_decay)],
            "weight_decay": args.weight_decay,
        },
        {
            "params": [p for n, p in model.named_parameters() if any(nd in n for nd in no_decay)],
            "weight_decay": 0.0,
        },
    ]
    optimizer = torch.optim.AdamW(optimizer_grouped_parameters, lr=args.learning_rate)

    # Scheduler and math around the number of training steps.
    overrode_max_train_steps = False
    
    if args.max_train_steps is None:
        args.max_train_steps = args.num_train_epochs * num_update_steps_per_epoch
        overrode_max_train_steps = True

    lr_scheduler = get_scheduler(
        name=args.lr_scheduler_type,
        optimizer=optimizer,
        num_warmup_steps=args.num_warmup_steps * args.gradient_accumulation_steps,
        num_training_steps=num_training_steps * args.gradient_accumulation_steps,
    )

    # We need to recalculate our total training steps as the size of the training dataloader may have changed.
    #num_update_steps_per_epoch = math.ceil(len(train_dataloader) / args.gradient_accumulation_steps)
    if overrode_max_train_steps:
        args.max_train_steps = args.num_train_epochs * num_update_steps_per_epoch
    # Afterwards we recalculate our number of training epochs
    #args.num_train_epochs = math.ceil(args.max_train_steps / num_update_steps_per_epoch)

    # Figure out how many steps we should save the Accelerator states
    checkpointing_steps = args.checkpointing_steps
    if checkpointing_steps is not None and checkpointing_steps.isdigit():
        checkpointing_steps = int(checkpointing_steps)

    # Get the metric function
    metric = evaluate.load("accuracy")
    clf_metrics = evaluate.combine([
        evaluate.load("accuracy",average="weighted"),
        evaluate.load("f1",average="weighted"),
        evaluate.load("precision", average="weighted"),
        evaluate.load("recall", average="weighted")
        ])
    
    # Train!
    # total_batch_size = args.per_device_train_batch_size * args.gradient_accumulation_steps
    

    print("***** Running training *****")
    print(f"  Num examples = {len(train_dataset)}")
    print(f"  Num Epochs = {args.num_train_epochs}")
    print(f"  Instantaneous batch size per device = {args.per_device_train_batch_size}")
    print(f"  Total train batch size (w. parallel, distributed & accumulation) = {global_batch_size}")
    print(f"  Gradient Accumulation steps = {args.gradient_accumulation_steps}")
    print(f"  Total optimization steps = {args.max_train_steps}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"Number of CUDA devices: {torch.cuda.device_count()}")

    for i in range(torch.cuda.device_count()):
        print(f"Device {i}: {torch.cuda.get_device_name(i)}")

    # Only show the progress bar once on each machine.
    progress_bar = tqdm(range(num_training_steps))
    completed_steps = 0
    starting_epoch = 0

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # model = model.to(device)
    
    train_step_count = 0

    for epoch in range(starting_epoch, args.num_train_epochs):
        if ray.train.get_context().get_world_size() > 1:
            train_dataloader.sampler.set_epoch(epoch)
            eval_dataloader.sampler.set_epoch(epoch)

        model.train()

        total_loss = 0
        for  batch in train_dataloader:
            train_start = time.perf_counter()

            batch = {k: v.to(device) for k, v, in batch.items()}
            outputs = model(**batch)
            loss = outputs.loss
                # We keep track of the loss at each epoch

            # print((f'batch: {(list(batch)[0]).device}'))

            total_loss += loss.detach().float()
            train_bp_start = time.perf_counter()
            print((f'train forward pass latency: {train_bp_start - train_start}'))
            loss.backward()
            print(f'train backprop latency: {time.perf_counter() - train_bp_start}')
            train_optim_start = time.perf_counter()
            optimizer.step() #gather gradient updates from all cores and apply them
            lr_scheduler.step()
            optimizer.zero_grad()
            print(f'train optimizer step latency: {time.perf_counter() - train_optim_start}')
            print(f'train total step latency: {time.perf_counter() - train_start}')
            train_step_count += 1
            print(f'train step count: {train_step_count}')

            progress_bar.update(1)
            completed_steps += 1


            if completed_steps >= args.max_train_steps:
                break
        print(
            "Epoch {}, Loss {:0.4f}".format(epoch, loss.detach().to("cpu"))
            )       
        model.eval()
        for step, batch in enumerate(eval_dataloader):
            with torch.no_grad():
                batch = {k: v.to(device) for k, v, in batch.items()}
                outputs = model(**batch)
                loss = outputs.loss
            predictions = outputs.logits.argmax(dim=-1)
            references = batch["labels"]
            metric.add_batch(
                predictions=predictions,
                references=references,
            )

        eval_metric = metric.compute()
        print(f"epoch {epoch}: {eval_metric}")
        print(f"epoch {epoch}: eval loss {loss}")

        metrics = {"loss": loss.item(), "accuracy": eval_metric['accuracy']}  # Training/validation metrics.


        with tempfile.TemporaryDirectory() as temp_checkpoint_dir:

            checkpoint = None

            if ray.train.get_context().get_world_rank() == 0:

                # # Save the configuration
                # config.save_pretrained(temp_checkpoint_dir)

                # Save the model weights
                # torch.save(
                #     model.state_dict(), os.path.join(temp_checkpoint_dir, "pytorch_model.bin")
                # )

                model.module.save_pretrained(temp_checkpoint_dir)

                # save configuration file
                # config.save_pretrained(temp_checkpoint_dir)

                # Build a Ray Train checkpoint from a directory
                checkpoint = ray.train.Checkpoint.from_directory(temp_checkpoint_dir)

                # Ray Train will automatically save the checkpoint to persistent storage,
                # so the local `temp_checkpoint_dir` can be safely cleaned up after.
            ray.train.report(metrics=metrics, checkpoint=checkpoint)





    # if args.output_dir is not None:  
    #     # os.chmod(args.output_dir, 0o777)  # Ensure the directory has write permissions for all users
    #     image_processor.save_pretrained(args.output_dir)
    #     # model.module.save_pretrained(args.output_dir)
    #     torch.save(model.state_dict(), os.path.join(args.output_dir, "pytorch_model.bin"))
    #     config.save_pretrained(args.output_dir)
    #     all_results = {f"eval_{k}": v for k, v in eval_metric.items()}
    #     with open(os.path.join(args.output_dir, "all_results.json"), "w") as f:
    #         json.dump(all_results, f)


    




def main():
    args = parse_args()

    start_time = time.time()

    #initialize Ray
    ray.init()

    experiment_path = "/fsx/checkpoints/train-images-ray/"

    # run_config = RunConfig(storage_path="s3://eks-ray-bucket/run_configs", name="train_images-ray")
    run_config = RunConfig(
        failure_config=FailureConfig(max_failures=-1),
        checkpoint_config=CheckpointConfig(
            num_to_keep=1,
            checkpoint_score_attribute="mean_accuracy",
            checkpoint_score_order="max",
    ),
        storage_path=experiment_path
    )


    
    if TorchTrainer.can_restore(experiment_path):
        print("Restoring trainer from previous checkpoint")
        trainer = TorchTrainer.restore(experiment_path, run_config=run_config)
    else: 
        print("No checkpoint found. Starting new training session...")
        trainer = TorchTrainer(
            train_loop_per_worker=train_loop_per_worker,
            # train_loop_config=args.__dict__,
            train_loop_config={"lr": 1e-3, "batch_size": args.per_device_train_batch_size, "epochs": args.num_train_epochs},
            scaling_config=ScalingConfig(num_workers=args.num_workers, use_gpu=True, resources_per_worker={"GPU": 1}),
            run_config=run_config
    )

    results = trainer.fit()

    end_time = time.time()
    elapsed_time = end_time - start_time

    # print(f"Final Metrics: {result.metrics}")
    print(f"Training Time: {elapsed_time} seconds")
    print(f"Results: {results} ")




    ray.shutdown()



if __name__ == "__main__":
    main()


















# import argparse
# import datetime
# import json
# import logging
# import math
# from pathlib import Path
# import time

# # RAY
# import ray
# from ray import air
# from ray.air import session
# from ray.air.config import ScalingConfig
# from ray.train import RunConfig, CheckpointConfig, FailureConfig
# import ray.train.torch
# from ray.train.torch import TorchTrainer
# from ray.data import Dataset

# import evaluate
# import torch
# from torch.nn.parallel import DistributedDataParallel as DDP

# import os
# import tempfile
# import ray.train

# from datasets import load_dataset
# from datasets import load_from_disk
# from torch.utils.data import DataLoader
# from torchvision.transforms import (
#     CenterCrop,
#     Compose,
#     Normalize,
#     RandomHorizontalFlip,
#     RandomResizedCrop,
#     Resize,
#     ToTensor,
# )
# from tqdm.auto import tqdm
# from transformers import AutoConfig, AutoImageProcessor, AutoModelForImageClassification, SchedulerType, get_scheduler

# from typing import Any

# logging.basicConfig(level=logging.INFO)

# def parse_args():
#     parser = argparse.ArgumentParser(description="Fine-tune a Transformers model on an image classification dataset")
#     parser.add_argument("--dataset_name", type=str, default="cifar10")
#     parser.add_argument("--validation_dir", type=str, default=None)
#     parser.add_argument("--max_train_samples", type=int, default=None)
#     parser.add_argument("--max_eval_samples", type=int, default=None)
#     parser.add_argument("--train_val_split", type=float, default=0.15)
#     parser.add_argument("--model_name_or_path", type=str, default="google/vit-base-patch16-224-in21k")
#     parser.add_argument("--per_device_train_batch_size", type=int, default=64)
#     parser.add_argument("--per_device_eval_batch_size", type=int, default=64)
#     parser.add_argument("--learning_rate", type=float, default=5e-5)
#     parser.add_argument("--weight_decay", type=float, default=0.0)
#     parser.add_argument("--num_train_epochs", type=int, default=3)
#     parser.add_argument("--max_train_steps", type=int, default=None)
#     parser.add_argument("--gradient_accumulation_steps", type=int, default=1)
#     parser.add_argument("--lr_scheduler_type", type=SchedulerType, default="linear")
#     parser.add_argument("--num_warmup_steps", type=int, default=0)
#     parser.add_argument("--output_dir", type=str, default="/fsx/models/test4")
#     parser.add_argument("--seed", type=int, default=None)
#     parser.add_argument("--checkpointing_steps", type=str, default=None)
#     parser.add_argument("--resume_from_checkpoint", type=str, default=None)
#     parser.add_argument("--ignore_mismatched_sizes", action="store_false")
#     parser.add_argument("--num_workers", type=int, default=2)
#     parser.add_argument("--num_gpu_per_worker", type=int, default=4)
#     return parser.parse_args()

# def train_loop_per_worker(config):
#     args = parse_args()
#     if args.seed is not None:
#         torch.manual_seed(args.seed)
#     dataset = load_dataset(args.dataset_name)
    
#     labels = dataset["train"].features["label"].names
#     label2id = {label: str(i) for i, label in enumerate(labels)}
#     id2label = {str(i): label for i, label in enumerate(labels)}
    
#     config = AutoConfig.from_pretrained(args.model_name_or_path, num_labels=len(labels), id2label=id2label, label2id=label2id)
#     image_processor = AutoImageProcessor.from_pretrained(args.model_name_or_path)
#     model = AutoModelForImageClassification.from_pretrained(args.model_name_or_path, config=config, ignore_mismatched_sizes=args.ignore_mismatched_sizes)
#     model = ray.train.torch.prepare_model(model, parallel_strategy='ddp')
    
#     def collate_fn(examples):
#         pixel_values = torch.stack([example["pixel_values"] for example in examples])
#         labels = torch.tensor([example["label"] for example in examples])
#         return {"pixel_values": pixel_values, "labels": labels}
    
#     train_dataloader = DataLoader(dataset["train"], batch_size=args.per_device_train_batch_size, collate_fn=collate_fn, num_workers=args.num_workers)
#     train_dataloader = ray.train.torch.prepare_data_loader(train_dataloader)
    
#     optimizer = torch.optim.AdamW(model.parameters(), lr=args.learning_rate)
#     num_training_steps = args.num_train_epochs * len(train_dataloader)
#     lr_scheduler = get_scheduler(name=args.lr_scheduler_type, optimizer=optimizer, num_warmup_steps=args.num_warmup_steps, num_training_steps=num_training_steps)
    
#     progress_bar = tqdm(range(num_training_steps))
#     for epoch in range(args.num_train_epochs):
#         model.train()
#         for batch in train_dataloader:
#             outputs = model(**batch)
#             loss = outputs.loss
#             loss.backward()
#             optimizer.step()
#             lr_scheduler.step()
#             optimizer.zero_grad()
#             progress_bar.update(1)
        
#         with tempfile.TemporaryDirectory() as temp_checkpoint_dir:
#             checkpoint = None
#             if ray.train.get_context().get_world_rank() == 0:
#                 model.module.save_pretrained(temp_checkpoint_dir)
#                 checkpoint = ray.train.Checkpoint.from_directory(temp_checkpoint_dir)
#             ray.train.report(metrics={"loss": loss.item()}, checkpoint=checkpoint)

# def main():
#     args = parse_args()
#     ray.init()
#     experiment_path = "/fsx/checkpoints/train-images-ray/"
#     run_config = RunConfig(
#         failure_config=FailureConfig(max_failures=-1),
#         checkpoint_config=CheckpointConfig(num_to_keep=1, checkpoint_score_attribute="mean_accuracy", checkpoint_score_order="max"),
#         storage_path=experiment_path
#     )
    
#     if TorchTrainer.can_restore(experiment_path):
#         print("Restoring trainer from previous checkpoint")
#         trainer = TorchTrainer.restore(experiment_path, run_config=run_config)
#     else:
#         print("No checkpoint found. Starting new training session...")
#         trainer = TorchTrainer(
#             train_loop_per_worker=train_loop_per_worker,
#             train_loop_config={"lr": 1e-3, "batch_size": args.per_device_train_batch_size, "epochs": args.num_train_epochs},
#             scaling_config=ScalingConfig(num_workers=args.num_workers, use_gpu=True, resources_per_worker={"GPU": 1}),
#             run_config=run_config
#         )
#     results = trainer.fit()
#     print(f"Training Time: {time.time() - start_time} seconds")
#     print(f"Results: {results}")
#     ray.shutdown()

# if __name__ == "__main__":
#     main()
