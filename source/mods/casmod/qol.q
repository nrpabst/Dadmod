dadmod_redo_ready = 0
dadmod_redo_male = 1
dadmod_redo_profile = { }
dadmod_undo_ready = 0
dadmod_undo_male = 1
dadmod_undo_profile = { }
dadmod_preview_armed = 0
dadmod_preview_token = 0
dadmod_page_size = 10
dadmod_color_copied = 0
dadmod_color_copy = { h = 0 s = 0 v = 0 }
script dadmod_undo_save
    GetCurrentSkaterProfileIndex
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    GetSkaterProfileInfo player = <currentSkaterProfileIndex>
    Change dadmod_undo_profile = <profile>
    Change dadmod_undo_male = <is_male>
    Change dadmod_undo_ready = 1
    Change dadmod_redo_ready = 0
endscript
script dadmod_undo_apply
    GetCurrentSkaterProfileIndex
    SetPlayerAppearance player = <currentSkaterProfileIndex> appearance_structure = <to>
    SetSkaterProfileProperty player = <currentSkaterProfileIndex> is_male <male>
    RefreshSkaterModel Skater = 0 profile = <currentSkaterProfileIndex> no_board = no_board
    Skater : TurnOffSpecialItem
endscript
script dadmod_undo
    if not IsTrue dadmod_undo_ready
        return
    endif
    GetCurrentSkaterProfileIndex
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    GetSkaterProfileInfo player = <currentSkaterProfileIndex>
    Change dadmod_redo_profile = <profile>
    Change dadmod_redo_male = <is_male>
    Change dadmod_redo_ready = 1
    Change dadmod_undo_ready = 0
    dadmod_undo_apply to = ( dadmod_undo_profile ) male = ( dadmod_undo_male )
endscript
script dadmod_redo
    if not IsTrue dadmod_redo_ready
        return
    endif
    GetCurrentSkaterProfileIndex
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    GetSkaterProfileInfo player = <currentSkaterProfileIndex>
    Change dadmod_undo_profile = <profile>
    Change dadmod_undo_male = <is_male>
    Change dadmod_undo_ready = 1
    Change dadmod_redo_ready = 0
    dadmod_undo_apply to = ( dadmod_redo_profile ) male = ( dadmod_redo_male )
endscript
script dadmod_undo_keys
    if ScreenElementExists id = current_menu
        SetScreenElementProps {
        id = current_menu
        event_handlers = [
        { pad_expand dadmod_undo params = { } }
        { pad_square dadmod_redo params = { } }
        ]
        }
    endif
endscript
script dadmod_undo_menu_item
    make_thugpro_menu_item text = "Undo Last Change" pad_choose_script = dadmod_undo
endscript
script dadmod_preview_part
    if not IsTrue dadmod_preview_armed
        Change dadmod_preview_armed = 1
        return
    endif
    Change dadmod_preview_token = ( dadmod_preview_token + 1 )
    SpawnScript dadmod_preview_wait params = { structure = <structure> desc_id = <desc_id> part = <part> token = ( dadmod_preview_token ) }
endscript
script dadmod_preview_wait
    wait 8 gameframes
    <now> = ( dadmod_preview_token )
    if not ( <token> = <now> )
        return
    endif
    <want> = <desc_id>
    GetCurrentSkaterProfileIndex
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = <part>
        if GotParam desc_id
            if ChecksumEquals a = <desc_id> b = <want>
                return
            endif
        endif
    endif
    cas_set_part structure = <structure> desc_id = <want> part = <part>
    Change dadmod_preview_dirty = 1
endscript
script dadmod_part_menu_ready
    Change dadmod_preview_armed = 0
    dadmod_turn_check part = <array>
    dadmod_undo_keys
    dadmod_preview_keep
    SetScreenElementProps {
    id = current_menu
    event_handlers = [
    { pad_L3 dadmod_page_jump params = { up } }
    { pad_r3 dadmod_page_jump params = { } }
    ]
    }
    GetCurrentSkaterProfileIndex
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = <array>
        if GotParam desc_id
            if ScreenElementExists id = <desc_id>
                dadmod_mark_selected id = <desc_id> array = <array>
                return focus_target = <desc_id>
            endif
        endif
    endif
endscript
script dadmod_page_jump
    if not ScreenElementExists id = current_menu
        return
    endif
    <n> = ( dadmod_page_size )
    begin
        if GotParam up
            FireEvent Type = pad_up target = current_menu
        else
            FireEvent Type = pad_down target = current_menu
        endif
    repeat <n>
