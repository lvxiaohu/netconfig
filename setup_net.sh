#!/usr/bin/env bash
#! /bin/bash

cp -rp ./config.sh /usr/local/bin/
echo "alias config='bash /usr/local/bin/config.sh'" >> /etc/bashrc
