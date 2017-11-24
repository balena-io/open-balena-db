#!/bin/bash

psql --username postgres <<-EOSQL
	CREATE DATABASE resin;
	CREATE DATABASE sentry;
EOSQL
