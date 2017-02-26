#!/system/bin/sh

MODDIR=${0%/*}
update_file=magisk_manager_update.txt
version_file=magisk_manager_version.txt
wget=$MODDIR/wget
bbx=/data/magisk/busybox
strg=/storage/emulated/0/MagiskManager
url=https://raw.githubusercontent.com/stangri/MagiskFiles/master

exec &>$MODDIR/updater.log

check(){
    echo "Waiting for Magisk Manager process start..."

    while sleep 1; do
        uid=$($bbx pgrep com.topjohnwu.magisk)
        error=$?
        if [ "$error" == 0 ]; then
            break
        fi
    done

    update
}

update(){
    chmod 755 $MODDIR/wget

    $wget --no-check-certificate -O $MODDIR/$update_file $url/updates/$update_file

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
        mkdir -p $strg
        $wget --no-check-certificate -O $strg/$apkname $download_url
        status=$(ls /data/app | grep com.topjohnwu.magisk*)
        am start -d file:$strg/$apkname
        while sleep 1; do
            if [ "$status" != "$(ls /data/app | grep com.topjohnwu.magisk*)" ]; then
                break
            fi
        done
        $wget --no-check-certificate -O $MODDIR/$version_file $url/$version_file
    fi

    echo "Waiting for Magisk Manager process close..."
    while sleep 60; do
        if [ "$uid" != "$($bbx pgrep com.topjohnwu.magisk)" ]; then
            break
        fi
    done

    check
}

check
update
