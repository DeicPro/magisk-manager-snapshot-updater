MODID=magisk-manager-snapshot-updater

print_modname() {
    ui_print "*******************************"
    ui_print "  Magisk Manager Snapshot"
    ui_print "  Updater Module v3.2.3"
    ui_print "  By Deiki (@Deic/DeicPro)"
    ui_print "*******************************"
}

set_permissions() {
    set_perm_recursive  $MODPATH  0  0  0755 0644
}
