script Land2 {
    RevertTime = 5
    }
    if not SkaterIsFlipping
        DoPerfectCheck
    endif
    AllowRailTricks
    NollieOff
    PressureOff
    ClearLipCombos
    if LandingFromBankDrop
        ResetLandedFromVert
        ResetLandingFromBankDrop
    endif
    if LandedFromVert
        OverrideCancelGround
        Obj_ClearFlag FLAG_SKATER_MANUALCHEESE
        GetSpeed
        if ( <speed> > 250 )
            dadmod_bhra_easy_time RevertTime = <RevertTime>
            SetExtraTricks_Reverts duration = <RevertTime>
            dadmod_bhra_land2_arm RevertTime = <RevertTime>
        endif
        if AnimEquals [ ToTail_In ToTail_Idle ToTail_Out ]
            SetTrickName "To Tail"
            SetTrickScore 500
            Display
            CopingHit Terrain = 3
            flip
        endif
    else
        if IsTrue landpivotson
            if ( ( ( GetGlobalFlag flag = FLAG_EXPERT_MODE_NO_MANUALS ) or ( GetGlobalFlag flag = FLAG_G_EXPERT_MODE_NO_MANUALS ) )
                or ( ( GetGlobalFlag flag = FLAG_EXPERT_MODE_NO_REVERTS ) or ( GetGlobalFlag flag = FLAG_G_EXPERT_MODE_NO_REVERTS ) ) )
            else
                GetSpeed
                if ( <speed> > 250 )
                    dadmod_bhra_easy_time RevertTime = <RevertTime>
                    SetExtraTricks tricks = LandPivot duration = <RevertTime>
                    dadmod_bhra_land2_arm RevertTime = <RevertTime> pivot = 1
                endif
            endif
        endif
        DoNextManualTrick FromAir
    endif
    GetAirtime
    if Crouched
        if GotParam LittleAir
            PlayAnim anim = CrouchedLand_Tiny BlendPeriod = 0.1
        else
            if Backwards
                if IsOnMotoSkateboard
                    if LandedFromVert
                        manual_turnaround
                        PlayAnim random( @ anim = SketchyCrouchLand @ anim = SketchyLand1 ) BlendPeriod = 0.1
                    else
                        PlayAnim anim = RevertFS Backwards BlendPeriod = 0 speed = 2.0
                        FlipAfter
                    endif
                else
                    FlipAndRotate
                    PlayAnim randomnorepeat( @ anim = CrouchedLandTurn4 @ anim = CrouchedLandTurn5 ) BlendPeriod = 0.0
                    BoardRotate
                endif
            else
                if YawBetween (45.0,6e+01)
                    if AirTimeGreaterThan 0.75 second
                        PlayAnim random( @ anim = SketchyCrouchLand @ anim = SketchyLand1 ) BlendPeriod = 0.1
                    else
                        PlayLandAnim <...>
                    endif
                else
                    PlayLandAnim <...>
                endif
            endif
        endif
    else
        if GotParam LittleAir
            PlayAnim anim = StandingLand_Tiny BlendPeriod = 0.1
        else
            if Backwards
                if IsOnMotoSkateboard
                    if LandedFromVert
                        manual_turnaround
                        PlayAnim random( @ anim = SketchyLand @ anim = SketchyLand1 ) BlendPeriod = 0.1
                    else
                        PlayAnim anim = RevertFS Backwards BlendPeriod = 0 speed = 2.0
                        FlipAfter
                    endif
                else
                    FlipAndRotate
                    PlayAnim random( @ anim = StandingLandTurn @ anim = StandingLandTurn1 ) BlendPeriod = 0
                    BoardRotate
                endif
            else
                if YawBetween (45.0,6e+01)
                    if AirTimeGreaterThan 0.5 second
                        PlayAnim random( @ anim = SketchyLand @ anim = SketchyLand1 ) BlendPeriod = 0.1
                    else
                        PlayLandAnim <...>
                    endif
                else
                    PlayLandAnim <...>
                endif
            endif
        endif
    endif
    ClearTrickQueue
    ClearEventBuffer buttons = [ x ]
    SetSkaterAirManualTricks
    OnGroundExceptions NoEndRun
    if GotParam bhra_arm
        OnExceptionRun dadmod_bhra_land2_out
    else
        OnExceptionRun LandSkaterTricks
    endif
    if GoalManager_GoalShouldExpire
        no_ollies = 1
        if GotParam bhra_arm
            if IsTrue dadmod_bhra_keep
                bhra_keepz = 1
            endif
        endif
    endif
    if GotParam no_ollies
        if GotParam bhra_keepz
        else
            ClearException Ollied
        endif
        ClearException GroundGone
        ClearException WallPush
        SetQueueTricks NoTricks
        if GotParam bhra_keepz
            OnExceptionRun dadmod_bhra_land2_out
        endif
    endif
    if GotParam NoReverts
    else
        if LandedFromVert
            ResetLandedFromVert
            ResetLandingFromBankDrop
            begin
                wait 1
            repeat <RevertTime>
        else
            begin
                DoNextManualTrick FromAir
                wait 1
            repeat 10
        endif
    endif
    KillExtraTricks
    LandSkaterTricks
    OnExceptionRun
    OnGroundExceptions
    CheckForNetBrake
    WaitAnimWhilstChecking AndManuals
    goto OnGroundAi
