#!/system/bin/sh

MODDIR=${0%/*}
mod_data=/data/magisk-manager-snapshot-updater
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager

cd $mod_data

config() {
    [ -f config.txt ] || {
        cat > config.txt <<EOF
wifi_only=1
notification_ticker=1
update_interval=600
EOF
    }

    chmod 755 config.txt

    source config.txt
}

notification() {
    [ -f /data/app/com.hal9k.notify4scripts*/*.apk ] || return

    config

    str_exec="am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"
    str_ticker=$1

    [ "$3" ] && str_exec="su \ntouch $mod_data/.wait_notification"

    [ "$notification_ticker" == 0 ] && unset str_ticker

    am startservice -e int_cancel "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV
    am startservice -e str_exec "$str_exec" -e str_ticker "$str_ticker" -e str_title "Magisk Manager Snapshot Updater" -e str_content "$1" -e b_autocancel "1" -e int_id "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV

    [ "$3" ] && { while :; do [ -f .wait_notification ] && { rm -f .wait_notification; break; }; sleep 3; done; }
}

get_version() {
    [ -f /data/app/$1*/*.apk ] || return

    chmod 755 $MODDIR/aapt

    version=$($MODDIR/aapt d badging /data/app/$1*/*.apk | grep versionName | $bbx awk -F: 'match($0,"versionName"){ print substr($2,RSTART+'$2') }' | $bbx tr -d \' | $bbx awk '{ print $1 }')
}

download() {
    config

    [ "$wifi_only" == 1 ] && {
        while :; do [ "$(getprop init.svc.dhcpcd_wlan0)" == running ] || [ "$(getprop dhcp.wlan0.result)" == ok ] && break; sleep 3; done
    }

    chmod 755 $MODDIR/wget

    while :; do
        $MODDIR/wget -nv --no-check-certificate -O $1 $2 > .tmp_null 2>&1
        error=$?
        [ "$error" == 0 ] && break || { [ "$error" == 4 ] && {
            echo "No internet connection or server is down:"
            echo $2; }; } || cat .tmp_null
        sleep 3
    done

    rm -f .tmp_null
}

install_tool() {
    apk_number=$(ls /data/app | grep $1*)

    while :; do
        [ "$apk_number" == "$(ls /data/app | grep $1*)" ] && {
            [ "$downloaded" ] || {
                download $strg/$2 $3
                downloaded=1
            }
            [ "$installed" ] || {
                notification "Install Magisk Manager ${lastest_version}" "2" "1"
                am start -a android.intent.action.INSTALL_PACKAGE -d file:$strg/$2
                notification "Updating Magisk Manager..." "2"
                installed=1
            }
        } || {
            sleep 10
            unset downloaded installed
            break
        }
        sleep 3
    done
}
