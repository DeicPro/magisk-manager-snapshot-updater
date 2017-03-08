#!/system/bin/sh

MODDIR=${0%/*}

mv $MODDIR/updater.log $MODDIR/previous_updater.log

exec &> $MODDIR/updater.log

while :; do [ "$(getprop sys.boot_completed)" != 1 ] || break; sleep 1; done

cat /system/build.prop | grep ro.build
cat /system/build.prop | grep ro.product
cat /system/build.prop | grep ro.board

module_version=3.1.0
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

download() { chmod 755 $MODDIR/wget; $MODDIR/wget -nv --no-check-certificate -O $1; }

notification() {
    str_exec="am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"

    [ "$3" ] && { str_exec="su \ntouch $MODDIR/.wait"; }

    am startservice -e int_cancel "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV
    am startservice -e str_exec "$str_exec" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "$1" -e b_autocancel "1" -e int_id "$2" -n com.hal9k.notify4scripts/.NotifyServiceCV

    [ "$3" ] && { while :; do [ -f $MODDIR/.wait ] && { rm -f $MODDIR/.wait; break; }; sleep 3; done; }
}

module_update() {
    [ "$first_run" ] || notification "Checking for module updates..." "1"

    download "$MODDIR/$module_update_file $url/updates/$module_update_file"

    chmod 755 $MODDIR/$module_update_file

    source $MODDIR/$module_update_file

    if [ "$module_version" ] && [ "$module_lastest_version" ] && [ "$module_lastest_version" != "$module_version" ]; then
        notification "New module v${module_lastest_version} found" "1" "1"
        notification "Downloading module v${module_lastest_version}..." "1"
        download "$strg/$module_file $module_download_url"
        notification "Updating module..." "1"
        $bbx unzip -o $strg/$module_file module.prop common/service.sh common/wget -d $strg
        cp -f $strg/module.prop $MODDIR/module.prop
        cp -f $strg/common/service.sh $MODDIR/service.sh
        cp -f $strg/common/wget $MODDIR/wget
        notification "Module successfully updated" "1"
        sh $MODDIR/service.sh &
        exit
    fi

    [ "$first_run" ] || notification "Module is up-to-date" "1"

    update
}

update() {
    [ "$first_run" ] || notification "Checking for Magisk Manager updates..." "2"

    download "$MODDIR/$update_file $url/updates/$update_file"

    if [ ! -f $MODDIR/$version_file ]; then
        echo "version=170304" > $MODDIR/$version_file
    fi

    chmod 755 $MODDIR/$version_file
    chmod 755 $MODDIR/$update_file

    source $MODDIR/$version_file
    source $MODDIR/$update_file

    if [ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ]; then
        [ ! -f $strg ] && { mkdir -p $strg; }
        notification "New Magisk Manager v${lastest_version} found" "2" "1"
        notification "Downloading Magisk Manager v${lastest_version}..." "2"
        installing=0
        install_tool "com.topjohnwu.magisk" "$apk_file" "$download_url"
        if [ "$installing" == 1 ]; then
            echo "version=$lastest_version" > $MODDIR/$version_file
            notification "Magisk Manager successfully updated" "2"
        fi
    fi

    [ "$first_run" ] || { notification "Magisk Manager is up-to-date" "2"; first_run=1; }

    sleep 600

    module_update
}

install_tool() {
    [ "$(pm list packages)" ] && { get_pkg=1; [ "$installing" ] && { pm uninstall -k $1; }; wait=0; } || { get_pkg=2; apk_number=$(ls /data/app | grep $1*); wait=10; }

    if [ -f $MODDIR/config.txt ]; then
        chmod 755 $MODDIR/config.txt
        source $MODDIR/config.txt
    fi

    while :; do
        if [ "$get_pkg" == 1 ] && [ ! "$(pm list packages | grep $1)" ] || [ "$get_pkg" == 2 ] && [ "$apk_number" == "$(ls /data/app | grep $1*)" ]; then
            if [ ! "$download" ]; then
                download "$strg/$2 $3"
                download=1
            fi
            if [ ! "$install" ]; then
                if [ "$pm" != 0 ]; then
                    if [ "$installing" ]; then
                        notification "Updating Magisk Manager..." "2"
                    fi
                    pm install -r $strg/$2 &
                    install=1
                else
                    if [ "$installing" ]; then
                        notification "Install Magisk Manager ${lastest_version}" "2" "1"
                        am start --user 0 -d file:$strg/$2
                        notification "Updating Magisk Manager..." "2"
                    else
                        am start -d file:$strg/$2
                    fi
                    install=1
                fi
            fi
            count=$(($count+3))
            if [ "$count" == 150 ]; then
                unset count install
                echo "pm=0" > $MODDIR/config.txt
                pm=0
            fi
        else
            sleep $wait
            unset download install
            [ "$installing" ] && { installing=1; }
            break
        fi
        sleep 3
    done
}

[ -d /data/app/com.hal9k.notify4scripts* ] || install_tool "com.hal9k.notify4scripts" "com.hal9k.notify4scripts.apk" "https://github.com/halnovemila/Notify4Scripts/raw/master/com.hal9k.notify4scripts.apk"

module_update
