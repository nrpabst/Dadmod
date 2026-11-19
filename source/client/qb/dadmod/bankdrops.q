script toggle_thugrecomp_bankdrops
    GetTags
    if THUGRECOMP_BankDropsOn
        THUGRECOMP_BankDropsSet on = 0
        thugpro_menu_item_update_extra_text id = <id> off
    else
        THUGRECOMP_BankDropsSet on = 1
        thugpro_menu_item_update_extra_text id = <id> on
    endif
endscript
