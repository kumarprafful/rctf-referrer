cd /home/ubuntu/bfr/
nohup uwsgi_python27 -s /tmp/bfr.sock -w "bfr:app()"&
service nginx start
sudo chmod 777 /tmp/bfr.sock