endscript
script dadmod_color_copy_items
    make_thugpro_menu_item text = "Copy Color" pad_choose_script = dadmod_color_copy pad_choose_params = { part = <part> }
    make_thugpro_menu_item text = "Paste Color" pad_choose_script = dadmod_color_paste pad_choose_params = { part = <part> }
endscript
script dadmod_color_copy
    colormenu_get_hsv part = <part>
    Change dadmod_color_copy = { h = <h> s = <s> v = <v> }
    Change dadmod_color_copied = 1
endscript
script dadmod_color_paste
    if not IsTrue dadmod_color_copied
        return
    endif
    colormenu_set_hsv part = <part> h = ( ( dadmod_color_copy ) . h ) s = ( ( dadmod_color_copy ) . s ) v = ( ( dadmod_color_copy ) . v )
    colormenu_refresh_skaters
    __thugpro_color_menu_refresh part = <part>
endscript
script dadmod_part_color_item title = "Edit Skater"
    if GotParam logo_parts
        return
    endif
    if not GotParam parts
        return
    endif
    <back> = { parts = <parts> title = <title> }
    if GotParam callback
        <back> = { <back> callback = <callback> }
    endif
    if GotParam callback_params
        <back> = { <back> callback_params = <callback_params> }
    endif
    if GotParam cam
        <back> = { <back> cam = <cam> }
    endif
    FormatText TextName = color_title "%a Color" a = <title>
    make_thugpro_menu_item {
    text = "\\c6Color"
    pad_choose_script = dadmod_part_color_go
    pad_choose_params = { parts = <parts> title = <color_title> callback = create_part_cas_menu callback_params = <back> }
    }
endscript
dadmod_undo_hold = 0
script dadmod_undo_save_color
    if GotParam callback
        if ChecksumEquals a = <callback> b = create_part_cas_menu
            Change dadmod_undo_hold = 1
            return
        endif
    endif
    dadmod_undo_save
endscript
script dadmod_undo_save_part
    if IsTrue dadmod_undo_hold
        Change dadmod_undo_hold = 0
        return
    endif
    dadmod_undo_save
endscript
dadmod_null_legs = [
{ part = skater_m_legs lower = skater_m_lower_legs }
{ part = skater_f_legs lower = skater_f_lower_legs }
]
script dadmod_after_set_part
    dadmod_keep_color_apply part = <part>
    dadmod_null_legs_check part = <part> desc_id = <desc_id>
endscript
script dadmod_null_legs_check
    if not ChecksumEquals a = <desc_id> b = null
        return
    endif
    GetArraySize dadmod_null_legs
    <i> = 0
    begin
        <e> = ( dadmod_null_legs [ <i> ] )
        if ChecksumEquals a = <part> b = ( <e> . part )
            GetCurrentSkaterProfileIndex
            EditPlayerAppearance profile = <currentSkaterProfileIndex> target = SetPart targetParams = { part = ( <e> . lower ) desc_id = none }
            return
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
endscript
dadmod_preview_dirty = 0
dadmod_preview_base = { }
script dadmod_preview_keep
    GetCurrentSkaterProfileIndex
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    Change dadmod_preview_base = <profile>
    Change dadmod_preview_dirty = 0
endscript
script dadmod_choose_part
    Change dadmod_preview_token = ( dadmod_preview_token + 1 )
    cas_set_part <...>
    dadmod_preview_keep
    if ScreenElementExists id = <desc_id>
        dadmod_mark_selected id = <desc_id> array = <part>
    endif
endscript
script dadmod_preview_revert
    Change dadmod_preview_token = ( dadmod_preview_token + 1 )
    if IsTrue dadmod_preview_dirty
        GetCurrentSkaterProfileIndex
        <base> = ( dadmod_preview_base )
        SetPlayerAppearance player = <currentSkaterProfileIndex> appearance_structure = <base>
        RefreshSkaterModel Skater = 0 profile = <currentSkaterProfileIndex> no_board = no_board
        Skater : TurnOffSpecialItem
        Change dadmod_preview_dirty = 0
    endif
endscript
script dadmod_part_menu_back
    dadmod_preview_revert
    dadmod_turn_back
    <callback> <callback_params>
