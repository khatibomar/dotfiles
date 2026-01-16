#!/bin/bash

SCRIPT_DIR="$(dirname "$0")/backup-scripts"

main_menu() {
	while true; do
		echo ""
		echo "===== Setup Menu ====="
		echo "1) Launch Fedora Apps Installation Menu"
		echo "2) Backup & copy Neovim configuration"
		echo "3) Backup & copy general Config"
		echo "4) Backup & copy Scripts"
		echo "5) Import GPG keys"
		echo "6) Import SSH keys"
		echo "7) Install OpenCode AI Assistant"
		echo "8) Run ALL steps"
		echo "0) Exit"
		echo "======================"
		echo ""

		read -rp "Choose an option: " choice
		echo ""

		case $choice in
		1)
			echo "Launching Fedora Apps Installation menu..."
			# Source the apps installer so its `main` function is available
			source ./scripts/install_apps.sh
			main # call the function defined in install_apps.sh
			;;
		2) bash "$SCRIPT_DIR/install_nvim.sh" ;;
		3) bash "$SCRIPT_DIR/install_config.sh" ;;
		4) bash "$SCRIPT_DIR/install_scripts.sh" ;;
		5) bash "$SCRIPT_DIR/import_gpg_keys.sh" ;;
		6) bash "$SCRIPT_DIR/import_ssh_keys.sh" ;;
		7) bash ./scripts/install_opencode.sh ;;
		8)
			echo "Running ALL steps..."
			source ./scripts/install_apps.sh
			main
			bash "$SCRIPT_DIR/install_nvim.sh"
			bash "$SCRIPT_DIR/install_config.sh"
			bash "$SCRIPT_DIR/install_scripts.sh"
			bash "$SCRIPT_DIR/import_gpg_keys.sh"
			bash "$SCRIPT_DIR/import_ssh_keys.sh"
			bash ./scripts/install_opencode.sh
			;;
		0)
			echo "Exiting..."
			break
			;;
		*) echo "Invalid option, please try again." ;;
		esac
	done

	echo ""
	echo "===== Installation Complete ====="
	echo "Restart your terminal or run: source ~/.zshrc"
	echo "================================"
}

main_menu
