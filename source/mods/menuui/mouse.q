dadmod_cg_layout = -1
script dadmod_char_guide_tick
    if not ScreenElementExists id = char_guide_l2
        Change dadmod_cg_layout = -1
        return
    endif
    cg_lay = 1
    if ( ( GLOBAL_CtrlLayout ) = 0 )
        cg_lay = 0
    endif
    if (<cg_lay> = ( dadmod_cg_layout ))
        return
    endif
    Change dadmod_cg_layout = <cg_lay>
    dadmod_kb_label row = keyboard_row_4 idx = 6 lay = <cg_lay> glyph = '\\m9' scale = (0.85,0.75) small = (0.68,0.75) shrink = 0.8
    dadmod_kb_label row = keyboard_row_5 idx = 2 lay = <cg_lay> glyph = '\\m8'
    dadmod_kb_label row = keyboard_row_6 idx = 1 lay = <cg_lay> glyph = '\\m1'
    if (<cg_lay> = 0)
        SetScreenElementProps id = char_guide_l2 text = ""
        if ScreenElementExists id = char_guide_r2
            SetScreenElementProps id = char_guide_r2 text = ""
        endif
    else
        SetScreenElementProps id = char_guide_l2 text = '\\mf'
        if ScreenElementExists id = char_guide_r2
            SetScreenElementProps id = char_guide_r2 text = '\\mg'
        endif
    endif
endscript
script dadmod_kb_label
    if not ScreenElementExists id = { <row> child = { <idx> child = 31 } }
        return
    endif
    if not ScreenElementExists id = { <row> child = { <idx> child = 30 } }
        return
    endif
    if (<lay> = 0)
        SetScreenElementProps id = { <row> child = { <idx> child = 30 } } text = ""
        mm_kw = 40.0
        GetScreenElementDims id = { <row> child = { <idx> child = 31 } }
        mm_kw = <width>
        if GotParam small
            DoScreenElementMorph id = { <row> child = { <idx> child = 31 } } scale = <small> time = 0
            mm_kw = ( <mm_kw> * <shrink> )
        endif
        mm_kx = ( 62.0 - ( <mm_kw> / 2.0 ) )
        SetScreenElementProps id = { <row> child = { <idx> child = 31 } } pos = ( (1.0,0.0) * <mm_kx> + (0.0,10.0) )
    else
        SetScreenElementProps id = { <row> child = { <idx> child = 30 } } text = <glyph>
        if GotParam scale
            DoScreenElementMorph id = { <row> child = { <idx> child = 31 } } scale = <scale> time = 0
        endif
        SpawnScript dadmod_kb_label_place params = { row = <row> idx = <idx> }
    endif
endscript
script dadmod_kb_label_place
    wait 1 gameframe
    if not ScreenElementExists id = { <row> child = { <idx> child = 31 } }
        return
    endif
    if not ScreenElementExists id = { <row> child = { <idx> child = 30 } }
        return
    endif
    GetStackedScreenElementPos x id = { <row> child = { <idx> child = 30 } } offset = (3.0,0.0)
    SetScreenElementProps id = { <row> child = { <idx> child = 31 } } pos = <pos>
endscript
dadmod_mouse_last = none
dadmod_mouse_pxu = 0.0
dadmod_mouse_pyu = 0.0
dadmod_mouse_back_hl = -1
dadmod_mouse_next_hl = -1
script dadmod_mouse_rpause
    rp_ok = 0
    if not LevelIs Load_MainMenu
        if ObjectExists id = skater
            rp_ok = 1
        endif
    endif
    if (<rp_ok> = 1)
        if ScreenElementExists id = current_menu_anchor
            rp_ok = 0
        endif
        if ScreenElementExists id = current_menu
            rp_ok = 0
        endif
        if ScreenElementExists id = dialog_box_anchor
            rp_ok = 0
        endif
        if ScreenElementExists id = keyboard_anchor
            rp_ok = 0
        endif
        if IsTrue view_mode
            rp_ok = 0
        endif
    endif
    THUGRECOMP_MouseRightPause ok = <rp_ok>
