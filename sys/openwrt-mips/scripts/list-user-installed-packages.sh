#!/bin/sh

FLASH_TIME=$(opkg status busybox | grep '^Installed-Time: ')
echo $FLASH_TIME

for i in $(opkg list-installed | cut -d' ' -f1)
do
    if [ "$(opkg status $i | grep '^Installed-Time: ')" != "$FLASH_TIME" ]
    then
        echo $i
    fi
done
