scalingmenu_min_scale = 1.0
scalingmenu_max_scale = 1000.0
scalingmenu_constraints = [
{ part = object_scaling male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = headtop_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = head_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = nose_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = jaw_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = torso_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = stomach_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = upper_arm_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = lower_arm_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = hands_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = upper_leg_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = lower_leg_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = feet_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = board_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
{ part = wheels_bone_group male_min = 1.0 male_max = 1000.0 female_min = 1.0 female_max = 1000.0 }
]
dadmod_analog_boost = 6
dadmod_stick_threshold = 0.3
script dadmod_stick_step
    <step> = 1
    <controller> = 0
    <found> = 0
    begin
        if ControllerBoundToSkater controller = <controller> Skater = 0
            <found> = 1
            break
        endif
        <controller> = ( <controller> + 1 )
    repeat 4
    if ( <found> = 1 )
        GetAnalogueInfo controller = <controller>
        <ax> = <leftx>
        if ( <ax> < 0 )
            <ax> = ( 0 - <ax> )
        endif
        if ( <ax> > ( dadmod_stick_threshold ) )
            <step> = ( dadmod_analog_boost )
        endif
    endif
    return step = <step>
endscript
script dadmod_color_step
    dadmod_stick_step
    if GotParam left
        <step> = ( 0 - <step> )
    endif
    colormenu_get_hsv part = <part>
    switch <component>
    case h
        <h> = ( <h> + <step> )
        if ( <h> > 359 )
            <h> = ( <h> - 360 )
        endif
        if ( <h> < 0 )
            <h> = ( <h> + 360 )
        endif
    case s
        <s> = ( <s> + <step> )
        if ( <s> > 100 )
            <s> = 100
        endif
        if ( <s> < 0 )
            <s> = 0
        endif
    case v
        <v> = ( <v> + <step> )
        if ( <v> > 100 )
            <v> = 100
        endif
        if ( <v> < 0 )
            <v> = 0
        endif
    endswitch
    colormenu_set_hsv part = <part> h = <h> s = <s> v = <v>
    colormenu_refresh_skaters
    __thugpro_color_menu_refresh_component <...>
endscript
script dadmod_scale_step
    dadmod_stick_step
    if GotParam left
        <step> = ( 0 - <step> )
    endif
    scalingmenu_get_xyz part = <part>
    scalingmenu_get_limits part = <part>
    if GotParam affectX
        if ( <affectX> = 1 )
            <x> = ( <x> + <step> )
        endif
    endif
    if GotParam affectY
        if ( <affectY> = 1 )
            <y> = ( <y> + <step> )
        endif
    endif
    if GotParam affectZ
        if ( <affectZ> = 1 )
            <z> = ( <z> + <step> )
        endif
    endif
    if ( <x> > <max> )
        <x> = <max>
    endif
    if ( <x> < <min> )
        <x> = <min>
    endif
    if ( <y> > <max> )
        <y> = <max>
    endif
    if ( <y> < <min> )
        <y> = <min>
    endif
    if ( <z> > <max> )
        <z> = <max>
    endif
    if ( <z> < <min> )
        <z> = <min>
    endif
    scalingmenu_set_xyz part = <part> x = <x> y = <y> z = <z>
    scalingmenu_refresh_skaters
    __thugpro_scaling_menu_refresh part = <part>
endscript
script thugpro_color_menu_add_options_to_menu
    make_thugpro_menu_slider_item {
    id = menu_id_color
    text = "Color"
    extra_text = "0"
    child_texture = colorbar
    option_arrows_callback = __thugpro_color_menu_change_component
    option_arrows_callback_params = { part = <part> component = h }
    option_arrows
    }
    make_thugpro_menu_slider_item {
    id = menu_id_value
    text = "Brightness"
    extra_text = "0"
    child_texture = bw_slider
    option_arrows_callback = __thugpro_color_menu_change_component
    option_arrows_callback_params = { part = <part> component = v }
    option_arrows
    }
    make_thugpro_menu_slider_item {
    id = menu_id_saturation
    text = "Saturation"
    extra_text = "0"
    child_texture = bw_slider
    option_arrows_callback = __thugpro_color_menu_change_component
    option_arrows_callback_params = { part = <part> component = s }
    option_arrows
    }
    make_thugpro_menu_item text = "Random Color" pad_choose_script = dadmod_random_color pad_choose_params = { part = <part> }
    make_thugpro_menu_item text = "Default Color" pad_choose_script = __thugpro_color_menu_reset_to_default pad_choose_params = { part = <part> }
    dadmod_stick_watch_start
    dadmod_undo_keys
endscript
script dadmod_random_color
    GetCurrentSkaterProfileIndex
    SetPlayerAppearanceColor player = <currentSkaterProfileIndex> part = <part> h = RandomRange (0.0,359.0) s = RandomRange (10.0,70.0) v = RandomRange (10.0,60.0) use_default_hsv = 0
    colormenu_refresh_skaters
    __thugpro_color_menu_refresh part = <part>
endscript
dadmod_stick_watching = 0
dadmod_stick_fast = 0
script dadmod_stick_watch_start
    if IsTrue dadmod_stick_watching
        return
    endif
    Change dadmod_stick_watching = 1
    SpawnScript dadmod_stick_watch
endscript
script dadmod_stick_watch
    begin
        wait 1 gameframe
        <alive> = 0
        if ScreenElementExists id = menu_id_color
            <alive> = 1
        endif
        if ScreenElementExists id = scalingmenu_x_slider
            <alive> = 1
        endif
        if ScreenElementExists id = scalingmenu_xyz_slider
            <alive> = 1
        endif
        if ( <alive> = 0 )
            break
        endif
        dadmod_stick_step
        if ( <step> > 1 )
            if not IsTrue dadmod_stick_fast
                Change dadmod_stick_fast = 1
                Change thugpro_colormenu_hue_increment = 6.0
                Change thugpro_colormenu_saturation_increment = 6.0
                Change thugpro_colormenu_value_increment = 6.0
                Change scalingmenu_scale_increment = 6
            endif
        else
            if IsTrue dadmod_stick_fast
                dadmod_stick_slow
            endif
        endif
    repeat
    dadmod_stick_slow
    Change dadmod_stick_watching = 0
endscript
script dadmod_stick_slow
    Change dadmod_stick_fast = 0
    Change thugpro_colormenu_hue_increment = 1.0
    Change thugpro_colormenu_saturation_increment = 1.0
    Change thugpro_colormenu_value_increment = 1.0
    Change scalingmenu_scale_increment = 1
endscript