endscript
script dadmod_mouse_tick
    dadmod_mouse_rpause
    if ScreenElementExists id = keyboard_anchor
        if ScreenElementExists id = keyboard_vmenu
            dadmod_mouse_kb_tick
            return
        endif
    endif
    Change dadmod_mouse_kb_row = none
    mm_menu = 0
    mm_mid = current_menu
    mm_dialog = 0
    if ScreenElementExists id = dialog_box_vmenu
        mm_menu = 1
        mm_mid = dialog_box_vmenu
        mm_dialog = 1
    else
        if ScreenElementExists id = <mm_mid>
            mm_menu = 1
        endif
    endif
    if ScreenElementExists id = keyboard_anchor
        mm_menu = 0
    endif
    mm_screen = <mm_menu>
    if ScreenElementExists id = helper_text_anchor
        if LevelIs Load_MainMenu
            mm_screen = 1
        endif
    endif
    mm_accept = 0
    if (<mm_dialog> = 0)
        if ScreenElementExists id = select_skater_anchor
            mm_accept = 1
            mm_screen = 1
        endif
    endif
    if ScreenElementExists id = keyboard_anchor
        mm_screen = 0
    endif
    mm_lvl = 0
    if (<mm_dialog> = 0)
        if ScreenElementExists id = level_select_logo
            mm_lvl = 1
        endif
        if ScreenElementExists id = level_select_panel_container
            mm_lvl = 1
        endif
    endif
    mm_nocam = <mm_accept>
    mm_hc = <mm_screen>
    if (<mm_screen> = 0)
        if (<mm_menu> = 0)
            if ScreenElementExists id = root_window
                if root_window : GetSingleTag dadmod_walkcam_ok
                    if (<dadmod_walkcam_ok> = 1)
                        mm_hc = 2
                    endif
                endif
            endif
        endif
    endif
    if (<mm_dialog> = 1)
        mm_nocam = 1
    endif
    if (<mm_lvl> = 1)
        mm_nocam = 1
    endif
    if (<mm_menu> = 1)
        THUGRECOMP_MouseMenu id = <mm_mid> root = root_window nocam = <mm_nocam> hidecur = <mm_screen> nodrag = <mm_lvl>
    else
        THUGRECOMP_MouseMenu id = dadmod_mouse_no_menu root = root_window nocam = <mm_nocam> hidecur = <mm_hc>
    endif
    if (<mm_screen> = 0)
        ms_active = 0
    endif
    if (<ms_active> = 0)
        dadmod_mouse_hide
        Change dadmod_mouse_last = none
        return
    endif
    if not (<ms_px_unit> = ( dadmod_mouse_pxu ))
        dadmod_mouse_hide
    endif
    if not (<ms_px_unit_y> = ( dadmod_mouse_pyu ))
        dadmod_mouse_hide
    endif
    Change dadmod_mouse_pxu = <ms_px_unit>
    Change dadmod_mouse_pyu = <ms_px_unit_y>
    dadmod_mouse_pointer
    if ScreenElementExists id = startup_menu
        ms_over_back = 0
        if ScreenElementExists id = dadmod_mouse_back
            DestroyScreenElement id = dadmod_mouse_back
        endif
    else
        dadmod_mouse_back_button x = <ms_corner_x> y = <ms_corner_y> mm_hl = <ms_over_back>
    endif
    mm_next = 0
    mm_side_l = 0
    mm_side_r = 0
    mm_over_sel = 0
    mm_over_load = 0
    if (<mm_accept> = 1)
        ms_hit = -1
        mm_next = 1
        dadmod_mouse_ss_arrows x = <ms_x> y = <ms_y>
        dadmod_mouse_ss_buttons x = <ms_x> y = <ms_y> cx = <ms_corner_x> cy = <ms_corner_y>
        dadmod_mouse_skin_pill x = <ms_x> y = <ms_y>
    else
        dadmod_mouse_ss_off
    endif
    if (<mm_menu> = 0)
        mm_next = 1
    else
        if (<ms_rows> = 0)
            mm_next = 1
        endif
    endif
    if (<mm_accept> = 1)
        mm_next_btn = 0
    else
        mm_next_btn = <mm_next>
    endif
    if (<mm_next_btn> = 1)
        dadmod_mouse_next_button x = <ms_next_x> y = <ms_corner_y> mm_hl = <ms_over_next>
    else
        ms_over_next = 0
        if ScreenElementExists id = dadmod_mouse_next
            DestroyScreenElement id = dadmod_mouse_next
        endif
        Change dadmod_mouse_next_hl = -1
    endif
    mm_scroll = <ms_hover_edge>
    dadmod_mouse_hover_bar_off
    if (<ms_hit> > -1)
        if not (<ms_hit_id> = ( dadmod_mouse_last ))
            mm_hov = 0
            if (<ms_click> > 0)
                mm_hov = 1
            endif
            if (<ms_moved> = 1)
                if (<mm_scroll> = 0)
                    mm_hov = 1
                endif
            endif
            if (<mm_hov> = 1)
                if ScreenElementExists id = <ms_hit_id>
                    FireEvent type = unfocus target = <mm_mid>
                    FireEvent type = focus target = <mm_mid> data = { child_id = <ms_hit_id> }
                    Change dadmod_mouse_last = <ms_hit_id>
                    Change dadmod_mouse_tagside = 0
                endif
            endif
        endif
        if (<ms_moved> = 1)
            if (<ms_hit_id> = ( dadmod_mouse_last ))
                dadmod_mouse_tag_hover id = <ms_hit_id> x = <ms_x> y = <ms_y>
            endif
        endif
    endif
    mm_lv_l = 0
    mm_lv_r = 0
    if (<mm_lvl> = 1)
        if (<ms_box> = 1)
            dadmod_mouse_lvl_arrows x = <ms_x> y = <ms_y> bx0 = <ms_bx0> by0 = <ms_by0> bx1 = <ms_bx1> by1 = <ms_by1> cx = <ms_corner_x> rx = ( <ms_next_x> + ( 34.0 * <ms_px_unit> ) )
        endif
    else
        dadmod_mouse_lvl_off
    endif
    if (<ms_click> > 0)
        if (<ms_over_back> = 1)
            dadmod_mouse_back_press
            return
        endif
        if (<mm_lv_l> = 1)
            SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_ll child = arr_c } x = 28.0 y = 28.0 dx = -8.0 }
            if ScreenElementExists id = current_menu
                FireEvent type = pad_left target = current_menu
            endif
            return
        endif
        if (<mm_lv_r> = 1)
            SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_lr child = arr_c } x = 28.0 y = 28.0 dx = 8.0 }
            if ScreenElementExists id = current_menu
                FireEvent type = pad_right target = current_menu
            endif
            return
        endif
        if (<mm_over_load> = 1)
            SpawnScript dadmod_mouse_press params = { id = { dadmod_mouse_ssb child = load_box } flash = { dadmod_mouse_ssb child = { load_box child = load_bg } } fill = [ 50 50 50 128 ] }
            Change dadmod_mouse_last = none
            generic_menu_pad_choose_sound
            ss_overwrite_warning
            return
        endif
        if GotParam mm_skin_l
            if (<mm_skin_l> = 1)
                SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_skin child = skin_l } x = -94.0 y = 0.0 dx = -6.0 }
                if ScreenElementExists id = <mm_skin_item>
                    FireEvent type = pad_up target = <mm_skin_item>
                endif
                return
            endif
            if (<mm_skin_r> = 1)
                SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_skin child = skin_r } x = 94.0 y = 0.0 dx = 6.0 }
                if ScreenElementExists id = <mm_skin_item>
                    FireEvent type = pad_down target = <mm_skin_item>
                endif
                return
            endif
        endif
        if (<mm_side_l> = 1)
            SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_sl child = arr_c } x = 28.0 y = 28.0 dx = -8.0 }
            if ScreenElementExists id = <mm_mid>
                FireEvent type = pad_left target = <mm_mid>
            endif
            return
        endif
        if (<mm_side_r> = 1)
            SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_sr child = arr_c } x = 28.0 y = 28.0 dx = 8.0 }
            if ScreenElementExists id = <mm_mid>
                FireEvent type = pad_right target = <mm_mid>
            endif
            return
        endif
        if (<mm_next> = 1)
            if (<mm_over_sel> = 1)
                SpawnScript dadmod_mouse_press params = { id = { dadmod_mouse_ssb child = sel_box } flash = { dadmod_mouse_ssb child = { sel_box child = sel_bg } } fill = [ 60 60 60 128 ] }
                mm_kx = ( ( ( dadmod_mouse_selw ) / 2.0 ) - 30.0 )
                SpawnScript dadmod_mouse_kick params = { id = { dadmod_mouse_ssb child = { sel_box child = sel_chev } } x = <mm_kx> y = 0.0 dx = 8.0 }
            endif
            Change dadmod_mouse_last = none
            THUGRECOMP_MouseNext
            return
        endif
        if (<ms_hit> > -1)
            dadmod_mouse_click id = <ms_hit_id> x = <ms_x> y = <ms_y>
            return
        endif
    endif
    if (<ms_rclick> > 0)
        dadmod_mouse_back_press
        return
    endif
    if (<mm_accept> = 1)
        if (<ms_wheel> > 0)
            begin
                if ScreenElementExists id = <mm_mid>
                    FireEvent type = pad_left target = <mm_mid>
                endif
            repeat <ms_wheel>
        endif
        if (<ms_wheel> < 0)
            n = (0 - <ms_wheel>)
            begin
                if ScreenElementExists id = <mm_mid>
                    FireEvent type = pad_right target = <mm_mid>
                endif
            repeat <n>
        endif
        return
    endif
    if (<ms_wheel> > 0)
        Change dadmod_mouse_last = none
        begin
            if ScreenElementExists id = <mm_mid>
                FireEvent type = pad_up target = <mm_mid>
            endif
        repeat <ms_wheel>
    endif
    if (<ms_wheel> < 0)
        Change dadmod_mouse_last = none
        n = (0 - <ms_wheel>)
        begin
            if ScreenElementExists id = <mm_mid>
                FireEvent type = pad_down target = <mm_mid>
            endif
        repeat <n>
    endif
endscript
dadmod_mouse_kb_row = none
script dadmod_mouse_kb_tick
    THUGRECOMP_MouseMenu id = keyboard_vmenu grid = 1 hidecur = 1
    if (<ms_active> = 0)
        dadmod_mouse_hide
        Change dadmod_mouse_last = none
        Change dadmod_mouse_kb_row = none
        return
    endif
    if not (<ms_px_unit> = ( dadmod_mouse_pxu ))
        dadmod_mouse_hide
    endif
    if not (<ms_px_unit_y> = ( dadmod_mouse_pyu ))
        dadmod_mouse_hide
    endif
    Change dadmod_mouse_pxu = <ms_px_unit>
    Change dadmod_mouse_pyu = <ms_px_unit_y>
    dadmod_mouse_pointer
    if ScreenElementExists id = dadmod_mouse_next
        DestroyScreenElement id = dadmod_mouse_next
    endif
    Change dadmod_mouse_next_hl = -1
    dadmod_mouse_back_button x = <ms_corner_x> y = <ms_corner_y> mm_hl = <ms_over_back>
    if (<ms_hit> > -1)
        if GotParam ms_hit_row
            if not (<ms_hit_id> = ( dadmod_mouse_last ))
                if ( (<ms_moved> = 1) or (<ms_click> > 0) )
                    if ScreenElementExists id = <ms_hit_row>
                        if ScreenElementExists id = <ms_hit_id>
                            if not (<ms_hit_row> = ( dadmod_mouse_kb_row ))
                                FireEvent type = unfocus target = keyboard_vmenu
                                FireEvent type = focus target = keyboard_vmenu data = { child_id = <ms_hit_row> }
                                Change dadmod_mouse_kb_row = <ms_hit_row>
                            endif
                            FireEvent type = unfocus target = <ms_hit_row>
                            FireEvent type = focus target = <ms_hit_row> data = { child_id = <ms_hit_id> }
                            Change dadmod_mouse_last = <ms_hit_id>
                        endif
                    endif
                endif
            endif
        endif
    endif
    if (<ms_click> > 0)
        if (<ms_over_back> = 1)
            dadmod_mouse_back_press
            return
        endif
        if THUGRECOMP_MouseOver id = char_guide_left_arrow x = <ms_x> y = <ms_y> pad = 8.0
            FireEvent type = pad_l1 target = keyboard_vmenu
            return
        endif
        if THUGRECOMP_MouseOver id = char_guide_right_arrow x = <ms_x> y = <ms_y> pad = 8.0
            FireEvent type = pad_r1 target = keyboard_vmenu
            return
        endif
        if (<ms_hit> > -1)
            if ScreenElementExists id = <ms_hit_id>
                SpawnScript dadmod_kb_click_anim params = { id = <ms_hit_id> }
                FireEvent type = pad_choose target = <ms_hit_id>
            endif
            return
        endif
    endif
    if (<ms_rclick> > 0)
        dadmod_mouse_back_press
    endif
