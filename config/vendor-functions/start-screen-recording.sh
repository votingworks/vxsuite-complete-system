#!/usr/bin/env bash

set -euo pipefail

USER="vx-ui" # Since we want to record the tty1 screen we have to act as the vx-ui user

echo "Starting to record the screen, when you are done with your recording press Q to exit"
sleep 1
RECORDING_DIR=/var/vx/ui/screen-recordings

sudo su $USER -c "mkdir -p $RECORDING_DIR"

FILENAME="recording-$(date '+%Y-%m-%d-%H-%M-%S').mp4"
OUTPUT_FILE="$RECORDING_DIR/$FILENAME"

sudo su $USER -c "ffmpeg -f x11grab -framerate 25 -i :0.0 -preset fast $OUTPUT_FILE"
