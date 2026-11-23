---
title: "Module 2: Installation and Setup"
subject: Climate Data Operators Training
subtitle: "Installing CDO on Your System"
---

# Module 2: Installation and Setup

## Learning Objectives

By the end of this module, you will be able to:

- Install CDO on Linux, macOS, and Windows systems
- Install CDO using package managers and conda
- Build CDO from source code
- Install and configure supporting tools (NCO, Python libraries)
- Verify your CDO installation is working correctly
- Troubleshoot common installation issues
- Set up environment variables for optimal CDO usage

---

## System Requirements

Before installing CDO, ensure your system meets these minimum requirements:

```{note}
CDO is lightweight and runs on modest hardware, but large climate datasets benefit from more resources.
```

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Processor** | 1 GHz single-core | 4+ cores |
| **RAM** | 1 GB | 16+ GB |
| **Storage** | 100 MB (CDO only) | 100+ GB (for datasets) |
| **OS** | Linux, macOS, Windows | Linux |
| **Python** | 3.7+ (optional) | 3.10+ |

### Required Dependencies

CDO depends on several libraries for format support:

| Library | Purpose | Required |
|---------|---------|----------|
| `libnetcdf` | NetCDF read/write | Yes |
| `libgrib_api` / `eccodes` | GRIB read/write | Yes (for GRIB) |
| `libhdf5` | HDF5 support | Optional |
| `libproj` | Projections | Optional |
| `libszip` | Compression | Optional |
| `libudunits2` | Unit conversion | Optional |

## Install on Ubuntu/Debian

The simplest method on Debian-based systems:

```bash
sudo apt-get update
sudo apt-get install cdo
```

```{tip}
Use `apt-cache search cdo` to check available versions before installing.
```

### Install with Full Format Support

For complete format support including GRIB and HDF5:

```bash
sudo apt-get update
sudo apt-get install -y \
    cdo \
    libnetcdf-dev \
    libgrib-api-dev \
    libeccodes-dev \
    libhdf5-dev \
    libproj-dev \
    libudunits2-dev \
    libszip-dev \
    nco \
    netcdf-bin \
    gdal-bin
```

### Verify Package Version

```bash
apt-cache policy cdo
```

```{warning}
Ubuntu LTS repositories sometimes have older CDO versions. For the latest version, consider using conda or building from source.
```

## Install on Fedora/CentOS/RHEL

### Fedora

```bash
sudo dnf install cdo
```

### CentOS/RHEL 8+ with EPEL

```bash
sudo dnf install epel-release
sudo dnf install cdo
```

### Enable PowerTools for Dependencies

On CentOS/RHEL 8:

```bash
sudo dnf config-manager --set-enabled PowerTools
sudo dnf install cdo
```

### Install Supporting Libraries

```bash
sudo dnf install \
    netcdf-devel \
    eccodes-devel \
    hdf5-devel \
    proj-devel \
    udunits2-devel \
    nco
```

## Install on macOS via Homebrew

```{note}
Homebrew is the recommended package manager for macOS. Install it from https://brew.sh if you don't have it.
```

### Basic Installation

```bash
brew install cdo
```

### Install with All Options

```bash
brew install cdo --with-hdf5 --with-eccodes --with-proj --with-udunits
```

### Check Available Formula Options

```bash
brew options cdo
```

### Update CDO

```bash
brew upgrade cdo
```

```{tip}
On Apple Silicon (M1/M2/M3) Macs, Homebrew installs to `/opt/homebrew/` instead of `/usr/local/`. Ensure this is in your PATH.
```

## Install on Windows via WSL

Windows does not natively support CDO, but Windows Subsystem for Linux (WSL) provides a Linux environment.

```{important}
WSL 2 is recommended for better performance and full Linux kernel compatibility.
```

### Step 1: Install WSL

Open PowerShell as Administrator:

```powershell
wsl --install
```

This installs Ubuntu as the default distribution. Reboot when prompted.

### Step 2: Install CDO in WSL

```bash
sudo apt-get update
sudo apt-get install cdo
```

### Step 3: Access Windows Files from WSL

Your Windows files are available under `/mnt/`:

```bash
# Access C:\ drive
cd /mnt/c/Users/YourName/

# Access D:\ drive
cd /mnt/d/
```

```{warning}
Processing files on Windows drives from WSL can be slower. For large datasets, copy files into the WSL filesystem (`~/`) for better performance.
```

### Alternative: Using Git BASH

For simple CDO operations, you can also use Git BASH on Windows, but WSL is strongly recommended for full functionality.

## Install via Conda

