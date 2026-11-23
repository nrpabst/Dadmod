dadmod_gen03_names = [ IsTrue GotParam ScreenElementExists ]

dadmod_c2_physfix = {
SportsCar = {
mass = 4400
moment_of_inertia = (40000000.0,5600000.0,40000000.0)
suspension_center_of_mass = (0.0,-22.0,30.0)
colliders = [
[
(36.0,26.0,125.0)
(-36.0,26.0,125.0)
(36.0,26.0,-35.0)
]
[
(26.0,44.0,70.0)
(-26.0,44.0,70.0)
(26.0,44.0,0.0)
]
]
body_restitution = 0.2
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.3
max_steering_angle = 38
constant_rotational_damping = 200000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 8
in_air_slerp_time_delay = 0.3
engine = {
drive_torque = 600
drag_torque = 600
upshift_rpm = 6000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [ 4.2 3 1.8 0.9 0 ]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 455
damping_rate = 60
static_friction = 2.6
min_static_grip_velocity = 4
max_static_grip_velocity = 8
min_dynamic_grip_velocity = 18
handbrake_torque = 4000
brake_torque = 2930
}
Wheels = [
{
max_draw_y_offset = -25
steering = left
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -25
steering = right
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
]
}
}

script dadmod_cars_extra_items
    dadmod_cars_item_x t = "Hearse" c = dadmod_car_hearse
    dadmod_cars_item_x t = "Woodie Wagon" c = dadmod_car_woodie
    dadmod_cars_item_x t = "Sedan" c = dadmod_car_sedan
    dadmod_cars_item_x t = "Smart Car" c = dadmod_car_smart
    dadmod_cars_item_x t = "Hippie Van" c = dadmod_car_hippyvan
    dadmod_cars_item_x t = "Delivery Van" c = dadmod_car_benzvan
    dadmod_cars_item_x t = "Minivan" c = dadmod_car_minivan
    dadmod_cars_item_x t = "Old Van" c = dadmod_car_oldvan
    dadmod_cars_item_x t = "SUV" c = dadmod_car_suv
    dadmod_cars_item_x t = "Rust Bucket" c = dadmod_car_rust
    dadmod_cars_item_x t = "Liberty" c = dadmod_car_liberty
    dadmod_cars_item_x t = "Barcelona Taxi" c = dadmod_car_bcntaxi
    dadmod_cars_item_x t = "Neon" c = dadmod_car_neon
    dadmod_cars_item_x t = "Box Truck" c = dadmod_car_dctruck
    dadmod_cars_item_x t = "Tour Bus" c = dadmod_car_tourbus
    dadmod_cars_item_x t = "ATV" c = dadmod_car_atv
    dadmod_cars_item_x t = "Parade Float" c = dadmod_car_mardi
    dadmod_cars_item_x t = "Duck Boat" c = dadmod_car_duck
    dadmod_cars_item_x t = "Submarine" c = dadmod_car_sub
    dadmod_cars_item_x t = "Streetcar" c = dadmod_car_streetcar
endscript

script dadmod_cars_prop_items
    dadmod_cars_item_x t = "Traffic Cone" c = dadmod_prop_cone
    dadmod_cars_item_x t = "Shopping Cart" c = dadmod_prop_cart
    dadmod_cars_item_x t = "Scooter" c = dadmod_prop_scooter
    dadmod_cars_item_x t = "Small Robot" c = dadmod_prop_robot
    dadmod_cars_item_x t = "Robot 2" c = dadmod_prop_robot2
    dadmod_cars_item_x t = "Treasure Chest" c = dadmod_prop_chest
    dadmod_cars_item_x t = "Copper Bike" c = dadmod_prop_bike
    dadmod_cars_item_x t = "Mini Car" c = dadmod_prop_mini
    dadmod_cars_item_x t = "Half Pipe" c = dadmod_prop_halfpipe
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
    dadmod_throw_item t = "Cars" a = dadmod_throw_cars d = "Throw cars, a different one each time. DadMod players see the car, others a COMBO O"
    dadmod_throw_item t = "Random Animal" a = dadmod_throw_animals d = "Throw animals, a different one each time. Others see a COMBO O"
    dadmod_throw_item t = "Random Pedestrian" a = dadmod_throw_peds d = "Throw people, a different one each time. Others see a COMBO O"
    dadmod_throw_item t = "Random Junk" a = dadmod_throw_junk d = "Throw junk, a different thing each time. Others see a COMBO O"
    dadmod_throw_item t = "Skateboard" a = dadmod_throw_board d = "Throw skateboards. DadMod players see the board, others a COMBO O"
    dadmod_throw_item t = "Bowling Ball" a = dadmod_throw_ball d = "Throw a heavy ball. DadMod players see it, others a COMBO O"
    dadmod_throw_item t = "Mystery Box" a = dadmod_throw_mystery d = "Every throw is a surprise: cars, animals, people, junk. Others see a COMBO O"
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

script dadmod_lamplights_level
    if GotParam level
        THUGRECOMP_LampBulbsClear level = <level>
    else
        THUGRECOMP_LampBulbsClear
    endif
    keep = 1
    if GotParam game
        if ( ( <game> = THPS1 ) or ( <game> = THPS2 ) or ( <game> = THPS3 ) or ( <game> = THPS4 ) )
            keep = 0
        endif
    endif
    THUGRECOMP_SettingSave key = "gfx_keeplit" value = <keep>
    KillSpawnedScript Name = dadmod_lamp_night
    if GotParam level
        if ScriptExists dadmod_lampedit_level_hook
            dadmod_lampedit_level_hook level = <level>
        endif
        FormatText ChecksumName = list "dadmod_lamps_%s" s = <level>
        if GlobalExists Name = <list> Type = array
            THUGRECOMP_SettingLoad key = "gfx_lampreach"
            ForEachIn <list> Do = dadmod_lamp_add params = { level = <level> reachset = <value> }
            THUGRECOMP_Log text = "lamplights: lamps added for this level"
            SpawnScript dadmod_lamp_night params = { list = <list> level = <level> }
        endif
    endif
endscript

script dadmod_lamp_add
    post = 0
    if GotParam model
        post = 1
    endif
    ForEachIn <bulbs> Do = dadmod_lamp_bulb params = { post = <post> }
    THUGRECOMP_LampBulb Pos = <pool> pool = <poolr> drop = 0 r = 0 g = 0 b = 0 post = <post>
    FormatText ChecksumName = nm "dadmod_ll_%s_%d" s = <level> d = <id>
    THUGRECOMP_AddLevelLight Name = <nm> Pos = <light> Brightness = 0.0 InnerRadius = ( <reachset> * 0.5 ) OuterRadius = ( <reachset> * 1.0 ) color = [ 255 150 50 ] ExcludeSkater
    if GotParam model
        if ScriptExists dadmod_lampedit_ship
            dadmod_lampedit_ship model = <model> model_pos = <model_pos> model_rot = <model_rot>
        endif
    endif
endscript

script dadmod_lamp_bulb
    THUGRECOMP_LampBulb Pos = <Pos> pool = 0 drop = 0 post = <post>
endscript

script dadmod_lamp_night
    lampon = 0
    lamppo = 1
    THUGRECOMP_SettingLoad key = "gfx_lampreach"
    lastreach = <value>
    begin
        THUGRECOMP_SettingLoad key = "gfx_lampreach"
        if not ( <value> = <lastreach> )
            <lastreach> = <value>
            ForEachIn <list> Do = dadmod_lamp_reach params = { level = <level> reachset = <value> }
        endif
        THUGRECOMP_LampNight
        THUGRECOMP_SettingLoad key = "gfx_lamplights"
        newon = ( <night> * <value> )
        THUGRECOMP_SettingLoad key = "gfx_lampposts"
        newpo = <value>
        dochange = 0
        if not ( <newon> = <lampon> )
            dochange = 1
        endif
        if not ( <newpo> = <lamppo> )
            dochange = 1
        endif
        if ( <dochange> = 1 )
            <lampstep> = 1
            begin
                frac = ( <lampstep> * 0.05 )
                ForEachIn <list> Do = dadmod_lamp_pct params = { level = <level> frac = <frac> a0 = <lampon> a1 = <newon> p0 = <lamppo> p1 = <newpo> }
                <lampstep> = ( <lampstep> + 1 )
                if ( <lampstep> > 20 )
                    break
                endif
                wait 0.15 seconds
            repeat
            lampon = <newon>
            lamppo = <newpo>
        endif
        wait 0.5 seconds
    repeat
endscript

script dadmod_lamp_pct
    t0 = <a0>
    t1 = <a1>
    if GotParam model
        t0 = ( <a0> * <p0> )
        t1 = ( <a1> * <p1> )
    endif
    dt = ( <t1> - <t0> )
    pct = ( ( <t0> + <dt> * <frac> ) * 100.0 )
    FormatText ChecksumName = nm "dadmod_ll_%s_%d" s = <level> d = <id>
    FakeLights id = <nm> Percent = <pct>
endscript

script dadmod_lamp_reach
    FormatText ChecksumName = nm "dadmod_ll_%s_%d" s = <level> d = <id>
    FakeLights id = <nm> outer_radius = ( <reachset> * 1.0 )
endscript

dadmod_lamps_hof = [
{ id = 1 light = (-2472.0,610.2,495.6) reach = 917.0 pool = (-2472.0,208.9,495.6) poolr = 517 bulbs = [ { Pos = (-2611.3,651.8,498.1) } { Pos = (-2332.9,655.4,498.7) } ] }
{ id = 2 light = (-2473.9,610.2,-2939.8) reach = 917.0 pool = (-2473.9,208.9,-2939.8) poolr = 517 bulbs = [ { Pos = (-2613.2,651.8,-2937.2) } { Pos = (-2334.8,655.4,-2936.7) } ] }
{ id = 3 light = (-2959.9,610.2,-4042.4) reach = 917.0 pool = (-2959.9,208.9,-4042.4) poolr = 517 bulbs = [ { Pos = (-3099.2,651.8,-4039.9) } { Pos = (-2820.8,655.4,-4039.3) } ] }
{ id = 4 light = (-2473.9,610.2,-4940.6) reach = 917.0 pool = (-2473.9,208.9,-4940.6) poolr = 517 bulbs = [ { Pos = (-2616.8,651.8,-4937.6) } { Pos = (-2332.2,655.4,-4936.9) } ] }
{ id = 5 light = (-2472.0,610.2,-903.3) reach = 917.0 pool = (-2472.0,208.9,-903.3) poolr = 517 bulbs = [ { Pos = (-2611.7,651.8,-895.5) } { Pos = (-2332.3,655.4,-894.5) } ] }
{ id = 6 light = (-2958.0,610.2,1393.7) reach = 917.0 pool = (-2958.0,208.9,1393.7) poolr = 517 bulbs = [ { Pos = (-3097.3,651.8,1396.3) } { Pos = (-2818.9,655.4,1396.8) } ] }
{ id = 7 light = (-2958.0,610.2,-2365.0) reach = 917.0 pool = (-2958.0,208.9,-2365.0) poolr = 517 bulbs = [ { Pos = (-3100.9,651.8,-2362.0) } { Pos = (-2816.3,655.4,-2361.3) } ] }
{ id = 8 light = (3493.8,610.2,-5518.4) reach = 917.0 pool = (3493.8,208.9,-5518.4) poolr = 517 bulbs = [ { Pos = (3491.2,651.8,-5657.7) } { Pos = (3490.2,655.4,-5379.1) } ] }
{ id = 9 light = (2595.6,610.2,-5032.4) reach = 917.0 pool = (2595.6,208.9,-5032.4) poolr = 517 bulbs = [ { Pos = (2593.0,651.8,-5171.7) } { Pos = (2592.1,655.4,-4893.2) } ] }
{ id = 10 light = (1697.5,610.2,-5518.4) reach = 917.0 pool = (1697.5,208.9,-5518.4) poolr = 517 bulbs = [ { Pos = (1694.9,651.8,-5657.7) } { Pos = (1693.9,655.4,-5379.1) } ] }
{ id = 11 light = (790.0,610.2,-5032.4) reach = 917.0 pool = (790.0,208.9,-5032.4) poolr = 517 bulbs = [ { Pos = (787.4,651.8,-5171.7) } { Pos = (786.4,655.4,-4893.2) } ] }
{ id = 12 light = (-108.2,610.2,-5518.4) reach = 917.0 pool = (-108.2,208.9,-5518.4) poolr = 517 bulbs = [ { Pos = (-110.8,651.8,-5657.7) } { Pos = (-111.7,655.4,-5379.1) } ] }
{ id = 13 light = (-1825.8,610.2,-5518.4) reach = 917.0 pool = (-1825.8,208.9,-5518.4) poolr = 517 bulbs = [ { Pos = (-1828.3,651.8,-5657.7) } { Pos = (-1829.3,655.4,-5379.1) } ] }
{ id = 14 light = (-932.6,610.2,-5032.4) reach = 917.0 pool = (-932.6,208.9,-5032.4) poolr = 517 bulbs = [ { Pos = (-930.2,651.8,-5171.7) } { Pos = (-931.1,655.4,-4893.2) } ] }
{ id = 15 light = (2507.0,610.2,2989.9) reach = 917.0 pool = (2507.0,208.9,2989.9) poolr = 517 bulbs = [ { Pos = (2510.0,651.8,3132.8) } { Pos = (2510.7,655.4,2848.2) } ] }
{ id = 16 light = (1838.0,610.2,4034.3) reach = 917.0 pool = (1838.0,208.9,4034.3) poolr = 517 bulbs = [ { Pos = (1941.1,651.8,4133.3) } { Pos = (1740.4,655.4,3931.5) } ] }
{ id = 17 light = (693.2,610.2,4486.1) reach = 917.0 pool = (693.2,208.9,4486.1) poolr = 517 bulbs = [ { Pos = (793.9,651.8,4583.0) } { Pos = (597.0,655.4,4384.8) } ] }
{ id = 18 light = (1609.1,610.2,5782.0) reach = 917.0 pool = (1609.1,208.9,5782.0) poolr = 517 bulbs = [ { Pos = (1611.7,651.8,5921.7) } { Pos = (1612.7,655.4,5642.3) } ] }
{ id = 19 light = (2507.1,610.2,5289.6) reach = 917.0 pool = (2507.1,208.9,5289.6) poolr = 517 bulbs = [ { Pos = (2509.7,651.8,5429.3) } { Pos = (2510.7,655.4,5149.9) } ] }
{ id = 20 light = (3405.3,610.2,5781.9) reach = 917.0 pool = (3405.3,208.9,5781.9) poolr = 517 bulbs = [ { Pos = (3407.9,651.8,5921.6) } { Pos = (3408.9,655.4,5642.2) } ] }
{ id = 21 light = (3710.7,610.2,5176.5) reach = 917.0 pool = (3710.7,208.9,5176.5) poolr = 517 bulbs = [ { Pos = (3850.4,651.8,5173.9) } { Pos = (3571.0,655.4,5172.9) } ] }
{ id = 22 light = (4201.6,610.2,4391.7) reach = 917.0 pool = (4201.6,208.9,4391.7) poolr = 517 bulbs = [ { Pos = (4340.8,651.8,4389.1) } { Pos = (4062.4,655.4,4388.6) } ] }
{ id = 23 light = (3694.7,610.2,3577.3) reach = 917.0 pool = (3694.7,208.9,3577.3) poolr = 517 bulbs = [ { Pos = (3834.4,651.8,3574.7) } { Pos = (3555.0,655.4,3573.7) } ] }
{ id = 24 light = (3711.5,610.2,-4076.5) reach = 917.0 pool = (3711.5,208.9,-4076.5) poolr = 517 bulbs = [ { Pos = (3850.8,651.8,-4079.1) } { Pos = (3572.4,655.4,-4079.7) } ] }
{ id = 25 light = (3713.4,610.2,-2116.3) reach = 917.0 pool = (3713.4,208.9,-2116.3) poolr = 517 bulbs = [ { Pos = (3852.7,651.8,-2118.9) } { Pos = (3574.3,655.4,-2119.4) } ] }
{ id = 26 light = (3713.4,610.2,-320.0) reach = 917.0 pool = (3713.4,208.9,-320.0) poolr = 517 bulbs = [ { Pos = (3852.7,651.8,-322.6) } { Pos = (3574.3,655.4,-323.1) } ] }
{ id = 27 light = (4197.5,610.2,-3178.4) reach = 917.0 pool = (4197.5,208.9,-3178.4) poolr = 517 bulbs = [ { Pos = (4336.8,651.8,-3180.9) } { Pos = (4058.4,655.4,-3181.5) } ] }
{ id = 28 light = (4199.4,610.2,-1218.2) reach = 917.0 pool = (4199.4,208.9,-1218.2) poolr = 517 bulbs = [ { Pos = (4338.6,651.8,-1220.7) } { Pos = (4060.2,655.4,-1221.3) } ] }
{ id = 29 light = (-1699.1,610.2,1725.5) reach = 917.0 pool = (-1699.1,208.9,1725.5) poolr = 517 bulbs = [ { Pos = (-1696.5,651.8,1864.8) } { Pos = (-1696.0,655.4,1586.4) } ] }
{ id = 30 light = (-2597.2,610.2,2211.4) reach = 917.0 pool = (-2597.2,208.9,2211.4) poolr = 517 bulbs = [ { Pos = (-2594.7,651.8,2350.8) } { Pos = (-2594.1,655.4,2072.3) } ] }
{ id = 31 light = (2507.5,610.2,0.1) reach = 917.0 pool = (2507.5,208.9,0.1) poolr = 517 bulbs = [ { Pos = (2510.0,651.8,139.4) } { Pos = (2510.6,655.4,-139.0) } ] }
{ id = 32 light = (1609.3,610.2,486.1) reach = 917.0 pool = (1609.3,208.9,486.1) poolr = 517 bulbs = [ { Pos = (1611.9,651.8,625.3) } { Pos = (1612.4,655.4,346.9) } ] }
{ id = 33 light = (810.8,610.2,223.2) reach = 917.0 pool = (810.8,208.9,223.2) poolr = 517 bulbs = [ { Pos = (911.1,651.8,319.9) } { Pos = (714.6,655.4,122.6) } ] }
{ id = 34 light = (520.8,610.2,1201.7) reach = 917.0 pool = (520.8,208.9,1201.7) poolr = 517 bulbs = [ { Pos = (621.0,651.8,1298.4) } { Pos = (424.6,655.4,1101.2) } ] }
{ id = 35 light = (-458.0,610.2,1493.2) reach = 917.0 pool = (-458.0,208.9,1493.2) poolr = 517 bulbs = [ { Pos = (-357.7,651.8,1589.8) } { Pos = (-554.1,655.4,1392.6) } ] }
{ id = 36 light = (3402.3,610.2,484.6) reach = 917.0 pool = (3402.3,208.9,484.6) poolr = 517 bulbs = [ { Pos = (3405.2,651.8,627.5) } { Pos = (3405.9,655.4,342.9) } ] }
{ id = 37 light = (-800.9,610.2,2211.4) reach = 917.0 pool = (-800.9,208.9,2211.4) poolr = 517 bulbs = [ { Pos = (-797.9,651.8,2354.4) } { Pos = (-797.3,655.4,2069.8) } ] }
{ id = 1001 light = (73.8,349.5,-1339.5) reach = 521.6 pool = (73.8,211.8,-1339.5) poolr = 450 bulbs = [ { Pos = (73.8,409.5,-1339.5) } ] model = "SF2:4d8f0345" model_pos = (73.8,61.8,-1339.4) model_rot = 15.0 }
{ id = 1002 light = (214.4,312.6,-572.8) reach = 466.4 pool = (214.4,211.7,-572.8) poolr = 450 bulbs = [ { Pos = (214.4,372.6,-572.8) } ] model = "SCH:84d7e95d" model_pos = (290.6,61.7,-528.7) model_rot = 510.0 }
{ id = 1003 light = (-791.4,202.8,-280.2) reach = 350.0 pool = (-791.4,427.9,-280.2) poolr = 450 bulbs = [ { Pos = (-791.4,262.8,-280.2) } ] model = "SCH:84d7e95d" model_pos = (-791.5,-48.1,-192.1) model_rot = 450.0 }
{ id = 1004 light = (-2094.5,202.8,-292.5) reach = 350.0 pool = (-2094.5,427.9,-292.5) poolr = 450 bulbs = [ { Pos = (-2094.5,262.8,-292.5) } ] model = "SCH:84d7e95d" model_pos = (-2094.6,-48.1,-204.4) model_rot = 450.0 }
{ id = 1005 light = (-1392.8,198.8,-275.4) reach = 350.0 pool = (-1392.8,427.9,-275.4) poolr = 450 bulbs = [ { Pos = (-1392.8,258.8,-275.4) } ] model = "SCH:84d7e95d" model_pos = (-1392.9,-52.1,-187.3) model_rot = 450.0 }
{ id = 1006 light = (-150.0,349.4,-2496.9) reach = 521.6 pool = (-150.0,211.7,-2496.9) poolr = 450 bulbs = [ { Pos = (-150.0,409.4,-2496.9) } ] model = "SF2:4d8f0345" model_pos = (-150.0,61.7,-2496.8) model_rot = 1440.0 }
{ id = 1007 light = (-1663.6,811.8,-1330.4) reach = 697.5 pool = (-1663.6,556.8,-1330.4) poolr = 450 bulbs = [ { Pos = (-1663.6,871.8,-1330.4) } ] model = "Z_HO:06f66a45" model_pos = (-1813.3,406.8,-1327.7) model_rot = 0.0 }
{ id = 1008 light = (-1719.9,811.8,-2296.3) reach = 697.5 pool = (-1719.9,556.8,-2296.3) poolr = 450 bulbs = [ { Pos = (-1719.9,871.8,-2296.3) } ] model = "Z_HO:06f66a45" model_pos = (-1869.6,406.8,-2293.6) model_rot = 0.0 }
{ id = 1009 light = (-1046.0,811.8,-1329.4) reach = 697.5 pool = (-1046.0,556.8,-1329.4) poolr = 450 bulbs = [ { Pos = (-1046.0,871.8,-1329.4) } ] model = "Z_HO:06f66a45" model_pos = (-896.3,406.8,-1332.1) model_rot = 180.0 }
{ id = 1010 light = (-1063.6,811.8,-2282.7) reach = 697.5 pool = (-1063.6,556.8,-2282.7) poolr = 450 bulbs = [ { Pos = (-1063.6,871.8,-2282.7) } ] model = "Z_HO:06f66a45" model_pos = (-913.9,406.8,-2285.4) model_rot = 180.0 }
{ id = 1011 light = (-33.0,512.3,-4657.8) reach = 350.0 pool = (-33.0,556.8,-4657.8) poolr = 450 bulbs = [ { Pos = (-33.0,572.3,-4657.8) } ] model = "TESTLEVEL:78cbbdba" model_pos = (-37.8,406.8,-4658.2) model_rot = 1575.0 }
{ id = 1012 light = (151.8,512.3,-3402.7) reach = 350.0 pool = (151.8,556.8,-3402.7) poolr = 450 bulbs = [ { Pos = (151.8,572.3,-3402.7) } ] model = "TESTLEVEL:78cbbdba" model_pos = (147.0,406.8,-3403.1) model_rot = 1575.0 }
{ id = 1013 light = (-1344.9,345.3,-2709.4) reach = 350.0 pool = (-1344.9,441.8,-2709.4) poolr = 450 bulbs = [ { Pos = (-1344.9,405.3,-2709.4) } ] model = "TESTLEVEL:78cbbdba" model_pos = (-1349.7,239.8,-2709.8) model_rot = 1575.0 }
{ id = 1014 light = (-2721.1,-79.9,2658.4) reach = 350.0 pool = (-2721.1,-20.9,2658.4) poolr = 450 bulbs = [ { Pos = (-2721.1,-19.9,2658.4) } ] model = "SF2:e2885a9f" model_pos = (-2721.0,-170.9,2658.4) model_rot = 0.0 }
{ id = 1015 light = (-1090.7,-79.9,2634.3) reach = 350.0 pool = (-1090.7,-20.9,2634.3) poolr = 450 bulbs = [ { Pos = (-1090.7,-19.9,2634.3) } ] model = "SF2:e2885a9f" model_pos = (-1090.6,-170.9,2634.3) model_rot = 0.0 }
{ id = 1016 light = (-1809.2,-79.9,2644.7) reach = 350.0 pool = (-1809.2,-20.9,2644.7) poolr = 450 bulbs = [ { Pos = (-1809.2,-19.9,2644.7) } ] model = "SF2:e2885a9f" model_pos = (-1809.1,-170.9,2644.7) model_rot = 0.0 }
{ id = 1017 light = (-254.0,-79.9,2510.1) reach = 350.0 pool = (-254.0,-20.9,2510.1) poolr = 450 bulbs = [ { Pos = (-254.0,-19.9,2510.1) } ] model = "SF2:e2885a9f" model_pos = (-253.9,-170.9,2510.1) model_rot = 0.0 }
{ id = 1018 light = (270.3,-79.9,2081.3) reach = 350.0 pool = (270.3,-20.9,2081.3) poolr = 450 bulbs = [ { Pos = (270.3,-19.9,2081.3) } ] model = "SF2:e2885a9f" model_pos = (270.4,-170.9,2081.3) model_rot = 0.0 }
{ id = 1019 light = (889.7,-79.9,1436.7) reach = 350.0 pool = (889.7,-20.9,1436.7) poolr = 450 bulbs = [ { Pos = (889.7,-19.9,1436.7) } ] model = "SF2:e2885a9f" model_pos = (889.8,-170.9,1436.7) model_rot = 0.0 }
{ id = 1020 light = (1500.8,-79.8,914.0) reach = 350.0 pool = (1500.8,-20.8,914.0) poolr = 450 bulbs = [ { Pos = (1500.8,-19.8,914.0) } ] model = "SF2:e2885a9f" model_pos = (1500.9,-170.8,914.0) model_rot = 0.0 }
{ id = 1021 light = (3026.9,-79.9,950.6) reach = 350.0 pool = (3026.9,-20.9,950.6) poolr = 450 bulbs = [ { Pos = (3026.9,-19.9,950.6) } ] model = "SF2:e2885a9f" model_pos = (3027.0,-170.9,950.6) model_rot = 0.0 }
{ id = 1022 light = (2336.2,-79.9,917.7) reach = 350.0 pool = (2336.2,-20.9,917.7) poolr = 450 bulbs = [ { Pos = (2336.2,-19.9,917.7) } ] model = "SF2:e2885a9f" model_pos = (2336.3,-170.9,917.7) model_rot = 0.0 }
{ id = 1023 light = (1193.2,310.1,-2148.7) reach = 350.0 pool = (1193.2,369.1,-2148.7) poolr = 450 bulbs = [ { Pos = (1193.2,370.1,-2148.7) } ] model = "SF2:e2885a9f" model_pos = (1193.3,219.1,-2148.7) model_rot = 0.0 }
{ id = 1024 light = (1864.2,180.2,-2154.7) reach = 350.0 pool = (1864.2,239.2,-2154.7) poolr = 450 bulbs = [ { Pos = (1864.2,240.2,-2154.7) } ] model = "SF2:e2885a9f" model_pos = (1864.3,89.2,-2154.7) model_rot = 0.0 }
{ id = 1025 light = (789.0,272.5,-2151.8) reach = 350.0 pool = (789.0,331.5,-2151.8) poolr = 450 bulbs = [ { Pos = (789.0,332.5,-2151.8) } ] model = "SF2:e2885a9f" model_pos = (789.1,181.5,-2151.8) model_rot = 0.0 }
{ id = 1026 light = (1425.7,469.0,-3286.6) reach = 521.6 pool = (1425.7,331.3,-3286.6) poolr = 450 bulbs = [ { Pos = (1425.7,529.0,-3286.6) } ] model = "SF2:4d8f0345" model_pos = (1425.7,181.3,-3286.5) model_rot = 0.0 }
{ id = 1027 light = (1434.4,469.0,-3930.6) reach = 521.6 pool = (1434.4,331.3,-3930.6) poolr = 450 bulbs = [ { Pos = (1434.4,529.0,-3930.6) } ] model = "SF2:4d8f0345" model_pos = (1434.4,181.3,-3930.5) model_rot = 0.0 }
{ id = 1028 light = (1013.6,390.2,-6311.7) reach = 506.7 pool = (1013.6,262.4,-6311.7) poolr = 450 bulbs = [ { Pos = (1013.6,450.2,-6311.7) } ] model = "SF2:8ea802b5" model_pos = (1009.8,112.4,-6311.7) model_rot = 0.0 }
{ id = 1029 light = (1712.9,390.2,-6310.8) reach = 506.7 pool = (1712.9,262.4,-6310.8) poolr = 450 bulbs = [ { Pos = (1712.9,450.2,-6310.8) } ] model = "SF2:8ea802b5" model_pos = (1716.7,112.4,-6310.8) model_rot = 180.0 }
{ id = 1030 light = (4121.6,447.8,-6358.9) reach = 506.7 pool = (4121.6,320.0,-6358.9) poolr = 450 bulbs = [ { Pos = (4121.6,507.8,-6358.9) } ] model = "SF2:8ea802b5" model_pos = (4125.4,170.0,-6358.9) model_rot = 540.0 }
{ id = 1031 light = (3443.3,447.2,-6361.1) reach = 506.7 pool = (3443.3,319.4,-6361.1) poolr = 450 bulbs = [ { Pos = (3443.3,507.2,-6361.1) } ] model = "SF2:8ea802b5" model_pos = (3439.5,169.4,-6361.1) model_rot = 720.0 }
{ id = 1032 light = (5455.2,404.7,-6700.5) reach = 466.4 pool = (5455.2,303.8,-6700.5) poolr = 450 bulbs = [ { Pos = (5455.2,464.7,-6700.5) } ] model = "SCH:84d7e95d" model_pos = (5455.3,153.8,-6788.6) model_rot = 270.0 }
{ id = 1033 light = (5665.7,404.7,-4988.8) reach = 466.4 pool = (5665.7,303.8,-4988.8) poolr = 450 bulbs = [ { Pos = (5665.7,464.7,-4988.8) } ] model = "SCH:84d7e95d" model_pos = (5665.6,153.8,-4900.7) model_rot = 450.0 }
{ id = 1034 light = (4333.9,552.7,-6494.7) reach = 466.4 pool = (4333.9,451.8,-6494.7) poolr = 450 bulbs = [ { Pos = (4333.9,612.7,-6494.7) } ] model = "SCH:84d7e95d" model_pos = (4334.0,301.8,-6582.8) model_rot = 630.0 }
{ id = 1035 light = (4969.3,552.7,-6488.0) reach = 466.4 pool = (4969.3,451.8,-6488.0) poolr = 450 bulbs = [ { Pos = (4969.3,612.7,-6488.0) } ] model = "SCH:84d7e95d" model_pos = (4969.4,301.8,-6576.1) model_rot = 630.0 }
{ id = 1036 light = (3127.4,552.7,-6281.8) reach = 466.4 pool = (3127.4,451.8,-6281.8) poolr = 450 bulbs = [ { Pos = (3127.4,612.7,-6281.8) } ] model = "SCH:84d7e95d" model_pos = (3127.5,301.8,-6369.9) model_rot = 630.0 }
{ id = 1037 light = (2273.7,552.7,-6248.7) reach = 466.4 pool = (2273.7,451.8,-6248.7) poolr = 450 bulbs = [ { Pos = (2273.7,612.7,-6248.7) } ] model = "SCH:84d7e95d" model_pos = (2273.8,301.8,-6336.8) model_rot = 630.0 }
{ id = 1038 light = (5142.9,496.7,-4595.9) reach = 466.4 pool = (5142.9,395.8,-4595.9) poolr = 450 bulbs = [ { Pos = (5142.9,556.7,-4595.9) } ] model = "SCH:84d7e95d" model_pos = (5231.0,245.8,-4595.8) model_rot = 900.0 }
{ id = 1039 light = (5151.2,722.7,-3212.4) reach = 466.4 pool = (5151.2,621.8,-3212.4) poolr = 450 bulbs = [ { Pos = (5151.2,782.7,-3212.4) } ] model = "SCH:84d7e95d" model_pos = (5239.3,471.8,-3212.3) model_rot = 900.0 }
{ id = 1040 light = (4633.3,361.4,-5550.9) reach = 539.4 pool = (4633.3,211.8,-5550.9) poolr = 450 bulbs = [ { Pos = (4633.3,421.4,-5550.9) } ] model = "BO:1dce954a" model_pos = (4753.6,61.8,-5620.1) model_rot = 570.0 }
{ id = 1041 light = (4872.5,295.6,-3894.5) reach = 440.7 pool = (4872.5,211.8,-3894.5) poolr = 450 bulbs = [ { Pos = (4920.0,355.6,-3894.5) } { Pos = (4824.9,355.6,-3894.5) } ] model = "HI:b204f78c" model_pos = (4872.4,61.8,-3894.2) model_rot = 1260.0 }
{ id = 1042 light = (4661.2,149.9,-4304.7) reach = 350.0 pool = (4661.2,208.9,-4304.7) poolr = 450 bulbs = [ { Pos = (4661.2,209.9,-4304.7) } ] model = "SF2:e2885a9f" model_pos = (4661.3,58.9,-4304.7) model_rot = 0.0 }
{ id = 1043 light = (4647.7,149.9,-3840.0) reach = 350.0 pool = (4647.7,208.9,-3840.0) poolr = 450 bulbs = [ { Pos = (4647.7,209.9,-3840.0) } ] model = "SF2:e2885a9f" model_pos = (4647.8,58.9,-3840.0) model_rot = 0.0 }
{ id = 1044 light = (2285.3,309.8,-1687.6) reach = 466.4 pool = (2285.3,208.9,-1687.6) poolr = 450 bulbs = [ { Pos = (2285.3,369.8,-1687.6) } ] model = "SCH:84d7e95d" model_pos = (2373.4,58.9,-1687.5) model_rot = 180.0 }
{ id = 1045 light = (2287.4,309.8,-1133.5) reach = 466.4 pool = (2287.4,208.9,-1133.5) poolr = 450 bulbs = [ { Pos = (2287.4,369.8,-1133.5) } ] model = "SCH:84d7e95d" model_pos = (2375.5,58.9,-1133.4) model_rot = 180.0 }
{ id = 1046 light = (2294.9,309.8,-590.9) reach = 466.4 pool = (2294.9,208.9,-590.9) poolr = 450 bulbs = [ { Pos = (2294.9,369.8,-590.9) } ] model = "SCH:84d7e95d" model_pos = (2383.0,58.9,-590.8) model_rot = 180.0 }
{ id = 1047 light = (1967.7,309.8,-1167.0) reach = 466.4 pool = (1967.7,208.9,-1167.0) poolr = 450 bulbs = [ { Pos = (1967.7,369.8,-1167.0) } ] model = "SCH:84d7e95d" model_pos = (1882.6,58.9,-1189.9) model_rot = 345.0 }
{ id = 1048 light = (1313.9,447.8,-559.1) reach = 466.4 pool = (1313.9,346.9,-559.1) poolr = 450 bulbs = [ { Pos = (1313.9,507.8,-559.1) } ] model = "SCH:84d7e95d" model_pos = (1314.0,196.9,-647.2) model_rot = 630.0 }
{ id = 1049 light = (4431.1,361.4,174.8) reach = 539.4 pool = (4431.1,211.8,174.8) poolr = 450 bulbs = [ { Pos = (4431.1,421.4,174.8) } ] model = "BO:1dce954a" model_pos = (4569.8,61.8,175.0) model_rot = 180.0 }
{ id = 1050 light = (3467.2,356.6,3818.3) reach = 521.6 pool = (3467.2,218.9,3818.3) poolr = 450 bulbs = [ { Pos = (3467.2,416.6,3818.3) } ] model = "SF2:4d8f0345" model_pos = (3467.2,68.9,3818.2) model_rot = 180.0 }
{ id = 1051 light = (1576.0,303.5,4873.3) reach = 521.6 pool = (1576.0,165.8,4873.3) poolr = 450 bulbs = [ { Pos = (1576.0,363.5,4873.3) } ] model = "SF2:4d8f0345" model_pos = (1576.0,15.8,4873.2) model_rot = 180.0 }
{ id = 1052 light = (4805.5,210.2,6161.9) reach = 350.0 pool = (4805.5,269.2,6161.9) poolr = 450 bulbs = [ { Pos = (4805.5,270.2,6161.9) } ] model = "SF2:e2885a9f" model_pos = (4805.4,119.2,6161.9) model_rot = 180.0 }
{ id = 1053 light = (4826.1,210.2,5481.3) reach = 350.0 pool = (4826.1,269.2,5481.3) poolr = 450 bulbs = [ { Pos = (4826.1,270.2,5481.3) } ] model = "SF2:e2885a9f" model_pos = (4826.0,119.2,5481.3) model_rot = 180.0 }
{ id = 1054 light = (300.9,210.2,4643.3) reach = 350.0 pool = (300.9,269.2,4643.3) poolr = 450 bulbs = [ { Pos = (300.9,270.2,4643.3) } ] model = "SF2:e2885a9f" model_pos = (300.8,119.2,4643.3) model_rot = 180.0 }
{ id = 1055 light = (282.1,210.2,5723.5) reach = 350.0 pool = (282.1,269.2,5723.5) poolr = 450 bulbs = [ { Pos = (282.1,270.2,5723.5) } ] model = "SF2:e2885a9f" model_pos = (282.0,119.2,5723.5) model_rot = 180.0 }
{ id = 1056 light = (293.1,210.2,5174.6) reach = 350.0 pool = (293.1,269.2,5174.6) poolr = 450 bulbs = [ { Pos = (293.1,270.2,5174.6) } ] model = "SF2:e2885a9f" model_pos = (293.0,119.2,5174.6) model_rot = 180.0 }
{ id = 1057 light = (2827.9,152.8,2784.9) reach = 350.0 pool = (2827.9,211.8,2784.9) poolr = 450 bulbs = [ { Pos = (2827.9,212.8,2784.9) } ] model = "SF2:e2885a9f" model_pos = (2827.8,61.8,2784.9) model_rot = 180.0 }
{ id = 1058 light = (1923.0,152.8,3016.7) reach = 350.0 pool = (1923.0,211.8,3016.7) poolr = 450 bulbs = [ { Pos = (1923.0,212.8,3016.7) } ] model = "SF2:e2885a9f" model_pos = (1922.9,61.8,3016.7) model_rot = 180.0 }
{ id = 1059 light = (919.7,152.8,3996.1) reach = 350.0 pool = (919.7,211.8,3996.1) poolr = 450 bulbs = [ { Pos = (919.7,212.8,3996.1) } ] model = "SF2:e2885a9f" model_pos = (919.6,61.8,3996.1) model_rot = 180.0 }
{ id = 1060 light = (3669.5,158.4,1727.8) reach = 350.0 pool = (3669.5,217.4,1727.8) poolr = 450 bulbs = [ { Pos = (3669.5,218.4,1727.8) } ] model = "SF2:e2885a9f" model_pos = (3669.6,67.4,1727.8) model_rot = 0.0 }
{ id = 1061 light = (4254.0,152.7,1743.4) reach = 350.0 pool = (4254.0,211.7,1743.4) poolr = 450 bulbs = [ { Pos = (4254.0,212.7,1743.4) } ] model = "SF2:e2885a9f" model_pos = (4254.1,61.7,1743.4) model_rot = 0.0 }
{ id = 1062 light = (3662.8,152.8,2506.3) reach = 350.0 pool = (3662.8,211.8,2506.3) poolr = 450 bulbs = [ { Pos = (3662.8,212.8,2506.3) } ] model = "SF2:e2885a9f" model_pos = (3662.9,61.8,2506.3) model_rot = 0.0 }
{ id = 1063 light = (4240.4,152.8,2494.0) reach = 350.0 pool = (4240.4,211.8,2494.0) poolr = 450 bulbs = [ { Pos = (4240.4,212.8,2494.0) } ] model = "SF2:e2885a9f" model_pos = (4240.5,61.8,2494.0) model_rot = 0.0 }
{ id = 1064 light = (4241.1,152.8,987.1) reach = 350.0 pool = (4241.1,211.8,987.1) poolr = 450 bulbs = [ { Pos = (4241.1,212.8,987.1) } ] model = "SF2:e2885a9f" model_pos = (4241.2,61.8,987.1) model_rot = 0.0 }
{ id = 1065 light = (3680.0,152.8,986.5) reach = 350.0 pool = (3680.0,211.8,986.5) poolr = 450 bulbs = [ { Pos = (3680.0,212.8,986.5) } ] model = "SF2:e2885a9f" model_pos = (3680.1,61.8,986.5) model_rot = 0.0 }
{ id = 1066 light = (4255.6,152.8,1331.0) reach = 350.0 pool = (4255.6,211.8,1331.0) poolr = 450 bulbs = [ { Pos = (4255.6,212.8,1331.0) } ] model = "SF2:e2885a9f" model_pos = (4255.7,61.8,1331.0) model_rot = 0.0 }
{ id = 1067 light = (3673.2,152.8,1324.2) reach = 350.0 pool = (3673.2,211.8,1324.2) poolr = 450 bulbs = [ { Pos = (3673.2,212.8,1324.2) } ] model = "SF2:e2885a9f" model_pos = (3673.3,61.8,1324.2) model_rot = 0.0 }
{ id = 1068 light = (3669.2,152.8,2156.5) reach = 350.0 pool = (3669.2,211.8,2156.5) poolr = 450 bulbs = [ { Pos = (3669.2,212.8,2156.5) } ] model = "SF2:e2885a9f" model_pos = (3669.3,61.8,2156.5) model_rot = 0.0 }
{ id = 1069 light = (4254.0,152.8,2154.8) reach = 350.0 pool = (4254.0,211.8,2154.8) poolr = 450 bulbs = [ { Pos = (4254.0,212.8,2154.8) } ] model = "SF2:e2885a9f" model_pos = (4254.1,61.8,2154.8) model_rot = 0.0 }
{ id = 1070 light = (2919.1,469.0,-3014.4) reach = 521.6 pool = (2919.1,331.3,-3014.4) poolr = 450 bulbs = [ { Pos = (2919.1,529.0,-3014.4) } ] model = "SF2:4d8f0345" model_pos = (2919.1,181.3,-3014.3) model_rot = 0.0 }
{ id = 1071 light = (1761.2,469.0,-2573.1) reach = 521.6 pool = (1761.2,331.3,-2573.1) poolr = 450 bulbs = [ { Pos = (1761.2,529.0,-2573.1) } ] model = "SF2:4d8f0345" model_pos = (1761.2,181.3,-2573.0) model_rot = 0.0 }
{ id = 1072 light = (2863.2,469.0,-4212.9) reach = 521.6 pool = (2863.2,331.3,-4212.9) poolr = 450 bulbs = [ { Pos = (2863.2,529.0,-4212.9) } ] model = "SF2:4d8f0345" model_pos = (2863.2,181.3,-4212.8) model_rot = 0.0 }
{ id = 1073 light = (2426.1,469.0,-4681.1) reach = 521.6 pool = (2426.1,331.3,-4681.1) poolr = 450 bulbs = [ { Pos = (2426.1,529.0,-4681.1) } ] model = "SF2:4d8f0345" model_pos = (2426.1,181.3,-4681.0) model_rot = 0.0 }
{ id = 1074 light = (1696.6,469.0,-4681.2) reach = 521.6 pool = (1696.6,331.3,-4681.2) poolr = 450 bulbs = [ { Pos = (1696.6,529.0,-4681.2) } ] model = "SF2:4d8f0345" model_pos = (1696.6,181.3,-4681.1) model_rot = 0.0 }
{ id = 1075 light = (3178.8,682.2,-3408.1) reach = 466.4 pool = (3178.8,581.3,-3408.1) poolr = 450 bulbs = [ { Pos = (3178.8,742.2,-3408.1) } ] model = "SCH:84d7e95d" model_pos = (3090.7,431.3,-3408.2) model_rot = 0.0 }
{ id = 1076 light = (3201.9,682.2,-3947.1) reach = 466.4 pool = (3201.9,581.3,-3947.1) poolr = 450 bulbs = [ { Pos = (3201.9,742.2,-3947.1) } ] model = "SCH:84d7e95d" model_pos = (3113.8,431.3,-3947.2) model_rot = 0.0 }
{ id = 1077 light = (445.2,240.2,-3342.0) reach = 466.4 pool = (445.2,139.3,-3342.0) poolr = 450 bulbs = [ { Pos = (445.2,300.2,-3342.0) } ] model = "SCH:84d7e95d" model_pos = (357.1,-10.7,-3342.1) model_rot = 0.0 }
{ id = 1078 light = (436.7,240.2,-4025.8) reach = 466.4 pool = (436.7,139.3,-4025.8) poolr = 450 bulbs = [ { Pos = (436.7,300.2,-4025.8) } ] model = "SCH:84d7e95d" model_pos = (348.6,-10.7,-4025.9) model_rot = 0.0 }
{ id = 1079 light = (461.3,240.2,-4701.9) reach = 466.4 pool = (461.3,139.3,-4701.9) poolr = 450 bulbs = [ { Pos = (461.3,300.2,-4701.9) } ] model = "SCH:84d7e95d" model_pos = (373.2,-10.7,-4702.0) model_rot = 0.0 }
{ id = 1080 light = (650.3,434.7,-813.5) reach = 466.4 pool = (650.3,333.8,-813.5) poolr = 450 bulbs = [ { Pos = (650.3,494.7,-813.5) } ] model = "SCH:84d7e95d" model_pos = (738.4,183.8,-813.4) model_rot = 180.0 }
{ id = 1081 light = (653.3,434.7,-1182.8) reach = 466.4 pool = (653.3,333.8,-1182.8) poolr = 450 bulbs = [ { Pos = (653.3,494.7,-1182.8) } ] model = "SCH:84d7e95d" model_pos = (741.4,183.8,-1182.7) model_rot = 180.0 }
{ id = 1082 light = (656.2,434.7,-1550.1) reach = 466.4 pool = (656.2,333.8,-1550.1) poolr = 450 bulbs = [ { Pos = (656.2,494.7,-1550.1) } ] model = "SCH:84d7e95d" model_pos = (744.3,183.8,-1550.0) model_rot = 180.0 }
]

dadmod_lamps_sf2 = [
{ id = 1 light = (687.6,321.4,-712.6) reach = 561.2 pool = (687.6,157.2,-712.6) poolr = 450 bulbs = [ { Pos = (687.5,360.2,-712.6) } ] }
{ id = 2 light = (363.6,321.4,1135.6) reach = 561.2 pool = (363.6,157.2,1135.6) poolr = 450 bulbs = [ { Pos = (363.6,360.2,1135.6) } ] }
{ id = 3 light = (363.6,321.4,3780.7) reach = 561.2 pool = (363.6,157.2,3780.7) poolr = 450 bulbs = [ { Pos = (363.6,360.2,3780.7) } ] }
{ id = 4 light = (687.6,321.4,5628.8) reach = 561.2 pool = (687.6,157.2,5628.8) poolr = 450 bulbs = [ { Pos = (687.5,360.2,5628.8) } ] }
{ id = 5 light = (-1110.2,292.5,3123.5) reach = 482.0 pool = (-1110.2,181.2,3123.5) poolr = 450 bulbs = [ { Pos = (-1110.2,332.9,3123.5) } ] }
{ id = 6 light = (-1110.2,292.5,1789.2) reach = 482.0 pool = (-1110.2,181.2,1789.2) poolr = 450 bulbs = [ { Pos = (-1110.2,332.9,1789.2) } ] }
{ id = 7 light = (-1886.3,130.5,2673.9) reach = 350.0 pool = (-1886.3,131.2,2673.9) poolr = 300 bulbs = [ { Pos = (-1885.9,180.5,2673.7) } ] }
{ id = 8 light = (-1886.3,130.5,2241.9) reach = 350.0 pool = (-1886.3,131.2,2241.9) poolr = 300 bulbs = [ { Pos = (-1885.9,180.5,2241.7) } ] }
{ id = 9 light = (-363.4,321.4,-186.8) reach = 561.2 pool = (-363.4,157.2,-186.8) poolr = 450 bulbs = [ { Pos = (-363.4,360.2,-186.9) } ] }
{ id = 10 light = (-363.4,321.4,1576.6) reach = 561.2 pool = (-363.4,157.2,1576.6) poolr = 450 bulbs = [ { Pos = (-363.4,360.2,1576.5) } ] }
{ id = 11 light = (-363.4,321.4,3340.1) reach = 561.2 pool = (-363.4,157.2,3340.1) poolr = 450 bulbs = [ { Pos = (-363.4,360.2,3339.9) } ] }
{ id = 12 light = (-363.4,321.4,5103.5) reach = 561.2 pool = (-363.4,157.2,5103.5) poolr = 450 bulbs = [ { Pos = (-363.4,360.2,5103.3) } ] }
{ id = 1001 light = (2190.2,264.9,1199.1) reach = 521.6 pool = (2190.2,127.2,1199.1) poolr = 450 bulbs = [ { Pos = (2190.2,324.9,1199.1) } ] model = "SF2:4d8f0345" model_pos = (2190.2,-22.8,1199.2) model_rot = 0.0 }
{ id = 1002 light = (2200.7,264.9,2533.8) reach = 521.6 pool = (2200.7,127.2,2533.8) poolr = 450 bulbs = [ { Pos = (2200.7,324.9,2533.8) } ] model = "SF2:4d8f0345" model_pos = (2200.7,-22.8,2533.9) model_rot = 0.0 }
{ id = 1003 light = (1468.9,264.9,3667.2) reach = 521.6 pool = (1468.9,127.2,3667.2) poolr = 450 bulbs = [ { Pos = (1468.9,324.9,3667.2) } ] model = "SF2:4d8f0345" model_pos = (1468.9,-22.8,3667.3) model_rot = 0.0 }
{ id = 1004 light = (2847.5,264.9,3706.6) reach = 521.6 pool = (2847.5,127.2,3706.6) poolr = 450 bulbs = [ { Pos = (2847.5,324.9,3706.6) } ] model = "SF2:4d8f0345" model_pos = (2847.5,-22.8,3706.7) model_rot = 0.0 }
{ id = 1005 light = (2368.2,264.9,3477.5) reach = 521.6 pool = (2368.2,127.2,3477.5) poolr = 450 bulbs = [ { Pos = (2368.2,324.9,3477.5) } ] model = "SF2:4d8f0345" model_pos = (2368.2,-22.8,3477.6) model_rot = 0.0 }
{ id = 1006 light = (3325.9,98.2,862.2) reach = 350.0 pool = (3325.9,157.2,862.2) poolr = 450 bulbs = [ { Pos = (3325.9,158.2,862.2) } ] model = "SF2:e2885a9f" model_pos = (3326.0,7.2,862.2) model_rot = 0.0 }
{ id = 1007 light = (3154.7,294.9,2042.4) reach = 521.6 pool = (3154.7,157.2,2042.4) poolr = 450 bulbs = [ { Pos = (3154.7,354.9,2042.4) } ] model = "SF2:4d8f0345" model_pos = (3154.7,7.2,2042.5) model_rot = 0.0 }
{ id = 1008 light = (3440.2,98.2,3182.3) reach = 350.0 pool = (3440.2,157.2,3182.3) poolr = 450 bulbs = [ { Pos = (3440.2,158.2,3182.3) } ] model = "SF2:e2885a9f" model_pos = (3440.3,7.2,3182.3) model_rot = 0.0 }
{ id = 1009 light = (2586.8,366.9,5051.5) reach = 521.6 pool = (2586.8,229.2,5051.5) poolr = 450 bulbs = [ { Pos = (2586.8,426.9,5051.5) } ] model = "SF2:4d8f0345" model_pos = (2586.8,79.2,5051.6) model_rot = 0.0 }
{ id = 1010 light = (2719.2,158.2,4694.9) reach = 350.0 pool = (2719.2,217.2,4694.9) poolr = 450 bulbs = [ { Pos = (2719.2,218.2,4694.9) } ] model = "SF2:e2885a9f" model_pos = (2719.3,67.2,4694.9) model_rot = 0.0 }
{ id = 1011 light = (2950.0,158.2,4921.8) reach = 350.0 pool = (2950.0,217.2,4921.8) poolr = 450 bulbs = [ { Pos = (2950.0,218.2,4921.8) } ] model = "SF2:e2885a9f" model_pos = (2950.1,67.2,4921.8) model_rot = 0.0 }
{ id = 1012 light = (2914.0,252.2,4500.6) reach = 350.0 pool = (2914.0,311.2,4500.6) poolr = 450 bulbs = [ { Pos = (2914.0,312.2,4500.6) } ] model = "SF2:e2885a9f" model_pos = (2914.1,161.2,4500.6) model_rot = 0.0 }
{ id = 1013 light = (3141.9,252.2,4733.7) reach = 350.0 pool = (3141.9,311.2,4733.7) poolr = 450 bulbs = [ { Pos = (3141.9,312.2,4733.7) } ] model = "SF2:e2885a9f" model_pos = (3142.0,161.2,4733.7) model_rot = 0.0 }
{ id = 1014 light = (3403.0,252.2,4477.2) reach = 350.0 pool = (3403.0,311.2,4477.2) poolr = 450 bulbs = [ { Pos = (3403.0,312.2,4477.2) } ] model = "SF2:e2885a9f" model_pos = (3403.1,161.2,4477.2) model_rot = 0.0 }
{ id = 1015 light = (3178.0,252.2,4240.8) reach = 350.0 pool = (3178.0,311.2,4240.8) poolr = 450 bulbs = [ { Pos = (3178.0,312.2,4240.8) } ] model = "SF2:e2885a9f" model_pos = (3178.1,161.2,4240.8) model_rot = 0.0 }
{ id = 1016 light = (3456.1,255.7,3961.2) reach = 350.0 pool = (3456.1,314.7,3961.2) poolr = 450 bulbs = [ { Pos = (3456.1,315.7,3961.2) } ] model = "SF2:e2885a9f" model_pos = (3456.2,164.7,3961.2) model_rot = 0.0 }
{ id = 1017 light = (3675.0,255.7,4197.3) reach = 350.0 pool = (3675.0,314.7,4197.3) poolr = 450 bulbs = [ { Pos = (3675.0,315.7,4197.3) } ] model = "SF2:e2885a9f" model_pos = (3675.1,164.7,4197.3) model_rot = 0.0 }
{ id = 1018 light = (3694.5,371.7,3727.3) reach = 350.0 pool = (3694.5,430.7,3727.3) poolr = 450 bulbs = [ { Pos = (3694.5,431.7,3727.3) } ] model = "SF2:e2885a9f" model_pos = (3694.6,280.7,3727.3) model_rot = 0.0 }
{ id = 1019 light = (3915.7,363.7,3944.0) reach = 350.0 pool = (3915.7,422.7,3944.0) poolr = 450 bulbs = [ { Pos = (3915.7,423.7,3944.0) } ] model = "SF2:e2885a9f" model_pos = (3915.8,272.7,3944.0) model_rot = 0.0 }
{ id = 1020 light = (4535.4,532.3,4833.8) reach = 466.4 pool = (4535.4,431.4,4833.8) poolr = 450 bulbs = [ { Pos = (4535.4,592.3,4833.8) } ] model = "SCH:84d7e95d" model_pos = (4597.6,281.4,4896.1) model_rot = 855.0 }
{ id = 1021 light = (4778.6,532.3,4591.7) reach = 466.4 pool = (4778.6,431.4,4591.7) poolr = 450 bulbs = [ { Pos = (4778.6,592.3,4591.7) } ] model = "SCH:84d7e95d" model_pos = (4840.8,281.4,4654.0) model_rot = 855.0 }
{ id = 1022 light = (75.3,337.9,7110.0) reach = 350.0 pool = (75.3,396.9,7110.0) poolr = 450 bulbs = [ { Pos = (75.3,397.9,7110.0) } ] model = "SF2:e2885a9f" model_pos = (75.2,246.9,7109.9) model_rot = 855.0 }
{ id = 1023 light = (611.3,376.2,6582.7) reach = 350.0 pool = (611.3,435.2,6582.7) poolr = 450 bulbs = [ { Pos = (611.3,436.2,6582.7) } ] model = "SF2:e2885a9f" model_pos = (611.2,285.2,6582.6) model_rot = 855.0 }
{ id = 1024 light = (1327.9,416.2,5875.7) reach = 350.0 pool = (1327.9,475.2,5875.7) poolr = 450 bulbs = [ { Pos = (1327.9,476.2,5875.7) } ] model = "SF2:e2885a9f" model_pos = (1327.8,325.2,5875.6) model_rot = 855.0 }
{ id = 1025 light = (2209.3,416.2,5877.1) reach = 350.0 pool = (2209.3,475.2,5877.1) poolr = 450 bulbs = [ { Pos = (2209.3,476.2,5877.1) } ] model = "SF2:e2885a9f" model_pos = (2209.2,325.2,5877.0) model_rot = 855.0 }
{ id = 1026 light = (2936.4,416.2,5845.2) reach = 350.0 pool = (2936.4,475.2,5845.2) poolr = 450 bulbs = [ { Pos = (2936.4,476.2,5845.2) } ] model = "SF2:e2885a9f" model_pos = (2936.3,325.2,5845.1) model_rot = 855.0 }
{ id = 1027 light = (3653.1,395.0,5171.5) reach = 350.0 pool = (3653.1,454.0,5171.5) poolr = 450 bulbs = [ { Pos = (3653.1,455.0,5171.5) } ] model = "SF2:e2885a9f" model_pos = (3653.0,304.0,5171.4) model_rot = 855.0 }
{ id = 1028 light = (4248.2,356.2,4579.1) reach = 350.0 pool = (4248.2,415.2,4579.1) poolr = 450 bulbs = [ { Pos = (4248.2,416.2,4579.1) } ] model = "SF2:e2885a9f" model_pos = (4248.1,265.2,4579.0) model_rot = 855.0 }
{ id = 1029 light = (944.3,401.4,6229.3) reach = 350.0 pool = (944.3,460.4,6229.3) poolr = 450 bulbs = [ { Pos = (944.3,461.4,6229.3) } ] model = "SF2:e2885a9f" model_pos = (944.2,310.4,6229.2) model_rot = 855.0 }
{ id = 1030 light = (3654.2,356.2,2049.6) reach = 350.0 pool = (3654.2,415.2,2049.6) poolr = 450 bulbs = [ { Pos = (3654.2,416.2,2049.6) } ] model = "SF2:e2885a9f" model_pos = (3654.3,265.2,2049.6) model_rot = 0.0 }
{ id = 1031 light = (3581.3,356.2,3139.7) reach = 350.0 pool = (3581.3,415.2,3139.7) poolr = 450 bulbs = [ { Pos = (3581.3,416.2,3139.7) } ] model = "SF2:e2885a9f" model_pos = (3581.4,265.2,3139.7) model_rot = 0.0 }
{ id = 1032 light = (3750.4,785.7,852.1) reach = 466.4 pool = (3750.4,684.8,852.1) poolr = 450 bulbs = [ { Pos = (3750.4,845.7,852.1) } ] model = "SCH:84d7e95d" model_pos = (3838.5,534.8,852.2) model_rot = 180.0 }
{ id = 1033 light = (3068.5,785.7,502.0) reach = 466.4 pool = (3068.5,684.8,502.0) poolr = 450 bulbs = [ { Pos = (3068.5,845.7,502.0) } ] model = "SCH:84d7e95d" model_pos = (3068.6,534.8,413.9) model_rot = 270.0 }
{ id = 1034 light = (3517.4,356.2,892.0) reach = 350.0 pool = (3517.4,415.2,892.0) poolr = 450 bulbs = [ { Pos = (3517.4,416.2,892.0) } ] model = "SF2:e2885a9f" model_pos = (3517.4,265.2,892.1) model_rot = 270.0 }
{ id = 1035 light = (2240.4,294.9,-203.6) reach = 521.6 pool = (2240.4,157.2,-203.6) poolr = 450 bulbs = [ { Pos = (2240.4,354.9,-203.6) } ] model = "SF2:4d8f0345" model_pos = (2240.3,7.2,-203.6) model_rot = 270.0 }
{ id = 1036 light = (3117.8,559.4,-543.6) reach = 615.3 pool = (3117.8,359.2,-543.6) poolr = 450 bulbs = [ { Pos = (3117.8,619.4,-543.6) } ] model = "Z_HO:2ff6f811" model_pos = (3117.7,209.2,-631.6) model_rot = 900.0 }
{ id = 1037 light = (-3383.6,326.9,-3681.2) reach = 521.6 pool = (-3383.6,189.2,-3681.2) poolr = 450 bulbs = [ { Pos = (-3383.6,386.9,-3681.2) } ] model = "SF2:4d8f0345" model_pos = (-3383.7,39.2,-3681.3) model_rot = 945.0 }
{ id = 1038 light = (-3271.2,294.9,-2874.7) reach = 521.6 pool = (-3271.2,157.2,-2874.7) poolr = 450 bulbs = [ { Pos = (-3271.2,354.9,-2874.7) } ] model = "SF2:4d8f0345" model_pos = (-3271.3,7.2,-2874.8) model_rot = 945.0 }
{ id = 1039 light = (-1275.1,294.9,-2861.0) reach = 521.6 pool = (-1275.1,157.2,-2861.0) poolr = 450 bulbs = [ { Pos = (-1275.1,354.9,-2861.0) } ] model = "SF2:4d8f0345" model_pos = (-1275.2,7.2,-2861.1) model_rot = 945.0 }
{ id = 1040 light = (536.4,294.9,-2867.8) reach = 521.6 pool = (536.4,157.2,-2867.8) poolr = 450 bulbs = [ { Pos = (536.4,354.9,-2867.8) } ] model = "SF2:4d8f0345" model_pos = (536.3,7.2,-2867.9) model_rot = 945.0 }
{ id = 1041 light = (760.7,333.9,-3747.1) reach = 521.6 pool = (760.7,196.2,-3747.1) poolr = 450 bulbs = [ { Pos = (760.7,393.9,-3747.1) } ] model = "SF2:4d8f0345" model_pos = (760.6,46.2,-3747.2) model_rot = 945.0 }
{ id = 1042 light = (-819.9,137.2,-3839.1) reach = 350.0 pool = (-819.9,196.2,-3839.1) poolr = 450 bulbs = [ { Pos = (-819.9,197.2,-3839.1) } ] model = "SF2:e2885a9f" model_pos = (-820.0,46.2,-3839.0) model_rot = 945.0 }
{ id = 1043 light = (-2046.4,137.2,-3835.0) reach = 350.0 pool = (-2046.4,196.2,-3835.0) poolr = 450 bulbs = [ { Pos = (-2046.4,197.2,-3835.0) } ] model = "SF2:e2885a9f" model_pos = (-2046.5,46.2,-3834.9) model_rot = 945.0 }
{ id = 1044 light = (-2677.4,539.1,-2357.5) reach = 466.4 pool = (-2677.4,438.2,-2357.5) poolr = 450 bulbs = [ { Pos = (-2677.4,599.1,-2357.5) } ] model = "SCH:84d7e95d" model_pos = (-2765.5,288.2,-2357.6) model_rot = 1080.0 }
{ id = 1045 light = (-2969.7,539.1,-1774.0) reach = 466.4 pool = (-2969.7,438.2,-1774.0) poolr = 450 bulbs = [ { Pos = (-2969.7,599.1,-1774.0) } ] model = "SCH:84d7e95d" model_pos = (-2881.6,288.2,-1773.9) model_rot = 1260.0 }
{ id = 1046 light = (-2975.8,539.1,-2358.6) reach = 466.4 pool = (-2975.8,438.2,-2358.6) poolr = 450 bulbs = [ { Pos = (-2975.8,599.1,-2358.6) } ] model = "SCH:84d7e95d" model_pos = (-2887.7,288.2,-2358.5) model_rot = 1260.0 }
{ id = 1047 light = (-2693.1,539.1,-1768.4) reach = 466.4 pool = (-2693.1,438.2,-1768.4) poolr = 450 bulbs = [ { Pos = (-2693.1,599.1,-1768.4) } ] model = "SCH:84d7e95d" model_pos = (-2781.2,288.2,-1768.5) model_rot = 1800.0 }
{ id = 1048 light = (-778.4,539.1,-2180.9) reach = 466.4 pool = (-778.4,438.2,-2180.9) poolr = 450 bulbs = [ { Pos = (-778.4,599.1,-2180.9) } ] model = "SCH:84d7e95d" model_pos = (-716.2,288.2,-2118.6) model_rot = 1935.0 }
{ id = 1049 light = (-239.0,539.1,-1510.8) reach = 466.4 pool = (-239.0,438.2,-1510.8) poolr = 450 bulbs = [ { Pos = (-239.0,599.1,-1510.8) } ] model = "SCH:84d7e95d" model_pos = (-176.7,288.2,-1573.0) model_rot = 2025.0 }
{ id = 1050 light = (-669.5,539.1,-1940.7) reach = 466.4 pool = (-669.5,438.2,-1940.7) poolr = 450 bulbs = [ { Pos = (-669.5,599.1,-1940.7) } ] model = "SCH:84d7e95d" model_pos = (-607.2,288.2,-2002.9) model_rot = 2025.0 }
{ id = 1051 light = (-530.8,539.1,-2073.6) reach = 466.4 pool = (-530.8,438.2,-2073.6) poolr = 450 bulbs = [ { Pos = (-530.8,599.1,-2073.6) } ] model = "SCH:84d7e95d" model_pos = (-593.1,288.2,-2011.4) model_rot = 2205.0 }
{ id = 1052 light = (-95.1,539.1,-1643.4) reach = 466.4 pool = (-95.1,438.2,-1643.4) poolr = 450 bulbs = [ { Pos = (-95.1,599.1,-1643.4) } ] model = "SCH:84d7e95d" model_pos = (-157.4,288.2,-1581.2) model_rot = 2205.0 }
{ id = 1053 light = (-3864.3,645.4,-2060.5) reach = 451.4 pool = (-3864.3,554.4,-2060.5) poolr = 450 bulbs = [ { Pos = (-3864.3,705.4,-2013.0) } { Pos = (-3864.3,705.4,-2108.1) } ] model = "HI:2c60622f" model_pos = (-3865.5,404.4,-2060.6) model_rot = 2250.0 }
{ id = 1054 light = (-703.2,294.9,10211.8) reach = 521.6 pool = (-703.2,157.2,10211.8) poolr = 450 bulbs = [ { Pos = (-703.2,354.9,10211.8) } ] model = "SF2:4d8f0345" model_pos = (-703.1,7.2,10211.8) model_rot = 2250.0 }
{ id = 1055 light = (55.6,294.9,9445.2) reach = 521.6 pool = (55.6,157.2,9445.2) poolr = 450 bulbs = [ { Pos = (55.6,354.9,9445.2) } ] model = "SF2:4d8f0345" model_pos = (55.7,7.2,9445.2) model_rot = 2250.0 }
{ id = 1056 light = (516.7,98.2,8557.0) reach = 350.0 pool = (516.7,157.2,8557.0) poolr = 450 bulbs = [ { Pos = (516.7,158.2,8557.0) } ] model = "SF2:e2885a9f" model_pos = (516.7,7.2,8556.9) model_rot = 2250.0 }
{ id = 1057 light = (154.2,98.2,8917.1) reach = 350.0 pool = (154.2,157.2,8917.1) poolr = 450 bulbs = [ { Pos = (154.2,158.2,8917.1) } ] model = "SF2:e2885a9f" model_pos = (154.2,7.2,8917.0) model_rot = 2250.0 }
{ id = 1058 light = (863.5,98.2,8173.8) reach = 350.0 pool = (863.5,157.2,8173.8) poolr = 450 bulbs = [ { Pos = (863.5,158.2,8173.8) } ] model = "SF2:e2885a9f" model_pos = (863.5,7.2,8173.7) model_rot = 2250.0 }
{ id = 1059 light = (871.1,118.2,7685.1) reach = 350.0 pool = (871.1,177.2,7685.1) poolr = 450 bulbs = [ { Pos = (871.1,178.2,7685.1) } ] model = "SF2:e2885a9f" model_pos = (871.1,27.2,7685.0) model_rot = 2250.0 }
{ id = 1060 light = (1161.9,294.8,7191.2) reach = 521.6 pool = (1161.9,157.1,7191.2) poolr = 450 bulbs = [ { Pos = (1161.9,354.8,7191.2) } ] model = "SF2:4d8f0345" model_pos = (1162.0,7.1,7191.2) model_rot = 2250.0 }
{ id = 1061 light = (-1377.3,489.7,8583.5) reach = 408.8 pool = (-1377.3,427.2,8583.5) poolr = 450 bulbs = [ { Pos = (-1377.3,549.7,8583.5) } ] model = "BA:2e232ee3" model_pos = (-1417.7,277.2,8582.3) model_rot = 2610.0 }
{ id = 1062 light = (-1557.3,489.7,8896.7) reach = 408.8 pool = (-1557.3,427.2,8896.7) poolr = 450 bulbs = [ { Pos = (-1557.3,549.7,8896.7) } ] model = "BA:2e232ee3" model_pos = (-1585.0,277.2,8867.3) model_rot = 3285.0 }
{ id = 1063 light = (-1945.8,489.7,9280.6) reach = 408.8 pool = (-1945.8,427.2,9280.6) poolr = 450 bulbs = [ { Pos = (-1945.8,549.7,9280.6) } ] model = "BA:2e232ee3" model_pos = (-1973.5,277.2,9251.2) model_rot = 3285.0 }
{ id = 1064 light = (-3879.4,246.9,8552.3) reach = 521.6 pool = (-3879.4,109.2,8552.3) poolr = 450 bulbs = [ { Pos = (-3879.4,306.9,8552.3) } ] model = "SF2:4d8f0345" model_pos = (-3879.3,-40.8,8552.4) model_rot = 3285.0 }
{ id = 1065 light = (-3357.8,246.9,9068.7) reach = 521.6 pool = (-3357.8,109.2,9068.7) poolr = 450 bulbs = [ { Pos = (-3357.8,306.9,9068.7) } ] model = "SF2:4d8f0345" model_pos = (-3357.7,-40.8,9068.8) model_rot = 3285.0 }
{ id = 1066 light = (-2741.7,246.9,9689.9) reach = 521.6 pool = (-2741.7,109.2,9689.9) poolr = 450 bulbs = [ { Pos = (-2741.7,306.9,9689.9) } ] model = "SF2:4d8f0345" model_pos = (-2741.6,-40.8,9690.0) model_rot = 3285.0 }
{ id = 1067 light = (-3092.4,295.8,6939.4) reach = 399.9 pool = (-3092.4,239.2,6939.4) poolr = 450 bulbs = [ { Pos = (-3092.4,355.8,6939.4) } ] model = "BA:b257485a" model_pos = (-3045.9,89.2,6989.4) model_rot = 3465.0 }
{ id = 1068 light = (-2336.9,146.2,6364.2) reach = 350.0 pool = (-2336.9,205.2,6364.2) poolr = 450 bulbs = [ { Pos = (-2336.9,206.2,6364.2) } ] model = "SF2:e2885a9f" model_pos = (-2337.0,55.2,6364.3) model_rot = 3465.0 }
{ id = 1069 light = (-1625.0,146.2,5439.5) reach = 350.0 pool = (-1625.0,205.2,5439.5) poolr = 450 bulbs = [ { Pos = (-1625.0,206.2,5439.5) } ] model = "SF2:e2885a9f" model_pos = (-1625.1,55.2,5439.6) model_rot = 3465.0 }
{ id = 1070 light = (-3608.9,146.2,7415.3) reach = 350.0 pool = (-3608.9,205.2,7415.3) poolr = 450 bulbs = [ { Pos = (-3608.9,206.2,7415.3) } ] model = "SF2:e2885a9f" model_pos = (-3609.0,55.2,7415.4) model_rot = 3465.0 }
{ id = 1071 light = (-2030.0,337.9,6667.6) reach = 350.0 pool = (-2030.0,396.9,6667.6) poolr = 450 bulbs = [ { Pos = (-2030.0,397.9,6667.6) } ] model = "SF2:e2885a9f" model_pos = (-2030.1,246.9,6667.7) model_rot = 3465.0 }
{ id = 1072 light = (-1954.5,342.9,7645.3) reach = 521.6 pool = (-1954.5,205.2,7645.3) poolr = 450 bulbs = [ { Pos = (-1954.5,402.9,7645.3) } ] model = "SF2:4d8f0345" model_pos = (-1954.6,55.2,7645.2) model_rot = 3465.0 }
{ id = 1073 light = (-1263.4,337.9,8036.7) reach = 350.0 pool = (-1263.4,396.9,8036.7) poolr = 450 bulbs = [ { Pos = (-1263.4,397.9,8036.7) } ] model = "SF2:e2885a9f" model_pos = (-1263.5,246.9,8036.8) model_rot = 3465.0 }
{ id = 1074 light = (-2126.4,337.9,8224.8) reach = 350.0 pool = (-2126.4,396.9,8224.8) poolr = 450 bulbs = [ { Pos = (-2126.4,397.9,8224.8) } ] model = "SF2:e2885a9f" model_pos = (-2126.5,246.9,8224.9) model_rot = 3465.0 }
{ id = 1075 light = (-2479.0,337.9,7628.6) reach = 350.0 pool = (-2479.0,396.9,7628.6) poolr = 450 bulbs = [ { Pos = (-2479.0,397.9,7628.6) } ] model = "SF2:e2885a9f" model_pos = (-2479.1,246.9,7628.7) model_rot = 3465.0 }
{ id = 1076 light = (-2112.8,337.9,7054.6) reach = 350.0 pool = (-2112.8,396.9,7054.6) poolr = 450 bulbs = [ { Pos = (-2112.8,397.9,7054.6) } ] model = "SF2:e2885a9f" model_pos = (-2112.9,246.9,7054.7) model_rot = 3465.0 }
{ id = 1077 light = (-1030.6,337.9,7383.4) reach = 350.0 pool = (-1030.6,396.9,7383.4) poolr = 450 bulbs = [ { Pos = (-1030.6,397.9,7383.4) } ] model = "SF2:e2885a9f" model_pos = (-1030.7,246.9,7383.5) model_rot = 3465.0 }
{ id = 1078 light = (-1228.0,337.9,6257.0) reach = 350.0 pool = (-1228.0,396.9,6257.0) poolr = 450 bulbs = [ { Pos = (-1228.0,397.9,6257.0) } ] model = "SF2:e2885a9f" model_pos = (-1228.1,246.9,6257.1) model_rot = 3465.0 }
{ id = 1079 light = (-897.0,337.9,6572.7) reach = 350.0 pool = (-897.0,396.9,6572.7) poolr = 450 bulbs = [ { Pos = (-897.0,397.9,6572.7) } ] model = "SF2:e2885a9f" model_pos = (-897.1,246.9,6572.8) model_rot = 3465.0 }
{ id = 1080 light = (-271.6,337.9,7199.6) reach = 350.0 pool = (-271.6,396.9,7199.6) poolr = 450 bulbs = [ { Pos = (-271.6,397.9,7199.6) } ] model = "SF2:e2885a9f" model_pos = (-271.7,246.9,7199.7) model_rot = 3465.0 }
{ id = 1081 light = (-2814.6,146.2,10288.3) reach = 350.0 pool = (-2814.6,205.2,10288.3) poolr = 450 bulbs = [ { Pos = (-2814.6,206.2,10288.3) } ] model = "SF2:e2885a9f" model_pos = (-2814.5,55.2,10288.3) model_rot = 0.0 }
{ id = 1082 light = (-3036.8,146.2,10058.5) reach = 350.0 pool = (-3036.8,205.2,10058.5) poolr = 450 bulbs = [ { Pos = (-3036.8,206.2,10058.5) } ] model = "SF2:e2885a9f" model_pos = (-3036.7,55.2,10058.5) model_rot = 0.0 }
{ id = 1083 light = (-3285.7,146.2,9812.1) reach = 350.0 pool = (-3285.7,205.2,9812.1) poolr = 450 bulbs = [ { Pos = (-3285.7,206.2,9812.1) } ] model = "SF2:e2885a9f" model_pos = (-3285.6,55.2,9812.1) model_rot = 0.0 }
{ id = 1084 light = (-3475.2,146.2,9621.1) reach = 350.0 pool = (-3475.2,205.2,9621.1) poolr = 450 bulbs = [ { Pos = (-3475.2,206.2,9621.1) } ] model = "SF2:e2885a9f" model_pos = (-3475.1,55.2,9621.1) model_rot = 0.0 }
{ id = 1085 light = (-3926.2,146.2,9172.8) reach = 350.0 pool = (-3926.2,205.2,9172.8) poolr = 450 bulbs = [ { Pos = (-3926.2,206.2,9172.8) } ] model = "SF2:e2885a9f" model_pos = (-3926.1,55.2,9172.8) model_rot = 0.0 }
{ id = 1086 light = (-4117.6,146.2,8985.9) reach = 350.0 pool = (-4117.6,205.2,8985.9) poolr = 450 bulbs = [ { Pos = (-4117.6,206.2,8985.9) } ] model = "SF2:e2885a9f" model_pos = (-4117.5,55.2,8985.9) model_rot = 0.0 }
{ id = 1087 light = (-4510.4,146.2,8591.4) reach = 350.0 pool = (-4510.4,205.2,8591.4) poolr = 450 bulbs = [ { Pos = (-4510.4,206.2,8591.4) } ] model = "SF2:e2885a9f" model_pos = (-4510.3,55.2,8591.4) model_rot = 0.0 }
{ id = 1088 light = (-3696.2,146.2,9397.4) reach = 350.0 pool = (-3696.2,205.2,9397.4) poolr = 450 bulbs = [ { Pos = (-3696.2,206.2,9397.4) } ] model = "SF2:e2885a9f" model_pos = (-3696.1,55.2,9397.4) model_rot = 0.0 }
{ id = 1089 light = (-4311.7,146.2,8800.4) reach = 350.0 pool = (-4311.7,205.2,8800.4) poolr = 450 bulbs = [ { Pos = (-4311.7,206.2,8800.4) } ] model = "SF2:e2885a9f" model_pos = (-4311.6,55.2,8800.4) model_rot = 0.0 }
{ id = 1090 light = (-2993.7,338.0,7381.5) reach = 399.9 pool = (-2993.7,281.4,7381.5) poolr = 450 bulbs = [ { Pos = (-2993.7,398.0,7381.5) } ] model = "BA:b257485a" model_pos = (-2943.7,131.4,7335.0) model_rot = 315.0 }
{ id = 1091 light = (-2622.7,474.0,8704.2) reach = 399.9 pool = (-2622.7,417.4,8704.2) poolr = 450 bulbs = [ { Pos = (-2622.7,534.0,8704.2) } ] model = "BA:b257485a" model_pos = (-2576.2,267.4,8754.2) model_rot = 585.0 }
{ id = 1092 light = (-2002.3,146.2,9613.4) reach = 350.0 pool = (-2002.3,205.2,9613.4) poolr = 450 bulbs = [ { Pos = (-2002.3,206.2,9613.4) } ] model = "SF2:e2885a9f" model_pos = (-2002.4,55.2,9613.3) model_rot = 855.0 }
{ id = 1093 light = (-1221.8,145.6,8325.0) reach = 399.9 pool = (-1221.8,89.0,8325.0) poolr = 450 bulbs = [ { Pos = (-1221.8,205.6,8325.0) } ] model = "BA:b257485a" model_pos = (-1268.3,-61.0,8275.0) model_rot = 1125.0 }
{ id = 1094 light = (2673.9,484.0,6973.5) reach = 528.2 pool = (2673.9,341.9,6973.5) poolr = 450 bulbs = [ { Pos = (2673.9,544.0,6973.5) } ] model = "TOK:9b16e657" model_pos = (2673.9,191.9,7116.8) model_rot = 360.0 }
{ id = 1095 light = (41.4,484.0,-1358.2) reach = 528.2 pool = (41.4,341.9,-1358.2) poolr = 450 bulbs = [ { Pos = (41.4,544.0,-1358.2) } ] model = "TOK:9b16e657" model_pos = (-59.9,191.9,-1459.5) model_rot = 585.0 }
{ id = 1096 light = (44.4,294.9,6608.4) reach = 521.6 pool = (44.4,157.2,6608.4) poolr = 450 bulbs = [ { Pos = (44.4,354.9,6608.4) } ] model = "SF2:4d8f0345" model_pos = (44.3,7.2,6608.3) model_rot = 585.0 }
{ id = 1097 light = (-548.1,294.9,6048.5) reach = 521.6 pool = (-548.1,157.2,6048.5) poolr = 450 bulbs = [ { Pos = (-548.1,354.9,6048.5) } ] model = "SF2:4d8f0345" model_pos = (-548.2,7.2,6048.4) model_rot = 585.0 }
{ id = 1098 light = (-656.4,292.1,755.1) reach = 528.2 pool = (-656.4,150.0,755.1) poolr = 450 bulbs = [ { Pos = (-656.4,352.1,755.1) } ] model = "TOK:9b16e657" model_pos = (-799.7,0.0,755.1) model_rot = 270.0 }
{ id = 1099 light = (1487.8,164.2,514.1) reach = 350.0 pool = (1487.8,223.2,514.1) poolr = 450 bulbs = [ { Pos = (1487.8,224.2,514.1) } ] model = "SF2:e2885a9f" model_pos = (1487.9,73.2,514.1) model_rot = 0.0 }
{ id = 1100 light = (1657.1,140.2,1917.3) reach = 350.0 pool = (1657.1,199.2,1917.3) poolr = 450 bulbs = [ { Pos = (1657.1,200.2,1917.3) } ] model = "SF2:e2885a9f" model_pos = (1657.2,49.2,1917.3) model_rot = 0.0 }
{ id = 1101 light = (1226.2,120.0,4307.3) reach = 350.0 pool = (1226.2,179.0,4307.3) poolr = 450 bulbs = [ { Pos = (1226.2,180.0,4307.3) } ] model = "SF2:e2885a9f" model_pos = (1226.3,29.0,4307.3) model_rot = 0.0 }
{ id = 1102 light = (1968.2,104.0,4847.1) reach = 350.0 pool = (1968.2,163.0,4847.1) poolr = 450 bulbs = [ { Pos = (1968.2,164.0,4847.1) } ] model = "SF2:e2885a9f" model_pos = (1968.3,13.0,4847.0) model_rot = 15.0 }
{ id = 1103 light = (1776.6,92.0,5517.6) reach = 350.0 pool = (1776.6,151.0,5517.6) poolr = 450 bulbs = [ { Pos = (1776.6,152.0,5517.6) } ] model = "SF2:e2885a9f" model_pos = (1776.7,1.0,5517.5) model_rot = 15.0 }
{ id = 1104 light = (3453.7,98.2,5566.3) reach = 350.0 pool = (3453.7,157.2,5566.3) poolr = 450 bulbs = [ { Pos = (3453.7,158.2,5566.3) } ] model = "SF2:e2885a9f" model_pos = (3453.8,7.2,5566.3) model_rot = 0.0 }
{ id = 1105 light = (3721.4,98.2,6772.3) reach = 350.0 pool = (3721.4,157.2,6772.3) poolr = 450 bulbs = [ { Pos = (3721.4,158.2,6772.3) } ] model = "SF2:e2885a9f" model_pos = (3721.5,7.2,6772.3) model_rot = 0.0 }
{ id = 1106 light = (2929.3,98.2,6767.4) reach = 350.0 pool = (2929.3,157.2,6767.4) poolr = 450 bulbs = [ { Pos = (2929.3,158.2,6767.4) } ] model = "SF2:e2885a9f" model_pos = (2929.4,7.2,6767.4) model_rot = 0.0 }
{ id = 1107 light = (2226.4,98.2,6786.7) reach = 350.0 pool = (2226.4,157.2,6786.7) poolr = 450 bulbs = [ { Pos = (2226.4,158.2,6786.7) } ] model = "SF2:e2885a9f" model_pos = (2226.5,7.2,6786.7) model_rot = 0.0 }
{ id = 1108 light = (1442.4,98.2,6769.6) reach = 350.0 pool = (1442.4,157.2,6769.6) poolr = 450 bulbs = [ { Pos = (1442.4,158.2,6769.6) } ] model = "SF2:e2885a9f" model_pos = (1442.5,7.2,6769.6) model_rot = 0.0 }
{ id = 1109 light = (677.7,98.2,6614.7) reach = 350.0 pool = (677.7,157.2,6614.7) poolr = 450 bulbs = [ { Pos = (677.7,158.2,6614.7) } ] model = "SF2:e2885a9f" model_pos = (677.8,7.2,6614.7) model_rot = 0.0 }
{ id = 1110 light = (5.6,98.2,6097.1) reach = 350.0 pool = (5.6,157.2,6097.1) poolr = 450 bulbs = [ { Pos = (5.6,158.2,6097.1) } ] model = "SF2:e2885a9f" model_pos = (5.7,7.2,6097.1) model_rot = 0.0 }
{ id = 1111 light = (-450.3,99.3,4433.5) reach = 350.0 pool = (-450.3,158.3,4433.5) poolr = 450 bulbs = [ { Pos = (-450.3,159.3,4433.5) } ] model = "SF2:e2885a9f" model_pos = (-450.2,8.3,4433.5) model_rot = 0.0 }
{ id = 1112 light = (4562.7,98.2,6766.4) reach = 350.0 pool = (4562.7,157.2,6766.4) poolr = 450 bulbs = [ { Pos = (4562.7,158.2,6766.4) } ] model = "SF2:e2885a9f" model_pos = (4562.8,7.2,6766.4) model_rot = 0.0 }
{ id = 1113 light = (5264.5,98.2,6760.0) reach = 350.0 pool = (5264.5,157.2,6760.0) poolr = 450 bulbs = [ { Pos = (5264.5,158.2,6760.0) } ] model = "SF2:e2885a9f" model_pos = (5264.6,7.2,6760.0) model_rot = 0.0 }
{ id = 1114 light = (5984.6,98.2,6748.7) reach = 350.0 pool = (5984.6,157.2,6748.7) poolr = 450 bulbs = [ { Pos = (5984.6,158.2,6748.7) } ] model = "SF2:e2885a9f" model_pos = (5984.7,7.2,6748.7) model_rot = 0.0 }
{ id = 1115 light = (6672.6,98.2,6763.7) reach = 350.0 pool = (6672.6,157.2,6763.7) poolr = 450 bulbs = [ { Pos = (6672.6,158.2,6763.7) } ] model = "SF2:e2885a9f" model_pos = (6672.7,7.2,6763.7) model_rot = 0.0 }
{ id = 1116 light = (7323.4,98.2,6762.0) reach = 350.0 pool = (7323.4,157.2,6762.0) poolr = 450 bulbs = [ { Pos = (7323.4,158.2,6762.0) } ] model = "SF2:e2885a9f" model_pos = (7323.5,7.2,6762.0) model_rot = 0.0 }
{ id = 1117 light = (7513.9,98.2,6263.0) reach = 350.0 pool = (7513.9,157.2,6263.0) poolr = 450 bulbs = [ { Pos = (7513.9,158.2,6263.0) } ] model = "SF2:e2885a9f" model_pos = (7514.0,7.2,6263.0) model_rot = 0.0 }
{ id = 1118 light = (7503.9,98.2,5557.9) reach = 350.0 pool = (7503.9,157.2,5557.9) poolr = 450 bulbs = [ { Pos = (7503.9,158.2,5557.9) } ] model = "SF2:e2885a9f" model_pos = (7504.0,7.2,5557.9) model_rot = 0.0 }
{ id = 1119 light = (7512.8,98.2,5025.2) reach = 350.0 pool = (7512.8,157.2,5025.2) poolr = 450 bulbs = [ { Pos = (7512.8,158.2,5025.2) } ] model = "SF2:e2885a9f" model_pos = (7512.9,7.2,5025.2) model_rot = 0.0 }
{ id = 1120 light = (6623.6,98.2,5520.5) reach = 350.0 pool = (6623.6,157.2,5520.5) poolr = 450 bulbs = [ { Pos = (6623.6,158.2,5520.5) } ] model = "SF2:e2885a9f" model_pos = (6623.7,7.2,5520.5) model_rot = 0.0 }
{ id = 1121 light = (6160.3,98.2,5891.2) reach = 350.0 pool = (6160.3,157.2,5891.2) poolr = 450 bulbs = [ { Pos = (6160.3,158.2,5891.2) } ] model = "SF2:e2885a9f" model_pos = (6160.4,7.2,5891.2) model_rot = 0.0 }
{ id = 1122 light = (5634.5,98.2,5888.0) reach = 350.0 pool = (5634.5,157.2,5888.0) poolr = 450 bulbs = [ { Pos = (5634.5,158.2,5888.0) } ] model = "SF2:e2885a9f" model_pos = (5634.6,7.2,5888.0) model_rot = 0.0 }
{ id = 1123 light = (4964.8,98.2,5877.3) reach = 350.0 pool = (4964.8,157.2,5877.3) poolr = 450 bulbs = [ { Pos = (4964.8,158.2,5877.3) } ] model = "SF2:e2885a9f" model_pos = (4964.9,7.2,5877.3) model_rot = 0.0 }
{ id = 1124 light = (4321.4,98.2,5874.9) reach = 350.0 pool = (4321.4,157.2,5874.9) poolr = 450 bulbs = [ { Pos = (4321.4,158.2,5874.9) } ] model = "SF2:e2885a9f" model_pos = (4321.5,7.2,5874.9) model_rot = 0.0 }
]

