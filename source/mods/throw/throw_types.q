script thugpro_throw_parse2
    switch <msg>
    case "!AMMO CAR"
    case " !AMMO CAR"
    case "!AMMO CARS"
    case " !AMMO CARS"
    case "!CARS"
    case " !CARS"
        return ammo = dadmod_throw_car label = "cars" modonly = 1
    case "!AMMO LIMO"
    case " !AMMO LIMO"
    case "!AMMO LIMOS"
    case " !AMMO LIMOS"
    case "!LIMOS"
    case " !LIMOS"
        return ammo = dadmod_throw_limo label = "limos" modonly = 1
    case "!AMMO TRUCK"
    case " !AMMO TRUCK"
    case "!AMMO TRUCKS"
    case " !AMMO TRUCKS"
    case "!TRUCKS"
    case " !TRUCKS"
        return ammo = dadmod_throw_truck label = "trucks" modonly = 1
    case "!AMMO VAN"
    case " !AMMO VAN"
    case "!AMMO VANS"
    case " !AMMO VANS"
    case "!VANS"
    case " !VANS"
        return ammo = dadmod_throw_van label = "vans" modonly = 1
    case "!AMMO HEARSE"
    case " !AMMO HEARSE"
    case "!AMMO HEARSES"
    case " !AMMO HEARSES"
    case "!HEARSES"
    case " !HEARSES"
        return ammo = dadmod_throw_hearse label = "hearses" modonly = 1
    case "!AMMO BUS"
    case " !AMMO BUS"
    case "!AMMO BUSES"
    case " !AMMO BUSES"
    case "!BUSES"
    case " !BUSES"
        return ammo = dadmod_throw_bus label = "buses" modonly = 1
    case "!AMMO BLIMP"
    case " !AMMO BLIMP"
    case "!AMMO BLIMPS"
    case " !AMMO BLIMPS"
    case "!BLIMPS"
    case " !BLIMPS"
        return ammo = dadmod_throw_blimp label = "blimps" modonly = 1
    case "!AMMO BOAT"
    case " !AMMO BOAT"
    case "!AMMO BOATS"
    case " !AMMO BOATS"
    case "!BOATS"
    case " !BOATS"
        return ammo = dadmod_throw_boat label = "duck boats" modonly = 1
    case "!AMMO HALFPIPE"
    case " !AMMO HALFPIPE"
    case "!AMMO HALFPIPES"
    case " !AMMO HALFPIPES"
    case "!HALFPIPES"
    case " !HALFPIPES"
        return ammo = dadmod_throw_halfpipe label = "half pipes" modonly = 1
    endswitch
