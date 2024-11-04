# syntax=docker/dockerfile:1.9
FROM python:3.12-slim AS base

# 更新包列表并安装必要的工具
RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    cmake \
    libxml2-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/*

# 升级 pip 并安装最新的 setuptools 和 setuptools_scm
RUN pip install --upgrade pip setuptools setuptools_scm

# 创建非 root 用户
RUN useradd -m appuser

# 创建工作目录并赋予权限
RUN mkdir /app && chown appuser:appuser /app

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV MARIMO_SKIP_UPDATE_CHECK=1
ENV PORT=8080
ENV HOST=0.0.0.0

# 安装公共依赖
RUN pip install --no-cache-dir --verbose  \
    SCCAF \
    tqdm \
    matplotlib && \
    pip cache purge

# 安装指定版本的 marimo
ARG marimo_version=0.9.13
RUN pip install --verbose --no-cache-dir marimo==${marimo_version}

# 创建必要的目录并赋予权限
RUN mkdir -p /app/data && chown -R appuser:appuser /app

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE $PORT

## slim 阶段
FROM base AS slim
CMD ["marimo", "edit", "--no-token", "-p", "$PORT", "--host", "$HOST"]

## data 阶段
FROM base AS data

# 安装数据处理相关的依赖
RUN pip install --no-cache-dir --verbose  \
    pandas \
    numpy \
    altair && \
    pip cache purge

CMD ["marimo", "edit", "--no-token", "-p", "$PORT", "--host", "$HOST"]

## sql 阶段
FROM data AS sql

# 安装 marimo 的 sql 扩展
RUN pip install --verbos --no-cache-dir marimo[sql] && \
    pip cache purge

CMD ["marimo", "edit", "--no-token", "-p", "8080", "--host", "0.0.0.0"]
