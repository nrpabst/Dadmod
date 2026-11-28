dadmod_upd_front = 1
dadmod_upd_gen = 0
dadmod_upd_seen = 0

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
    FormatText TextName = row_text "%s  >" s = <update_row>
    row_desc = "Check for updates, see what's new and turn Auto update on or off"
    if not (<update_line> = "")
        row_desc = <update_line>
    endif
    make_thugpro_menu_item {
    text = <row_text>
    id = dadmod_main_update
    description_text = <row_desc>
    pad_choose_script = dadmod_updates_open
    }
endscript

script dadmod_updates_open
    my_gen = ( (dadmod_upd_gen) + 1 )
    Change dadmod_upd_gen = <my_gen>
    THUGRECOMP_UpdateInfo
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_updates
    menu_title = "Updates"
    menu_style = MENU_STYLE_LEFT
    helper_text = generic_helper_text
    pad_back_script = dadmod_updates_back
    show_description_panel
    show_gradient
    }
    make_thugpro_menu_item {
    text = <update_act>
    id = dadmod_upd_act
    description_text = <update_act_desc>
    pad_choose_script = dadmod_upd_act_choose
    }
    if (<update_state> = 2)
        FormatText TextName = new_text "What's new in %v  >" v = <update_version>
        make_thugpro_menu_item {
        text = <new_text>
        id = dadmod_upd_new
        description_text = "The changes in the new version"
        pad_choose_script = dadmod_whatsnew_open
        pad_choose_params = { which = 0 }
        }
    endif
    if ( <update_current_num> > 0 )
        FormatText TextName = cur_text "What's new in %v (yours)  >" v = <update_current>
        make_thugpro_menu_item {
        text = <cur_text>
        id = dadmod_upd_cur
        description_text = "The changes in the dadmod you have now"
        pad_choose_script = dadmod_whatsnew_open
        pad_choose_params = { which = 1 }
        }
    endif
    if (<update_auto> = 1)
        auto_text = "Auto update: On"
    else
        auto_text = "Auto update: Off"
    endif
    make_thugpro_menu_item {
    text = <auto_text>
    id = dadmod_upd_auto
    description_text = "On: new versions download while you play and install when you quit. Off: you choose"
    pad_choose_script = dadmod_upd_auto_choose
    }
    dadmod_desc_panel_right
    if GotParam focus_id
        thugpro_menu_finalize focus_target = <focus_id> no_animate
    else
        thugpro_menu_finalize
    endif
    SpawnScript dadmod_updates_live params = { gen = <my_gen> st = <update_state> dl = <update_dl> act = <update_act> }
endscript

script dadmod_updates_live
    begin
        if (<dl> = 1)
            wait 2 seconds
        else
            wait 0.5 seconds
        endif
        if not ((dadmod_upd_gen) = <gen>)
            return
        endif
        if not ScreenElementExists id = dadmod_upd_act
            return
        endif
        if not ScreenElementExists id = dialog_box_anchor
            THUGRECOMP_UpdateInfo
            if not (<update_state> = <st>)
                break
            endif
            if not (<update_dl> = <dl>)
                break
            endif
            if not (<update_act> = <act>)
                break
            endif
        endif
    repeat
    dadmod_updates_open focus_id = dadmod_upd_act
endscript

script dadmod_updates_back
    my_gen = ( (dadmod_upd_gen) + 1 )
    Change dadmod_upd_gen = <my_gen>
    dadmod_layout_open node = 0 focus_id = dadmod_main_update
endscript

script dadmod_updates_reopen
    dialog_box_exit
    dadmod_updates_open focus_id = dadmod_upd_act
endscript

