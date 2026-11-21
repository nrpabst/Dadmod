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
    case dadmod_throw_halfpipe
        dadmod_tm = "veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl"
    case dadmod_throw_anl_dog
        dadmod_tm = "animals\\anl_dog\\anl_dog.skin"
        dadmod_tsk = anl_dog
    case dadmod_throw_anl_dog_grey
        dadmod_tm = "animals\\anl_dog\\anl_dog_grey.skin"
        dadmod_tsk = anl_dog
    case dadmod_throw_anl_cat
        dadmod_tm = "animals\\anl_cat\\anl_cat.skin"
        dadmod_tsk = anl_cat
    case dadmod_throw_anl_pigeon
        dadmod_tm = "animals\\anl_pigeon\\anl_pigeon.skin"
        dadmod_tsk = anl_pigeon
    case dadmod_throw_anl_seagull
        dadmod_tm = "animals\\anl_seagull\\anl_seagull.skin"
        dadmod_tsk = anl_seagull
    case dadmod_throw_anl_bat
        dadmod_tm = "animals\\anl_bat\\anl_bat.skin"
        dadmod_tsk = anl_pigeon
    case dadmod_throw_anl_parrot
        dadmod_tm = "animals\\anl_parrot\\anl_parrot.skin"
        dadmod_tsk = anl_pigeon
    case dadmod_throw_anl_bull
        dadmod_tm = "animals\\anl_bull\\anl_bull.skin"
        dadmod_tsk = anl_bull
    case dadmod_throw_anl_shark
        dadmod_tm = "animals\\anl_shark\\anl_shark.skin"
        dadmod_tsk = Anl_shark
    case dadmod_throw_anl_fish
        dadmod_tm = "animals\\anl_fish\\anl_fish.skin"
        dadmod_tsk = Anl_shark
    case dadmod_throw_anl_eel
        dadmod_tm = "animals\\anl_electriceel\\anl_electriceel.skin"
        dadmod_tsk = Anl_shark
    case dadmod_throw_ped_mime
        dadmod_tm = "peds\\ped_mime\\ped_mime.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_pirate
        dadmod_tm = "peds\\ped_pirate\\ped_pirate.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_jester
        dadmod_tm = "peds\\ped_jester\\ped_jester.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_natas
        dadmod_tm = "peds\\ped_natas\\ped_natas.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_bigfoot
        dadmod_tm = "peds\\ped_bigfoot\\ped_bigfoot.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_benfranklin
        dadmod_tm = "peds\\ped_benfranklin\\ped_benfranklin.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_zombie
        dadmod_tm = "peds\\ped_zombiemale01\\ped_zombiemale01.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_boxer
        dadmod_tm = "peds\\ped_boxer\\ped_boxer.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_wienerman
        dadmod_tm = "peds\\ped_wienerman\\ped_wienerman.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_bullfighter
        dadmod_tm = "peds\\ped_bullfighter\\ped_bullfighter.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_lifeguard
        dadmod_tm = "peds\\ped_lifeguard\\ped_lifeguard.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_copaussie
        dadmod_tm = "peds\\ped_copaussie\\ped_copaussie.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_germancop
        dadmod_tm = "peds\\ped_germancop\\ped_germancop.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_alien
        dadmod_tm = "peds\\ped_alien\\ped_alien.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_imp
        dadmod_tm = "peds\\ped_imp\\ped_imp.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_judge
        dadmod_tm = "peds\\ped_judge\\ped_judge.skin"
        dadmod_tsk = THPS6_human
    case dadmod_throw_ped_nurse
        dadmod_tm = "peds\\ped_nurse\\ped_nurse.skin"
        dadmod_tsk = Ped_Female
    case dadmod_throw_ped_zombiefem
        dadmod_tm = "peds\\ped_zombiefem01\\ped_zombiefem01.skin"
        dadmod_tsk = Ped_Female
    case dadmod_throw_junk_cone
        dadmod_tm = "mdl_cone\\mdl_cone.mdl"
    case dadmod_throw_junk_dogfood
        dadmod_tm = "gameobjects\\pickups\\dog_food\\dog_food.mdl"
    case dadmod_throw_junk_hoagie
        dadmod_tm = "gameobjects\\pickups\\hoagie\\hoagie.mdl"
    case dadmod_throw_junk_skunk
        dadmod_tm = "gameobjects\\pickups\\skunk\\skunk.mdl"
    case dadmod_throw_junk_chest
        dadmod_tm = "gameobjects\\pickups\\treasure_chest\\treasure_chest.mdl"
    case dadmod_throw_junk_pot
        dadmod_tm = "gameobjects\\pickups\\flower_pot\\flower_pot.mdl"
    case dadmod_throw_junk_shoebox
        dadmod_tm = "gameobjects\\vc\\shoebox_pickup\\shoebox_pickup.mdl"
    case dadmod_throw_junk_tomato
        dadmod_tm = "gameobjects\\projectiles\\tomato\\tomato.mdl"
    case dadmod_throw_junk_apple
        dadmod_tm = "gameobjects\\projectiles\\apple\\apple.mdl"
    case dadmod_throw_junk_paintcan
        dadmod_tm = "gameobjects\\projectiles\\paintcan\\paintcan.mdl"
    case dadmod_throw_junk_crown
        dadmod_tm = "crown\\crown.mdl"
    case dadmod_throw_junk_letter_s
        dadmod_tm = "gameobjects\\skate\\letter_s\\letter_s.mdl"
    case dadmod_throw_board
        dadmod_tm = "board_default\\board_default.mdl"
    case dadmod_throw_ball
        dadmod_tm = "gameobjects\\pickups\\crystal_ball\\crystal_ball.mdl"
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
        if GotParam dadmod_tsk
            <model> = [ { component = skeleton skeletonName = <dadmod_tsk> } { component = model model = <dadmod_tm> } ]
            RemoveParameter dadmod_tsk
        else
            <model> = [ { component = model model = <dadmod_tm> } ]
        endif
        <projectilecollision> = [ { component = projectilecollision projectile_type = tomato } ]
        RemoveParameter dadmod_tm
        dadmod_throw_next_car <...>
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
dadmod_throw_vehicles = [ dadmod_throw_car dadmod_throw_limo dadmod_throw_truck dadmod_throw_van dadmod_throw_hearse dadmod_throw_bus dadmod_throw_blimp dadmod_throw_boat dadmod_throw_halfpipe ]
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
    dadmod_throw_random_go a = <a>
    skater : SetAmmo 0
    skater : give_skater_ammo Type = <a> num = 99
    FormatText TextName = msg "%t: \\b1 throws them (99)" t = <t>
    create_panel_message id = dadmod_throw_msg text = <msg> time = 3000
    dadmod_ammo_hud_start
    dadmod_throw_msg_clear
endscript
