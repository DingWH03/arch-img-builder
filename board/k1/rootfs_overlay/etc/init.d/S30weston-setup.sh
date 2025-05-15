#!/bin/sh
setup()
{
    /root/run_weston.sh &
}

clean()
{
    kill `pidof weston`
    kill `pidof weston-keyboard`
    kill `pidof weston-desktop-shell`
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
