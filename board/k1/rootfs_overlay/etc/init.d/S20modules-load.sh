#!/bin/sh

setup()
{
    modules_usrload=$(cat /sys/firmware/devicetree/base/modules_usrload)
    if [ -z "$modules_usrload" ]; then
        echo "no module defined"
        return
    fi

    echo "$modules_usrload" | tr ',' '\n' | while IFS= read -r i; do
        if [ -n "$i" ]; then
            modprobe "$i" &
        fi
    done
}

clean()
{
    echo "nothing to do for clean"
}

OPT=$1
case "$1" in
    start)
        setup
        ;;
    stop)
        clean
        ;;
    restart|reload)
        clean
        setup
        ;;
    *)
        echo "Usage: $0 {start|stop|reload}"
        exit 1
esac
exit $?
