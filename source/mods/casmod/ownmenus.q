scalingmenu_min_scale = 0.0
scalingmenu_max_scale = 1000000.0
scalingmenu_constraints = [
{ part = object_scaling male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = headtop_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = head_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = nose_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = jaw_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = torso_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = stomach_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = upper_arm_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = lower_arm_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = hands_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = upper_leg_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = lower_leg_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = feet_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = board_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
{ part = wheels_bone_group male_max = 1000000.0 male_min = 0.0 female_max = 1000000.0 female_min = 0.0 }
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
dadmod_color_sliders = [
{ which = h bar = colorbar label = "Color" el = menu_id_color }
{ which = v bar = bw_slider label = "Brightness" el = menu_id_value }
{ which = s bar = bw_slider label = "Saturation" el = menu_id_saturation }
]
script thugpro_color_menu_add_options_to_menu
    GetArraySize dadmod_color_sliders
    <dm_i> = 0
    begin
        <sl> = ( dadmod_color_sliders [ <dm_i> ] )
        <cb> = { component = ( <sl> . which ) part = <part> }
        make_thugpro_menu_slider_item {
        option_arrows
        option_arrows_callback_params = <cb>
        option_arrows_callback = __thugpro_color_menu_change_component
        child_texture = ( <sl> . bar )
        extra_text = "0"
        text = ( <sl> . label )
        id = ( <sl> . el )
        }
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
    <cb> = { part = <part> }
    make_thugpro_menu_item pad_choose_params = <cb> pad_choose_script = dadmod_random_color text = "Random Color"
    make_thugpro_menu_item pad_choose_params = <cb> pad_choose_script = __thugpro_color_menu_reset_to_default text = "Default Color"
    dadmod_undo_keys
    dadmod_stick_watch_start
endscript
script dadmod_random_color
    dadmod_me
    SetPlayerAppearanceColor player = <me> part = <part> h = RandomRange (0.0,359.0) s = RandomRange (10.0,70.0) v = RandomRange (10.0,60.0) use_default_hsv = 0
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
script dadmod_scale_nudge
    <dm_step> = ( ( scalingmenu_scale_increment ) * 1.0 )
    if ( ( <dm_v> / 20.0 ) > <dm_step> )
        <dm_step> = ( <dm_v> / 20.0 )
    endif
    <dm_v> = ( <dm_v> + ( <dm_step> * <dm_sign> ) )
    if ( <lo> > <dm_v> )
        <dm_v> = <lo>
    endif
    if ( <dm_v> > <hi> )
        <dm_v> = <hi>
    endif
    CastToInteger dm_v
    return dm_v = <dm_v>
endscript
script __thugpro_scaling_menu_change_uniform
    GetTags
    <dm_sign> = -1
    if GotParam right
        <dm_sign> = 1
    endif
    scalingmenu_get_limits part = <part> <...>
    scalingmenu_get_xyz part = <part>
    if GotParam affectZ
        if ( <affectZ> = 1 )
            dadmod_scale_nudge dm_v = <z> dm_sign = <dm_sign> lo = <min> hi = <max>
            <z> = <dm_v>
        endif
    endif
    if GotParam affectY
        if ( <affectY> = 1 )
            dadmod_scale_nudge dm_v = <y> dm_sign = <dm_sign> lo = <min> hi = <max>
            <y> = <dm_v>
        endif
    endif
    if GotParam affectX
        if ( <affectX> = 1 )
            dadmod_scale_nudge dm_v = <x> dm_sign = <dm_sign> lo = <min> hi = <max>
            <x> = <dm_v>
        endif
    endif
    scalingmenu_set_xyz z = <z> y = <y> x = <x> part = <part>
    scalingmenu_refresh_skaters
    __thugpro_scaling_menu_refresh part = <part>
endscript
