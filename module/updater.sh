#!/system/bin/sh

MODDIR=${0%/*}
LOGFILE=/cache/magisk.log

log_print() {
  echo "### Magisk Manager Snapshot Updater ### $1"
  echo "### Magisk Manager Snapshot Updater ### $1" >> $LOGFILE
  log -p i -t Magisk Manager Snapshot Updater "### Magisk Manager Snapshot Updater ### $1"
}

log_print "
Run \"mmsu\" from terminal to configurate the module"

mod_data=/data/magisk-manager-snapshot-updater

[ -f $mod_data ] || mkdir -p $mod_data

cd $mod_data

[ -f old_updater.log ] && mv old_updater.log oldest_updater.log
[ -f updater.log ] && mv updater.log old_updater.log

exec &> updater.log

while :; do [ "$(getprop sys.boot_completed)" == 1 ] && break; sleep 1; done

cat /system/build.prop | grep ro.build
cat /system/build.prop | grep ro.product
cat /system/build.prop | grep ro.board

#module_version=3.3.0
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

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

    #count=$2
    version=$($MODDIR/aapt d badging /data/app/$1*/*.apk | grep versionName | $bbx awk -F: 'match($0,"versionName"){ print substr($2,RSTART+'$2') }' | $bbx tr -d \' | $bbx awk '{ print $1 }')
}

module_update() {
    [ "$first_run" ] || notification "Checking for module updates..." "1"

    download $module_update_file https://raw.githubusercontent.com/DeicPro/magisk-manager-snapshot-updater/updates/$module_update_file

    chmod 755 $module_update_file

    source $module_update_file

    [ "$module_version" ] && [ "$module_lastest_version" ] && [ "$module_lastest_version" != "$module_version" ] && {
        notification "New module v${module_lastest_version} found" "1" "1"
        notification "Downloading module v${module_lastest_version}..." "1"
        download $strg/$module_file $module_download_url
        notification "Updating module..." "1"
        $bbx unzip -o $strg/$module_file install.sh
        chmod 755 install.sh
        sh install.sh
        rm -f install.sh
        notification "Module successfully updated" "1"
        sh $MODDIR/service.sh &
        exit
    }

    [ "$first_run" ] || notification "Module is up-to-date" "1"
}

update() {
    #[ "$arch" == x86_64 ] && { [ -f magisk_manager_version.txt ] || echo "version=170312" > magisk_manager_version.txt; chmod 755 magisk_manager_version.txt; source magisk_manager_version.txt; } || 
    get_version com.topjohnwu.magisk 9

    echo "
$(date "+[%y/%m/%d %H:%M:%S]") MAGISK MANAGER VERSION: $version
"

    [ "$first_run" ] || notification "Checking for Magisk Manager updates..." "2"

    download $update_file $url/updates/$update_file

    chmod 755 $update_file

    source $update_file

    [ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ] && {
        [ -f $strg ] || mkdir -p $strg
        notification "New Magisk Manager v${lastest_version} found" "2" "1"
        notification "Downloading Magisk Manager v${lastest_version}..." "2"
        install_tool "com.topjohnwu.magisk" "$apk_file" "$download_url"
        #["$arch" == x86_64 ] && echo "version=$lastest_version" > magisk_manager_version.txt
        notification "Magisk Manager successfully updated" "2"
    }

    [ "$first_run" ] || { notification "Magisk Manager is up-to-date" "2"; first_run=1; }
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

echo "
$(date "+[%y/%m/%d %H:%M:%S]") MODULE VERSION: $module_version
"

arch=Armv7

[ "$(getprop ro.product.cpu.abi | $bbx cut -c-3)" == x86 ] && arch=x86
[ "$(getprop ro.product.cpu.abi2 | $bbx cut -c-3)" == x86 ] && arch=x86
[ "$(getprop ro.product.cpu.abi)" == arm64-v8a ] && arch=Arm64
#[ "$(getprop ro.product.cpu.abi)" == x86_64 ] && arch=x86_64

#[ "$arch" == x86_64 ] || {
[ -f $MODDIR/aapt ] || download $MODDIR/aapt https://raw.githubusercontent.com/DeicPro/magisk-manager-snapshot-updater/bin/aapt-$arch #; }

get_version com.hal9k.notify4scripts 5

[ -f /data/app/com.hal9k.notify4scripts*/*.apk ] && [ "$version" == 1.0-mmsu ] || {
    [ -f /data/app/com.hal9k.notify4scripts*/*.apk ] && {
        notification "Is required to uninstall and install an app, tap please" "3" "1"
        am start -a android.intent.action.UNINSTALL_PACKAGE -d package:com.hal9k.notify4scripts
        while :; do
            [ -f /data/app/com.hal9k.notify4scripts*/*.apk ] || {
                rm -f /data/system/customized_icons/com.hal9k.notify4scripts*
                sleep 10
                break
            }
            sleep 3
        done
    }
    install_tool "com.hal9k.notify4scripts" "com.hal9k.notify4scripts.apk" "https://github.com/DeicPro/magisk-manager-snapshot-updater/raw/bin/com.hal9k.notify4scripts.apk"
}

config

while :; do module_update; update; sleep $update_interval; done
