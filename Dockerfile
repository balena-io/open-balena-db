FROM zumbrunnen/postgresql

RUN apt-get install -y -q supervisor

CMD ["su", "postgres", "--command", "/usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf"]
