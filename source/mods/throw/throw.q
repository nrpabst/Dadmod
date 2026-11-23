script thugpro_throw_parse
    switch <msg>
    case "!AMMO"
    case " !AMMO"
    case "!TOMATO"
    case " !TOMATO"
    case "!TOMATOES"
    case " !TOMATOES"
    case "!AMMO TOMATO"
    case " !AMMO TOMATO"
    case "!AMMO TOMATOES"
    case " !AMMO TOMATOES"
        return ammo = tomato label = "tomatoes"
    case "!APPLE"
    case " !APPLE"
    case "!APPLES"
    case " !APPLES"
    case "!AMMO APPLE"
    case " !AMMO APPLE"
    case "!AMMO APPLES"
    case " !AMMO APPLES"
        return ammo = apple label = "apples"
    case "!BEADS"
    case " !BEADS"
    case "!AMMO BEADS"
    case " !AMMO BEADS"
        return ammo = beads label = "beads"
    case "!SHRIMP"
    case " !SHRIMP"
    case "!AMMO SHRIMP"
    case " !AMMO SHRIMP"
        return ammo = shrimp label = "shrimp"
    case "!SMOKEBOMB"
    case " !SMOKEBOMB"
    case "!SMOKEBOMBS"
    case " !SMOKEBOMBS"
    case "!AMMO SMOKE"
    case " !AMMO SMOKE"
    case "!AMMO SMOKEBOMB"
    case " !AMMO SMOKEBOMB"
    case "!AMMO SMOKEBOMBS"
    case " !AMMO SMOKEBOMBS"
        return ammo = smokebomb label = "smoke bombs"
    case "!PAINTCAN"
    case " !PAINTCAN"
    case "!PAINTCANS"
    case " !PAINTCANS"
    case "!AMMO PAINT"
    case " !AMMO PAINT"
    case "!AMMO PAINTCAN"
    case " !AMMO PAINTCAN"
    case "!AMMO PAINTCANS"
    case " !AMMO PAINTCANS"
        return ammo = PaintCan label = "paint cans"
    endswitch
endscript
script thugpro_throw_chat
    thugpro_throw_parse msg = <msg>
    if not GotParam ammo
        thugpro_throw_parse2 msg = <msg>
    endif
    if not GotParam ammo
        return
    endif
    if not THUGRECOMP_IsLocalPlayerName name = <name>
        return handled = 1
    endif
    thugpro_throw_give who = <name> ammo = <ammo>
    if GotParam modonly
        FormatText TextName = text "You got 20 %l! the flip button (Square / X) throws. Without the mod they look like a COMBO O" l = <label>
    else
        FormatText TextName = text "You got 20 %l! Press the flip button (Square / X) to throw them at people" l = <label>
    endif
    SpawnScript thugpro_throw_confirm params = { name = <name> text = <text> } NotSessionSpecific = 1
    return handled = 1
endscript
script thugpro_throw_give
    p = { id = thugrecomp_throw_ammo text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = RunScriptOnObject id = skater give_skater_ammo params = { Type = <ammo> num = 20 } } }
    if THUGRECOMP_IsLocalPlayerName name = <who>
        if ObjectExists id = skater
            create_panel_block <p>
            dadmod_ammo_hud_start
        endif
    else
        THUGRECOMP_PlayerScript name = <who> run = create_panel_block params = <p> skaters_only
    endif
endscript
script thugpro_throw_confirm
    wait 1.5 seconds
    thugpro_say_to name = <name> text = <text>
