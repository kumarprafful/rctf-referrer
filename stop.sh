ps -ef | grep uwsgi_python27 | grep -v grep | awk '{print $2}' | xargs kill
service nginx stop
