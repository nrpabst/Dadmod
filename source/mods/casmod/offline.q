edit_skater_main_entries = [
{ text = "Pre-made Skaters" run = edit_skater_premade_skater_menu }
{ text = "Information" run = edit_skater_info_menu }
{ text = "Head Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_head_options cam_pos = head } }
{ text = "Torso Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_torso_options cam_pos = torso from_level_1 } }
{ text = "Leg Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_leg_options cam_pos = Legs } }
{ text = "Tattoo Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_tattoo_options cam_pos = General } }
{ text = "Deck Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_deck_options cam_pos = board } }
{ text = "Scale Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_scaling_options cam_pos = General } }
{ text = "Graphic Options" run = edit_skater_create_options_menu with = { options_array = edit_skater_graphics cam_pos = General } }
{ text = "Face Mapping" run = create_face_map_menu with = { pause_skater load_library cam_pos = head } }
{ text = "Remove Clothes" run = dadmod_remove_clothes }
]
script edit_skater_create_main_menu
    if LevelIs load_cas
        SpawnScript eventually_setup_camera
    endif
    Change current_cas_category = 0
    <back_to> = launch_new_ss_menu
    if IsTrue came_to_cas_menu_from_main_menu
        <back_to> = create_pre_cas_menu
    endif
    SetScreenElementProps {
    id = edit_skater_vmenu
    event_handlers = [
    { pad_back generic_menu_pad_back params = { callback = <back_to> } }
    { pad_up generic_menu_up_or_down_sound params = { up } }
    { pad_down generic_menu_up_or_down_sound params = { down } }
    { pad_alt cas_skater_left params = { } }
    { pad_alt2 cas_skater_right params = { } }
    ]
    replace_handlers
    }
    GetArraySize edit_skater_main_entries
    <i> = 0
    begin
        <e> = ( edit_skater_main_entries [ <i> ] )
        <with> = { }
        if StructureContains structure = <e> with
            <with> = ( <e> . with )
        endif
        if StructureContains structure = <e> header
            FormatText ChecksumName = hdr_id "dadmod_main_hdr_%a" a = <i>
            make_thugpro_menu_item id = <hdr_id> text = ( <e> . text ) not_focusable centered
            if ( <i> > 0 )
                dadmod_es_section_line id = <hdr_id>
            endif
        else
            make_thugpro_menu_item text = ( <e> . text ) pad_choose_script = ( <e> . run ) pad_choose_params = <with>
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
    dadmod_undo_keys
    thugpro_menu_finalize <...>
endscript
