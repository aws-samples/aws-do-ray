import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets
from torchvision.transforms import ToTensor
import ray.train.torch
from ray.train import CheckpointConfig
import time
import os
import tempfile
import ray.train




## SET UP DATASET AND MODEL
def get_dataset():
    return datasets.FashionMNIST(
        root="/tmp/data",
        train=True,
        download=True,
        transform=ToTensor(),
    )

class NeuralNetwork(nn.Module):
    def __init__(self):
        super().__init__()
        self.flatten = nn.Flatten()
        self.linear_relu_stack = nn.Sequential(
            nn.Linear(28 * 28, 512),
            nn.ReLU(),
            nn.Linear(512, 512),
            nn.ReLU(),
            nn.Linear(512, 10),
        )

    def forward(self, inputs):
        inputs = self.flatten(inputs)
        logits = self.linear_relu_stack(inputs)
        return logits
    

# ## DEFINE SINGLE WORKER PYTORCH TRAINING FUNCTION
# def train_func():
#     num_epochs = 3
#     batch_size = 64

#     dataset = get_dataset()
#     dataloader = DataLoader(dataset, batch_size=batch_size)

#     model = NeuralNetwork()

#     criterion = nn.CrossEntropyLoss()
#     optimizer = torch.optim.SGD(model.parameters(), lr=0.01)

#     for epoch in range(num_epochs):
#         for inputs, labels in dataloader:
#             optimizer.zero_grad()
#             pred = model(inputs)
#             loss = criterion(pred, labels)
#             loss.backward()
#             optimizer.step()
#         print(f"epoch: {epoch}, loss: {loss.item()}")
    

## DEFINE YOUR MULTI WORKER PYTORCH TRAINING FUNCTION
def train_func_distributed():
    num_epochs = 3
    batch_size = 64

    dataset = get_dataset()
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
    dataloader = ray.train.torch.prepare_data_loader(dataloader)

    model = NeuralNetwork()
    model = ray.train.torch.prepare_model(model)
    # model = torch.nn.DataParallel(model)


    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.SGD(model.parameters(), lr=0.01)

    for epoch in range(num_epochs):
        if ray.train.get_context().get_world_size() > 1:
            dataloader.sampler.set_epoch(epoch)

        for inputs, labels in dataloader:
            optimizer.zero_grad()
            pred = model(inputs)
            loss = criterion(pred, labels)
            loss.backward()
            optimizer.step()
        print(f"epoch: {epoch}, loss: {loss.item()}")

        with tempfile.TemporaryDirectory() as temp_checkpoint_dir:
            torch.save(
                model.state_dict(), os.path.join(temp_checkpoint_dir, "model.pt")
            )

            metrics = {"loss": loss.item()}  # Training/validation metrics.

            # Build a Ray Train checkpoint from a directory
            checkpoint = ray.train.Checkpoint.from_directory(temp_checkpoint_dir)

            # Ray Train will automatically save the checkpoint to persistent storage,
            # so the local `temp_checkpoint_dir` can be safely cleaned up after.
            ray.train.report(metrics=metrics, checkpoint=checkpoint)


## INSTANTIATE A TORCHTRAINER WITH 2 WORKERS, AND USE IT TO RUN THE TRAINING FUNCTION

if __name__ == "__main__":

    start_time = time.time()

    #Initialize Ray
    ray.init()

    from ray.train.torch import TorchTrainer
    from ray.train import ScalingConfig
    from ray.train import RunConfig

    # For GPU Training, set `use_gpu` to True.
    use_gpu = True

    #run_config = RunConfig(storage_path="/fsx/dt-pytorch/run_configs", name="run_test1")

    trainer = TorchTrainer(
        train_func_distributed,
        scaling_config=ScalingConfig(num_workers=1,use_gpu=use_gpu, resources_per_worker={"GPU": 1}),
        #run_config=run_config
    )
    # trainer.set_placement_strategy("SPREAD")

    # trainer.set_load_balanced()

    results = trainer.fit()
    configs = trainer.get_dataset_config()


    end_time = time.time()
    elapsed_time = end_time - start_time

    # print(f"Final Metrics: {result.metrics}")
    print(f"Training Time: {elapsed_time} seconds")
    print(f"Results: {results} ")
    print(f"Configs: {configs} ")

    

    ray.shutdown()

