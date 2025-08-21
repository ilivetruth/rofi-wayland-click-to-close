# Rofi Auto-Close on Wayland

This configuration adds click-to-exit functionality for rofi on Wayland/Hyprland, automatically closing rofi when you click outside its bounds.

## Dependencies

Make sure you have the following packages installed:

```bash
# Core dependencies
sudo pacman -S rofi slurp jq
```

## Files

- `launch-rofi-with-monitor.sh` - Main launcher script
- `rofi-slurp-monitor.sh` - Background monitor that detects clicks outside rofi

## How It Works

1. The launcher script starts the slurp monitor in the background
2. Rofi opens normally
3. Slurp creates an invisible overlay that covers the entire screen
4. When you click anywhere outside rofi's bounds, slurp detects the click
5. The monitor script automatically closes rofi

## Usage

### Method 1: Direct Command

```bash
cd ~/.config/rofi
./launch-rofi-with-monitor.sh
```

### Method 2: Hyprland Keybinding

Add this to your Hyprland config (`~/.config/hypr/hyprland.conf`):

```
bind = $mainMod, D, exec, ~/.config/rofi/launch-rofi-with-monitor.sh
```

Replace `$mainMod, D` with your preferred key combination.

### Method 3: Waybar Integration

Add this to your waybar config (`~/.config/waybar/config`):

```json
{
    "custom/rofi": {
        "format": "󱓩",
        "tooltip": false,
        "on-click": "~/.config/rofi/launch-rofi-with-monitor.sh"
    }
}
```

Then add `"custom/rofi"` to your waybar modules list.

## Customization

### Rofi Dimensions

The script automatically reads rofi dimensions from your theme files:
- Window size: `~/.config/rofi/config.rasi` (width/height in em)
- Font size: `~/.config/ml4w/settings/rofi-font.rasi`

If your rofi config is in a different location, update the paths in `rofi-slurp-monitor.sh`.

### Cursor Appearance

When the overlay is active, you'll see a crosshair cursor outside rofi's bounds. This is slurp's default behavior and indicates the click-to-exit mode is active. Inside rofi's bounds, you'll see your normal cursor.

## Troubleshooting

### Script doesn't work
- Ensure all dependencies are installed
- Check that the script files are executable: `chmod +x *.sh`
- Test rofi works normally: `rofi -show drun`

### Rofi doesn't close on click
- Check if slurp is working: run `slurp` manually
- Verify jq is parsing monitor info: `hyprctl monitors -j | jq`
- Check the console output when running the script manually

### Wrong dimensions
- Verify your rofi config paths in the script
- Test dimension parsing: `grep -A 20 "^window {" ~/.config/rofi/config.rasi`

## Known Limitations

1. **Cursor appearance**: Outside rofi bounds, you'll see a crosshair cursor instead of your system cursor. This is a limitation of slurp.

2. **Wayland only**: This solution is specific to Wayland compositors.

3. **Hyprland specific**: Some commands use `hyprctl` which is Hyprland-specific. For other Wayland compositors, the monitor detection would need adjustment.