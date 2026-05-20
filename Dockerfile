FROM postgres:17@sha256:ea206dba4203bf62bc772fa7e1a51990a2b7f7f91390ab0a6098e4b20ba95d47

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
