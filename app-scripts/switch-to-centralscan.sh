#!/bin/bash

systemctl stop admin.service
systemctl disable admin.service

systemctl enable central-scan.service
systemctl start central-scan.service

