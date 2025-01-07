#!/bin/bash

# Exit on any error
set -e

###############################################################################
# 0. Prerequisites:
#    1) You must already have a conda env "ocr" (or any name) with Python 3.10.
#    2) "conda activate ocr" must be done before running this script.
###############################################################################

# -----------------------------------------------------------------------------
# 1. Ensure Conda Environment is Active
# -----------------------------------------------------------------------------
if [ -z "$CONDA_PREFIX" ]; then
    echo "Error: CONDA_PREFIX is not set. Please activate your conda environment first."
    echo "  e.g. conda activate ocr"
    exit 1
fi

echo "Conda environment detected: $CONDA_PREFIX"

# -----------------------------------------------------------------------------
# 2. Optional: Install/Upgrade pip + Install NumPy in the conda environment
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Ensuring pip + NumPy are installed in $CONDA_PREFIX"
echo "------------------------------------"
"$CONDA_PREFIX/bin/python" -m pip install --upgrade pip
"$CONDA_PREFIX/bin/python" -m pip install --upgrade numpy

echo "** Checking that NumPy is recognized:"
"$CONDA_PREFIX/bin/python" -c "import numpy; print('NumPy found at:', numpy.__file__)"

# -----------------------------------------------------------------------------
# 3. Configuration Variables
# -----------------------------------------------------------------------------
VERSION="4.10.0"
WORKSPACE_DIR="opencv_build"
NUM_CORES=$(nproc)

# -----------------------------------------------------------------------------
# 4. Define Python Paths (executable, includes, library, site-packages)
# -----------------------------------------------------------------------------
env_python=$(which python)
env_sitepackages_dir=$($env_python -c "import site; print(site.getsitepackages()[0])")

