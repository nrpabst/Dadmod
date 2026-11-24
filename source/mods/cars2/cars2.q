script dadmod_cars_menu
    dialog_box_exit
    generic_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_cars
    scrolling
    num_items_to_show = 13
    menu_title = "cars"
    menu_style = MENU_STYLE_LEFT
    pad_back_script = dadmod_menu
    helper_text = generic_helper_text
    show_description_panel
    show_gradient
    boxed
    }
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        make_thugpro_menu_item {
        text = <dadmod_c2_no>
        not_focusable
        }
    endif
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_ko "Get out here. In a car: %b gets out, %c handbrake, %h horn" b = <dadmod_c2_xl> c = <dadmod_c2_hk> h = <dadmod_c2_hn>
    make_thugpro_menu_item {
    text = "Get Out"
    description_text = <dadmod_c2_ko>
    pad_choose_script = dadmod_cars_exit
    }
    make_thugpro_menu_item {
    text = "More Cars  >"
    description_text = "20 more cars. DadMod players see them, others see a green car"
    pad_choose_script = dadmod_cars_menu_extra
    }
    make_thugpro_menu_item {
    text = "Props  >"
    description_text = "Drive a traffic cone, a shopping cart, a robot and more"
    pad_choose_script = dadmod_cars_menu_props
    }
    dadmod_cars_item t = "TransAm" c = JunkerCar
    dadmod_cars_item t = "Custom Tuner" c = RallyCar
    dadmod_cars_item t = "Impala" c = ImpalaCar
    dadmod_cars_item t = "Police Car" c = PoliceCar
    dadmod_cars_item t = "NY Cab" c = TaxiNY
    dadmod_cars_item t = "Security Cart" c = SecurityCart
    dadmod_cars_item t = "Gardener Cart" c = GardnersCart
    dadmod_cars_item t = "El Camino" c = ElCaminoCar
    dadmod_cars_item t = "Lada" c = LadaCar
    dadmod_cars_item t = "Mini Baja" c = MiniBajaCar
    dadmod_cars_item t = "Limo" c = LimoCar
    dadmod_cars_item t = "Taurus" c = TaurusCar
    dadmod_cars_item t = "Pickup" c = PickupTruck
    dadmod_cars_item t = "Wrangler" c = WranglerCar
    dadmod_cars_item t = "Sports Car" c = SportsCar
    dadmod_cars_item t = "Forklift" c = Forklift
    dadmod_cars_item t = "Blimp" c = Blimp
    thugpro_menu_finalize
endscript
script dadmod_cars_item
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_d "Drive the %t: %a/%b gas/brake, %c/%e steer, %h handbrake, %o out. Everyone sees it" t = <t> a = <dadmod_c2_up> b = <dadmod_c2_dn> c = <dadmod_c2_lf> e = <dadmod_c2_rt> h = <dadmod_c2_hk> o = <dadmod_c2_xo>
    make_thugpro_menu_item {
    text = <t>
    description_text = <dadmod_c2_d>
    pad_choose_script = dadmod_cars_pick
    pad_choose_params = { dadmod_c2_c = <c> }
    }
endscript
script dadmod_cars_can_drive
    if not ObjectExists id = skater
        return dadmod_c2_no = "No skater right now"
    endif
    if ChangeLevelPending
        return dadmod_c2_no = "The level is changing"
    endif
    if IsTrue THUGPRO_ObserveOn
        return dadmod_c2_no = "Not while observing"
    endif
    if InNetGame
        if GameModeEquals is_horse
            return dadmod_c2_no = "No cars in Horse"
        endif
        if GameModeEquals is_goal_attack
            return dadmod_c2_no = "No cars in Goal Attack"
        endif
    else
        if not ( ( GameModeEquals is_lobby ) or ( GameModeEquals is_singlesession ) )
            return dadmod_c2_no = "Cars work in free skate only"
        endif
    endif
    return dadmod_c2_ok = 1
