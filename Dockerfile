FROM postgres:17@sha256:538bdb8c6b278f2f09070a4d79f04a83363a795ed23ec0d92d6b70cabc398eae

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
