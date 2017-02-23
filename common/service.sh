#!/system/bin/sh

MODDIR=${0%/*}
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
wget=$MODDIR/wget
bbx=/data/magisk/busybox
strg=/storage/emulated/0/MagiskManager

exec &>$MODDIR/updater.log
while :; do
    $bbx pgrep com.topjohnwu.magisk
    error=$?
    if [ "$error" == 0 ]; then
        break
    fi
done

update(){
    chmod 755 $MODDIR/wget
    $wget --no-check-certificate -O $MODDIR/$update_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/updates/$update_file
    if [ ! -f $MODDIR/$version_file ]; then
        cat > $MODDIR/$version_file <<EOF
version=170221
EOF
    fi
    chmod 755 $MODDIR/$version_file
    chmod 755 $MODDIR/$update_file
    source $MODDIR/$version_file
    source $MODDIR/$update_file
    if [ "$version" ] && [ "$lastest_version" ] && [ ! "$lastest_version" == "$version" ]; then
        $wget --no-check-certificate -O $strg/$apkname $download_url
        pm install -r $strg/$apkname
        $wget --no-check-certificate -O $MODDIR/$version_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/$version_file
        am start com.topjohnwu.magisk/.SplashActivity
    fi
    sleep 3600
    return $?
}

update
