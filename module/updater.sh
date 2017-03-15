#!/system/bin/sh

MODDIR=${0%/*}
mod_data=/data/magisk/magisk-manager-snapshot-updater

[ -f $mod_data ] || mkdir -p $mod_data

cd $mod_data

[ -f old_updater.log ] && mv old_updater.log oldest_updater.log
[ -f updater.log ] && mv updater.log old_updater.log

exec &> updater.log

while :; do [ "$(getprop sys.boot_completed)" != 1 ] || break; sleep 1; done

cat /system/build.prop | grep ro.build
cat /system/build.prop | grep ro.product
cat /system/build.prop | grep ro.board

module_version=3.2.0
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

download() {
    chmod 755 $MODDIR/wget

    $MODDIR/wget -nv --no-check-certificate -O $1 $2 > .tmp_null 2>&1

    error=$?

    [ "$error" == 0 ] || { [ "$error" == 4 ] && {
        echo "No internet connection or server is down:"
        echo $2; }; } || cat .tmp_null

    rm -f .tmp_null

    unset error
}

notification() {
    str_exec="am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"

    [ "$3" ] && { str_exec="su \ntouch .wait_notification"; }

    am startservice -e int_cancel "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV
    am startservice -e str_exec "$str_exec" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "$1" -e b_autocancel "1" -e int_id "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV

    [ "$3" ] && { while :; do [ -f .wait_notification ] && { rm -f .wait_notification; break; }; sleep 3; done; }
}

module_update() {
    [ "$first_run" ] || notification "Checking for module updates..." "1"

    download $module_update_file https://raw.githubusercontent.com/DeicPro/magisk-manager-snapshot-updater/testing/$module_update_file

    chmod 755 $module_update_file

    source $module_update_file

    if [ "$module_version" ] && [ "$module_lastest_version" ] && [ "$module_lastest_version" != "$module_version" ]; then
        notification "New module v${module_lastest_version} found" "1" "1"
        notification "Downloading module v${module_lastest_version}..." "1"
        download $strg/$module_file $module_download_url
        notification "Updating module..." "1"
        $bbx unzip -o $strg/$module_file install.sh
        chmod 755 install.sh
        sh install.sh
        notification "Module successfully updated" "1"
        sh $MODDIR/service.sh &
        exit
    fi

    [ "$first_run" ] || notification "Module is up-to-date" "1"
}

update() {
    [ "$arch" == x86_64 ] && { [ -f magisk_manager_version.txt ] || echo "version=170312" > magisk_manager_version.txt; chmod 755 magisk_manager_version.txt; source magisk_manager_version.txt; } || version=$($MODDIR/aapt d badging /data/app/com.topjohnwu.magisk*/*.apk | grep versionName | $bbx awk -F: 'match($0,"versionName"){ print substr($2,RSTART+9) }' | $bbx tr -d \' | $bbx awk '{ print $1 }')

    echo "
MAGISK MANAGER VERSION: $version
"

    [ "$first_run" ] || notification "Checking for Magisk Manager updates..." "2"

    download $update_file $url/updates/$update_file

    chmod 755 $update_file

    source $update_file

    if [ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ]; then
        [ -f $strg ] || mkdir -p $strg
        notification "New Magisk Manager v${lastest_version} found" "2" "1"
        notification "Downloading Magisk Manager v${lastest_version}..." "2"
        installing=0
        install_tool "com.topjohnwu.magisk" "$apk_file" "$download_url"
        if [ "$installing" == 1 ]; then
            notification "Magisk Manager successfully updated" "2"
        fi
    fi

    [ "$first_run" ] || { notification "Magisk Manager is up-to-date" "2"; first_run=1; }
}

install_tool() {
    apk_number=$(ls /data/app | grep $1*)

    while :; do
        if [ "$apk_number" == "$(ls /data/app | grep $1*)" ]; then
            if [ ! "$downloaded" ]; then
                download $strg/$2 $3
                downloaded=1
            fi
            if [ ! "$installed" ]; then
                if [ "$installing" ]; then
                    notification "Install Magisk Manager ${lastest_version}" "2" "1"
                    am start -d file:$strg/$2
                    notification "Updating Magisk Manager..." "2"
                else
                    am start -d file:$strg/$2
                fi
                installed=1
            fi
        else
            sleep 10
            unset downloaded installed
            [ "$installing" ] && { installing=1; }
            break
        fi
        sleep 3
    done
}

echo "
MODULE VERSION: $module_version
"

arch=Armv7

[ "$(getprop ro.product.cpu.abi | $bbx cut -c-3)" == x86 ] && arch=x86
[ "$(getprop ro.product.cpu.abi2 | $bbx cut -c-3)" == x86 ] && arch=x86
[ "getprop ro.product.cpu.abi" == arm64-v8a ] && arch=Arm64
[ "getprop ro.product.cpu.abi" == x86_64 ] && arch=x86_64

[ "$arch" == x86_64 ] || { download $MODDIR/aapt https://raw.githubusercontent.com/DeicPro/magisk-manager-snapshot-updater/bin/aapt-$arch; chmod 755 $MODDIR/aapt; }

[ -d /data/app/com.hal9k.notify4scripts* ] || install_tool "com.hal9k.notify4scripts" "com.hal9k.notify4scripts.apk" "https://github.com/halnovemila/Notify4Scripts/raw/master/com.hal9k.notify4scripts.apk"

while :; do module_update; update; sleep 600; done
