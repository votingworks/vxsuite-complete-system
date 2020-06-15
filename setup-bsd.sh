#!/bin/bash

sudo cp config/vx-bsd.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/vx-bsd.service
sudo systemctl enable vx-bsd.service
sudo systemctl start vx-bsd.service


