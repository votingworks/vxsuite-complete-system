#!/usr/bin/env bash

set -euo pipefail

sudo tpm2-totp clean || true
sudo tpm2-totp --pcrs=0,2,4,5,7 init