endscript
script dadmod_cars_msg
    THUGRECOMP_Log text = <text>
    create_panel_message id = dadmod_cars_note text = <text> time = 2500
endscript
script dadmod_cars_pick
    if not GotParam dadmod_c2_c
        return
    endif
    exit_pause_menu
    KillSpawnedScript Name = dadmod_cars_go
    Change vehicleCameraSetup = { alignment_rate = 3.5 offset_height = 55 offset_distance = 240 angle = 0 }
    SpawnScript dadmod_cars_go params = { dadmod_c2_c = <dadmod_c2_c> } NotSessionSpecific = 1
endscript
script dadmod_cars_go
    wait 5 gameframes
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        dadmod_cars_msg text = <dadmod_c2_no>
        return
    endif
    if Skater : Driving
        KillSpawnedScript Name = dadmod_cars_wait_exit
        KillSpawnedScript Name = dadmod_cars_watch
        dadmod_cars_exit_now
        wait 10 gameframes
        if not ObjectExists id = skater
            return
        endif
        if Skater : Driving
            dadmod_cars_msg text = "Could not switch cars"
            return
        endif
        dadmod_c2_sw = 1
    endif
    if not GotParam dadmod_c2_sw
        if Skater : InAir
            dadmod_cars_msg text = "Land first, then pick the car"
            return
        endif
        if Skater : IsInBail
            dadmod_cars_msg text = "Get up first, then pick the car"
            return
        endif
    endif
    dadmod_cars_boot
    GetVehicleSetup control_type = <dadmod_c2_c>
    if not StructureContains structure = ( VehicleSetupMapping ) <dadmod_c2_c>
        if StructureContains structure = ( dadmod_c2_extra_map ) <dadmod_c2_c>
            VehicleSetup = ( dadmod_c2_extra_map . <dadmod_c2_c> )
        endif
    endif
    Skater : Obj_GetPosition
    VehicleSetup = { <VehicleSetup> control_type = <dadmod_c2_c> Pos = ( <Pos> + (0.0,20.0,0.0) ) }
    THUGRECOMP_CarsDrive gta = 0
    if StructureContains structure = ( dadmod_c2_physfix ) <dadmod_c2_c>
        dadmod_c2_pf = ( dadmod_c2_physfix . <dadmod_c2_c> )
        VehicleSetup = { <VehicleSetup> <dadmod_c2_pf> }
    endif
    if StructureContains structure = ( dadmod_c2_car_sounds ) <dadmod_c2_c>
        dadmod_c2_sn = ( dadmod_c2_car_sounds . <dadmod_c2_c> )
        VehicleSetup = { <VehicleSetup> sounds = <dadmod_c2_sn> }
    endif
    if StructureContains structure = <VehicleSetup> skater_anim
        VehicleSetup = { <VehicleSetup> skater_anim = Ped_SIT_Idle }
    endif
    dadmod_c2_hide = 1
    if StructureContains structure = <VehicleSetup> make_skater_visible
        dadmod_c2_hide = 0
    endif
    THUGRECOMP_Log text = "cars2: get in"
    LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
    LoadSound "Vehicles\\Vehicle_Tire_Loop"
    LoadSound "Terrains\\BonkMetal_11"
    dadmod_cars_load_sound c = <dadmod_c2_c>
    dadmod_c2_cd = 240
    dadmod_c2_ch = 55
    dadmod_c2_ca = 3.5
    if StructureContains structure = ( dadmod_c2_cams ) <dadmod_c2_c>
        dadmod_c2_cm = ( dadmod_c2_cams . <dadmod_c2_c> )
        dadmod_c2_cd = ( <dadmod_c2_cm> . d )
        dadmod_c2_ch = ( <dadmod_c2_cm> . h )
    endif
    Change vehicleCameraSetup = { alignment_rate = <dadmod_c2_ca> offset_height = <dadmod_c2_ch> offset_distance = <dadmod_c2_cd> angle = 0 }
    MakeSkaterGoto Switch_OnGroundAi params = { NewScript = TransAm VehicleSetup = <VehicleSetup> Exitable }
    dadmod_c2_k = 0
    begin
        if ObjectExists id = PlayerVehicleCamera
            break
        endif
        if ( <dadmod_c2_k> > 30 )
            THUGRECOMP_Log text = "cars2: no PlayerVehicleCamera after 30 frames"
            dadmod_cars_msg text = "The car didn't start"
            Change vehicleCameraSetup = { alignment_rate = 3.5 offset_height = 55 offset_distance = 240 angle = 0 }
            dadmod_cars_start_failed
            return
        endif
        dadmod_c2_k = ( <dadmod_c2_k> + 1 )
        wait 1 gameframe
    repeat
    Change vehicleCameraSetup = { alignment_rate = 3.5 offset_height = 55 offset_distance = 240 angle = 0 }
    PlayerVehicleCamera : VehicleCamera_Reset
    SetActiveCamera id = PlayerVehicleCamera
    dadmod_cars_after_zero
    if GotParam dadmod_c2_z
        MakeSkaterGoto dadmod_cars_drive_ai params = { dadmod_c2_z = 1 }
        if ObjectExists id = skater
            Skater : EnablePlayerInput
        endif
    else
        MakeSkaterGoto dadmod_cars_drive_ai
    endif
    dadmod_cars_prop_show VehicleSetup = <VehicleSetup>
    if ObjectExists id = skater
        Skater : SetTags dadmod_c2_hide = <dadmod_c2_hide>
        if ( <dadmod_c2_hide> = 1 )
            Skater : hide
        endif
    endif
    dadmod_cars_hint_off
    THUGRECOMP_CarsDrive on = 1
    KillSpawnedScript Name = dadmod_cars_wait_exit
    SpawnScript dadmod_cars_wait_exit NotSessionSpecific = 1
    KillSpawnedScript Name = dadmod_cars_watch
    SpawnScript dadmod_cars_watch params = { dadmod_c2_hide = <dadmod_c2_hide> } NotSessionSpecific = 1
