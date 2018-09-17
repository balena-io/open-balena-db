#!/bin/bash

psql --username docker <<-EOSQL
	CREATE DATABASE resin;
EOSQL
