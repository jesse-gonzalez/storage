# Docker Setup for MLPerf Storage Benchmark

This directory contains Docker configuration files to run the MLPerf Storage benchmark suite in a containerized environment.

## Files

- `Dockerfile`: Multi-stage build for Ubuntu 24.04 with all dependencies
- `docker-compose.yml`: Docker Compose configuration with volume mounts
- `Taskfile.yml`: Task automation for building, running, and managing Docker operations
- `.dockerignore`: Excludes unnecessary files from Docker build context

## Quick Start

### Using Taskfile (Easiest)

If you have [Task](https://taskfile.dev/) installed, you can use the provided Taskfile for simplified commands:

```bash
# Build the image
task build

# Run interactively
task run

# Run a specific command
task run-cmd CMD="mlpstorage --help"

# See all available tasks
task --list
```

### Build and Run with Docker Compose (Recommended)

```bash
# Build the container
docker-compose build

# Run interactively with workspace mounted
docker-compose run --rm mlpstorage

# Or run a specific command
docker-compose run --rm mlpstorage mlpstorage --help
```

### Build and Run with Docker

```bash
# First, build the image (required before running)
docker build -t mlpstorage:latest .

# Run interactively with workspace mounted
docker run -it --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/data:/workspace/data \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) \
  --network host \
  mlpstorage:latest /bin/bash

# Run a specific command (after building the image)
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/data:/workspace/data \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) \
  --network host \
  mlpstorage:latest mlpstorage --help
```

## Usage Examples

Once inside the container, you can run the benchmark commands as described in the main README:

```bash
# Calculate dataset size
mlpstorage training datasize -m unet3d --client-host-memory-in-gb 64 --num-client-hosts 1 --max-accelerators 4 --accelerator-type h100

# Generate data
mlpstorage training datagen --hosts 127.0.0.1 --num-processes 8 --model unet3d --data-dir /workspace/data/unet3d_data --results-dir /workspace/results

# Run benchmark
mlpstorage training run --hosts 127.0.0.1 --num-client-hosts 1 --client-host-memory-in-gb 64 --num-accelerators 4 --accelerator-type h100 --model unet3d --data-dir /workspace/data/unet3d_data --results-dir /workspace/results
```

## Features

- **Ubuntu 24.04 slim base**: Minimal footprint while including all necessary dependencies
- **Python 3.12**: Matches the validated environment from the README  
- **OpenMPI**: Required for distributed workloads across multiple hosts
- **Non-root user**: Runs as `mlperf` user for security
- **Volume mounting**: Workspace is mounted to allow live editing and persistent results
- **Network host mode**: Enables MPI communication for multi-host setups

## Notes

- The container uses network host mode to support MPI communication
- File permissions are preserved through user mapping in docker-compose
- Data and results directories are created and mounted for persistence
- All Python dependencies are installed in a virtual environment at `/opt/venv`

## Multi-Host Setup

For distributed benchmarks across multiple hosts, you'll need to:

1. Ensure Docker and this image are available on all hosts
2. Set up passwordless SSH between hosts
3. Use the same data directory paths on all hosts
4. Configure the `--hosts` parameter with actual IP addresses

## Troubleshooting

- If you encounter permission issues, ensure the UID/GID mapping in docker-compose matches your host user
- For MPI issues across hosts, verify network connectivity and firewall settings
- Check that the data directory paths are consistent across all participating hosts