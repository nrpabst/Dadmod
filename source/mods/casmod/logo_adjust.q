dadmod_logo_ranges = [
{ part = left_forearm_tattoo flip = 1 u_lo = -75 u_hi = 75 v_lo = -500 v_hi = 200 }
{ part = right_forearm_tattoo flip = -1 u_lo = -75 u_hi = 75 v_lo = -500 v_hi = 200 }
{ part = left_bicep_tattoo flip = 1 u_lo = -75 u_hi = 75 v_lo = -200 v_hi = 500 }
{ part = right_bicep_tattoo flip = -1 u_lo = -75 u_hi = 75 v_lo = -200 v_hi = 500 }
]
dadmod_logo_default_range = { flip = 1 u_lo = -300 u_hi = 300 v_lo = -300 v_hi = 300 }
dadmod_logo_scale_lo = 0.001
dadmod_logo_scale_hi = 10000.0
dadmod_logo_scale_step = 1.05
dadmod_logo_float = 0
script dadmod_logo_range
    <r> = dadmod_logo_default_range
    GetArraySize dadmod_logo_ranges
    <dm_i> = 0
    begin
        if ChecksumEquals a = ( ( dadmod_logo_ranges [ <dm_i> ] ) . part ) b = <part>
            <r> = ( dadmod_logo_ranges [ <dm_i> ] )
            break
        endif
        <dm_i> = ( <dm_i> + 1 )
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
    posmenu_set_uv uv_rot = <uv_rot> uv_scale = <uv_scale> uv_v = <uv_v> uv_u = <uv_u> part = <part>
    refresh_skater_uv
endscript
script posmenu_adjust_uv_position
    GetTags
    if not GotParam material
        return
    endif
    if not GotParam pass
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
    if not GotParam material
        return
    endif
    if not GotParam pass
        return
    endif
    dadmod_logo_range part = <part>
    <step> = ( <range> . flip )
    if GotParam left
        <step> = ( 0 - <step> )
    endif
    posmenu_get_uv part = <part>
    <uv_rot> = ( <uv_rot> + <step> )
    if ( <uv_rot> > 359 )
        <uv_rot> = ( <uv_rot> - 360 )
    endif
    if ( 0 > <uv_rot> )
        <uv_rot> = ( 360 + <uv_rot> )
    endif
    dadmod_logo_apply <...>
    posmenu_update_all_text part = <part>
endscript
script posmenu_adjust_uv_scale
    GetTags
    if not GotParam material
        return
    endif
    if not GotParam pass
        return
    endif
    posmenu_get_uv part = <part>
    <old> = <uv_scale>
    if GotParam right
        <uv_scale> = ( <uv_scale> / ( dadmod_logo_scale_step ) )
    else
        <uv_scale> = ( <uv_scale> * ( dadmod_logo_scale_step ) )
    endif
    if ( ( dadmod_logo_scale_lo ) > <uv_scale> )
        <uv_scale> = ( dadmod_logo_scale_lo )
    endif
    if ( <uv_scale> > ( dadmod_logo_scale_hi ) )
        <uv_scale> = ( dadmod_logo_scale_hi )
    endif
    if ( 1.0 > <uv_scale> )
        dadmod_logo_float_check part = <part> keep = <old>
        if ( <float_ok> = 0 )
            <uv_scale> = 1
        endif
    endif
    if ( <uv_scale> = <old> )
        return
    endif
    dadmod_logo_apply <...>
    posmenu_update_all_text part = <part>
endscript
script dadmod_logo_float_check
    if ( ( dadmod_logo_float ) = 0 )
        posmenu_get_uv part = <part>
        posmenu_set_uv uv_rot = <uv_rot> uv_scale = 1.5 uv_v = <uv_v> uv_u = <uv_u> part = <part>
        posmenu_get_uv part = <part>
        <dm_seen> = <uv_scale>
        posmenu_set_uv uv_rot = <uv_rot> uv_scale = <keep> uv_v = <uv_v> uv_u = <uv_u> part = <part>
        if ( <dm_seen> = 1.5 )
            Change dadmod_logo_float = 1
        else
            Change dadmod_logo_float = 2
        endif
    endif
    if ( ( dadmod_logo_float ) = 1 )
        return float_ok = 1
    endif
    return float_ok = 0
endscript
script dadmod_logo_put
    if ScreenElementExists id = <el>
        thugpro_menu_item_update_extra_text { text = <txt> id = <el> }
    endif
endscript
script posmenu_update_all_text
    if not GotParam part
        return
    endif
    posmenu_get_uv part = <part>
    <size> = 100
    if ( <uv_scale> > 0 )
        <size> = ( 10000.0 / <uv_scale> )
    endif
    CastToInteger size
    CastToInteger uv_rot
    CastToInteger uv_u
    CastToInteger uv_v
    FormatText TextName = dm_txt "%a" a = <size>
    dadmod_logo_put el = menu_scale_parts txt = <dm_txt>
    FormatText TextName = dm_txt "%a" a = <uv_rot>
    dadmod_logo_put el = menu_rot_parts txt = <dm_txt>
    FormatText TextName = dm_txt "%a" a = <uv_v>
    dadmod_logo_put el = menu_pos_y_parts txt = <dm_txt>
    FormatText TextName = dm_txt "%a" a = <uv_u>
    dadmod_logo_put el = menu_pos_x_parts txt = <dm_txt>
endscript
