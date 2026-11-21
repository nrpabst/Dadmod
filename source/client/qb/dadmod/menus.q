dadmod_ins_mode = 0
dadmod_tod_upd = 0

script dadmod_ins_check
    dadmod_ins = 0
    if (dadmod_ins_mode = 1)
        if (<id> = menu_continue)
            dadmod_ins = 1
        endif
    endif
    if (dadmod_ins_mode = 3)
        dadmod_ins = 2
    endif
    if (dadmod_ins_mode = 2)
        if (<id> = quick_menu_level_restarts)
            dadmod_ins = 1
        endif
    endif
    return dadmod_ins = <dadmod_ins>
endscript

script dadmod_ins_items
    if (dadmod_ins_mode = 2)
        Change dadmod_ins_mode = 0
        dadmod_nc_show = 0
        if InNetGame
            dadmod_nc_show = 1
        endif
        if GameModeEquals is_singlesession
            dadmod_nc_show = 1
        endif
        if GameModeEquals is_freeskate
            dadmod_nc_show = 1
        endif
        if IsObserving
            dadmod_nc_show = 0
        endif
        if (<dadmod_nc_show> = 1)
            dadmod_noclip_is_on
            if (<dadmod_nc_on> = 1)
                dadmod_nc_label = "Noclip: On"
            else
                dadmod_nc_label = "Noclip: Off"
            endif
            make_thugpro_menu_item {
            text = <dadmod_nc_label>
            id = dadmod_noclip_item
            description_text = "Fly through walls (F6). Up/Down move, Left/Right turn, \\b3 up, \\b1 down, \\b2 fast"
            pad_choose_script = dadmod_noclip_quick
            }
        endif
        make_thugpro_menu_item {
        text = "Free Cam"
        id = dadmod_free_cam
        description_text = "Fly the camera around freely"
        pad_choose_script = dadmod_free_cam
        }
        dadmod_midload_quick_item
        make_thugpro_menu_item {
        text = "Set Main Menu Here"
        id = dadmod_set_menu_here
        description_text = "Make this level the main menu, with your skater standing right here and the camera on their front"
        pad_choose_script = dadmod_set_menu_here
        pad_choose_params = { from_quick }
        }
        return
    endif
    if (dadmod_ins_mode = 0)
        return
    endif
    Change dadmod_ins_mode = 0
    make_thugpro_menu_item {
    description_text = "Dadmod tools..."
    text = "Dadmod"
    id = menu_dadmod
    pad_choose_script = dadmod_menu
    }
endscript

script create_pause_menu
    if GotParam no_exit
        Change dadmod_ins_mode = 3
    else
        Change dadmod_ins_mode = 1
    endif
    create_pause_menu_orig <...>
    Change dadmod_ins_mode = 0
endscript

script thugpro_show_quick_menu
    Change dadmod_ins_mode = 2
    thugpro_show_quick_menu_orig <...>
    Change dadmod_ins_mode = 0
endscript

script exit_pause_menu
    exit_pause_menu_orig <...>
    if not InNetGame
        if ObjectExists id = Skater
            Skater : NetEnablePlayerInput
        endif
    endif
endscript

script thugpro_update_tod
    Change dadmod_tod_upd = 1
    thugpro_update_tod_orig <...>
    Change dadmod_tod_upd = 0
endscript

script thugpro_menu_create_title title_scale = 0.6 title_pos = (0.0,52.5) title_text_just = [ left center ]
    if GotParam title_texture
        thugpro_menu_create_title_orig <...>
        return
    endif
    <dm_want> = <title_scale>
    <title_scale> = 1.0
    thugpro_menu_create_title_orig <...>
    if GotParam title_text
        if ScreenElementExists id = menu_title_text
            SetScreenElementProps id = menu_title_text tags = { dadmod_txt = <title_text> }
        endif
    endif
    dadmod_title_fit dm_at = <title_pos> dm_tj = <title_text_just> want = <dm_want>
endscript
script dadmod_title_fit want = 0.6
    if not ScreenElementExists id = menu_title_container
        return
    endif
    <dm_fit> = <want>
    if ScreenElementExists id = menu_title_text
        GetScreenElementDims id = menu_title_text
        <dm_x> = ( <dm_at> . (1.0,0.0) )
        <dm_side> = left
        if GotParam dm_tj
            <dm_side> = ( <dm_tj> [ 0 ] )
        endif
        <dm_room> = ( 628.0 - <dm_x> )
        if ChecksumEquals a = <dm_side> b = right
            <dm_room> = ( <dm_x> - 12.0 )
        endif
        if ChecksumEquals a = <dm_side> b = center
            if ( ( <dm_x> - 12.0 ) < <dm_room> )
                <dm_room> = ( <dm_x> - 12.0 )
            endif
            <dm_room> = ( <dm_room> * 2.0 )
        endif
        if ( <dm_room> < 60.0 )
            <dm_room> = 60.0
        endif
        if ( <width> > 0 )
            if ( ( <width> * <want> ) > <dm_room> )
                <dm_fit> = ( <dm_room> / <width> )
            endif
        endif
    endif
    DoScreenElementMorph id = menu_title_container scale = <dm_fit> time = 0
