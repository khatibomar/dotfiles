#!/bin/bash

# Print basic colors (0-7)
echo "Basic Colors (0-7):"
for i in {0..7}; do
	printf "\e[3${i}mColor ${i}\e[0m  "
done
echo -e "\n"

# Print bright colors (8-15)
echo "Bright Colors (8-15):"
for i in {0..7}; do
	printf "\e[3${i};1mColor $((i + 8))\e[0m  "
done
echo -e "\n"

# Print 256 colors
echo "256 Colors:"
for i in {0..255}; do
	printf "\e[38;5;${i}mColor ${i}\e[0m "
	# Break line after every 16 colors for better readability
	if (((i + 1) % 16 == 0)); then
		echo
	fi
done
echo