script dadmod_upd_act_choose
    THUGRECOMP_UpdateInfo
    if (<update_state> = 2)
        if (<update_dl> = 2)
            FormatText TextName = upd_text "Restart now to install dadmod %v? THUG Pro closes, updates and starts again. If you keep playing, it installs when you quit." v = <update_version>
            dadmod_update_clear
            create_snazzy_dialog_box {
            title = "Install update"
            text = <upd_text>
            text_dims = (3.2e+02,0.0)
            pad_back_script = dadmod_updates_reopen
            buttons = [
            { font = small text = "Keep playing" pad_choose_script = dadmod_updates_reopen }
            { font = small text = "Restart now" pad_choose_script = dadmod_update_go }
            ]
            }
            return
        endif
        if (<update_dl> = 1)
            return
        endif
        THUGRECOMP_UpdateDownload
    else
        if (<update_state> = 1)
            THUGRECOMP_UpdateCheck
        else
            if (<update_state> = 3)
                THUGRECOMP_UpdateCheck
            else
                return
            endif
        endif
    endif
    dadmod_updates_open focus_id = dadmod_upd_act
endscript

script dadmod_upd_auto_choose
    THUGRECOMP_UpdateInfo
    if (<update_auto> = 1)
        THUGRECOMP_SettingSave key = "upd_auto" value = 0
    else
        THUGRECOMP_SettingSave key = "upd_auto" value = 1
        THUGRECOMP_UpdateInfo auto
    endif
    dadmod_updates_open focus_id = dadmod_upd_auto
endscript

script dadmod_update_clear
    dialog_box_exit
    default_skateshop_menu_cleanup
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
    pad_back_script = dadmod_updates_reopen
    buttons = [
    { font = small text = "OK" pad_choose_script = dadmod_updates_reopen }
    ]
    }
endscript

script dadmod_whatsnew_open which = 0 from = 0
    THUGRECOMP_UpdateInfo
    THUGRECOMP_UpdateNotes which = <which> index = 0
    if (<which> = 0)
        FormatText TextName = page_title "What's new in %v" v = <update_version>
    else
        FormatText TextName = page_title "What's new in %v" v = <update_current>
    endif
    rows = <note_count>
    if ( <rows> > 13 )
        rows = 13
    endif
    if ( <rows> < 1 )
        rows = 1
    endif
    dadmod_update_clear
    thugpro_menu_create {
    menu_name = dadmod_whatsnew
    scrolling
    num_items_to_show = <rows>
    menu_title = <page_title>
    menu_style = MENU_STYLE_LEFT
    helper_text = generic_helper_text
    pad_back_script = dadmod_whatsnew_back
    pad_back_params = { which = <which> from = <from> }
    show_gradient
    }
    if (<note_count> = 0)
        make_thugpro_menu_item {
        text = "No notes for this version"
        description_text = "See README.txt in your dadmod-install folder"
        pad_choose_script = dadmod_whatsnew_back
        pad_choose_params = { which = <which> from = <from> }
        }
    else
        i = 0
        begin
            if (<i> = <note_count>)
                break
            endif
            THUGRECOMP_UpdateNotes which = <which> index = <i>
            if (<note_text> = "")
                note_text = " "
            endif
            make_thugpro_menu_item {
            text = <note_text>
            description_text = <page_title>
            pad_choose_script = NullScript
            }
            i = ( <i> + 1 )
        repeat
    endif
    thugpro_menu_finalize
endscript

script dadmod_whatsnew_back which = 0 from = 0
    if (<from> = 1)
        dadmod_update_dialog_done
        return
    endif
    if (<which> = 0)
        dadmod_updates_open focus_id = dadmod_upd_new
    else
        dadmod_updates_open focus_id = dadmod_upd_cur
    endif
endscript

script dadmod_update_dialog_done
    dialog_box_exit
    dadmod_back_to_main
endscript

script dadmod_update_popup_dl
    THUGRECOMP_UpdateDownload
    dadmod_update_dialog_done
endscript

script dadmod_update_popup_new
    dialog_box_exit
    dadmod_whatsnew_open which = 0 from = 1
endscript

script dadmod_update_popup_cur
    dialog_box_exit
    dadmod_whatsnew_open which = 1 from = 1
endscript

