#!/system/bin/sh

[ -d /data/magisk-manager-snapshot-updater ] || mkdir -p /data/magisk-manager-snapshot-updater

cd /data/magisk-manager-snapshot-updater

source module_update.txt

/data/magisk/busybox unzip -o $EXTERNAL_STORAGE/MagiskManager/$module_file "module/*"

cp -rf module/* /magisk/magisk-manager-snapshot-updater/

touch /magisk/magisk-manager-snapshot-updater/auto_mount

chmod -R 755 /magisk/magisk-manager-snapshot-updater

rm -rf module