endscript
script dadmod_throw_model
    switch <ammo_type>
    case dadmod_throw_car
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Chevy_Impala\\Veh_Chevy_Impala.mdl" } ]
    case dadmod_throw_limo
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Limo\\Veh_Limo.mdl" } ]
    case dadmod_throw_truck
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Pickup\\Veh_Pickup.mdl" } ]
    case dadmod_throw_van
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_OldVan\\Veh_OldVan.mdl" } ]
    case dadmod_throw_hearse
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Hearse\\Veh_Hearse.mdl" } ]
    case dadmod_throw_bus
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_TourBus\\Veh_TourBus.mdl" } ]
    case dadmod_throw_blimp
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Blimp\\Veh_Blimp.mdl" } ]
    case dadmod_throw_boat
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Duck\\Veh_Duck.mdl" } ]
    case dadmod_throw_halfpipe
        return dadmod_tmodel = [ { component = model model = "veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl" } ]
    case dadmod_throw_anl_dog
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_dog } { component = model model = "animals\\anl_dog\\anl_dog.skin" } ]
    case dadmod_throw_anl_dog_grey
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_dog } { component = model model = "animals\\anl_dog\\anl_dog_grey.skin" } ]
    case dadmod_throw_anl_cat
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_cat } { component = model model = "animals\\anl_cat\\anl_cat.skin" } ]
    case dadmod_throw_anl_pigeon
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_pigeon } { component = model model = "animals\\anl_pigeon\\anl_pigeon.skin" } ]
    case dadmod_throw_anl_seagull
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_seagull } { component = model model = "animals\\anl_seagull\\anl_seagull.skin" } ]
    case dadmod_throw_anl_bat
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_pigeon } { component = model model = "animals\\anl_bat\\anl_bat.skin" } ]
    case dadmod_throw_anl_parrot
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_pigeon } { component = model model = "animals\\anl_parrot\\anl_parrot.skin" } ]
    case dadmod_throw_anl_bull
        return dadmod_tmodel = [ { component = skeleton skeletonName = anl_bull } { component = model model = "animals\\anl_bull\\anl_bull.skin" } ]
    case dadmod_throw_anl_shark
        return dadmod_tmodel = [ { component = skeleton skeletonName = Anl_shark } { component = model model = "animals\\anl_shark\\anl_shark.skin" } ]
    case dadmod_throw_anl_fish
        return dadmod_tmodel = [ { component = skeleton skeletonName = Anl_shark } { component = model model = "animals\\anl_fish\\anl_fish.skin" } ]
    case dadmod_throw_anl_eel
        return dadmod_tmodel = [ { component = skeleton skeletonName = Anl_shark } { component = model model = "animals\\anl_electriceel\\anl_electriceel.skin" } ]
    case dadmod_throw_ped_mime
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_mime\\ped_mime.skin" } ]
    case dadmod_throw_ped_pirate
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_pirate\\ped_pirate.skin" } ]
    case dadmod_throw_ped_jester
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_jester\\ped_jester.skin" } ]
    case dadmod_throw_ped_natas
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_natas\\ped_natas.skin" } ]
    case dadmod_throw_ped_bigfoot
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_bigfoot\\ped_bigfoot.skin" } ]
    case dadmod_throw_ped_benfranklin
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_benfranklin\\ped_benfranklin.skin" } ]
    case dadmod_throw_ped_zombie
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_zombiemale01\\ped_zombiemale01.skin" } ]
    case dadmod_throw_ped_boxer
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_boxer\\ped_boxer.skin" } ]
    case dadmod_throw_ped_wienerman
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_wienerman\\ped_wienerman.skin" } ]
    case dadmod_throw_ped_bullfighter
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_bullfighter\\ped_bullfighter.skin" } ]
    case dadmod_throw_ped_lifeguard
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_lifeguard\\ped_lifeguard.skin" } ]
    case dadmod_throw_ped_copaussie
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_copaussie\\ped_copaussie.skin" } ]
    case dadmod_throw_ped_germancop
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_germancop\\ped_germancop.skin" } ]
    case dadmod_throw_ped_alien
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_alien\\ped_alien.skin" } ]
    case dadmod_throw_ped_imp
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_imp\\ped_imp.skin" } ]
    case dadmod_throw_ped_judge
        return dadmod_tmodel = [ { component = skeleton skeletonName = THPS6_human } { component = model model = "peds\\ped_judge\\ped_judge.skin" } ]
    case dadmod_throw_ped_nurse
        return dadmod_tmodel = [ { component = skeleton skeletonName = Ped_Female } { component = model model = "peds\\ped_nurse\\ped_nurse.skin" } ]
    case dadmod_throw_ped_zombiefem
        return dadmod_tmodel = [ { component = skeleton skeletonName = Ped_Female } { component = model model = "peds\\ped_zombiefem01\\ped_zombiefem01.skin" } ]
    case dadmod_throw_junk_cone
        return dadmod_tmodel = [ { component = model model = "mdl_cone\\mdl_cone.mdl" } ]
    case dadmod_throw_junk_dogfood
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\dog_food\\dog_food.mdl" } ]
    case dadmod_throw_junk_hoagie
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\hoagie\\hoagie.mdl" } ]
    case dadmod_throw_junk_skunk
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\skunk\\skunk.mdl" } ]
    case dadmod_throw_junk_chest
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\treasure_chest\\treasure_chest.mdl" } ]
    case dadmod_throw_junk_pot
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\flower_pot\\flower_pot.mdl" } ]
    case dadmod_throw_junk_shoebox
        return dadmod_tmodel = [ { component = model model = "gameobjects\\vc\\shoebox_pickup\\shoebox_pickup.mdl" } ]
    case dadmod_throw_junk_tomato
        return dadmod_tmodel = [ { component = model model = "gameobjects\\projectiles\\tomato\\tomato.mdl" } ]
    case dadmod_throw_junk_apple
        return dadmod_tmodel = [ { component = model model = "gameobjects\\projectiles\\apple\\apple.mdl" } ]
    case dadmod_throw_junk_paintcan
        return dadmod_tmodel = [ { component = model model = "gameobjects\\projectiles\\paintcan\\paintcan.mdl" } ]
    case dadmod_throw_junk_crown
        return dadmod_tmodel = [ { component = model model = "crown\\crown.mdl" } ]
    case dadmod_throw_junk_letter_s
        return dadmod_tmodel = [ { component = model model = "gameobjects\\skate\\letter_s\\letter_s.mdl" } ]
    case dadmod_throw_board
        return dadmod_tmodel = [ { component = model model = "board_default\\board_default.mdl" } ]
    case dadmod_throw_ball
        return dadmod_tmodel = [ { component = model model = "gameobjects\\pickups\\crystal_ball\\crystal_ball.mdl" } ]
    endswitch
