#!/system/bin/sh

MODDIR=${0%/*}

exec &>$MODDIR/updater.log

while sleep 1; do
    if [ "$(getprop sys.boot_completed)" == 1 ]; then
        break
    fi
done

module_version=2.0.1
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
bbx=/data/magisk/busybox
strg=/storage/emulated/0/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

module_update(){
    chmod 755 $wget
    am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Checking for module updates..." -n com.hal9k.notify4scripts/.NotifyServiceCV

    $MODDIR/wget -nv --no-check-certificate -O $MODDIR/$module_update_file $url/updates/$module_update_file

    chmod 755 $MODDIR/$module_update_file

    source $MODDIR/$module_update_file

    if [ "$module_version" ] && [ "$module_lastest_version" ] && [ ! "$module_lastest_version" == "$module_version" ]; then
        am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Downloading ${module_file}..." -n com.hal9k.notify4scripts/.NotifyServiceCV
        am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Downloading ${module_file}..." -n com.rja.utility/.ShowToast
        $MODDIR/wget -nv --no-check-certificate -O $strg/$module_file $module_download_url
        am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Updating module..." -n com.hal9k.notify4scripts/.NotifyServiceCV
        am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Updating module..." -n com.rja.utility/.ShowToast
        $bbx unzip -o $strg/$module_file module.prop common/service.sh common/wget -d $strg
        cp -f $strg/module.prop $MODDIR/module.prop
        cp -f $strg/common/service.sh $MODDIR/service.sh
        cp -f $strg/common/wget $MODDIR/wget
        am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Module updated" -n com.hal9k.notify4scripts/.NotifyServiceCV
        am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Module updated" -n com.rja.utility/.ShowToast
        sh $MODDIR/service.sh &
        exit
    fi

    update
}

update(){
    am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Checking for Magisk Manager updates..." -n com.hal9k.notify4scripts/.NotifyServiceCV

    $MODDIR/wget -nv --no-check-certificate -O $MODDIR/$update_file $url/updates/$update_file

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

    if [ "$version" ] && [ "$lastest_version" ] && [ ! "$lastest_version" == "$version" ]; then
        mkdir -p $strg
        am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Downloading ${apk_file}..." -n com.hal9k.notify4scripts/.NotifyServiceCV
        am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Downloading ${apk_file}..." -n com.rja.utility/.ShowToast
        $MODDIR/wget -nv --no-check-certificate -O $strg/$apk_file $download_url
        status=$(ls /data/app | grep com.topjohnwu.magisk*)
        if [ "$pm" != 0 ]; then
            pm_install=1
            am startservice -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Updating Magisk Manager..." -n com.hal9k.notify4scripts/.NotifyServiceCV
            am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Updating Magisk Manager..." -n com.rja.utility/.ShowToast
            pm install -r $strg/$apk_file &
            check_install
        fi
        if [ "$pm" == 0 ]; then
            am startservice -e str_exec "am start --user 0 -d file:$strg/$apk_file" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Tap to install ${apk_file}" -n com.hal9k.notify4scripts/.NotifyServiceCV
            am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Tap the notification to install ${apk_file}" -n com.rja.utility/.ShowToast
            check_install
        fi
        if [ "$installed" != 0 ]; then
            echo "version=$lastest_version" > $MODDIR/$version_file
            am startservice -e str_exec "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "Magisk Manager updated" -e b_autocancel "1" -n com.hal9k.notify4scripts/.NotifyServiceCV
            am start -a android.intent.action.MAIN -e message "Magisk Manager Snapshot Updater:
Magisk Manager updated" -n com.rja.utility/.ShowToast
        fi
    fi

    am startservice -e str_exec "am start --user 0 -a android.intent.action.MAIN -n com.topjohnwu.magisk/.SplashActivity" -e str_ticker "" -e str_title "Magisk Manager Snapshot Updater" -e str_content "You are up-to-date" -e b_autocancel "1" -n com.hal9k.notify4scripts/.NotifyServiceCV

    sleep 3600

    module_update
}

check_install(){
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
