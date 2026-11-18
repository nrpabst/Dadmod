dadmod_idle_hold_anims = [ FrontEnd_CAS_HoldBoard_Bot FrontEnd_CAS_HoldBoard_Top ]
dadmod_idle_skate_cycle = [ Ped_M_SkateIdleB Ped_M_SkateIdleA Ped_M_SkateIdleC Ped_M_SkateIdleD ]
script dadmod_idle_shot
    <shot> = { rate = 0.8 aim = (0.0,6e+01,5e+01) eye = (-5e+01,3e+01,5e+01) }
    switch <cam_pos>
    case head
        <shot> = { rate = 0.8 aim = (0.0,6e+01,3e+01) eye = (-5e+01,1e+01,3e+01) main = Ped_M_ScratchChin }
    case torso
        <shot> = { rate = 0.95 aim = (0.0,6e+01,5e+01) eye = (-5e+01,1e+01,5e+01) main = FrontEnd_CAS_LookArms }
    case Legs
        <shot> = { rate = 0.95 aim = (0.0,1e+01,3e+01) eye = (-5e+01,1e+01,3e+01) main = FrontEnd_CAS_LookFeet }
    case board
        <shot> = { rate = 1.0 aim = (0.0,1e+01,3e+01) eye = (-5e+01,1e+01,3e+01) main = FrontEnd_CAS_HoldBoard_Bot idle_loop = FrontEnd_CAS_HoldBoard_Bot deck }
    case board_griptape
        <shot> = { rate = 1.0 aim = (0.0,1e+01,3e+01) eye = (-5e+01,1e+01,3e+01) main = FrontEnd_CAS_HoldBoard_Top idle_loop = FrontEnd_CAS_HoldBoard_Top deck }
    case graffiti
        <shot> = { rate = 0.8 aim = (0.0,6e+01,5e+01) eye = (-5e+01,3e+01,5e+01) intro = Ped_Graffiti_ShakeCan main = Ped_Graffiti_Step2BigTag tag2 = Ped_Graffiti_BigTag01 outro = Ped_Graffiti_BigTagStepBack spray }
    default
        if GotParam trans_anim_generic
            <shot> = { <shot> main = <trans_anim_generic> }
        endif
    endswitch
    return shot = <shot>
endscript
script dadmod_idle_play
    PlayAnim NoRestart speed = <rate> anim = <anim>
    Obj_WaitAnimFinished
endscript
script dadmod_idle_frozen_check
    THUGRECOMP_MenuOpt key = "frozen" step = 0
    if ( <on> = 1 )
        PausePhysics
        return
    endif
    if GotParam wake
        UnpausePhysics
    endif
endscript
script dadmod_idle_custom_skater
    select_skater_get_current_skater_name
    if ( <current_skater> = custom )
        return
    endif
    ResetLastSkaterBehaviorStuff
    Change LAST_SELECTED_SKATER_SKIN_INDEX = 0
    Change LAST_SELECTED_SKATER_LIST_INDEX = 0
    Change LAST_SELECTED_SKATER_MENU_ID = custom
    load_pro_skater { Name = custom Skater = 0 profile = 0 }
endscript
script SkateshopCasIdle
    dadmod_idle_custom_skater
    Skater : TurnOffSpecialItem
    SkaterInit ReturnControl NoAnims NoEndRun
    dadmod_idle_frozen_check
    ClearExceptions
    SwitchOffBoard
    TurnOffSpecialItem
    dadmod_idle_shot <...>
    if StructureContains structure = <shot> deck
        SwitchOnBoard
    endif
    BlendPeriodOut 0.2
    KillSkaterCamAnim All
    PlaySkaterCamAnim {
    virtual_cam
    frames = 1
    play_hold
    positionOffset = ( <shot> . eye )
    targetOffset = ( <shot> . aim )
    targetid = TRG_DummySkater
    Name = SkateShopCas_CAM
    Skater = 0
    }
    SetActiveCamera move id = SkateShopCas_CAM
    CancelRotateDisplay
    SetRollingFriction 10000
    dadmod_idle_frozen_check wake
    if StructureContains structure = <shot> spray
        TurnOnSpecialItem specialitem_details = spraycan_cas_details
    endif
    <rate> = ( <shot> . rate )
    if StructureContains structure = <shot> intro
        dadmod_idle_play rate = <rate> anim = ( <shot> . intro )
    endif
    if StructureContains structure = <shot> main
        dadmod_idle_play rate = <rate> anim = ( <shot> . main )
    endif
    if StructureContains structure = <shot> tag2
        dadmod_idle_play rate = <rate> anim = ( <shot> . tag2 )
    endif
    if StructureContains structure = <shot> outro
        dadmod_idle_play rate = <rate> anim = ( <shot> . outro )
    endif
    if StructureContains structure = <shot> spray
        TurnOffSpecialItem
    endif
    if StructureContains structure = <shot> main
        <ended> = ( <shot> . main )
        if ChecksumEquals a = <ended> b = Ped_M_SkateIdleA
            begin
                <dm_k> = 0
                begin
                    PlayAnim speed = 0.9 anim = ( dadmod_idle_skate_cycle [ <dm_k> ] )
                    Obj_WaitAnimFinished
                    <dm_k> = ( <dm_k> + 1 )
                repeat 4
            repeat
        endif
        if ArrayContains array = dadmod_idle_hold_anims contains = <ended>
            if StructureContains structure = <shot> idle_loop
                begin
                    PlayAnim speed = 0.9 anim = ( <shot> . idle_loop )
                    Obj_WaitAnimFinished
                repeat
            endif
            return
        endif
    endif
    begin
        PlayAnim speed = 0.9 anim = Ped_M_Idle1
        Obj_WaitAnimFinished
    repeat
endscript
