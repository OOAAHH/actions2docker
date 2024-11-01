# syntax=docker/dockerfile:1.9
FROM python:3.12-slim AS base

# Create a non-root user
RUN useradd -m appuser

# 更新包列表并安装 bash 和构建工具2
RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG marimo_version=0.9.13
ENV MARIMO_SKIP_UPDATE_CHECK=1
RUN pip install --no-cache-dir marimo==${marimo_version} && \
  mkdir -p /app/data && \
  chown -R appuser:appuser /app

COPY --chown=appuser:appuser marimo/_tutorials tutorials
RUN rm -rf tutorials/__init__.py

ENV PORT=8080
EXPOSE $PORT

ENV HOST=0.0.0.0

# -slim entry point
FROM base AS slim
CMD marimo edit --no-token -p $PORT --host $HOST

# -data entry point
FROM base AS data
RUN pip install --no-cache-dir altair pandas numpy
CMD marimo edit --no-token -p $PORT --host $HOST

# -sql entry point, extends -data
FROM data AS sql
RUN pip install SCCAF pandas tqdm matplotlib
RUN pip install --no-cache-dir marimo[sql]
RUN pip cache purge
CMD marimo edit --no-token -p $PORT --host $HOST
