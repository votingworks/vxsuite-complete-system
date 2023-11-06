# Check if syslog is a user. If not, add it
if ! id syslog &> /dev/null; then
	sudo useradd -U -G adm,tty syslog
	sudo chown syslog:adm /var/spool/rsyslog
	sudo chown syslog:adm /var/log/syslog
	sudo chown :adm /var/log
	sudo chmod 775 /var/log
fi

sudo cp config/30-votingworks.conf /etc/rsyslog.d/30-votingworks.conf
sudo cp config/rsyslog.conf /etc/rsyslog.conf
#sudo cp config/journald.conf /etc/systemd/journald.conf

sudo systemctl restart rsyslog
