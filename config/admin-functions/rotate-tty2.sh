#!/usr/bin/env bash

# Requires sudo

set -euo pipefail

echo 3 | tee -a /sys/class/graphics/fbcon/rotate