PYTHON_VERSION=$($env_python -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
PYTHON_INCLUDE_DIR="$CONDA_PREFIX/include/python${PYTHON_VERSION}"
PYTHON_LIBRARY=$(find "$CONDA_PREFIX/lib" -name "libpython${PYTHON_VERSION}*.so" | head -n 1)

# Quick sanity check:
if [ -z "$PYTHON_LIBRARY" ]; then
    echo "Error: Could not find libpython*.so in $CONDA_PREFIX/lib."
    exit 1
fi

# -----------------------------------------------------------------------------
# 5. Print Validation Summary
# -----------------------------------------------------------------------------
clear
cat << EOF
Validation Summary:
-------------------
Python executable:          $env_python
Python include directory:   $PYTHON_INCLUDE_DIR
Python library:             $PYTHON_LIBRARY
Python site-packages dir:   $env_sitepackages_dir
Conda prefix:               $CONDA_PREFIX
EOF

while true; do
    echo "Are these environment variables correct? (yes/no)"
    read -r confirm
    if [ "$confirm" = "yes" ]; then
        break
    elif [ "$confirm" = "no" ]; then
        echo "Exiting script. Please correct the environment settings and try again."
        exit 1
    else
        echo "Please answer yes or no."
    fi
done

# -----------------------------------------------------------------------------
# 6. Prompt to Remove Existing OpenCV Installations
# -----------------------------------------------------------------------------
while true; do
    echo "Do you want to remove existing OpenCV installations (yes/no)?"
    read -r rm_old
    if [ "$rm_old" = "yes" ]; then
        echo "** Removing existing system-level OpenCV and pip-installed OpenCV packages..."
        sudo apt -y purge '*libopencv*' || true
        pip uninstall -y opencv-python opencv-contrib-python || true
        break
    elif [ "$rm_old" = "no" ]; then
        echo "** Skipping removal of existing OpenCV installations."
        break
    else
        echo "Please answer yes or no."
    fi
done

# -----------------------------------------------------------------------------
# 7. Install System Dependencies
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Installing system dependencies"
echo "------------------------------------"
sudo apt-get update
sudo apt-get install -y \
    gcc-10 \
    g++-10 \
    build-essential \
    cmake \
    git \
    pkg-config \
    yasm \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libxvidcore-dev \
    x264 \
    libx264-dev \
    libfaac-dev \
    libmp3lame-dev \
    libtheora-dev \
    libvorbis-dev \
    libdc1394-25 \
    libdc1394-dev \
    libxine2-dev \
    libv4l-dev \
    v4l-utils \
    curl \
    unzip

# -----------------------------------------------------------------------------
# 8. Create and Navigate to Workspace Directory
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Creating workspace directory: $WORKSPACE_DIR"
echo "------------------------------------"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# -----------------------------------------------------------------------------
# 9. Download OpenCV and OpenCV Contrib
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Downloading OpenCV and OpenCV Contrib v${VERSION}"
echo "------------------------------------"
wget -O "opencv.zip" "https://github.com/opencv/opencv/archive/refs/tags/${VERSION}.zip"
wget -O "opencv_contrib.zip" "https://github.com/opencv/opencv_contrib/archive/refs/tags/${VERSION}.zip"

# -----------------------------------------------------------------------------
# 10. Unzip OpenCV and OpenCV Contrib
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Unzipping OpenCV and OpenCV Contrib"
echo "------------------------------------"
unzip "opencv.zip"
unzip "opencv_contrib.zip"

# Remove the zip files after extraction
rm "opencv.zip" "opencv_contrib.zip"

# Verify unzipped dirs exist
if [ ! -d "opencv-${VERSION}" ]; then
    echo "Error: opencv-${VERSION} directory not found after unzipping."
    exit 1
fi
if [ ! -d "opencv_contrib-${VERSION}" ]; then
    echo "Error: opencv_contrib-${VERSION} directory not found after unzipping."
    exit 1
fi

# -----------------------------------------------------------------------------
# 11. Set Up Build Directory
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Setting up build directory"
echo "------------------------------------"
cd "opencv-${VERSION}"
rm -rf build
mkdir -p build
cd build
rm -f CMakeCache.txt  # remove old cache if any

# -----------------------------------------------------------------------------
# 12. Configure OpenCV with CMake
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Configuring OpenCV with CMake"
echo "------------------------------------"
cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D BUILD_opencv_python3=ON \
  -D PYTHON3_EXECUTABLE="$env_python" \
  -D PYTHON3_INCLUDE_DIR="$PYTHON_INCLUDE_DIR" \
  -D PYTHON3_LIBRARY="$PYTHON_LIBRARY" \
  -D PYTHON3_PACKAGES_PATH="$env_sitepackages_dir" \
  -D OPENCV_PYTHON_INSTALL_PATH="$env_sitepackages_dir" \
  -D CUDA_ARCH_BIN=8.9 \
  -D WITH_CUDA=ON \
  -D WITH_CUDNN=ON \
  -D OPENCV_DNN_CUDA=ON \
  -D ENABLE_FAST_MATH=1 \
  -D CUDA_FAST_MATH=1 \
  -D OPENCV_ENABLE_NONFREE=ON \
  -D WITH_CUBLAS=1 \
  -D WITH_V4L=ON \
  -D OPENCV_EXTRA_MODULES_PATH="../../opencv_contrib-${VERSION}/modules" \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_opencv_world=ON \
  -D ENABLE_PYTHON_LOADER=OFF \
  ..

# -----------------------------------------------------------------------------
# 13. Build OpenCV
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Building OpenCV (this may take a while)"
echo "------------------------------------"
make -j"$NUM_CORES"

# -----------------------------------------------------------------------------
# 14. Install OpenCV into Conda Environment
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Installing OpenCV into conda environment"
echo "------------------------------------"
make install

# -----------------------------------------------------------------------------
# 15. Verify Installation
# -----------------------------------------------------------------------------
echo "------------------------------------"
echo "** Verifying OpenCV installation"
echo "------------------------------------"
"$env_python" -c "import cv2; print(cv2.getBuildInformation())"

echo "------------------------------------"
echo "** OpenCV ${VERSION} successfully installed into $CONDA_PREFIX"
echo "** To verify again later, run within your conda environment:"
echo "   python -c 'import cv2; print(cv2.getBuildInformation())'"
echo "------------------------------------"
echo "** Bye :)"