endscript
script dadmod_mouse_click
    if not ScreenElementExists id = <id>
        return
    endif
    if THUGRECOMP_MouseArrows row = <id> left = { <id> child = left_arrow } right = { <id> child = right_arrow } tag1 = { <id> child = dadmod_tag } tag1a = { <id> child = dadmod_tag_arrow } tag2 = { <id> child = dadmod_tag2 } tag2a = { <id> child = dadmod_tag2_arrow } x = <x> y = <y>
        if (<ms_tag> > 0)
            dadmod_mouse_es_tag id = <id> n = <ms_tag>
            return
        endif
        if (<ms_arrow> = 0)
            FireEvent type = pad_left target = <id>
            return
        endif
        if (<ms_arrow> = 1)
            FireEvent type = pad_right target = <id>
            return
        endif
    endif
    if not LevelIs Load_MainMenu
        if ScreenElementExists id = root_window
            if root_window : GetSingleTag pause_controller
                FireEvent type = pad_choose target = <id> data = { device_num = <pause_controller> }
                return
            endif
        endif
    endif
    FireEvent type = pad_choose target = <id>
endscript
dadmod_mouse_tagside = 0
script dadmod_mouse_tag_hover
    if not ScreenElementExists id = { <id> child = dadmod_tag }
        return
    endif
    mm_want = 0
    if THUGRECOMP_MouseArrows row = <id> tag1 = { <id> child = dadmod_tag } tag1a = { <id> child = dadmod_tag_arrow } tag2 = { <id> child = dadmod_tag2 } tag2a = { <id> child = dadmod_tag2_arrow } x = <x> y = <y>
        mm_want = <ms_tag>
    endif
    if (<mm_want> = ( dadmod_mouse_tagside ))
        return
    endif
    Change dadmod_mouse_tagside = <mm_want>
    if (<mm_want> = 0)
        SetScreenElementProps id = <id> tags = { dadmod_side = 1 }
        FireEvent type = pad_left target = <id>
        return
    endif
    SetScreenElementProps id = <id> tags = { dadmod_side = 0 }
    FireEvent type = pad_right target = <id>
    if (<mm_want> = 2)
        if ScreenElementExists id = <id>
            FireEvent type = pad_right target = <id>
        endif
    endif
endscript
script dadmod_mouse_es_tag
    if not ScreenElementExists id = <id>
        return
    endif
    SetScreenElementProps id = <id> tags = { dadmod_side = 0 }
    FireEvent type = pad_right target = <id>
    if (<n> = 2)
        FireEvent type = pad_right target = <id>
    endif
    Change dadmod_mouse_tagside = <n>
    if ScreenElementExists id = <id>
        FireEvent type = pad_choose target = <id>
    endif
endscript
script dadmod_mouse_back_press
    Change dadmod_mouse_last = none
    if ScreenElementExists id = startup_menu
        return
    endif
    THUGRECOMP_MouseBack
endscript
script dadmod_mouse_hide
    if ScreenElementExists id = dadmod_mouse_ptr
        DestroyScreenElement id = dadmod_mouse_ptr
    endif
    if ScreenElementExists id = dadmod_mouse_back
        DestroyScreenElement id = dadmod_mouse_back
    endif
    if ScreenElementExists id = dadmod_mouse_next
        DestroyScreenElement id = dadmod_mouse_next
    endif
    Change dadmod_mouse_back_hl = -1
    Change dadmod_mouse_next_hl = -1
    dadmod_mouse_ss_off
    dadmod_mouse_lvl_off
    dadmod_mouse_hover_bar_off
endscript
script dadmod_mouse_px parent = dadmod_mouse_ptr x = 0 y = 0 w = 1 h = 1 rgba = [ 128 128 128 128 ] z = 9000 a = 1.0
    if GotParam lid
        CreateScreenElement {
        type = SpriteElement
        parent = <parent>
        local_id = <lid>
        texture = white
        just = [ left top ]
        pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) )
        scale = ( (1.0,0.0) * ( <w> * ( dadmod_mouse_pxu ) / 4.0 ) + (0.0,1.0) * ( <h> * ( dadmod_mouse_pyu ) / 4.0 ) )
        rgba = <rgba>
        alpha = <a>
        z_priority = <z>
        }
        return
    endif
    CreateScreenElement {
    type = SpriteElement
    parent = <parent>
    texture = white
    just = [ left top ]
    pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) )
    scale = ( (1.0,0.0) * ( <w> * ( dadmod_mouse_pxu ) / 4.0 ) + (0.0,1.0) * ( <h> * ( dadmod_mouse_pyu ) / 4.0 ) )
    rgba = <rgba>
    alpha = <a>
    z_priority = <z>
    }
endscript
script dadmod_mouse_pointer
    if ScreenElementExists id = dadmod_mouse_ptr
        DestroyScreenElement id = dadmod_mouse_ptr
    endif
endscript
dadmod_mouse_sl_hl = -1
dadmod_mouse_sr_hl = -1
script dadmod_mouse_tri parent = dadmod_mouse_sl x = 0 y = 0 n = 14 dir = 0 rgba = [ 128 128 128 128 ] z = 8993 sh = 1
    mm_ti = 0
    begin
        if (<dir> = 0)
            mm_tx = ( <x> + <mm_ti> )
        else
            mm_tx = ( <x> + <n> - 1 - <mm_ti> )
        endif
        if (<sh> = 1)
            dadmod_mouse_px parent = <parent> x = ( <mm_tx> + 2 ) y = ( <y> - <mm_ti> + 2 ) w = 1 h = ( 2 * <mm_ti> + 1 ) rgba = [ 0 0 0 128 ] a = 0.35 z = ( <z> - 1 )
        endif
        dadmod_mouse_px parent = <parent> x = <mm_tx> y = ( <y> - <mm_ti> ) w = 1 h = ( 2 * <mm_ti> + 1 ) rgba = <rgba> z = <z>
        dadmod_mouse_px parent = <parent> x = <mm_tx> y = ( <y> - <mm_ti> - 1 ) w = 1 h = 1 rgba = <rgba> a = 0.45 z = <z>
        dadmod_mouse_px parent = <parent> x = <mm_tx> y = ( <y> + <mm_ti> + 1 ) w = 1 h = 1 rgba = <rgba> a = 0.45 z = <z>
        mm_ti = ( <mm_ti> + 1 )
    repeat <n>
endscript
script dadmod_mouse_frame parent = dadmod_mouse_ssb x = 0 y = 0 w = 100 h = 30 th = 2 rgba = [ 128 128 128 128 ] fill = [ 0 0 0 128 ] fa = 0.8 z = 8992 lid = none
    dadmod_mouse_px parent = <parent> x = ( <x> + 4 ) y = ( <y> + 4 ) w = <w> h = <h> rgba = [ 0 0 0 128 ] a = 0.3 z = ( <z> - 2 )
    if (<lid> = none)
        dadmod_mouse_px parent = <parent> x = ( <x> + 1 ) y = ( <y> + 1 ) w = ( <w> - 2 ) h = ( <h> - 2 ) rgba = <fill> a = <fa> z = ( <z> - 1 )
    else
        dadmod_mouse_px parent = <parent> lid = <lid> x = ( <x> + 1 ) y = ( <y> + 1 ) w = ( <w> - 2 ) h = ( <h> - 2 ) rgba = <fill> a = <fa> z = ( <z> - 1 )
    endif
    dadmod_mouse_px parent = <parent> x = ( <x> + 2 ) y = <y> w = ( <w> - 4 ) h = <th> rgba = <rgba> z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + 2 ) y = ( <y> + <h> - <th> ) w = ( <w> - 4 ) h = <th> rgba = <rgba> z = <z>
    dadmod_mouse_px parent = <parent> x = <x> y = ( <y> + 2 ) w = <th> h = ( <h> - 4 ) rgba = <rgba> z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + <w> - <th> ) y = ( <y> + 2 ) w = <th> h = ( <h> - 4 ) rgba = <rgba> z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + 1 ) y = ( <y> + 1 ) w = 1 h = 1 rgba = <rgba> a = 0.6 z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + <w> - 2 ) y = ( <y> + 1 ) w = 1 h = 1 rgba = <rgba> a = 0.6 z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + 1 ) y = ( <y> + <h> - 2 ) w = 1 h = 1 rgba = <rgba> a = 0.6 z = <z>
    dadmod_mouse_px parent = <parent> x = ( <x> + <w> - 2 ) y = ( <y> + <h> - 2 ) w = 1 h = 1 rgba = <rgba> a = 0.6 z = <z>
