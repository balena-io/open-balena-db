FROM postgres:12

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
