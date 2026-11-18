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
