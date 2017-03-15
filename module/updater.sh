#!/system/bin/sh

MODDIR=${0%/*}
mod_data=/data/magisk/magisk-manager-snapshot-updater

[ -f /data/magisk ] || mkdir -p /data/magisk

[ -f $mod_data ] || mkdir -p $mod_data

cd $mod_data

[ -f old_updater.log ] && mv old_updater.log oldest_updater.log
[ -f updater.log ] && mv updater.log old_updater.log

exec &> updater.log

while :; do [ "$(getprop sys.boot_completed)" != 1 ] || break; sleep 1; done

cat /system/build.prop | grep ro.build
cat /system/build.prop | grep ro.product
cat /system/build.prop | grep ro.board

module_version=3.1.1
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

download() { chmod 755 $MODDIR/wget; $MODDIR/wget -nv --no-check-certificate -O $1; }

notification() { am startservice -e str_exec "$2" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "$1" -e b_autocancel "1" -n com.hal9k.notify4scripts/.NotifyServiceCV; }

toast() { am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
$1" -n com.rja.utility/.ShowToast; }

module_update() {
    #notification "Checking for module updates..."

    download "$module_update_file https://raw.githubusercontent.com/DeicPro/magisk-manager-snapshot-updater/updates/$module_update_file"

    chmod 755 $module_update_file

    source $module_update_file

    if [ "$module_version" ] && [ "$module_lastest_version" ] && [ "$module_lastest_version" != "$module_version" ]; then
        notification "Downloading module v${module_lastest_version}..."
        #toast "Downloading module v${module_lastest_version}..."
        download "$strg/$module_file $module_download_url"
        notification "Updating module..."
        #toast "Updating module..."
        $bbx unzip -o $strg/$module_file install.sh
        chmod 755 install.sh
        sh install.sh
        notification "Module successfully updated"
        #toast "Module successfully updated"
        sh $MODDIR/service.sh &
        exit
    fi

    update
}

update() {
    #notification "Checking for Magisk Manager updates..."

    download "$update_file $url/updates/$update_file"

    if [ ! -f $version_file ]; then
        echo "version=170308" > $version_file
    fi

    chmod 755 $version_file
    chmod 755 $update_file

    source $version_file
    source $update_file

    if [ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ]; then
        [ ! -f $strg ] && { mkdir -p $strg; }
        notification "Downloading Magisk Manager v${lastest_version}..."
        #toast "Downloading Magisk Manager v${lastest_version}..."
        installing=0
        install_tool "com.topjohnwu.magisk" "$apk_file" "$download_url"
        if [ "$installing" == 1 ]; then
            echo "version=$lastest_version" > $version_file
            notification "Magisk Manager successfully updated" "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"
            #toast "Magisk Manager successfully updated"
        fi
    fi

    #notification "You are up-to-date" "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"

    #$bbx sed -i '/WARNING: cannot verify/d' $MODDIR/updater.log
    #$bbx sed -i '/Unable to locally verify/d' $MODDIR/updater.log

    #exec &>> $MODDIR/updater.log

    sleep 600

    module_update
}

install_tool() {
    echo "pm=0" > config.txt
    get_pkg=2
    apk_number=$(ls /data/app | grep $1*)
    wait=10

    if [ -f config.txt ]; then
        chmod 755 config.txt
        source config.txt
    fi

    while :; do
        if [ "$get_pkg" == 2 ] && [ "$apk_number" == "$(ls /data/app | grep $1*)" ]; then
            if [ ! "$download" ]; then
                download "$strg/$2 $3"
                download=1
            fi
            if [ ! "$install" ]; then
                if [ "$pm" != 0 ]; then
                    if [ "$installing" ]; then
                        notification "Updating Magisk Manager..."
                        #toast "Updating Magisk Manager..."
                    fi
                    pm install -r $strg/$2 &
                    install=1
                else
                    if [ "$installing" ]; then
                        notification "Tap to install new Magisk Manager v${lastest_version}" "am start --user 0 -d file:$strg/$2"
                        #toast "Tap the notification to install new Magisk Manager v${lastest_version}"
                    else
                        am start -d file:$strg/$2
                    fi
                    install=1
                fi
            fi
            count=$(($count+3))
            if [ "$count" == 150 ]; then
                unset count install
                echo "pm=0" > config.txt
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

#[ -d /data/app/com.rja.utility* ] || install_tool "com.rja.utility" "ShowToastMessage_NoDrawerIcon.apk" "https://forum.xda-developers.com/attachment.php?attachmentid=395194&d=1283630913"

module_update

#process=$($bbx ps | grep "sh /magisk/magisk-manager-snapshot-updater/updater.sh" | grep -v grep | $bbx awk '{ print $1 }')

#kill -9 $process
