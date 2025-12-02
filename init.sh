#!/bin/bash

set -e

apt-get install apt-transport-https curl
mkdir -p /etc/apt/keyrings
curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'

cp mariadb.sources  /etc/apt/sources.list.d/mariadb.sources
apt update
apt install -y mariadb-server mariadb-backup
