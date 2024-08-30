FROM kubeflow/pytorch-elastic-example-imagenet:latest

RUN pip install evaluate transformers python-etcd torch torchvision

COPY train_images.py /workspace/train_images.py

WORKDIR /workspace





