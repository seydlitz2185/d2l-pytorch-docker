FROM python:3.13-bookworm

# 构建与运行示例：
# # CPU 版本（默认）
# docker build -t pytorch-cpu .
# docker run -it --rm -v $(pwd):/root/d2l-pytorch pytorch-cpu



WORKDIR /root

# ========== 1️⃣ 配置 Debian 国内镜像源 ==========
RUN <<EOT
    cat > /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security trixie-security main contrib non-free
EOT

# 更新源并安装工具 + 字体
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        ca-certificates \
        curl \
        vim \
        fontconfig \
        fonts-noto-cjk && \
    # fc-cache -fv  && \
    rm -rf /var/lib/apt/lists/*


# ========== 2️⃣ 配置 pip 国内镜像 + 安装 uv ==========
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config set global.trusted-host mirrors.tuna.tsinghua.edu.cn && \
    pip install -U pip && \
    pip install uv

# ========== 3️⃣ 设置镜像源环境变量 ==========
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn


# ========== 4️⃣ 安装基础包 ==========
RUN uv pip install --system \
    notebook jupyterlab openpyxl \
    numpy pandas scipy scikit-learn \
    matplotlib seaborn tqdm pillow requests \
    polars optuna joblib imblearn \
    opencv-python 

# ========== 5️⃣ 安装 PyTorch + torchvision + d2l ==========
RUN <<EOF
    # CPU 版本（自动区分架构）
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        uv pip install torch==2.6.0+cpu torchvision==0.21.0 torchaudio==2.6.0+cpu --index-url https://download.pytorch.org/whl/cpu --system
    else
        uv pip install torch==2.6.0+cpu torchvision==0.21.0+cpu torchaudio==2.6.0+cpu --index-url https://download.pytorch.org/whl/cpu --system
    fi
    # 安装 d2l (动手学深度学习)
    # ```uv pip install d2l==1.0.3 --system


EOF
    # 安装 ultralytics（不会再自动下载 torch）
RUN pip install --no-cache-dir ultralytics

# ========== 6️⃣ 预设工作卷和默认启动项 ==========
VOLUME ["/root/mathmodeling"]

ENTRYPOINT ["/bin/bash"]
