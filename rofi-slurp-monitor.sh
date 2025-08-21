#!/bin/bash

# Use slurp to create invisible overlay for click detection

get_rofi_dimensions() {
    local font_line=$(grep -o "font:.*[0-9]\+" ~/.config/ml4w/settings/rofi-font.rasi | grep -o "[0-9]\+")
    local font_size=${font_line:-16}
    
    local width_em=$(grep -A 20 "^window {" ~/.config/rofi/config.rasi | grep "width:" | grep -o '[0-9]\+' | head -1)
    local height_em=$(grep -A 20 "^window {" ~/.config/rofi/config.rasi | grep "height:" | grep -o '[0-9]\+' | head -1)
    
    local width_px=$((${width_em:-56} * font_size))
    local height_px=$((${height_em:-35} * font_size))
    
    echo "$width_px $height_px"
}

monitor_rofi_with_slurp() {
    local rofi_pid
    
    # Wait for rofi to start
    while ! rofi_pid=$(pgrep -x rofi); do
        sleep 0.01
    done
    
    echo "=== DEBUG: Monitoring rofi PID: $rofi_pid ==="
    
    # Get screen and rofi dimensions
    local screen_info=$(hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height)"' 2>/dev/null)
    read -r screen_w screen_h <<< "$screen_info"
    
    read -r rofi_width rofi_height <<< "$(get_rofi_dimensions)"
    local rofi_x=$(( (screen_w - rofi_width) / 2 ))
    local rofi_y=$(( (screen_h - rofi_height) / 2 ))
    
    echo "DEBUG: Screen: ${screen_w}x${screen_h}"
    echo "DEBUG: Rofi bounds: ${rofi_x},${rofi_y} ${rofi_width}x${rofi_height}"
    
    # Check initial cursor position
    local initial_cursor=$(hyprctl cursorpos 2>/dev/null)
    echo "DEBUG: Initial cursor position: $initial_cursor"
    
    # Get current cursor theme from GTK settings (which Hyprland uses)
    local cursor_info=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
    local cursor_size=$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)
    
    # Fallback to default if not found
    cursor_info=${cursor_info:-"default"}
    cursor_size=${cursor_size:-24}
    
    echo "Using cursor theme: $cursor_info, size: $cursor_size"
    
    # Simple slurp overlay - no cursor manipulation during setup
    XCURSOR_THEME="$cursor_info" XCURSOR_SIZE="$cursor_size" slurp -b '#00000000' -c '#00000000' -s '#00000000' >/dev/null 2>&1 &
    local slurp_pid=$!
    
    # AFTER everything is set up, move cursor to screen center
    # Start ydotool daemon if not running
    if ! pgrep -x ydotoold >/dev/null; then
        ydotoold &
        sleep 0.3
    fi
    
    # Move cursor to absolute center of screen based on resolution
    local screen_center_x=$((screen_w / 2))  # 1920/2 = 960
    local screen_center_y=$((screen_h / 2))  # 1080/2 = 540
    
    # Scale to ydotool coordinate system - need to find the right scaling
    # We know 960,540 screen center should map to ydotool coords that put cursor at exact screen center
    local ydotool_x=$((screen_center_x * 470 / 960))  # Adjust based on your feedback
    local ydotool_y=$((screen_center_y * 260 / 540))  # Adjust based on your feedback
    
    ydotool mousemove --absolute -x "$ydotool_x" -y "$ydotool_y" 2>/dev/null
    
    # Monitor both rofi and slurp processes
    while true; do
        # Check if rofi is still running
        if ! kill -0 "$rofi_pid" 2>/dev/null; then
            echo "Rofi closed naturally, killing slurp"
            kill "$slurp_pid" 2>/dev/null
            break
        fi
        
        # Check if slurp is still running (user interaction)
        if ! kill -0 "$slurp_pid" 2>/dev/null; then
            echo "Slurp interaction detected, closing rofi"
            kill "$rofi_pid" 2>/dev/null
            break
        fi
        
        sleep 0.1
    done
}

monitor_rofi_with_slurp