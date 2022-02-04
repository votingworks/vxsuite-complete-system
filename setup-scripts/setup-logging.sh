# Check if syslog is a user. If not, add it
if ! id syslog &> /dev/null; then
	sudo useradd -U -G adm,tty syslog
	sudo chown syslog:adm /var/spool/rsyslog
	sudo chown syslog:adm /var/log/syslog
	sudo chown :adm /var/log
	sudo chmod 775 /var/log
fi


ver="$(lsb_release -sr)"
if [[ $ver == 18* ]] ;
then
  sudo add-apt-repository -y ppa:adiscon/v8-devel
  sudo apt-get update
  sudo apt-get install -y rsyslog
fi

sudo cp config/30-votingworks.conf /etc/rsyslog.d/30-votingworks.conf

sudo cp config/rsyslog.conf /etc/rsyslog.conf
sudo cp config/journald.conf /etc/systemd/journald.conf

sudo systemctl restart rsyslog
