script dadmod_square_getup
    dadmod_sqget_get
    dadmod_abc_get
    if ( ( <sqget_on> = 0 ) and ( <abc_on> = 0 ) )
        return
    endif
    if IsTrue THUGPRO_ObserveOn
        return
    endif
    if ( ( GameModeEquals is_firefight ) or ( GameModeEquals is_king ) or ( GameModeEquals is_ctf ) or ( IsTrue AlreadyEndedRun ) )
        return
    endif
    if ( <abc_on> = 1 )
        begin
            if not IsInBail
                return
            endif
            if not InAir
                break
            endif
            wait 1 gameframe
        repeat
        abc_frames = 0
        begin
            if not IsInBail
                return
            endif
            if ( <abc_frames> > 20 )
                break
            endif
            abc_frames = ( <abc_frames> + 1 )
            wait 1 gameframe
        repeat
    else
        begin
            if not IsInBail
                return
            endif
            if not Held Square
                break
            endif
            wait 1 gameframe
        repeat
        begin
            if not IsInBail
                return
            endif
            if Held Square
                dadmod_square_getup_blocked
                if ( <blocked> = 0 )
                    break
                endif
            endif
            wait 1 gameframe
        repeat
        begin
            if not IsInBail
                return
            endif
            if not InAir
                break
            endif
            wait 1 gameframe
        repeat
    endif
    if IsTrue AlreadyEndedRun
        return
    endif
    SetCurrentBailEndpose
    dadmod_bail_vanish
    if ( <abc_abort> = 1 )
        return
    endif
    MakeSkaterGoto dadmod_bail_cancel_state
endscript
script dadmod_bail_cancel_state
    NoQuickGetup
    TantrumOff
    ExitTantrum
    SwitchOnBoard
    BoardRotate Normal
    if ObjectExists id = BurnMoFo
        BurnMoFo : unhide
    endif
    if ObjectExists id = SmokeyMoFo
        SmokeyMoFo : unhide
    endif
    OnExceptionRun
    ResetEventHandlersFromTable StartSkateExceptionTable
    VibrateOff
    PlayAnim anim = idle BlendPeriod = 0.15
    Obj_KillSpawnedScript Name = dadmod_bail_reform
    Obj_SpawnScript dadmod_bail_reform
    goto BailDone
endscript
script dadmod_square_getup_blocked
    if ObjectExists id = keyboard_anchor
        return blocked = 1
    endif
    root_window : GetSingleTag menu_state
    if GotParam menu_state
        if ( <menu_state> = on )
            return blocked = 1
        endif
    endif
    return blocked = 0
endscript
script dadmod_sqget_get
    on = 1
    if THUGRECOMP_SettingLoad key = "square_getup"
        if ( <value> = 0 )
            on = 0
        endif
    endif
    return sqget_on = <on>
endscript
script dadmod_sqget_text
    dadmod_sqget_get
    if ( <sqget_on> = 1 )
        return sqget_text = "On"
    endif
    return sqget_text = "Off"
endscript
script dadmod_sqget_toggle
    if ScreenElementExists id = dadmod_sqget_item
        if dadmod_sqget_item : GetSingleTag sqget_lock
            if ( <sqget_lock> = 1 )
                return
            endif
        endif
        dadmod_sqget_item : SetTags sqget_lock = 1
        SpawnScript dadmod_sqget_unlock
    endif
    dadmod_sqget_get
    if ( <sqget_on> = 1 )
        on = 0
    else
        on = 1
    endif
    THUGRECOMP_SettingSave key = "square_getup" value = <on>
    dadmod_sqget_text
    thugpro_menu_item_update_extra_text id = dadmod_sqget_item text = <sqget_text>
endscript
script dadmod_sqget_unlock
    wait 6 gameframes
    if ScreenElementExists id = dadmod_sqget_item
        dadmod_sqget_item : SetTags sqget_lock = 0
    endif
endscript
script dadmod_bail_vanish
    dadmod_abc_play part = abc_vanish
    dadmod_abcsnd_get
    if ( <abcsnd_on> = 1 )
        DestroyFlexibleParticleSystem Name = dadmod_abc_fx_out
        CreateFlexibleParticleSystem Name = dadmod_abc_fx_out params_script = dadmod_abc_particle_params
    endif
    abc_on_f = 5
    begin
        if not IsInBail
            unhide
            return abc_abort = 1
        endif
        hide
        wait 2 frames
        unhide
        wait <abc_on_f> frames
        abc_on_f = ( <abc_on_f> - 1 )
        if ( <abc_on_f> < 1 )
            break
        endif
    repeat
    if not IsInBail
        return abc_abort = 1
    endif
    hide
    Obj_ShadowOff
    wait 4 frames
    return abc_abort = 0
