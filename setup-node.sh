# node and npm and yarn
# https://github.com/nodesource/distributions/blob/master/README.md#debmanual
NODE_VERSION=node_12.x

curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
DISTRO="$(lsb_release -s -c)"
echo "deb https://deb.nodesource.com/${NODE_VERSION} ${DISTRO} main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/${NODE_VERSION} ${DISTRO} main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

sudo apt update
sudo apt install -y nodejs

sudo npm install -g yarn

