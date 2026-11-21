script dadmod_tsfx_get
    on = 1
    if THUGRECOMP_SettingLoad key = "screen_fx"
        if ( <value> = 0 )
            on = 0
        endif
    endif
    return tsfx_on = <on>
endscript
script dadmod_tsfx_text
    dadmod_tsfx_get
    if ( <tsfx_on> = 1 )
        return tsfx_text = "On"
    endif
    return tsfx_text = "Off"
endscript
script dadmod_tsfx_toggle
    if ScreenElementExists id = dadmod_tsfx_item
        if dadmod_tsfx_item : GetSingleTag tsfx_lock
            if ( <tsfx_lock> = 1 )
                return
            endif
        endif
        dadmod_tsfx_item : SetTags tsfx_lock = 1
        SpawnScript dadmod_tsfx_unlock
    endif
    dadmod_tsfx_get
    if ( <tsfx_on> = 1 )
        on = 0
    else
        on = 1
    endif
    THUGRECOMP_SettingSave key = "screen_fx" value = <on>
    dadmod_tsfx_text
    thugpro_menu_item_update_extra_text id = dadmod_tsfx_item text = <tsfx_text>
endscript
script dadmod_tsfx_unlock
    wait 6 gameframes
    if ScreenElementExists id = dadmod_tsfx_item
        dadmod_tsfx_item : SetTags tsfx_lock = 0
    endif
endscript
