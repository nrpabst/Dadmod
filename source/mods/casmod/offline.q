edit_skater_main_entries = [
{ text = "Pre-made Skaters" run = edit_skater_premade_skater_menu }
{ text = "Information" run = edit_skater_info_menu }
{ text = "Head Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_head cam_pos = head } }
{ text = "Torso Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_torso cam_pos = torso from_level_1 } }
{ text = "Leg Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_legs cam_pos = Legs } }
{ text = "Tattoo Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_tattoo cam_pos = General } }
{ text = "Deck Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_deck cam_pos = board } }
{ text = "Scale Options" run = dadmod_es_options_menu with = { options_array = dadmod_es_scale cam_pos = General } }
{ text = "Graphic Options" run = dadmod_es_options_menu with = { options_array = edit_skater_graphics cam_pos = General } }
{ text = "Face Mapping" run = create_face_map_menu with = { pause_skater load_library cam_pos = head } }
{ text = "Remove Clothes" run = dadmod_remove_clothes }
]
script edit_skater_create_main_menu
    dadmod_help_build
    if ( <built> = 1 )
        create_helper_text generic_helper_text_cas
    endif
    Change current_cas_category = 0
    if LevelIs load_cas
        SpawnScript eventually_setup_camera
    endif
    <back_to> = launch_new_ss_menu
    if IsTrue came_to_cas_menu_from_main_menu
        <back_to> = create_pre_cas_menu
    endif
    SetScreenElementProps {
    id = edit_skater_vmenu
    replace_handlers
    event_handlers = [
    { pad_alt2 dadmod_es_spin params = { } }
    { pad_alt dadmod_es_spin params = { left } }
    { pad_down generic_menu_up_or_down_sound params = { down } }
    { pad_up generic_menu_up_or_down_sound params = { up } }
    { pad_back generic_menu_pad_back params = { callback = <back_to> } }
    ]
    }
    GetArraySize edit_skater_main_entries
    <dm_i> = 0
    begin
        <e> = ( edit_skater_main_entries [ <dm_i> ] )
        <with> = { }
        if StructureContains structure = <e> with
            <with> = ( <e> . with )
        endif
        if StructureContains structure = <e> header
            FormatText ChecksumName = hdr_id "dadmod_main_hdr_%a" a = <dm_i>
            make_thugpro_menu_item id = <hdr_id> text = ( <e> . text ) not_focusable centered
            if ( <dm_i> > 0 )
                dadmod_es_section_line id = <hdr_id>
            endif
        else
            make_thugpro_menu_item text = ( <e> . text ) pad_choose_script = ( <e> . run ) pad_choose_params = <with>
        endif
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
    dadmod_undo_keys
    thugpro_menu_finalize <...>
endscript
