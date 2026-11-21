dadmod_gen02_names = [ IsTrue GotParam ScreenElementExists ]

dadmod_ui_defaults = [
{ key = "ui_text" value = 0 }
{ key = "ui_focus" value = 0 }
{ key = "ui_bar" value = 0 }
{ key = "ui_title" value = 0 }
{ key = "ui_rainbow" value = 0 }
{ key = "ui_bright" value = 100 }
{ key = "ui_text_fx" value = 0 }
{ key = "ui_focus_fx" value = 0 }
{ key = "ui_bar_fx" value = 0 }
{ key = "ui_title_fx" value = 0 }
{ key = "ui_rb_speed" value = 4 }
{ key = "ui_rb_theme" value = 0 }
{ key = "ui_colortheme" value = 1 }
{ key = "ui_theme_mode" value = 0 }
{ key = "ui_fx_speed" value = 5 }
{ key = "ui_rb_angle" value = 0 }
{ key = "ui_item0_fx" value = 0 }
{ key = "ui_item1_fx" value = 0 }
{ key = "ui_item2_fx" value = 0 }
{ key = "ui_item3_fx" value = 0 }
{ key = "ui_item4_fx" value = 0 }
{ key = "ui_item5_fx" value = 0 }
{ key = "ui_item6_fx" value = 0 }
{ key = "ui_item7_fx" value = 0 }
{ key = "ui_sat" value = 100 }
{ key = "ui_scale" value = 120 }
{ key = "ui_x" value = 0 }
{ key = "ui_side" value = 2 }
{ key = "ui_size" value = 100 }
{ key = "ui_y" value = 0 }
{ key = "ui_item0" value = 0 }
{ key = "ui_item1" value = 0 }
{ key = "ui_item2" value = 0 }
{ key = "ui_item3" value = 0 }
{ key = "ui_item4" value = 0 }
{ key = "ui_item5" value = 0 }
{ key = "ui_item6" value = 0 }
{ key = "ui_item7" value = 0 }
]

dadmod_ui_color_keys = [ "ui_text" "ui_focus" "ui_bar" "ui_title" "ui_rainbow" "ui_bright" "ui_sat" "ui_text_fx" "ui_focus_fx" "ui_bar_fx" "ui_title_fx" "ui_rb_speed" "ui_rb_theme" "ui_colortheme" "ui_theme_mode" "ui_fx_speed" "ui_rb_angle" "ui_item0_fx" "ui_item1_fx" "ui_item2_fx" "ui_item3_fx" "ui_item4_fx" "ui_item5_fx" "ui_item6_fx" "ui_item7_fx" "ui_item0" "ui_item1" "ui_item2" "ui_item3" "ui_item4" "ui_item5" "ui_item6" "ui_item7" ]

script dadmod_ui_reset_colors
    GetArraySize dadmod_ui_defaults
    i = 0
    begin
        if (<i> = <array_size>)
            break
        endif
        k = ( ( dadmod_ui_defaults [ <i> ] ) . key )
        GetArraySize dadmod_ui_color_keys
        n = <array_size>
        j = 0
        begin
            if (<j> = <n>)
                break
            endif
            if ( ( dadmod_ui_color_keys [ <j> ] ) = <k> )
                THUGRECOMP_SettingSave key = <k> value = ( ( dadmod_ui_defaults [ <i> ] ) . value )
                break
            endif
            j = ( <j> + 1 )
        repeat
        GetArraySize dadmod_ui_defaults
        i = ( <i> + 1 )
    repeat
    THUGRECOMP_SettingSave key = "desc_color" value = 0
    THUGRECOMP_SettingSave key = "desc_accent_color" value = 0
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_ui_colours_menu
    endif
endscript

script dadmod_ui_reset
    GetArraySize dadmod_ui_defaults
    i = 0
    begin
        if (<i> = <array_size>)
            break
        endif
        THUGRECOMP_SettingSave key = ( ( dadmod_ui_defaults [ <i> ] ) . key ) value = ( ( dadmod_ui_defaults [ <i> ] ) . value )
        i = ( <i> + 1 )
    repeat
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_ui_menu
    endif
endscript

script dadmod_desc_setting
    if THUGRECOMP_SettingLoad key = <key>
        return setting = <value>
    endif
    return setting = <def>
endscript

script dadmod_desc_panel_right
    Change dadmod_desc_is_strip = 0
    dadmod_desc_setting key = "desc_x" def = 470
    x = <setting>
    dadmod_desc_setting key = "desc_y" def = 125
    y = <setting>
    dadmod_desc_setting key = "desc_w" def = 230
    w = <setting>
    dadmod_desc_setting key = "desc_scale" def = 100
    sc = ( 0.16 * <setting> / 100.0 )
    dadmod_desc_setting key = "desc_alpha" def = 65
    pa = ( <setting> / 100.0 )
    dadmod_desc_setting key = "desc_accent" def = 1
    accent_on = <setting>
    dadmod_desc_setting key = "desc_align" def = 1
    ij = [ center top ]
    if (<setting> = 0)
        ij = [ left top ]
    endif
    if (<setting> = 2)
        ij = [ right top ]
    endif
    text_rgba = [ 128 128 128 128 ]
    dadmod_ui_color key = "desc_color"
    if GotParam color
        text_rgba = <color>
        RemoveParameter color
    endif
    bg_rgba = [ 0 0 0 128 ]
    dadmod_ui_color key = "desc_bg"
    if GotParam color
        bg_rgba = <color>
        RemoveParameter color
    endif
    accent_rgba = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    dadmod_ui_color key = "desc_accent_color"
    if GotParam color
        accent_rgba = <color>
        RemoveParameter color
    endif
    if ScreenElementExists id = desc_text_container
        DestroyScreenElement id = desc_text_container
    endif
    CreateScreenElement {
    id = desc_text_container
    parent = current_menu_anchor
    type = ContainerElement
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    }
    desc_text_container : SetTags dadmod_box = 1 box_w = <w> box_scale = <sc> panel_alpha = <pa> accent_on = <accent_on>
    CreateScreenElement {
    local_id = panel
    parent = desc_text_container
    type = SpriteElement
    texture = white
    rgba = <bg_rgba>
    alpha = 0.0
    just = [ center top ]
    pos = (0.0,0.0)
    scale = ( (0.25,0.0) * ( <w> + 24 ) + (0.0,10.0) )
    z_priority = 1010
    }
    CreateScreenElement {
    local_id = accent
    parent = desc_text_container
    type = SpriteElement
    texture = white
    rgba = <accent_rgba>
    alpha = 0.0
    just = [ center top ]
    pos = (0.0,0.0)
    scale = ( (0.25,0.0) * ( <w> + 24 ) + (0.0,0.5) )
    z_priority = 1011
    }
    CreateScreenElement {
    local_id = text
    parent = desc_text_container
    type = TextBlockElement
    font = bebas
    text = ""
    dims = ( (1.0,0.0) * ( <w> / <sc> ) )
    allow_expansion
    just = [ center top ]
    internal_just = <ij>
    scale = <sc>
    pos = (0.0,12.0)
    rgba = <text_rgba>
    alpha = 0.0
    z_priority = 1020
    }
endscript

script dadmod_desc_fit_later
    wait 1 gameframe
    dadmod_desc_fit
endscript

script dadmod_desc_fit
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    desc_text_container : GetTags
    GetScreenElementDims id = { desc_text_container child = text }
    h = ( <height> + 24 )
    panel_scale = ( (0.25,0.0) * ( <box_w> + 24 ) + (0.0,0.25) * <h> )
    if GotParam hide
        DoScreenElementMorph id = { desc_text_container child = panel } alpha = 0.0 time = 0.15
        if ScreenElementExists id = { desc_text_container child = accent }
            DoScreenElementMorph id = { desc_text_container child = accent } alpha = 0.0 time = 0.15
        endif
    else
        DoScreenElementMorph id = { desc_text_container child = panel } scale = <panel_scale> alpha = <panel_alpha> time = 0.12
        if (<accent_on> = 1)
            if ScreenElementExists id = { desc_text_container child = accent }
                DoScreenElementMorph id = { desc_text_container child = accent } alpha = 1.0 time = 0.12
            endif
        endif
    endif
endscript

script thugpro_menu_desc_text_focus
    if not GotParam text
        return
    endif
    Change dadmod_desc_seq = ( dadmod_desc_seq + 1 )
    THUGRECOMP_TextClip text = <text> max = 90
    short = <clipped>
    dadmod_box = 0
    if ScreenElementExists id = desc_text_container
        desc_text_container : GetTags
    endif
    if not (<dadmod_box> = 1)
        text = <short>
    endif
    if ScreenElementExists id = desc_text_container
        DoScreenElementMorph {
        id = { desc_text_container child = text }
        alpha = 0.8
        time = 0.2
        }
        SetScreenElementProps {
        id = { desc_text_container child = text }
        text = <text>
        }
        KillSpawnedScript Name = dadmod_desc_fit_later
        SpawnScript dadmod_desc_fit_later
        if (<short> = "")
            dadmod_desc_strip alpha = 0.0
        else
            dadmod_desc_strip alpha = 0.4
        endif
    endif
    if ScreenElementExists id = tp_helper_text
        DoScreenElementMorph {
        id = tp_helper_text
        alpha = 0.8
        time = 0.2
        }
        SetScreenElementProps {
        id = tp_helper_text
        text = <short>
        }
    endif
endscript

script dadmod_desc_panel_refresh
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    dadmod_desc_panel_right
    SetScreenElementProps id = { desc_text_container child = text } text = "Description box preview: this is where the text for the selected option shows up."
    DoScreenElementMorph id = { desc_text_container child = text } alpha = 0.8 time = 0.1
    KillSpawnedScript Name = dadmod_desc_fit_later
    SpawnScript dadmod_desc_fit_later
endscript

script dadmod_offline_ui_live
    dadmod_ui_apply
    dadmod_ui_repaint
    dadmod_desc_panel_refresh
    if GotParam main
        if ScreenElementExists id = startup_menu
            create_main_menu
        endif
    endif
endscript

script thugpro_menu_create_helper_text parent = current_menu_anchor
    if not LevelIs Load_MainMenu
        dadmod_desc_panel_right
        return
    endif
    Change dadmod_desc_is_strip = 1
    if ScreenElementExists id = desc_text_container
        DestroyScreenElement id = desc_text_container
    endif
    CreateScreenElement {
    id = desc_text_container
    parent = <parent>
    type = ContainerElement
    pos = (320.0,398.0)
    }
    CreateScreenElement {
    local_id = text
    parent = desc_text_container
    type = TextElement
    font = bebas
    text = ""
    scale = 0.15
    alpha = 0.0
    just = [ center center ]
    internal_just = [ center center ]
    z_priority = 1020
    }
    CreateScreenElement {
    local_id = panel
    parent = desc_text_container
    type = SpriteElement
    texture = white
    alpha = 0.0
    just = [ center center ]
    rgba = [ 0 0 0 128 ]
    scale = (200.0,10.0)
    }
endscript

script dadmod_desc_strip alpha = 0.0
    if not IsTrue dadmod_desc_is_strip
        return
    endif
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    DoScreenElementMorph id = { desc_text_container child = panel } alpha = <alpha> time = 0.2
endscript

dadmod_desc_seq = 0

dadmod_desc_is_strip = 0

script thugpro_menu_desc_text_unfocus
    if ScreenElementExists id = desc_text_container
        DoScreenElementMorph id = { desc_text_container child = text } alpha = 0.0 time = 0.2
        SetScreenElementProps id = { desc_text_container child = text } text = " "
        dadmod_desc_strip alpha = 0.0
        KillSpawnedScript Name = dadmod_desc_fit_later
        KillSpawnedScript Name = dadmod_desc_hide_later
        SpawnScript dadmod_desc_hide_later params = { seq = ( dadmod_desc_seq ) }
    endif
    if ScreenElementExists id = tp_helper_text
        DoScreenElementMorph id = tp_helper_text alpha = 0.0 time = 0.2
        SetScreenElementProps id = tp_helper_text text = " "
    endif
endscript

script dadmod_desc_hide_later
    wait 2 gameframes
    if not (<seq> = ( dadmod_desc_seq ))
        return
    endif
    if not ScreenElementExists id = desc_text_container
        return
    endif
    if desc_text_container : GetSingleTag dadmod_box
        dadmod_desc_fit hide
    endif
endscript

