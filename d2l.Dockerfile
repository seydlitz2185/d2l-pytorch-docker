# Use the official Ubuntu base image
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies

RUN <<EOT
    sed -i 's#http://archive.ubuntu.com/#http://mirrors.tuna.tsinghua.edu.cn/#' /etc/apt/sources.list 
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list 
    apt-get update 
    apt-get install -y \
    git wget bzip2 ca-certificates curl
    rm -rf /var/lib/apt/lists/*

EOT
# Download and install Miniforge
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O Miniforge3.sh \
    && bash Miniforge3.sh -b -p /opt/conda \
    && rm Miniforge3.sh

# Set up the environment
ENV PATH /opt/conda/bin:$PATH

# Create a non-root user
RUN useradd -m -s /bin/bash user
USER user
WORKDIR /home/user

# Initialize conda
RUN conda init bash

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# Install some basic packages
RUN conda install -y numpy pandas matplotlib

# Clean up
RUN conda clean -a -y

#install poetry
RUN curl -sSL https://install.python-poetry.org | python3 - --version 1.8.4

#add poetry to PATH
ENV PATH="${PATH}:/home/user/.local/bin"

#clone d2l-pytorch-docker repo
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN \
git clone https://github.com/seydlitz2185/d2l-pytorch-docker.git 

VOLUME [ "/data" ]

VOLUME [ "/poetry" ]

WORKDIR /root

# Set the entrypoint
ENTRYPOINT ["/bin/bash"]