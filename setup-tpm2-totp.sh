set -euo pipefail

# install core dependencies
sudo apt -y install build-essential autoconf autoconf-archive automake m4 libtool gcc pkg-config libqrencode-dev pandoc doxygen liboath-dev iproute2 plymouth libplymouth-dev libssl-dev libjson-c-dev libcurl4-openssl-dev

(
    cd tpm2-software/tpm2-tss
    ./bootstrap
    ./configure
    make 
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
sudo ldconfig

# initialize the TOTP code, which will display the QR code with the secret.
sudo tpm2-totp --pcrs=0,7 init



