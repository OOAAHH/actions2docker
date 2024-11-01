# 使用精简版的 Python 3.11 基础镜像
FROM python:3.11-slim

# 更新包列表并安装 bash 和构建工具
RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装 marimo 以及其它的依赖？
RUN pip install --no-cache-dir marimo
RUN pip install SCCAF pandas tqdm matplotlib
RUN pip cache purge

# 运行 marimo tutorial intro
# RUN marimo tutorial intro

# 暴露 marimo 使用的端口（假设为8080）
EXPOSE 2818

# 设置工作目录为 /docs
WORKDIR /docs

# 设置容器启动时运行的命令
# CMD ["marimo", "edit"]
# 设置容器启动时运行的命令，指定端口为 2818
CMD ["marimo", "edit", "--port", "2818"]
