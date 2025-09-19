FROM python:3.9-slim

WORKDIR /root

# 配置 Debian 国内镜像源并安装必要工具
RUN <<EOT
    # # 备份原始源配置
    # cp /etc/apt/sources.list /etc/apt/sources.list.bak
    
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
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config set global.trusted-host mirrors.tuna.tsinghua.edu.cn

# 使用 PyPI 官方源安装 uv
RUN pip config set global.index-url https://pypi.org/simple && \
    pip install uv && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 配置 uv 使用国内镜像源
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

# 预先安装项目依赖
RUN <<EOF
    uv pip install notebook==7.3.2 --system 
    # 按架构选择安装源与包名：
    # - arm64/aarch64：使用官方 whl 索引（不带 +cpu 后缀）
    # - amd64/x86_64：使用 /cpu 索引并带 +cpu 后缀
    ARCH="$(dpkg --print-architecture)"
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        uv pip install torch==2.6.0+cpu torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cpu --system
    else
        uv pip install torch==2.6.0+cpu torchvision==0.21.0+cpu --index-url https://download.pytorch.org/whl/cpu --system
    fi
    uv pip install d2l==1.0.3 --system
EOF

# # 使用toml文件安装
# COPY pyproject.toml /root/
# RUN <<EOT
#     uv pip sync pyproject.toml --system 
# EOT

VOLUME ["/root/d2l-pytorch"]

# 设置入口点
ENTRYPOINT ["/bin/bash"] 