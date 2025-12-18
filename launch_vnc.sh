#!/bin/bash
set -e

# Use the env var from Docker if possible, otherwise fallback
export USER=${USER_NAME:-juanpa}
export HOME=/home/$USER
export XDG_RUNTIME_DIR=/tmp/runtime-$USER

# 1. Cleanup old sockets
rm -f $XDG_RUNTIME_DIR/wayland-*

# 2. Start Weston (Headless Backend)
# This acts as the "Hardware" for Niri
weston --backend=headless-backend.so --socket=wayland-1 --width=1280 --height=720 &
while [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; do sleep 0.2; done

# 3. Start Niri
# We point Niri to use Weston as its display
export WAYLAND_DISPLAY=wayland-1
# WLR_RENDERER=pixman is the correct flag for wlroots-based compositors to force software
export WLR_RENDERER=pixman 
export NIRI_RENDERER=pixman

niri &

# 4. Wait for Niri to create its own socket (wayland-2)
echo "Waiting for Niri socket..."
while [ ! -S "$XDG_RUNTIME_DIR/wayland-2" ]; do sleep 0.2; done

# 5. Start WayVNC
# IMPORTANT: WayVNC needs to be on the Niri socket (wayland-2)
export WAYLAND_DISPLAY=wayland-2

echo "Starting WayVNC..."
# Add --output to specify which virtual screen to grab
wayvnc 0.0.0.0 5900 &

# --- ADD THIS PART ---
echo "Launching test terminal..."
# Give Niri a second to fully map the output
sleep 2
kitty -e fish & 
# --------------------

wait