endscript
script dadmod_bail_reform
    hide
    Obj_ShadowOff
    wait 3 frames
    dadmod_abc_play part = abc_reform
    dadmod_abcsnd_get
    if ( <abcsnd_on> = 1 )
        DestroyFlexibleParticleSystem Name = dadmod_abc_fx_in
        CreateFlexibleParticleSystem Name = dadmod_abc_fx_in params_script = dadmod_abc_particle_params
    endif
    abc_on_f = 1
    begin
        unhide
        wait <abc_on_f> frames
        hide
        wait 2 frames
        abc_on_f = ( <abc_on_f> + 1 )
        if ( <abc_on_f> > 5 )
            break
        endif
    repeat
    unhide
    Obj_ShadowOn ShadowType = Detailed
endscript
dadmod_abc_particle_params = {
bone = Bone_Pelvis
EnableRotate
emitScript = emit_dadmod_abc_particle
emitterIndependent = 1
max = 40
Type = Flat
texture = apm_spray_01
BlendMode = Add
}
script emit_dadmod_abc_particle
    setEmitRange width = 30.0 height = 50.0 depth = 0.0
    setCircularEmit circular = 1
    setLife min = 0.2 max = 0.45
    setAngleSpread spread = 0.5
    setSpeedRange min = 1.0 max = 4.0
    setEmitTarget x = 0.0 y = 1.0 z = 0.0
    setForce x = 0.0 y = 0.05 z = 0.0
    setParticleSize sw = 6.0 ew = 1.0
    setColor sr = 120 sg = 170 sb = 255 sa = 255 er = 60 eg = 40 eb = 255 ea = 0
    EmitRate rate = 120.0
    wait 0.3 seconds
    EmitRate rate = 0
    destroy ifEmpty = 1
endscript
script dadmod_abc_get
    on = 0
    if THUGRECOMP_SettingLoad key = "auto_bail_cancel"
        if ( <value> = 1 )
            on = 1
        endif
    endif
    return abc_on = <on>
endscript
script dadmod_abc_text
    dadmod_abc_get
    if ( <abc_on> = 1 )
        return abc_text = "On"
    endif
    return abc_text = "Off"
endscript
script dadmod_abc_toggle
    if ScreenElementExists id = dadmod_abc_item
        if dadmod_abc_item : GetSingleTag abc_lock
            if ( <abc_lock> = 1 )
                return
            endif
        endif
        dadmod_abc_item : SetTags abc_lock = 1
        SpawnScript dadmod_abc_unlock
    endif
    dadmod_abc_get
    if ( <abc_on> = 1 )
        on = 0
    else
        on = 1
    endif
    THUGRECOMP_SettingSave key = "auto_bail_cancel" value = <on>
    dadmod_abc_text
    thugpro_menu_item_update_extra_text id = dadmod_abc_item text = <abc_text>
endscript
script dadmod_abc_unlock
    wait 6 gameframes
    if ScreenElementExists id = dadmod_abc_item
        dadmod_abc_item : SetTags abc_lock = 0
    endif
endscript
script dadmod_abc_play part = abc_vanish
    if ( <part> = abc_vanish )
        KillSpawnedScript Name = dadmod_abc_whoosh_later
        SpawnScript dadmod_abc_whoosh_later
    endif
endscript
script dadmod_abc_whoosh_later
    wait 8 gameframes
    dadmod_abcsnd_get
    if ( <abcsnd_on> = 1 )
        PlaySound Whoosh vol = 100
    endif
endscript
script dadmod_abcsnd_get
    on = 1
    if THUGRECOMP_SettingLoad key = "bail_cancel_sound_on"
        if ( <value> = 0 )
            on = 0
        endif
    endif
    return abcsnd_on = <on>
endscript
script dadmod_abcsnd_text
    dadmod_abcsnd_get
    if ( <abcsnd_on> = 1 )
        return abcsnd_text = "On"
    endif
    return abcsnd_text = "Off"
endscript
script dadmod_abcsnd_toggle
    if ScreenElementExists id = dadmod_abcsnd_item
        if dadmod_abcsnd_item : GetSingleTag abcsnd_lock
            if ( <abcsnd_lock> = 1 )
                return
            endif
        endif
        dadmod_abcsnd_item : SetTags abcsnd_lock = 1
        SpawnScript dadmod_abcsnd_unlock
    endif
    dadmod_abcsnd_get
    if ( <abcsnd_on> = 1 )
        on = 0
    else
        on = 1
    endif
    THUGRECOMP_SettingSave key = "bail_cancel_sound_on" value = <on>
    dadmod_abcsnd_text
    thugpro_menu_item_update_extra_text id = dadmod_abcsnd_item text = <abcsnd_text>
endscript
script dadmod_abcsnd_unlock
    wait 6 gameframes
    if ScreenElementExists id = dadmod_abcsnd_item
        dadmod_abcsnd_item : SetTags abcsnd_lock = 0
    endif
endscript
