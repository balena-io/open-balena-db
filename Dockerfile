FROM postgres:18@sha256:6d732ddbc9cca651c7cbda3f2b84bc515c6d09de796204176c9e312ce8069c6c

ENV POSTGRES_USER=docker
ENV POSTGRES_PASSWORD=docker
ENV PGDATA=/var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