script make_thugpro_menu_item {
    parent_id = current_menu
    Dims = (3.2e+02,20.5)
    Just = [ LEFT , CENTER ]
    text_just = [ LEFT , CENTER ]
    text_alpha = 1.0
    Scale = 1.0
    width_ajustment = 1.0
    focus_script = NullScript
    unfocus_script = NullScript
    focus_params = { }
    unfocus_params = { }
    child_texture_offset = (-183.0,1e+01)
    child_texture_alpha = 0.0
    child_texture_scale = 0.8
    extra_text_scale = 0.2
    extra_text_align = CENTER
    }
    if GotParam id
        if not GotParam dadmod_ins_inner
            dadmod_ins_check id = <id>
            if (<dadmod_ins> = 1)
                make_thugpro_menu_item <...> dadmod_ins_inner
                dadmod_ins_items
                return
            endif
        endif
    endif
    if not GotParam dadmod_replay
        dadmod_capture_item <...>
        if (<captured> = 1)
            return
        endif
    endif
    if not GotParam dadmod_rebuild
        dadmod_keep_item <...>
    endif
    if GotParam #"0x1d710c47"
        make_thugpro_menu_item_orig <...>
        return
    endif
    if GotParam #"0x8f12a08c"
        make_thugpro_menu_item_orig <...>
        return
    endif
    if ScreenElementExists ID = <ID>
        RemoveParameter ID
    endif
    if GotParam helper_text
        edmsg2 "@FIXME: \\c2'%a', got param helper_text!" #"0x174841bc" = <TEXT>
    endif
    if GotParam ID
        container_id = <ID>
    else
        FormatText TextName = auto_id "autoid_%a_%b" #"0x174841bc" = randomrange (0.0,2048.0) #"0x8e411006" = randomrange (0.0,8096.0)
        FormatText ChecksumName = container_id "%a" #"0x174841bc" = <auto_id>
    endif
    if GotParam not_focusable
        <text_alpha> = 0.4
        if GotParam heading_alpha
            <text_alpha> = <heading_alpha>
        endif
        <focusable> = not_focusable
    endif
    if not ScreenElementExists ID = { <parent_id> child = 0 }
        <first_item> = first_item
        <actually_first_item> = first_item
    endif
    if GotParam line_top
        <first_item> = first_item
    endif
    if GotParam line_bot
        <last_item> = last_item
    endif
    if <parent_id> : GetSingleTag boxed
    endif
    if GotParam no_box
        RemoveParameter boxed
    endif
    if <parent_id> : GetSingleTag SCROLLING
    endif
    if <parent_id> : GetSingleTag wide_extra_text
    endif
    if <parent_id> : GetSingleTag colorful
    endif
    if <parent_id> : GetSingleTag menu_item_max_width
        <max_width> = <menu_item_max_width>
        RemoveParameter menu_item_max_width
    endif
    if GotParam centered
        text_just = [ CENTER , CENTER ]
        text_offset = (158.0,0.0)
    endif
    if <parent_id> : GetSingleTag width_ajustment
        Printf "Got width_ajustment style from parent menu!"
    endif
    <bar_scale> = ( ( (0.32,0.0) * <width_ajustment> ) + (0.0,0.24) )
    <box_line_width> = ( (8e+01,0.0) * <width_ajustment> )
    <box_line_pos> = ( ( (3.2e+02,0.0) * <width_ajustment> ) + (-4.0,0.0) )
    <option_arrow_left_offset> = (2e+01,1e+01)
    <option_arrow_right_offset> = ( (1.4e+02,1e+01) - (4.0,0.0) )
    <extra_text_offset> = ( (8e+01,0.0) + (-4.0,1e+01) )
    if GotParam wide_extra_text
        <extra_text_offset> = ( <extra_text_offset> - (2e+01,0.0) )
        <option_arrow_left_offset> = ( <option_arrow_left_offset> - (4e+01,0.0) )
    endif
    <option_arrow_left_offset> = ( <option_arrow_left_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    <option_arrow_right_offset> = ( <option_arrow_right_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    <extra_text_offset> = ( <extra_text_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    CreateScreenElement {
    TYPE = ContainerElement
    ID = <container_id>
    Parent = <parent_id>
    Scale = <Scale>
    z_priority = 1000
    Dims = <Dims>
    Just = <Just>
    <focusable>
    }
    <container_id> : SetTags Parent = <parent_id>
    <container_id> : SetTags dadmod_base_scale = <Scale>
    if GotParam sub_label
        <container_id> : SetTags dadmod_sub = <sub_label>
    endif
    if GotParam not_focusable
        <container_id> : SetTags dadmod_nf = 1
    endif
    if not GotParam not_counted
        if <parent_id> : GetSingleTag menu_item_count
            <container_id> : SetTags menu_item_index = <menu_item_count>
            <parent_id> : SetTags menu_item_count = ( <menu_item_count> + 1 )
        endif
    endif
    if GotParam actually_first_item
        <container_id> : SetTags first_item = <actually_first_item>
    endif
    if GotParam child_texture_persistent
        <container_id> : SetTags child_texture_persistent = 1
    endif
    if GotParam sub_label
        dadmod_hl_style
        if (<hl> = 3)
            TEXT = <sub_label>
        endif
    endif
    if GotParam TEXT
        GetUpperCaseString <TEXT>
        CreateScreenElement {
        TYPE = TextElement
        local_id = TEXT
        Parent = <container_id>
        TEXT = <TEXT>
        Font = Crillee
        Scale = 0.2
        Pos = <text_offset>
        Just = <text_just>
        Alpha = <text_alpha>
        rgba = ( ( THUGPRO_GlobalThemeInfo ) . UNHIGHLIGHTED_TEXT_COLOR )
        z_priority = 1002
        }
        <container_id> : SetTags dadmod_txt = <TEXT>
        if GotParam centered
            <container_id> : SetTags dadmod_center = 1
        endif
        if GotParam max_width
            truncate_string ID = { <container_id> child = TEXT } max_width = <max_width>
        endif
    endif
    if GotParam extra_text
        RemoveParameter UpperCaseString
        GetUpperCaseString <extra_text>
        GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <extra_text_offset>
        CreateScreenElement {
        TYPE = TextElement
        local_id = extra_text
        Parent = <container_id>
        TEXT = <extra_text>
        Font = Crillee
        Scale = <extra_text_scale>
        Pos = <Pos>
        internal_just = [ CENTER CENTER ]
        Just = [ CENTER CENTER ]
        rgba = [ 90 90 90 90 ]
        z_priority = 1006
        Alpha = <text_alpha>
        }
        if GotParam option_arrows
            GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <option_arrow_left_offset>
            CreateScreenElement {
            TYPE = SpriteElement
            local_id = left_arrow
            Parent = <container_id>
            Just = [ CENTER , CENTER ]
            Alpha = 0.0
            rgba = [ 128 128 128 128 ]
            Texture = left_arrow
            Pos = <Pos>
            Scale = 0.4
            z_priority = 1002
            }
            GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <option_arrow_right_offset>
            CreateScreenElement {
            TYPE = SpriteElement
            local_id = right_arrow
            Parent = <container_id>
            Just = [ CENTER , CENTER ]
            Alpha = 0.0
            rgba = [ 128 128 128 128 ]
            Texture = right_arrow
            Pos = <Pos>
            Scale = 0.4
            z_priority = 1002
            }
        endif
    endif
    if GotParam child_texture
        GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <child_texture_offset>
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = ICON
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = <child_texture_alpha>
        Texture = <child_texture>
        Pos = <Pos>
        Scale = <child_texture_scale>
        rgba = <child_texture_rgba>
        z_priority = 1004
        }
    endif
    if not GotParam no_bar
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = Bar
        Parent = <container_id>
        Just = <Just>
        Alpha = 0.0
        Texture = new_menu_bar
        Pos = (-5.0,2.5)
        Scale = <bar_scale>
        z_priority = 500
        }
    endif
    if GotParam boxed
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = line_left
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = 1.0
        Texture = WHITE
        Pos = (-4.0,0.0)
        Scale = (0.1,5.7)
        z_priority = 600
        }
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = line_right
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = 1.0
        Texture = WHITE
        Pos = <box_line_pos>
        Scale = (0.1,5.7)
        z_priority = 600
        }
        if not GotParam SCROLLING
            if GotParam first_item
                CreateScreenElement {
                TYPE = SpriteElement
                local_id = line_top
                Parent = <container_id>
                Just = <Just>
                Alpha = 1.0
                Texture = WHITE
                Pos = (-4.0,-11.0)
                Scale = ( <box_line_width> + (0.0,0.1) )
                z_priority = 600
                }
            endif
            if GotParam last_item
                CreateScreenElement {
                TYPE = SpriteElement
                local_id = line_bot
                Parent = <container_id>
                Just = <Just>
                Alpha = 1.0
                Texture = WHITE
                Pos = (-4.0,11.0)
                Scale = ( <box_line_width> + (0.0,0.1) )
                z_priority = 600
                }
            endif
        endif
        if GotParam colorful
            <background_rgba> = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        else
            <background_rgba> = ( ( THUGPRO_GlobalThemeInfo ) . UNHIGHLIGHTED_TEXT_COLOR )
        endif
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = background
        Parent = <container_id>
        Pos = (-4.0,0.0)
        Scale = ( <box_line_width> + (0.0,5.7) )
        Just = <Just>
        Texture = WHITE
        Alpha = 0.5
        rgba = [ 20 20 20 128 ]
        z_priority = 400
        }
    endif
    if GotParam not_focusable
        return
    endif
    SetScreenElementProps {
    ID = <container_id>
    event_handlers = [
    { Focus thugpro_menu_item_focus }
    { unfocus thugpro_menu_item_unfocus }
    { Focus <focus_script> Params = <focus_params> }
    { unfocus <unfocus_script> Params = <unfocus_params> }
    ]
    replace_handlers
    }
    if GotParam description_text
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = [
        { Focus thugpro_menu_desc_text_focus Params = { TEXT = <description_text> } }
        { unfocus thugpro_menu_desc_text_unfocus }
        ]
        }
    endif
    if GotParam option_arrows
        if GotParam option_arrows_callback
            if GotParam option_arrows_callback_params
                if GotParam pad_choose
                    handlers = [
                    { pad_left <option_arrows_callback> Params = ( { LEFT } + <option_arrows_callback_params> ) }
                    { pad_right <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    { pad_choose <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    ]
                else
                    handlers = [
                    { pad_left <option_arrows_callback> Params = ( { LEFT } + <option_arrows_callback_params> ) }
                    { pad_right <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    ]
                endif
            else
                if GotParam pad_choose
                    handlers = [
                    { pad_left <option_arrows_callback> Params = { LEFT } }
                    { pad_right <option_arrows_callback> Params = { RIGHT } }
                    { pad_choose <option_arrows_callback> Params = { RIGHT } }
                    ]
                else
                    handlers = [
                    { pad_left <option_arrows_callback> Params = { LEFT } }
                    { pad_right <option_arrows_callback> Params = { RIGHT } }
                    ]
                endif
            endif
            SetScreenElementProps {
            ID = <container_id>
            event_handlers = <handlers>
            }
        endif
    endif
    if GotParam pad_back_script
        if GotParam pad_choose_params
            handlers = [ { pad_back <pad_back_script> Params = <pad_back_params> } ]
        else
            handlers = [ { pad_back <pad_back_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
    endif
    if GotParam pad_choose_script
        if GotParam pad_choose_params
            handlers = [ { pad_choose <pad_choose_script> Params = <pad_choose_params> } ]
        else
            handlers = [ { pad_choose <pad_choose_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
        if not GotParam no_sound
            SetScreenElementProps {
            ID = <container_id>
            event_handlers = [ { pad_choose generic_menu_pad_choose_sound } ]
            }
        endif
    endif
    if GotParam pad_option_script
        if GotParam pad_option_params
            handlers = [ { pad_option <pad_option_script> Params = <pad_option_params> } ]
        else
            handlers = [ { pad_option <pad_option_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
    endif
    if GotParam dadmod_rebuild
        dadmod_keep_link h = <dadmod_rebuild> item = <container_id>
    else
        dadmod_keep_link h = ( dadmod_keep_last ) item = <container_id>
    endif
    return { menu_item_id = <container_id> }
endscript

dadmod_cap_count = 0

script dadmod_capture_item
    if ScreenElementExists id = <parent_id>
        if <parent_id> : GetSingleTag Anchor
            if GotParam text
                THUGRECOMP_MenuSeen menu = <Anchor> text = <text>
            endif
            if THUGRECOMP_MenuHasOrder menu = <Anchor>
                Change dadmod_cap_count = ( dadmod_cap_count + 1 )
                FormatText ChecksumName = holder "dadmod_cap_%i" i = ( dadmod_cap_count )
                CreateScreenElement {
                type = ContainerElement
                parent = root_window
                id = <holder>
                alpha = 0.0
                }
                <holder> : SetTags <...>
                THUGRECOMP_CapturePush id = <holder> text = <text>
                return captured = 1
            endif
        endif
    endif
    return captured = 0
endscript

script dadmod_replay_all
    if not ScreenElementExists id = <menu_parent>
        THUGRECOMP_CaptureClear
        return
    endif
    if not <menu_parent> : GetSingleTag Anchor
        return
    endif
    begin
        if not THUGRECOMP_CaptureNext menu = <Anchor>
            break
        endif
        h = <id>
        if (<hide> = 0)
            dadmod_replay_item h = <h> grey = <grey> stock = <stock>
        endif
        if ScreenElementExists id = <h>
            DestroyScreenElement id = <h>
        endif
    repeat
endscript

script dadmod_replay_item
    <h> : GetTags
    if (<grey> = 1)
        make_thugpro_menu_item <...> dadmod_replay not_focusable = not_focusable
    else
        make_thugpro_menu_item <...> dadmod_replay
    endif
endscript

script thugpro_menu_finalize {
    Parent = current_menu
    }
    dadmod_skc_et_items
    dadmod_replay_all menu_parent = <Parent>
    thugpro_menu_find_last_item { Parent = <Parent> }
    if GotParam last_item_id
        SetScreenElementProps ID = <last_item_id> TAGS = { last_item = last_item }
    endif
    if <Parent> : GetSingleTag boxed
        <Parent> : GetSingleTag width_ajustment
        if not <Parent> : GetSingleTag SCROLLING
            thugpro_menu_mark_last_item { ID = <last_item_id> width_ajustment = <width_ajustment> Parent = <Parent> }
        endif
    endif
    thugpro_menu_update_counter_text <...>
    dadmod_move_hint_menu
    SetScreenElementProps ID = root_window TAGS = { menu_state = ON }
    if not GotParam no_animate
        RunScriptOnScreenElement ID = <Parent> animate_in_fade
    endif
    if not GotParam no_focus
        if ScreenElementExists id = <Parent>
            if GotParam focus_target
                FireEvent TYPE = Focus Target = <Parent> data = { child_id = <focus_target> }
            else
                FireEvent TYPE = Focus Target = <Parent>
            endif
        endif
    endif
    KillSpawnedScript Name = dadmod_fit_all
    SpawnScript dadmod_fit_all
endscript

dadmod_keep_n = 0

dadmod_keep_last = none

dadmod_reorder_on = 0

dadmod_reorder_pick = -1

dadmod_reorder_menu = none

script dadmod_keep_item
    Change dadmod_keep_last = none
    if not ScreenElementExists id = current_menu_anchor
        return
    endif
    if not ScreenElementExists id = <parent_id>
        return
    endif
    if not <parent_id> : GetSingleTag Anchor
        return
    endif
    if not current_menu_anchor : GetSingleTag dadmod_keep_menu
        Change dadmod_keep_n = 0
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_keep_menu = <Anchor> }
    endif
    if not GotParam stock
        stock = ( dadmod_keep_n )
    endif
    FormatText ChecksumName = keep_h "dadmod_keep_%i" i = ( dadmod_keep_n )
    if ScreenElementExists id = <keep_h>
        DestroyScreenElement id = <keep_h>
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = current_menu_anchor
    id = <keep_h>
    alpha = 0.0
    }
    <keep_h> : SetTags <...>
    Change dadmod_keep_last = <keep_h>
    Change dadmod_keep_n = ( dadmod_keep_n + 1 )
endscript

script dadmod_keep_link
    if ScreenElementExists id = <h>
        SetScreenElementProps id = <h> tags = { dadmod_item = <item> }
    endif
endscript

script dadmod_reorder_keys
    if ScreenElementExists id = startup_menu
        return
    endif
    if not ScreenElementExists id = current_menu_anchor
        Change dadmod_reorder_on = 0
        return
    endif
    if IsTrue dadmod_reorder_on
        live = 0
        if current_menu_anchor : GetSingleTag dadmod_reorder_live
            live = <dadmod_reorder_live>
        endif
        if (<live> = 0)
            Change dadmod_reorder_on = 0
        endif
    endif
    dadmod_pad_chord
    if THUGRECOMP_KeyPressed key = "F9"
        SpawnScript dadmod_reorder_toggle
    endif
    if (<chord> = 1)
        SpawnScript dadmod_reorder_toggle
    endif
    if IsTrue dadmod_reorder_on
        if THUGRECOMP_KeyPressed key = "F10"
            SpawnScript dadmod_reorder_undo
        endif
        if THUGRECOMP_KeyPressed key = "F12"
            SpawnScript dadmod_reorder_reset
        endif
        if (<chord> = 2)
            SpawnScript dadmod_reorder_undo
        endif
        if (<chord> = 3)
            SpawnScript dadmod_reorder_reset
        endif
    endif
endscript

script dadmod_reorder_toggle
    if not ScreenElementExists id = current_menu_anchor
        return
    endif
    if IsTrue dadmod_reorder_on
        Change dadmod_reorder_on = 0
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
        THUGRECOMP_Log text = "menu reorder: done"
        return
    endif
    if not current_menu_anchor : GetSingleTag dadmod_keep_menu
        return
    endif
    if ( ( dadmod_keep_n ) < 2 )
        return
    endif
    if current_menu_anchor : GetSingleTag dadmod_reorder_live
        if not THUGRECOMP_ReorderPermInit menu = <dadmod_keep_menu> count = ( dadmod_keep_n )
            return
        endif
    else
        if not THUGRECOMP_ReorderPermInit menu = <dadmod_keep_menu> count = ( dadmod_keep_n ) fresh = 1
            return
        endif
    endif
    Change dadmod_reorder_menu = <dadmod_keep_menu>
    Change dadmod_reorder_pick = -1
    Change dadmod_reorder_on = 1
    THUGRECOMP_Log text = "menu reorder: move mode on"
    dadmod_reorder_rebuild
endscript

script dadmod_reorder_rebuild
    n = ( dadmod_keep_n )
    i = 0
    begin
        if (<i> = <n>)
            break
        endif
        FormatText ChecksumName = h "dadmod_keep_%i" i = <i>
        if ScreenElementExists id = <h>
            if <h> : GetSingleTag dadmod_item
                if ScreenElementExists id = <dadmod_item>
                    DestroyScreenElement id = <dadmod_item>
                endif
            endif
        endif
        i = ( <i> + 1 )
    repeat
    THUGRECOMP_ReorderPermInit menu = ( dadmod_reorder_menu ) count = <n>
    pos = 0
    begin
        if (<pos> = <n>)
            break
        endif
        if THUGRECOMP_ReorderPermAt pos = <pos>
            FormatText ChecksumName = h "dadmod_keep_%i" i = <idx>
            if ScreenElementExists id = <h>
                dadmod_reorder_make h = <h> pos = <pos>
            endif
        endif
        pos = ( <pos> + 1 )
    repeat
    if IsTrue dadmod_reorder_on
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_reorder_live = 1 }
    else
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_reorder_live = 0 }
    endif
    thugpro_menu_finalize no_animate
    if GotParam focus_pos
        SpawnScript dadmod_reorder_refocus params = { focus_pos = <focus_pos> n = <n> }
    endif
endscript

script dadmod_reorder_refocus
    wait 2 gameframes
    if not ScreenElementExists id = current_menu
        return
    endif
    if GetScreenElementChildren id = current_menu
        GetArraySize <children>
        k = ( <array_size> - <n> + <focus_pos> )
        if (<k> > -1)
            if (<k> < <array_size>)
                FireEvent Type = unfocus target = current_menu
                FireEvent Type = Focus target = current_menu data = { child_id = ( <children> [ <k> ] ) }
            endif
        endif
    endif
endscript

script dadmod_reorder_make
    dadmod_ro_holder = <h>
    <dadmod_ro_holder> : GetTags
    RemoveParameter dadmod_item
    if IsTrue dadmod_reorder_on
        RemoveParameter option_arrows
        RemoveParameter option_arrows_callback
        RemoveParameter option_arrows_callback_params
        RemoveParameter pad_choose
        RemoveParameter not_focusable
        focus_script = NullScript
        unfocus_script = NullScript
        focus_params = { }
        unfocus_params = { }
        if GotParam text
            if ( ( dadmod_reorder_pick ) = <pos> )
                FormatText TextName = text "\\c4> %s <" s = <text>
            endif
        endif
        if ( ( dadmod_reorder_pick ) = <pos> )
            description_text = "Now choose where to put it"
        else
            if dadmod_on_pad
                description_text = "Move mode: \\b9+\\bh undo, \\b9+\\be stock order, \\b9+\\bg done. Pick an option, then where it goes"
            else
                description_text = "Move mode: pick an option, then where it goes. F10 undo, F12 stock order, F9 done"
            endif
        endif
        pad_choose_script = dadmod_reorder_choose
        pad_choose_params = { pos = <pos> }
    endif
    make_thugpro_menu_item <...> dadmod_rebuild = <dadmod_ro_holder> dadmod_replay
    return made_id = <menu_item_id>
endscript

script dadmod_reorder_choose
    if ( ( dadmod_reorder_pick ) = -1 )
        Change dadmod_reorder_pick = <pos>
    else
        THUGRECOMP_ReorderPermMove from = ( dadmod_reorder_pick ) to = <pos>
        Change dadmod_reorder_pick = -1
        dadmod_reorder_save
    endif
    dadmod_reorder_rebuild focus_pos = <pos>
endscript

script dadmod_reorder_save
    THUGRECOMP_ReorderBegin menu = ( dadmod_reorder_menu )
    n = ( dadmod_keep_n )
    pos = 0
    begin
        if (<pos> = <n>)
            break
        endif
        if THUGRECOMP_ReorderPermAt pos = <pos>
            FormatText ChecksumName = h "dadmod_keep_%i" i = <idx>
            t = "-"
            if ScreenElementExists id = <h>
                if <h> : GetSingleTag text
                    t = <text>
                endif
            endif
            THUGRECOMP_ReorderAdd text = <t>
        endif
        pos = ( <pos> + 1 )
    repeat
    THUGRECOMP_ReorderSave
endscript

script dadmod_reorder_undo
    if THUGRECOMP_ReorderUndo menu = ( dadmod_reorder_menu )
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
    endif
endscript

script dadmod_reorder_reset
    if THUGRECOMP_ReorderReset menu = ( dadmod_reorder_menu )
        THUGRECOMP_ReorderPermPush
        n = ( dadmod_keep_n )
        pos = 0
        begin
            if (<pos> = <n>)
                break
            endif
            i = 0
            begin
                if (<i> = <n>)
                    break
                endif
                FormatText ChecksumName = h "dadmod_keep_%i" i = <i>
                if ScreenElementExists id = <h>
                    if <h> : GetSingleTag stock
                        if (<stock> = <pos>)
                            THUGRECOMP_ReorderPermSet pos = <pos> idx = <i>
                        endif
                    endif
                endif
                i = ( <i> + 1 )
            repeat
            pos = ( <pos> + 1 )
        repeat
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
    endif
endscript

script dadmod_move_hint_menu
    anchor_id = helper_text_anchor
    if ScreenElementExists id = dadmod_helper_store
        dadmod_helper_store : GetSingleTag anchor_id
    endif
    dadmod_move_hint anchor_id = <anchor_id>
endscript

script dadmod_move_hint_off anchor_id = helper_text_anchor
    if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_undo } }
        DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_undo } }
    endif
    if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_stock } }
        DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_stock } }
    endif
    if GotParam all
        if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_move } }
            DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_move } }
        endif
    endif