endscript
script SkateIn_Right
    if SkateInAble right
        SkateIn = 1
    else
        if GotParam Swerve
            if THUGPRO_NearGround move right
                SkateIn = 1
                params = { no_land_anim = 1 }
                Obj_MoveToPos <NearGroundPos>
            endif
        endif
    endif
    if GotParam SkateIn
        printf "SkateInable RIGHT >>>>>>>>>>>>>>>>>>>>>>>>"
        SetLandedFromVert
        if THUGPRO_MaybeDropdown right
        endif
        Rotate y = -30 duration = 0.2 seconds
        SetState GROUND
        if not IsSkaterOnVehicle
            dadmod_bhra_skatein_exc
        endif
        dadmod_bhra_dd_arm
        if GotParam bhra_arm
            OnExceptionRun dadmod_bhra_skatein_out
        else
            OnExceptionRun SkateInOrBail_Out
        endif
        SetQueueTricks NoTricks
        SetManualTricks NoTricks
        SetExtraTricks_Reverts duration = 50
        if IsSkaterOnVehicle
            goto vehicle_rail_exit params = { callback = Vehicle_Land }
        else
            if GotParam OutAnim
                PlayAnim anim = <OutAnim> BlendPeriod = 0.3 speed = <InitOutSpeed>
            else
                PlayAnim anim = <InitAnim> Backwards BlendPeriod = 0.3 speed = <InitOutSpeed>
            endif
            WaitAnimWhilstChecking
            if GotParam bhra_arm
                dadmod_bhra_dd_easy_wait
            endif
            goto SkateInLand params = <params>
        endif
    else
        printf "Not SkateInAble right >>>>>>>>>>>>>>>>>>>>>>>>"
        move y = <MoveY>
        wait 1 frame
        move x = <MoveX>
        if IsSkaterOnVehicle
            vehicle_rail_exit params = { callback = vehicle_bail }
        else
            SkateIn_Bail <...> dir = right
        endif
    endif