Conda provides a cross-platform installation method that works on Linux, macOS, and Windows.

```{note}
Conda installation works on Windows natively without WSL, though WSL is still recommended for best performance.
```

### Install Miniconda or Anaconda

If you don't have conda installed:

```bash
# Download Miniconda (recommended)
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### Install CDO from conda-forge

```bash
conda install -c conda-forge cdo
```

### Create a Dedicated Environment

```bash
conda create -n cdo_env -c conda-forge cdo python=3.10
conda activate cdo_env
```

### Install Additional Tools in the Environment

```bash
conda install -c conda-forge \
    nco \
    netcdf4 \
    xarray \
    matplotlib \
    jupyter
```

### Check CDO Version in Conda

```bash
conda list cdo
```

```{tip}
Use conda environments to isolate different versions of CDO or to avoid dependency conflicts.
```

## Docker Installation

Docker provides a containerized environment with CDO pre-installed.

### Pull an Existing Docker Image

```bash
docker pull joesfer/cdo
```

### Run CDO in Docker

```bash
# Interactive session
docker run -it --rm -v $(pwd):/data joesfer/cdo bash

# Run a CDO command directly
docker run --rm -v $(pwd):/data joesfer/cdo cdo --version
```

### Create Your Own Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    cdo \
    nco \
    netcdf-bin \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install xarray netcdf4 matplotlib

WORKDIR /data

CMD ["bash"]
```

Build and run:

```bash
docker build -t cdo-env .
docker run -it --rm -v $(pwd):/data cdo-env
```

```{warning}
Mount your data directory with `-v $(pwd):/data` to access local files inside the container.
```

## Build from Source

Building from source gives you the latest features and full control over compilation options.

### Step 1: Download Source Code

```bash
wget https://code.mpimet.mpg.de/attachments/download/29643/cdo-2.4.0.tar.gz
tar -xzf cdo-2.4.0.tar.gz
cd cdo-2.4.0
```

```{note}
Check https://code.mpimet.mpg.de/projects/cdo/files for the latest version.
```

### Step 2: Install Build Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install build-essential libnetcdf-dev libeccodes-dev \
    libhdf5-dev libproj-dev libudunits2-dev libszip-dev

# Fedora
sudo dnf install gcc gcc-c++ make netcdf-devel eccodes-devel \
    hdf5-devel proj-devel udunits2-devel szip-devel
```

### Step 3: Configure

```bash
./configure --prefix=/usr/local \
    --with-netcdf=/usr \
    --with-eccodes=/usr \
    --with-hdf5=/usr \
    --with-proj=/usr \
    --with-udunits2=/usr
