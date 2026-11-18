script SkateshopCasIdle
    select_skater_get_current_skater_name
    if not ( <current_skater> = custom )
        ResetLastSkaterBehaviorStuff
        load_pro_skater { profile = 0 Skater = 0 Name = custom }
        Change LAST_SELECTED_SKATER_MENU_ID = custom
        Change LAST_SELECTED_SKATER_LIST_INDEX = 0
        Change LAST_SELECTED_SKATER_SKIN_INDEX = 0
    endif
    Skater : TurnOffSpecialItem
    SkaterInit NoEndRun ReturnControl NoAnims
    THUGRECOMP_MenuOpt key = "frozen" step = 0
    if (<on> = 1)
        PausePhysics
    endif
    TurnOffSpecialItem
    SwitchOffBoard
    ClearExceptions
    speed = 1.0
    switch <cam_pos>
    case head
        <trans_anim> = Ped_M_ScratchChin
        targetOffset = (0.0,6e+01,3e+01)
        positionOffset = (-5e+01,1e+01,3e+01)
        <speed> = 0.8
        BlendPeriodOut 0.2
    case torso
        <trans_anim> = FrontEnd_CAS_LookArms
        targetOffset = (0.0,6e+01,5e+01)
        positionOffset = (-5e+01,1e+01,5e+01)
        <speed> = 0.95
        BlendPeriodOut 0.2
    case Legs
        <trans_anim> = FrontEnd_CAS_LookFeet
        targetOffset = (0.0,1e+01,3e+01)
        positionOffset = (-5e+01,1e+01,3e+01)
        <speed> = 0.95
        BlendPeriodOut 0.2
    case board
        SwitchOnBoard
        <trans_anim> = FrontEnd_CAS_HoldBoard_Bot
        <idle_anim> = FrontEnd_CAS_HoldBoard_Bot
        targetOffset = (0.0,1e+01,3e+01)
        positionOffset = (-5e+01,1e+01,3e+01)
        <show_board> = show_board
        BlendPeriodOut 0.2
    case board_griptape
        SwitchOnBoard
        <trans_anim> = FrontEnd_CAS_HoldBoard_Top
        <idle_anim> = FrontEnd_CAS_HoldBoard_Top
        targetOffset = (0.0,1e+01,3e+01)
        positionOffset = (-5e+01,1e+01,3e+01)
        <show_board> = show_board
        BlendPeriodOut 0.2
    case graffiti
        <in_anim> = Ped_Graffiti_ShakeCan
        <trans_anim> = Ped_Graffiti_Step2BigTag
        <trans_anim2> = Ped_Graffiti_BigTag01
        <Out_Anim> = Ped_Graffiti_BigTagStepBack
        BlendPeriodOut 0.2
        targetOffset = (0.0,6e+01,5e+01)
        positionOffset = (-5e+01,3e+01,5e+01)
        speed = 0.8
        show_spraycan = 1
    default
        <trans_anim> = <trans_anim_generic>
        targetOffset = (0.0,6e+01,5e+01)
        positionOffset = (-5e+01,3e+01,5e+01)
        <speed> = 0.8
        BlendPeriodOut 0.2
    endswitch
    KillSkaterCamAnim All
    Skater : Obj_GetId
    PlaySkaterCamAnim {
    Skater = 0
    Name = SkateShopCas_CAM
    targetid = TRG_DummySkater
    targetOffset = <targetOffset>
    positionOffset = <positionOffset>
    play_hold
    frames = 1
    virtual_cam
    }
    SetActiveCamera id = SkateShopCas_CAM move
    if not Obj_HasModelLights
        script_assert "No skater lighting!"
    endif
    CancelRotateDisplay
    SetRollingFriction 10000
    THUGRECOMP_MenuOpt key = "frozen" step = 0
    if (<on> = 1)
        PausePhysics
    else
        UnpausePhysics
    endif
    if GotParam show_spraycan
        TurnOnSpecialItem specialitem_details = spraycan_cas_details
    endif
    if GotParam in_anim
        PlayAnim anim = <in_anim> speed = <speed> NoRestart
        Obj_WaitAnimFinished
    endif
    if GotParam trans_anim
        PlayAnim anim = <trans_anim> speed = <speed> NoRestart
        Obj_WaitAnimFinished
    endif
    if GotParam trans_anim2
        PlayAnim anim = <trans_anim2> speed = <speed> NoRestart
        Obj_WaitAnimFinished
    endif
    if GotParam Out_Anim
        PlayAnim anim = <Out_Anim> speed = <speed> NoRestart
        Obj_WaitAnimFinished
    endif
    if GotParam show_spraycan
        TurnOffSpecialItem
    endif
    Animations = [
    FrontEnd_CAS_HoldBoard_Bot
    FrontEnd_CAS_HoldBoard_Top
    Ped_M_SkateIdleA
    ]
    if ArrayContains array = <Animations> contains = <trans_anim>
        if ( <trans_anim> = Ped_M_SkateIdleA )
            begin
                PlayAnim anim = Ped_M_SkateIdleB speed = 0.9
                Obj_WaitAnimFinished
                PlayAnim anim = Ped_M_SkateIdleA speed = 0.9
                Obj_WaitAnimFinished
                PlayAnim anim = Ped_M_SkateIdleC speed = 0.9
                Obj_WaitAnimFinished
                PlayAnim anim = Ped_M_SkateIdleD speed = 0.9
                Obj_WaitAnimFinished
            repeat
        else
            if GotParam idle_anim
                begin
                    PlayAnim anim = <idle_anim> speed = 0.9
                    Obj_WaitAnimFinished
                repeat
            endif
            return
        endif
    endif
    begin
        PlayAnim anim = Ped_M_Idle1 speed = 0.9
        Obj_WaitAnimFinished
    repeat
endscript
