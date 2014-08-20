FROM zumbrunnen/postgresql:latest

ADD ./createdb.conf /etc/supervisor/conf.d/createdb.conf

CMD ["/usr/bin/supervisord"]
