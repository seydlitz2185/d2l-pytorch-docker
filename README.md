# 使用Dockerfile快速构建PyTorch版本d2l深度学习教程运行环境

## 本仓库的目的

- 构建一个Docker镜像来运行d2l notebook，可以在主流操作系统（Windows、macOS、Ubuntu Linux等）上运行，适合多种平台上的用户。
- 使用基于项目的python包管理器uv（或poetry），避免软件包版本冲突，提高项目的可移植性。
- 不拘泥于d2l学习项目，也可以作为未来构建自己的机器学习项目作为参考。

## 使用教程

下面将详细介绍如何使用本仓库的方法构建docker镜像；

### 预备

#### Docker与 WSL2简介

> Docker 是一种 **容器化技术** ，允许开发者将应用及其依赖打包到一个轻量级、可移植的“容器”中。容器共享操作系统内核，但彼此隔离，确保环境一致性。通过 Docker，应用可在任何支持容器的系统（如开发机、云服务器）中快速部署，解决“本地能跑，线上报错”的问题，提升开发和运维效率。
>
> **WSL2** （Windows Subsystem for Linux 第二代）是微软推出的轻量级虚拟机技术，允许在Windows中直接运行完整的Linux内核及工具链。相比初代WSL1，它通过虚拟化实现更高的系统兼容性和性能（尤其文件I/O和进程调用）。
>
> **为什么Windows Docker需用WSL2？**
>
> 1. **性能提升** ：传统Windows Docker依赖Hyper-V虚拟机，资源消耗大且文件读写慢。WSL2提供轻量级Linux环境，容器直接运行其中，文件操作效率接近原生Linux。
> 2. **内核兼容性** ：Docker依赖Linux内核特性（如cgroups、命名空间），WSL2内置完整Linux内核，无需额外虚拟化层即可支持容器。
> 3. **无缝集成** ：Docker Desktop默认基于WSL2，可直接调用Linux工具链，实现开发、调试与部署环境统一。
> 4. **资源效率** ：WSL2动态分配内存/CPU，与Windows共享资源，启动更快且占用更低。
>
> 简言之，WSL2让Windows用户以接近原生体验高效运行Docker，解决环境割裂与性能瓶颈。
>
> 以上内容来自deepseek

参考链接：

- [Docker官方文档](https://docs.docker.com/get-started/)
- [WSL2官方文档](https://learn.microsoft.com/zh-cn/windows/wsl/about)

#### 如果你是Windows用户，请先安装WSL2

对于Windows用户，需要用WSL2作为docker的后端，可以直接按照[微软官方安装教程](https://learn.microsoft.com/zh-cn/windows/wsl/install)进行安装。这里摘录部分关键信息：

> 必须运行 Windows 10 版本 2004 及更高版本（内部版本 19041 及更高版本）或 Windows 11 才能使用以下命令。 如果使用的是更早的版本，请参阅[手动安装页](https://learn.microsoft.com/zh-cn/windows/wsl/install-manual)。

> - 在管理员模式下打开 PowerShell 或 Windows 命令提示符，方法是右键单击并选择“以管理员身份运行”
> - 输入 `wsl --install` 命令，等待程序安装完毕
> - 重启计算机。
>
>   ——微软官方文档

注：`wsl --install`默认选择安装Ubuntu，可以使用 `wsl --install -d debian` 指定安装Debian Linux发行版

#### 安装Docker：

对于新手，可以直接从[Docker官网](https://www.docker.com/)上下载Docker Desktop的安装包。注意选择适合自己电脑处理器架构的安装包。

![img](./img/docker1.png "选择适合自己电脑的docker版本")![](1.png)![](1.png)

下载完成后依照指示安装即可。

注：

1. 对于Windows用户，安装完毕后可以同时在Windows PowerShell和WSL2 终端中使用docker命令。

![img](./img/docker2.png)

2. Windows系统内置的Power Shell版本较为落后，如果你喜欢使用 PowerShell，建议[安装PowerShell 7](https://github.com/PowerShell/powershell/releases)并将它设置为Windows系统默认终端。

其他安装教程的参考链接：

[- 菜鸟教程：Windows Docker](https://www.runoob.com/docker/windows-docker-install.html)

### 项目结构

请仔细阅读注释

```
# Dockerfile文件，用于构建Docker镜像
├── d2l-uv.Dockerfil			# （推荐）只使用uv，只下载cpu版本的torch
├── d2l-poetry-all.Dockerfile 		# （不推荐）使用miniconda + poetry，下载全部版本的torch，包含gpu版本
├── d2l-poetry.Dockerfile 		# （不推荐）使用miniconda + poetry，只下载cpu版本的torch
#python项目文件，用于在Docker镜像构建过程中配置python环境
├── pyproject.toml 			# python项目文件
├── setup.py				# python
#其他文件
├── docker-proxy.txt 			# 记录了docker镜像站，用于加速docker pull过程，防止因为网络问题无法构建
└── README.md				# 项目介绍文档，你正在阅读这个文件
```

### 构建Docker镜像

### 运行Docker容器
