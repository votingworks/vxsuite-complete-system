#!/bin/bash

# Various files and directories to clean up during
# VM shutdown in the build process
/usr/bin/find /home/vx -mindepth 1 -delete
/usr/bin/rm -f /var/log/*.log
/usr/bin/rm -f /var/log/syslog
/usr/bin/rm -f /var/log/votingworks/*
/usr/bin/systemctl disable vx-cleanup.service

exit 0