endscript
script dadmod_throw_menu
    dialog_box_exit
    generic_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_throw
    scrolling
    num_items_to_show = 13
    menu_title = "throwables"
    menu_style = MENU_STYLE_LEFT
    pad_back_script = dadmod_menu
    helper_text = generic_helper_text
    show_description_panel
    show_gradient
    boxed
    }
    make_thugpro_menu_item {
    text = "Stop throwing"
    description_text = "Drop your ammo so Square goes back to normal"
    pad_choose_script = dadmod_throw_pick
    pad_choose_params = { dadmod_tstop }
    }
    make_thugpro_menu_item {
    text = "Everyone sees these"
    not_focusable
    }
    dadmod_throw_item t = "COMBO letter O" a = none d = "The COMBO O. \\b1 throws it, it works in any server and everyone sees it"
    dadmod_throw_item t = "Tomatoes" a = tomato d = "Story mode tomatoes. No tomato model in THUG Pro, so they look like a COMBO O"
    dadmod_throw_item t = "Apples" a = apple d = "Story mode apples. They look like a COMBO O, everyone sees it"
    dadmod_throw_item t = "Beads" a = beads d = "Story mode beads. They look like a COMBO O, everyone sees it"
    dadmod_throw_item t = "Shrimp" a = shrimp d = "Story mode shrimp. They look like a COMBO O, everyone sees it"
    dadmod_throw_item t = "Smoke bombs" a = smokebomb d = "Story mode smoke bombs. They look like a COMBO O, everyone sees it"
    dadmod_throw_item t = "Paint cans" a = PaintCan d = "Story mode paint cans. They look like a COMBO O, everyone sees it"
    make_thugpro_menu_item {
    text = "DadMod players see these"
    not_focusable
    }
    dadmod_throw_item t = "Cars" a = dadmod_throw_cars d = "Throw cars, a different one each time. DadMod players see the car, others see it when a dadmod player hosts"
    dadmod_throw_item t = "Random Animal" a = dadmod_throw_animals d = "Throw animals, a different one each time. Others see it when a dadmod player hosts"
    dadmod_throw_item t = "Random Pedestrian" a = dadmod_throw_peds d = "Throw people, a different one each time. Others see it when a dadmod player hosts"
    dadmod_throw_item t = "Random Junk" a = dadmod_throw_junk d = "Throw junk, a different thing each time. Others see it when a dadmod player hosts"
    dadmod_throw_item t = "Skateboard" a = dadmod_throw_board d = "Throw skateboards. DadMod players see the board, others see it when a dadmod player hosts"
    dadmod_throw_item t = "Bowling Ball" a = dadmod_throw_ball d = "Throw a heavy ball. DadMod players see it, others see it when a dadmod player hosts"
    dadmod_throw_item t = "Mystery Box" a = dadmod_throw_mystery d = "Every throw is a surprise: cars, animals, people, junk. Others see it when a dadmod player hosts"
    if THUGRECOMP_ThrowStockOn
        dadmod_tst = "Show to players without dadmod: On"
    else
        dadmod_tst = "Show to players without dadmod: Off"
    endif
    make_thugpro_menu_item {
    text = <dadmod_tst>
    description_text = "When you host: players without dadmod see the real thing thrown, not a COMBO O (or nothing)"
    pad_choose_script = dadmod_throw_stock_toggle
    }
    thugpro_menu_finalize
endscript
script dadmod_throw_item
    make_thugpro_menu_item {
    text = <t>
    description_text = <d>
    pad_choose_script = dadmod_throw_pick
    pad_choose_params = { a = <a> t = <t> }
    }
endscript
script dadmod_throw_pick
    exit_pause_menu
    KillSpawnedScript Name = dadmod_throw_go
    SpawnScript dadmod_throw_go params = { <...> } NotSessionSpecific = 1
endscript
script dadmod_throw_go
    wait 5 gameframes
    if not ObjectExists id = skater
        return
    endif
    if GotParam dadmod_tstop
        skater : SetAmmo 0
        create_panel_message id = dadmod_throw_msg text = "No more ammo: Square is back to normal" time = 2500
        dadmod_throw_msg_clear
        return
    endif
    dadmod_throw_random_go a = <a> t = <t>
    skater : SetAmmo 0
    skater : give_skater_ammo Type = <a> num = 99
    FormatText TextName = msg "%t: \\b1 throws them (99)" t = <t>
    create_panel_message id = dadmod_throw_msg text = <msg> time = 3000
    dadmod_ammo_hud_start
    dadmod_throw_msg_clear
endscript
script dadmod_throw_msg_clear
    wait 2.5 seconds
    if ScreenElementExists id = dadmod_throw_msg
        DestroyScreenElement id = dadmod_throw_msg
    endif
endscript
script dadmod_throw_label
    switch <ammo_type>
    case tomato
        return dadmod_tl = "Tomatoes"
    case apple
        return dadmod_tl = "Apples"
    case beads
        return dadmod_tl = "Beads"
    case shrimp
        return dadmod_tl = "Shrimp"
    case smokebomb
        return dadmod_tl = "Smoke bombs"
    case PaintCan
        return dadmod_tl = "Paint cans"
    endswitch
    if ObjectExists id = skater
        skater : GetTags
        if GotParam dadmod_throw_lbl
            return dadmod_tl = <dadmod_throw_lbl>
        endif
    endif
    if StructureContains structure = ( dadmod_throw_cat_label ) <ammo_type>
        return dadmod_tl = ( dadmod_throw_cat_label . <ammo_type> )
    endif
    return dadmod_tl = "COMBO O"
endscript
script dadmod_ammo_hud_start
    KillSpawnedScript Name = dadmod_ammo_hud_watch
    SpawnScript dadmod_ammo_hud_watch NotSessionSpecific = 1