endscript
script dadmod_mouse_arrow_build bid = dadmod_mouse_sl x = 0.0 y = 0.0 mm_hl = 0 dir = 0 phl = 0
    if ScreenElementExists id = <bid>
        DestroyScreenElement id = <bid>
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = <bid>
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    just = [ left top ]
    z_priority = 8990
    }
    dadmod_mouse_px parent = <bid> x = 0 y = 0 w = 56 h = 56 rgba = [ 0 0 0 0 ] z = 8991
    mm_s0 = 1.0
    if (<phl> = 1)
        mm_s0 = 1.1
    endif
    dadmod_mouse_box parent = <bid> lid = arr_c x = 28.0 y = 28.0 sc = <mm_s0>
    mm_col = [ 128 128 128 128 ]
    if (<mm_hl> = 1)
        mm_col = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    endif
    dadmod_mouse_tri parent = { <bid> child = arr_c } x = -8 y = 0 n = 16 dir = <dir> rgba = <mm_col> z = 8993
    mm_dx = -4.0
    if (<dir> = 1)
        mm_dx = 4.0
    endif
    if (<mm_hl> = 1)
        DoScreenElementMorph id = { <bid> child = arr_c } scale = 1.1 time = 0.12
        SpawnScript dadmod_mouse_nudge params = { id = { <bid> child = arr_c } x = 28.0 y = 28.0 dx = <mm_dx> }
    else
        if (<phl> = 1)
            DoScreenElementMorph id = { <bid> child = arr_c } scale = 1.0 time = 0.12
        endif
    endif
endscript
script dadmod_mouse_ss_arrows
    mm_size = ( 56.0 * ( dadmod_mouse_pxu ) )
    mm_sizey = ( 56.0 * ( dadmod_mouse_pyu ) )
    mm_ly = ( 205.0 - ( <mm_sizey> / 2.0 ) )
    mm_lx = ( 74.0 - <mm_size> )
    mm_rx = 230.0
    mm_l = 0
    mm_r = 0
    if ScreenElementExists id = { dadmod_mouse_sl child = 0 }
        if THUGRECOMP_MouseOver id = { dadmod_mouse_sl child = 0 } x = <x> y = <y> pad = 0.0
            mm_l = 1
        endif
    endif
    if ScreenElementExists id = { dadmod_mouse_sr child = 0 }
        if THUGRECOMP_MouseOver id = { dadmod_mouse_sr child = 0 } x = <x> y = <y> pad = 0.0
            mm_r = 1
        endif
    endif
    if not ScreenElementExists id = dadmod_mouse_sl
        Change dadmod_mouse_sl_hl = -1
    endif
    if not ScreenElementExists id = dadmod_mouse_sr
        Change dadmod_mouse_sr_hl = -1
    endif
    if not (<mm_l> = ( dadmod_mouse_sl_hl ))
        FormatText TextName = mm_msg "mouse: skater arrows hover left %a right %b" a = <mm_l> b = <mm_r>
        THUGRECOMP_Log text = <mm_msg>
        mm_p = 0
        if (( dadmod_mouse_sl_hl ) = 1)
            mm_p = 1
        endif
        if (<mm_l> = 1)
            generic_menu_up_or_down_sound
        endif
        Change dadmod_mouse_sl_hl = <mm_l>
        dadmod_mouse_arrow_build bid = dadmod_mouse_sl x = <mm_lx> y = <mm_ly> mm_hl = <mm_l> dir = 0 phl = <mm_p>
    endif
    if not (<mm_r> = ( dadmod_mouse_sr_hl ))
        mm_p = 0
        if (( dadmod_mouse_sr_hl ) = 1)
            mm_p = 1
        endif
        if (<mm_r> = 1)
            generic_menu_up_or_down_sound
        endif
        Change dadmod_mouse_sr_hl = <mm_r>
        dadmod_mouse_arrow_build bid = dadmod_mouse_sr x = <mm_rx> y = <mm_ly> mm_hl = <mm_r> dir = 1 phl = <mm_p>
    endif
    return mm_side_l = <mm_l> mm_side_r = <mm_r>
endscript
dadmod_mouse_sel_hl = -1
dadmod_mouse_load_hl = -1
script dadmod_mouse_txt parent = dadmod_mouse_ssb x = 0 y = 0 text = "" font = crillee scale = 0.2 rgba = [ 128 128 128 128 ] z = 8995 lid = dadmod_t
    CreateScreenElement {
    type = TextElement
    parent = <parent>
    local_id = <lid>
    font = <font>
    text = <text>
    just = [ left center ]
    pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) )
    scale = <scale>
    rgba = <rgba>
    z_priority = <z>
    }
endscript
script dadmod_mouse_box parent = dadmod_mouse_ssb lid = sel_box x = 0.0 y = 0.0 sc = 1.0
    CreateScreenElement {
    type = ContainerElement
    parent = <parent>
    local_id = <lid>
    pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) )
    just = [ left top ]
    scale = <sc>
    }
endscript
script dadmod_mouse_measure parent = dadmod_mouse_ssb text = "" scale = 0.2
    dadmod_mouse_txt parent = <parent> lid = dadmod_measure text = <text> font = crillee scale = <scale> rgba = [ 0 0 0 0 ]
    mm_w = 100.0
    if ScreenElementExists id = { <parent> child = dadmod_measure }
        GetScreenElementDims id = { <parent> child = dadmod_measure }
        mm_w = ( <width> / ( dadmod_mouse_pxu ) )
        DestroyScreenElement id = { <parent> child = dadmod_measure }
    endif
    return mm_w = <mm_w>
