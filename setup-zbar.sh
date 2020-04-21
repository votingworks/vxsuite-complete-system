sudo apt install -y autoconf imagemagick libmagick-dev gtk+2.0

# may need to run this from the right location to get the zbar library
# from https://github.com/votingworks/zbar
cd zbar
autoreconf -f -i
./configure --without-python
make
sudo make install

# add the shared libraries for it
sudo echo -e "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
sudo ldconfig
