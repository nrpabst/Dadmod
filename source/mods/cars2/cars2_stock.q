script dadmod_cars_stock_tick
    if not InNetGame
        return
    endif
    if not OnServer
        return
    endif
    if not THUGRECOMP_ThrowStockOn
        return
    endif
    dadmod_cs_new = 0
    dadmod_cs_m = { }
    dadmod_cs_i = 0
    begin
        dadmod_cars_stock_slot id = <dadmod_cs_i> mark = 1
        if GotParam dadmod_cs_ct
            dadmod_cs_e = ( dadmod_c2_stock_entries . <dadmod_cs_ct> )
            dadmod_cs_m = { <dadmod_cs_m> <dadmod_cs_e> }
            if GotParam dadmod_cs_fresh
                dadmod_cs_new = 1
            endif
            RemoveParameter dadmod_cs_ct
            RemoveParameter dadmod_cs_fresh
        endif
        dadmod_cs_i = ( <dadmod_cs_i> + 1 )
    repeat 16
    if ( <dadmod_cs_new> = 0 )
        return
    endif
    KillSpawnedScript Name = dadmod_cars_stock_push
    SpawnScript dadmod_cars_stock_push params = { dadmod_cs_m = <dadmod_cs_m> } NotSessionSpecific = 1
endscript
script dadmod_cars_stock_slot
    thugpro_slaphit_obj id = <id>
    if not GotParam o
        return
    endif
    if not ObjectExists id = <o>
        return
    endif
    dadmod_cs_local = 0
    if ObjectExists id = skater
        skater : Obj_GetId
        if ( <objID> = <o> )
            dadmod_cs_local = 1
        endif
    endif
    if ( <dadmod_cs_local> = 1 )
        if not Skater : Driving
            return
        endif
        skater : GetTags
        if not GotParam dadmod_c2_ct
            return
        endif
        if not ObjectExists id = PlayerVehicle
            return
        endif
        dadmod_cs_car = PlayerVehicle
        dadmod_cs_ct = <dadmod_c2_ct>
    else
        MangleChecksums a = <o> b = NonLocalPlayerVehicle
        dadmod_cs_car = <mangled_id>
        if not ObjectExists id = <dadmod_cs_car>
            return
        endif
        <dadmod_cs_car> : GetTags
        if not GotParam current_control_type
            return
        endif
        dadmod_cs_ct = <current_control_type>
    endif
    if not StructureContains structure = ( dadmod_c2_stock_entries ) <dadmod_cs_ct>
        return
    endif
    <dadmod_cs_car> : GetTags
    dadmod_cs_fresh = 1
    if GotParam dadmod_cs_pushed
        if ( <dadmod_cs_pushed> = <dadmod_cs_ct> )
            dadmod_cs_fresh = 0
        endif
    endif
    if GotParam mark
        <dadmod_cs_car> : SetTags dadmod_cs_pushed = <dadmod_cs_ct>
    endif
    if ( <dadmod_cs_fresh> = 1 )
        return dadmod_cs_ct = <dadmod_cs_ct> dadmod_cs_o = <o> dadmod_cs_fresh = 1
    endif
    return dadmod_cs_ct = <dadmod_cs_ct> dadmod_cs_o = <o>
endscript
script dadmod_cars_stock_push
    wait 2 gameframes
    dadmod_cs_nm = ( dadmod_c2_stock_tbl . m )
    dadmod_cs_nm = { <dadmod_cs_nm> <dadmod_cs_m> }
    if not THUGRECOMP_ThrowPushStock run = create_panel_block params = { id = dadmod_cs_map text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = Change globalname = VehicleSetupMapping newvalue = <dadmod_cs_nm> } }
        THUGRECOMP_Log text = "cars2 stock: car list push not sent"
    endif
    wait 2 gameframes
    dadmod_cs_i = 0
    begin
        dadmod_cars_stock_slot id = <dadmod_cs_i>
        if GotParam dadmod_cs_ct
            THUGRECOMP_ThrowPushStock run = create_panel_block params = { id = dadmod_cs_rm text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = remove_car_from_non_local_skater SkaterId = <dadmod_cs_o> } }
            wait 2 gameframes
            THUGRECOMP_ThrowPushStock run = create_panel_block params = { id = dadmod_cs_in text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = NonLocalClientInVehicle SkaterId = <dadmod_cs_o> control_type = <dadmod_cs_ct> } }
            wait 2 gameframes
            RemoveParameter dadmod_cs_ct
        endif
        dadmod_cs_i = ( <dadmod_cs_i> + 1 )
    repeat 16
endscript
script dadmod_cars_stock_clear
    if ObjectExists id = PlayerVehicle
        PlayerVehicle : SetTags dadmod_cs_pushed = none
    endif
    dadmod_cs_i = 0
    begin
        thugpro_slaphit_obj id = <dadmod_cs_i>
        MangleChecksums a = <o> b = NonLocalPlayerVehicle
        if ObjectExists id = <mangled_id>
            <mangled_id> : SetTags dadmod_cs_pushed = none
        endif
        dadmod_cs_i = ( <dadmod_cs_i> + 1 )
    repeat 16
endscript
script dadmod_cars_stock_rejoin
    dadmod_cs_t = 0
    begin
        if THUGRECOMP_PlayerReady name = <name>
            break
        endif
        dadmod_cs_t = ( <dadmod_cs_t> + 1 )
        if ( <dadmod_cs_t> > 90 )
            return
        endif
        wait 1 second
    repeat
    wait 6 seconds
    dadmod_cars_stock_clear
endscript
script dadmod_cars_stock_row
    if THUGRECOMP_ThrowStockOn
        dadmod_cs_tx = "Show to players without dadmod: On"
    else
        dadmod_cs_tx = "Show to players without dadmod: Off"
    endif
    make_thugpro_menu_item {
    text = <dadmod_cs_tx>
    description_text = "When you host: players without dadmod see More Cars and Props as the real thing (same switch as Throwables)"
    pad_choose_script = dadmod_cars_stock_toggle
    }
endscript
script dadmod_cars_stock_toggle
    if THUGRECOMP_ThrowStockOn
        THUGRECOMP_ThrowStockOn set = 0
    else
        THUGRECOMP_ThrowStockOn set = 1
    endif
    dadmod_cars_menu
endscript
