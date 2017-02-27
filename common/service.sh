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
        pid=$($bbx pgrep com.topjohnwu.magisk)
        error=$?
        if [ "$error" == 0 ]; then
            break
        fi
    done

    update
}

update(){
    chmod 755 $wget

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

    if [ -f $MODDIR/config.txt ]; then
        chmod 755 $MODDIR/config.txt
        source $MODDIR/config.txt
    fi

    if [ "$version" ] && [ "$lastest_version" ] && [ ! "$lastest_version" == "$version" ]; then
        mkdir -p $strg
        $wget --no-check-certificate -O $strg/$apkname $download_url
        status=$(ls /data/app | grep com.topjohnwu.magisk*)
        if [ "$pm" != 0 ]; then
            pm_install=1
            pm install -r $strg/$apkname &
            check_install
        fi
        am start -d file:$strg/$apkname
        check_install
        if [ "$installed" != 0 ]; then
            $wget --no-check-certificate -O $MODDIR/$version_file $url/$version_file
        fi
    fi

    echo "Waiting for Magisk Manager process close..."

    while sleep 300; do
        if [ "$pid" != "$($bbx pgrep com.topjohnwu.magisk)" ]; then
            break
        fi
    done

    check
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
                echo  "pm=0" > $MODDIR/config.txt
            fi
            break
        fi
    done
}

check
update
