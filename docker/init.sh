#!/bin/bash
# shellcheck shell=bash

sudo -u postgres /bin/initdb --locale=C -D /data
sudo -u postgres ln -s /etc/postgresql.conf /data/postgresql.conf
sudo -u postgres /bin/postgres -p 5432 -D /data
