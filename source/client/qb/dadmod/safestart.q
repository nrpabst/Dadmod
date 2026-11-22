dadmod_safestart_on = 0

script dadmod_safestart_main
    THUGRECOMP_SafeStartInfo
    Change dadmod_safestart_on = <safe>
    dadmod_safestart_line
    if (<just_on> = 1)
        KillSpawnedScript Name = dadmod_safestart_popup_wait
        SpawnScript dadmod_safestart_popup_wait
    endif
    if (<back> = 1)
        KillSpawnedScript Name = dadmod_safestart_back_msg
        SpawnScript dadmod_safestart_back_msg
    endif
endscript

script dadmod_safestart_line
    if ScreenElementExists id = dadmod_safestart_text
        DestroyScreenElement id = dadmod_safestart_text
    endif
    if not IsTrue dadmod_safestart_on
        return
    endif
    if not ScreenElementExists id = startup_menu
        return
    endif
    anchor_id = helper_text_anchor
    if ScreenElementExists id = dadmod_helper_store
        dadmod_helper_store : GetSingleTag anchor_id
    endif
    if not ScreenElementExists id = <anchor_id>
        return
    endif
    CreateScreenElement {
    Type = textElement
    parent = <anchor_id>
    id = dadmod_safestart_text
    font = dialog
    text = "Safe start: on"
    rgba = [ 128 98 20 128 ]
    scale = 0.45
    just = [ left bottom ]
    Pos = (14.0,444.0)
    z_priority = 2100
    not_focusable
    }
endscript

script dadmod_safestart_popup_wait
    wait 4 seconds
    n = 0
    begin
        if ScreenElementExists id = startup_menu
            if not ScreenElementExists id = dialog_box_anchor
                break
            endif
        endif
        n = (<n> + 1)
        if (<n> > 600)
            return
        endif
        wait 1 seconds
    repeat
    dadmod_update_clear
    create_snazzy_dialog_box {
    title = "Safe start"
    text = "THUG Pro closed during startup last time, so dadmod now skips one risky startup step. Everything still works, graphics too. dadmod will try a normal start again after an update."
    text_dims = (3.2e+02,0.0)
    pad_back_script = dadmod_safestart_ok
    buttons = [
    { font = small text = "OK" pad_choose_script = dadmod_safestart_ok }
    ]
    }
endscript

script dadmod_safestart_ok
    dialog_box_exit
    dadmod_layout_open node = 0
endscript

script dadmod_safestart_back_msg
    wait 4 seconds
    if ScreenElementExists id = dadmod_safestart_back_text
        DestroyScreenElement id = dadmod_safestart_back_text
    endif
    Create_Panel_Message {
    text = "Normal start is back on."
    id = dadmod_safestart_back_text
    font_face = crillee
    scale = 0.3
    style = dadmod_welcome_style
    rgba = [ 128 128 128 255 ]
    Pos = (165.0,3.6e+02)
    }
endscript

script dadmod_safestart_gfx_rows
    if not IsTrue dadmod_safestart_on
        return
    endif
    make_thugpro_menu_item {
    text = "Safe start is on: one startup step is skipped"
    id = dadmod_safestart_note
    description_text = "THUG Pro closed during startup once, so dadmod skips its early Direct3D hook."
    not_focusable
    }
    make_thugpro_menu_item {
    text = "Try a normal start"
    id = dadmod_safestart_try
    description_text = "The next start runs the normal way. If it closes again, safe start comes back."
    pad_choose_script = dadmod_safestart_try
    }
endscript

script dadmod_safestart_try
    THUGRECOMP_SafeStartRetry
    dialog_box_exit
    generic_menu_cleanup
    create_snazzy_dialog_box {
    title = "Safe start"
    text = "Restart the game to try a normal start."
    text_dims = (3.2e+02,0.0)
    pad_back_script = dadmod_safestart_try_ok
    buttons = [
    { font = small text = "OK" pad_choose_script = dadmod_safestart_try_ok }
    ]
    }
endscript

script dadmod_safestart_try_ok
    dialog_box_exit
    dadmod_pause_graphics
endscript