```

### Step 4: Compile and Install

```bash
make -j$(nproc)
sudo make install
```

### Step 5: Verify

```bash
which cdo
cdo --version
```

```{tip}
The `-j$(nproc)` flag speeds up compilation by using all CPU cores.
```

## Verify Installation

After installation, verify CDO is working correctly:

### Check Version

```bash
cdo --version
```

Example output:
```
Climate Data Operators version 2.4.0 (https://mpimet.mpg.de/cdo)
Copyright: 2005-2024 Max Planck Institute for Meteorology
...

Compiled with: ...
Features: 32GB HDF5 NC2 NC4 NC5 SZIP UDUNITS2 PROJ2
```

```{important}
Check the "Features" line - it shows which formats and capabilities are enabled.
```

### Check Help

```bash
cdo --help | head -20
```

### Run a Simple Test

```bash
# Create a test file
cdo -f nc -random,10,5,3 test.nc

# Display info
cdo sinfo test.nc

# Clean up
rm test.nc
```

### Test Format Support

```bash
# Test NetCDF
cdo --version | grep -i "NC4\|HDF5"

# Test GRIB support
cdo --version | grep -i "eccodes\|grib"
```

## Install NCO Tools

The NetCDF Operators (NCO) toolkit complements CDO with additional capabilities.

### Install via Package Manager

```bash
# Ubuntu/Debian
sudo apt-get install nco

# Fedora
sudo dnf install nco

# macOS
brew install nco

# Conda
conda install -c conda-forge nco
```

### Key NCO Commands

| Command | Purpose |
|---------|---------|
| `ncdump` | Display NetCDF file contents in text form |
| `ncgen` | Generate NetCDF file from text description |
| `ncks` | Extract, hyperslab, and manipulate |
| `ncatted` | Edit attributes |
| `ncrename` | Rename dimensions and variables |
| `ncwa` | Weighted averages |

```{note}
CDO and NCO are complementary. CDO excels at climate-specific operations, while NCO provides low-level NetCDF manipulation.
```

## Install Python Dependencies

Python is often used alongside CDO for analysis and visualization.

```{warning}
Install Python packages in a virtual environment or conda environment to avoid conflicts.
```

### Create a Virtual Environment

```bash
python3 -m venv cdo_venv
source cdo_venv/bin/activate
```

### Required Packages

```bash
pip install numpy xarray netcdf4 matplotlib cartopy jupyter
```

### Optional Packages

```bash
pip install pandas scipy seaborn dask cfgrib pygrib
```

### Verify Python Setup

```python
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt

print(f"xarray version: {xr.__version__}")
print(f"numpy version: {np.__version__}")
```

## Environment Variables

Set these environment variables to optimize CDO behavior:

### CDO-Specific Variables

```bash
# Set number of threads for parallel operations
export CDO_NTHREADS=4

# Set temporary directory (ensure enough space)
export CDO_TEMPDIR=/scratch/tmp

# Show verbose warnings
export CDO_VERBOSE=1

# Set memory limit (in GB)
export CDO_MEMORY=8
```

### Add to Shell Configuration

Add these lines to `~/.bashrc` or `~/.zshrc`:

```bash
# CDO Configuration
export CDO_NTHREADS=$(nproc)
export CDO_TEMPDIR=/tmp/cdo
mkdir -p $CDO_TEMPDIR

# NCO Configuration
export NCARG_ROOT=/usr/local
```

### Path Configuration

Ensure CDO is in your PATH:

```bash
# Check if CDO is accessible
which cdo

# Add to PATH if needed (for custom installations)
export PATH=/usr/local/bin:$PATH
```

## Troubleshooting Common Issues

### Problem: "command not found: cdo"

```{admonition} Solution
:class: note
1. Verify installation: `dpkg -l | grep cdo` (Ubuntu) or `rpm -qa | grep cdo` (Fedora)
2. Check PATH: `echo $PATH`
3. Reinstall if necessary: `sudo apt-get install --reinstall cdo`
```

### Problem: "GRIB API functions not found"

```{admonition} Solution
:class: note
1. Install eccodes: `sudo apt-get install libeccodes-dev`
2. Reinstall CDO: `sudo apt-get install --reinstall cdo`
3. Verify: `cdo --version | grep -i grib`
```

### Problem: CDO version is too old

```{admonition} Solution
:class: note
Option 1: Install via conda for latest version:
       conda install -c conda-forge cdo

Option 2: Build from source (see Build from Source section)

Option 3: Use Docker: docker pull joesfer/cdo
```

### Problem: "Cannot allocate memory" error

```{admonition} Solution
:class: note
1. Reduce CDO memory usage:
   export CDO_MEMORY=4

2. Use chunking: cdo -z zip_5 input.nc output.nc

3. Process smaller temporal subsets:
   cdo seldate,2020-01-01,2020-12-31 bigfile.nc subset.nc

4. Use CDO's streaming with pipes instead of intermediate files
```

### Problem: "NetCDF: Not a valid NetCDF ID"

```{admonition} Solution
:class: note
1. Check file integrity: `ncdump -h file.nc`
2. Verify file format: `file file.nc`
3. Try opening with different format flag: `cdo -f nc copy damaged.nc fixed.nc`
4. File may be corrupted - check source
```

### Problem: Slow performance on large files

```{admonition} Solution
:class: note
1. Enable parallel processing:
   export CDO_NTHREADS=8

2. Use compression to reduce I/O:
   cdo -z zip_5 -f nc copy input.grib output.nc

3. Use faster storage (SSD instead of HDD)

4. Avoid processing across WSL filesystem boundaries
```

```{tip}
For the best performance, always process files inside the Linux filesystem (not on mounted Windows drives) when using WSL.
```

## Hands-On Exercises

### Exercise 1: Install CDO on Your Platform

```{exercise}
:label: ex-installation-1
Install CDO using the method appropriate for your operating system.

After installation, record:
1. The installation method you used
2. The installed CDO version
3. The compiled features (from `cdo --version`)
4. Whether GRIB support is enabled
```

### Exercise 2: Compare Installation Methods

```{exercise}
:label: ex-installation-2
If possible, install CDO using two different methods (e.g., package manager and conda) and compare:

1. Version numbers
2. Compiled features
3. File sizes (`which cdo` then `ls -lh`)
4. Performance (time `cdo -random,1000000,100,10 test.nc`)

Create a table comparing the methods.
```

### Exercise 3: Set Up a Complete Environment

````{exercise}
:label: ex-installation-3
Set up a complete climate data processing environment:

1. Install CDO
2. Install NCO tools
3. Create a Python virtual environment with xarray, netcdf4, and matplotlib
4. Set up environment variables in your shell config
5. Verify everything works with a simple test:

```bash
cdo -f nc -random,100,10,5 test.nc
ncdump -h test.nc
python3 -c "import xarray as xr; print(xr.open_dataset('test.nc'))"
rm test.nc
```
````

### Exercise 4: Docker Setup

```{exercise}
:label: ex-installation-4
If you have Docker installed, create a portable CDO environment:

1. Pull the joesfer/cdo image
2. Run CDO inside a container
3. Mount a local directory and process a file
4. Create a Dockerfile with CDO + Python support
5. Build and test your image
```

### Exercise 5: Troubleshooting Scenarios

```{exercise}
:label: ex-installation-5
Simulate and resolve common issues:

1. **Missing GRIB support**: Run `cdo --version` and check the Features line
   - If GRIB support is missing, install the necessary libraries

2. **PATH issue**: Temporarily rename CDO with `sudo mv $(which cdo) /usr/local/bin/cdo_backup`
   - Then find it again and restore it

3. **Version check**: Check your CDO version against the latest release at https://code.mpimet.mpg.de/projects/cdo
   - If outdated, plan an upgrade strategy
```

## Quiz

```{admonition} Quiz
:class: tip
Test your knowledge of CDO installation and setup.
```

```{exercise} Question 1: Which command installs CDO on Ubuntu/Debian systems?
:label: q-installation-1

A. `brew install cdo`  
B. `sudo apt-get install cdo`  
C. `sudo dnf install cdo`  
D. `pip install cdo`  

```

```{solution} q-installation-1
B. `sudo apt-get install cdo`
```

```{exercise} Question 2: What is the recommended way to install CDO on Windows?
:label: q-installation-2

A. Direct Windows installer  
B. Windows Subsystem for Linux (WSL)  
C. Chocolatey  
D. Cygwin  

```

```{solution} q-installation-2
B. Windows Subsystem for Linux (WSL)
```

```{exercise} Question 3: Which environment variable controls CDO's thread count for parallel operations?
:label: q-installation-3

A. `CDO_THREADS`  
B. `OMP_NUM_THREADS`  
C. `CDO_NTHREADS`  
D. `NPROC`  

```

```{solution} q-installation-3
C. `CDO_NTHREADS`
```

```{exercise} Question 4: Which command correctly installs CDO via conda?
:label: q-installation-4

A. `conda install cdo`  
B. `conda install -c conda-forge cdo`  
C. `conda install -c mpimet cdo`  
D. `pip install cdo`  

```

```{solution} q-installation-4
B. `conda install -c conda-forge cdo`
```

```{exercise} Question 5: Which feature line in `cdo --version` output indicates GRIB2 support?
:label: q-installation-5

A. `GRIB2`  
B. `ECCODES`  
C. `GRIB`  
D. `GRIB_API`  

```

```{solution} q-installation-5
B. `ECCODES` (or `GRIB_API` in older versions)
```

## Summary

In this module, we covered:

- **System requirements**: CDO runs on Linux, macOS, and Windows (via WSL)
- **Package manager installation**:
  - Ubuntu/Debian: `sudo apt-get install cdo`
  - Fedora/CentOS: `sudo dnf install cdo`
  - macOS: `brew install cdo`
  - Windows: WSL + `sudo apt-get install cdo`
- **Conda installation**: `conda install -c conda-forge cdo`
- **Docker**: `docker pull joesfer/cdo`
- **Build from source**: For latest features and customization
- **Verification**: `cdo --version` and `cdo --help`
- **Supporting tools**: NCO (`ncdump`, `ncgen`, `ncks`), Python (xarray, netcdf4)
- **Environment variables**: `CDO_NTHREADS`, `CDO_TEMPDIR`, `CDO_MEMORY`
- **Troubleshooting**: Common issues and solutions

```{admonition} Key Points
:class: note
- Package manager installation is simplest for most users
- Conda provides cross-platform consistency and latest versions
- WSL is required for full CDO functionality on Windows
- Always verify compiled features after installation
- Set up environment variables for optimal performance
```

## References

- CDO Download Page: https://code.mpimet.mpg.de/projects/cdo/files
- Conda-Forge CDO: https://anaconda.org/conda-forge/cdo
- Docker CDO Image: https://hub.docker.com/r/joesfer/cdo
- WSL Installation Guide: https://docs.microsoft.com/en-us/windows/wsl/install
- NCO Toolkit: http://nco.sourceforge.net/