endscript
script dadmod_part_color_go
    dadmod_preview_revert
    create_part_cas_color_menu <...>
endscript
script dadmod_mark_selected
    GetArraySize <array>
    <i> = 0
    begin
        <e> = ( <array> [ <i> ] )
        <eid> = ( <e> . desc_id )
        if ScreenElementExists id = { <eid> child = text }
            if StructureContains structure = <e> frontend_desc
                if ChecksumEquals a = <eid> b = <id>
                    FormatText TextName = shown "\\c4> %s" s = ( <e> . frontend_desc )
                else
                    <shown> = ( <e> . frontend_desc )
                endif
                dadmod_mark_set_text item = <eid> text = <shown>
            endif
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
endscript
script dadmod_mark_set_text
    RemoveParameter dadmod_plain
    RemoveParameter dadmod_txt
    <item> : GetTags
    if GotParam dadmod_plain
        <item> : SetTags dadmod_plain = <text>
        dadmod_hl_brackets id = <item> on = 0
        dadmod_hl_brackets id = <item> on = 1
        return
    endif
    if GotParam dadmod_txt
        <item> : SetTags dadmod_txt = <text>
    endif
    SetScreenElementProps id = { <item> child = text } text = <text>
endscript
dadmod_keep_color_parts = [ skater_m_hair skater_f_hair skater_m_hat_hair skater_f_hat_hair skater_m_jaw ]
dadmod_keep_color_on = 0
dadmod_keep_color_part = none
dadmod_keep_color_hsv = { h = 0 s = 0 v = 0 }
script dadmod_before_set_part
    Change dadmod_keep_color_on = 0
    if not ArrayContains array = dadmod_keep_color_parts contains = <part>
        return
    endif
    GetCurrentSkaterProfileIndex
    if not GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = <part>
        return
    endif
    if not GotParam h
        return
    endif
    if GotParam use_default_hsv
        if ( <use_default_hsv> = 1 )
            return
        endif
    endif
    Change dadmod_keep_color_hsv = { h = <h> s = <s> v = <v> }
    Change dadmod_keep_color_part = <part>
    Change dadmod_keep_color_on = 1
endscript
script dadmod_keep_color_apply
    if not IsTrue dadmod_keep_color_on
        return
    endif
    Change dadmod_keep_color_on = 0
    <kept> = ( dadmod_keep_color_part )
    if not ChecksumEquals a = <kept> b = <part>
        return
    endif
    <c> = ( dadmod_keep_color_hsv )
    GetCurrentSkaterProfileIndex
    SetPlayerAppearanceColor player = <currentSkaterProfileIndex> part = <part> h = ( <c> . h ) s = ( <c> . s ) v = ( <c> . v ) use_default_hsv = 0
