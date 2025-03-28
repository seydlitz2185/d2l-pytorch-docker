FROM python:3.9-slim

WORKDIR /root

# 配置 Debian 国内镜像源并安装必要工具
RUN <<EOT
    # 使用清华大学镜像源
    cat > /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
EOF
    
    # 更新软件包列表并安装必要工具
    apt-get update 
    apt-get install -y \
    git wget ca-certificates
    rm -rf /var/lib/apt/lists/*
EOT

# # 配置 pip 使用国内镜像源
RUN pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple && \
    pip config set global.trusted-host mirrors.tuna.tsinghua.edu.cn

# 使用 PyPI 官方源安装 uv
RUN pip config set global.index-url https://pypi.org/simple && \
    pip install uv && \
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple

# 配置 uv 使用国内镜像源
ENV PIP_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/pypi/simple
ENV PIP_TRUSTED_HOST=mirrors.tuna.tsinghua.edu.cn

# 复制项目文件
COPY pyproject.toml /root/

# 安装依赖
RUN uv pip install --system "torch==2.6.0+cpu" "torchvision==0.21.0+cpu" --index-url https://download.pytorch.org/whl/cpu && \
    uv pip sync pyproject.toml --system --index-strategy unsafe-best-match

# 创建工作目录
WORKDIR /root/d2l-pytorch
VOLUME ["/root/d2l-pytorch"]

# 设置入口点
ENTRYPOINT ["/bin/bash"] 