endscript
script SkateIn_Left
    if SkateInAble left
        SkateIn = 1
    else
        if GotParam Swerve
            if THUGPRO_NearGround move left
                SkateIn = 1
                params = { no_land_anim = 1 }
                Obj_MoveToPos <NearGroundPos>
            endif
        endif
    endif
    if GotParam SkateIn
        printf "SkateInAble LEFT >>>>>>>>>>>>>>>>>>>>>>>>"
        SetLandedFromVert
        if THUGPRO_MaybeDropdown left
        endif
        Rotate y = 30 duration = 0.2 seconds
        SetState GROUND
        if not IsSkaterOnVehicle
            dadmod_bhra_skatein_exc
        endif
        dadmod_bhra_dd_arm
        if GotParam bhra_arm
            OnExceptionRun dadmod_bhra_skatein_out
        else
            OnExceptionRun SkateInOrBail_Out
        endif
        SetQueueTricks NoTricks
        SetManualTricks NoTricks
        SetExtraTricks_Reverts duration = 50
        if IsSkaterOnVehicle
            goto vehicle_rail_exit params = { callback = Vehicle_Land }
        else
            if GotParam OutAnim
                PlayAnim anim = <OutAnim> BlendPeriod = 0.3 speed = <InitOutSpeed>
            else
                PlayAnim anim = <InitAnim> Backwards BlendPeriod = 0.3 speed = <InitOutSpeed>
            endif
            WaitAnimWhilstChecking
            if GotParam bhra_arm
                dadmod_bhra_dd_easy_wait
            endif
            goto SkateInLand params = <params>
        endif
    else
        printf "Not SkateInAble left >>>>>>>>>>>>>>>>>>>>>>>>"
        move y = <MoveY>
        wait 1 frame
        move x = <MoveX>
        if IsSkaterOnVehicle
            vehicle_rail_exit params = { callback = vehicle_bail }
        else
            SkateIn_Bail <...> dir = left
        endif
    endif
endscript
script land
    dadmod_bhra_flush
    goto land_orig params = { <...> }
endscript
script BailSkaterTricks
    dadmod_bhra_flush
    BailSkaterTricks_orig <...>
endscript
script grind
    dadmod_bhra_flush
    goto grind_orig params = { <...> }
endscript
script Ollie
    dadmod_bhra_ollie_mark
    goto Ollie_orig params = { <...> }
endscript
script Wallride
    dadmod_bhra_flush
    goto Wallride_orig params = { <...> }
endscript
script dadmod_bhra_pivot_land
    ClearEventBuffer
    if InAir
        PlayAnim anim = PutDownManual BlendPeriod = 0.3 speed = 2.5
    else
    if GotParam revert_style
        if not Held x
            PlayAnim anim = CrouchIdleToIdle BlendPeriod = 0.2 speed = 0.7
        else
            PlayAnim anim = CrouchIdle BlendPeriod = 0.2 From = 0 To = 0.3 seconds
            BlendPeriodOut 0.3
        endif
    else
        PlayAnim anim = PutDownManual BlendPeriod = 0.3 speed = 2.5
    endif
    endif
    Obj_ClearFlag FLAG_SKATER_IN_LAND_PIVOT
    if InAir
        ClearException Ollied
        if GoalManager_GoalShouldExpire
            OnGroundExceptions NoEndRun
            WaitAnimWhilstChecking AndManuals
            if not OnGround
                SetState GROUND
            endif
            OnGroundExceptions NoEndRun
            begin
                wait 1 gameframe
            repeat 30
            goto OnGroundAi
        endif
        WaitAnimWhilstChecking AndManuals
        goto OnGroundAi
    endif
    if not OnGround
        SetState GROUND
    endif
    OnGroundExceptions NoEndRun
    RevertTime = 5
    dadmod_bhra_easy_time RevertTime = <RevertTime>
    SetExtraTricks tricks = LandPivot duration = <RevertTime>
    dadmod_bhra_land2_arm RevertTime = <RevertTime> pivot = 1
    if GoalManager_GoalShouldExpire
        if GotParam bhra_arm
            if IsTrue dadmod_bhra_keep
                bhra_keepz = 1
            endif
        endif
        if GotParam bhra_keepz
            ClearException GroundGone
            ClearException WallPush
            SetQueueTricks NoTricks
        else
            LandSkaterTricks
            WaitAnimWhilstChecking AndManuals
            goto OnGroundAi
        endif
    endif
    if GotParam bhra_arm
        OnExceptionRun dadmod_bhra_land2_out
    else
        OnExceptionRun LandSkaterTricks
    endif
    begin
        DoNextManualTrick FromAir
        wait 1 gameframe
    repeat 10
    KillExtraTricks
    LandSkaterTricks
    OnExceptionRun
    OnGroundExceptions
    WaitAnimWhilstChecking AndManuals
    goto OnGroundAi
endscript
