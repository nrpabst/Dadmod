dadmod_skc_scales_ready = 0
dadmod_skc_scales_undo = { }
dadmod_skc_tricks_ready = 0
dadmod_skc_undo_map = { }
dadmod_skc_undo_specials = [ { } { } { } { } { } { } { } { } { } { } { } { } ]
script dadmod_skc_list_items
    THUGRECOMP_SkcCount
    <dm_total> = <count>
    if ( <dm_total> = 0 )
        make_thugpro_menu_item text = "No saved skaters found" pad_choose_script = nullscript not_focusable
        return
    endif
    <dm_n> = 0
    begin
        THUGRECOMP_SkcName index = <dm_n>
        make_thugpro_menu_item {
        text = <name>
        pad_choose_script = <dm_run>
        pad_choose_params = { index = <dm_n> }
        }
        <dm_n> = ( <dm_n> + 1 )
    repeat <dm_total>
endscript
script dadmod_skc_scales_menu
    dadmod_es_open name = dadmod_skc_list title = "Copy Scales From" back_script = dadmod_skc_scales_back back_params = { focus_target = dadmod_es_plain_0 }
    dadmod_skc_list_items dm_run = dadmod_skc_scales_pick
    thugpro_menu_finalize
endscript
script dadmod_skc_scales_back
    dadmod_es_options_menu options_array = dadmod_es_scale cam_pos = General <...>
endscript
script dadmod_skc_scales_pick
    dadmod_me
    GetPlayerAppearance player = <me>
    <dm_before> = <profile>
    <skc_app> = <profile>
    if THUGRECOMP_SkcScales index = <index>
        dadmod_undo_save
        Change dadmod_skc_scales_undo = <dm_before>
        Change dadmod_skc_scales_ready = 1
        dadmod_undo_apply to = <skc_app> male = <me_male>
        dadmod_midload_mark
    endif
    dadmod_skc_scales_back focus_target = dadmod_es_plain_0
endscript
script dadmod_skc_scales_undo
    if IsTrue dadmod_skc_scales_ready
        dadmod_me
        GetPlayerAppearance player = <me>
        <skc_app> = <profile>
        <skc_from> = ( dadmod_skc_scales_undo )
        if THUGRECOMP_SkcScales
            dadmod_undo_save
            dadmod_undo_apply to = <skc_app> male = <me_male>
            dadmod_midload_mark
        endif
        Change dadmod_skc_scales_ready = 0
    endif
    dadmod_skc_scales_back focus_target = dadmod_es_plain_0
endscript
script dadmod_skc_et_items
    if not ScreenElementExists id = MoreOptions_boneless_anim
        return
    endif
    if ScreenElementExists id = dadmod_skc_copy_tricks
        return
    endif
    make_thugpro_menu_item {
    id = dadmod_skc_copy_tricks
    text = "Copy Tricks From..."
    pad_choose_script = dadmod_skc_tricks_menu
    pad_choose_params = { }
    description_text = "Use the tricks and specials of another saved skater"
    }
    if IsTrue dadmod_skc_tricks_ready
        make_thugpro_menu_item {
        id = dadmod_skc_undo_tricks
        text = "Undo Copy Tricks"
        pad_choose_script = dadmod_skc_tricks_undo
        pad_choose_params = { }
        description_text = "Put back the tricks you had before the copy"
        }
    else
        make_thugpro_menu_item {
        id = dadmod_skc_undo_tricks
        text = "Undo Copy Tricks"
        pad_choose_script = nullscript
        not_focusable
        description_text = "Put back the tricks you had before the copy"
        }
    endif
endscript
script dadmod_skc_tricks_back
    if LevelIs Load_MainMenu
        create_edit_tricks_menu from_ss_menu focus_target = <focus_target>
    else
        create_edit_tricks_menu focus_target = <focus_target>
    endif