endscript
script dadmod_es_item
    <f> = focusable
    if GotParam not_focusable
        <f> = not_focusable
    endif
    <part_script> = ( <item> . pad_choose_script )
    <part_params> = ( <item> . pad_choose_params )
    <colorable> = 0
    <is_part_list> = 0
    if ChecksumEquals a = <part_script> b = create_part_cas_menu
        if StructureContains structure = <part_params> parts
            if not StructureContains structure = <part_params> logo_parts
                <is_part_list> = 1
                dadmod_es_color_in_use parts = ( <part_params> . parts )
                <colorable> = <in_use>
            endif
        endif
    endif
    <has_extra> = 0
    if StructureContains structure = <item> dadmod_extra
        <has_extra> = 1
        if ( <is_part_list> = 1 )
            <has_extra> = <colorable>
        endif
    endif
    if ( ( <colorable> = 0 ) and ( <has_extra> = 0 ) )
        FormatText ChecksumName = plain_id "dadmod_es_plain_%a" a = <index>
        <ctr> = dadmod_not_centered
        if StructureContains structure = <item> dadmod_header
            <ctr> = centered
        endif
        make_thugpro_menu_item {
        id = <plain_id>
        text = ( <item> . text )
        pad_choose_script = <part_script>
        pad_choose_params = <part_params>
        <f>
        <ctr>
        }
        if StructureContains structure = <item> dadmod_header
            if ( <index> > 0 )
                dadmod_es_section_line id = <plain_id>
            endif
        endif
        return
    endif
    FormatText ChecksumName = item_id "dadmod_es_item_%a" a = <index>
    <back> = { options_array = <options_array> focus_target = <item_id> }
    if GotParam cam_pos
        <back> = { <back> cam_pos = <cam_pos> }
    endif
    if StructureContains structure = <part_params> callback_params
        <cbp> = ( <part_params> . callback_params )
        <part_params> = { <part_params> callback_params = { <cbp> focus_target = <item_id> } }
    endif
    <title> = "Edit Skater"
    if StructureContains structure = <part_params> title
        <title> = ( <part_params> . title )
    endif
    FormatText TextName = color_title "%a Color" a = <title>
    <color_params> = { parts = ( <part_params> . parts ) title = <color_title> callback = edit_skater_create_options_menu callback_params = <back> }
    <choose> = { id = <item_id> part_script = <part_script> part_params = <part_params> color_params = <color_params> }
    <tags> = 0
    <label1> = "color"
    <dx1> = (22.0,0.0)
    if ( <colorable> = 1 )
        <tags> = 1
    endif
    if ( <has_extra> = 1 )
        <x> = ( <item> . dadmod_extra )
        <xp> = ( <x> . params )
        if StructureContains structure = <xp> callback_params
            <xcb> = ( <xp> . callback_params )
            <xp> = { <xp> callback_params = { <xcb> focus_target = <item_id> } }
        endif
        <choose> = { <choose> extra_script = ( <x> . run ) extra_params = <xp> }
        if ( <tags> = 0 )
            <choose> = { <choose> first_is_extra }
            <label1> = ( <x> . label )
            <dx1> = ( <x> . dx )
        endif
        <tags> = ( <tags> + 1 )
    endif
    make_thugpro_menu_item {
    id = <item_id>
    text = ( <item> . text )
    pad_choose_script = dadmod_es_choose
    pad_choose_params = <choose>
    <f>
    }
    if ScreenElementExists id = <item_id>
        <item_id> : SetTags dadmod_side = 0 dadmod_tags = <tags> dadmod_label1 = <label1>
        if ( <tags> = 2 )
            GetStackedScreenElementPos x id = <item_id> offset = (50.0,1e+01)
        else
            GetStackedScreenElementPos x id = <item_id> offset = (76.0,1e+01)
        endif
        CreateScreenElement {
        Type = textElement
        local_id = dadmod_tag
        parent = <item_id>
        text = <label1>
        font = crillee
        scale = 0.13
        Pos = <Pos>
        just = [ center center ]
        internal_just = [ center center ]
        rgba = [ 90 90 90 90 ]
        z_priority = 1006
        }
        CreateScreenElement {
        Type = SpriteElement
        local_id = dadmod_tag_arrow
        parent = <item_id>
        just = [ center , center ]
        alpha = 0.0
        rgba = [ 128 128 128 128 ]
        texture = right_arrow
        Pos = ( <Pos> - <dx1> )
        scale = 0.3
        z_priority = 1006
        }
        if ( <tags> = 2 )
            <item_id> : SetTags dadmod_label2 = ( <x> . label )
            GetStackedScreenElementPos x id = <item_id> offset = (98.0,1e+01)
            CreateScreenElement {
            Type = textElement
            local_id = dadmod_tag2
            parent = <item_id>
            text = ( <x> . label )
            font = crillee
            scale = 0.13
            Pos = <Pos>
            just = [ center center ]
            internal_just = [ center center ]
            rgba = [ 90 90 90 90 ]
            z_priority = 1006
            }
            CreateScreenElement {
            Type = SpriteElement
            local_id = dadmod_tag2_arrow
            parent = <item_id>
            just = [ center , center ]
            alpha = 0.0
            rgba = [ 128 128 128 128 ]
            texture = right_arrow
            Pos = ( <Pos> - ( <x> . dx ) )
            scale = 0.3
            z_priority = 1006
            }
        endif
        SetScreenElementProps {
        id = <item_id>
        event_handlers = [
        { pad_right dadmod_es_side params = { id = <item_id> on } }
        { pad_left dadmod_es_side params = { id = <item_id> } }
        { unfocus dadmod_es_side params = { id = <item_id> away } }
        { focus dadmod_es_side params = { id = <item_id> refresh } }
        ]
        }
    endif
