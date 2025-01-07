#!/usr/bin/env bash
# install_docker.sh - Install Docker on Ubuntu for either x86_64 or ARM64.
#                     If an NVIDIA GPU is detected, also install nvidia-docker.

set -e

# Function to prompt or parse the architecture
get_arch_choice() {
  local arch_choice="$1"

  # If the user didn't provide an argument, prompt interactively
  if [[ -z "$arch_choice" ]]; then
    echo "Select architecture to install Docker for:"
    echo "  1) x86_64"
    echo "  2) arm64"
    read -rp "Enter choice [1 or 2]: " choice
    case "$choice" in
      1) arch_choice="x86_64" ;;
      2) arch_choice="arm64" ;;
      *) 
        echo "Invalid choice. Please rerun and select either 1 or 2."
        exit 1
        ;;
    esac
  fi

  # Validate the choice if provided as command-line argument
  case "$arch_choice" in
    "x86_64" | "amd64")
      arch_choice="amd64"
      ;;
    "arm64")
      ;;
    *)
      echo "Invalid architecture: $arch_choice"
      echo "Valid options: x86_64, arm64"
      exit 1
      ;;
  esac

  echo "$arch_choice"
}

# Function to install Docker
install_docker() {
  local arch="$1"

  echo "Uninstalling any old versions of Docker..."
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

  echo "Installing required packages..."
  sudo apt-get update -y
  sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common

  echo "Adding Docker’s official GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo "Setting up the Docker repository for architecture: $arch"
  echo \
    "deb [arch=$arch signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  echo "Updating apt package index..."
  sudo apt-get update -y

  echo "Installing Docker Engine, CLI, and Containerd..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  echo "Docker has been installed successfully!"
  echo "Enabling Docker service to start on boot..."
  sudo systemctl enable docker
  echo "Starting Docker service..."
  sudo systemctl start docker
}

# Function to install nvidia-docker2 if NVIDIA GPU is present
install_nvidia_docker() {
  echo "Checking for NVIDIA GPU via nvidia-smi..."
  if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected. Installing nvidia-docker2..."

    # Add the package repositories
    distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list \
      | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update -y
    sudo apt-get install -y nvidia-docker2

    echo "Restarting Docker..."
    sudo systemctl restart docker

    echo "nvidia-docker2 installation completed!"
  else
    echo "No NVIDIA GPU detected (nvidia-smi not found)."
    echo "Skipping nvidia-docker2 installation."
  fi
}

main() {
  # 1) Get the architecture choice
  ARCH=$(get_arch_choice "$1")

  # 2) Install Docker
  install_docker "$ARCH"

  # 3) If NVIDIA GPU is found, install NVIDIA Docker
  install_nvidia_docker

  echo "All done!"
}

main "$@"

