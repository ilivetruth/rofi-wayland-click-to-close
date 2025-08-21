#!/bin/bash

# Launch rofi with auto-close monitoring

# Start the slurp monitor in the background
~/.config/rofi/rofi-slurp-monitor.sh &

# Small delay to ensure monitor starts
sleep 0.2

# Launch rofi
rofi -show drun -replace