endscript

script load_level
    dadmod_alt = 0
    if GotParam frontend_level
        if GotParam text
            dadmod_keep_text = <text>
        endif
        if GotParam respot
            dadmod_keep_respot = <respot>
        endif
        THUGRECOMP_MenuOpt key = "shop_theme" step = 0
        if GotParam theme
            if ( ( <theme> = 1 ) or ( <theme> = 4 ) )
                dadmod_alt = 1
            endif
            RemoveParameter theme
        endif
        RemoveParameter text
        RemoveParameter respot
        if GotParam dadmod_keep_text
            text = <dadmod_keep_text>
            RemoveParameter dadmod_keep_text
        endif
        if GotParam dadmod_keep_respot
            respot = <dadmod_keep_respot>
            RemoveParameter dadmod_keep_respot
        endif
    endif
    if (<dadmod_alt> = 1)
        RemoveParameter dadmod_alt
        load_level_orig <...> use_alternate_default_params
    else
        RemoveParameter dadmod_alt
        load_level_orig <...>
    endif
    if GotParam frontend_level
        UnloadQB "dadmod_casidle.qb"
        LoadQB "dadmod_casidle.qb" LevelSpecific
    endif
    UnloadQB "dadmod_levelfix.qb"
    LoadQB "dadmod_levelfix.qb" LevelSpecific
endscript

script create_main_menu
    dadmod_ui_apply
    hide_select_skater_arrows
    THUGRECOMP_MenuOpt key = "menu_alive" step = 0
    menu_alive = 0
    if GotParam alive
        menu_alive = <alive>
        RemoveParameter alive
    endif
    RemoveParameter text
    RemoveParameter respot
    if (<menu_alive> = 1)
        THUGRECOMP_MenuOpt key = "pose_refresh" step = 0
        RemoveParameter text
        RemoveParameter respot
        cas_remove_ped_stuff_from_skater
    else
        thugpro_orient_menu_skater
        cas_remove_ped_stuff_from_skater
        KillSkaterCamAnim All
        PlaySkaterCamAnim Name = skateshop_startcam play_hold
    endif
    SetNetworkMode
    UnpauseMusicAndStreams
    Change back_to_local_net_menu = 0
    Change in_server_options = 0
    change_gamemode_singlesession
    autoload_thugpro_registry
    fade_thugpro_startup_loadscreen
    maybe_show_autoload_cas_failed_dialog
    maybe_show_autoload_net_failed_dialog
    autoload_thugpro_set_first_run_key
    maybe_show_custom_level_validation_failed_dialog
    if GotParam InputDelay
        KillSpawnedScript Name = TemporarilyDisableInput
        SpawnScript TemporarilyDisableInput params = { time = 400 }
    endif
    SetMenuPadMappings [ active use_as_first ]
    if IsTrue thugpro_main_reorder
        main_helper = thugpro_main_helper_reorder
    else
        main_helper = thugpro_main_helper
    endif
    dadmod_ui_main_style
    thugpro_menu_create {
    menu_name = startup
    menu_title = "SKATESHOP"
    menu_title_texture = thugpro_logo_new
    menu_title_scale = <title_scale>
    menu_style = <style>
    helper_text = <main_helper>
    show_description_panel
    }
    thugpro_menu_create_background { }
    CreateScreenElement {
    Type = SpriteElement
    parent = current_menu_anchor
    texture = top_gradient
    id = menu_top_gradient
    alpha = 0.8
    scale = (9e+01,1e+01)
    Pos = (0.0,0.0)
    just = [ left top ]
    rgba = [ 0 0 0 128 ]
    z_priority = 0
    }
    i = 0
    begin
        THUGRECOMP_MenuOrder count = 8 pos = <i>
        thugpro_main_item idx = <idx> pos = <i>
        i = ( <i> + 1 )
    repeat 8
    thugpro_menu_finalize <...>
    dadmod_ui_offset_main
    kill_start_key_binding
    wait 1 gameframe
    if (<menu_alive> = 0)
        destroy_thugpro_startup_loadscreen_or_fade_in
    endif
    dadmod_welcome
endscript
