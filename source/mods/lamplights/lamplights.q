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
        THUGRECOMP_LampPost model = <model> Pos = <model_pos> rot = <model_rot>
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