endscript
dadmod_throw_vehicles = [ dadmod_throw_car dadmod_throw_limo dadmod_throw_truck dadmod_throw_van dadmod_throw_hearse dadmod_throw_bus dadmod_throw_blimp dadmod_throw_boat dadmod_throw_halfpipe ]
dadmod_throw_animals = [ dadmod_throw_anl_dog dadmod_throw_anl_dog_grey dadmod_throw_anl_cat dadmod_throw_anl_pigeon dadmod_throw_anl_seagull dadmod_throw_anl_bat dadmod_throw_anl_parrot dadmod_throw_anl_bull dadmod_throw_anl_shark dadmod_throw_anl_fish dadmod_throw_anl_eel ]
dadmod_throw_peds = [ dadmod_throw_ped_mime dadmod_throw_ped_pirate dadmod_throw_ped_jester dadmod_throw_ped_natas dadmod_throw_ped_bigfoot dadmod_throw_ped_benfranklin dadmod_throw_ped_zombie dadmod_throw_ped_boxer dadmod_throw_ped_wienerman dadmod_throw_ped_bullfighter dadmod_throw_ped_lifeguard dadmod_throw_ped_copaussie dadmod_throw_ped_germancop dadmod_throw_ped_alien dadmod_throw_ped_imp dadmod_throw_ped_judge dadmod_throw_ped_nurse dadmod_throw_ped_zombiefem ]
dadmod_throw_junk = [ dadmod_throw_junk_cone dadmod_throw_junk_dogfood dadmod_throw_junk_hoagie dadmod_throw_junk_skunk dadmod_throw_junk_chest dadmod_throw_junk_pot dadmod_throw_junk_shoebox dadmod_throw_junk_tomato dadmod_throw_junk_apple dadmod_throw_junk_paintcan dadmod_throw_junk_crown dadmod_throw_junk_letter_s ]
dadmod_throw_all = [ dadmod_throw_car dadmod_throw_limo dadmod_throw_truck dadmod_throw_van dadmod_throw_hearse dadmod_throw_bus dadmod_throw_blimp dadmod_throw_boat dadmod_throw_halfpipe dadmod_throw_anl_dog dadmod_throw_anl_dog_grey dadmod_throw_anl_cat dadmod_throw_anl_pigeon dadmod_throw_anl_seagull dadmod_throw_anl_bat dadmod_throw_anl_parrot dadmod_throw_anl_bull dadmod_throw_anl_shark dadmod_throw_anl_fish dadmod_throw_anl_eel dadmod_throw_ped_mime dadmod_throw_ped_pirate dadmod_throw_ped_jester dadmod_throw_ped_natas dadmod_throw_ped_bigfoot dadmod_throw_ped_benfranklin dadmod_throw_ped_zombie dadmod_throw_ped_boxer dadmod_throw_ped_wienerman dadmod_throw_ped_bullfighter dadmod_throw_ped_lifeguard dadmod_throw_ped_copaussie dadmod_throw_ped_germancop dadmod_throw_ped_alien dadmod_throw_ped_imp dadmod_throw_ped_judge dadmod_throw_ped_nurse dadmod_throw_ped_zombiefem dadmod_throw_junk_cone dadmod_throw_junk_dogfood dadmod_throw_junk_hoagie dadmod_throw_junk_skunk dadmod_throw_junk_chest dadmod_throw_junk_pot dadmod_throw_junk_shoebox dadmod_throw_junk_tomato dadmod_throw_junk_apple dadmod_throw_junk_paintcan dadmod_throw_junk_crown dadmod_throw_junk_letter_s dadmod_throw_board dadmod_throw_ball ]
dadmod_throw_cat_label = {
dadmod_throw_car = "Cars"
dadmod_throw_limo = "Cars"
dadmod_throw_truck = "Cars"
dadmod_throw_van = "Cars"
dadmod_throw_hearse = "Cars"
dadmod_throw_bus = "Cars"
dadmod_throw_blimp = "Cars"
dadmod_throw_boat = "Cars"
dadmod_throw_halfpipe = "Cars"
dadmod_throw_anl_dog = "Animals"
dadmod_throw_anl_dog_grey = "Animals"
dadmod_throw_anl_cat = "Animals"
dadmod_throw_anl_pigeon = "Animals"
dadmod_throw_anl_seagull = "Animals"
dadmod_throw_anl_bat = "Animals"
dadmod_throw_anl_parrot = "Animals"
dadmod_throw_anl_bull = "Animals"
dadmod_throw_anl_shark = "Animals"
dadmod_throw_anl_fish = "Animals"
dadmod_throw_anl_eel = "Animals"
dadmod_throw_ped_mime = "Pedestrians"
dadmod_throw_ped_pirate = "Pedestrians"
dadmod_throw_ped_jester = "Pedestrians"
dadmod_throw_ped_natas = "Pedestrians"
dadmod_throw_ped_bigfoot = "Pedestrians"
dadmod_throw_ped_benfranklin = "Pedestrians"
dadmod_throw_ped_zombie = "Pedestrians"
dadmod_throw_ped_boxer = "Pedestrians"
dadmod_throw_ped_wienerman = "Pedestrians"
dadmod_throw_ped_bullfighter = "Pedestrians"
dadmod_throw_ped_lifeguard = "Pedestrians"
dadmod_throw_ped_copaussie = "Pedestrians"
dadmod_throw_ped_germancop = "Pedestrians"
dadmod_throw_ped_alien = "Pedestrians"
dadmod_throw_ped_imp = "Pedestrians"
dadmod_throw_ped_judge = "Pedestrians"
dadmod_throw_ped_nurse = "Pedestrians"
dadmod_throw_ped_zombiefem = "Pedestrians"
dadmod_throw_junk_cone = "Junk"
dadmod_throw_junk_dogfood = "Junk"
dadmod_throw_junk_hoagie = "Junk"
dadmod_throw_junk_skunk = "Junk"
dadmod_throw_junk_chest = "Junk"
dadmod_throw_junk_pot = "Junk"
dadmod_throw_junk_shoebox = "Junk"
dadmod_throw_junk_tomato = "Junk"
dadmod_throw_junk_apple = "Junk"
dadmod_throw_junk_paintcan = "Junk"
dadmod_throw_junk_crown = "Junk"
dadmod_throw_junk_letter_s = "Junk"
dadmod_throw_board = "Skateboards"
dadmod_throw_ball = "Bowling balls"
}
