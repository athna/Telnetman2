#!/usr/bin/sh

#
# CentOS 7
#

yum -y update

yum -y install telnet \
mlocate \
traceroute \
tcpdump \
wget \
zip \
unzip \
gcc \
epel-release \
mariadb-server \
httpd \
mod_ssl \
ipa-pgothic-fonts


yum -y install perl-CGI \
perl-GD \
ImageMagick-perl \
perl-Test-Simple \
perl-Archive-Zip \
perl-Net-Telnet \
perl-JSON \
perl-ExtUtils-MakeMaker \
perl-Digest-MD5 \
perl-Text-Diff \
perl-Mail-Sendmail \
perl-Net-OpenSSH \
perl-TermReadKey \
perl-Thread-Queue \
perl-Data-UUID \
perl-Data-Dumper-Concise \
perl-Clone \
cpan

yum clean all


# CPAN
echo q | /usr/bin/perl -MCPAN -e shell
cpan -f GD::SecurityImage
cpan -f GD::SecurityImage::AC
cpan -f URI::Escape::JavaScript
cpan -f IO::Pty
cpan -f Net::Ping::External


# MariaDB
sed -i -e 's/\[mysqld\]/\[mysqld\]\ncharacter-set-server = utf8\nskip-character-set-client-handshake\nmax_connect_errors=999999999\n\n\[client\]\ndefault-character-set=utf8/' /etc/my.cnf.d/server.cnf
systemctl start mariadb
mysql -u root < ./install/Telnetman2.sql


# Apache
sed -i -e 's/Options Indexes FollowSymLinks/Options MultiViews FollowSymLinks/' /etc/httpd/conf/httpd.conf
sed -i -e 's/Options None/Options ExecCGI/' /etc/httpd/conf/httpd.conf
sed -i -e 's/#AddHandler cgi-script \.cgi/AddHandler cgi-script .cgi/' /etc/httpd/conf/httpd.conf
sed -i -e 's/DirectoryIndex index\.html/DirectoryIndex index.html index.cgi/' /etc/httpd/conf/httpd.conf
sed -i -e '/ErrorDocument 403/s/^/#/' /etc/httpd/conf.d/welcome.conf
sed -i -e 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html">\n    RewriteEngine on\n    RewriteBase \/\n    RewriteRule ^$ Telnetman2\/index.html [L]\n    RewriteCond %{REQUEST_FILENAME} !-f\n    RewriteCond %{REQUEST_FILENAME} !-d\n    RewriteRule ^(.+)$ Telnetman2\/$1 [L]\n/' /etc/httpd/conf/httpd.conf


# SSL
sed -i -e "\$a[SAN]\nsubjectAltName='DNS:telnetman" /etc/pki/tls/openssl.cnf
openssl req \
 -newkey rsa:2048 \
 -days 3650 \
 -nodes \
 -x509 \
 -subj "/C=JP/ST=/L=/O=/OU=/CN=telnetman" \
 -extensions SAN \
 -reqexts SAN \
 -config /etc/pki/tls/openssl.cnf \
 -keyout /etc/pki/tls/private/server.key \
 -out /etc/pki/tls/certs/server.crt
chmod 644 /etc/pki/tls/private/server.key
chmod 644 /etc/pki/tls/certs/server.crt
sed -i -e 's/localhost\.key/server.key/' /etc/httpd/conf.d/ssl.conf
sed -i -e 's/localhost\.crt/server.crt/' /etc/httpd/conf.d/ssl.conf


# Directories & Files
mkdir /usr/local/Telnetman2
mkdir /usr/local/Telnetman2/lib
mkdir /usr/local/Telnetman2/pl
mkdir /var/Telnetman2
mkdir /var/Telnetman2/archive
mkdir /var/Telnetman2/auth
mkdir /var/Telnetman2/captcha
mkdir /var/Telnetman2/session
mkdir /var/Telnetman2/log
mkdir /var/Telnetman2/conversion_script
mkdir /var/Telnetman2/tmp
mkdir /var/www/html/Telnetman2
mkdir /var/www/html/Telnetman2/img
mkdir /var/www/html/Telnetman2/css
mkdir /var/www/html/Telnetman2/js
mkdir /var/www/cgi-bin/Telnetman2
mv ./html/* /var/www/html/Telnetman2/
mv ./js/*   /var/www/html/Telnetman2/js/
mv ./css/*  /var/www/html/Telnetman2/css/
mv ./img/*  /var/www/html/Telnetman2/img/
mv ./cgi/*  /var/www/cgi-bin/Telnetman2/
mv ./lib/*  /usr/local/Telnetman2/lib/
mv ./pl/*   /usr/local/Telnetman2/pl/
chmod 755 /var/www/cgi-bin/Telnetman2/*
chown -R apache:apache /usr/local/Telnetman2
chown -R apache:apache /var/Telnetman2
chown -R apache:apache /var/www/html/Telnetman2
chown -R apache:apache /var/www/cgi-bin/Telnetman2


# Cron
mv ./install/Telnetman2.cron /etc/cron.d/
chmod 644 /etc/cron.d/Telnetman2.cron
chown root:root /etc/cron.d/Telnetman2.cron


# Logrotate 
mv ./install/Telnetman2.logrotate.txt /etc/logrotate.d/Telnetman2
chmod 644 /etc/logrotate.d/Telnetman2
chown root:root /etc/logrotate.d/Telnetman2


# Firewalld
firewall-cmd --add-service=https --permanent


# Disable SELinux
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


systemctl enable mariadb
systemctl enable httpd
