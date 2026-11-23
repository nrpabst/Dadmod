script dadmod_shadow_restore
    if THUGRECOMP_SettingLoad key = "gfx_shadowdetail"
        if (<value> = 1)
            Obj_ShadowOn ShadowType = Detailed
            return
        endif
    endif
    Obj_ShadowOn ShadowType = Simple
endscript
script dadmod_shadow_refresh
    if LevelIs Load_MainMenu
        return
    endif
    if not ObjectExists id = Skater
        return
    endif
    if Skater : Driving
        return
    endif
    if IsObserving
        return
    endif
    if THUGRECOMP_SettingLoad key = "gfx_shadowdetail"
        if (<value> = 1)
            Skater : Obj_ShadowOn ShadowType = Detailed
            return
        endif
    endif
    Skater : Obj_ShadowOn ShadowType = Simple
endscript
