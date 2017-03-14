#!/system/bin/sh

cd /data/magisk-manager-snapshot-updater

source module_update.txt

/data/magisk/busybox unzip -o $EXTERNAL_STORAGE/MagiskManager/$module_file "module/*"

cp -rf module/* /magisk/magisk-manager-snapshot-updater/

chmod -R 755 /magisk/magisk-manager-snapshot-updater

rm -rf module
