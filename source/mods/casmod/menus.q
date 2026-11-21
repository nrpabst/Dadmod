dadmod_es_greyed = [ none Shirtless ]
dadmod_es_ped_default = [
{ list = ped_m_head part = skater_m_head look = #"Light Skin 1" }
{ list = ped_f_head part = skater_f_head look = #"Light Head 1" }
]
script dadmod_me
    GetCurrentSkaterProfileIndex
    GetSkaterSex player = <currentSkaterProfileIndex>
    return me = <currentSkaterProfileIndex> me_male = <is_male>
endscript
script dadmod_es_pick_side
    dadmod_me
    if ( <me_male> = 1 )
        return side = ( <pair> [ 0 ] )
    endif
    GetArraySize <pair>
    if ( <array_size> < 2 )
        return side = ( <pair> [ 0 ] )
    endif
    return side = ( <pair> [ 1 ] )
endscript
script dadmod_es_spin
    if GotParam left
        cas_skater_left
    else
        cas_skater_right
    endif
endscript
script dadmod_es_keys
    if not ScreenElementExists id = current_menu
        return
    endif
    SetScreenElementProps {
    id = current_menu
    event_handlers = [
    { pad_alt2 dadmod_es_spin params = { } }
    { pad_alt dadmod_es_spin params = { left } }
    ]
    }
endscript
script dadmod_es_open name = edit_skater_options title = "Edit Skater" help = dadmod_help_cas
    dadmod_help_build
    if GotParam wide
        thugpro_menu_create {
        boxed
        wide_extra_text
        menu_title = <title>
        menu_name = <name>
        helper_text = <help>
        pad_back_params = <back_params>
        pad_back_script = <back_script>
        menu_style = MENU_STYLE_RIGHT
        }
    else
        thugpro_menu_create {
        boxed
        scrolling
        menu_title = <title>
        menu_name = <name>
        helper_text = <help>
        pad_back_params = <back_params>
        pad_back_script = <back_script>
        menu_style = MENU_STYLE_RIGHT
        }
    endif
    dadmod_es_keys
endscript
script dadmod_es_cam
    if not GotParam cam
        return
    endif
    <shot> = { cam_pos = <cam> }
    SpawnSkaterScript SkateshopCasIdle params = <shot>
endscript
script dadmod_es_can_pick
    <pp> = ( <item> . pad_choose_params )
    if ChecksumEquals a = ( <item> . pad_choose_script ) b = dadmod_skc_scales_undo
        if not IsTrue dadmod_skc_scales_ready
            return pick = not_focusable
        endif
    endif
    if StructureContains structure = <pp> allowed_items
        if not ArrayContains array = ( <pp> . allowed_items ) contains = <board_now>
            return pick = not_focusable
        endif
    endif
    <go> = ( <item> . pad_choose_script )
    <needs_part> = 0
    if StructureContains structure = <pp> logo_parts
        <needs_part> = 1
    endif
    if ArrayContains array = [ dadmod_es_scale_menu create_part_cas_scale_menu create_part_cas_color_menu create_part_cas_pos_menu create_part_logo_menu ] contains = <go>
        <needs_part> = 1
    endif
    if ( <needs_part> = 0 )
        return pick = focusable
    endif
    if not StructureContains structure = <pp> parts
        return pick = focusable
    endif
    dadmod_es_pick_side pair = ( <pp> . parts )
    RemoveParameter desc_id
    if not GetPlayerAppearancePart player = <me> part = <side>
        return pick = not_focusable
    endif
    if GotParam desc_id
        if ArrayContains array = dadmod_es_greyed contains = <desc_id>
            return pick = not_focusable
        endif
    endif
    return pick = focusable
endscript
script dadmod_es_options_menu cam_pos = General
    dadmod_es_open name = edit_skater_options back_script = pre_cas_menu_exit back_params = { new_menu_script = create_edit_skater_menu }
    dadmod_es_cam cam = <cam_pos>
    dadmod_es_cam_ctx cam_pos = <cam_pos> options_array = <options_array>
    if not GotParam options_array
        thugpro_menu_finalize <...>
        return
    endif
    dadmod_me
    <board_now> = none
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <me> part = board
        if GotParam desc_id
            <board_now> = <desc_id>
        endif
    endif
    GetArraySize <options_array>
    <rows> = <array_size>
    <dm_n> = 0
    begin
        <row> = ( <options_array> [ <dm_n> ] )
        if StructureContains structure = <row> t
            dadmod_es_row row = <row> options_array = <options_array> cam_pos = <cam_pos>
        else
            <item> = <row>
        endif
        <show> = 1
        if StructureContains structure = <item> male_only
            if not ( <me_male> = 1 )
                <show> = 0
            endif
        endif
        if ( <show> = 1 )
            <pick> = focusable
            if StructureContains structure = <item> dadmod_header
                <pick> = not_focusable
            else
                dadmod_es_can_pick item = <item> board_now = <board_now> me = <me>
            endif
            dadmod_es_item <pick> item = <item> index = <dm_n> options_array = <options_array> cam_pos = <cam_pos>
        endif
        <dm_n> = ( <dm_n> + 1 )
    repeat <rows>
    dadmod_undo_keys
    thugpro_menu_create_remainder_items
    thugpro_menu_finalize <...>
endscript
script dadmod_es_part_menu title = "Edit Skater"
    if GotParam logo_parts
        dadmod_es_pick_side pair = <logo_parts>
    else
        dadmod_es_pick_side pair = <parts>
    endif
    <list> = <side>
    ClearExceptions
    dadmod_es_open name = edit_skater_part title = <title> help = dadmod_help_part back_script = dadmod_part_menu_back back_params = { callback_params = <callback_params> callback = <callback> }
    dadmod_es_cam <...>
    GetArraySize dadmod_es_ped_default
    <dm_k> = 0
    begin
        <d> = ( dadmod_es_ped_default [ <dm_k> ] )
        if ChecksumEquals a = <list> b = ( <d> . list )
            make_thugpro_menu_item {
            id = default_skater_head
            text = "Default"
            pad_choose_params = { part = ( <d> . part ) desc_id = ( <d> . look ) }
            pad_choose_script = dadmod_choose_part
            }
        endif
        <dm_k> = ( <dm_k> + 1 )
    repeat <array_size>
    dadmod_undo_save_part
    dadmod_part_remove_item array = <list> callback = <callback> callback_params = <callback_params>
    dadmod_es_ped_names_for list = <list>
    GetArraySize <list>
    <count> = <array_size>
    <dm_n> = 0
    begin
        <e> = ( <list> [ <dm_n> ] )
        <dm_show> = 1
        if StructureContains structure = <e> hidden
            <dm_show> = 0
        endif
        RemoveParameter dm_nm
        if ( <dm_show> = 1 )
            if ( <dm_n> < <dm_nsize> )
                <dm_nm> = ( <dm_names> [ <dm_n> ] )
                if ChecksumEquals a = ( <dm_nm> . id ) b = ( <e> . desc_id )
                    if StructureContains structure = <dm_nm> skip
                        <dm_show> = 0
                    endif
                else
                    RemoveParameter dm_nm
                endif
            endif
        endif
        if ( <dm_show> = 1 )
            if GotParam desc_prefix
                FormatText TextName = label "%a %i" a = <desc_prefix> i = <dm_n>
                FormatText ChecksumName = item_id "%a%i" a = <desc_prefix> i = <dm_n>
            else
                <item_id> = ( <e> . desc_id )
                if StructureContains structure = <e> frontend_desc
                    <label> = ( <e> . frontend_desc )
                else
                    if GotParam dm_nm
                        <label> = ( <dm_nm> . t )
                    else
                        <dm_num> = ( <dm_n> + 1 )
                        FormatText TextName = label "%a %i" a = <dm_word> i = <dm_num>
                    endif
                    if ScreenElementExists id = <item_id>
                        FormatText ChecksumName = item_id "dadmod_es_ped_row%i" i = <dm_n>
                    endif
                endif
            endif
            <use> = { part = <list> desc_id = ( <e> . desc_id ) structure = <e> }
            make_thugpro_menu_item {
            id = <item_id>
            text = <label>
            focus_params = <use>
            focus_script = dadmod_preview_part
            pad_choose_params = <use>
            pad_choose_script = dadmod_choose_part
            }
        endif
        <dm_n> = ( <dm_n> + 1 )
    repeat <count>
    thugpro_menu_create_remainder_items
    dadmod_part_menu_ready array = <list>
    thugpro_menu_finalize <...>
endscript
script dadmod_es_ped_names_for
    GetArraySize dadmod_es_ped_names
    <dm_k> = 0
    begin
        <r> = ( dadmod_es_ped_names [ <dm_k> ] )
        if ChecksumEquals a = <list> b = ( <r> . list )
            <dm_nl> = ( <r> . n )
            GetArraySize <dm_nl>
            return dm_names = <dm_nl> dm_nsize = <array_size> dm_word = ( <r> . w )
        endif
        <dm_k> = ( <dm_k> + 1 )
    repeat <array_size>
    return dm_names = [ ] dm_nsize = 0 dm_word = "Item"
endscript
script dadmod_es_color_menu title = "Color"
    dadmod_undo_save_color callback = <callback>
    if GotParam color_parts
        dadmod_es_pick_side pair = <color_parts>
    else
        dadmod_es_pick_side pair = <parts>
    endif
    <cpart> = <side>
    dadmod_es_open wide name = edit_skater_color title = <title> help = dadmod_help_color back_script = <callback> back_params = <callback_params>
    dadmod_es_cam <...>
    thugpro_color_menu_add_options_to_menu part = <cpart>
    dadmod_color_copy_items part = <cpart>
    thugpro_menu_finalize <...>
    __thugpro_color_menu_refresh part = <cpart>
endscript
script dadmod_es_scale_menu title = "Scaling"
    dadmod_es_open wide name = scaling title = "Scaling" help = dadmod_help_color back_script = <callback> back_params = <callback_params>
    dadmod_es_cam <...>
    thugpro_scaling_menu_add_options_to_menu {
    <scaling_params>
    part = <bone_group>
    }
    dadmod_undo_keys
    dadmod_stick_watch_start
    thugpro_menu_finalize <...>
    __thugpro_scaling_menu_refresh part = <bone_group>
endscript
script dadmod_set_part
    dadmod_before_set_part part = <part>
    cas_set_part <...>
    dadmod_after_set_part part = <part> desc_id = <desc_id>
endscript
dadmod_help_cas = { }
dadmod_help_part = { }
dadmod_help_color = { }
dadmod_help_ready = 0
dadmod_help_words = [
{ k = pick pc = "\\b7/\\b4 = Select" con = "\\b7/\\b4 = Select" }
{ k = slide pc = "\\b6/\\b5 = Adjust" con = "\\b6/\\b5 = Adjust" }
{ k = pick pc = "\\bn = Back" con = "\\m1 = Back" }
{ k = pick pc = "\\bm = Accept" con = "\\m0 = Accept" }
{ k = spin pc = "\\bq/\\br = Rotate" con = "\\bg/\\bh = Rotate" }
{ k = pick pc = "KP+/KP- = Zoom" con = "\\be/\\bf = Zoom" }
{ k = skip pc = "\\bk/\\bl = Skip" con = "\\bk/\\bl = Skip" }
{ k = undo pc = "\\b0 = Undo" con = "\\b0 = Undo" }
{ k = undo pc = "\\b1 = Redo" con = "\\b1 = Redo" }
{ k = pick pc = "PgUp/PgDn = Tilt" pconly = 1 }
{ k = slide pc = "Shift = Fast" pconly = 1 }
]
script dadmod_help_one
    <pc> = [ { } { } { } { } { } { } { } { } { } { } { } ]
    <con> = [ { } { } { } { } { } { } { } { } { } { } { } ]
    <dm_n> = 0
    <dm_c> = 0
    GetArraySize dadmod_help_words
    <dm_i> = 0
    begin
        <w> = ( dadmod_help_words [ <dm_i> ] )
        <take> = 0
        if ArrayContains array = <want> contains = ( <w> . k )
            <take> = 1
        endif
        if ( <take> = 1 )
            SetArrayElement arrayname = pc index = <dm_n> newvalue = { text = ( <w> . pc ) }
            <dm_n> = ( <dm_n> + 1 )
            if not StructureContains structure = <w> pconly
                SetArrayElement arrayname = con index = <dm_c> newvalue = { text = ( <w> . con ) }
                <dm_c> = ( <dm_c> + 1 )
            endif
        endif
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
    dadmod_help_cut row = <pc> used = <dm_n>
    <pc> = <row>
    dadmod_help_cut row = <con> used = <dm_c>
    return bar = { helper_text_elements_console = <row> helper_text_elements_pc = <pc> }
endscript
script dadmod_help_cut
    switch <used>
    case 6
        <out> = [ { } { } { } { } { } { } ]
    case 7
        <out> = [ { } { } { } { } { } { } { } ]
    case 8
        <out> = [ { } { } { } { } { } { } { } { } ]
    case 9
        <out> = [ { } { } { } { } { } { } { } { } { } ]
    default
        <out> = [ { } { } { } { } { } { } { } { } { } { } ]
    endswitch
    <dm_n> = 0
    begin
        SetArrayElement arrayname = out index = <dm_n> newvalue = ( <row> [ <dm_n> ] )
        <dm_n> = ( <dm_n> + 1 )
    repeat <used>
    return row = <out>
endscript
script dadmod_help_build
    if IsTrue dadmod_help_ready
        return built = 0
    endif
    dadmod_btn action = l3 dev = 0
    dm_l3 = <btn>
    dadmod_btn action = r3 dev = 0
    FormatText TextName = dm_skip "%a/%b = Skip" a = <dm_l3> b = <btn>
    dm_words = ( dadmod_help_words )
    SetArrayElement arrayname = dm_words index = 6 newvalue = { k = skip pc = <dm_skip> con = "\\bk/\\bl = Skip" }
    Change dadmod_help_words = <dm_words>
    dadmod_help_one want = [ pick spin undo ]
    Change dadmod_help_cas = <bar>
    Change generic_helper_text_cas = <bar>
    dadmod_help_one want = [ pick spin skip undo ]
    Change dadmod_help_part = <bar>
    dadmod_help_one want = [ pick slide undo ]
    Change dadmod_help_color = <bar>
    dadmod_help_one want = [ pick slide spin ]
    Change generic_helper_text_color_menu = <bar>
    Change dadmod_help_ready = 1
    return built = 1
endscript
