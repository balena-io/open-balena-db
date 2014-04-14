FROM ubuntu:12.04
MAINTAINER Praneeth Bodduluri <lifeeth@resin.io>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.utf8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get -qq update
RUN dpkg-divert --local --rename /usr/bin/ischroot && ln -sf /bin/true /usr/bin/ischroot
RUN apt-get -yqq upgrade


ADD ./postgresql/locale /etc/default/locale

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

RUN apt-get -yqq install wget ca-certificates
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet --no-check-certificate -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get -qq update
RUN apt-get -yqq install postgresql-9.3 \
 && /etc/init.d/postgresql start && sleep 15s \
  && echo "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" | su postgres -c psql \
    && su postgres -c "createdb -O docker docker" \
    && su postgres -c "createdb -O docker gitlabhq_production"

ADD ./postgresql/postgresql.conf /etc/postgresql/9.3/main/postgresql.conf
ADD ./postgresql/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf

RUN apt-get -yqq install supervisor
ADD ./postgresql/supervisord.conf /etc/supervisor/supervisord.conf
ADD ./postgresql/supervisor.conf /etc/supervisor/conf.d/postgresql.conf

VOLUME ["/var/lib/postgresql"]
EXPOSE 5432


CMD ["/usr/bin/supervisord"]
