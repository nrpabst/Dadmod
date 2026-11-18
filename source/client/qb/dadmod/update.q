script thugpro_menu_find_last_item
    dadmod_update_row <...>
    thugpro_menu_find_last_item_orig <...>
    return last_item_id = <last_item_id>
endscript

script dadmod_update_row
    if GotParam parent
        if not (<parent> = current_menu)
            return
        endif
    endif
    if not ((dadmod_layout_node) = 0)
        return
    endif
    if not ScreenElementExists id = dadmod_layout_vmenu
        return
    endif
    if ScreenElementExists id = dadmod_pause_set_menu_here
        return
    endif
    if ScreenElementExists id = dadmod_main_update
        return
    endif
    THUGRECOMP_UpdateInfo
    if not (<update_state> = 2)
        return
    endif
    make_thugpro_menu_item {
    text = <update_label>
    id = dadmod_main_update
    description_text = <update_desc>
    pad_choose_script = dadmod_update_choose
    }
endscript

script dadmod_update_choose
    THUGRECOMP_UpdateInfo
    if (<update_dl> = 2)
        FormatText TextName = upd_text "dadmod %v is downloaded. Restart now to install it? THUG Pro closes, updates and starts again." v = <update_version>
        dadmod_update_clear
        create_snazzy_dialog_box {
        title = "Install update"
        text = <upd_text>
        text_dims = (3.2e+02,0.0)
        pad_back_script = dadmod_update_back
        buttons = [
        { font = small text = "Later" pad_choose_script = dadmod_update_back }
        { font = small text = "Restart now" pad_choose_script = dadmod_update_go }
        ]
        }
        return
    endif
    if (<update_dl> = 1)
        return
    endif
    THUGRECOMP_UpdateDownload
    if (<update_ok> = 1)
        KillSpawnedScript Name = dadmod_update_progress
        SpawnScript dadmod_update_progress
    endif
    dadmod_update_clear
    dadmod_update_back
endscript

script dadmod_update_clear
    dialog_box_exit
    default_skateshop_menu_cleanup
endscript

script dadmod_update_back
    dialog_box_exit
    dadmod_layout_open node = 0 focus_id = dadmod_main_update
endscript

script dadmod_update_go
    THUGRECOMP_UpdateStart
    if (<update_ok> = 1)
        THUGRECOMP_ClientLog text = "update: quitting so the updater can run"
        dialog_box_exit
        QuitGame
        return
    endif
    dadmod_update_clear
    create_snazzy_dialog_box {
    title = "Install update"
    text = "The updater could not start. Close THUG Pro and run Setup.bat in your dadmod-install folder."
    text_dims = (3.2e+02,0.0)
    pad_back_script = dadmod_update_back
    buttons = [
    { font = small text = "OK" pad_choose_script = dadmod_update_back }
    ]
    }
endscript

script dadmod_update_progress
    begin
        THUGRECOMP_UpdateInfo
        if not ScreenElementExists id = dadmod_update_dl_text
            Create_Panel_Message {
            text = <update_progress>
            id = dadmod_update_dl_text
            font_face = crillee
            scale = 0.3
            style = dadmod_update_hold_style
            rgba = [ 128 128 128 255 ]
            Pos = (165.0,3.4e+02)
            }
        endif
        SetScreenElementProps id = dadmod_update_dl_text text = <update_progress>
        if not (<update_dl> = 1)
            break
        endif
        wait 0.5 seconds
    repeat
    wait 4 seconds
    if ScreenElementExists id = dadmod_update_dl_text
        DestroyScreenElement id = dadmod_update_dl_text
    endif
endscript

script dadmod_update_hold_style
    DoMorph time = 0 scale = 0.3 alpha = 0
    DoMorph time = 0.15 scale = 0.3 alpha = 1
endscript

script dadmod_update_popup_wait
    wait 3.5 seconds
    upd_tries = 0
    begin
        if not ScreenElementExists id = startup_menu
            return
        endif
        THUGRECOMP_UpdateInfo
        if (<update_state> = 0)
            upd_tries = (<upd_tries> + 1)
            if (<upd_tries> > 30)
                return
            endif
            wait 0.5 seconds
        else
            break
        endif
    repeat
    if (<update_state> = 2)
        THUGRECOMP_UpdateInfo popup
        if (<update_popup> = 1)
            dadmod_update_text
        endif
    endif
endscript

script dadmod_update_text
    if ScreenElementExists id = dadmod_update_avail_text
        DestroyScreenElement id = dadmod_update_avail_text
    endif
    Create_Panel_Message {
    text = "Update available"
    id = dadmod_update_avail_text
    font_face = crillee
    scale = 0.3
    style = dadmod_welcome_style
    rgba = [ 128 128 128 255 ]
    Pos = (165.0,3.4e+02)
    }
    KillSpawnedScript Name = dadmod_update_matrix
    SpawnScript dadmod_update_matrix
endscript

script dadmod_update_matrix
    t = 0.0
    begin
        if not ScreenElementExists id = dadmod_update_avail_text
            break
        endif
        if ( <t> > 3.4 )
            break
        endif
        if ( <t> > 2.9 )
            THUGRECOMP_ScanText text = "Update available" mode = 5 t = ( <t> * 30.0 ) reveal = 0.0
            SetScreenElementProps id = dadmod_update_avail_text text = <text>
        else
            if ( <t> > 0.9 )
                SetScreenElementProps id = dadmod_update_avail_text text = "Update available"
            else
                THUGRECOMP_ScanText text = "Update available" mode = 5 t = ( <t> * 30.0 ) reveal = ( <t> / 0.9 )
                SetScreenElementProps id = dadmod_update_avail_text text = <text>
            endif
        endif
        t = ( <t> + 0.0167 )
        wait 1 gameframe
    repeat
endscript
