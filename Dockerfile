FROM postgres:9.3

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-gitlab-db.sh /docker-entrypoint-initdb.d/
