#!/bin/bash
cp -rp ./config.sh /usr/local/bin/
`alias config='bash /usr/local/bin/config.sh'`
echo "alias config='bash /usr/local/bin/config.sh'" >> /etc/bashrc
/bin/bash