script dadmod_update_main_tick
    if not IsTrue dadmod_upd_seen
        Change dadmod_upd_seen = 1
        if not (<update_from> = "")
            from_ver = <update_from>
            THUGRECOMP_UpdateInfo seen
            THUGRECOMP_ClientLog text = "update: showing Updated to"
            FormatText TextName = upd_text "You now have dadmod %v (you had %f). Your settings were kept." v = <update_current> f = <from_ver>
            dadmod_update_clear
            create_snazzy_dialog_box {
            title = "dadmod updated"
            text = <upd_text>
            text_dims = (3.2e+02,0.0)
            pad_back_script = dadmod_update_dialog_done
            buttons = [
            { font = small text = "OK" pad_choose_script = dadmod_update_dialog_done }
            { font = small text = "What's new" pad_choose_script = dadmod_update_popup_cur }
            ]
            }
            return shown = 1
        endif
    endif
    if not (<update_state> = 2)
        return shown = 0
    endif
    if not (<update_auto> = 0)
        return shown = 0
    endif
    if not (<update_dl> = 0)
        return shown = 0
    endif
    seen_ver = 0
    if THUGRECOMP_SettingLoad key = "upd_popver"
        seen_ver = <value>
    endif
    if not ( <seen_ver> < <update_version_num> )
        return shown = 0
    endif
    THUGRECOMP_SettingSave key = "upd_popver" value = <update_version_num>
    THUGRECOMP_ClientLog text = "update: showing the update popup"
    FormatText TextName = upd_text "dadmod %v is out. %n" v = <update_version> n = <update_act_desc>
    dadmod_update_clear
    create_snazzy_dialog_box {
    title = "Update available"
    text = <upd_text>
    text_dims = (3.2e+02,0.0)
    pad_back_script = dadmod_update_dialog_done
    buttons = [
    { font = small text = "Download now" pad_choose_script = dadmod_update_popup_dl }
    { font = small text = "What's new" pad_choose_script = dadmod_update_popup_new }
    { font = small text = "Later" pad_choose_script = dadmod_update_dialog_done }
    ]
    }
    return shown = 1
endscript

script dadmod_update_watch
    wait 1 seconds
    last_dl = -1
    ready_left = 0
    begin
        THUGRECOMP_UpdateInfo auto
        line = ""
        if (<update_dl> = 1)
            line = <update_line>
        endif
        if (<update_dl> = 2)
            if (<last_dl> = 1)
                ready_left = 8
            endif
        endif
        if ( <ready_left> > 0 )
            line = <update_line>
            ready_left = ( <ready_left> - 1 )
        endif
        last_dl = <update_dl>
        if IsTrue dadmod_upd_front
            if ScreenElementExists id = startup_menu
                if not ScreenElementExists id = dadmod_welcome_text
                    if not ScreenElementExists id = dialog_box_anchor
                        line = <update_line>
                        if not (<update_state> = 0)
                            dadmod_update_main_tick <...>
                            if (<shown> = 1)
                                line = ""
                            endif
                        endif
                    endif
                endif
            endif
        endif
        dadmod_update_show line = <line>
        wait 1 seconds
    repeat
endscript

script dadmod_update_show line = ""
    if (<line> = "")
        if ScreenElementExists id = dadmod_update_line
            DestroyScreenElement id = dadmod_update_line
        endif
        return
    endif
    if ScreenElementExists id = dadmod_update_line
        SetScreenElementProps id = dadmod_update_line text = <line>
        return
    endif
    if IsTrue dadmod_upd_front
        line_pos = (30.0,3.4e+02)
    else
        line_pos = (30.0,4.0e+01)
    endif
    Create_Panel_Message {
    text = <line>
    id = dadmod_update_line
    font_face = crillee
    scale = 0.3
    style = dadmod_update_hold_style
    rgba = [ 128 128 128 255 ]
    Pos = <line_pos>
    just = [ left center ]
    }
endscript

script dadmod_update_hold_style
    DoMorph time = 0 scale = 0.3 alpha = 0
    DoMorph time = 0.15 scale = 0.3 alpha = 1
endscript

script dadmod_update_watch_start
    KillSpawnedScript Name = dadmod_update_watch
    SpawnScript dadmod_update_watch
endscript
