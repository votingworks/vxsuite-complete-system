#!/usr/bin/env bash

trap '' SIGINT SIGTSTP SIGQUIT

set -euo pipefail

sudo tpm2-totp clean 2>/dev/null || true
sudo tpm2-totp --pcrs=0,2,4,5,7 init
