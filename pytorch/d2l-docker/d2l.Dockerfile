ARG MINIFORGE_VERSION=24.11.3-0
ARG INSTALL_DIR=/opt/conda

# 第一阶段：使用国内镜像下载安装脚本
FROM --platform=$BUILDPLATFORM alpine:3.18 AS downloader

ARG MINIFORGE_VERSION
ARG TARGETARCH

# 国内镜像源配置（可选项）
ENV INSTALLER_MIRROR="https://mirror.nju.edu.cn/github-release/conda-forge/miniforge/LatestRelease"
# 可选镜像：
# 清华大学镜像站：https://mirrors.tuna.tsinghua.edu.cn/github-release/conda-forge/miniforge
# 中科大镜像站：https://mirrors.ustc.edu.cn/github-release/conda-forge/miniforge


RUN <<EOF
  # 架构映射
  case "${TARGETARCH}" in
    "amd64") target_arch="x86_64" ;;
    "arm64") target_arch="aarch64" ;;
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;;
  esac

  # 构造下载URL
  download_url="${INSTALLER_MIRROR}/Miniforge3-${MINIFORGE_VERSION}-Linux-${target_arch}.sh"
  
  # 下载并校验
  wget -q -O /Miniforge3.sh "${download_url}"
  sha256sum /Miniforge3.sh > /Miniforge3.sha256
EOF

FROM ubuntu:20.04

WORKDIR  /root
ARG INSTALL_DIR

RUN <<EOT
    sed -i 's#http://archive.ubuntu.com/#http://mirrors.tuna.tsinghua.edu.cn/#' /etc/apt/sources.list 
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list 
    apt-get update 
    apt-get install -y \
    git wget bzip2 ca-certificates curl
    rm -rf /var/lib/apt/lists/*

EOT
# Install Miniforge
# 复制安装文件
COPY --from=downloader /Miniforge3.sh /Miniforge3.sha256 /tmp/

# 安装 Miniforge 并配置镜像源
RUN <<EOF
  # 安装 Miniforge
  bash /tmp/Miniforge3.sh -b -p ${INSTALL_DIR} && \
  rm -f /tmp/Miniforge3*

  # 配置 conda 镜像源（清华源）
  mkdir -p ${INSTALL_DIR}/.condarc.d
  cat > ${INSTALL_DIR}/.condarc <<CONFIG
channels:
  - defaults
  - conda-forge
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
CONFIG

  # 配置 pip 镜像源（清华源）
  mkdir -p ${INSTALL_DIR}/pip
  cat > ${INSTALL_DIR}/pip/pip.conf <<PIPCONFIG
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
PIPCONFIG

  # 清理缓存
  ${INSTALL_DIR}/bin/conda clean -y --all
EOF

# 配置环境变量
ENV PATH="${INSTALL_DIR}/bin:${PATH}" \
    PIP_CONFIG_FILE="${INSTALL_DIR}/pip/pip.conf"

    
SHELL ["/bin/bash", "-c"]

# 阶段1: 安装conda环境
RUN <<EOT
    eval "$(conda shell.bash hook)"
    conda create -n d2l-pytorch python=3.9.16 -y
    conda install -n d2l-pytorch poetry -c conda-forge -y
EOT
# 阶段2: 复制项目文件
COPY pyproject.toml /root/

# 阶段3: 安装依赖
RUN <<EOT
    eval "$(conda shell.bash hook)"
    conda init
    source ~/.bashrc
    conda activate d2l-pytorch
    poetry config virtualenvs.create false
    poetry lock
    poetry install --no-interaction
    
EOT

VOLUME [ "/root/d2l-pytorch" ]



# Set the entrypoint
ENTRYPOINT ["/bin/bash"]