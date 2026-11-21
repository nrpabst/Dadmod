script dadmod_homelevel_tick
    if THUGRECOMP_KeyPressed key = "Home"
        if not LevelIs Load_MainMenu
            KillSpawnedScript Name = dadmod_homelevel_open
            SpawnScript dadmod_homelevel_open NotSessionSpecific = 1
        endif
    endif
endscript
script dadmod_homelevel_open
    if ( is_changing_levels = 1 )
        return
    endif
    if InNetGame
        if not IsHost
            return
        endif
    endif
    if ScreenElementExists id = keyboard_anchor
        return
    endif
    if ScreenElementExists id = dialog_box_anchor
        return
    endif
    if ScreenElementExists id = level_select_panel_container
        return
    endif
    root_window : GetSingleTag menu_state
    if ( <menu_state> = on )
        return
    endif
    if ScreenElementExists id = current_menu_anchor
        return
    endif
    handle_start_pressed device_num = 0
    wait 8 gameframes
    root_window : GetSingleTag menu_state
    if not ( <menu_state> = on )
        return
    endif
    if not ScreenElementExists id = current_menu_anchor
        return
    endif
    if InNetGame
        launch_level_select_menu show_warning
    else
        launch_level_select_menu
    endif
endscript
