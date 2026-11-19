script ClientLaunchProjectile
    switch <ammo_type>
    case dadmod_throw_car
        dadmod_tm = "veh\\Veh_Chevy_Impala\\Veh_Chevy_Impala.mdl"
    case dadmod_throw_limo
        dadmod_tm = "veh\\Veh_Limo\\Veh_Limo.mdl"
    case dadmod_throw_truck
        dadmod_tm = "veh\\Veh_Pickup\\Veh_Pickup.mdl"
    case dadmod_throw_van
        dadmod_tm = "veh\\Veh_OldVan\\Veh_OldVan.mdl"
    case dadmod_throw_hearse
        dadmod_tm = "veh\\Veh_Hearse\\Veh_Hearse.mdl"
    case dadmod_throw_bus
        dadmod_tm = "veh\\Veh_TourBus\\Veh_TourBus.mdl"
    case dadmod_throw_blimp
        dadmod_tm = "veh\\Veh_Blimp\\Veh_Blimp.mdl"
    case dadmod_throw_boat
        dadmod_tm = "veh\\Veh_Duck\\Veh_Duck.mdl"
    case dadmod_throw_sleigh
        dadmod_tm = "Veh_Meck_Sleigh\\Veh_Meck_Sleigh.mdl"
    case dadmod_throw_halfpipe
        dadmod_tm = "veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl"
    endswitch
    if GotParam dadmod_tm
        if not THUGRECOMP_ModelExists model = <dadmod_tm>
            RemoveParameter dadmod_tm
        endif
    endif
    if GotParam dadmod_tm
        Obj_GetId
        <SkaterId> = <objID>
        <SoundType> = #"Default"
        <model> = [ { component = model model = <dadmod_tm> } ]
        <projectilecollision> = [ { component = projectilecollision projectile_type = tomato } ]
        RemoveParameter dadmod_tm
        ClientLaunchProjectileReal <...>
        return
    endif
    ClientLaunchProjectile_orig <...>
endscript
script ClientLaunchProjectileReal
    dadmod_proj_slot
    if not GotParam dadmod_slot
        return
    endif
    if not GotParam SoundType
        SoundType = #"Default"
    endif
    dadmod_pp = {
    Name = <dadmod_slot>
    owner_id = <owner_id>
    vel = <vel>
    Pos = <skater_pos>
    radius = 24
    scale = 1.0
    orient_to_vel
    NeverSuspend
    SystemLifetime = 1
    DieUponSettling
    death_script = projectile_die
    SoundType = <SoundType>
    }
    dadmod_pc = ( client_projectile_composite_structure + <model> )
    if OnServer
        if InNetGame
            dadmod_pc = ( net_server_projectile_composite_structure + <model> + <projectilecollision> )
        else
            dadmod_pc = ( server_projectile_composite_structure + <model> )
        endif
    endif
    CreateCompositeObject Components = <dadmod_pc> params = <dadmod_pp>
    <dadmod_slot> : RigidBody_IgnoreSkater 15 frames
    <dadmod_slot> : RigidBody_Wake
endscript
script dadmod_proj_slot
    dadmod_i = 0
    begin
        FormatText ChecksumName = dadmod_n "projectile_%i" i = <dadmod_i>
        if not ObjectExists id = <dadmod_n>
            return dadmod_slot = <dadmod_n>
        endif
        dadmod_i = ( <dadmod_i> + 1 )
    repeat 5
endscript
dadmod_throw_vehicles = [ dadmod_throw_car dadmod_throw_limo dadmod_throw_truck dadmod_throw_van dadmod_throw_hearse dadmod_throw_bus dadmod_throw_blimp dadmod_throw_boat dadmod_throw_sleigh dadmod_throw_halfpipe ]
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
    if InNetGame
        if ArrayContains array = dadmod_throw_vehicles contains = <a>
            create_panel_message id = dadmod_throw_msg text = "Vehicle throwables are offline only" time = 2500
            dadmod_throw_msg_clear
            return
        endif
    endif
    skater : SetAmmo 0
    skater : give_skater_ammo Type = <a> num = 99
    FormatText TextName = msg "%t: \\b1 throws them (99)" t = <t>
    create_panel_message id = dadmod_throw_msg text = <msg> time = 3000
    dadmod_ammo_hud_start
    dadmod_throw_msg_clear
endscript
