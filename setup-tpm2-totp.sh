
sudo apt -y install build-essential autoconf autoconf-archive automake m4 libtool gcc pkg-config libqrencode-dev pandoc doxygen liboath-dev iproute2 plymouth libplymouth-dev libssl-dev libjson-c-dev libcurl4-openssl-dev

mkdir ./tpm2-totp
cd tpm2-totp

git clone https://github.com/tpm2-software/tpm2-tss
cd tpm2-tss
./bootstrap
./configure
make 
sudo make install
cd ..

git clone https://github.com/tpm2-software/tpm2-totp
cd tpm2-totp
./bootstrap
./configure
make
sudo make install

sudo ldconfig

sudo tpm2-totp --pcrs=0,7 init

cd ../

rm -rf tpm2-tss tpm2-totp