endscript

script dadmod_hint_text
    if ScreenElementExists id = { <anchor_id> child = { line1 child = <name> } }
        SetScreenElementProps id = { <anchor_id> child = { line1 child = <name> } } text = <text>
        return
    endif
    CreateScreenElement {
    Type = textElement
    parent = { <anchor_id> child = line1 }
    local_id = <name>
    font = dialog
    text = <text>
    rgba = [ 70 70 70 108 ]
    scale = 0.75
    z_priority = 2100
    Pos = (0.0,0.0)
    not_focusable
    }
endscript

script dadmod_move_hint
    if not GotParam anchor_id
        anchor_id = helper_text_anchor
    endif
    if not ScreenElementExists id = <anchor_id>
        return
    endif
    if not ScreenElementExists id = { <anchor_id> child = line1 }
        return
    endif
    ok = 0
    if not ScreenElementExists id = startup_menu
        if ScreenElementExists id = current_menu_anchor
            if current_menu_anchor : GetSingleTag dadmod_keep_menu
                if ( ( dadmod_keep_n ) > 1 )
                    ok = 1
                endif
            endif
        endif
    endif
    if (<ok> = 0)
        dadmod_move_hint_off all = 1 anchor_id = <anchor_id>
        return
    endif
    on = 0
    if IsTrue dadmod_reorder_on
        on = 1
    endif
    if ( ( GLOBAL_CtrlLayout ) = 0 )
        if (<on> = 1)
            t1 = "F9 = Done"
            t2 = "F10 = Undo"
            t3 = "F12 = Stock order"
        else
            t1 = "F9 = Reorder"
        endif
    else
        if (<on> = 1)
            t1 = "\\b9+\\bg = Done"
            t2 = "\\b9+\\bh = Undo"
            t3 = "\\b9+\\be = Stock order"
        else
            t1 = "\\b9+\\bg = Reorder"
        endif
    endif
    dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_move text = <t1>
    if (<on> = 1)
        dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_undo text = <t2>
        dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_stock text = <t3>
    else
        dadmod_move_hint_off anchor_id = <anchor_id>
    endif
endscript

script dadmod_helper_seen
    if ScreenElementExists id = dadmod_helper_store
        DestroyScreenElement id = dadmod_helper_store
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_helper_store
    alpha = 0.0
    }
    dadmod_helper_store : SetTags <...>
    if ( ( GLOBAL_CtrlLayout ) = 0 )
        if not GotParam spacing_between
            return spacing_between = 26
        endif
        if ( <spacing_between> < 26 )
            return spacing_between = 26
        endif
    endif
endscript

script dadmod_helper_refresh
    if not ScreenElementExists id = dadmod_helper_store
        return
    endif
    dadmod_helper_store : GetTags
    if not GotParam anchor_id
        anchor_id = helper_text_anchor
    endif
    if not ScreenElementExists id = <anchor_id>
        return
    endif
    if GotParam parent
        if not ScreenElementExists id = <parent>
            return
        endif
    endif
    create_helper_text <...>
endscript

script dadmod_prompt_tick
    dadmod_char_guide_tick
    if not THUGRECOMP_InputDevice
        return
    endif
    if ScreenElementExists id = keyboard_anchor
        return
    endif
    if THUGRECOMP_BindPoll
        return
    endif
    if THUGRECOMP_InputDevice apply = 1
        Change GLOBAL_CtrlLayout = <layout>
        dadmod_helper_refresh
    endif
endscript

script dadmod_btn
    if THUGRECOMP_ButtonText <...>
        return btn = <text>
    endif
    return btn = "?"
endscript

script dadmod_on_pad
    THUGRECOMP_InputDevice
    if (<device> = 1)
        return true
    endif
    return false
endscript

script dadmod_pad_chord
    chord = 0
    if THUGRECOMP_PadHeld button = "back"
        if THUGRECOMP_PadPressed button = "leftshoulder"
            chord = 1
        endif
        if THUGRECOMP_PadPressed button = "rightshoulder"
            chord = 2
        endif
        if THUGRECOMP_PadPressed button = "lefttrigger"
            chord = 3
        endif
    endif
    return chord = <chord>
