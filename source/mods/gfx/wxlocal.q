dadmod_wx_on = 0
dadmod_wx_kind = -1
dadmod_wx_amt = -1
dadmod_wx_level = none
script dadmod_wx_watch_start
    if IsTrue dadmod_wx_watch_on
        return
    endif
    Change dadmod_wx_watch_on = 1
    SpawnScript dadmod_wx_watch NotSessionSpecific = 1
endscript
dadmod_wx_watch_on = 0
dadmod_wx_server = 0
script dadmod_wx_server_set kind = 0
    Change dadmod_wx_server = <kind>
    THUGRECOMP_SettingSave key = "gfx_wxsrv" value = <kind>
endscript
script dadmod_wx_wanted
    kind = 0
    if THUGRECOMP_SettingLoad key = "gfx_wxnow"
        kind = <value>
    endif
    amt = 5
    if THUGRECOMP_SettingLoad key = "gfx_wxamt"
        amt = <value>
    endif
    if (<amt> < 1)
        amt = 1
    endif
    if (<amt> > 10)
        amt = 10
    endif
    if (dadmod_wx_server > 0)
        if InNetGame
            kind = 9
        else
            Change dadmod_wx_server = 0
            THUGRECOMP_SettingSave key = "gfx_wxsrv" value = 0
        endif
    endif
    if LevelIs Load_MainMenu
        kind = 0
    endif
    return kind = <kind> amt = <amt>
endscript
script dadmod_wx_watch
    begin
        wait 30 gameframes
        if ObjectExists id = skater
            dadmod_wx_wanted
            lvl = none
            GetLevelStructureName
            if GotParam level_structure_name
                lvl = <level_structure_name>
            endif
            if not (<lvl> = ( dadmod_wx_level ))
                Change dadmod_wx_level = <lvl>
                Change dadmod_wx_kind = -1
            endif
            if not ( ( <kind> = ( dadmod_wx_kind ) ) and ( <amt> = ( dadmod_wx_amt ) ) )
                dadmod_wx_apply kind = <kind> amt = <amt>
            endif
        endif
    repeat
endscript
script dadmod_wx_apply
    Change dadmod_wx_kind = <kind>
    Change dadmod_wx_amt = <amt>
    switch <kind>
    case 1
        dadmod_wx_rain amt = <amt> storm = 0
    case 2
        dadmod_wx_rain amt = <amt> storm = 1
    case 3
        dadmod_wx_snow amt = <amt>
    case 9
        Change dadmod_wx_on = 0
    default
        if (dadmod_wx_on = 1)
            WeatherSetSplashRate 0
            WeatherSetRainRate 0
            WeatherSetSnowRate 0
            Change dadmod_wx_on = 0
        endif
    endswitch
    FormatText TextName = dbg "weather (local): kind %k intensity %a" k = <kind> a = <amt>
    THUGRECOMP_Log text = <dbg>
endscript
script dadmod_wx_rain
    rate = ( 3 + <amt> )
    blend = ( 4 + <amt> )
    splash = ( <amt> / 2 )
    CastToInteger splash
    if (<storm> = 1)
        rate = 12
        blend = ( 8 + <amt> )
        splash = ( 2 + <amt> )
    endif
    WeatherUpdateGrid
    WeatherSetSnowRate 0
    WeatherSetSnowColor 0
    WeatherSetRainActive
    WeatherSetRainHeight 1000
    WeatherSetRainFrames 80
    WeatherSetRainLength 120
    WeatherSetRainBlendMode fixadd <blend>
    WeatherSetRainColor top = 285212671 bottom = 1073741823
    WeatherSetSplashLife 8
    WeatherSetSplashSize 12
    WeatherSetSplashColor -1
    WeatherSetSplashBlendMode fixadd 16
    WeatherSetSplashRate <splash>
    WeatherSetRainRate <rate>
    Change dadmod_wx_on = 1
endscript
script dadmod_wx_snow amt = 5
    rate = ( 1 + ( <amt> / 3 ) )
    CastToInteger rate
    blend = ( 30 + ( <amt> * 3 ) )
    WeatherUpdateGrid
    WeatherSetRainRate 0
    WeatherSetSplashRate 0
    WeatherSetRainColor top = 0 bottom = 0
    WeatherSetSplashColor 0
    WeatherSetSnowActive
    WeatherSetSnowHeight 300
    WeatherSetSnowFrames 255
    WeatherSetSnowSize 4
    WeatherSetSnowBlendMode fixadd <blend>
    WeatherSetSnowColor -1
    WeatherSetSnowRate <rate>
    Change dadmod_wx_on = 1
endscript
