# syntax=docker/dockerfile:latest
#
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
RUN touch /etc/environment && chmod 644 /etc/environment

# Install Base Package
RUN sed -i 's/archive.ubuntu.com/kartolo.sby.datautama.net.id/g' /etc/apt/sources.list
RUN sed -i 's/security.ubuntu.com/kartolo.sby.datautama.net.id/g' /etc/apt/sources.list
RUN apt -y update
RUN apt -y install sudo nano wget curl lsb-release dos2unix locales net-tools tzdata chrony cron
RUN apt -y install make gcc apt-transport-https ca-certificates software-properties-common systemd 
RUN apt -y install htop git screen socat rsyslog python

# Run Single Script
ADD /source/service/install-openssh-server /opt/install-openssh-server
RUN chmod +x /opt/install-openssh-server && dos2unix /opt/install-openssh-server && sh -c /opt/install-openssh-server && rm -rf /opt/install-openssh-server
ADD /source/service/install-dropbear /opt/install-dropbear
RUN chmod +x /opt/install-dropbear && dos2unix /opt/install-dropbear && sh -c /opt/install-dropbear && rm -rf /opt/install-dropbear
ADD /source/service/install-stunnel /opt/install-stunnel
RUN chmod +x /opt/install-stunnel && dos2unix /opt/install-stunnel && sh -c /opt/install-stunnel && rm -rf /opt/install-stunnel
ADD /source/service/install-trojan /opt/install-trojan
RUN chmod +x /opt/install-trojan && dos2unix /opt/install-trojan && sh -c /opt/install-trojan && rm -rf /opt/install-trojan
ADD /source/service/install-vnstat /opt/install-vnstat
RUN chmod +x /opt/install-vnstat && dos2unix /opt/install-vnstat && sh -c /opt/install-vnstat && rm -rf /opt/install-vnstat
ADD /source/service/install-badvpn /opt/install-badvpn
RUN chmod +x /opt/install-badvpn && dos2unix /opt/install-badvpn && sh -c /opt/install-badvpn && rm -rf /opt/install-badvpn

# Import Application Data
ADD /source/config/trojan/config.json /etc/trojan/config.json
ADD /source/config/trojan/uuid.txt /etc/trojan/uuid.txt
ADD /source/service/trojan.service /etc/systemd/system/trojan.service
RUN chmod 644 /etc/systemd/system/trojan.service
RUN touch /etc/trojan/akun.conf && touch /tmp/iptrojan.txt
RUN find /etc/trojan/ -type f -print0 | xargs -0 dos2unix
RUN find /etc/trojan/ -type f -print0 | xargs -0 chmod +x

# Container Source [RC-LOCAL]
ADD /source/service/rc-local.service /etc/systemd/system/rc-local.service
ADD /source/config/rc.local /etc/rc.local
RUN chmod 644 /etc/systemd/system/rc-local.service
RUN dos2unix /etc/rc.local
RUN chmod 750 /etc/rc.local
RUN systemctl enable rc-local

# Import Script
ADD /source/script /usr/local/bin
RUN find /usr/local/bin -type f -print0 | xargs -0 dos2unix
RUN find /usr/local/bin -type f -print0 | xargs -0 chmod 750

# Import Certificate
ADD /source/certificate /opt/certificate
RUN find /opt/certificate -type f -print0 | xargs -0 dos2unix
RUN find /opt/certificate -type f -print0 | xargs -0 chmod 750

# banner /etc/issue.net
RUN echo "Premium Server By OpenSVH - Contact @ wa.me/6281317971329" > /etc/issue.net
RUN echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
RUN sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear

# Create Cron
RUN echo "# Auto Restart Job" > /etc/cron.d/auto-restart
RUN echo "0 0 * * * root /usr/local/bin/auto-restart" >> /etc/cron.d/auto-restart
RUN echo "# Auto Clear Memory" > /etc/cron.d/memory-clear
RUN echo "0 0 * * * root /usr/local/bin/memory-clear" >> /etc/cron.d/memory-clear
RUN echo "# Auto Expire Account" > /etc/cron.d/auto-expire
RUN echo "0 0 * * * root /usr/local/bin/auto-expire" >> /etc/cron.d/auto-expire
RUN echo "# Auto Kill Job" > /etc/cron.d/auto-kill
RUN echo "*/1 * * * * root /usr/local/bin/kick-ssh 2" >> /etc/cron.d/auto-kill

# Fix bug tty
RUN cp /bin/true /sbin/agetty

# Container Environment
EXPOSE 22/tcp 80/tcp 443/tcp
LABEL maintainer="Andika Muhammad Cahya <andkmc99@gmail.com>"
CMD ["/lib/systemd/systemd"]
VOLUME [ "/sys/fs/cgroup" ]
WORKDIR /root