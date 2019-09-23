#!/bin/bash

read -p "Select a language: (en/zh）" language

function zh_set() {
    cp -rp ./zh_net_config.sh /usr/local/bin/
    `alias config='bash /usr/local/bin/zh_net_config.sh'`
    echo "alias config='bash /usr/local/bin/zh_net_config.sh'" >> /etc/bashrc
    /bin/bash
}

function en_set() {
    cp -rp ./en_net_config.sh /usr/local/bin/
    `alias config='bash /usr/local/bin/en_net_config.sh'`
    echo "alias config='bash /usr/local/bin/en_net_config.sh'" >> /etc/bashrc
    /bin/bash
}

function main() {
    if [ ${language} == "en" ] ||  [ ${language} == "EN" ]
    then
    en_set
    elif [ ${language} == "zh" ] ||  [ ${language} == "ZH" ]
    then
    zh_set
    else
    exit 1
    fi
}

main