endscript

script keyboard_key_focus
    if ObjectExists id = <id>
        DoScreenElementMorph id = <id> time = 0.05 scale = ( <org_scale> * 1.05 )
    endif
endscript

script keyboard_text_focus
    SetProps rgba = ( ( THUGPRO_GlobalThemeInfo ) . MENU_TITLE_COLOR )
endscript

script thugpro_menu_item_update_extra_text
    if ScreenElementExists id = { <id> child = extra_text }
        if GotParam text
            GetUpperCaseString <text>
            SetScreenElementProps id = { <id> child = extra_text } text = <text>
        else
            if GotParam off
                SetScreenElementProps id = { <id> child = extra_text } text = "OFF"
            else
                SetScreenElementProps id = { <id> child = extra_text } text = "ON"
            endif
        endif
        dadmod_fit_extra id = <id>
    endif
endscript

script dadmod_hl_style
    fxs = ( dadmod_ui_fx )
    if StructureContains structure = <fxs> hl
        return hl = ( <fxs> . hl )
    endif
    return hl = 0
endscript

script dadmod_hl_measure
    GetScreenElementDims id = <id>
    iw = <width>
    GetScreenElementDims id = { <id> child = text }
    lw = 0.0
    if (<iw> > 0)
        lw = ( <width> * 320.0 / <iw> )
    endif
    RemoveParameter dadmod_center
    <id> : GetTags
    left = 0.0
    if GotParam dadmod_center
        left = ( 158.0 - <lw> / 2.0 )
    endif
    return lw = <lw> left = <left>
endscript

script dadmod_hl_clear
    if ScreenElementExists id = { <id> child = dadmod_hl_u }
        DestroyScreenElement id = { <id> child = dadmod_hl_u }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_m }
        DestroyScreenElement id = { <id> child = dadmod_hl_m }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_l }
        DestroyScreenElement id = { <id> child = dadmod_hl_l }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_r }
        DestroyScreenElement id = { <id> child = dadmod_hl_r }
    endif
endscript

script dadmod_hl_focus
    dadmod_hl_style
    if (<hl> = 0)
        return
    endif
    if not ScreenElementExists id = <id>
        return
    endif
    if ScreenElementExists id = { <id> child = bar }
        DoScreenElementMorph id = { <id> child = bar } alpha = 0.0 time = 0
        RunScriptOnScreenElement id = { <id> child = bar } dadmod_hl_hide_bar
    endif
    Change random_effect_break_loop = 1
    dadmod_hl_clear id = <id>
    RemoveParameter dadmod_base_scale
    RemoveParameter dadmod_slid
    dadmod_grown = 0
    <id> : GetTags
    bs = 1.0
    if GotParam dadmod_base_scale
        bs = <dadmod_base_scale>
    endif
    switch <hl>
    case 1
        if (<dadmod_grown> = 0)
            <id> : SetTags dadmod_grown = 1
            dadmod_hl_grow id = <id> s = 1.15
        endif
    case 2
        slid = 0
        if GotParam dadmod_slid
            slid = <dadmod_slid>
        endif
        if (<slid> = 0)
            <id> : SetTags dadmod_slid = 1
            RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_slide params = { dx = 12.0 }
        endif
    case 3
        dadmod_hl_brackets id = <id> on = 1
    case 4
        RunScriptOnScreenElement id = <id> dadmod_hl_decorate params = { id = <id> kind = 4 }
    case 5
        RunScriptOnScreenElement id = <id> dadmod_hl_decorate params = { id = <id> kind = 5 }
    case 6
        dadmod_hl_spotlight id = <id>
    case 7
        <id> : SetTags dadmod_bounce = 1
        RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_bounce params = { item = <id> }
    endswitch
endscript

script dadmod_hl_unfocus
    if not ScreenElementExists id = <id>
        return
    endif
    dadmod_hl_clear id = <id>
    RemoveParameter dadmod_base_scale
    RemoveParameter dadmod_slid
    dadmod_grown = 0
    <id> : GetTags
    if GotParam dadmod_base_scale
        DoScreenElementMorph id = <id> scale = <dadmod_base_scale> time = 0.08
    endif
    if GotParam dadmod_slid
        if (<dadmod_slid> = 1)
            <id> : SetTags dadmod_slid = 0
            if ScreenElementExists id = { <id> child = text }
                RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_slide params = { dx = -12.0 }
            endif
        endif
    endif
    if (<dadmod_grown> = 1)
        <id> : SetTags dadmod_grown = 0
        dadmod_hl_grow id = <id> s = ( 1.0 / 1.15 )
    endif
    <id> : SetTags dadmod_bounce = 0
    dadmod_hl_brackets id = <id> on = 0
    dadmod_hl_style
    if (<hl> = 6)
        if ScreenElementExists id = { <id> child = text }
            DoScreenElementMorph id = { <id> child = text } alpha = 0.2 time = 0.1
        endif
    endif
endscript

script dadmod_hl_slide
    DoMorph time = 0.08 Pos = { ( (1.0,0.0) * <dx> ) relative }
endscript

script dadmod_hl_bounce
    begin
        if not ScreenElementExists id = <item>
            break
        endif
        RemoveParameter dadmod_bounce
        <item> : GetTags
        if not GotParam dadmod_bounce
            break
        endif
        if (<dadmod_bounce> = 0)
            break
        endif
        DoMorph time = 0.18 Pos = { (0.0,-3.0) relative }
        DoMorph time = 0.18 Pos = { (0.0,3.0) relative }
    repeat
endscript

script dadmod_hl_decorate
    wait 4 gameframes
    if not ScreenElementExists id = <id>
        return
    endif
    if not ( ( dadmod_ui_focused ) = <id> )
        return
    endif
    dadmod_hl_clear id = <id>
    dadmod_hl_measure id = <id>
    col = ( dadmod_ui_bar_rgba )
    switch <kind>
    case 3
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_l parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> - 6.0 ) ) just = [ center center ] scale = (0.3,2.2) rgba = <col> z_priority = 1003 }
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_r parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> + <lw> + 6.0 ) ) just = [ center center ] scale = (0.3,2.2) rgba = <col> z_priority = 1003 }
    case 4
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_u parent = <id> texture = white2 Pos = ( (1.0,0.0) * <left> + (0.0,9.0) ) just = [ left center ] scale = ( (1.0,0.0) * ( <lw> / 8.0 ) + (0.0,0.25) ) rgba = <col> z_priority = 1003 }
    case 5
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_m parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> - 9.0 ) ) just = [ center center ] scale = (0.8,0.8) rot_angle = 45 rgba = <col> z_priority = 1003 }
    endswitch
endscript

script dadmod_hl_spotlight
    p = <id>
    RemoveParameter Parent
    <id> : GetTags
    if not GotParam Parent
        return
    endif
    if GetScreenElementChildren id = <Parent>
        GetArraySize <children>
        i = 0
        begin
            if (<i> = <array_size>)
                break
            endif
            c = ( <children> [ <i> ] )
            if ScreenElementExists id = { <c> child = text }
                RemoveParameter dadmod_nf
                <c> : GetTags
                if not GotParam dadmod_nf
                    if (<c> = <p>)
                        DoScreenElementMorph id = { <c> child = text } alpha = 1.0 time = 0.1
                    else
                        DoScreenElementMorph id = { <c> child = text } alpha = 0.2 time = 0.1
                    endif
                endif
            endif
            i = ( <i> + 1 )
        repeat
    endif
endscript

script dadmod_hl_hide_bar
    wait 2 gameframes
    DoMorph time = 0 alpha = 0.0
    wait 6 gameframes
    DoMorph time = 0 alpha = 0.0
endscript

script dadmod_hl_brackets
    RemoveParameter dadmod_txt
    RemoveParameter dadmod_plain
    <id> : GetTags
    if not GotParam dadmod_txt
        return
    endif
    if (<on> = 1)
        if not GotParam dadmod_plain
            <id> : SetTags dadmod_plain = <dadmod_txt>
            RemoveParameter dadmod_sub
            <id> : GetTags
            bl = <dadmod_txt>
            if GotParam dadmod_sub
                bl = <dadmod_sub>
            endif
            dadmod_hl_bracket_code
            dadmod_hl_text_managed
            if (<bcode> = "scan")
                <id> : SetTags dadmod_txt = <bl> dadmod_brk = "scan"
                RunScriptOnScreenElement id = <id> dadmod_hl_brk_scan params = { id = <id> bl = <bl> }
                return
            endif
            if (<managed> = 1)
                if (<bcode> = "")
                    bcode = "\\cc"
                endif
                <id> : SetTags dadmod_txt = <bl> dadmod_brk = <bcode>
            else
                if (<bcode> = "")
                    FormatText TextName = bt "> %s <" s = <bl>
                else
                    FormatText TextName = bt "%c> \\c0%s %c<" c = <bcode> s = <bl>
                endif
                <id> : SetTags dadmod_txt = <bt>
                if ScreenElementExists id = { <id> child = text }
                    SetScreenElementProps id = { <id> child = text } text = <bt>
                endif
            endif
        endif
    else
        if GotParam dadmod_plain
            <id> : SetTags dadmod_txt = <dadmod_plain> dadmod_brk = ""
            <id> : RemoveTags tags = [ dadmod_plain ]
            dadmod_hl_text_managed
            if (<managed> = 0)
                if ScreenElementExists id = { <id> child = text }
                    SetScreenElementProps id = { <id> child = text } text = <dadmod_plain>
                endif
            endif
        endif
    endif
endscript

script dadmod_hl_text_managed
    dadmod_ui_get key = "ui_rainbow" def = 0
    if (<value> > 4)
        if (<value> < 9)
            return managed = 1
        endif
    endif
    if (<value> = 0)
        dadmod_ui_get key = "ui_colortheme" def = 0
        if (<value> > 0)
            dadmod_ui_get key = "ui_theme_mode" def = 0
            if ( ( <value> = 2 ) or ( <value> = 4 ) or ( <value> = 5 ) )
                return managed = 1
            endif
        endif
    endif
    return managed = 0
endscript

script dadmod_hl_bracket_code
    dadmod_ui_get key = "ui_br_color" def = 10
    switch <value>
    case 1
        return bcode = "\\cc"
    case 2
        return bcode = "\\cg"
    case 3
        return bcode = "\\cb"
    case 4
        return bcode = "\\c5"
    case 5
        return bcode = "\\cf"
    case 6
        return bcode = "\\cd"
    case 7
        return bcode = "\\c6"
    case 8
        return bcode = "\\cu"
    case 9
        return bcode = "\\c7"
    case 10
        return bcode = "scan"
    endswitch
    return bcode = ""
endscript

script dadmod_hl_brk_code t = 0
    codes = [ "\\cg" "\\cb" "\\ce" "\\c5" "\\cf" "\\c4" "\\cd" "\\c6" "\\cu" "\\cs" "\\c7" "\\cl" ]
    dadmod_ui_get key = "ui_br_speed" def = 5
    k = ( <t> * 0.4 * <value> )
    CastToInteger k
    dadmod_ui_mod v = <k> m = 12
    return brk_code = ( <codes> [ <v> ] )
endscript

script dadmod_hl_brk_scan
    k = 0
    begin
        if not ScreenElementExists id = <id>
            break
        endif
        if not ( ( dadmod_ui_focused ) = <id> )
            break
        endif
        RemoveParameter dadmod_brk
        <id> : GetTags
        if not GotParam dadmod_brk
            break
        endif
        if not (<dadmod_brk> = "scan")
            break
        endif
        dadmod_hl_text_managed
        if (<managed> = 0)
            dadmod_hl_brk_code t = ( <k> * 0.5 )
            FormatText TextName = bt "%c> \\c0%s %c<" c = <brk_code> s = <bl>
            if ScreenElementExists id = { <id> child = text }
                SetScreenElementProps id = { <id> child = text } text = <bt>
            endif
        endif
        k = ( <k> + 1 )
        wait 0.1 seconds
    repeat
endscript

script dadmod_hl_grow
    dadmod_hl_grow_child id = { <id> child = text } s = <s>
    dadmod_hl_grow_child id = { <id> child = extra_text } s = <s>
    dadmod_hl_grow_child id = { <id> child = left_arrow } s = <s>
    dadmod_hl_grow_child id = { <id> child = right_arrow } s = <s>
    dadmod_hl_grow_child id = { <id> child = icon } s = <s>
endscript

script dadmod_hl_grow_child
    if ScreenElementExists id = <id>
        RunScriptOnScreenElement id = <id> dadmod_hl_grow_morph params = { s = <s> }
    endif
endscript

script dadmod_hl_grow_morph
    DoMorph time = 0.08 scale = <s> relative_scale
endscript

dadmod_layout_block_begin = "Dadmod menus built from dadmod_layout.txt (Host Manager > Dadmod Menus). Items come from dadmod_item_catalog (layout_catalog.q, generated by gen_layout.py)"

dadmod_layout_node = -1

script create_dadmod_setup_menu
    dadmod_layout_open node = 0
endscript

script dadmod_layout_back
    if THUGRECOMP_PadHeld button = "y"
        if ( ( dadmod_ui_focused ) = mmopt_spotpick )
            return
        endif
    endif
    Change dadmod_mm_armed = none
    if (<parent> < 0)
        Change dadmod_layout_node = -1
        dadmod_back_to_main
    else
        dadmod_layout_open node = <parent>
    endif
endscript

