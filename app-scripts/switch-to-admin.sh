#!/bin/bash

sudo systemctl stop central-scan.service
sudo systemctl disable central-scan.service

sudo systemctl enable admin.service
sudo systemctl start admin.service


