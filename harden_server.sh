#!/bin/bash

# Update and upgrade system packages
apt update
apt upgrade -y

# Install essential security tools
apt install -y ufw fail2ban

# Configure firewall (UFW)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp
ufw allow 80/tcp # Allow HTTP
ufw allow 443/tcp # Allow HTTPS
ufw enable

# Enable and configure Fail2Ban
systemctl enable fail2ban
cp /etc/fail2ban/jail.{conf,local}
echo "[sshd]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local

# Secure SSH configuration
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Remove unnecessary packages
apt autoremove -y

# Disable unused services
systemctl disable apache2 # If not needed
systemctl disable mysql # If not needed

# Secure user accounts
passwd -l root # Lock the root account

# Configure automatic security updates
apt install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# Set strong password policy
apt install -y libpam-pwquality
sed -i 's/password requisite pam_pwquality.so retry=3/password requisite pam_pwquality.so retry=3 minlen=12 minclass=2 minclassrepeat=3 maxrepeat=3/' /etc/security/pwquality.conf
sed -i 's/password requisite pam_unix.so sha512/password requisite pam_unix.so sha512 minlen=8 remember=5/' /etc/pam.d/common-password

# Disable guest account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf.d/50-no-guest.conf

# Remove unnecessary SUID/SGID binaries
find / -type f \( -perm -4000 -o -perm -2000 \) -exec chmod ug-s {} \;

# Harden sysctl settings (you can adjust these based on your needs)
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 2048" >> /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syn_retries = 5" >> /etc/sysctl.conf
sysctl -p

# Harden cron jobs
chmod 750 /etc/crontab
chmod 750 /etc/cron.hourly
chmod 750 /etc/cron.daily
chmod 750 /etc/cron.weekly
chmod 750 /etc/cron.monthly
chmod 750 /etc/cron.d

# Enable and start necessary services
systemctl enable ufw
systemctl enable fail2ban

# Restart services
systemctl restart ufw
systemctl restart fail2ban

# Reboot the system
reboot
