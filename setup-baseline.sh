#!/bin/bash
#
# install the full Vx environment
#

# save current directory
INSTALL_DIR=$(pwd)

sudo apt install -y make unclutter mingetty emacs curl pmount python3-pip

source ./setup-node.sh

# TODO: move this to one of the individual makefiles, but for now this is easier
python3 -m pip install pipenv