endscript
script dadmod_es_side
    if not ScreenElementExists id = <id>
        return
    endif
    <max> = 1
    if <id> : GetSingleTag dadmod_tags
        <max> = <dadmod_tags>
    endif
    <s> = 0
    if <id> : GetSingleTag dadmod_side
        <s> = <dadmod_side>
    endif
    <focused> = 1
    if GotParam on
        if ( <s> < <max> )
            <s> = ( <s> + 1 )
        endif
    else
        if GotParam away
            <s> = 0
            <focused> = 0
        else
            if not GotParam refresh
                if ( <s> > 0 )
                    <s> = ( <s> - 1 )
                endif
            endif
        endif
    endif
    <id> : SetTags dadmod_side = <s>
    <a1> = 0.0
    <a2> = 0.0
    if ( <focused> = 1 )
        if ( <s> = 0 )
            <a1> = 1.0
        endif
        if ( <s> = 1 )
            <a2> = 1.0
        endif
    endif
    dadmod_es_arrow id = <id> alpha = <a1>
    if ScreenElementExists id = { <id> child = dadmod_tag2_arrow }
        DoScreenElementMorph id = { <id> child = dadmod_tag2_arrow } alpha = <a2> time = 0
    endif
    if ScreenElementExists id = { <id> child = dadmod_tag }
        <dadmod_label1> = "color"
        <id> : GetSingleTag dadmod_label1
        if ( <s> = 1 )
            FormatText TextName = shown "\\c6> %s" s = <dadmod_label1>
            SetScreenElementProps id = { <id> child = dadmod_tag } text = <shown> rgba = [ 128 128 128 128 ]
        else
            SetScreenElementProps id = { <id> child = dadmod_tag } text = <dadmod_label1> rgba = [ 90 90 90 90 ]
        endif
    endif
    if ScreenElementExists id = { <id> child = dadmod_tag2 }
        <id> : GetSingleTag dadmod_label2
        if ( <s> = 2 )
            FormatText TextName = shown "\\c6> %s" s = <dadmod_label2>
            SetScreenElementProps id = { <id> child = dadmod_tag2 } text = <shown> rgba = [ 128 128 128 128 ]
        else
            SetScreenElementProps id = { <id> child = dadmod_tag2 } text = <dadmod_label2> rgba = [ 90 90 90 90 ]
        endif
    endif
endscript
script dadmod_es_choose
    <side> = 0
    if ScreenElementExists id = <id>
        if <id> : GetSingleTag dadmod_side
            <side> = <dadmod_side>
        endif
    endif
    if ( <side> = 0 )
        <part_script> <part_params>
        return
    endif
    if GotParam first_is_extra
        <side> = 2
    endif
    if ( <side> = 2 )
        dadmod_preview_revert
        <extra_script> <extra_params>
        return
    endif
    dadmod_part_color_go <color_params>
