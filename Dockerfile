FROM postgres:17@sha256:ef92240eff6b0bcce8ccf038c2edcd0d8fd8ef90621849993b8c8995881ab09a

ENV POSTGRES_USER docker
ENV POSTGRES_PASSWORD docker

COPY create-resin-db.sh /docker-entrypoint-initdb.d/
COPY balena-entrypoint.sh /balena-entrypoint.sh

CMD [ "postgres" ]
ENTRYPOINT [ "/balena-entrypoint.sh" ]
