# Check if apt is available on the system
if command -v apt >/dev/null 2>&1; then
	echo "apt package manager detected. Likely an Ubuntu or Debian-based system."

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
elif command -v dnf >/dev/null 2>&1; then
	echo "dnf package manager detected. Likely a Fedora system."

	# Uninstall old versions if they exist
	echo "Removing old Docker versions if they exist..."
	sudo dnf remove -y docker \
		docker-client \
		docker-client-latest \
		docker-common \
		docker-latest \
		docker-latest-logrotate \
		docker-logrotate \
		docker-selinux \
		docker-engine-selinux \
		docker-engine

	# Install required packages
	echo "Installing required packages..."
	sudo dnf -y install dnf-plugins-core

	# Add Docker repository
	echo "Adding Docker repository..."
	sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

	# Install Docker Engine and related packages
	echo "Installing Docker Engine and related packages..."
	sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	# Create docker group if it doesn't exist
	sudo groupadd docker 2>/dev/null || true

	# Add current user to docker group
	echo "Adding current user to docker group..."
	sudo usermod -aG docker $USER

	# Start and enable Docker service
	echo "Starting and enabling Docker service..."
	sudo systemctl enable --now docker

	# Verify the installation
	echo "Verifying Docker installation..."
	docker --version

	# Run hello-world container to test the installation
	echo "Testing Docker installation with hello-world container..."
	sudo docker run hello-world

	echo "Docker installation complete! You may need to log out and back in for group changes to take effect."
else
	echo "Neither apt nor dnf package managers found. This is not an Ubuntu/Debian or Fedora system."
	echo "consider modifying the script to work with your package manager."
fi
