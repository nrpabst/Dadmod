script dadmod_tod_lerp
    u = ( 1.0 - <t> )
    p = <b>
    if StructureContains structure = <a> sun_theta
        if StructureContains structure = <b> sun_theta
            v = ( ( ( <a> . sun_theta ) * <u> ) + ( ( <b> . sun_theta ) * <t> ) )
            p = { <p> sun_theta = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_phi
        if StructureContains structure = <b> sun_phi
            v = ( ( ( <a> . sun_phi ) * <u> ) + ( ( <b> . sun_phi ) * <t> ) )
            p = { <p> sun_phi = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_red
        if StructureContains structure = <b> sun_red
            v = ( ( ( <a> . sun_red ) * <u> ) + ( ( <b> . sun_red ) * <t> ) )
            p = { <p> sun_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_green
        if StructureContains structure = <b> sun_green
            v = ( ( ( <a> . sun_green ) * <u> ) + ( ( <b> . sun_green ) * <t> ) )
            p = { <p> sun_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_blue
        if StructureContains structure = <b> sun_blue
            v = ( ( ( <a> . sun_blue ) * <u> ) + ( ( <b> . sun_blue ) * <t> ) )
            p = { <p> sun_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_lo
        if StructureContains structure = <b> ambient_mod_factor_lo
            v = ( ( ( <a> . ambient_mod_factor_lo ) * <u> ) + ( ( <b> . ambient_mod_factor_lo ) * <t> ) )
            p = { <p> ambient_mod_factor_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_hi
        if StructureContains structure = <b> ambient_mod_factor_hi
            v = ( ( ( <a> . ambient_mod_factor_hi ) * <u> ) + ( ( <b> . ambient_mod_factor_hi ) * <t> ) )
            p = { <p> ambient_mod_factor_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_lo
        if StructureContains structure = <b> mod_factor_0_lo
            v = ( ( ( <a> . mod_factor_0_lo ) * <u> ) + ( ( <b> . mod_factor_0_lo ) * <t> ) )
            p = { <p> mod_factor_0_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_hi
        if StructureContains structure = <b> mod_factor_0_hi
            v = ( ( ( <a> . mod_factor_0_hi ) * <u> ) + ( ( <b> . mod_factor_0_hi ) * <t> ) )
            p = { <p> mod_factor_0_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_lo
        if StructureContains structure = <b> mod_factor_1_lo
            v = ( ( ( <a> . mod_factor_1_lo ) * <u> ) + ( ( <b> . mod_factor_1_lo ) * <t> ) )
            p = { <p> mod_factor_1_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_hi
        if StructureContains structure = <b> mod_factor_1_hi
            v = ( ( ( <a> . mod_factor_1_hi ) * <u> ) + ( ( <b> . mod_factor_1_hi ) * <t> ) )
            p = { <p> mod_factor_1_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_red
        if StructureContains structure = <b> lev_red
            v = ( ( ( <a> . lev_red ) * <u> ) + ( ( <b> . lev_red ) * <t> ) )
            CastToInteger v
            p = { <p> lev_red = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_green
        if StructureContains structure = <b> lev_green
            v = ( ( ( <a> . lev_green ) * <u> ) + ( ( <b> . lev_green ) * <t> ) )
            CastToInteger v
            p = { <p> lev_green = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_blue
        if StructureContains structure = <b> lev_blue
            v = ( ( ( <a> . lev_blue ) * <u> ) + ( ( <b> . lev_blue ) * <t> ) )
            CastToInteger v
            p = { <p> lev_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_red
        if StructureContains structure = <b> sky_red
            v = ( ( ( <a> . sky_red ) * <u> ) + ( ( <b> . sky_red ) * <t> ) )
            CastToInteger v
            p = { <p> sky_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_green
        if StructureContains structure = <b> sky_green
            v = ( ( ( <a> . sky_green ) * <u> ) + ( ( <b> . sky_green ) * <t> ) )
            CastToInteger v
            p = { <p> sky_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_blue
        if StructureContains structure = <b> sky_blue
            v = ( ( ( <a> . sky_blue ) * <u> ) + ( ( <b> . sky_blue ) * <t> ) )
            CastToInteger v
            p = { <p> sky_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_red
        if StructureContains structure = <b> fog_red
            v = ( ( ( <a> . fog_red ) * <u> ) + ( ( <b> . fog_red ) * <t> ) )
            CastToInteger v
            p = { <p> fog_red = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_green
        if StructureContains structure = <b> fog_green
            v = ( ( ( <a> . fog_green ) * <u> ) + ( ( <b> . fog_green ) * <t> ) )
            CastToInteger v
            p = { <p> fog_green = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_blue
        if StructureContains structure = <b> fog_blue
            v = ( ( ( <a> . fog_blue ) * <u> ) + ( ( <b> . fog_blue ) * <t> ) )
            CastToInteger v
            p = { <p> fog_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_alpha
        if StructureContains structure = <b> fog_alpha
            v = ( ( ( <a> . fog_alpha ) * <u> ) + ( ( <b> . fog_alpha ) * <t> ) )
            CastToInteger v
            p = { <p> fog_alpha = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_dist
        if StructureContains structure = <b> fog_dist
            v = ( ( ( <a> . fog_dist ) * <u> ) + ( ( <b> . fog_dist ) * <t> ) )
            CastToInteger v
            p = { <p> fog_dist = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_red
        if StructureContains structure = <b> ambient_red
            v = ( ( ( <a> . ambient_red ) * <u> ) + ( ( <b> . ambient_red ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_red = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_green
        if StructureContains structure = <b> ambient_green
            v = ( ( ( <a> . ambient_green ) * <u> ) + ( ( <b> . ambient_green ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_green = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_blue
        if StructureContains structure = <b> ambient_blue
            v = ( ( ( <a> . ambient_blue ) * <u> ) + ( ( <b> . ambient_blue ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_0
        if StructureContains structure = <b> heading_0
            v = ( ( ( <a> . heading_0 ) * <u> ) + ( ( <b> . heading_0 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_0
        if StructureContains structure = <b> pitch_0
            v = ( ( ( <a> . pitch_0 ) * <u> ) + ( ( <b> . pitch_0 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_0
        if StructureContains structure = <b> red_0
            v = ( ( ( <a> . red_0 ) * <u> ) + ( ( <b> . red_0 ) * <t> ) )
            CastToInteger v
            p = { <p> red_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_0
        if StructureContains structure = <b> green_0
            v = ( ( ( <a> . green_0 ) * <u> ) + ( ( <b> . green_0 ) * <t> ) )
            CastToInteger v
            p = { <p> green_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_0
        if StructureContains structure = <b> blue_0
            v = ( ( ( <a> . blue_0 ) * <u> ) + ( ( <b> . blue_0 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_1
        if StructureContains structure = <b> heading_1
            v = ( ( ( <a> . heading_1 ) * <u> ) + ( ( <b> . heading_1 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_1
        if StructureContains structure = <b> pitch_1
            v = ( ( ( <a> . pitch_1 ) * <u> ) + ( ( <b> . pitch_1 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_1
        if StructureContains structure = <b> red_1
            v = ( ( ( <a> . red_1 ) * <u> ) + ( ( <b> . red_1 ) * <t> ) )
            CastToInteger v
            p = { <p> red_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_1
        if StructureContains structure = <b> green_1
            v = ( ( ( <a> . green_1 ) * <u> ) + ( ( <b> . green_1 ) * <t> ) )
            CastToInteger v
            p = { <p> green_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_1
        if StructureContains structure = <b> blue_1
            v = ( ( ( <a> . blue_1 ) * <u> ) + ( ( <b> . blue_1 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom1
        if StructureContains structure = <b> bloom1
            v = ( ( ( <a> . bloom1 ) * <u> ) + ( ( <b> . bloom1 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom2
        if StructureContains structure = <b> bloom2
            v = ( ( ( <a> . bloom2 ) * <u> ) + ( ( <b> . bloom2 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom2 = <v> }
        endif
    endif
    return p = <p>
endscript

script dadmod_tod_phase_params
    GetLevelStructureName
    switch <phase>
    case 1
        FormatText ChecksumName = n "%a_tod_morning_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_morning
        state = morning
    case 3
        FormatText ChecksumName = n "%a_tod_evening_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_evening
        state = evening
    case 4
        n = dadmod_tod_night_moon
        params = dadmod_tod_night_moon
        state = night
    case 5
        n = dadmod_tod_evening_lights
        params = dadmod_tod_evening_lights
        state = night
    default
        FormatText ChecksumName = n "%a_tod_afternoon_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_afternoon
        state = afternoon
    endswitch
    if GlobalExists Name = <n> Type = structure
        params = ( <n> )
    else
        params = ( <params> )
    endif
    return params = <params> state = <state>
endscript

script dadmod_tod_fade
    Change dadmod_tod_fading = 1
    dadmod_tod_phase_params phase = <from>
    a = <params>
    sa = <state>
    dadmod_tod_phase_params phase = <to>
    b = <params>
    sb = <state>
    st = <sb>
    if (<sa> = night)
        st = night
    endif
    if not InNetGame
        THUGPRO_SetLightUpdateState unpause
    endif
    Change tod_manager_inactive = 0
    TODManager_SetActive 1
    i = 1
    begin
        if (<i> > 24)
            break
        endif
        t = ( <i> / 24.0 )
        dadmod_tod_lerp a = <a> b = <b> t = <t>
        switch <st>
        case morning
            tod_manager_set_default_params morning_params = <p>
        case evening
            tod_manager_set_default_params evening_params = <p>
        case night
            tod_manager_set_default_params night_params = <p>
        default
            tod_manager_set_default_params afternoon_params = <p>
        endswitch
        Change LEVEL_TOD_STATE = <st>
        TODManager_SetTODInstant <st>
        wait 20 gameframes
        if not IsTrue dadmod_tod_fading
            return
        endif
        if LevelIs Load_MainMenu
            Change dadmod_tod_fading = 0
            return
        endif
        i = ( <i> + 1 )
    repeat
    Change dadmod_tod_custom = 1
    Change dadmod_tod_fading = 0
    dadmod_tod_refresh
endscript

script dadmod_mirror_l2
    mir = 0
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        mir = <value>
    endif
    l2 = 0
    if GotParam spin_with_L2
        l2 = 1
    endif
    if (<mir> = 1)
        l2 = (1 - <l2>)
    endif
    return l2 = <l2>
endscript

script SwitchFootPogo_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script CasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        }
    endif
endscript

script AntiCasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        }
    endif
endscript

script TruckSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script PogoSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script revert
    if not GotParam FSName
        FSName = 'FS Revert'
    endif
    if not GotParam BSName
        BSName = 'BS Revert'
    endif
    if not GotParam FSAnim
        FSAnim = RevertFS
    endif
    if not GotParam BSAnim
        BSAnim = RevertBS
    endif
    if IsSkaterOnVehicle
        goto vehicle_revert
    endif
    if IsOnMotoSkateboard
        FSAnim = RevertFS
        BSAnim = RevertBS
    endif
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        if (<value> = 1)
            a = <FSAnim>
            FSAnim = <BSAnim>
            BSAnim = <a>
        endif
    endif
    OnExitRun ExitRevert
    InRevert
    ClearLipCombos
    KillExtraTricks
    SetTrickScore 100
    OnGroundExceptions NoEndRun
    LaunchStateChangeEvent state = Skater_InRevert
    ClearException Ollied
    if not GetGlobalFlag flag = SERVER_CHEAT_NO_REVERT_SPEED_LOSS
        SetSpecialFriction [ 0 , 0 , 5 , 10 , 15 , 25 ] duration = 0.667
    endif
    CanKickOff
    SetQueueTricks SkateToWalkTricks
    NollieOff
    PressureOff
    if GotParam LandPivot
        GetBoardTypeAndRevert Type = manuallink
        PlayAnim anim = GTurn
        if InAir
            SetTrickName 'Bunny Hop Revert'
        else
            SetTrickName 'Land Pivot'
        endif
        Obj_SetFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        GetBoardTypeAndRevert Type = revert
        if InAir
            FSName = 'Bunny Hop Revert'
            BSName = 'Bunny Hop Revert'
        endif
        if Obj_FlagSet FLAG_SKATER_REVERTFS
            Obj_ClearFlag FLAG_SKATER_REVERTFS
            PlayAnim anim = <FSAnim>
            SetTrickName <FSName>
        else
            if Obj_FlagSet FLAG_SKATER_REVERTBS
                Obj_ClearFlag FLAG_SKATER_REVERTBS
                PlayAnim anim = <BSAnim>
                SetTrickName <BSName>
            else
                if LastSpinWas Frontside
                    PlayAnim anim = <FSAnim>
                    SetTrickName <FSName>
                else
                    PlayAnim anim = <BSAnim>
                    SetTrickName <BSName>
                endif
            endif
        endif
    endif
    SetSkaterAirManualTricks
    Display Blockspin
    if not IsOnMotoSkateboard
        FlipAfter
        BoardRotateAfter
    endif
    wait 0.1 seconds
    SetException ex = Ollied scr = Ollie
    if not GotParam LandPivot
        ResetLandedFromVert
    endif
    WaitAnim 100 Percent
    CanKickOn
    if GotParam LandPivot
        PlayAnim anim = Manual_Range From = middle BlendPeriod = 0.0
        DoNextManualTrick SkipInitAnim LandPivotManual
    else
        DoNextManualTrick FromAir
    endif
    DoNextTrick
    OnGroundExceptions
    LandSkaterTricks
    ClearEventBuffer
    if GotParam LandPivot
        PlayAnim anim = PutDownManual BlendPeriod = 0.3 speed = 2.5
        Obj_ClearFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        if not Held x
            PlayAnim anim = CrouchIdleToIdle BlendPeriod = 0.0 speed = 0.7
        else
            PlayAnim anim = CrouchIdle BlendPeriod = 0.0 From = 0 To = 0.3 seconds
            BlendPeriodOut 0.3
        endif
    endif
    WaitAnimWhilstChecking AndManuals
    goto OnGroundAi
endscript

dadmod_added_levels = [ #"0x001202e3" #"0x341caf9f" #"0x6552c592" #"0xe0d4e51a" #"0xf06d95da" #"0x73babdd0" #"0x16a10a9a" #"0x1a69989e" #"0x896a81b2" #"0x27eeac8d" #"0x2843fdc8" Load_dadmod_THPGFDR Load_dadmod_THPGLove Load_dadmod_THPGSlums Load_dadmod_THPGBCity Load_dadmod_THPGHarbor Load_dadmod_THPGLansdowne Load_dadmod_THPGMonuments Load_dadmod_THPGMuseums Load_dadmod_THPGMuseumInt Load_dadmod_THPGPhilly Load_dadmod_THPGBaltimore Load_dadmod_THPGWashington Load_dadmod_THPGTraining Load_dadmod_THPGLarxPhilly Load_dadmod_THPGLarxBaltimore Load_dadmod_THPGLarxWashington ]

dadmod_added_level_creators = [ "tyler.thpsX" "letmynutzgo" "letmynutzgo" "letmynutzgo" "rodafy" "letmynutzgo" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Larxian" "Larxian" "Larxian" ]

script dadmod_added_level_creator
    GetArraySize dadmod_added_levels
    <i> = 0
    begin
        if ( ( dadmod_added_levels [ <i> ] ) = <level> )
            return creator = ( dadmod_added_level_creators [ <i> ] )
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
endscript

Level_dadmod_Streets = {
game = THPS1
structure_name = Level_dadmod_Streets
load_script = #"0x001202e3"
Name = "Streets"
loading_time = 8.5
level = "Streets"
sky = "Streets_Sky"
wallride_hack
qb = "levels\\Streets\\Streets.qb"
level_qb = "levels\\Streets\\Streets_scripts.qb"
more_level_qbs = [
"levels\\Streets\\Streets_thugpro.qb"
]
pre = "Streets_scripts.pre"
scnpre = "Streetsscn.pre"
colpre = "Streetscol.pre"
default_level_stuff
}

script #"0x001202e3"
    load_level Level_dadmod_Streets
endscript

Level_dadmod_THPS2NY = {
game = THPS2
structure_name = Level_dadmod_THPS2NY
load_script = #"0x341caf9f"
Name = "New York City"
loading_time = 8.5
level = "THPS2NY"
sky = "THPS2NY_Sky"
nosun
wallride_hack
qb = "levels\\THPS2NY\\THPS2NY.qb"
level_qb = "levels\\THPS2NY\\THPS2NY_scripts.qb"
more_level_qbs = [
"levels\\THPS2NY\\THPS2NY_thugpro.qb"
]
pre = "THPS2NY_scripts.pre"
scnpre = "THPS2NYscn.pre"
colpre = "THPS2NYcol.pre"
default_level_stuff
}

script #"0x341caf9f"
    load_level Level_dadmod_THPS2NY
endscript

Level_dadmod_THPS2SS = {
game = THPS2
structure_name = Level_dadmod_THPS2SS
load_script = #"0x6552c592"
Name = "Skatestreet"
loading_time = 8.5
level = "THPS2SS"
sky = "default_sky"
indoor
nosun
wallride_hack
qb = "levels\\THPS2SS\\THPS2SS.qb"
level_qb = "levels\\THPS2SS\\THPS2SS_scripts.qb"
more_level_qbs = [
"levels\\THPS2SS\\THPS2SS_thugpro.qb"
]
pre = "THPS2SS_scripts.pre"
scnpre = "THPS2SSscn.pre"
colpre = "THPS2SScol.pre"
default_level_stuff
}

script #"0x6552c592"
    load_level Level_dadmod_THPS2SS
endscript

Level_dadmod_THPS2Bullring = {
game = THPS2
structure_name = Level_dadmod_THPS2Bullring
load_script = #"0xe0d4e51a"
Name = "Bullring"
loading_time = 8.5
level = "THPS2Bullring"
sky = "THPS2Bullring_Sky"
nosun
wallride_hack
qb = "levels\\THPS2Bullring\\THPS2Bullring.qb"
level_qb = "levels\\THPS2Bullring\\THPS2Bullring_scripts.qb"
more_level_qbs = [
"levels\\THPS2Bullring\\THPS2Bullring_thugpro.qb"
]
pre = "THPS2Bullring_scripts.pre"
scnpre = "THPS2Bullringscn.pre"
colpre = "THPS2Bullringcol.pre"
default_level_stuff
}

script #"0xe0d4e51a"
    load_level Level_dadmod_THPS2Bullring
endscript

Level_dadmod_THPS2_SH = {
game = THPS2
structure_name = Level_dadmod_THPS2_SH
load_script = #"0xf06d95da"
Name = "Skate Heaven"
loading_time = 8.5
level = "THPS2_SH"
sky = "default_sky"
nosun
qb = "levels\\THPS2_SH\\THPS2_SH.qb"
level_qb = "levels\\THPS2_SH\\THPS2_SH_scripts.qb"
more_level_qbs = [
"levels\\THPS2_SH\\THPS2_SH_thugpro.qb"
]
pre = "THPS2_SH_scripts.pre"
scnpre = "THPS2_SHscn.pre"
colpre = "THPS2_SHcol.pre"
default_level_stuff
}

script #"0xf06d95da"
    load_level Level_dadmod_THPS2_SH
endscript

Level_dadmod_THPS2ChopperDrop = {
game = THPS2
structure_name = Level_dadmod_THPS2ChopperDrop
load_script = #"0x73babdd0"
Name = "Chopper Drop"
loading_time = 8.5
level = "THPS2ChopperDrop"
sky = "THPS2ChopperDrop_Sky"
nosun
wallride_hack
qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop.qb"
level_qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop_scripts.qb"
more_level_qbs = [
"levels\\THPS2ChopperDrop\\THPS2ChopperDrop_thugpro.qb"
]
pre = "THPS2ChopperDrop_scripts.pre"
scnpre = "THPS2ChopperDropscn.pre"
colpre = "THPS2ChopperDropcol.pre"
default_level_stuff
}

script #"0x73babdd0"
    load_level Level_dadmod_THPS2ChopperDrop
endscript

Level_dadmod_P8Training = {
game = THP8
structure_name = Level_dadmod_P8Training
load_script = #"0x1a69989e"
Name = "Training"
loading_time = 8.5
level = "P8Training"
sky = "P8Training_Sky"
qb = "levels\\P8Training\\P8Training.qb"
level_qb = "levels\\P8Training\\P8Training_scripts.qb"
more_level_qbs = [
"levels\\P8Training\\P8Training_thugpro.qb"
]
pre = "P8Training_scripts.pre"
scnpre = "P8Trainingscn.pre"
colpre = "P8Trainingcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
overview_cam_pos = (-698.3,4416.4,795.5)
overview_cam_angle = 0
}

script #"0x1a69989e"
    load_level Level_dadmod_P8Training
endscript

Level_dadmod_P8Suburbs = {
game = THP8
structure_name = Level_dadmod_P8Suburbs
load_script = #"0x16a10a9a"
Name = "Suburbs"
loading_time = 8.5
level = "P8Suburbs"
sky = "P8Suburbs_Sky"
qb = "levels\\P8Suburbs\\P8Suburbs.qb"
level_qb = "levels\\P8Suburbs\\P8Suburbs_scripts.qb"
more_level_qbs = [
"levels\\P8Suburbs\\P8Suburbs_thugpro.qb"
]
pre = "P8Suburbs_scripts.pre"
scnpre = "P8Suburbsscn.pre"
colpre = "P8Suburbscol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Suburbs_goals
overview_cam_pos = (-2032.6,4565.6,-2302.5)
overview_cam_angle = 0
}

script #"0x16a10a9a"
    load_level Level_dadmod_P8Suburbs
endscript

Level_dadmod_P8Downtown = {
game = THP8
structure_name = Level_dadmod_P8Downtown
load_script = #"0x896a81b2"
Name = "Downtown"
loading_time = 8.5
level = "P8Downtown"
sky = "P8Downtown_Sky"
qb = "levels\\P8Downtown\\P8Downtown.qb"
level_qb = "levels\\P8Downtown\\P8Downtown_scripts.qb"
more_level_qbs = [
"levels\\P8Downtown\\P8Downtown_thugpro.qb"
]
pre = "P8Downtown_scripts.pre"
scnpre = "P8Downtownscn.pre"
colpre = "P8Downtowncol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Downtown_goals
overview_cam_pos = (2920.1,5821.6,-1341.0)
overview_cam_angle = 0
}

script #"0x896a81b2"
    load_level Level_dadmod_P8Downtown
endscript

Level_dadmod_P8CarFactory = {
game = THP8
structure_name = Level_dadmod_P8CarFactory
load_script = #"0x27eeac8d"
Name = "Car Factory"
loading_time = 8.5
level = "P8CarFactory"
sky = "P8CarFactory_Sky"
qb = "levels\\P8CarFactory\\P8CarFactory.qb"
level_qb = "levels\\P8CarFactory\\P8CarFactory_scripts.qb"
more_level_qbs = [
"levels\\P8CarFactory\\P8CarFactory_thugpro.qb"
]
pre = "P8CarFactory_scripts.pre"
scnpre = "P8CarFactoryscn.pre"
colpre = "P8CarFactorycol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CarFactory_goals
overview_cam_pos = (-2428.3,6098.0,3137.1)
overview_cam_angle = 0
}

script #"0x27eeac8d"
    load_level Level_dadmod_P8CarFactory
endscript

Level_dadmod_P8CretePark = {
game = THP8
structure_name = Level_dadmod_P8CretePark
load_script = #"0x2843fdc8"
Name = "Crete Park"
loading_time = 8.5
level = "P8CretePark"
sky = "P8CretePark_Sky"
qb = "levels\\P8CretePark\\P8CretePark.qb"
level_qb = "levels\\P8CretePark\\P8CretePark_scripts.qb"
more_level_qbs = [
"levels\\P8CretePark\\P8CretePark_thugpro.qb"
]
pre = "P8CretePark_scripts.pre"
scnpre = "P8CreteParkscn.pre"
colpre = "P8CreteParkcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CretePark_goals
overview_cam_pos = (-7389.1,6911.9,-2279.5)
overview_cam_angle = 0
}

script #"0x2843fdc8"
    load_level Level_dadmod_P8CretePark
endscript

script create_thugpro_level_menu_item {
    pad_choose_script = level_select_valid_choice
    }
    if GotParam hidden
        return
    endif
    if GotParam level
        FormatText ChecksumName = id "menu_%a" a = <level>
    endif
    if not ScriptExists <level>
        focusable = not_focusable
        exclude = 1
    endif
    if GotParam level
        if InNetGame
            if ArrayContains array = dadmod_added_levels contains = <level>
                if ScriptExists dadmod_level_online_ok
                    dadmod_level_online_ok level = <level>
                endif
                if not GotParam ok
                    focusable = not_focusable
                    exclude = 1
                endif
            endif
        endif
    endif
    if LevelIs Load_MainMenu
        if ( in_server_options = 1 )
            level_callback_script = THUGPRO_LevelSelect_menu_exit
        else
            level_callback_script = level_select_change_level
        endif
    else
        level_callback_script = level_select_change_level
    endif
    pad_choose_params = <...>
    if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
        GetIndexOfItemContaining { array = level_select_menu_level_info index = 0 Name = level value = <level> }
        if ( ( ( level_select_menu_level_info [ <index> ] ) . enabled ) = 1 )
            <checked> = checked
        else
            <checked> = unchecked
        endif
        <make_menu_item_script> = make_thugpro_menu_checkbox_item
        pad_option_script = level_select_valid_choice
        pad_option_params = { <...> }
    else
        pad_option_script = nullscript
        pad_option_params = { }
        <make_menu_item_script> = make_thugpro_menu_item
    endif
    if GotParam is_custompark
        current_menu_anchor : GetSingleTag custom_park_menu_index
        FormatText TextName = text <filename>
        FormatText ChecksumName = id "menu_custom_park_%i" i = <custom_park_menu_index>
        current_menu_anchor : SetTags custom_park_menu_index = ( <custom_park_menu_index> + 1 )
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = created_park_launch
            pad_option_script = level_select_valid_choice
            pad_option_params = { <...> }
        else
            level_callback_script = created_park_launch
            pad_choose_script = level_select_valid_choice
            pad_choose_params = { <...> }
        endif
    endif
    if GotParam is_premadepark
        FormatText TextName = text <Name>
        FormatText ChecksumName = id "menu_%s" s = <Name>
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = maybe_load_premade_park
            pad_option_script = maybe_load_premade_park
            pad_option_params = { slot = <slot> }
        else
            level_callback_script = maybe_load_premade_park
            pad_choose_script = maybe_load_premade_park
            pad_choose_params = { slot = <slot> }
        endif
    endif
    if not GotParam creator
        if GotParam level
            dadmod_added_level_creator level = <level>
        endif
    endif
    if GotParam level
        if ScriptExists dadmod_levelthumb_for
            dadmod_levelthumb_for level = <level>
        endif
    endif
    <make_menu_item_script> {
    text = <text>
    extra_text = <creator>
    id = <id>
    unfocus_script = thugpro_level_select_item_unfocus
    focus_script = thugpro_level_select_item_focus
    focus_params = { level = <level> text = <text> texture = <level_thumb> }
    pad_choose_script = <pad_choose_script>
    pad_choose_params = <pad_choose_params>
    pad_option_script = <pad_option_script>
    pad_option_params = <pad_option_params>
    <focusable>
    <checked>
    }
endscript

dadmod_levelthumbs_booted = 0

script dadmod_levelthumbs_boot
    if ( dadmod_levelthumbs_booted = 1 )
        return
    endif
    Change dadmod_levelthumbs_booted = 1
    if ScriptExists dadmod_levelthumbs_load
        dadmod_levelthumbs_load
    endif
endscript

script Load_MainMenu
    Load_MainMenu_scene
    KillSpawnedScript Name = dadmod_menu_watch
    SpawnScript dadmod_menu_watch
    dadmod_noclip_boot
    dadmod_speed_boot
    dadmod_levelthumbs_boot
endscript

script Load_MainMenu_scene
    level = 1
    THUGRECOMP_MenuLevel
    THUGRECOMP_MenuOpt key = "ambient_level" step = 0 index = <level>
    if GotParam live_level
        if GlobalExists Name = <live_level> Type = structure
            Change thugpro_mainmenu_east_la = 1
            load_level <live_level>
            return
        endif
    endif
    if (<level> = 0)
        Change thugpro_mainmenu_east_la = 0
        load_level level_Mainmenu
        return
    endif
    Change thugpro_mainmenu_east_la = 1
    switch <level>
    case 2
        load_level level_Mainmenu_toystory_bedroom
    case 3
        load_level level_Mainmenu_tr
    case 4
        load_level level_Mainmenu_bo
    case 5
        load_level level_Mainmenu_ba
    case 6
        load_level level_Mainmenu_be
    case 7
        load_level level_Mainmenu_au
    case 8
        load_level level_Mainmenu_no
    case 9
        load_level level_Mainmenu_st
    case 10
        load_level level_Mainmenu_se
    case 11
        load_level level_Mainmenu_se2
    case 12
        load_level level_Mainmenu_la
    case 13
        load_level level_Mainmenu_sc
    case 14
        load_level level_Mainmenu_hn
    case 15
        load_level level_Mainmenu_vn
    case 16
        load_level level_Mainmenu_sc2
    case 17
        load_level level_Mainmenu_ph
    case 18
        load_level level_Mainmenu_dj
    case 19
        load_level level_Mainmenu_ca
    case 20
        load_level level_Mainmenu_ap
    case 21
        load_level level_Mainmenu_nj
    case 22
        load_level level_Mainmenu_ny
    case 23
        load_level level_Mainmenu_fl
    case 24
        load_level level_Mainmenu_sd
    case 25
        load_level level_Mainmenu_hi
    case 26
        load_level level_Mainmenu_vc
    case 27
        load_level level_Mainmenu_sj
    case 28
        load_level level_Mainmenu_ru
    case 29
        load_level level_Mainmenu_hh
    case 30
        load_level level_Mainmenu_practice
    case 31
        load_level level_Mainmenu_sch
    case 32
        load_level level_Mainmenu_alc
    case 33
        load_level level_Mainmenu_sf2
    case 34
        load_level level_Mainmenu_kon
    case 35
        load_level level_Mainmenu_lon
    case 36
        load_level level_Mainmenu_jnk
    case 37
        load_level level_Mainmenu_zoo
    case 38
        load_level level_Mainmenu_cnv
    case 39
        load_level level_Mainmenu_hof
    case 40
        load_level level_Mainmenu_vans
    case 41
        load_level level_Mainmenu_skatepark
    case 42
        load_level level_Mainmenu_sz
    case 43
        load_level level_Mainmenu_atlanta
    case 44
        load_level level_Mainmenu_kyoto
    case 45
        load_level level_Mainmenu_hisch
    case 46
        load_level level_Mainmenu_z_funpark
    case 47
        load_level level_Mainmenu_z_center
    case 48
        load_level level_Mainmenu_z_riod
    case 49
        load_level level_Mainmenu_z_sm
    case 50
        load_level level_Mainmenu_z_bh
    case 51
        load_level level_Mainmenu_z_sv2
    case 52
        load_level level_Mainmenu_z_sr
    case 53
        load_level level_Mainmenu_z_dt
    case 54
        load_level level_Mainmenu_z_ho
    case 55
        load_level level_Mainmenu_z_lv
    case 56
        load_level level_Mainmenu_z_oi
    case 57
        load_level level_Mainmenu_foun
    case 58
        load_level level_Mainmenu_rio
    case 59
        load_level level_Mainmenu_sub
    case 60
        load_level level_Mainmenu_tok
    case 61
        load_level level_Mainmenu_shp
    case 62
        load_level level_Mainmenu_si
    case 63
        load_level level_Mainmenu_oil
    case 64
        load_level level_Mainmenu_ware
    case 65
        load_level level_Mainmenu_z_ma
    case 66
        load_level level_Mainmenu_z_dn
    case 67
        load_level level_Mainmenu_burn
    case 68
        load_level level_Mainmenu_ros
    case 69
        load_level level_Mainmenu_z_ms
    case 70
        load_level level_Mainmenu_streets
    case 71
        load_level level_Mainmenu_thps2ny
    case 72
        load_level level_Mainmenu_thps2ss
    case 73
        load_level level_Mainmenu_thps2bullring
    case 74
        load_level level_Mainmenu_thps2_sh
    case 75
        load_level level_Mainmenu_thps2chopperdrop
    case 76
        load_level level_Mainmenu_p8training
    case 77
        load_level level_Mainmenu_p8suburbs
    case 78
        load_level level_Mainmenu_p8downtown
    case 79
        load_level level_Mainmenu_p8carfactory
    case 80
        load_level level_Mainmenu_p8cretepark
    case 81
        load_level level_Mainmenu_thpgtraining
    default
        load_level level_Mainmenu_EL
    endswitch
endscript

script dadmod_menu_level_menu
    THUGRECOMP_MenuOpt key = "level" step = 0
    cur = <index>
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_menulevel
    menu_title = "Menu level"
    menu_style = MENU_STYLE_LEFT
    helper_text = generic_helper_text
    pad_back_script = dadmod_menu_level_back
    show_description_panel
    show_gradient
    scrolling
    }
    GetArraySize dadmod_menu_level_list
    i = 0
    last_game = ""
    begin
        if (<i> = <array_size>)
            break
        endif
        e = ( dadmod_menu_level_list [ <i> ] )
        g = ( <e> . game )
        if not THUGRECOMP_MenuLevelHas index = ( <e> . i )
            g = <last_game>
        endif
        if not (<g> = <last_game>)
            FormatText TextName = h "- %s -" s = <g>
            make_thugpro_menu_item {
            text = <h>
            not_focusable
            }
            last_game = <g>
        endif
        if ( ( <e> . i ) = <cur> )
            FormatText TextName = t "%s  *" s = ( <e> . name )
            d = "The level behind the main menu now"
        else
            t = ( <e> . name )
            d = "Show this level behind the main menu. It loads right away"
        endif
        if THUGRECOMP_MenuLevelHas index = ( <e> . i )
        make_thugpro_menu_item {
        text = <t>
        description_text = <d>
        pad_choose_script = dadmod_menu_level_pick
        pad_choose_params = { pick = ( <e> . i ) }
        }
        endif
        i = ( <i> + 1 )
    repeat
    dadmod_desc_panel_right
    thugpro_menu_finalize
endscript

script dadmod_menu_level_pick
    THUGRECOMP_MenuOpt key = "level" pick = <pick>
    Change dadmod_mm_armed = none
    if GotParam pending
        if (<pending> = 1)
            Change dadmod_mm_reopen = 1
            SpawnScript dadmod_reload_menu_scene
            return
        endif
    endif
    dadmod_menu_level_back
endscript

script dadmod_menu_level_back
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_setup_menu
    endif
endscript

