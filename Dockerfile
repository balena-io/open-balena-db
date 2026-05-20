FROM postgres:17@sha256:3a83c3e2e6f5507ba4bfd2f2981936d055f81a40c08d7ea80f7a5e46d6512d6e

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
