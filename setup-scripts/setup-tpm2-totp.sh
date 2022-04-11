set -euo pipefail

if hostnamectl status | grep 'Virtualization: parallels'; then
	echo 'Skipping TPM2 setup on Parallels VMs'
        exit 0	
fi

# install core dependencies
sudo apt -y install build-essential autoconf autoconf-archive automake m4 libtool gcc pkg-config libqrencode-dev libssl-dev libjson-c-dev libcurl4-openssl-dev

(
    cd tpm2-software/tpm2-tss
    ./bootstrap
    ./configure
    make  -j
    sudo make install
)

(
    cd tpm2-software/tpm2-totp
    ./bootstrap
    ./configure
    make
    sudo make install
)

# reindex shared objects
# TODO is this necessary if we're not setting up TOTP until after a reboot?
sudo ldconfig