endscript
script dadmod_cars_wait_exit
    wait 0.5 seconds
    WaitForEvent Type = ExitVehicleRequest
    KillSpawnedScript Name = dadmod_cars_watch
    dadmod_cars_exit_now
endscript
script dadmod_cars_watch dadmod_c2_hide = 0
    GetGameMode
    dadmod_c2_gm = <gamemode>
    dadmod_cars_time_left
    dadmod_c2_tl = <dadmod_c2_t>
    begin
        dadmod_cars_beat dadmod_c2_hide = <dadmod_c2_hide>
        wait 3 gameframes
    repeat 10
    begin
        dadmod_cars_beat dadmod_c2_hide = <dadmod_c2_hide>
        wait 3 gameframes
        if not ObjectExists id = skater
            KillSpawnedScript Name = dadmod_cars_wait_exit
            dadmod_cars_hint_off
            dadmod_cars_prop_hide
            break
        endif
        if not Skater : Driving
            KillSpawnedScript Name = dadmod_cars_wait_exit
            dadmod_cars_hint_off
            dadmod_cars_prop_hide
            if Skater : IsHidden
                Skater : unhide
            endif
            break
        endif
        if not ObjectExists id = PlayerVehicle
            KillSpawnedScript Name = dadmod_cars_wait_exit
            THUGRECOMP_Log text = "cars2: car gone while driving, cleaning up"
            dadmod_cars_exit_now
            break
        endif
        dadmod_cars_can_drive
        if GotParam dadmod_c2_no
            KillSpawnedScript Name = dadmod_cars_wait_exit
            THUGRECOMP_Log text = "cars2: car not allowed here any more, getting out"
            dadmod_cars_exit_now
            break
        endif
        GetGameMode
        if not ( <gamemode> = <dadmod_c2_gm> )
            if GameModeEquals is_lobby
                dadmod_c2_gm = <gamemode>
            else
                KillSpawnedScript Name = dadmod_cars_wait_exit
                THUGRECOMP_Log text = "cars2: a new game is starting, getting out"
                dadmod_cars_exit_now
                break
            endif
        endif
        dadmod_cars_time_left
        if not GameModeEquals is_lobby
            if ( <dadmod_c2_t> > ( <dadmod_c2_tl> + 3000 ) )
                KillSpawnedScript Name = dadmod_cars_wait_exit
                THUGRECOMP_Log text = "cars2: a new round is starting, getting out"
                dadmod_cars_exit_now
                break
            endif
        endif
        dadmod_c2_tl = <dadmod_c2_t>
    repeat
