# ========== 基础镜像：含 CUDA 12.9 + cuDNN  ==========
FROM nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04

# ========== 1️⃣ 设置工作目录 ==========
WORKDIR /root

# ========== 2️⃣ 配置国内 apt 源 ==========
RUN set -eux && \
    sed -i 's|archive.ubuntu.com|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    sed -i 's|security.ubuntu.com|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv git wget curl vim ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ========== 3️⃣ 配置 pip 国内源并安装 uv ==========
RUN python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    python3 -m pip install -U pip && \
    python3 -m pip install uv

# ========== 4️⃣ 设置环境变量（加速下载与重试） ==========
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn
ENV UV_HTTP_TIMEOUT=1800
ENV UV_HTTP_CONNECT_TIMEOUT=300
ENV UV_CONCURRENCY=6
ENV UV_HTTP_RETRIES=3

# ========== 5️⃣ 安装常用数据科学与建模包 ==========
RUN uv pip install --system \
    notebook jupyterlab openpyxl \
    numpy pandas scipy scikit-learn \
    matplotlib seaborn tqdm pillow requests \
    polars optuna joblib imbalanced-learn ultralytics 

# ========== 6️⃣ 安装 PyTorch GPU 生态 ==========
RUN uv pip install --system \
    torch torchvision torchaudio 

# ========== 7️⃣ 可选：安装 d2l（动手学深度学习） ==========
# RUN uv pip install --system d2l==1.0.3

# ========== 8️⃣ 挂载默认工作卷 ==========
VOLUME ["/root/mathmodeling"]

# ========== 9️⃣ 默认启动 Bash ==========
ENTRYPOINT ["/bin/bash"]
