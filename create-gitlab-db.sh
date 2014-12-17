#!/bin/bash

gosu postgres postgres --single -E <<-EOSQL
	CREATE DATABASE gitlabhq_production
EOSQL
