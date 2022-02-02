# Check if syslog is a user. If not, add it
# TODO: 
id -u syslog  &> /dev/null || sudo useradd -u 104 -U -G adm,tty syslog 

# Good
sudo cp config/30-votingworks.conf /etc/rsyslog.d/30-votingworks.conf

sudo cp config/rsyslog.conf /etc/rsyslog.conf
sudo cp config/journald.conf /etc/systemd/journald.conf

sudo systemctl restart rsyslog