endscript
script dadmod_skc_tricks_menu
    if LevelIs Load_MainMenu
        <dm_style> = MENU_STYLE_RIGHT
        <dm_back> = { from_ss_menu focus_target = dadmod_skc_copy_tricks }
    else
        <dm_style> = MENU_STYLE_LEFT
        <dm_back> = { focus_target = dadmod_skc_copy_tricks }
    endif
    thugpro_menu_create {
    menu_name = dadmod_skc_list
    menu_title = "Copy Tricks From"
    menu_style = <dm_style>
    helper_text = generic_helper_text
    pad_back_script = create_edit_tricks_menu
    pad_back_params = <dm_back>
    boxed
    scrolling
    }
    dadmod_skc_list_items dm_run = dadmod_skc_tricks_pick
    thugpro_menu_finalize
endscript
script dadmod_skc_bind_special
    if ( <dm_cat> = 1 )
        BindTrickToKeyCombo {
        special
        index = <dm_slot_index>
        key_combo = <dm_slot>
        trick = <dm_trick>
        update_mappings = 1
        cat
        }
    else
        BindTrickToKeyCombo {
        special
        index = <dm_slot_index>
        key_combo = <dm_slot>
        trick = <dm_trick>
        update_mappings = 1
        }
    endif
endscript
script dadmod_skc_tricks_refresh
    GetCurrentSkaterProfileIndex
    if not InSplitScreenGame
        UpdateTrickMappings Skater = <currentSkaterProfileIndex>
    endif
    GoalManager_ReplaceTrickText All
endscript
script dadmod_skc_tricks_snapshot
    GetCurrentSkaterProfileIndex
    GetSkaterProfileInfo player = <currentSkaterProfileIndex>
    Change dadmod_skc_undo_map = <trick_mapping>
    <dm_list> = [ { } { } { } { } { } { } { } { } { } { } { } { } ]
    <dm_n> = 0
    begin
        GetSpecialTrickInfo index = <dm_n>
        SetArrayElement arrayname = dm_list index = <dm_n> newvalue = { slot = <special_trickslot> trick = <special_trickname> cat = <isCat> }
        <dm_n> = ( <dm_n> + 1 )
    repeat 12
    Change dadmod_skc_undo_specials = <dm_list>
endscript
script dadmod_skc_tricks_pick
    if not THUGRECOMP_SkcTricks index = <index>
        dadmod_skc_tricks_back focus_target = dadmod_skc_copy_tricks
        return
    endif
    dadmod_skc_tricks_snapshot
    <dm_n> = 0
    begin
        RemoveParameter slot
        RemoveParameter trick
        RemoveParameter cat
        <dm_slot> = Unassigned
        <dm_trick> = Unassigned
        <dm_cat> = 0
        if ( <dm_n> < <skc_specials> )
            if THUGRECOMP_SkcSpecial index = <dm_n>
                <dm_slot> = <slot>
                <dm_trick> = <trick>
                <dm_cat> = <cat>
            endif
        endif
        dadmod_skc_bind_special dm_slot_index = <dm_n> dm_slot = <dm_slot> dm_trick = <dm_trick> dm_cat = <dm_cat>
        <dm_n> = ( <dm_n> + 1 )
    repeat 12
    GetCurrentSkaterProfileIndex
    SetSkaterProfileInfo player = <currentSkaterProfileIndex> params = { trick_mapping = <skc_trick_mapping> }
    dadmod_skc_tricks_refresh
    Change dadmod_skc_tricks_ready = 1
    dadmod_midload_mark
    dadmod_skc_tricks_back focus_target = dadmod_skc_copy_tricks
endscript
script dadmod_skc_tricks_undo
    if IsTrue dadmod_skc_tricks_ready
        <dm_old> = ( dadmod_skc_undo_specials )
        <dm_n> = 0
        begin
            <dm_e> = ( <dm_old> [ <dm_n> ] )
            dadmod_skc_bind_special dm_slot_index = <dm_n> dm_slot = ( <dm_e> . slot ) dm_trick = ( <dm_e> . trick ) dm_cat = ( <dm_e> . cat )
            <dm_n> = ( <dm_n> + 1 )
        repeat 12
        GetCurrentSkaterProfileIndex
        SetSkaterProfileInfo player = <currentSkaterProfileIndex> params = { trick_mapping = ( dadmod_skc_undo_map ) }
        dadmod_skc_tricks_refresh
        Change dadmod_skc_tricks_ready = 0
        dadmod_midload_mark
    endif
    dadmod_skc_tricks_back focus_target = dadmod_skc_copy_tricks
endscript
