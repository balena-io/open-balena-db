FROM postgres:18@sha256:d129b9577d274bb96cbd44d902bdeb1b935c89247d161241e9154cba64e13df4

ENV POSTGRES_USER=docker
ENV POSTGRES_PASSWORD=docker
ENV PGDATA=/var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
