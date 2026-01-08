#!/bin/bash
sudo cp config/30-votingworks.conf /etc/rsyslog.d/30-votingworks.conf
sudo cp config/rsyslog.conf /etc/rsyslog.conf
sudo cp config/journald.conf /etc/systemd/journald.conf

# Truncate existing log files so build operations are not
# part of production use
for file in mail.log kern.log user.log cron.log syslog auth.log
do
  sudo sh -c "cat /dev/null > /var/log/votingworks/${file}"
  sudo chown syslog:adm /var/log/votingworks/${file}
done

sudo systemctl restart rsyslog
