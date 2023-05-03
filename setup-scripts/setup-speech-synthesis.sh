#!/bin/bash

set -euo pipefail

# save current directory
INSTALL_DIR=$(pwd)

mkdir -p /tmp/vx
cd /tmp/vx

# Download anc install mimic3
wget https://github.com/MycroftAI/mimic3/releases/download/release%2Fv0.2.4/mycroft-mimic3-tts_0.2.4_amd64.deb
sudo apt install -y ./mycroft-mimic3-tts_0.2.4_amd64.deb

# done with manually downloaded files
cd "$INSTALL_DIR"
rm -rf /tmp/vx

# Install speech dispatcher
sudo apt install -y speech-dispatcher

# Download the voice we want
VOICESDIR=/usr/share/mycroft/mimic3/voices/
sudo mkdir -p $VOICESDIR
sudo mimic3-download --output-dir $VOICESDIR en_US/m-ailabs_low

# configure speech dispatcher
sudo cp config/speechd.conf /etc/speech-dispatcher/
sudo cp config/mimic3-generic.conf /etc/speech-dispatcher/modules/

# mimic3 auto-start
sudo cp config/vx-mimic3.service /etc/systemd/system/
sudo systemctl enable vx-mimic3
sudo systemctl start vx-mimic3
