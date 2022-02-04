#!/bin/bash

set -euo pipefail

# save current directory
INSTALL_DIR=$(pwd)

mkdir -p /tmp/vx
cd /tmp/vx

# Festival and Speech Dispatcher
sudo apt install -y festival speech-dispatcher speech-dispatcher-festival festvox-us-slt-hts
wget http://www.speech.cs.cmu.edu/cmu_arctic/packed/cmu_us_slt_arctic-0.95-release.tar.bz2
bunzip2 cmu_us_slt_arctic-0.95-release.tar.bz2
tar xf cmu_us_slt_arctic-0.95-release.tar

if [[ $DISTRO == "Debian" ]]; then
	sudo mkdir -p /usr/share/festival/voices/us/
	sudo mv cmu_us_slt_arctic /usr/share/festival/voices/us/cmu_us_slt_arctic_clunits
else
	sudo mkdir -p /usr/share/festival/voices/english/
	sudo mv cmu_us_slt_arctic /usr/share/festival/voices/english/cmu_us_slt_arctic_clunits
fi

# done with downloaded files
cd "$INSTALL_DIR"
rm -rf /tmp/vx

# set up festival voice
sudo cp config/speechd.conf /etc/speech-dispatcher/
#sudo systemctl restart speech-dispatcher

# festival auto-start
sudo cp config/vx-festival.service /etc/systemd/system/
sudo systemctl enable vx-festival
sudo systemctl start vx-festival
