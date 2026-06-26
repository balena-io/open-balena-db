FROM postgres:18@sha256:4aabea78cf39b90e834caf3af7d602a18565f6fe2508705c8d01aa63245c2e20

ENV POSTGRES_USER=docker
ENV POSTGRES_PASSWORD=docker
ENV PGDATA=/var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
