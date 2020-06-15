#!/bin/bash

sudo cp config/vx-election-manager.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/vx-election-manager.service
sudo systemctl enable vx-election-manager.service
sudo systemctl start vx-election-manager.service