endscript
generic_helper_text_cas = {
helper_text_elements_pc = [ { text = "\\b7/\\b4 = Select" } { text = "\\bn = Back" } { text = "\\bm = Accept" } { text = "\\bq/\\br = Rotate" } { text = "\\be/\\bf = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
helper_text_elements_console = [ { text = "\\b7/\\b4 = Select" } { text = "\\m1 = Back" } { text = "\\m0 = Accept" } { text = "\\bg/\\bh = Rotate" } { text = "\\be/\\bf = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
}
dadmod_helper_text_cas_part = {
helper_text_elements_pc = [ { text = "\\b7/\\b4 = Select" } { text = "\\bn = Back" } { text = "\\bm = Accept" } { text = "\\bq/\\br = Rotate" } { text = "\\be/\\bf = Zoom" } { text = "\\bk/\\bl = Skip" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
helper_text_elements_console = [ { text = "\\b7/\\b4 = Select" } { text = "\\m1 = Back" } { text = "\\m0 = Accept" } { text = "\\bg/\\bh = Rotate" } { text = "\\be/\\bf = Zoom" } { text = "\\bk/\\bl = Skip" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
}
generic_helper_text_cas_z = {
helper_text_elements_pc = [ { text = "\\b7/\\b4 = Select" } { text = "\\bn = Back" } { text = "\\bm = Accept" } { text = "\\bq/\\br = Rotate" } { text = "\\bq = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
helper_text_elements_console = [ { text = "\\b7/\\b4 = Select" } { text = "\\m1 = Back" } { text = "\\m0 = Accept" } { text = "\\bg/\\bh = Rotate" } { text = "\\b9 = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
}
dadmod_helper_text_color = {
helper_text_elements_pc = [ { text = "\\b7/\\b4 = Select" } { text = "\\bn = Back" } { text = "\\bm = Accept" } { text = "\\be/\\bf = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
helper_text_elements_console = [ { text = "\\b7/\\b4 = Select" } { text = "\\m1 = Back" } { text = "\\m0 = Accept" } { text = "\\be/\\bf = Zoom" } { text = "\\b0 = Undo" } { text = "\\b1 = Redo" } ]
}
generic_helper_text_color_menu = {
helper_text_elements_pc = [ { text = "\\b7/\\b4 = Select" } { text = "\\b6/\\b5 = Adjust" } { text = "\\bn = Back" } { text = "\\bm = Accept" } { text = "\\bq/\\br = Rotate" } { text = "\\be/\\bf = Zoom" } ]
helper_text_elements_console = [ { text = "\\b7/\\b4 = Select" } { text = "\\b6/\\b5 = Adjust" } { text = "\\m1 = Back" } { text = "\\m0 = Accept" } { text = "\\bg/\\bh = Rotate" } { text = "\\be/\\bf = Zoom" } ]
}
dadmod_es_hair_parts = [ skater_m_hair skater_f_hair ]
dadmod_es_hat_hair_parts = [ skater_m_hat_hair skater_f_hat_hair ]
script dadmod_es_color_in_use
    GetCurrentSkaterProfileIndex
    GetSkaterSex player = <currentSkaterProfileIndex>
    if ( <is_male> )
        <part> = ( <parts> [ 0 ] )
    else
        GetArraySize <parts>
        if ( <array_size> > 1 )
            <part> = ( <parts> [ 1 ] )
        else
            <part> = ( <parts> [ 0 ] )
        endif
    endif
    RemoveParameter desc_id
    if not GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = <part>
        return in_use = 0
    endif
    if not GotParam desc_id
        return in_use = 0
    endif
    if ArrayContains array = dadmod_es_bare_descs contains = <desc_id>
        return in_use = 0
    endif
    <hat> = 0
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = hat
        if GotParam desc_id
            if not ChecksumEquals a = <desc_id> b = none
                <hat> = 1
            endif
        endif
    endif
    if ArrayContains array = dadmod_es_hair_parts contains = <part>
        if ( <hat> = 1 )
            return in_use = 0
        endif
    endif
    if ArrayContains array = dadmod_es_hat_hair_parts contains = <part>
        if ( <hat> = 0 )
            return in_use = 0
        endif
    endif
    return in_use = 1
endscript
script dadmod_es_arrow
    if ScreenElementExists id = { <id> child = dadmod_tag_arrow }
        DoScreenElementMorph id = { <id> child = dadmod_tag_arrow } alpha = <alpha> time = 0
    endif
endscript
script dadmod_es_section_line
    if not ScreenElementExists id = <id>
        return
    endif
    CreateScreenElement {
    Type = SpriteElement
    local_id = dadmod_section_line
    parent = <id>
    just = [ left , center ]
    texture = white
    rgba = [ 128 128 128 128 ]
    alpha = 0.4
    Pos = (-4.0,-11.0)
    scale = (8e+01,0.1)
    z_priority = 600
    }
endscript
dadmod_es_bare_descs = [ none null Hands BareFeet ]
dadmod_turn_parts = [ skater_m_backpack skater_f_backpack ]
dadmod_turned = 0
script dadmod_turn_check
    if not ArrayContains array = dadmod_turn_parts contains = <part>
        return
    endif
    if IsTrue dadmod_turned
        return
    endif
    Change dadmod_turned = 1
    Skater : Obj_RotY speed = 720 angle = 180
endscript
script dadmod_turn_back
    if not IsTrue dadmod_turned
        return
    endif
    Change dadmod_turned = 0
    Skater : Obj_RotY speed = 720 angle = -180
endscript
script dadmod_es_cam_ctx
    <t> = "Body"
    switch <cam_pos>
    case head
        <t> = "Face"
    case torso
        <t> = "Shirt Style"
    case Legs
        <t> = "Pants"
    case board
        <t> = "Board Type"
    endswitch
    if GotParam options_array
        if ChecksumEquals a = <options_array> b = edit_skater_tattoo_options
            <t> = "Head Tattoo"
        endif
    endif
    if ScreenElementExists id = current_menu
        if current_menu : GetSingleTag Anchor
            THUGRECOMP_MenuSeen menu = <Anchor> text = <t>
        endif
    endif
endscript
