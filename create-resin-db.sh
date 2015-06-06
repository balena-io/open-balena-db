#!/bin/bash

gosu postgres postgres --single -E <<-EOSQL
	CREATE DATABASE resin
EOSQL