endscript
script dadmod_mouse_ss_build bid = dadmod_mouse_ssb x = 0.0 y = 0.0 sel = 0 load = 0 psel = 0 pload = 0
    if ScreenElementExists id = <bid>
        DestroyScreenElement id = <bid>
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = <bid>
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    just = [ left top ]
    z_priority = 8990
    }
    dadmod_mouse_measure parent = <bid> text = "SELECT SKATER" scale = 0.2
    mm_selw = ( <mm_w> + 76.0 )
    dadmod_mouse_measure parent = <bid> text = "LOAD SKATER" scale = 0.125
    mm_loadw = ( <mm_w> + 30.0 )
    Change dadmod_mouse_selw = <mm_selw>
    Change dadmod_mouse_loadw = <mm_loadw>
    mm_line = [ 128 128 128 128 ]
    mm_seltxt = ( ( THUGPRO_GlobalThemeInfo ) . MENU_TITLE_COLOR )
    mm_selfill = [ 0 0 0 128 ]
    mm_selfa = 0.78
    if (<sel> = 1)
        mm_line = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_seltxt = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_selfill = [ 60 60 60 128 ]
        mm_selfa = 0.88
    endif
    mm_gray = [ 90 90 90 100 ]
    mm_loadtxt = ( ( THUGPRO_GlobalThemeInfo ) . UNHIGHLIGHTED_TEXT_COLOR )
    mm_loadfill = [ 0 0 0 128 ]
    mm_loadfa = 0.6
    if (<load> = 1)
        mm_gray = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_loadtxt = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_loadfill = [ 50 50 50 128 ]
        mm_loadfa = 0.8
    endif
    mm_scx = ( 78.0 + ( <mm_selw> / 2.0 ) )
    mm_s0 = 1.0
    if (<psel> = 1)
        mm_s0 = 1.04
    endif
    dadmod_mouse_box parent = <bid> lid = sel_box x = <mm_scx> y = 198.0 sc = <mm_s0>
    mm_sb = { <bid> child = sel_box }
    mm_hx = ( 0.0 - ( <mm_selw> / 2.0 ) )
    dadmod_mouse_frame parent = <mm_sb> lid = sel_bg x = <mm_hx> y = -32 w = <mm_selw> h = 64 th = 2 rgba = <mm_line> fill = <mm_selfill> fa = <mm_selfa> z = 8992
    dadmod_mouse_px parent = <mm_sb> x = ( <mm_hx> + 10 ) y = -22 w = 6 h = 44 rgba = ( ( THUGPRO_GlobalThemeInfo ) . MENU_TITLE_COLOR ) z = 8993
    dadmod_mouse_txt parent = <mm_sb> lid = sel_text x = ( <mm_hx> + 28 ) y = 0 text = "SELECT SKATER" font = crillee scale = 0.2 rgba = <mm_seltxt> z = 8995
    mm_chx = ( ( <mm_selw> / 2.0 ) - 30.0 )
    dadmod_mouse_box parent = <mm_sb> lid = sel_chev x = <mm_chx> y = 0.0
    if (<sel> = 1)
        dadmod_mouse_tri parent = { <bid> child = { sel_box child = sel_chev } } x = 2 y = 0 n = 11 dir = 1 rgba = <mm_line> z = 8996 sh = 0
    else
        dadmod_mouse_tri parent = { <bid> child = { sel_box child = sel_chev } } x = 0 y = 0 n = 9 dir = 1 rgba = <mm_line> z = 8996 sh = 0
    endif
    mm_lcx = ( 78.0 + ( <mm_loadw> / 2.0 ) )
    mm_l0 = 1.0
    if (<pload> = 1)
        mm_l0 = 1.04
    endif
    dadmod_mouse_box parent = <bid> lid = load_box x = <mm_lcx> y = 259.0 sc = <mm_l0>
    mm_lb = { <bid> child = load_box }
    mm_lhx = ( 0.0 - ( <mm_loadw> / 2.0 ) )
    dadmod_mouse_frame parent = <mm_lb> lid = load_bg x = <mm_lhx> y = -17 w = <mm_loadw> h = 34 th = 1 rgba = <mm_gray> fill = <mm_loadfill> fa = <mm_loadfa> z = 8992
    dadmod_mouse_txt parent = <mm_lb> lid = load_text x = ( <mm_lhx> + 14 ) y = 0 text = "LOAD SKATER" font = crillee scale = 0.125 rgba = <mm_loadtxt> z = 8995
    if (<sel> = 1)
        DoScreenElementMorph id = <mm_sb> scale = 1.04 time = 0.12
        SpawnScript dadmod_mouse_pulse params = { id = <mm_sb> }
        SpawnScript dadmod_mouse_nudge params = { id = { <bid> child = { sel_box child = sel_chev } } x = <mm_chx> dx = 4.0 }
    else
        if (<psel> = 1)
            DoScreenElementMorph id = <mm_sb> scale = 1.0 time = 0.12
        endif
    endif
    if (<load> = 1)
        DoScreenElementMorph id = <mm_lb> scale = 1.04 time = 0.12
        SpawnScript dadmod_mouse_pulse params = { id = <mm_lb> }
    else
        if (<pload> = 1)
            DoScreenElementMorph id = <mm_lb> scale = 1.0 time = 0.12
        endif
    endif
endscript
script dadmod_mouse_pulse
    wait 0.15 seconds
    begin
        if not ScreenElementExists id = <id>
            return
        endif
        DoScreenElementMorph id = <id> alpha = 0.8 time = 0.5
        wait 0.5 seconds
        if not ScreenElementExists id = <id>
            return
        endif
        DoScreenElementMorph id = <id> alpha = 1.0 time = 0.5
        wait 0.5 seconds
    repeat
endscript
script dadmod_mouse_nudge x = 0.0 y = 0.0 dx = 4.0
    begin
        if not ScreenElementExists id = <id>
            return
        endif
        DoScreenElementMorph id = <id> pos = ( (1.0,0.0) * ( ( <x> + <dx> ) * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) ) time = 0.3
        wait 0.3 seconds
        if not ScreenElementExists id = <id>
            return
        endif
        DoScreenElementMorph id = <id> pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) ) time = 0.3
        wait 0.3 seconds
    repeat
endscript
script dadmod_mouse_press scale = 1.04
    if not ScreenElementExists id = <id>
        return
    endif
    DoScreenElementMorph id = <id> scale = 0.94 time = 0.06
    if GotParam flash
        if ScreenElementExists id = <flash>
            DoScreenElementMorph id = <flash> rgba = [ 128 128 128 128 ] time = 0
            DoScreenElementMorph id = <flash> rgba = <fill> time = 0.15
        endif
    endif
    wait 0.06 seconds
    if ScreenElementExists id = <id>
        DoScreenElementMorph id = <id> scale = <scale> time = 0.09
    endif
endscript
script dadmod_mouse_kick x = 0.0 y = 0.0 dx = 8.0
    if not ScreenElementExists id = <id>
        return
    endif
    DoScreenElementMorph id = <id> pos = ( (1.0,0.0) * ( ( <x> + <dx> ) * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) ) time = 0.06
    wait 0.06 seconds
    if ScreenElementExists id = <id>
        DoScreenElementMorph id = <id> pos = ( (1.0,0.0) * ( <x> * ( dadmod_mouse_pxu ) ) + (0.0,1.0) * ( <y> * ( dadmod_mouse_pyu ) ) ) time = 0.12
    endif
endscript
dadmod_mouse_selw = 300.0
dadmod_mouse_loadw = 150.0
script dadmod_mouse_ss_buttons x = 0.0 y = 0.0 cx = 0.0 cy = 0.0
    mm_px = ( ( <x> - <cx> ) / ( dadmod_mouse_pxu ) )
    mm_py = ( ( <y> - <cy> ) / ( dadmod_mouse_pyu ) )
    mm_sel = 0
    mm_load = 0
    if (<mm_px> > 77.0)
        if (<mm_px> < ( 78.0 + ( dadmod_mouse_selw ) ))
            if (<mm_py> > 165.0)
                if (<mm_py> < 230.0)
                    mm_sel = 1
                endif
            endif
        endif
        if (<mm_px> < ( 78.0 + ( dadmod_mouse_loadw ) ))
            if (<mm_py> > 241.0)
                if (<mm_py> < 276.0)
                    mm_load = 1
                endif
            endif
        endif
    endif
    if not ScreenElementExists id = dadmod_mouse_ssb
        Change dadmod_mouse_sel_hl = -1
    endif
    mm_redo = 0
    if not (<mm_sel> = ( dadmod_mouse_sel_hl ))
        mm_redo = 1
    endif
    if not (<mm_load> = ( dadmod_mouse_load_hl ))
        mm_redo = 1
    endif
    if (<mm_redo> = 1)
        FormatText TextName = mm_msg "mouse: skater select hover sel %a load %b (pointer px %c,%d, select width %e)" a = <mm_sel> b = <mm_load> c = <mm_px> d = <mm_py> e = ( dadmod_mouse_selw )
        THUGRECOMP_Log text = <mm_msg>
        mm_psel = 0
        if (( dadmod_mouse_sel_hl ) = 1)
            mm_psel = 1
        endif
        mm_pload = 0
        if (( dadmod_mouse_load_hl ) = 1)
            mm_pload = 1
        endif
        if ( (<mm_sel> = 1) or (<mm_load> = 1) )
            if ( (<mm_psel> = 0) and (<mm_pload> = 0) )
                generic_menu_up_or_down_sound
            endif
        endif
        Change dadmod_mouse_sel_hl = <mm_sel>
        Change dadmod_mouse_load_hl = <mm_load>
        dadmod_mouse_ss_build x = <cx> y = <cy> sel = <mm_sel> load = <mm_load> psel = <mm_psel> pload = <mm_pload>
    endif
    return mm_over_sel = <mm_sel> mm_over_load = <mm_load>
