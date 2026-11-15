FROM postgres:18@sha256:2ea8630df176ad090ec92136dee850397c5af8781e4bcf2e4162593691c61bbc

ENV POSTGRES_USER=docker
ENV POSTGRES_PASSWORD=docker
ENV PGDATA=/var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
