#!/system/bin/sh

MODDIR=${0%/*}

exec &> $MODDIR/updater.log

while sleep 1; do [ "$(getprop sys.boot_completed)" != 1 ] || break; done

module_version=2.0.1
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
bbx=/data/magisk/busybox
strg=$EXTERNAL_STORAGE/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

download() { $MODDIR/wget -nv --no-check-certificate -O $1; }

notification() {
    am startservice -e str_exec "$2" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "$1" -e b_autocancel "1" -n com.hal9k.notify4scripts/.NotifyServiceCV
}

toast() {
    am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
$1" -n com.rja.utility/.ShowToast
}

module_update() {
    chmod 755 $MODDIR/wget

#com.rja.utility
#https://forum.xda-developers.com/attachment.php?attachmentid=395194&d=1283630913

#com.hal9k.notify4scripts
#https://github.com/halnovemila/Notify4Scripts/raw/master/com.hal9k.notify4scripts.apk

    notification "Checking for module updates..."

    download "$MODDIR/$module_update_file $url/updates/$module_update_file"

    chmod 755 $MODDIR/$module_update_file

    source $MODDIR/$module_update_file

    if [ "$module_version" ] && [ "$module_lastest_version" ] && [ "$module_lastest_version" != "$module_version" ]; then
        notification "Downloading ${module_file}..."
        toast "Downloading ${module_file}..."
        download "$strg/$module_file $module_download_url"
        notification "Updating module..."
        toast "Updating module..."
        $bbx unzip -o $strg/$module_file module.prop common/service.sh common/wget -d $strg
        cp -f $strg/module.prop $MODDIR/module.prop
        cp -f $strg/common/service.sh $MODDIR/service.sh
        cp -f $strg/common/wget $MODDIR/wget
        notification "Module updated"
        toast "Module updated"
        sh $MODDIR/service.sh &
        exit
    fi

    update
}

update() {
    notification "Checking for Magisk Manager updates..."

    download "$MODDIR/$update_file $url/updates/$update_file"

    if [ ! -f $MODDIR/$version_file ]; then
        echo "version=170221" > $MODDIR/$version_file
    fi

    chmod 755 $MODDIR/$version_file
    chmod 755 $MODDIR/$update_file

    source $MODDIR/$version_file
    source $MODDIR/$update_file

    if [ -f $MODDIR/config.txt ]; then
        chmod 755 $MODDIR/config.txt
        source $MODDIR/config.txt
    fi

    if [ "$version" ] && [ "$lastest_version" ] && [ "$lastest_version" != "$version" ]; then
        mkdir -p $strg
        notification "Downloading ${apk_file}..."
        toast "Downloading ${apk_file}..."
        download "$strg/$apk_file $download_url"
        status=$(ls /data/app | grep com.topjohnwu.magisk*)
        if [ "$pm" != 0 ]; then
            pm_install=1
            notification "Updating Magisk Manager..."
            toast "Updating Magisk Manager..."
            pm install -r $strg/$apk_file &
            check_install
        fi
        if [ "$pm" == 0 ]; then
            notification "Tap to install ${apk_file}" "am start --user 0 -d file:$strg/$apk_file"
            toast "Tap the notification to install ${apk_file}"
            check_install
        fi
        if [ "$installed" != 0 ]; then
            echo "version=$lastest_version" > $MODDIR/$version_file
            notification "Magisk Manager updated" "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"
            toast "Magisk Manager updated"
        fi
    fi

    notification "You are up-to-date" "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity"

    $bbx sed -i '/WARNING: cannot verify/d' $MODDIR/updater.log
    $bbx sed -i '/Unable to locally verify/d' $MODDIR/updater.log

    sleep 3600

    module_update
}

check_install() {
    while sleep 1; do
        if [ "$status" != "$(ls /data/app | grep com.topjohnwu.magisk*)" ]; then
            unset installed
            break
        fi
        count=$(($count+1))
        if [ "$count" == 300 ]; then
            unset count
            installed=0
            if [ "$pm_install" == 1 ]; then
                pm=0
                echo  "pm=0" > $MODDIR/config.txt
            fi
            break
        fi
    done
}

module_update
