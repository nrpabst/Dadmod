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
            <lampstep> = 1
            begin
                if ( <night> = 1 )
                    <pct> = ( <lampstep> * 20.0 )
                else
                    <pct> = ( 100.0 - <lampstep> * 20.0 )
                endif
                ForEachIn <list> Do = dadmod_lamp_pct params = { level = <level> pct = <pct> }
                <lampstep> = ( <lampstep> + 1 )
                if ( <lampstep> > 5 )
                    break
                endif
                wait 0.6 seconds
            repeat
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