endscript
script dadmod_cars_hint_off
    THUGRECOMP_CarsDrive on = 0
    if ScreenElementExists id = dadmod_cars_hint
        DestroyScreenElement id = dadmod_cars_hint
    endif
endscript
script dadmod_cars_beat dadmod_c2_hide = 0
    if ( <dadmod_c2_hide> = 1 )
        if ObjectExists id = skater
            if Skater : Driving
                if not Skater : IsHidden
                    Skater : hide
                endif
            endif
        endif
    endif
    dadmod_c2_m = 0
    if ScreenElementExists id = current_menu_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = dialog_box_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = keyboard_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = quit_dialog_anchor
        dadmod_c2_m = 1
    endif
    if GameIsPaused
        dadmod_c2_m = 1
    endif
    if ( <dadmod_c2_m> = 1 )
        THUGRECOMP_CarsDrive on = 0
    else
        THUGRECOMP_CarsDrive on = 1
        if GotParam horn
            dadmod_cars_horn
        endif
    endif
    if GotParam cam_reset
        if ObjectExists id = PlayerVehicleCamera
            PlayerVehicleCamera : VehicleCamera_Reset
        endif
    endif
endscript
script dadmod_cars_exit
    exit_pause_menu
    KillSpawnedScript Name = dadmod_cars_exit_go
    SpawnScript dadmod_cars_exit_go NotSessionSpecific = 1
endscript
script dadmod_cars_exit_go
    wait 3 gameframes
    KillSpawnedScript Name = dadmod_cars_wait_exit
    KillSpawnedScript Name = dadmod_cars_watch
    if ObjectExists id = skater
        if not Skater : Driving
            dadmod_cars_hint_off
            dadmod_cars_msg text = "You're not in a car"
            return
        endif
    endif
    dadmod_cars_exit_now
endscript
script dadmod_cars_exit_now
    dadmod_cars_prop_hide
    dadmod_cars_hint_off
    if not ObjectExists id = skater
        return
    endif
    if not Skater : Driving
        return
    endif
    THUGRECOMP_Log text = "cars2: get out"
    if ObjectExists id = PlayerVehicle
        PlayerVehicle : Obj_GetPosition
        dadmod_c2_pos = <Pos>
        if ObjectExists id = PlayerVehicleCamera
            ToggleUserControlledVehicleMode
            if ObjectExists id = skater
                Skater : dadmod_shadow_restore
            endif
        else
            PlayerVehicle : Die
            dadmod_cars_cleanup
        endif
    else
        dadmod_cars_cleanup
    endif
    if not ObjectExists id = skater
        return
    endif
    if GotParam dadmod_c2_pos
        Skater : Obj_SetPosition position = ( <dadmod_c2_pos> + (0.0,10.0,0.0) )
    endif
    Skater : UnpausePhysics
    Skater : SetSpeed 0
    MakeSkaterGoto Switch_OnGroundAi params = { NewScript = OnGroundAi }
    wait 2 gameframes
    if ObjectExists id = skater
        Skater : SetSpeed 0
        dadmod_cars_after_zero
        if GotParam dadmod_c2_z
            if not GameIsOver
                THUGRECOMP_Log text = "cars2: got out after the clock hit zero, ending the run"
                MakeSkaterGoto EndOfRun params = { instant }
            endif
        endif
    endif
