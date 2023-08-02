set -euo pipefail

export PATH="${PATH}:/sbin/"

if hostnamectl status | grep 'Virtualization: parallels'; then
	echo 'Skipping TPM2 setup on Parallels VMs'
        exit 0	
fi

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
