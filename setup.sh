#!/bin/bash

FILE_UDEV_RULE=test.rules
PWD=$(pwd)

sed -i "1i ACTION==\"add\",SUBSYSTEMS=\"pci|usb|nvme\",RUN+=\"$PWD/parse.sh\"" $FILE_UDEV_RULE