endscript
script dadmod_cars_cleanup
    dadmod_cars_prop_hide
    Skater : GetCameraId
    if ObjectExists id = <CameraId>
        if not GameIsPaused
            <CameraId> : unpause
        endif
        SetActiveCamera id = <CameraId>
    endif
    if ObjectExists id = PlayerVehicleCamera
        PlayerVehicleCamera : Die
    endif
    Skater : UnsetDriving
    Skater : unhide
    Skater : ReturnBoardToSkater
    Skater : dadmod_shadow_restore
    Skater : ResetRigidBodyCollisionRadiusBoost
    GoalManager_HideAllGoalPeds 0
    Change driving_parked_car = 0
endscript
script dadmod_cars_rehide
    if ObjectExists id = skater
        if Skater : Driving
            Skater : GetTags
            if GotParam dadmod_c2_hide
                if ( <dadmod_c2_hide> = 1 )
                    Skater : hide
                    KillSpawnedScript Name = dadmod_cars_rehide_frames
                    SpawnScript dadmod_cars_rehide_frames NotSessionSpecific = 1
                endif
            endif
        endif
    endif
endscript
script dadmod_cars_rehide_frames
    begin
        wait 1 gameframe
        if not ObjectExists id = skater
            break
        endif
        if not Skater : Driving
            break
        endif
        Skater : hide
    repeat 15
endscript
script dadmod_cars_item_x
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_d "Drive the %t: %a/%b gas/brake, %h handbrake, %o out. DadMod players see it" t = <t> a = <dadmod_c2_up> b = <dadmod_c2_dn> h = <dadmod_c2_hk> o = <dadmod_c2_xo>
    make_thugpro_menu_item {
    text = <t>
    description_text = <dadmod_c2_d>
    pad_choose_script = dadmod_cars_pick
    pad_choose_params = { dadmod_c2_c = <c> }
    }
endscript
script dadmod_cars_menu_extra
    dadmod_cars_sub_menu title = "more cars" items = dadmod_cars_extra_items
endscript
script dadmod_cars_menu_props
    dadmod_cars_sub_menu title = "props" items = dadmod_cars_prop_items
endscript
script dadmod_cars_sub_menu
    dialog_box_exit
    generic_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_cars_sub
    scrolling
    num_items_to_show = 13
    menu_title = <title>
    menu_style = MENU_STYLE_LEFT
    pad_back_script = dadmod_cars_menu
    helper_text = generic_helper_text
    show_description_panel
    show_gradient
    boxed
    }
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        make_thugpro_menu_item {
        text = <dadmod_c2_no>
        not_focusable
        }
    endif
    make_thugpro_menu_item {
    text = "Get Out"
    description_text = "Get out of the car and back on your board, right where the car is"
    pad_choose_script = dadmod_cars_exit
    }
    <items>
    thugpro_menu_finalize
endscript
script dadmod_cars_handling_get
    return dadmod_c2_gta = 0
endscript
script dadmod_cars_boot
    if not StructureContains structure = ( VehicleSetupMapping ) dadmod_prop_cone
        dadmod_cars_boot_maps
    endif
    dadmod_cars_handling_get
    THUGRECOMP_CarsDrive gta = <dadmod_c2_gta>
    KillSpawnedScript Name = dadmod_cars_remote_props
    SpawnScript dadmod_cars_remote_props NotSessionSpecific = 1
endscript
script dadmod_cars_horn
    if not ObjectExists id = skater
        return
    endif
    if not Skater : Driving
        return
    endif
    if not IsStreamPlaying CarHorn
        Skater : Obj_PlayStream CarHorn vol = 100 dropoff = 300
    endif
    if InNetGame
        THUGRECOMP_CarsHornSend
        if OnServer
            dadmod_cars_horn_push
        endif
    endif
