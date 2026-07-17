FROM postgres:18@sha256:32ca0af8e77bfb8c6610c488e4691f83f972a3e9e64d3b02facf3ab111ad5500

ENV POSTGRES_USER=docker
ENV POSTGRES_PASSWORD=docker
ENV PGDATA=/var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
