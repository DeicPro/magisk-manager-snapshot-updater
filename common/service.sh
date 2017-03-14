#!/system/bin/sh

MODDIR=${0%/*}

[ -f $MODDIR/updater.sh ] || cp -f $EXTERNAL_STORAGE/MagiskManager/common/updater.sh $MODDIR/updater.sh

sh $MODDIR/updater.sh &
