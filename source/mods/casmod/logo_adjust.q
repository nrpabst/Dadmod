dadmod_logo_ranges = [
{ part = left_forearm_tattoo flip = 1 u_lo = -75 u_hi = 75 v_lo = -500 v_hi = 200 }
{ part = right_forearm_tattoo flip = -1 u_lo = -75 u_hi = 75 v_lo = -500 v_hi = 200 }
{ part = left_bicep_tattoo flip = 1 u_lo = -75 u_hi = 75 v_lo = -200 v_hi = 500 }
{ part = right_bicep_tattoo flip = -1 u_lo = -75 u_hi = 75 v_lo = -200 v_hi = 500 }
]
dadmod_logo_default_range = { flip = 1 u_lo = -300 u_hi = 300 v_lo = -300 v_hi = 300 }
dadmod_logo_scale_lo = 1
dadmod_logo_scale_hi = 500
script dadmod_logo_range
    <r> = dadmod_logo_default_range
    GetArraySize dadmod_logo_ranges
    <i> = 0
    begin
        if ChecksumEquals a = ( ( dadmod_logo_ranges [ <i> ] ) . part ) b = <part>
            <r> = ( dadmod_logo_ranges [ <i> ] )
            break
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
    return range = <r>
endscript
script dadmod_logo_wrap
    if ( <n> < <lo> )
        return n = <hi>
    endif
    if ( <n> > <hi> )
        return n = <lo>
    endif
    return n = <n>
endscript
script dadmod_logo_apply
    posmenu_set_uv part = <part> uv_u = <uv_u> uv_v = <uv_v> uv_scale = <uv_scale> uv_rot = <uv_rot>
    refresh_skater_uv
endscript
script posmenu_adjust_uv_position
    GetTags
    if not GotParam pass
        return
    endif
    if not GotParam material
        return
    endif
    dadmod_logo_range part = <part>
    <step> = ( <range> . flip )
    if GotParam right
        <step> = ( 0 - <step> )
    endif
    posmenu_get_uv part = <part>
    if ( <component> = v )
        dadmod_logo_wrap n = ( <uv_v> - <step> ) lo = ( <range> . v_lo ) hi = ( <range> . v_hi )
        if ( <n> = <uv_v> )
            return
        endif
        <uv_v> = <n>
    else
        dadmod_logo_wrap n = ( <uv_u> + <step> ) lo = ( <range> . u_lo ) hi = ( <range> . u_hi )
        if ( <n> = <uv_u> )
            return
        endif
        <uv_u> = <n>
    endif
    dadmod_logo_apply <...>
    posmenu_update_all_text part = <part>
endscript
script posmenu_adjust_uv_rotation
    GetTags
    if not GotParam pass
        return
    endif
    if not GotParam material
        return
    endif
    dadmod_logo_range part = <part>
    <step> = ( <range> . flip )
    if GotParam left
        <step> = ( 0 - <step> )
    endif
    posmenu_get_uv part = <part>
    <uv_rot> = ( <uv_rot> + <step> )
    if ( <uv_rot> < 0 )
        <uv_rot> = ( <uv_rot> + 360 )
    endif
    if ( <uv_rot> > 359 )
        <uv_rot> = ( <uv_rot> - 360 )
    endif
    dadmod_logo_apply <...>
    posmenu_update_all_text part = <part>
endscript
script posmenu_adjust_uv_scale
    GetTags
    if not GotParam pass
        return
    endif
    if not GotParam material
        return
    endif
    posmenu_get_uv part = <part>
    <old> = <uv_scale>
    if GotParam right
        <uv_scale> = ( <uv_scale> - 1 )
    else
        <uv_scale> = ( <uv_scale> + 1 )
    endif
    if ( <uv_scale> < dadmod_logo_scale_lo )
        <uv_scale> = dadmod_logo_scale_lo
    endif
    if ( <uv_scale> > dadmod_logo_scale_hi )
        <uv_scale> = dadmod_logo_scale_hi
    endif
    if ( <uv_scale> = <old> )
        return
    endif
    dadmod_logo_apply <...>
    posmenu_update_all_text part = <part>
endscript
script posmenu_update_all_text
    if not GotParam part
        return
    endif
    posmenu_get_uv part = <part>
    <size> = ( 10000.0 / <uv_scale> )
    CastToInteger uv_u
    CastToInteger uv_v
    CastToInteger uv_rot
    CastToInteger size
    if ScreenElementExists id = menu_pos_x_parts
        FormatText TextName = t "%a" a = <uv_u>
        thugpro_menu_item_update_extra_text { id = menu_pos_x_parts text = <t> }
    endif
    if ScreenElementExists id = menu_pos_y_parts
        FormatText TextName = t "%a" a = <uv_v>
        thugpro_menu_item_update_extra_text { id = menu_pos_y_parts text = <t> }
    endif
    if ScreenElementExists id = menu_rot_parts
        FormatText TextName = t "%a" a = <uv_rot>
        thugpro_menu_item_update_extra_text { id = menu_rot_parts text = <t> }
    endif
    if ScreenElementExists id = menu_scale_parts
        FormatText TextName = t "%a%%" a = <size>
        thugpro_menu_item_update_extra_text { id = menu_scale_parts text = <t> }
    endif
endscript