endscript
script dadmod_cars_horn_push
    THUGRECOMP_CarsHornPushStock run = create_panel_block params = { id = thugrecomp_horn_block text = " " Pos = (-1000.0,-1000.0) style = generic_menu_pad_choose params = { callback = THUGPRO_Televator stream = CarHorn } }
endscript
script dadmod_cars_horn_hear
    if not GotParam id
        return
    endif
    thugpro_slaphit_obj id = <id>
    if not GotParam o
        return
    endif
    if not ObjectExists id = <o>
        return
    endif
    if OnServer
        dadmod_cars_horn_push
    endif
    if IsStreamPlaying CarHorn
        return
    endif
    <o> : Obj_GetPosition
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Die
    endif
    CreateCompositeObject {
    Components = [
    {
    component = stream
    }
    ]
    params = { Name = dadmod_horn_src Pos = <Pos> }
    }
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Obj_PlayStream CarHorn vol = 100 dropoff = 300
        KillSpawnedScript Name = dadmod_cars_horn_src_die
        SpawnScript dadmod_cars_horn_src_die NotSessionSpecific = 1
    endif
endscript
script dadmod_cars_horn_src_die
    wait 3 seconds
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Die
    endif
endscript
script dadmod_cars_prop_show
    dadmod_cars_prop_hide
    if not GotParam VehicleSetup
        return
    endif
    if not StructureContains structure = <VehicleSetup> dadmod_prop_model
        return
    endif
    if not ObjectExists id = PlayerVehicle
        return
    endif
    PlayerVehicle : hide
    CreateCompositeObject {
    Components = [
    {
    component = lockobj
    }
    {
    component = model
    model = ( <VehicleSetup> . dadmod_prop_model )
    UseModelLights
    }
    ]
    params = { Name = dadmod_prop_vis }
    }
    if ObjectExists id = dadmod_prop_vis
        dadmod_prop_vis : Obj_LockToObject id = PlayerVehicle (0.0,0.0,0.0)
    endif
endscript
script dadmod_cars_prop_hide
    if ObjectExists id = dadmod_prop_vis
        dadmod_prop_vis : Die
    endif
endscript
script dadmod_cars_remote_props
    begin
        wait 10 gameframes
        if InNetGame
            dadmod_c2_i = 0
            begin
                dadmod_cars_remote_prop_one id = <dadmod_c2_i>
                dadmod_c2_i = ( <dadmod_c2_i> + 1 )
            repeat 16
        endif
    repeat
endscript
script dadmod_cars_remote_prop_one
    thugpro_slaphit_obj id = <id>
    if not GotParam o
        return
    endif
    MangleChecksums a = <o> b = dadmod_prop_remote
    dadmod_c2_pv = <mangled_id>
    dadmod_c2_want = 0
    if ObjectExists id = <o>
        MangleChecksums a = <o> b = NonLocalPlayerVehicle
        dadmod_c2_car = <mangled_id>
        if ObjectExists id = <dadmod_c2_car>
            <dadmod_c2_car> : GetTags
            if GotParam current_control_type
                if StructureContains structure = ( dadmod_c2_extra_map ) <current_control_type>
                    dadmod_c2_set = ( dadmod_c2_extra_map . <current_control_type> )
                    if StructureContains structure = <dadmod_c2_set> dadmod_prop_model
                        dadmod_c2_want = 1
                    endif
                endif
            endif
        endif
    endif
    if ( <dadmod_c2_want> = 0 )
        if ObjectExists id = <dadmod_c2_pv>
            <dadmod_c2_pv> : Die
            if GotParam dadmod_c2_car
                if ObjectExists id = <dadmod_c2_car>
                    <dadmod_c2_car> : unhide
                endif
            endif
        endif
        return
    endif
    if ObjectExists id = <dadmod_c2_pv>
        <dadmod_c2_pv> : GetTags
        if GotParam dadmod_c2_ct
            if ( <dadmod_c2_ct> = <current_control_type> )
                <dadmod_c2_car> : hide
                return
            endif
        endif
        <dadmod_c2_pv> : Die
    endif
    CreateCompositeObject {
    Components = [
    {
    component = lockobj
    }
    {
    component = model
    model = ( <dadmod_c2_set> . dadmod_prop_model )
    UseModelLights
    }
    ]
    params = { Name = <dadmod_c2_pv> }
    }
    if ObjectExists id = <dadmod_c2_pv>
        <dadmod_c2_pv> : SetTags dadmod_c2_ct = <current_control_type>
        <dadmod_c2_pv> : Obj_LockToObject id = <dadmod_c2_car> (0.0,0.0,0.0)
        <dadmod_c2_car> : hide
    endif
