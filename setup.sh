#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

mkdir bfr;
cd bfr;

#Install nginx.
apt-get -y install nginx;
ufw allow 'Nginx Full';
ufw allow 'Nginx HTTP';
ufw allow 'Nginx HTTPS';

#Install uwsgi.
apt-get -y install uwsgi;
apt-get -y install uwsgi-plugin-python;

#Write config for uwsgi.
cd /etc/uwsgi/apps-available/;
UWSGI_APP="
[uwsgi]
chmod-socket = 777\n
chdir = /home/rajshiv169/bfr/\n
mount = wsgi.py\n
plugin = python\n
module = wsgi\n
master = true\n
processes = 1\n
threads = 1\n
vacuum = true\n
manage-script-name = true\n
wsgi-file = wsgi.py\n
callable = app\n
die-on-term = true\n
uid = www-data\n
gid = www-data\n";
echo -e $UWSGI_APP > bfr;
ln -s /etc/uwsgi/apps-available/bfr /etc/uwsgi/apps-enabled/bfr;

#Write nginx config.
cd /etc/nginx/sites-available/;
#note :in domain name or server ip is must

NGINX_CONFIG="
server {\n
\tlisten 80;\n
\tserver_name <domain/ip>;\n
\tlocation = /favicon.ico { access_log off; log_not_found off; }\n
location /static/ {\n
\troot /home/rajshiv169/bfr;\n
}\n
\tlocation / {\n
\tinclude uwsgi_params;\n
\tuwsgi_pass unix:/tmp/bfr.sock;\n
\t}\n
}\n";
echo -e $NGINX_CONFIG > bfr;
rm ../sites-enabled/default;
ln -s /etc/nginx/sites-available/bfr /etc/nginx/sites-enabled/default;

#Write activation script.
cd /home/rajshiv169/bfr/;
echo -e "cd /home/rajshiv169/bfr/" > start.sh;
echo -e "nohup uwsgi_python27 -s /tmp/bfr.sock -w \"bfr:create_app()\"&" >> start.sh;
echo -e "service nginx start" >> start.sh;
echo -e "sudo chmod 777 /tmp/bfr.sock" >> start.sh;

#Write de-activation script.
echo -e "ps -ef | grep uwsgi_python27 | grep -v grep | awk '{print $2}' | xargs kill" > stop.sh;
echo -e "service nginx stop" >> stop.sh;

chmod +x start.sh;
chmod +x stop.sh;

#Setup persistence (run at boot).
cd /etc/cron.d/;
echo -e "SHELL=/bin/sh" > bfr;
echo -e "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> bfr;
echo -e "@reboot   root    /home/rajshiv169/bfr/start.sh" >> bfr;

reboot;
