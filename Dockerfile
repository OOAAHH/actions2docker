# syntax=docker/dockerfile:1.9
FROM python:3.9-slim AS base
# 安装必要的工具
RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    cmake \
    libxml2-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/*

# 创建 Python 虚拟环境
RUN python3 -m venv /opt/venv

# 修改虚拟环境的所有者为 appuser
RUN useradd -m appuser && chown -R appuser:appuser /opt/venv

# 设置环境变量，使用虚拟环境的 Python 和 pip
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 切换到 appuser 用户
USER appuser

# 升级 pip 并安装最新的 setuptools 和 setuptools_scm
RUN pip install --upgrade pip setuptools setuptools_scm

# 切换回 root 用户，安装公共依赖
USER root

# 安装指定版本的 marimo
# ARG marimo_version=0.9.13
RUN pip install --no-cache-dir marimo

# 创建工作目录并赋予权限
RUN mkdir /app && chown appuser:appuser /app

# 设置工作目录
WORKDIR /app

# 设置应用程序环境变量
ENV MARIMO_SKIP_UPDATE_CHECK=1
ENV PORT=8080
ENV HOST=0.0.0.0

# 暴露端口
EXPOSE $PORT

# 切换到 appuser 用户
USER appuser

## slim 阶段
FROM base AS slim
CMD ["sh", "-c", "marimo edit --no-token -p $PORT --host $HOST"]

## data 阶段
FROM base AS data

# 切换到 root 用户安装依赖
USER root

# 安装数据处理相关的依赖
RUN pip install --no-cache-dir scvi-tools==0.20.0
RUN pip install --no-cache-dir -U anndata==0.10.8 requests
RUN pip install --no-cache-dir scgen 
RUN sed -i 's/^from scvi\._compat import Literal/# from scvi._compat import Literal\nfrom typing import Literal/' /opt/venv/lib/python3.9/site-packages/scgen/_scgenvae.py
RUN rm -rf /opt/venv/cache

# 切换回 appuser 用户
USER appuser

CMD ["sh", "-c", "marimo edit --no-token -p $PORT --host $HOST"]

## sql 阶段
FROM data AS sql

# 切换到 root 用户安装依赖
USER root

# 安装 marimo 的 sql 扩展
RUN pip install --no-cache-dir marimo[sql] && \
    rm -rf /opt/venv/cache

# 切换回 appuser 用户
USER appuser

CMD ["sh", "-c", "marimo edit --no-token -p $PORT --host $HOST"]