endscript
dadmod_skin_state = -1
script dadmod_mouse_skin_off
    if ScreenElementExists id = dadmod_mouse_skin
        DestroyScreenElement id = dadmod_mouse_skin
    endif
    Change dadmod_skin_state = -1
endscript
script dadmod_mouse_skin_pill x = 0.0 y = 0.0
    mm_item = ( LAST_SELECTED_SKATER_MENU_ID )
    mm_n = 0
    mm_i = 0
    if ScreenElementExists id = <mm_item>
        if <mm_item> : GetSingleTag number_of_skins
            mm_n = <number_of_skins>
        endif
        if <mm_item> : GetSingleTag selected_skin_index
            mm_i = <selected_skin_index>
        endif
    endif
    if (<mm_n> < 2)
        dadmod_mouse_skin_off
        return mm_skin_l = 0 mm_skin_r = 0
    endif
    mm_cx = 156.0
    mm_cy = 382.0
    mm_px = ( ( <x> - <mm_cx> ) / ( dadmod_mouse_pxu ) )
    mm_py = ( ( <y> - <mm_cy> ) / ( dadmod_mouse_pyu ) )
    mm_l = 0
    mm_r = 0
    if (<mm_py> > -18.0)
        if (<mm_py> < 18.0)
            if (<mm_px> > -115.0)
                if (<mm_px> < -55.0)
                    mm_l = 1
                endif
            endif
            if (<mm_px> > 55.0)
                if (<mm_px> < 115.0)
                    mm_r = 1
                endif
            endif
        endif
    endif
    mm_state = ( ( <mm_n> * 10000 ) + ( <mm_i> * 10 ) + <mm_l> + ( 2 * <mm_r> ) )
    if not ScreenElementExists id = dadmod_mouse_skin
        Change dadmod_skin_state = -1
    endif
    if not (<mm_state> = ( dadmod_skin_state ))
        Change dadmod_skin_state = <mm_state>
        dadmod_mouse_skin_build cx = <mm_cx> cy = <mm_cy> n = <mm_n> i = <mm_i> l = <mm_l> r = <mm_r>
    endif
    return mm_skin_l = <mm_l> mm_skin_r = <mm_r> mm_skin_item = <mm_item>
endscript
script dadmod_mouse_skin_build cx = 0.0 cy = 0.0 n = 1 i = 0 l = 0 r = 0
    if ScreenElementExists id = dadmod_mouse_skin
        DestroyScreenElement id = dadmod_mouse_skin
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_mouse_skin
    pos = ( (1.0,0.0) * <cx> + (0.0,1.0) * <cy> )
    just = [ left top ]
    z_priority = 8990
    }
    dadmod_mouse_px parent = dadmod_mouse_skin x = -98.2 y = -15.0 w = 202.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.2 y = -14.0 w = 208.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -103.2 y = -13.0 w = 212.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.7 y = -12.0 w = 215.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -105.9 y = -11.0 w = 217.8 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.0 y = -10.0 w = 219.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.8 y = -9.0 w = 221.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.6 y = -8.0 w = 223.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.3 y = -7.0 w = 224.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.9 y = -6.0 w = 225.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.4 y = -5.0 w = 226.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.8 y = -4.0 w = 227.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.1 y = -3.0 w = 228.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.4 y = -2.0 w = 228.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.7 y = -1.0 w = 229.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.8 y = 0.0 w = 229.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.9 y = 1.0 w = 229.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.0 y = 2.0 w = 230.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.0 y = 3.0 w = 230.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.9 y = 4.0 w = 229.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.8 y = 5.0 w = 229.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.7 y = 6.0 w = 229.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.4 y = 7.0 w = 228.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.1 y = 8.0 w = 228.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.8 y = 9.0 w = 227.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.4 y = 10.0 w = 226.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.9 y = 11.0 w = 225.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.3 y = 12.0 w = 224.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.6 y = 13.0 w = 223.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.8 y = 14.0 w = 221.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.0 y = 15.0 w = 219.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -105.9 y = 16.0 w = 217.8 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.7 y = 17.0 w = 215.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -103.2 y = 18.0 w = 212.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.2 y = 19.0 w = 208.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -98.2 y = 20.0 w = 202.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.30 z = 8991
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.2 y = -18.0 w = 202.4 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.2 y = -17.0 w = 208.4 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -106.2 y = -16.0 w = 212.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.7 y = -15.0 w = 215.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.9 y = -14.0 w = 217.8 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.0 y = -13.0 w = 219.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.8 y = -12.0 w = 221.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.6 y = -11.0 w = 223.2 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.3 y = -10.0 w = 224.6 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.9 y = -9.0 w = 225.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.4 y = -8.0 w = 226.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.8 y = -7.0 w = 227.6 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.1 y = -6.0 w = 228.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.4 y = -5.0 w = 228.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.7 y = -4.0 w = 229.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.8 y = -3.0 w = 229.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.9 y = -2.0 w = 229.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -115.0 y = -1.0 w = 230.0 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -115.0 y = 0.0 w = 230.0 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.9 y = 1.0 w = 229.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.8 y = 2.0 w = 229.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.7 y = 3.0 w = 229.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.4 y = 4.0 w = 228.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.1 y = 5.0 w = 228.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.8 y = 6.0 w = 227.6 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.4 y = 7.0 w = 226.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.9 y = 8.0 w = 225.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.3 y = 9.0 w = 224.6 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.6 y = 10.0 w = 223.2 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.8 y = 11.0 w = 221.7 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.0 y = 12.0 w = 219.9 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.9 y = 13.0 w = 217.8 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.7 y = 14.0 w = 215.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -106.2 y = 15.0 w = 212.3 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.2 y = 16.0 w = 208.4 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.2 y = 17.0 w = 202.4 h = 1 rgba = [ 100 100 100 128 ] a = 1.00 z = 8992
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.1 y = -17.0 w = 202.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.0 y = -16.0 w = 208.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -105.9 y = -15.0 w = 211.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.3 y = -14.0 w = 214.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.5 y = -13.0 w = 217.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.5 y = -12.0 w = 219.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.4 y = -11.0 w = 220.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.1 y = -10.0 w = 222.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.7 y = -9.0 w = 223.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.3 y = -8.0 w = 224.5 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.7 y = -7.0 w = 225.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.1 y = -6.0 w = 226.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.4 y = -5.0 w = 226.8 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.6 y = -4.0 w = 227.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.8 y = -3.0 w = 227.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.9 y = -2.0 w = 227.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.0 y = -1.0 w = 228.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -114.0 y = 0.0 w = 228.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.9 y = 1.0 w = 227.9 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.8 y = 2.0 w = 227.6 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.6 y = 3.0 w = 227.3 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.4 y = 4.0 w = 226.8 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -113.1 y = 5.0 w = 226.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.7 y = 6.0 w = 225.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -112.3 y = 7.0 w = 224.5 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.7 y = 8.0 w = 223.4 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -111.1 y = 9.0 w = 222.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -110.4 y = 10.0 w = 220.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -109.5 y = 11.0 w = 219.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -108.5 y = 12.0 w = 217.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -107.3 y = 13.0 w = 214.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -105.9 y = 14.0 w = 211.7 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -104.0 y = 15.0 w = 208.0 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    dadmod_mouse_px parent = dadmod_mouse_skin x = -101.1 y = 16.0 w = 202.2 h = 1 rgba = [ 0 0 0 128 ] a = 0.75 z = 8993
    FormatText TextName = mm_label "SKIN  %a / %b" a = ( <i> + 1 ) b = <n>
    dadmod_mouse_measure parent = dadmod_mouse_skin text = <mm_label> scale = 0.13
    mm_tx = ( 0.0 - ( <mm_w> / 2.0 ) )
    dadmod_mouse_txt parent = dadmod_mouse_skin lid = skin_text x = <mm_tx> y = 0 text = <mm_label> font = crillee scale = 0.13 rgba = [ 100 100 100 128 ] z = 8995
    mm_lc = [ 128 128 128 128 ]
    if (<l> = 1)
        mm_lc = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    endif
    mm_rc = [ 128 128 128 128 ]
    if (<r> = 1)
        mm_rc = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    endif
    dadmod_mouse_box parent = dadmod_mouse_skin lid = skin_l x = -94.0 y = 0.0
    dadmod_mouse_box parent = dadmod_mouse_skin lid = skin_r x = 94.0 y = 0.0
    if (<l> = 1)
        dadmod_mouse_tri parent = { dadmod_mouse_skin child = skin_l } x = -5 y = 0 n = 10 dir = 0 rgba = <mm_lc> z = 8996 sh = 0
        SpawnScript dadmod_mouse_nudge params = { id = { dadmod_mouse_skin child = skin_l } x = -94.0 y = 0.0 dx = -3.0 }
    else
        dadmod_mouse_tri parent = { dadmod_mouse_skin child = skin_l } x = -4 y = 0 n = 8 dir = 0 rgba = <mm_lc> z = 8996 sh = 0
    endif
    if (<r> = 1)
        dadmod_mouse_tri parent = { dadmod_mouse_skin child = skin_r } x = -5 y = 0 n = 10 dir = 1 rgba = <mm_rc> z = 8996 sh = 0
        SpawnScript dadmod_mouse_nudge params = { id = { dadmod_mouse_skin child = skin_r } x = 94.0 y = 0.0 dx = 3.0 }
    else
        dadmod_mouse_tri parent = { dadmod_mouse_skin child = skin_r } x = -4 y = 0 n = 8 dir = 1 rgba = <mm_rc> z = 8996 sh = 0
    endif
