script dadmod_homelevel_tick
    dadmod_hl_go = 0
    if THUGRECOMP_KeyPressed key = "Home"
        dadmod_hl_go = 1
    endif
    dadmod_hl_sticks = 0
    if THUGRECOMP_PadHeld button = "leftstick"
        if THUGRECOMP_PadHeld button = "rightstick"
            dadmod_hl_sticks = 1
        endif
    endif
    if (<dadmod_hl_sticks> = 1)
        if root_window : GetSingleTag dadmod_hl_sticks_was
            if (<dadmod_hl_sticks_was> = 0)
                dadmod_hl_go = 1
            endif
        endif
    endif
    if ScreenElementExists id = root_window
        root_window : SetTags dadmod_hl_sticks_was = <dadmod_hl_sticks>
    endif
    if (<dadmod_hl_go> = 1)
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
