# syntax=docker/dockerfile:1.9
FROM python:3.7 AS base

# Install necessary tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libxml2-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment
RUN python3 -m venv /opt/venv

# Modify virtual environment ownership
RUN useradd -m appuser && chown -R appuser:appuser /opt/venv

# Set environment variables to use virtual environment Python and pip
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Switch to appuser
USER appuser

# Upgrade pip and install necessary tools
RUN pip install --upgrade setuptools setuptools_scm

# Switch to root to install public dependencies
USER root

# Install Jupyter and necessary dependencies
RUN pip install --no-cache-dir scgen
RUN pip install scgen[tutorials]
RUN pip install --no-cache-dir jupyter

# Create working directory and set permissions
RUN mkdir /app && chown appuser:appuser /app

# Set working directory
WORKDIR /app

# Expose port for Jupyter Notebook
EXPOSE 8888

# Set environment variables for Jupyter Notebook
ENV JUPYTER_PORT=8888
ENV JUPYTER_HOST=0.0.0.0

# Switch to appuser
USER appuser

# Start Jupyter Notebook
CMD ["sh", "-c", "jupyter notebook --no-browser --port=$JUPYTER_PORT --ip=$JUPYTER_HOST"]
