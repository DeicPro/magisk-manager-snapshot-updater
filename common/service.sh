#!/system/bin/sh

MODDIR=${0%/*}
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
wget=$MODDIR/wget
bbx=/data/magisk/busybox
tmp=/data/local/tmp

while :; do
    $bbx pgrep com.topjohnwu.magisk
    error=$?
    if [ "$error" == 0 ]; then
        break
    fi
done

update(){
    $wget --no-check-certificate -O $MODDIR/$update_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/updates/$update_file
    source $tmp/$version_file
    source $tmp/$update_file
    if [ "$version" ] && [ "$lastest_version" ] && [ ! "$lastest_version" == "$version" ]; then
        $wget --no-check-certificate -O $tmp/$apkname $download_url
        $wget --no-check-certificate -O $MODDIR/$version_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/$version_file
        pm install -r $tmp/$apkname
        am start com.topjohnwu.magisk/.SplashActivity
    fi
    sleep 3600
    return $?
}

update