endscript
script dadmod_mouse_ss_off
    dadmod_mouse_skin_off
    if ScreenElementExists id = dadmod_mouse_ssb
        DestroyScreenElement id = dadmod_mouse_ssb
    endif
    Change dadmod_mouse_sel_hl = -1
    Change dadmod_mouse_load_hl = -1
    if ScreenElementExists id = dadmod_mouse_sl
        DestroyScreenElement id = dadmod_mouse_sl
    endif
    if ScreenElementExists id = dadmod_mouse_sr
        DestroyScreenElement id = dadmod_mouse_sr
    endif
    Change dadmod_mouse_sl_hl = -1
    Change dadmod_mouse_sr_hl = -1
endscript
script dadmod_mouse_back_button x = 0.0 y = 0.0 mm_hl = 0
    if ScreenElementExists id = dadmod_mouse_back
        if (<mm_hl> = ( dadmod_mouse_back_hl ))
            return
        endif
        DestroyScreenElement id = dadmod_mouse_back
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    Change dadmod_mouse_back_hl = <mm_hl>
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_mouse_back
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    just = [ left top ]
    z_priority = 8990
    }
    mm_line = [ 128 128 128 128 ]
    mm_fill = [ 0 0 0 83 ]
    if (<mm_hl> = 1)
        mm_line = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_fill = [ 12 24 56 90 ]
    endif
    dadmod_mouse_px parent = dadmod_mouse_back x = 0 y = 0 w = 34 h = 34 rgba = <mm_fill> z = 8991
    dadmod_mouse_px parent = dadmod_mouse_back x = 0 y = 0 w = 34 h = 2 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_back x = 0 y = 32 w = 34 h = 2 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_back x = 0 y = 2 w = 2 h = 30 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_back x = 32 y = 2 w = 2 h = 30 rgba = <mm_line> z = 8992
    mm_col = 0
    begin
        dadmod_mouse_px parent = dadmod_mouse_back x = ( 8 + <mm_col> ) y = ( 16 - <mm_col> ) w = 1 h = ( 2 + ( 2 * <mm_col> ) ) rgba = <mm_line> z = 8993
        mm_col = ( <mm_col> + 1 )
    repeat 8
    dadmod_mouse_px parent = dadmod_mouse_back x = 16 y = 15 w = 10 h = 4 rgba = <mm_line> z = 8993
endscript
script dadmod_mouse_next_button x = 0.0 y = 0.0 mm_hl = 0
    if ScreenElementExists id = dadmod_mouse_next
        if (<mm_hl> = ( dadmod_mouse_next_hl ))
            return
        endif
        DestroyScreenElement id = dadmod_mouse_next
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    Change dadmod_mouse_next_hl = <mm_hl>
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_mouse_next
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    just = [ left top ]
    z_priority = 8990
    }
    mm_line = [ 128 128 128 128 ]
    mm_fill = [ 0 0 0 83 ]
    if (<mm_hl> = 1)
        mm_line = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        mm_fill = [ 12 24 56 90 ]
    endif
    dadmod_mouse_px parent = dadmod_mouse_next x = 0 y = 0 w = 34 h = 34 rgba = <mm_fill> z = 8991
    dadmod_mouse_px parent = dadmod_mouse_next x = 0 y = 0 w = 34 h = 2 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_next x = 0 y = 32 w = 34 h = 2 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_next x = 0 y = 2 w = 2 h = 30 rgba = <mm_line> z = 8992
    dadmod_mouse_px parent = dadmod_mouse_next x = 32 y = 2 w = 2 h = 30 rgba = <mm_line> z = 8992
    mm_col = 0
    begin
        dadmod_mouse_px parent = dadmod_mouse_next x = ( 25 - <mm_col> ) y = ( 16 - <mm_col> ) w = 1 h = ( 2 + ( 2 * <mm_col> ) ) rgba = <mm_line> z = 8993
        mm_col = ( <mm_col> + 1 )
    repeat 8
    dadmod_mouse_px parent = dadmod_mouse_next x = 8 y = 15 w = 10 h = 4 rgba = <mm_line> z = 8993
endscript
script dadmod_kb_click_anim
    if not ScreenElementExists id = <id>
        return
    endif
    mm_org = (1.0,1.6)
    if <id> : GetSingleTag tag_txt_offset
        mm_org = (1.0,1.05)
    endif
    DoScreenElementMorph id = <id> time = 0.05 scale = ( <mm_org> * 1.15 )
    wait 0.06 seconds
    if ScreenElementExists id = <id>
        DoScreenElementMorph id = <id> time = 0.06 scale = ( <mm_org> * 0.95 )
    endif
    wait 0.06 seconds
    if ScreenElementExists id = <id>
        DoScreenElementMorph id = <id> time = 0.08 scale = ( <mm_org> * 1.05 )
    endif
endscript
script dadmod_fit_extra
    if not ScreenElementExists id = <id>
        return
    endif
    if not ScreenElementExists id = { <id> child = extra_text }
        return
    endif
    mm_base = 0.0
    if <id> : GetSingleTag dadmod_xbase
        mm_base = <dadmod_xbase>
    endif
    if THUGRECOMP_FitText row = <id> text = { <id> child = extra_text } left = { <id> child = left_arrow } right = { <id> child = right_arrow } base = <mm_base> min = 0.6
        if (<mm_base> = 0.0)
            <id> : SetTags dadmod_xbase = <ms_base>
        endif
        DoScreenElementMorph id = { <id> child = extra_text } scale = <ms_fit> time = 0
    endif
endscript
script dadmod_fit_all
    wait 2 gameframes
    if not ScreenElementExists id = current_menu
        return
    endif
    if GetScreenElementChildren id = current_menu
        GetArraySize <children>
        mm_k = 0
        begin
            dadmod_fit_extra id = ( <children> [ <mm_k> ] )
            mm_k = ( <mm_k> + 1 )
        repeat <array_size>
    endif
endscript
script dadmod_mouse_is_scroll_list
    if not ScreenElementExists id = <id>
        return mm_scroll_list = 0
    endif
    mm_show = 0
    mm_count = 0
    if <id> : GetSingleTag num_items_to_show
        mm_show = <num_items_to_show>
    endif
    if <id> : GetSingleTag menu_item_count
        mm_count = <menu_item_count>
    endif
    if (<mm_show> > 0)
        if (<mm_count> > <mm_show>)
            return mm_scroll_list = 1
        endif
    endif
    return mm_scroll_list = 0
endscript
dadmod_lvl_state = -1
script dadmod_mouse_lvl_off
    if ScreenElementExists id = dadmod_mouse_ll
        DestroyScreenElement id = dadmod_mouse_ll
    endif
    if ScreenElementExists id = dadmod_mouse_lr
        DestroyScreenElement id = dadmod_mouse_lr
    endif
    Change dadmod_lvl_state = -1