script dadmod_layout_open node = 0
    THUGRECOMP_LayoutInfo node = <node>
    Change dadmod_layout_node = <node>
    me = <node>
    hmode = 0
    has_eff = 0
    i = 0
    begin
        if (<i> = <count>)
            break
        endif
        if THUGRECOMP_LayoutChild node = <me> index = <i>
            if (<type> = 1)
                if (<hmode> = 0)
                    hmode = 1
                endif
                if ( ( <key> = "mmopt_spotpick" ) or ( <key> = "mmopt_anim" ) )
                    hmode = 2
                endif
                if (<key> = "mui_rainbow")
                    has_eff = 1
                endif
            endif
        endif
        i = ( <i> + 1 )
    repeat
    switch <hmode>
    case 1
        helper = generic_helper_text_up_down_adjust
    case 2
        helper = dadmod_mm_helper_text
    default
        helper = generic_helper_text
    endswitch
    off_page = 0
    if (<has_eff> = 1)
        dadmod_ui_get key = "ui_rainbow" def = 0 raw
        if (<value> = 0)
            off_page = 1
        endif
        if (<value> = 11)
            off_page = 2
        endif
    endif
    rows = <count>
    if ( <rows> > 13 )
        rows = 13
    endif
    if ( <rows> < 1 )
        rows = 1
    endif
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_layout
    scrolling
    num_items_to_show = <rows>
    menu_title = <title>
    menu_style = MENU_STYLE_LEFT
    helper_text = <helper>
    pad_back_script = dadmod_layout_back
    pad_back_params = { parent = <parent> }
    show_description_panel
    show_gradient
    }
    i = 0
    begin
        if (<i> = <count>)
            break
        endif
        if THUGRECOMP_LayoutChild node = <me> index = <i>
            dadmod_layout_entry <...>
        endif
        i = ( <i> + 1 )
    repeat
    dadmod_desc_panel_right
    if GotParam focus_id
        thugpro_menu_finalize focus_target = <focus_id> no_animate
    else
        thugpro_menu_finalize
    endif
    Change dadmod_mm_armed = none
endscript

script dadmod_layout_static_ok
    switch <type>
    case 1
        keys = [ "mui_rainbow" "mui_hl_style" "mui_br_color" "mui_br_speed" "mui_c_text" "mui_c_textfx" "mui_c_focus" "mui_c_focusfx" "mui_c_bar" "mui_c_barfx" "mui_c_title" "mui_c_titlefx" "mui_c_fxspeed" "mui_rb_speed" "mui_rb_angle" ]
        GetArraySize <keys>
        i = 0
        begin
            if (<i> = <array_size>)
                break
            endif
            if ( ( <keys> [ <i> ] ) = <key> )
                return static_ok = 1
            endif
            i = ( <i> + 1 )
        repeat
    case 2
        if ( ( <label> = "Your colors" ) or ( <label> = "Highlight" ) or ( <label> = "Text" ) )
            return static_ok = 1
        endif
    endswitch
    return static_ok = 0
endscript

script dadmod_layout_entry
    if (<hide> = 1)
        return
    endif
    if (<type> = 2)
        if (<label> = "Theme")
            dadmod_ui_get key = "ui_rainbow" def = 0 raw
            dadmod_ui_effect_resolve v = <value>
            if not (<v> = 9)
                return
            endif
        endif
    endif
    mmc = 0
    if (<type> = 0)
        if ( ( <label> = "Main menu colors" ) or ( <label> = "Main screen options" ) )
            mmc = 1
            dadmod_ui_get key = "ui_rainbow" def = 0 raw
            if not (<value> = 0)
                return
            endif
        endif
    endif
    if GotParam off_page
        if (<off_page> = 1)
            if (<mmc> = 0)
                if not (<type> = 1)
                    return
                endif
                if not ( ( <key> = "mui_rainbow" ) or ( <key> = "mui_hl_style" ) or ( <key> = "mui_br_color" ) or ( <key> = "mui_br_speed" ) or ( <key> = "mui_c_focus" ) )
                    return
                endif
            endif
        endif
        if (<off_page> = 2)
            dadmod_layout_static_ok type = <type> key = <key> label = <label>
            if (<static_ok> = 0)
                return
            endif
        endif
    endif
    switch <type>
    case 0
        if (<desc> = "")
            FormatText TextName = desc "Opens %s" s = <label>
        endif
        FormatText TextName = shown "%s  >" s = <label>
        make_thugpro_menu_item {
        text = <shown>
        sub_label = <label>
        description_text = <desc>
        pad_choose_script = dadmod_layout_open
        pad_choose_params = { node = <child> }
        }
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    case 1
        dadmod_layout_item name = <key> label = <label> grey = <grey>
    case 2
        make_thugpro_menu_item {
        text = <label>
        not_focusable = not_focusable
        centered
        heading_alpha = 0.55
        }
    default
        make_thugpro_menu_item {
        text = " "
        not_focusable = not_focusable
        }
    endswitch
endscript

script dadmod_layout_item
    GetArraySize dadmod_item_catalog
    j = 0
    begin
        if (<j> = <array_size>)
            return
        endif
        e = ( dadmod_item_catalog [ <j> ] )
        if ( ( <e> . name ) = <name> )
            break
        endif
        j = ( <j> + 1 )
    repeat
    p = ( <e> . p )
    if GotParam dadmod_pause
        p = ( <p> + { dadmod_pause = 1 } )
    endif
    if not (<label> = "")
        p = ( <p> + { label = <label> } )
    endif
    b = ( <e> . b )
    switch <b>
    case 0
        dadmod_mmopt_item <p>
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    case 1
        if ( ( <p> . key ) = "ui_br_color" )
            dadmod_hl_style
            if not (<hl> = 3)
                return
            endif
        endif
        if ( ( <p> . key ) = "ui_br_speed" )
            dadmod_hl_style
            if not (<hl> = 3)
                return
            endif
            dadmod_ui_get key = "ui_br_color" def = 10
            if not (<value> = 10)
                return
            endif
        endif
        dadmod_ui_should_grey key = ( <p> . key )
        if (<grey_it> = 1)
            return
        endif
        if (<grey> = 1)
            grey_it = 1
        endif
        if (<grey_it> = 1)
            p = ( <p> + { dadmod_grey = 1 } )
        endif
        dadmod_ui_item <p>
        if (<grey_it> = 1)
            dadmod_layout_grey_last
        endif
    default
        if (<label> = "")
            label = "Reset Menu UI"
        endif
        make_thugpro_menu_item {
        text = <label>
        id = mui_reset
        description_text = "Puts every Menu UI setting back to stock"
        pad_choose_script = dadmod_ui_reset
        }
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    endswitch
endscript

script dadmod_layout_live
    if (dadmod_layout_node > -1)
        if ScreenElementExists id = desc_text_container
            dadmod_layout_open node = ( dadmod_layout_node )
        endif
    endif
endscript

script dadmod_layout_grey_last
    if GetScreenElementChildren id = current_menu
        GetArraySize <children>
        c = ( <children> [ ( <array_size> - 1 ) ] )
        SetScreenElementProps id = <c> not_focusable
        if ScreenElementExists id = { <c> child = text }
            SetScreenElementProps id = { <c> child = text } alpha = 0.4
        endif
    endif
endscript

dadmod_tod_states = [ afternoon morning afternoon evening night night ]

dadmod_tod_requested = afternoon

dadmod_tod_custom = 0

dadmod_tod_last = -1

dadmod_tod_watch_on = 0

dadmod_tod_evening_lights = {
state_length = 140000
sun_theta = 0.0
sun_phi = 1.9e+02
sun_red = 255.0
sun_green = 110.0
sun_blue = 60.0
lev_red = 78
lev_green = 70
lev_blue = 76
sky_red = 70
sky_green = 48
sky_blue = 60
fog_on = 1
fog_red = 70
fog_green = 46
fog_blue = 52
fog_alpha = 40
fog_dist = 6000
ambient_red = 34
ambient_green = 30
ambient_blue = 38
ambient_mod_factor_lo = 0.3
ambient_mod_factor_hi = 0.0
heading_0 = 50
pitch_0 = 340
red_0 = 110
green_0 = 78
blue_0 = 52
mod_factor_0_lo = 0.6
mod_factor_0_hi = 0.0
heading_1 = 240
pitch_1 = 330
red_1 = 36
green_1 = 34
blue_1 = 52
mod_factor_1_lo = 0.3
mod_factor_1_hi = 0.0
headlights_on = 1
bloom_on = 1
bloom1 = 35
bloom2 = 90
bloom_color = [ 160 , 110 , 90 ]
entry_script = nullscript
}

dadmod_tod_night_moon = {
state_length = 140000
sun_theta = 0.0
sun_phi = 2e+02
sun_red = 0.0
sun_green = 0.0
sun_blue = 0.0
lev_red = 74
lev_green = 82
lev_blue = 100
sky_red = 14
sky_green = 20
sky_blue = 34
fog_red = 18
fog_green = 26
fog_blue = 40
fog_alpha = 30
fog_dist = 9000
ambient_red = 42
ambient_green = 48
ambient_blue = 66
ambient_mod_factor_lo = 0.3
ambient_mod_factor_hi = 0.0
heading_0 = 330
pitch_0 = 330
red_0 = 96
green_0 = 110
blue_0 = 140
mod_factor_0_lo = 0.45
mod_factor_0_hi = 0.0
heading_1 = 151
pitch_1 = 330
red_1 = 30
green_1 = 36
blue_1 = 52
mod_factor_1_lo = 0.25
mod_factor_1_hi = 0.0
headlights_on = 1
bloom_on = 1
bloom1 = 30
bloom2 = 90
bloom_color = [ 120 , 130 , 200 ]
entry_script = nullscript
}

script dadmod_tod_value
    value = 0
    if THUGRECOMP_SettingLoad key = "gfx_todnow"
    endif
    dadmod_tod_client_allowed
    if (<allowed> = 0)
        value = 0
    endif
    if (<value> < 0)
        value = 0
    endif
    if (<value> > 5)
        value = 0
    endif
    return tod = <value>
endscript

script thugpro_change_time_of_day
    if (dadmod_tod_upd = 1)
        <from_update> = 1
    endif
    Change dadmod_tod_requested = <tod_state>
    dadmod_tod_value
    Change dadmod_tod_last = <tod>
    custom = 0
    if (<tod> = 5)
        tod_manager_set_default_params night_params = dadmod_tod_evening_lights
        custom = 1
    endif
    if (<tod> = 4)
        tod_manager_set_default_params night_params = dadmod_tod_night_moon
        custom = 1
    endif
    if (<custom> = 1)
        Change dadmod_tod_custom = 1
    else
        if IsTrue dadmod_tod_custom
            tod_manager_set_default_params
            Change dadmod_tod_custom = 0
        endif
    endif
    if (<tod> > 0)
        tod_state = ( dadmod_tod_states [ <tod> ] )
    endif
    Change tod_manager_inactive = 0
    TODManager_SetActive 1
    SpawnScript thugpro_tod_level_specific_hack_before
    switch <tod_state>
    case afternoon
        Change LEVEL_TOD_STATE = afternoon
        TODManager_SetTODInstant afternoon
        set_current_tod_values tod_state = afternoon
    case night
        Change LEVEL_TOD_STATE = night
        TODManager_SetTODInstant night
        set_current_tod_values tod_state = night
    case morning
        Change LEVEL_TOD_STATE = morning
        TODManager_SetTODInstant morning
        set_current_tod_values tod_state = morning
    case evening
        Change LEVEL_TOD_STATE = evening
        TODManager_SetTODInstant evening
        set_current_tod_values tod_state = evening
    default
        Change LEVEL_TOD_STATE = afternoon
        TODManager_SetTODInstant afternoon
        set_current_tod_values tod_state = afternoon
    endswitch
    SpawnScript thugpro_tod_level_specific_hack_after
endscript

script dadmod_tod_refresh
    Change dadmod_tod_fading = 0
    if LevelIs Load_MainMenu
        return
    endif
    if not InNetGame
        THUGPRO_SetLightUpdateState unpause
    endif
    TODManager_ResetLevelLights
    thugpro_change_time_of_day tod_state = ( dadmod_tod_requested ) from_local
    if not InNetGame
        KillSpawnedScript Name = dadmod_tod_lights_settle
        SpawnScript dadmod_tod_lights_settle
    endif
endscript

script dadmod_tod_lights_settle
    wait 60 gameframes
    THUGPRO_SetLightUpdateState pause
endscript

script dadmod_tod_watch_start
    if IsTrue dadmod_tod_watch_on
        return
    endif
    dadmod_balance_apply
    Change dadmod_tod_watch_on = 1
    SpawnScript dadmod_tod_watch NotSessionSpecific = 1
    SpawnScript dadmod_balance_net_watch NotSessionSpecific = 1
    SpawnScript dadmod_mirror_watch NotSessionSpecific = 1
endscript

script dadmod_balance_meter_side
    arrows = [ (0.0,-17.0) (1e+01,-17.0) (2e+01,-15.0) (3e+01,-11.0) (4e+01,-6.0) (5e+01,1.0) (6e+01,12.0) ]
    info = ( balance_meter_info )
    info = ( <info> + { arrow_positions = <arrows> } )
    Change balance_meter_info = <info>
endscript