endscript
script dadmod_ammo_hud_watch
    wait 10 gameframes
    begin
        if not ObjectExists id = skater
            break
        endif
        skater : GetAmmo
        if not ( <ammo> > 0 )
            break
        endif
        skater : GetAmmoType
        dadmod_throw_label ammo_type = <ammo_type>
        FormatText TextName = dadmod_tt "%l: %a" l = <dadmod_tl> a = <ammo>
        if ScreenElementExists id = dadmod_ammo_hud
            SetScreenElementProps id = dadmod_ammo_hud text = <dadmod_tt>
        else
            SetScreenElementLock id = root_window off
            CreateScreenElement {
            Type = TextElement
            parent = root_window
            id = dadmod_ammo_hud
            font = dialog
            text = <dadmod_tt>
            Pos = (6.2e+02,3.9e+02)
            just = [ right center ]
            scale = 0.8
            rgba = [ 128 128 128 128 ]
            z_priority = 900
            }
        endif
        dadmod_ta = 1.0
        root_window : GetSingleTag menu_state
        if GotParam menu_state
            if ( <menu_state> = on )
                dadmod_ta = 0.0
            endif
        endif
        DoScreenElementMorph id = dadmod_ammo_hud alpha = <dadmod_ta> time = 0
        wait 0.15 seconds
    repeat
    if ScreenElementExists id = dadmod_ammo_hud
        DestroyScreenElement id = dadmod_ammo_hud
    endif
endscript
script dadmod_throw_random_go
    skater : SetTags dadmod_throw_rand = 0
    if GotParam t
        skater : SetTags dadmod_throw_lbl = <t>
    endif
    dadmod_tr = none
    switch <a>
    case dadmod_throw_cars
        dadmod_tr = dadmod_throw_vehicles
    case dadmod_throw_animals
        dadmod_tr = dadmod_throw_animals
    case dadmod_throw_peds
        dadmod_tr = dadmod_throw_peds
    case dadmod_throw_junk
        dadmod_tr = dadmod_throw_junk
    case dadmod_throw_mystery
        dadmod_tr = dadmod_throw_all
    endswitch
    if ( <dadmod_tr> = none )
        return a = <a>
    endif
    skater : SetTags dadmod_throw_rand = <dadmod_tr>
    dadmod_throw_random_car dadmod_tr = <dadmod_tr>
    return a = <dadmod_tc>
endscript
script dadmod_throw_random_car dadmod_tr = dadmod_throw_vehicles
    dadmod_tc = dadmod_throw_car
    dadmod_tk = 0
    begin
        GetRandomArrayElement <dadmod_tr>
        if not GotParam dadmod_tlast
            break
        endif
        if not ( <element> = <dadmod_tlast> )
            break
        endif
        dadmod_tk = ( <dadmod_tk> + 1 )
        if ( <dadmod_tk> > 8 )
            break
        endif
    repeat
    return dadmod_tc = <element>
endscript
script dadmod_throw_next_car
    if not GotParam owner_id
        return
    endif
    if not ObjectExists id = skater
        return
    endif
    skater : Obj_GetId
    if not ( <objID> = <owner_id> )
        return
    endif
    skater : GetTags
    if not GotParam dadmod_throw_rand
        return
    endif
    if ( <dadmod_throw_rand> = 0 )
        return
    endif
    skater : GetAmmo
    if not ( <ammo> > 0 )
        return
    endif
    dadmod_throw_random_car dadmod_tlast = <ammo_type> dadmod_tr = <dadmod_throw_rand>
    skater : SetAmmoType <dadmod_tc>
endscript
script dadmod_throw_stock_toggle
    if THUGRECOMP_ThrowStockOn
        THUGRECOMP_ThrowStockOn set = 0
    else
        THUGRECOMP_ThrowStockOn set = 1
    endif
    dadmod_throw_menu
endscript
script dadmod_throw_stock_register
    if THUGRECOMP_ThrowStockType
        return
    endif
    dadmod_ta = dadmod_throw_all
    GetArraySize <dadmod_ta>
    dadmod_ti = 0
    begin
        THUGRECOMP_ThrowStockType type = ( <dadmod_ta> [ <dadmod_ti> ] )
        dadmod_ti = ( <dadmod_ti> + 1 )
    repeat <array_size>
endscript
script dadmod_throw_stock_send
    if not InNetGame
        return
    endif
    if not OnServer
        return
    endif
    if not THUGRECOMP_ThrowStockOn
        return
    endif
    if not GotParam vel
        return
    endif
    if not GotParam owner_id
        return
    endif
    if GotParam skater_pos
        dadmod_sp = <skater_pos>
    else
        if not GotParam Pos
            return
        endif
        dadmod_sp = <Pos>
    endif
    FormatText ChecksumName = dadmod_tsname "dadmod_tp_%i" i = <dadmod_tsn>
    dadmod_tsc = ( client_projectile_composite_structure + <model> )
    THUGRECOMP_ThrowPushStock run = CreateCompositeObject params = { Components = <dadmod_tsc> params = { Name = <dadmod_tsname> owner_id = <owner_id> Pos = <dadmod_sp> vel = <vel> radius = 24 scale = 1.0 orient_to_vel NeverSuspend SystemLifetime = 1 DieUponSettling death_script = projectile_die } }
    THUGRECOMP_ThrowPushStock run = create_panel_block params = { id = dadmod_tps_wake text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = RunScriptOnObject id = <dadmod_tsname> generic_menu_pad_choose params = { callback = RigidBody_Wake } } }
endscript
