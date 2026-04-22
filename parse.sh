#!/bin/bash

NAME=$1
PATH=$2

FILE_RESULT=./result.ini

MAX_PCI=0
MAX_USB=0
MAX_SCSI=0
MAX_NVME=0

log()
{
    local msg=$1
    echo $msg >> $FILE_RESULT
}

init_env()
{
    [ -e $FILE_RESULT ] &&  /usr/bin/rm -f $FILE_RESULT
}

set_metadata()
{
    /usr/bin/sed -i "1i [Metadata]\n" $FILE_RESULT
    /usr/bin/sed -i "2i MAX_NVME=$MAX_NVME" $FILE_RESULT
    /usr/bin/sed -i "2i MAX_SCSI=$MAX_SCSI" $FILE_RESULT
    /usr/bin/sed -i "2i MAX_USB=$MAX_USB" $FILE_RESULT
    /usr/bin/sed -i "2i MAX_PCI=$MAX_PCI" $FILE_RESULT
}

dump_pci_info()
{
    local id=$1
    local bdf=$2
    # echo "bdf: " $bdf

    log "[PCI $id]"
    log "bdf=$bdf"
    log ""
}

# ./parse.sh 1-1 /sys/devices/PCI0000:00/0000:00:01.0/0000:01:00.0/0000:02:00.0
parse_pci()
{
    [[ "$PATH" =~ "PCI" ]] || return 0

    local next=$PATH
    local layers=0
    
    while true
    do
        # echo "next: " $next

        if [[ "$next" =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}.[0-8] ]]; then
            dump_pci_info $layers ${next:0:12}
            layers=$(($layers + 1))
        fi

        [[ x"$next" =~ "/" ]] || break
        next=${next#*/}
    done

    # echo "count: " $layers
    MAX_PCI=$layers
}

dump_usb_info()
{
    local id=$1
    local usb=$2
    # echo "usb: " $usb

    log "[USB $id]"
    log "usb=$usb"
    log ""
}

# ./parse.sh sg1 /sys/devices/PCI0000:00/0000:00:01.0/0000:01:00.0/0000:02:00.0/usb3/3-1/3-1.1/3-1.1.2/scsi_generic/sg1
parse_usb()
{
    [[ "$PATH" =~ "usb" ]] || return 0

    local next=$PATH
    local layers=0
    
    while true
    do
        # echo "next: " $next

        if [[ "$next" =~ ^[0-9]+-[0-9]+ ]]; then
            dump_usb_info $layers ${next%%/*}
            layers=$(($layers + 1))
        fi

        [[ x"$next" =~ "/" ]] || break
        next=${next#*/}
    done

    # echo "count: " $layers
    MAX_USB=$layers
}

dump_scsi_info()
{
    local id=$1
    local scsi=$2
    # echo "scsi: " $scsi

    log "[SCSI $id]"
    log "scsi=$scsi"
    log ""
}

# ./parse.sh sg1 /sys/devices/PCI0000:00/0000:00:01.0/0000:01:00.0/0000:02:00.0/usb3/3-1/3-1.1/3-1.1.2/scsi_generic/host0/0:1:2:3/sg1
parse_scsi()
{
    [[ "$PATH" =~ "usb" ]] || return 0

    local next=$PATH
    local layers=0
    
    while true
    do
        # echo "next: " $next

        if [[ "$next" =~ ^([0-9]+:){3}[0-9]+ ]]; then
            dump_scsi_info $layers ${next%%/*}
            layers=$(($layers + 1))
        fi

        if [[ "$next" =~ ^sg ]]; then
            log "[SCSI_GEN]"
            log "sg=${next%%/*}"
            log ""
        fi

        [[ x"$next" =~ "/" ]] || break
        next=${next#*/}
    done

    # echo "count: " $layers
    MAX_SCSI=$layers
}

dump_nvme_info()
{
    local id=$1
    local nvme=$2
    # echo "nvme: " $nvme

    log "[NVME $id]"
    log "nvme=$nvme"
    log ""
}

# ./parse.sh sg1 /sys/devices/PCI0000:00/0000:00:01.0/0000:01:00.0/nvme0/nvme0n1/nvme0n1p2
parse_nvme()
{
    [[ "$PATH" =~ "nvme" ]] || return 0

    local next=$PATH
    local layers=0
    
    while true
    do
        # echo "next: " $next

        if [[ "$next" =~ ^nvme[0-9]+/ ]]; then
            dump_nvme_info $layers ${next%%/*}
            layers=$(($layers + 1))
        fi

        [[ x"$next" =~ "/" ]] || break
        next=${next#*/}
    done

    # echo "count: " $layers
    MAX_NVME=$layers
}



init_env

# PCI info
parse_pci

# USB info
parse_usb

# SCSI info
parse_scsi

# NVMe info
parse_nvme

# Global data
set_metadata
