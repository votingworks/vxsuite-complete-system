# Check if syslog is a user. If not, add it
# TODO: 
if ! id syslog &> /dev/null; then
	sudo useradd -U -G adm,tty syslog
	sudo chown syslog:adm /var/spool/rsyslog
fi


# Good
sudo cp config/30-votingworks.conf /etc/rsyslog.d/30-votingworks.conf

sudo cp config/rsyslog.conf /etc/rsyslog.conf
sudo cp config/journald.conf /etc/systemd/journald.conf

sudo systemctl restart rsyslog
