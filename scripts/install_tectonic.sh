#!/usr/bin/env bash

literal_name_of_installation_directory=".tarball-installations"
general_installation_directory="$HOME/$literal_name_of_installation_directory"
local_bin_path="$HOME/.local/bin"
app_name=tectonic
app_installation_directory="$general_installation_directory/$app_name"
app_bin_in_local_bin="$local_bin_path/$app_name"

# Cleanup previous installations
echo "=== Cleaning previous installations ==="
[ -L "$app_bin_in_local_bin" ] && rm -v "$app_bin_in_local_bin"
[ -d "$app_installation_directory" ] && rm -rfv "$app_installation_directory"

# Create directories
mkdir -p "$general_installation_directory" || exit 1
mkdir -p "$local_bin_path" || exit 1

# Get latest release
echo "=== Fetching latest release ==="
api_url="https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest"
api_response=$(curl -sL "$api_url") || {
	echo "API request failed"
	exit 1
}

latest_tag=$(echo "$api_response" | grep '"tag_name":' | cut -d '"' -f 4)
[ -z "$latest_tag" ] && {
	echo "Failed to get tag name"
	exit 1
}

# Get architecture
arch=$(uname -m)
case "$arch" in
x86_64) target_arch="x86_64-unknown-linux-gnu" ;;
aarch64) target_arch="aarch64-unknown-linux-gnu" ;;
*)
	echo "Unsupported architecture: $arch"
	exit 1
	;;
esac

# Construct URL (direct binary download)
version=${latest_tag#tectonic@}
tarball_url="https://github.com/tectonic-typesetting/tectonic/releases/download/${latest_tag}/tectonic-${version}-${target_arch}.tar.gz"
echo "Download URL: $tarball_url"

# Download with integrity check
echo "=== Downloading tarball ==="
temp_tar=$(mktemp /tmp/tectonic.XXXXXX.tar.gz)
if ! curl -# -L "$tarball_url" -o "$temp_tar"; then
	echo "Download failed"
	rm -f "$temp_tar"
	exit 1
fi

# Validate tarball
echo "=== Validating tarball ==="
if ! tar -tf "$temp_tar" >/dev/null 2>&1; then
	echo "Invalid tarball! First 200 bytes:"
	head -c 200 "$temp_tar"
	echo -e "\nFile info:"
	file "$temp_tar"
	rm -f "$temp_tar"
	exit 1
fi

# Extract without stripping components
echo "=== Extracting files ==="
mkdir -p "$app_installation_directory"
echo "Tarball contents:"
tar -tf "$temp_tar"

if ! tar -xvf "$temp_tar" -C "$app_installation_directory"; then
	echo "Extraction failed!"
	rm -rf "$app_installation_directory"
	exit 1
fi

# Verify installation
echo "=== Verifying installation ==="
if [ ! -f "$app_installation_directory/tectonic" ]; then # Changed path
	echo "Installation failed! Directory contents:"
	ls -la "$app_installation_directory"
	exit 1
fi

# Create symlink
ln -sfv "$app_installation_directory/tectonic" "$app_bin_in_local_bin" # Updated path

# Final check
echo -e "\n=== Installation Summary ==="
echo "Binary location: $(readlink -f "$app_bin_in_local_bin")"
echo "Installed version: $("$app_installation_directory/tectonic" --version)"

# Cleanup
rm -v "$temp_tar"
