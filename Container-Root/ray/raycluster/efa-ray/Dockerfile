FROM public.ecr.aws/hpc-cloud/nccl-tests:latest

# Create ray user and home directory
RUN useradd -m -d /home/ray ray && \
    chown -R ray:ray /home/ray

COPY --from=rayproject/ray:2.42.1-py310-gpu /home/ray/requirements_compiled.txt /tmp/

# Install anaconda if it's not in base image
RUN if [ ! -d "/opt/anaconda3" ]; then \
    wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O /tmp/anaconda.sh && \
    bash /tmp/anaconda.sh -b -p /opt/anaconda3 && \
    rm /tmp/anaconda.sh; \
    fi

# Add anaconda to system-wide PATH
ENV PATH=/opt/anaconda3/bin:$PATH

# Install Ray and dependencies
RUN pip --no-cache-dir install -c /tmp/requirements_compiled.txt \
    "ray[all]==2.42.1"


# Install Python dependencies for PyTorch, Ray, Hugging Face, and more
RUN pip install --no-cache-dir \
    torch==2.7.0 \
    torchvision==0.22.0 \
    torchaudio==2.7.0 \
    numpy==1.26.4 \
    pytorch-lightning==2.6.0 \
    transformers==4.53.3 \
    datasets==4.0.0 \
    evaluate==0.4.6 \
    click==8.1.7 \
    ray[train] \
    ray[air] \
    ray[train-torch] \
    ray[train-lightning] \
    torchdata==0.11.0 \
    torchmetrics==1.8.2 \
    torch_optimizer==0.3.0 \
    accelerate==1.12.0 \
    scikit-learn==1.8.0 \
    Pillow==12.1.0 \
    protobuf==3.20.3

RUN pip install --upgrade datasets transformers

# Save pip freeze output
RUN pip freeze > /home/ray/pip-freeze.txt && \
    chown ray:ray /home/ray/pip-freeze.txt

# Cleanup
RUN rm -rf /tmp/requirements_compiled.txt

# Set the user
USER ray
WORKDIR /home/ray

# Verify ray installation
RUN which ray && \
    ray --version

# Default command
CMD [ "/bin/bash" ]

