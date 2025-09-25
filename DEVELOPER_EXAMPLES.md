# MLPerf Storage Benchmark - Developer Desktop Examples

This document provides minimal footprint examples optimized for developer desktop testing. These examples use the smallest possible datasets while still demonstrating the full benchmark workflow.

## Quick Start (Minimal Footprint)

The following examples use **ResNet-50** which has the smallest data footprint (~7GB for development vs 477GB for U-Net3D).

### Prerequisites

```bash
# Build the Docker image
docker build -t mlpstorage:latest --load .

# Or using Taskfile
task build
```

## Developer Examples

### 1. Minimal ResNet-50 Example (Recommended for Development)

**Data Requirements:** ~7GB
**Memory:** 4GB RAM minimum  
**Accelerators:** 1 simulated H100

```bash
# Step 1: Calculate minimum dataset size (optional - shows what's needed)
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/data:/workspace/data \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) --network host \
  mlpstorage:latest \
  mlpstorage training datasize \
    -m resnet50 \
    --client-host-memory-in-gb 4 \
    --num-client-hosts 1 \
    --max-accelerators 1 \
    --accelerator-type h100 \
    --results-dir /workspace/results \
    --open

# Step 2: Generate minimal dataset (50 files instead of 159 for faster setup)
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/data:/workspace/data \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) --network host \
  mlpstorage:latest \
  mlpstorage training datagen \
    --hosts 127.0.0.1 \
    --model resnet50 \
    --num-processes 1 \
    --data-dir /workspace/data/resnet50_dev \
    --results-dir /workspace/results \
    --param dataset.num_files_train=50 \
    --open

# Step 3: Run the benchmark
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/data:/workspace/data \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) --network host \
  mlpstorage:latest \
  mlpstorage training run \
    --hosts 127.0.0.1 \
    --num-client-hosts 1 \
    --client-host-memory-in-gb 4 \
    --num-accelerators 1 \
    --accelerator-type h100 \
    --model resnet50 \
    --data-dir /workspace/data/resnet50_dev \
    --results-dir /workspace/results \
    --param dataset.num_files_train=50 \
    --open

# Step 4: Generate report
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/results:/workspace/results \
  --user $(id -u):$(id -g) --network host \
  mlpstorage:latest \
  mlpstorage reports reportgen \
    --results-dir /workspace/results
```

### 2. Using Taskfile (Recommended)

If you have [Task](https://taskfile.dev/) installed, use the simplified commands:

```bash
# Complete workflow (build, generate data, run benchmark, create report)
task dev-test

# Individual steps for more control
task dev-datasize        # Calculate minimum dataset requirements
task dev-datagen         # Generate minimal dataset only
task dev-run             # Run benchmark only (requires data)
task dev-report          # Generate report only
task dev-clean           # Clean up generated data and results

# See all available tasks
task --list
```

## Resource Requirements Comparison

| Model | Min Files | Data Size | Memory | Time | Use Case |
|-------|-----------|-----------|--------|------|----------|
| **ResNet-50 (Dev)** | 50 | ~7GB | 4GB | ~3 min | **Developer testing** |
| ResNet-50 (Min Spec) | 159 | ~21GB | 4GB | ~8 min | Validation |
| U-Net3D (Min Spec) | 3,500 | ~478GB | 8GB | ~45 min | Full testing |

## Configuration Options

### Open vs Closed Submissions

- **`--open`**: Allows custom parameters, smaller datasets for development
- **`--closed`**: Strict MLPerf submission rules, larger datasets required
- **No flag**: Runs benchmark but results marked as invalid for submission

### Memory Settings

```bash
# Minimal (4GB RAM)
--client-host-memory-in-gb 4

# Standard Desktop (8GB RAM) 
--client-host-memory-in-gb 8

# High-end Desktop (16GB+ RAM)
--client-host-memory-in-gb 16
```

### Accelerator Types

```bash
# H100 (default, best performance)
--accelerator-type h100

# A100 (alternative)
--accelerator-type a100
```

## Expected Output

### During Benchmark Run

A successful run will show:

```text
[METRIC] Training Accelerator Utilization [AU] (%): 97.55 (1.36)
[METRIC] Training Throughput (samples/second): 1705.55 (28.14)
[METRIC] Training I/O Throughput (MB/second): 186.50 (3.08)
[METRIC] train_au_meet_expectation: success
```

### In Final Report

The development configuration will show **INVALID Report** due to using only 50 files instead of the required 159. This is **expected and correct** for development testing:

```text
------------------------- INVALID Report -------------------------
[INVALID] Insufficient number of training files (Expected: >= 159, Actual: 50)
```

**Key metrics to verify:**

- ✅ `train_au_meet_expectation: success`
- ✅ Accelerator utilization ~97-98%
- ✅ Consistent throughput values
- ✅ No fatal errors during execution

## Troubleshooting

### Common Issues

1. **"Insufficient number of training files"**
   - Use `--open` flag for development
   - Increase `dataset.num_files_train` parameter

2. **Docker permission errors**
   - Ensure `--user $(id -u):$(id -g)` is included
   - Check that data/results directories are writable

3. **Out of disk space**
   - Use ResNet-50 instead of U-Net3D
   - Reduce `dataset.num_files_train` parameter

4. **TensorFlow warnings during data generation**
   - **Expected warnings:** `unable to load libtensorflow_io_plugins.so` and `file system plugins are not loaded`
   - **These are non-fatal** and can be safely ignored
   - Related to TensorFlow I/O plugins in the containerized environment
   - Data generation and benchmarking will proceed normally despite these warnings

## Next Steps

Once you've verified the basic functionality:

1. **Scale up**: Try with more files (`dataset.num_files_train=159`)
2. **Multi-accelerator**: Increase `--num-accelerators` to 2 or 4
3. **Different models**: Test U-Net3D or CosmoFlow
4. **Multi-host**: Add additional hosts to `--hosts` parameter

## Production Use

For actual benchmarking (not development):

- Remove `--open` flag or use `--closed` 
- Use minimum required file counts from `datasize` command
- Ensure sufficient disk space (5x system memory rule)
- Use production-grade storage systems