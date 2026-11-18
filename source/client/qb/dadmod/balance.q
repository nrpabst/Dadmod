dadmod_balance_was_net = 0

script dadmod_balance_online
    if InNetGame
        if NOT GameModeEquals is_singlesession
            return online = 1
        endif
    endif
    return online = 0
endscript

script dadmod_balance_net_watch
    begin
        wait 30 gameframes
        dadmod_balance_moved = 0
        if THUGRECOMP_SettingLoad key = "balance_mode"
            if NOT ( <value> = 1 )
                dadmod_balance_moved = 1
            endif
        endif
        dadmod_balance_online
        if ( <online> = 1 )
            if ( ( dadmod_balance_was_net ) = 0 )
                Change dadmod_balance_was_net = 1
                if ( <dadmod_balance_moved> = 1 )
                    dadmod_balance_apply
                endif
            endif
        else
            if ( ( dadmod_balance_was_net ) = 1 )
                Change dadmod_balance_was_net = 0
                if ( <dadmod_balance_moved> = 1 )
                    dadmod_balance_apply
                endif
            endif
        endif
    repeat
endscript
