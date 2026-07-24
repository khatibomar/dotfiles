#!/bin/bash

echo "Enabling experimental features in BlueZ for battery level display..."
sudo sed -i 's/#Experimental = false/Experimental = true/g' /etc/bluetooth/main.conf
sudo systemctl restart bluetooth
echo "Bluetooth battery level display enabled."
