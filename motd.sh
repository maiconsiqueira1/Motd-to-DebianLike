#!/bin/bash

# Script to install Dynamic MOTD on Debian servers

# This version uses figlet

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or using sudo"
   exit 1
fi

if [ ! -f /etc/debian_version ] ; then
   echo "This script can run ONLY on Debian OS"
   exit 1
fi

# - lsb-release: get distro details (fallback)
apt-get install lsb-release -y

# Backup MOTD file
mv -f /etc/motd{,.ORIG}

# Symlink dynamic MOTD file
ln -s /var/run/motd /etc/motd

# Create dynamic motd environment
mkdir /etc/update-motd.d/
cd /etc/update-motd.d/

cat <<'EOF' > 00-header
#!/bin/sh
#
#    00-header - create the header of the MOTD
#
[ -r /etc/os-release ] && . /etc/os-release
OS=$PRETTY_NAME

if [ -z "$OS" ] && [ -x /usr/bin/lsb_release ]; then
        OS=$(lsb_release -s -d)
fi
printf "\n"
printf "\n"
echo "\e[1m Welcome to OPTEC Cloud Infrastructure \e[0m"
printf "\n"
printf "\n"
hostnamectl
printf "\n"
printf "\n"
printf "\t- %s\n\t- OS version %s\n\t- Kernel %s\n" "$OS" "$(cat /etc/debian_version)" "$(uname -r)"
printf "\n"
EOF

cat <<'EOF' > 10-sysinfo
#!/bin/bash
#
#    10-sysinfo - generate the system information
#
date=`date`
load=`cat /proc/loadavg | awk '{print $1}'`
root_usage=`df -h / | awk '/\// {print $(NF-1)}'`
home_usage=`df -h /home | awk '/\// {print $(NF-1)}'`
memory_usage=`free -m | awk 'NR==2{printf "%.2f%%\n", $3*100/$2 }'`
swap_usage=`free -m | awk '/Swap/ { printf("%3.1f%%", "exit !$2;$3/$2*100") }'`
users=`users | wc -w`
time=`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf $2" "$3 }'`
processes=`ps aux | wc -l`
ip=`ifconfig $(route -n | grep '^0.0.0.0' | awk '{ print $8 }') | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
printf "System information as of %s\n\n" "$date"
printf "IP Address:\t%s\tSystem uptime:\t%s\n" "$ip" "$time"
printf "System load:\t%s\tProcesses:\t%s\n" "$load" "$processes"
printf "RAM used:\t%s\tSwap used:\t%s\n" "$memory_usage" "$swap_usage"
printf "Usage on /:\t%s\tUsage on /home:\t%s\n" "$root_usage" "$home_usage"
printf "Local Users:\t%s\tProcesses:\t%s\n" "$users" "$processes"
printf "\n"
echo
printf "Your SSH key to remote access is /RSAKeys/$HOSTNAME/$USER/$USER@$HOSTNAME.pem" 
printf "\n"
echo
EOF


cat <<'EOF' > 90-footer
#!/bin/sh
#
#    90-footer - write the admin's footer to the MOTD
#
[ -f /etc/motd.tail ] && cat /etc/motd.tail || true
EOF


chmod +x /etc/update-motd.d/*

clear
echo "Installation completed. Please logout and login again to test."
