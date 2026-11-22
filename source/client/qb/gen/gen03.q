dadmod_gen03_names = [ IsTrue GotParam ScreenElementExists ]

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
    THUGRECOMP_LampBulbsClear
    keep = 1
    if GotParam game
        if ( ( <game> = THPS1 ) or ( <game> = THPS2 ) or ( <game> = THPS3 ) or ( <game> = THPS4 ) )
            keep = 0
        endif
    endif
    THUGRECOMP_SettingSave key = "gfx_keeplit" value = <keep>
    KillSpawnedScript Name = dadmod_lamp_night
    if GotParam level
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
    ForEachIn <bulbs> Do = dadmod_lamp_bulb
    THUGRECOMP_LampBulb Pos = <pool> pool = <poolr> drop = 0 r = 0 g = 0 b = 0
    FormatText ChecksumName = nm "dadmod_ll_%s_%d" s = <level> d = <id>
    THUGRECOMP_AddLevelLight Name = <nm> Pos = <light> Brightness = 0.0 InnerRadius = ( <reachset> * 0.5 ) OuterRadius = ( <reachset> * 1.0 ) color = [ 255 150 50 ] ExcludeSkater
endscript

script dadmod_lamp_bulb
    THUGRECOMP_LampBulb Pos = <Pos> pool = 0 drop = 0
endscript

script dadmod_lamp_night
    last = -1
    THUGRECOMP_SettingLoad key = "gfx_lampreach"
    lastreach = <value>
    begin
        THUGRECOMP_SettingLoad key = "gfx_lampreach"
        if not ( <value> = <lastreach> )
            <lastreach> = <value>
            ForEachIn <list> Do = dadmod_lamp_reach params = { level = <level> reachset = <value> }
        endif
        THUGRECOMP_LampNight
        if not ( <night> = <last> )
            <last> = <night>
            if ( <night> = 1 )
                <pct> = 100.0
            else
                <pct> = 0.0
            endif
            ForEachIn <list> Do = dadmod_lamp_pct params = { level = <level> pct = <pct> }
        endif
        wait 0.5 seconds
    repeat
endscript

script dadmod_lamp_pct
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
]