script dadmod_mirror_spin
    mir = 0
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        mir = <value>
    endif
    if (<mir> = 1)
        switch ( GLOBAL_ShoulderSpinButtons )
        case L2_R2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R2 spin_button_right = L2 shoulder_spin_enabled = 1 }
        case L1_R1
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R1 spin_button_right = L1 shoulder_spin_enabled = 1 }
        case R1_R2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R1 spin_button_right = R2 shoulder_spin_enabled = 1 }
        case L1_L2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = L1 spin_button_right = L2 shoulder_spin_enabled = 1 }
        endswitch
    else
        thugpro_set_ShoulderSpinButtons value = ( GLOBAL_ShoulderSpinButtons )
    endif
    return mir = <mir>
endscript

script dadmod_mirror_watch
    last = -1
    lastmir = -1
    lastspin = none
    lastsk = 0
    n = 0
    lastbal = -1
    lastmm = -1
    begin
        wait 1 gameframe
        mm = 0
        if LevelIs Load_MainMenu
            mm = 1
        endif
        if not (<mm> = <lastmm>)
            THUGRECOMP_SettingSave key = "gfx_mainmenu" value = <mm>
            lastmm = <mm>
        endif
        dadmod_reorder_keys
        dadmod_prompt_tick
        dadmod_mouse_tick
        n = (<n> + 1)
        if (<n> > 15)
            n = 0
            sk = 0
            if ObjectExists id = skater
                sk = 1
            endif
            mir = 0
            if THUGRECOMP_SettingLoad key = "gfx_mirror"
                mir = <value>
            endif
            again = 0
            if not (<mir> = <lastmir>)
                again = 1
            endif
            if not (<sk> = <lastsk>)
                again = 1
            endif
            if not (( GLOBAL_ShoulderSpinButtons ) = <lastspin>)
                again = 1
            endif
            if (<again> = 1)
                dadmod_mirror_spin
                lastmir = <mir>
                lastsk = <sk>
                lastspin = ( GLOBAL_ShoulderSpinButtons )
            endif
            dadmod_balance_flags
        endif
        bal = 0
        if ObjectExists id = skater
            if skater : OnRail
                bal = 1
            endif
            if skater : OnLip
                bal = 1
            endif
        endif
        if not (<bal> = <lastbal>)
            THUGRECOMP_SettingSave key = "gfx_balancing" value = <bal>
            lastbal = <bal>
        endif
        up = 0
        if ScreenElementExists id = current_menu_anchor
            up = 1
        endif
        if ScreenElementExists id = current_menu
            up = 1
        endif
        if ScreenElementExists id = dialog_box_anchor
            up = 1
        endif
        if ScreenElementExists id = keyboard_anchor
            up = 1
        endif
        if ScreenElementExists id = quit_dialog_anchor
            up = 1
        endif
        if not (<up> = <last>)
            THUGRECOMP_SettingSave key = "gfx_menuup" value = <up>
            last = <up>
        endif
    repeat
endscript

script dadmod_tod_server_state
    st = 0
    if InNetGame
        TODManager_GetCurrentTODParams
        if GotParam tod_params
            if StructureContains structure = <tod_params> current_state_name
                switch ( <tod_params> . current_state_name )
                case morning
                    st = 1
                case afternoon
                    st = 2
                case evening
                    st = 3
                case night
                    st = 4
                endswitch
            endif
        endif
    endif
    THUGRECOMP_SettingSave key = "gfx_servertod" value = <st>
endscript

script dadmod_tod_watch
    begin
        wait 30 gameframes
        dadmod_tod_server_state
        GetLevelStructureName
        if StructureContains structure = ( <level_structure_name> ) level
            FormatText TextName = lk "gfx_level_%a" a = ( <level_structure_name> . level )
            THUGRECOMP_SettingSave key = <lk> value = 1
        endif
        if not LevelIs Load_MainMenu
            if ObjectExists id = skater
                dadmod_tod_kali_watch
                dadmod_tod_value
                if not (<tod> = ( dadmod_tod_last ))
                    from = ( dadmod_tod_last )
                    Change dadmod_tod_last = <tod>
                    dyn = 0
                    if THUGRECOMP_SettingLoad key = "gfx_tod"
                        dyn = <value>
                    endif
                    fade = 0
                    if (<dyn> = 6)
                        if (<from> > 0)
                            if (<from> < 6)
                                if (<tod> > 0)
                                    fade = 1
                                endif
                            endif
                        endif
                    endif
                    if (<fade> = 1)
                        Change dadmod_tod_fading = 0
                        KillSpawnedScript Name = dadmod_tod_fade
                        SpawnScript dadmod_tod_fade NotSessionSpecific = 1 params = { from = <from> to = <tod> }
                    else
                        dadmod_tod_refresh
                    endif
                else
                    if IsTrue dadmod_tod_fading
                        tod = 0
                    endif
                    if (<tod> > 0)
                        if not ( ( LEVEL_TOD_STATE ) = ( dadmod_tod_states [ <tod> ] ) )
                            dadmod_tod_refresh
                        endif
                    endif
                endif
            endif
        endif
    repeat
endscript

dadmod_tod_fading = 0