endscript
script dadmod_cars_start_failed
    dadmod_cars_hint_off
    dadmod_cars_prop_hide
    if not ObjectExists id = skater
        return
    endif
    if Skater : Driving
        dadmod_cars_exit_now
        return
    endif
    if Skater : IsHidden
        Skater : unhide
    endif
    Skater : GetCameraId
    if ObjectExists id = <CameraId>
        SetActiveCamera id = <CameraId>
    endif
    MakeSkaterGoto Switch_OnGroundAi params = { NewScript = OnGroundAi }
endscript
script dadmod_cars_time_left
    dadmod_c2_t = 0
    if InNetGame
        if not GameModeEquals is_lobby
            if not GameModeEquals default_time_limit
                return dadmod_c2_t = 0
            endif
            GoalManager_GetTimeLeftInNetGame
            if GotParam time_left
                dadmod_c2_t = <time_left>
            endif
        endif
    endif
    return dadmod_c2_t = <dadmod_c2_t>
endscript
script dadmod_cars_after_zero
    if InNetGame
        if not GameModeEquals is_lobby
            if not GameModeEquals default_time_limit
                return dadmod_c2_t = 0
            endif
            GoalManager_GetTimeLeftInNetGame
            if GotParam time_left
                if ( <time_left> < 1 )
                    return dadmod_c2_z = 1
                endif
            endif
        endif
    endif
endscript
script dadmod_cars_drive_ai
    ClearAllWalkingExceptions
    ClearExceptions
    SetEventHandler ex = Vehicle_BodyCollision scr = Vehicle_BodyCollision
    SetEventHandler ex = SkaterCollideBail scr = DrivingCollisionLost
    SetEventHandler ex = MadeOtherSkaterBail scr = MadeOtherSkaterBailCar
    if not GotParam dadmod_c2_z
        SetException ex = RunHasEnded scr = dadmod_cars_run_ended
    endif
    SetException ex = GoalHasEnded scr = Goal_EndOfRun
    block
endscript
script dadmod_cars_run_ended
    ClearExceptions
    SetEventHandler ex = Vehicle_BodyCollision scr = Vehicle_BodyCollision
    SetEventHandler ex = SkaterCollideBail scr = DrivingCollisionLost
    SetEventHandler ex = MadeOtherSkaterBail scr = MadeOtherSkaterBailCar
    OnExitRun Script_ClearEndofRunStarted
    EndOfRunStarted
    if IsTrue THUGPRO_ObserveOn
        ResetScorePot
    else
        LandSkaterTricks
    endif
    if InNetGame
        if not GameIsOver
            if GameModeEquals is_ctf
                THUGPRO_DropFlag
            endif
        endif
    endif
    THUGRECOMP_Log text = "cars2: clock hit zero while driving, run ended, still driving"
    wait 1 seconds
    if IsTrue AlreadyEndedRun
        Change AlreadyEndedRun = 0
    else
        FireEvent Type = EndOfRunDone
        EndOfRunDone
    endif
    block
endscript
