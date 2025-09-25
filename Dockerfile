# MLPerf Storage Benchmark Suite
# Ubuntu 24.04 slim-based container with all dependencies
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Create a non-root user
RUN groupadd -r mlperf && useradd -r -g mlperf mlperf

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libopenmpi-dev \
    openmpi-bin \
    openmpi-common \
    git \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip to latest version
RUN python3 -m pip install --upgrade pip

# Set working directory
WORKDIR /workspace

# Copy the entire project
COPY . .

# Install the mlpstorage package and its dependencies
RUN pip install -e .

# Create directories for data and results
RUN mkdir -p /workspace/data /workspace/results && \
    chown -R mlperf:mlperf /workspace

# Switch to non-root user
USER mlperf

# Set the default command
CMD ["mlpstorage", "--help"]