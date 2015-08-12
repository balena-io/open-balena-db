#!/bin/bash

psql --username postgres <<-EOSQL
	CREATE DATABASE resin;
EOSQL
