#!/usr/bin/env bash

systemctl --user mask pulseaudio.service
systemctl --user mask pulseaudio.socket
amixer sset Master 100% unmute
amixer -c0 sset Headphone 100% unmute
amixer -c0 sset Speaker 0% mute
echo "Done! Press enter to return to the menu"
