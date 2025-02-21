# File name: Dockerfile
FROM rayproject/ray:2.9.0-gpu

USER root

# Ensure non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Enable additional repositories BEFORE installing dependencies
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && add-apt-repository multiverse \
    && apt-get update --fix-missing

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    make \
    git \
    build-essential \
    autoconf \
    libtool \
    pciutils \
    environment-modules \
    tcl \
    libnl-3-200 \
    libnl-3-dev \
    libnl-route-3-200 \
    libnl-route-3-dev \
    udev \
    dmidecode \
    ethtool \
    iproute2 \
    libhwloc15 \
    libevent-core-2.1-7 \
    libevent-pthreads-2.1-7 \
    --fix-missing \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure CUDA paths are properly set
ENV CUDA_HOME=/usr/local/cuda
ENV PATH="${CUDA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"

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


### **EFA and MPI SETUP** ###
ARG OPEN_MPI_PATH=/opt/amazon/openmpi/
ENV NCCL_VERSION=2.7.8
ENV EFA_VERSION=1.30.0
ENV BRANCH_OFI=1.1.1
ENV TORCH_NCCL_ASYNC_ERROR_HANDLING=1

RUN cd $HOME \
  && curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/aws-efa-installer-${EFA_VERSION}.tar.gz \
  && tar -xf aws-efa-installer-${EFA_VERSION}.tar.gz \
  && cd aws-efa-installer \
  && ./efa_installer.sh -y --skip-kmod -g 

# Set MPI and NCCL paths
ENV PATH="$OPEN_MPI_PATH/bin:$PATH"
ENV LD_LIBRARY_PATH="$OPEN_MPI_PATH/lib:$LD_LIBRARY_PATH"

### **NCCL, OFI, and NCCL-TEST SETUP** ###
RUN cd $HOME \
  && git clone https://github.com/NVIDIA/nccl.git -b v${NCCL_VERSION}-1 \
  && cd nccl \
  && make -j64 src.build BUILDDIR=/usr/local

RUN apt-get update && apt-get install -y autoconf

RUN cd $HOME \
  && git clone https://github.com/aws/aws-ofi-nccl.git -b v${BRANCH_OFI} \
  && cd aws-ofi-nccl \
  && ./autogen.sh \
  && ./configure --with-libfabric=/opt/amazon/efa \
       --with-mpi=/opt/amazon/openmpi \
       --with-cuda=/usr/local/cuda \
       --with-nccl=/usr/local --prefix=/usr/local \
  && make && make install

# Install NCCL test suite
RUN cd $HOME \
  && git clone https://github.com/NVIDIA/nccl-tests \
  && cd nccl-tests \
  && make MPI=1 MPI_HOME=/opt/amazon/openmpi CUDA_HOME=/usr/local/cuda NCCL_HOME=/usr/local

# Switch back to ray user for security
USER ray