script dadmod_tod_lerp
    u = ( 1.0 - <t> )
    p = <b>
    if StructureContains structure = <a> sun_theta
        if StructureContains structure = <b> sun_theta
            v = ( ( ( <a> . sun_theta ) * <u> ) + ( ( <b> . sun_theta ) * <t> ) )
            p = { <p> sun_theta = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_phi
        if StructureContains structure = <b> sun_phi
            v = ( ( ( <a> . sun_phi ) * <u> ) + ( ( <b> . sun_phi ) * <t> ) )
            p = { <p> sun_phi = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_red
        if StructureContains structure = <b> sun_red
            v = ( ( ( <a> . sun_red ) * <u> ) + ( ( <b> . sun_red ) * <t> ) )
            p = { <p> sun_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_green
        if StructureContains structure = <b> sun_green
            v = ( ( ( <a> . sun_green ) * <u> ) + ( ( <b> . sun_green ) * <t> ) )
            p = { <p> sun_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_blue
        if StructureContains structure = <b> sun_blue
            v = ( ( ( <a> . sun_blue ) * <u> ) + ( ( <b> . sun_blue ) * <t> ) )
            p = { <p> sun_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_lo
        if StructureContains structure = <b> ambient_mod_factor_lo
            v = ( ( ( <a> . ambient_mod_factor_lo ) * <u> ) + ( ( <b> . ambient_mod_factor_lo ) * <t> ) )
            p = { <p> ambient_mod_factor_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_hi
        if StructureContains structure = <b> ambient_mod_factor_hi
            v = ( ( ( <a> . ambient_mod_factor_hi ) * <u> ) + ( ( <b> . ambient_mod_factor_hi ) * <t> ) )
            p = { <p> ambient_mod_factor_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_lo
        if StructureContains structure = <b> mod_factor_0_lo
            v = ( ( ( <a> . mod_factor_0_lo ) * <u> ) + ( ( <b> . mod_factor_0_lo ) * <t> ) )
            p = { <p> mod_factor_0_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_hi
        if StructureContains structure = <b> mod_factor_0_hi
            v = ( ( ( <a> . mod_factor_0_hi ) * <u> ) + ( ( <b> . mod_factor_0_hi ) * <t> ) )
            p = { <p> mod_factor_0_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_lo
        if StructureContains structure = <b> mod_factor_1_lo
            v = ( ( ( <a> . mod_factor_1_lo ) * <u> ) + ( ( <b> . mod_factor_1_lo ) * <t> ) )
            p = { <p> mod_factor_1_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_hi
        if StructureContains structure = <b> mod_factor_1_hi
            v = ( ( ( <a> . mod_factor_1_hi ) * <u> ) + ( ( <b> . mod_factor_1_hi ) * <t> ) )
            p = { <p> mod_factor_1_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_red
        if StructureContains structure = <b> lev_red
            v = ( ( ( <a> . lev_red ) * <u> ) + ( ( <b> . lev_red ) * <t> ) )
            CastToInteger v
            p = { <p> lev_red = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_green
        if StructureContains structure = <b> lev_green
            v = ( ( ( <a> . lev_green ) * <u> ) + ( ( <b> . lev_green ) * <t> ) )
            CastToInteger v
            p = { <p> lev_green = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_blue
        if StructureContains structure = <b> lev_blue
            v = ( ( ( <a> . lev_blue ) * <u> ) + ( ( <b> . lev_blue ) * <t> ) )
            CastToInteger v
            p = { <p> lev_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_red
        if StructureContains structure = <b> sky_red
            v = ( ( ( <a> . sky_red ) * <u> ) + ( ( <b> . sky_red ) * <t> ) )
            CastToInteger v
            p = { <p> sky_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_green
        if StructureContains structure = <b> sky_green
            v = ( ( ( <a> . sky_green ) * <u> ) + ( ( <b> . sky_green ) * <t> ) )
            CastToInteger v
            p = { <p> sky_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_blue
        if StructureContains structure = <b> sky_blue
            v = ( ( ( <a> . sky_blue ) * <u> ) + ( ( <b> . sky_blue ) * <t> ) )
            CastToInteger v
            p = { <p> sky_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_red
        if StructureContains structure = <b> fog_red
            v = ( ( ( <a> . fog_red ) * <u> ) + ( ( <b> . fog_red ) * <t> ) )
            CastToInteger v
            p = { <p> fog_red = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_green
        if StructureContains structure = <b> fog_green
            v = ( ( ( <a> . fog_green ) * <u> ) + ( ( <b> . fog_green ) * <t> ) )
            CastToInteger v
            p = { <p> fog_green = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_blue
        if StructureContains structure = <b> fog_blue
            v = ( ( ( <a> . fog_blue ) * <u> ) + ( ( <b> . fog_blue ) * <t> ) )
            CastToInteger v
            p = { <p> fog_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_alpha
        if StructureContains structure = <b> fog_alpha
            v = ( ( ( <a> . fog_alpha ) * <u> ) + ( ( <b> . fog_alpha ) * <t> ) )
            CastToInteger v
            p = { <p> fog_alpha = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_dist
        if StructureContains structure = <b> fog_dist
            v = ( ( ( <a> . fog_dist ) * <u> ) + ( ( <b> . fog_dist ) * <t> ) )
            CastToInteger v
            p = { <p> fog_dist = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_red
        if StructureContains structure = <b> ambient_red
            v = ( ( ( <a> . ambient_red ) * <u> ) + ( ( <b> . ambient_red ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_red = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_green
        if StructureContains structure = <b> ambient_green
            v = ( ( ( <a> . ambient_green ) * <u> ) + ( ( <b> . ambient_green ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_green = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_blue
        if StructureContains structure = <b> ambient_blue
            v = ( ( ( <a> . ambient_blue ) * <u> ) + ( ( <b> . ambient_blue ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_0
        if StructureContains structure = <b> heading_0
            v = ( ( ( <a> . heading_0 ) * <u> ) + ( ( <b> . heading_0 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_0
        if StructureContains structure = <b> pitch_0
            v = ( ( ( <a> . pitch_0 ) * <u> ) + ( ( <b> . pitch_0 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_0
        if StructureContains structure = <b> red_0
            v = ( ( ( <a> . red_0 ) * <u> ) + ( ( <b> . red_0 ) * <t> ) )
            CastToInteger v
            p = { <p> red_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_0
        if StructureContains structure = <b> green_0
            v = ( ( ( <a> . green_0 ) * <u> ) + ( ( <b> . green_0 ) * <t> ) )
            CastToInteger v
            p = { <p> green_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_0
        if StructureContains structure = <b> blue_0
            v = ( ( ( <a> . blue_0 ) * <u> ) + ( ( <b> . blue_0 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_1
        if StructureContains structure = <b> heading_1
            v = ( ( ( <a> . heading_1 ) * <u> ) + ( ( <b> . heading_1 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_1
        if StructureContains structure = <b> pitch_1
            v = ( ( ( <a> . pitch_1 ) * <u> ) + ( ( <b> . pitch_1 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_1
        if StructureContains structure = <b> red_1
            v = ( ( ( <a> . red_1 ) * <u> ) + ( ( <b> . red_1 ) * <t> ) )
            CastToInteger v
            p = { <p> red_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_1
        if StructureContains structure = <b> green_1
            v = ( ( ( <a> . green_1 ) * <u> ) + ( ( <b> . green_1 ) * <t> ) )
            CastToInteger v
            p = { <p> green_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_1
        if StructureContains structure = <b> blue_1
            v = ( ( ( <a> . blue_1 ) * <u> ) + ( ( <b> . blue_1 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom1
        if StructureContains structure = <b> bloom1
            v = ( ( ( <a> . bloom1 ) * <u> ) + ( ( <b> . bloom1 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom2
        if StructureContains structure = <b> bloom2
            v = ( ( ( <a> . bloom2 ) * <u> ) + ( ( <b> . bloom2 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom2 = <v> }
        endif
    endif
    return p = <p>
endscript

script dadmod_tod_phase_params
    GetLevelStructureName
    switch <phase>
    case 1
        FormatText ChecksumName = n "%a_tod_morning_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_morning
        state = morning
    case 3
        FormatText ChecksumName = n "%a_tod_evening_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_evening
        state = evening
    case 4
        n = dadmod_tod_night_moon
        params = dadmod_tod_night_moon
        state = night
    case 5
        n = dadmod_tod_evening_lights
        params = dadmod_tod_evening_lights
        state = night
    default
        FormatText ChecksumName = n "%a_tod_afternoon_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_afternoon
        state = afternoon
    endswitch
    if GlobalExists Name = <n> Type = structure
        params = ( <n> )
    else
        params = ( <params> )
    endif
    return params = <params> state = <state>
endscript

script dadmod_tod_fade
    Change dadmod_tod_fading = 1
    dadmod_tod_phase_params phase = <from>
    a = <params>
    sa = <state>
    dadmod_tod_phase_params phase = <to>
    b = <params>
    sb = <state>
    st = <sb>
    if (<sa> = night)
        st = night
    endif
    if not InNetGame
        THUGPRO_SetLightUpdateState unpause
    endif
    Change tod_manager_inactive = 0
    TODManager_SetActive 1
    i = 1
    begin
        if (<i> > 24)
            break
        endif
        t = ( <i> / 24.0 )
        dadmod_tod_lerp a = <a> b = <b> t = <t>
        switch <st>
        case morning
            tod_manager_set_default_params morning_params = <p>
        case evening
            tod_manager_set_default_params evening_params = <p>
        case night
            tod_manager_set_default_params night_params = <p>
        default
            tod_manager_set_default_params afternoon_params = <p>
        endswitch
        Change LEVEL_TOD_STATE = <st>
        TODManager_SetTODInstant <st>
        wait 20 gameframes
        if not IsTrue dadmod_tod_fading
            return
        endif
        if LevelIs Load_MainMenu
            Change dadmod_tod_fading = 0
            return
        endif
        i = ( <i> + 1 )
    repeat
    Change dadmod_tod_custom = 1
    Change dadmod_tod_fading = 0
    dadmod_tod_refresh
endscript

script dadmod_mirror_l2
    mir = 0
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        mir = <value>
    endif
    l2 = 0
    if GotParam spin_with_L2
        l2 = 1
    endif
    if (<mir> = 1)
        l2 = (1 - <l2>)
    endif
    return l2 = <l2>
endscript

script SwitchFootPogo_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script CasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        }
    endif
endscript

script AntiCasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        }
    endif
endscript

script TruckSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script PogoSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script revert
    if not GotParam FSName
        FSName = 'FS Revert'
    endif
    if not GotParam BSName
        BSName = 'BS Revert'
    endif
    if not GotParam FSAnim
        FSAnim = RevertFS
    endif
    if not GotParam BSAnim
        BSAnim = RevertBS
    endif
    if IsSkaterOnVehicle
        goto vehicle_revert
    endif
    if IsOnMotoSkateboard
        FSAnim = RevertFS
        BSAnim = RevertBS
    endif
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        if (<value> = 1)
            a = <FSAnim>
            FSAnim = <BSAnim>
            BSAnim = <a>
        endif
    endif
    dadmod_bhra_revert_check
    OnExitRun ExitRevert
    InRevert
    ClearLipCombos
    KillExtraTricks
    SetTrickScore 100
    OnGroundExceptions NoEndRun
    LaunchStateChangeEvent state = Skater_InRevert
    ClearException Ollied
    if not GetGlobalFlag flag = SERVER_CHEAT_NO_REVERT_SPEED_LOSS
        SetSpecialFriction [ 0 , 0 , 5 , 10 , 15 , 25 ] duration = 0.667
    endif
    CanKickOff
    SetQueueTricks SkateToWalkTricks
    NollieOff
    PressureOff
    if GotParam LandPivot
        GetBoardTypeAndRevert Type = manuallink
        PlayAnim anim = GTurn
        if InAir
            SetTrickName 'Bunny Hop Revert'
        else
            SetTrickName 'Land Pivot'
        endif
        Obj_SetFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        GetBoardTypeAndRevert Type = revert
        if InAir
            FSName = 'Bunny Hop Revert'
            BSName = 'Bunny Hop Revert'
        endif
        if Obj_FlagSet FLAG_SKATER_REVERTFS
            Obj_ClearFlag FLAG_SKATER_REVERTFS
            PlayAnim anim = <FSAnim>
            SetTrickName <FSName>
        else
            if Obj_FlagSet FLAG_SKATER_REVERTBS
                Obj_ClearFlag FLAG_SKATER_REVERTBS
                PlayAnim anim = <BSAnim>
                SetTrickName <BSName>
            else
                if LastSpinWas Frontside
                    PlayAnim anim = <FSAnim>
                    SetTrickName <FSName>
                else
                    PlayAnim anim = <BSAnim>
                    SetTrickName <BSName>
                endif
            endif
        endif
    endif
    SetSkaterAirManualTricks
    Display Blockspin
    if not IsOnMotoSkateboard
        FlipAfter
        BoardRotateAfter
    endif
    wait 0.1 seconds
    SetException ex = Ollied scr = Ollie
    if not GotParam LandPivot
        ResetLandedFromVert
    endif
    if GotParam bhra_pv
        if GotParam LandPivot
            WaitAnim 100 Percent
        else
            WaitAnim 60 Percent
        endif
    else
        WaitAnim 100 Percent
    endif
    CanKickOn
    if GotParam bhra_air
        if not GotParam LandPivot
            if not GotParam bhra_pv
                if InAir
                    InAirExceptions
                    goto Airborne
                endif
                begin
                    DoNextManualTrick FromAir
                    wait 1 gameframe
                repeat 10
            endif
        endif
    endif
    if GotParam LandPivot
        PlayAnim anim = Manual_Range From = middle BlendPeriod = 0.0
        DoNextManualTrick SkipInitAnim LandPivotManual
    else
        DoNextManualTrick FromAir
    endif
    DoNextTrick
    OnGroundExceptions
    if GotParam bhra_air
        if GotParam LandPivot
            goto dadmod_bhra_pivot_land
        endif
        if GotParam bhra_pv
            goto dadmod_bhra_pivot_land params = { revert_style = 1 }
        endif
    endif
    LandSkaterTricks
    ClearEventBuffer
    if GotParam LandPivot
        PlayAnim anim = PutDownManual BlendPeriod = 0.3 speed = 2.5
        Obj_ClearFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        if not Held x
            PlayAnim anim = CrouchIdleToIdle BlendPeriod = 0.0 speed = 0.7
        else
            PlayAnim anim = CrouchIdle BlendPeriod = 0.0 From = 0 To = 0.3 seconds
            BlendPeriodOut 0.3
        endif
    endif
    WaitAnimWhilstChecking AndManuals
    goto OnGroundAi
endscript

dadmod_added_levels = [ #"0x001202e3" #"0x341caf9f" #"0x6552c592" #"0xe0d4e51a" #"0xf06d95da" #"0x73babdd0" #"0x16a10a9a" #"0x1a69989e" #"0x896a81b2" #"0x27eeac8d" #"0x2843fdc8" Load_dadmod_THPGFDR Load_dadmod_THPGLove Load_dadmod_THPGSlums Load_dadmod_THPGBCity Load_dadmod_THPGHarbor Load_dadmod_THPGLansdowne Load_dadmod_THPGMonuments Load_dadmod_THPGMuseums Load_dadmod_THPGMuseumInt Load_dadmod_THPGPhilly Load_dadmod_THPGWashington Load_dadmod_THPGTraining Load_dadmod_THPGLarxPhilly Load_dadmod_THPGLarxBaltimore Load_dadmod_THPGLarxWashington ]

dadmod_added_level_creators = [ "tyler.thpsX" "letmynutzgo" "letmynutzgo" "letmynutzgo" "rodafy" "letmynutzgo" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Larxian" "Larxian" "Larxian" ]

script dadmod_added_level_creator
    GetArraySize dadmod_added_levels
    <i> = 0
    begin
        if ( ( dadmod_added_levels [ <i> ] ) = <level> )
            return creator = ( dadmod_added_level_creators [ <i> ] )
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
endscript

Level_dadmod_Streets = {
game = THPS1
structure_name = Level_dadmod_Streets
load_script = #"0x001202e3"
Name = "Streets"
loading_time = 8.5
level = "Streets"
sky = "Streets_Sky"
wallride_hack
qb = "levels\\Streets\\Streets.qb"
level_qb = "levels\\Streets\\Streets_scripts.qb"
more_level_qbs = [
"levels\\Streets\\Streets_thugpro.qb"
]
pre = "Streets_scripts.pre"
scnpre = "Streetsscn.pre"
colpre = "Streetscol.pre"
default_level_stuff
}

script #"0x001202e3"
    load_level Level_dadmod_Streets
endscript

Level_dadmod_THPS2NY = {
game = THPS2
structure_name = Level_dadmod_THPS2NY
load_script = #"0x341caf9f"
Name = "New York City"
loading_time = 8.5
level = "THPS2NY"
sky = "THPS2NY_Sky"
nosun
wallride_hack
qb = "levels\\THPS2NY\\THPS2NY.qb"
level_qb = "levels\\THPS2NY\\THPS2NY_scripts.qb"
more_level_qbs = [
"levels\\THPS2NY\\THPS2NY_thugpro.qb"
]
pre = "THPS2NY_scripts.pre"
scnpre = "THPS2NYscn.pre"
colpre = "THPS2NYcol.pre"
default_level_stuff
}

script #"0x341caf9f"
    load_level Level_dadmod_THPS2NY
endscript

Level_dadmod_THPS2SS = {
game = THPS2
structure_name = Level_dadmod_THPS2SS
load_script = #"0x6552c592"
Name = "Skatestreet"
loading_time = 8.5
level = "THPS2SS"
sky = "default_sky"
indoor
nosun
wallride_hack
qb = "levels\\THPS2SS\\THPS2SS.qb"
level_qb = "levels\\THPS2SS\\THPS2SS_scripts.qb"
more_level_qbs = [
"levels\\THPS2SS\\THPS2SS_thugpro.qb"
]
pre = "THPS2SS_scripts.pre"
scnpre = "THPS2SSscn.pre"
colpre = "THPS2SScol.pre"
default_level_stuff
}

script #"0x6552c592"
    load_level Level_dadmod_THPS2SS
endscript

Level_dadmod_THPS2Bullring = {
game = THPS2
structure_name = Level_dadmod_THPS2Bullring
load_script = #"0xe0d4e51a"
Name = "Bullring"
loading_time = 8.5
level = "THPS2Bullring"
sky = "THPS2Bullring_Sky"
nosun
wallride_hack
qb = "levels\\THPS2Bullring\\THPS2Bullring.qb"
level_qb = "levels\\THPS2Bullring\\THPS2Bullring_scripts.qb"
more_level_qbs = [
"levels\\THPS2Bullring\\THPS2Bullring_thugpro.qb"
]
pre = "THPS2Bullring_scripts.pre"
scnpre = "THPS2Bullringscn.pre"
colpre = "THPS2Bullringcol.pre"
default_level_stuff
}

script #"0xe0d4e51a"
    load_level Level_dadmod_THPS2Bullring
endscript

Level_dadmod_THPS2_SH = {
game = THPS2
structure_name = Level_dadmod_THPS2_SH
load_script = #"0xf06d95da"
Name = "Skate Heaven"
loading_time = 8.5
level = "THPS2_SH"
sky = "default_sky"
nosun
qb = "levels\\THPS2_SH\\THPS2_SH.qb"
level_qb = "levels\\THPS2_SH\\THPS2_SH_scripts.qb"
more_level_qbs = [
"levels\\THPS2_SH\\THPS2_SH_thugpro.qb"
]
pre = "THPS2_SH_scripts.pre"
scnpre = "THPS2_SHscn.pre"
colpre = "THPS2_SHcol.pre"
default_level_stuff
}

script #"0xf06d95da"
    load_level Level_dadmod_THPS2_SH
endscript

Level_dadmod_THPS2ChopperDrop = {
game = THPS2
structure_name = Level_dadmod_THPS2ChopperDrop
load_script = #"0x73babdd0"
Name = "Chopper Drop"
loading_time = 8.5
level = "THPS2ChopperDrop"
sky = "THPS2ChopperDrop_Sky"
nosun
wallride_hack
qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop.qb"
level_qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop_scripts.qb"
more_level_qbs = [
"levels\\THPS2ChopperDrop\\THPS2ChopperDrop_thugpro.qb"
]
pre = "THPS2ChopperDrop_scripts.pre"
scnpre = "THPS2ChopperDropscn.pre"
colpre = "THPS2ChopperDropcol.pre"
default_level_stuff
}

script #"0x73babdd0"
    load_level Level_dadmod_THPS2ChopperDrop
endscript

Level_dadmod_P8Training = {
game = THP8
structure_name = Level_dadmod_P8Training
load_script = #"0x1a69989e"
Name = "Training"
loading_time = 8.5
level = "P8Training"
sky = "P8Training_Sky"
qb = "levels\\P8Training\\P8Training.qb"
level_qb = "levels\\P8Training\\P8Training_scripts.qb"
more_level_qbs = [
"levels\\P8Training\\P8Training_thugpro.qb"
]
pre = "P8Training_scripts.pre"
scnpre = "P8Trainingscn.pre"
colpre = "P8Trainingcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
overview_cam_pos = (-698.3,4416.4,795.5)
overview_cam_angle = 0
}

script #"0x1a69989e"
    load_level Level_dadmod_P8Training
endscript

Level_dadmod_P8Suburbs = {
game = THP8
structure_name = Level_dadmod_P8Suburbs
load_script = #"0x16a10a9a"
Name = "Suburbs"
loading_time = 8.5
level = "P8Suburbs"
sky = "P8Suburbs_Sky"
qb = "levels\\P8Suburbs\\P8Suburbs.qb"
level_qb = "levels\\P8Suburbs\\P8Suburbs_scripts.qb"
more_level_qbs = [
"levels\\P8Suburbs\\P8Suburbs_thugpro.qb"
]
pre = "P8Suburbs_scripts.pre"
scnpre = "P8Suburbsscn.pre"
colpre = "P8Suburbscol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Suburbs_goals
overview_cam_pos = (-2032.6,4565.6,-2302.5)
overview_cam_angle = 0
}

script #"0x16a10a9a"
    load_level Level_dadmod_P8Suburbs
endscript

Level_dadmod_P8Downtown = {
game = THP8
structure_name = Level_dadmod_P8Downtown
load_script = #"0x896a81b2"
Name = "Downtown"
loading_time = 8.5
level = "P8Downtown"
sky = "P8Downtown_Sky"
qb = "levels\\P8Downtown\\P8Downtown.qb"
level_qb = "levels\\P8Downtown\\P8Downtown_scripts.qb"
more_level_qbs = [
"levels\\P8Downtown\\P8Downtown_thugpro.qb"
]
pre = "P8Downtown_scripts.pre"
scnpre = "P8Downtownscn.pre"
colpre = "P8Downtowncol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Downtown_goals
overview_cam_pos = (2920.1,5821.6,-1341.0)
overview_cam_angle = 0
}

script #"0x896a81b2"
    load_level Level_dadmod_P8Downtown
endscript

Level_dadmod_P8CarFactory = {
game = THP8
structure_name = Level_dadmod_P8CarFactory
load_script = #"0x27eeac8d"
Name = "Car Factory"
loading_time = 8.5
level = "P8CarFactory"
sky = "P8CarFactory_Sky"
qb = "levels\\P8CarFactory\\P8CarFactory.qb"
level_qb = "levels\\P8CarFactory\\P8CarFactory_scripts.qb"
more_level_qbs = [
"levels\\P8CarFactory\\P8CarFactory_thugpro.qb"
]
pre = "P8CarFactory_scripts.pre"
scnpre = "P8CarFactoryscn.pre"
colpre = "P8CarFactorycol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CarFactory_goals
overview_cam_pos = (-2428.3,6098.0,3137.1)
overview_cam_angle = 0
}

script #"0x27eeac8d"
    load_level Level_dadmod_P8CarFactory
endscript

Level_dadmod_P8CretePark = {
game = THP8
structure_name = Level_dadmod_P8CretePark
load_script = #"0x2843fdc8"
Name = "Crete Park"
loading_time = 8.5
level = "P8CretePark"
sky = "P8CretePark_Sky"
qb = "levels\\P8CretePark\\P8CretePark.qb"
level_qb = "levels\\P8CretePark\\P8CretePark_scripts.qb"
more_level_qbs = [
"levels\\P8CretePark\\P8CretePark_thugpro.qb"
]
pre = "P8CretePark_scripts.pre"
scnpre = "P8CreteParkscn.pre"
colpre = "P8CreteParkcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CretePark_goals
overview_cam_pos = (-7389.1,6911.9,-2279.5)
overview_cam_angle = 0
}

script #"0x2843fdc8"
    load_level Level_dadmod_P8CretePark
endscript

script create_thugpro_level_menu_item {
    pad_choose_script = level_select_valid_choice
    }
    if GotParam hidden
        return
    endif
    if GotParam level
        FormatText ChecksumName = id "menu_%a" a = <level>
    endif
    if not ScriptExists <level>
        focusable = not_focusable
        exclude = 1
    endif
    if GotParam level
        if InNetGame
            if ArrayContains array = dadmod_added_levels contains = <level>
                if ScriptExists dadmod_level_online_ok
                    dadmod_level_online_ok level = <level>
                endif
                if not GotParam ok
                    focusable = not_focusable
                    exclude = 1
                endif
            endif
        endif
    endif
    if LevelIs Load_MainMenu
        if ( in_server_options = 1 )
            level_callback_script = THUGPRO_LevelSelect_menu_exit
        else
            level_callback_script = level_select_change_level
        endif
    else
        level_callback_script = level_select_change_level
    endif
    if GotParam online_level
        pad_choose_params = { <...> level = <online_level> }
    else
        pad_choose_params = <...>
    endif
    if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
        GetIndexOfItemContaining { array = level_select_menu_level_info index = 0 Name = level value = <level> }
        if ( ( ( level_select_menu_level_info [ <index> ] ) . enabled ) = 1 )
            <checked> = checked
        else
            <checked> = unchecked
        endif
        <make_menu_item_script> = make_thugpro_menu_checkbox_item
        pad_option_script = level_select_valid_choice
        pad_option_params = { <...> }
    else
        pad_option_script = nullscript
        pad_option_params = { }
        <make_menu_item_script> = make_thugpro_menu_item
    endif
    if GotParam is_custompark
        current_menu_anchor : GetSingleTag custom_park_menu_index
        FormatText TextName = text <filename>
        FormatText ChecksumName = id "menu_custom_park_%i" i = <custom_park_menu_index>
        current_menu_anchor : SetTags custom_park_menu_index = ( <custom_park_menu_index> + 1 )
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = created_park_launch
            pad_option_script = level_select_valid_choice
            pad_option_params = { <...> }
        else
            level_callback_script = created_park_launch
            pad_choose_script = level_select_valid_choice
            pad_choose_params = { <...> }
        endif
    endif
    if GotParam is_premadepark
        FormatText TextName = text <Name>
        FormatText ChecksumName = id "menu_%s" s = <Name>
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = maybe_load_premade_park
            pad_option_script = maybe_load_premade_park
            pad_option_params = { slot = <slot> }
        else
            level_callback_script = maybe_load_premade_park
            pad_choose_script = maybe_load_premade_park
            pad_choose_params = { slot = <slot> }
        endif
    endif
    if not GotParam creator
        if GotParam level
            dadmod_added_level_creator level = <level>
        endif
    endif
    if GotParam level
        if ScriptExists dadmod_levelthumb_for
            dadmod_levelthumb_for level = <level>
        endif
    endif
    <make_menu_item_script> {
    text = <text>
    extra_text = <creator>
    id = <id>
    unfocus_script = thugpro_level_select_item_unfocus
    focus_script = thugpro_level_select_item_focus
    focus_params = { level = <level> text = <text> texture = <level_thumb> }
    pad_choose_script = <pad_choose_script>
    pad_choose_params = <pad_choose_params>
    pad_option_script = <pad_option_script>
    pad_option_params = <pad_option_params>
    <focusable>
    <checked>
    }
endscript

dadmod_levelthumbs_booted = 0

script dadmod_levelthumbs_boot
    if ( dadmod_levelthumbs_booted = 1 )
        return
    endif
    Change dadmod_levelthumbs_booted = 1
    if ScriptExists dadmod_levelthumbs_load
        dadmod_levelthumbs_load
    endif
endscript

script Load_MainMenu
    Load_MainMenu_scene
    KillSpawnedScript Name = dadmod_menu_watch
    SpawnScript dadmod_menu_watch
    dadmod_noclip_boot
    dadmod_speed_boot
    dadmod_levelthumbs_boot
    dadmod_cars_boot
endscript

script Load_MainMenu_scene
    level = 1
    THUGRECOMP_MenuLevel
    THUGRECOMP_MenuOpt key = "ambient_level" step = 0 index = <level>
    if GotParam live_level
        if GlobalExists Name = <live_level> Type = structure
            Change thugpro_mainmenu_east_la = 1
            load_level <live_level>
            return
        endif
    endif
    if (<level> = 0)
        Change thugpro_mainmenu_east_la = 0
        load_level level_Mainmenu
        return
    endif
    Change thugpro_mainmenu_east_la = 1
    switch <level>
    case 2
        load_level level_Mainmenu_toystory_bedroom
    case 3
        load_level level_Mainmenu_tr
    case 4
        load_level level_Mainmenu_bo
    case 5
        load_level level_Mainmenu_ba
    case 6
        load_level level_Mainmenu_be
    case 7
        load_level level_Mainmenu_au
    case 8
        load_level level_Mainmenu_no
    case 9
        load_level level_Mainmenu_st
    case 10
        load_level level_Mainmenu_se
    case 11
        load_level level_Mainmenu_se2
    case 12
        load_level level_Mainmenu_la
    case 13
        load_level level_Mainmenu_sc
    case 14
        load_level level_Mainmenu_hn
    case 15
        load_level level_Mainmenu_vn
    case 16
        load_level level_Mainmenu_sc2
    case 17
        load_level level_Mainmenu_ph
    case 18
        load_level level_Mainmenu_dj
    case 19
        load_level level_Mainmenu_ca
    case 20
        load_level level_Mainmenu_ap
    case 21
        load_level level_Mainmenu_nj
    case 22
        load_level level_Mainmenu_ny
    case 23
        load_level level_Mainmenu_fl
    case 24
        load_level level_Mainmenu_sd
    case 25
        load_level level_Mainmenu_hi
    case 26
        load_level level_Mainmenu_vc
    case 27
        load_level level_Mainmenu_sj
    case 28
        load_level level_Mainmenu_ru
    case 29
        load_level level_Mainmenu_hh
    case 30
        load_level level_Mainmenu_practice
    case 31
        load_level level_Mainmenu_sch
    case 32
        load_level level_Mainmenu_alc
    case 33
        load_level level_Mainmenu_sf2
    case 34
        load_level level_Mainmenu_kon
    case 35
        load_level level_Mainmenu_lon
    case 36
        load_level level_Mainmenu_jnk
    case 37
        load_level level_Mainmenu_zoo
    case 38
        load_level level_Mainmenu_cnv
    case 39
        load_level level_Mainmenu_hof
    case 40
        load_level level_Mainmenu_vans
    case 41
        load_level level_Mainmenu_skatepark
    case 42
        load_level level_Mainmenu_sz
    case 43
        load_level level_Mainmenu_atlanta
    case 44
        load_level level_Mainmenu_kyoto
    case 45
        load_level level_Mainmenu_hisch
    case 46
        load_level level_Mainmenu_z_funpark
    case 47
        load_level level_Mainmenu_z_center
    case 48
        load_level level_Mainmenu_z_riod
    case 49
        load_level level_Mainmenu_z_sm
    case 50
        load_level level_Mainmenu_z_bh
    case 51
        load_level level_Mainmenu_z_sv2
    case 52
        load_level level_Mainmenu_z_sr
    case 53
        load_level level_Mainmenu_z_dt
    case 54
        load_level level_Mainmenu_z_ho
    case 55
        load_level level_Mainmenu_z_lv
    case 56
        load_level level_Mainmenu_z_oi
    case 57
        load_level level_Mainmenu_foun
    case 58
        load_level level_Mainmenu_rio
    case 59
        load_level level_Mainmenu_sub
    case 60
        load_level level_Mainmenu_tok
    case 61
        load_level level_Mainmenu_shp
    case 62
        load_level level_Mainmenu_si
    case 63
        load_level level_Mainmenu_oil
    case 64
        load_level level_Mainmenu_ware
    case 65
        load_level level_Mainmenu_z_ma
    case 66
        load_level level_Mainmenu_z_dn
    case 67
        load_level level_Mainmenu_burn
    case 68
        load_level level_Mainmenu_ros
    case 69
        load_level level_Mainmenu_z_ms
    case 70
        load_level level_Mainmenu_streets
    case 71
        load_level level_Mainmenu_thps2ny
    case 72
        load_level level_Mainmenu_thps2ss
    case 73
        load_level level_Mainmenu_thps2bullring
    case 74
        load_level level_Mainmenu_thps2_sh
    case 75
        load_level level_Mainmenu_thps2chopperdrop
    case 76
        load_level level_Mainmenu_p8training
    case 77
        load_level level_Mainmenu_p8suburbs
    case 78
        load_level level_Mainmenu_p8downtown
    case 79
        load_level level_Mainmenu_p8carfactory
    case 80
        load_level level_Mainmenu_p8cretepark
    case 81
        load_level level_Mainmenu_thpgtraining
    default
        load_level level_Mainmenu_EL
    endswitch
endscript

script dadmod_menu_level_menu
    THUGRECOMP_MenuOpt key = "level" step = 0
    cur = <index>
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_menulevel
    menu_title = "Menu level"
    menu_style = MENU_STYLE_LEFT
    helper_text = generic_helper_text
    pad_back_script = dadmod_menu_level_back
    show_description_panel
    show_gradient
    scrolling
    }
    GetArraySize dadmod_menu_level_list
    i = 0
    last_game = ""
    begin
        if (<i> = <array_size>)
            break
        endif
        e = ( dadmod_menu_level_list [ <i> ] )
        g = ( <e> . game )
        if not THUGRECOMP_MenuLevelHas index = ( <e> . i )
            g = <last_game>
        endif
        if not (<g> = <last_game>)
            FormatText TextName = h "- %s -" s = <g>
            make_thugpro_menu_item {
            text = <h>
            not_focusable
            }
            last_game = <g>
        endif
        if ( ( <e> . i ) = <cur> )
            FormatText TextName = t "%s  *" s = ( <e> . name )
            d = "The level behind the main menu now"
        else
            t = ( <e> . name )
            d = "Show this level behind the main menu. It loads right away"
        endif
        if THUGRECOMP_MenuLevelHas index = ( <e> . i )
        make_thugpro_menu_item {
        text = <t>
        description_text = <d>
        pad_choose_script = dadmod_menu_level_pick
        pad_choose_params = { pick = ( <e> . i ) }
        }
        endif
        i = ( <i> + 1 )
    repeat
    dadmod_desc_panel_right
    thugpro_menu_finalize
endscript

script dadmod_menu_level_pick
    THUGRECOMP_MenuOpt key = "level" pick = <pick>
    Change dadmod_mm_armed = none
    if GotParam pending
        if (<pending> = 1)
            Change dadmod_mm_reopen = 1
            SpawnScript dadmod_reload_menu_scene
            return
        endif
    endif
    dadmod_menu_level_back
endscript

script dadmod_menu_level_back
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_setup_menu
    endif
endscript

