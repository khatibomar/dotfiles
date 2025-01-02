# Check if apt is available on the system
if command -v apt >/dev/null 2>&1; then
  echo "apt package manager detected. Likely an Ubuntu or Debian-based system."
  # Execute your script or command here
  ./your_script.sh

  # Install required packages
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg

  # Add Docker's official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the Docker repository with the correct Ubuntu code name
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  jammy stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # Update the package index
  sudo apt-get update

  # Install Docker
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Add the current user to the docker group
  sudo groupadd docker

  # Add the current user to the docker group
  sudo usermod -aG docker $USER

  # Restart the Docker service
  sudo systemctl restart docker

  # Verify the installation
  docker --version
else
  echo "apt package manager not found. This is not an Ubuntu or Debian-based system."
  echo "consider modifying the script to work with your package manager."
fi
