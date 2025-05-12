#FROM rayproject/ray:2.42.1-py310-gpu
FROM anyscale/ray:2.44.1-slim-py311-cu128

# Install Python dependencies for PyTorch, Ray, Hugging Face, and more
RUN pip install --no-cache-dir \
    torch torchvision torchaudio \
    numpy \
    pytorch-lightning \
    transformers datasets evaluate tqdm click \
    ray[train] ray[air] \
    ray[train-torch] ray[train-lightning] \
    torchdata \
    torchmetrics \
    torch_optimizer \
    accelerate \
    scikit-learn \
    Pillow==9.5.0 \
    protobuf==3.20.3

RUN pip install --upgrade datasets transformers



# Set the user
#USER ray
WORKDIR /home/ray

# Verify ray installation
RUN which ray && \
    ray --version

# Default command
#CMD [ "/bin/bash" ]



