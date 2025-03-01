#!/bin/bash

# 定义环境文件路径（默认为 environment.yml）
ENV_FILE="${1:-environment.yml}"

# 检查文件是否存在
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: File $ENV_FILE not found!"
    exit 1
fi

# 提取依赖项的函数
extract_deps() {
    # 提取 Conda 原生依赖（排除 pip 和 Python）
    yq eval '.dependencies | map(select(. != "pip" and (type == "string"))) | .[]' "$ENV_FILE" | \
    while IFS= read -r dep; do
        # 分离包名和版本（处理 "numpy=1.21.0" 或 "numpy"）
        pkg=$(echo "$dep" | awk -F'=' '{print $1}')
        version=$(echo "$dep" | awk -F'=' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # 跳过 Python 本身（已在 pyproject.toml 中指定）
        if [ "$pkg" == "python" ]; then
            continue
        fi
        
        # 构造 poetry add 命令
        if [ -n "$version" ]; then
            echo "poetry add \"$pkg==$version\""
            poetry add "$pkg==$version" || echo "Failed to add $pkg"
        else
            echo "poetry add \"$pkg\""
            poetry add "$pkg" || echo "Failed to add $pkg"
        fi
    done

    # 提取 pip 安装的依赖
    yq eval '.dependencies.[] | select(has("pip")) | .pip[]' "$ENV_FILE" | \
    while IFS= read -r pip_dep; do
        # 分离包名和版本（处理 "requests==2.26.0"）
        pkg=$(echo "$pip_dep" | awk -F'==' '{print $1}')
        version=$(echo "$pip_dep" | awk -F'==' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # 构造 poetry add 命令
        if [ -n "$version" ]; then
            echo "poetry add \"$pkg==$version\""
            poetry add "$pkg==$version" || echo "Failed to add $pkg"
        else
            echo "poetry add \"$pkg\""
            poetry add "$pkg" || echo "Failed to add $pkg"
        fi
    done
}

# 执行提取和添加
extract_deps
