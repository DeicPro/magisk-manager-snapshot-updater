#!/system/bin/sh

mod=${0%/*}
version_file=magish_manager_version.sh
update_version_file=magisk_manager_update.sh
wget=$mod/wget
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
    $wget --no-check-certificate -O $tmp/$update_version_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/updates/$update_version_file
    source $mod/$version_file
    source $tmp/$update_version_file
    if [ "$version" ] && [ "$lastest_version" ] && [ ! "$lastest_version" == "$version" ]; then
        $wget --no-check-certificate -O $tmp/$apkname $download_url
        $wget --no-check-certificate -O $mod/$version_file https://raw.githubusercontent.com/stangri/MagiskFiles/master/$version_file
        pm install -r $tmp/$apkname
        am start com.topjohnwu.magisk/.SplashActivity
fi
    sleep 3600
    return $?
}

update
