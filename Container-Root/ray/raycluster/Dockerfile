FROM rayproject/ray:2.42.1-py310-gpu


# Install Python dependencies for PyTorch, Ray, Hugging Face, and more

RUN pip install --no-cache-dir \
    torch==2.6.0 \
    torchvision==0.21.0 \
    torchaudio==2.6.0 \
    numpy==1.26.4 \
    pytorch-lightning==2.5.0.post0 \
    transformers==4.49.0 \
    datasets==3.3.2 \
    evaluate==0.4.3 \
    tqdm==4.66.1 \
    click==8.1.7 \
    ray==2.42.1 \
    torchdata==0.11.0 \
    torchmetrics==1.6.2 \
    torch-optimizer==0.3.0 \
    accelerate==1.4.0 \
    scikit-learn==1.6.1 \
    Pillow==9.5.0 \
    protobuf==3.20.3 \
    pandas==1.5.3 \
    fsspec==2023.5.0 \
    PyYAML==6.0.1 \
    tensorboardX==2.6.2.2

# Additional libraries that might be required
RUN pip install --no-cache-dir \
    aiohttp==3.9.5 \
    boto3==1.26.76 \
    cloudpickle==2.2.0 \
    fastapi==0.109.2 \
    grpcio==1.66.2 \
    huggingface-hub==0.29.1 \
    psutil==5.9.6 \
    pyarrow==19.0.1 \
    redis==4.4.2 \
    uvicorn==0.22.0



# Set the user
USER ray
WORKDIR /home/ray

# Verify ray installation
RUN which ray && \
    ray --version

# Default command
CMD [ "/bin/bash" ]
