#!/system/bin/sh

while :; do [ "$(getprop sys.boot_completed)" == 1 ] && break; sleep 1; done

MODDIR=${0%/*}

source $MODDIR/functions.sh

log_print() {
  echo "### Magisk Manager Snapshot Updater ### $1"
  echo "### Magisk Manager Snapshot Updater ### $1" >> /cache/magisk.log
  log -p i -t Magisk Manager Snapshot Updater "### Magisk Manager Snapshot Updater ### $1"
}

log_print "
Run \"mmsu\" from terminal to configurate the module"

[ -f $mod_data ] || mkdir -p $mod_data

cd $mod_data

[ -f old_updater.log ] && mv old_updater.log oldest_updater.log
[ -f updater.log ] && mv updater.log old_updater.log

exec &> updater.log

cat /system/build.prop | grep ro.build
cat /system/build.prop | grep ro.product
cat /system/build.prop | grep ro.board

#module_version=3.3.0
module_update_file=module_update.txt
update_file=magisk_manager_update.txt
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

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
