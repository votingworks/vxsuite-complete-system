set -euo pipefail

# install core dependencies
sudo apt -y install build-essential autoconf autoconf-archive automake m4 libtool gcc pkg-config libqrencode-dev plymouth libplymouth-dev libssl-dev libjson-c-dev libcurl4-openssl-dev

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

# clear out any preexisting TPM-bound TOTP
sudo tpm2-totp clean

# initialize the TOTP code, which will display the QR code with the secret.
sudo tpm2-totp --pcrs=0,7 init