endscript
script dadmod_mouse_lvl_arrows x = 0.0 y = 0.0 bx0 = 0.0 by0 = 0.0 bx1 = 0.0 by1 = 0.0 cx = 0.0 rx = 640.0
    mm_sz = ( 56.0 * ( dadmod_mouse_pxu ) )
    mm_szy = ( 56.0 * ( dadmod_mouse_pyu ) )
    mm_gap = ( 12.0 * ( dadmod_mouse_pxu ) )
    mm_lx = ( <bx0> - <mm_gap> - <mm_sz> )
    if (<mm_lx> < <cx>)
        mm_lx = <cx>
    endif
    mm_rxx = ( <bx1> + <mm_gap> )
    if (( <mm_rxx> + <mm_sz> ) > <rx>)
        mm_rxx = ( <rx> - <mm_sz> )
    endif
    mm_ly = ( ( ( <by0> + <by1> ) / 2.0 ) - ( <mm_szy> / 2.0 ) )
    mm_l = 0
    mm_r = 0
    if (<y> > <mm_ly>)
        if (<y> < ( <mm_ly> + <mm_szy> ))
            if (<x> > <mm_lx>)
                if (<x> < ( <mm_lx> + <mm_sz> ))
                    mm_l = 1
                endif
            endif
            if (<x> > <mm_rxx>)
                if (<x> < ( <mm_rxx> + <mm_sz> ))
                    mm_r = 1
                endif
            endif
        endif
    endif
    mm_state = ( ( <mm_lx> * 1000.0 ) + ( <mm_ly> * 10.0 ) + ( <mm_rxx> * 0.001 ) + <mm_l> + ( 2 * <mm_r> ) )
    if not ScreenElementExists id = dadmod_mouse_ll
        Change dadmod_lvl_state = -1
    endif
    if not (<mm_state> = ( dadmod_lvl_state ))
        Change dadmod_lvl_state = <mm_state>
        dadmod_mouse_arrow_build bid = dadmod_mouse_ll x = <mm_lx> y = <mm_ly> mm_hl = <mm_l> dir = 0
        dadmod_mouse_arrow_build bid = dadmod_mouse_lr x = <mm_rxx> y = <mm_ly> mm_hl = <mm_r> dir = 1
    endif
    return mm_lv_l = <mm_l> mm_lv_r = <mm_r>
endscript
dadmod_hbar_state = -1.0
script dadmod_mouse_hover_bar_off
    if ScreenElementExists id = dadmod_mouse_hbar
        DestroyScreenElement id = dadmod_mouse_hbar
    endif
    Change dadmod_hbar_state = -1.0
endscript
script dadmod_mouse_hover_bar x0 = 0.0 y0 = 0.0 x1 = 0.0 y1 = 0.0
    mm_state = ( ( <x0> * 1000.0 ) + ( <y0> * 10.0 ) + ( <x1> * 0.01 ) + ( <y1> * 0.0001 ) )
    if ScreenElementExists id = dadmod_mouse_hbar
        if (<mm_state> = ( dadmod_hbar_state ))
            return
        endif
        DestroyScreenElement id = dadmod_mouse_hbar
    endif
    if not ScreenElementExists id = root_window
        return
    endif
    Change dadmod_hbar_state = <mm_state>
    mm_w = ( <x1> - <x0> )
    mm_h = ( <y1> - <y0> )
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_mouse_hbar
    pos = ( (1.0,0.0) * <x0> + (0.0,1.0) * <y0> )
    just = [ left top ]
    z_priority = 1001
    }
    mm_col = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    CreateScreenElement {
    type = SpriteElement
    parent = dadmod_mouse_hbar
    texture = white
    just = [ left top ]
    pos = (0.0,0.0)
    scale = ( (1.0,0.0) * ( <mm_w> / 4.0 ) + (0.0,1.0) * ( <mm_h> / 4.0 ) )
    rgba = <mm_col>
    alpha = 0.22
    z_priority = 1001
    }
    CreateScreenElement {
    type = SpriteElement
    parent = dadmod_mouse_hbar
    texture = white
    just = [ left top ]
    pos = (0.0,0.0)
    scale = ( (1.0,0.0) * ( 3.0 * ( dadmod_mouse_pxu ) / 4.0 ) + (0.0,1.0) * ( <mm_h> / 4.0 ) )
    rgba = <mm_col>
    alpha = 0.9
    z_priority = 1001
    }
endscript
dadmod_walkcam_opt = 1
dadmod_walkcam_n = 0
script dadmod_walkcam_tick
    Change dadmod_walkcam_n = ( ( dadmod_walkcam_n ) + 1 )
    if (( dadmod_walkcam_n ) > 15)
        Change dadmod_walkcam_n = 0
        wc_opt = 1
        if THUGRECOMP_SettingLoad key = "mouse_camera"
            wc_opt = <value>
        endif
        Change dadmod_walkcam_opt = <wc_opt>
    endif
    wc_on = 0
    wc_quit = 1
    if not LevelIs Load_MainMenu
        if ObjectExists id = skater
            if ObjectExists id = skatercam0
                wc_quit = 0
                if (( dadmod_walkcam_opt ) = 1)
                    if Skater : Walking
                        wc_on = 1
                    endif
                endif
            endif
        endif
    endif
    if (<wc_on> = 1)
        if Skater : Driving
            wc_on = 0
        endif
        if IsTrue view_mode
            wc_on = 0
        endif
        if IsObserving
            wc_on = 0
        endif
        if ScreenElementExists id = current_menu_anchor
            wc_on = 0
        endif
        if ScreenElementExists id = current_menu
            wc_on = 0
        endif
        if ScreenElementExists id = dialog_box_anchor
            wc_on = 0
        endif
        if ScreenElementExists id = keyboard_anchor
            wc_on = 0
        endif
        if GetCurrentSkaterCamAnimName
            if GotParam CurrentSkaterCamAnimName
                wc_on = 0
            endif
        endif
    endif
    wc_nc = 0
    if ScreenElementExists id = root_window
        if root_window : GetSingleTag dadmod_noclip
            if (<dadmod_noclip> > 0)
                wc_nc = 1
            endif
        endif
        wc_nc_was = <wc_nc>
        if root_window : GetSingleTag dadmod_walkcam_nc
            wc_nc_was = <dadmod_walkcam_nc>
        endif
        if not (<wc_nc_was> = <wc_nc>)
            wc_on = 0
        endif
        root_window : SetTags dadmod_walkcam_nc = <wc_nc>
        root_window : SetTags dadmod_walkcam_ok = <wc_on>
    endif
    if (<wc_quit> = 1)
        THUGRECOMP_WalkCam quit = 1
    else
        Skater : Obj_GetPosition
        wc_sp = <Pos>
        Skater : Obj_GetOrientation
        wc_hx = <x>
        wc_hz = <z>
        if (<wc_nc> = 1)
            wc_hx = 0.0
            wc_hz = 1.0
        endif
        skatercam0 : Obj_GetPosition
        wc_cp = <Pos>
        skatercam0 : Obj_GetOrientation
        THUGRECOMP_WalkCam on = <wc_on> sx = ( <wc_sp> . (1.0,0.0,0.0) ) sy = ( <wc_sp> . (0.0,1.0,0.0) ) sz = ( <wc_sp> . (0.0,0.0,1.0) ) hx = <wc_hx> hz = <wc_hz> cpx = ( <wc_cp> . (1.0,0.0,0.0) ) cpy = ( <wc_cp> . (0.0,1.0,0.0) ) cpz = ( <wc_cp> . (0.0,0.0,1.0) ) cdx = <x> cdy = <y> cdz = <z>
    endif
    wc_live = 0
    if GotParam wc_state
        if (<wc_state> = 1)
            wc_live = 1
        endif
    endif
    if ScreenElementExists id = root_window
        root_window : SetTags dadmod_walkcam_live = <wc_live>
    endif
    if GotParam wc_state
        if (<wc_state> = 1)
            if not ObjectExists id = dadmod_orbit_cam
                CreateCompositeObject {
                Components = menucam_composite_structure
                params = { Name = dadmod_orbit_cam }
                }
            endif
            dadmod_orbit_cam : Obj_SetPosition position = <cam_pos>
            dadmod_orbit_cam : Obj_SetOrientation dir = <cam_dir>
            SetActiveCamera id = dadmod_orbit_cam
        endif
        if (<wc_state> = 2)
            restore_skater_camera
        endif
    endif
endscript
