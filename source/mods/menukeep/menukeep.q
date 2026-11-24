dadmod_mk_chat = 0
dadmod_mk_game = 0
dadmod_mk_keep = 0
script dadmod_chatkeep_save
    Change dadmod_mk_game = ( dadmod_mk_game + 1 )
    Change dadmod_mk_keep = 0
    dadmod_mk_pause_open
    if ( <mk_po> = 1 )
        Change dadmod_mk_keep = 1
        KillSpawnedScript Name = dadmod_mk_keep_clear
        SpawnScript dadmod_mk_keep_clear NotSessionSpecific = 1
    endif
endscript
script dadmod_mk_keep_clear
    wait 1 gameframe
    Change dadmod_mk_keep = 0
endscript
script dadmod_mk_pause_open
    mk_p = 0
    if InNetGame
        if not LevelIs Load_MainMenu
            if not IsTrue is_changing_levels
                if not IsObserving
                    if ScreenElementExists id = current_menu_anchor
                        dadmod_mk_menu_state
                        if ( <mk_menu_state> = on )
                            mk_p = 1
                        endif
                    endif
                endif
            endif
        endif
    endif
    if ScreenElementExists id = keyboard_anchor
        mk_p = 0
    endif
    if ScreenElementExists id = dialog_box_anchor
        mk_p = 0
    endif
    if ScreenElementExists id = quit_dialog_anchor
        mk_p = 0
    endif
    if ScreenElementExists id = rankings_anchor
        mk_p = 0
    endif
    if ScreenElementExists id = view_goals_menu
        mk_p = 0
    endif
    return mk_po = <mk_p>
endscript
script dadmod_mk_keeping
    mk_k = 0
    if ( dadmod_mk_keep = 1 )
        if ScreenElementExists id = current_menu_anchor
            mk_k = 1
        endif
    endif
    return mk_keeping = <mk_k>
endscript
script sound_options_exit
    if GotParam just_remove
        dadmod_mk_keeping
        if ( <mk_keeping> = 1 )
            return
        endif
    endif
    sound_options_exit_orig <...>
endscript
script edit_tricks_menu_exit
    if GotParam just_remove
        dadmod_mk_keeping
        if ( <mk_keeping> = 1 )
            return
        endif
    endif
    edit_tricks_menu_exit_orig <...>
endscript
script dadmod_mk_menu_state
    menu_state = off
    if ScreenElementExists id = root_window
        root_window : GetSingleTag menu_state
    endif
    return mk_menu_state = <menu_state>
endscript
script dadmod_mk_busy
    mk_bz = 0
    if InNetGame
        if not LevelIs Load_MainMenu
            if ScreenElementExists id = current_menu_anchor
                dadmod_mk_menu_state
                if ( <mk_menu_state> = on )
                    mk_bz = 1
                endif
            endif
            if ScreenElementExists id = keyboard_anchor
                mk_bz = 1
            endif
            if ( dadmod_mk_chat = 1 )
                mk_bz = 1
            endif
            if ScreenElementExists id = dialog_box_anchor
                mk_bz = 0
            endif
            if ScreenElementExists id = quit_dialog_anchor
                mk_bz = 0
            endif
            if ScreenElementExists id = rankings_anchor
                mk_bz = 0
            endif
        endif
    endif
    return mk_busy = <mk_bz>
endscript
script dadmod_mk_hostauto
    mk_au = 0
    if OnServer
        if GetGlobalFlag flag = FLAG_AUTO_SERVER_MODE
            mk_au = 1
        endif
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            mk_au = 1
        endif
    endif
    return mk_auto = <mk_au>
endscript
script create_rankings
    dadmod_mk_busy
    if ( <mk_busy> = 1 )
        dadmod_mk_hostauto
        if ( <mk_auto> = 0 )
            if OnServer
                MarkGameOver
            endif
            HideClock
            mk_g = ( dadmod_mk_game )
            KillSpawnedScript Name = dadmod_mk_rank_wait
            SpawnScript dadmod_mk_rank_wait params = { <...> dadmod_mk_g = <mk_g> }
            return
        endif
    endif
    create_rankings_orig <...>
endscript
script dadmod_mk_rank_wait
    begin
        wait 3 gameframes
        if not InNetGame
            return
        endif
        if LevelIs Load_MainMenu
            return
        endif
        if IsTrue is_changing_levels
            return
        endif
        if not ( <dadmod_mk_g> = ( dadmod_mk_game ) )
            return
        endif
        dadmod_mk_busy
        if ( <mk_busy> = 0 )
            break
        endif
    repeat
    create_rankings_orig <...>
endscript
script create_onscreen_keyboard
    Change dadmod_mk_chat = 0
    create_onscreen_keyboard_orig <...>
endscript
script dadmod_mk_chat_opened
    if ScreenElementExists id = keyboard_anchor
        Change dadmod_mk_chat = 1
        KillSpawnedScript Name = dadmod_mk_chat_watch
        SpawnScript dadmod_mk_chat_watch NotSessionSpecific = 1
    endif
endscript
script enter_kb_chat
    enter_kb_chat_orig <...>
    dadmod_mk_chat_opened
endscript
script launch_chat_keyboard
    launch_chat_keyboard_orig <...>
    dadmod_mk_chat_opened
endscript
script launch_quick_menu_keyboard
    launch_quick_menu_keyboard_orig <...>
    dadmod_mk_chat_opened
endscript
script cancel_enter_chat_menu
    Change dadmod_mk_chat = 0
    cancel_enter_chat_menu_orig <...>
endscript
script cancel_chat_menu
    Change dadmod_mk_chat = 0
    cancel_chat_menu_orig <...>
endscript
script dadmod_mk_safe
    mk_sf = 1
    if not InNetGame
        mk_sf = 0
    endif
    if IsTrue is_changing_levels
        mk_sf = 0
    endif
    if ScreenElementExists id = current_menu_anchor
        mk_sf = 0
    endif
    if ScreenElementExists id = keyboard_anchor
        mk_sf = 0
    endif
    if ScreenElementExists id = dialog_box_anchor
        mk_sf = 0
    endif
    if ScreenElementExists id = quit_dialog_anchor
        mk_sf = 0
    endif
    if ScreenElementExists id = rankings_anchor
        mk_sf = 0
    endif
    if ScreenElementExists id = ped_speech_dialog
        mk_sf = 0
    endif
    if ScreenElementExists id = goal_start_dialog
        mk_sf = 0
    endif
    if ScreenElementExists id = goal_description_anchor
        mk_sf = 0
    endif
    return mk_safe = <mk_sf>
endscript
script dadmod_mk_chat_watch
    mk_txt = ""
    mk_calm = 0
    mk_gone = 0
    begin
        wait 1 gameframe
        if not ( dadmod_mk_chat = 1 )
            return
        endif
        if ScreenElementExists id = keyboard_current_string
            GetTextElementString id = keyboard_current_string
            if GotParam String
                mk_txt = <String>
            endif
            mk_calm = 0
            mk_gone = 0
        else
            if LevelIs Load_MainMenu
                Change dadmod_mk_chat = 0
                return
            endif
            mk_gone = ( <mk_gone> + 1 )
            if ( <mk_gone> > 3600 )
                Change dadmod_mk_chat = 0
                return
            endif
            dadmod_mk_safe
            if ( <mk_safe> = 1 )
                mk_calm = ( <mk_calm> + 1 )
            else
                mk_calm = 0
            endif
            if ( <mk_calm> > 8 )
                dadmod_mk_reopen mk_text = <mk_txt>
                mk_calm = 0
                mk_gone = 0
            endif
        endif
    repeat
endscript
script dadmod_mk_reopen mk_text = ""
    DestroyIfObjectExist id = bg_container
    create_onscreen_keyboard {
    allow_cancel no_buttons text_block
    Pos = (3.2e+02,2.6e+02)
    keyboard_cancel_script = cancel_enter_chat_menu
    keyboard_done_script = entered_chat_message
    display_text = "Enter message"
    keyboard_title = "Enter message"
    min_length = 1
    max_length = 75
    display_text_scale = 0.5
    text = <mk_text>
    }
    if ScreenElementExists id = keyboard_display_string
        FormatText TextName = shown "%s_" s = <mk_text>
        SetScreenElementProps id = keyboard_display_string text = <shown>
    endif
    if ScreenElementExists id = keyboard_anchor
        Change dadmod_mk_chat = 1
    endif
endscript
script dadmod_mk_is_cmd
    mk_cm = 0
    StringToCharArray String = <mk_text>
    GetArraySize <char_array>
    if ( <array_size> > 0 )
        if ( ( <char_array> [ 0 ] ) = "!" )
            mk_cm = 1
        endif
        if ( ( <char_array> [ 0 ] ) = "?" )
            mk_cm = 1
        endif
        if ( ( <char_array> [ 0 ] ) = "/" )
            mk_cm = 1
        endif
    endif
    return mk_cmd = <mk_cm>
endscript
script dadmod_mk_join mk_from = 0 mk_to = 0
    mk_out = ""
    mk_i = <mk_from>
    if ( <mk_to> > <mk_i> )
        begin
            FormatText TextName = mk_tmp "%a%b" a = <mk_out> b = ( <mk_chars> [ <mk_i> ] )
            mk_out = <mk_tmp>
            mk_i = ( <mk_i> + 1 )
            if not ( <mk_to> > <mk_i> )
                break
            endif
        repeat
    endif
    return mk_joined = <mk_out>
endscript
script dadmod_mk_split mk_max = 80
    StringToCharArray String = <mk_text>
    GetArraySize <char_array>
    mk_n = <array_size>
    if not ( <mk_n> > <mk_max> )
        return mk_first = <mk_text> mk_rest = "" mk_more = 0
    endif
    mk_cut = <mk_max>
    mk_skip = <mk_max>
    mk_low = ( <mk_max> - 25 )
    mk_i = <mk_max>
    begin
        if not ( <mk_i> > <mk_low> )
            break
        endif
        if ( ( <char_array> [ <mk_i> ] ) = " " )
            mk_cut = <mk_i>
            mk_skip = ( <mk_i> + 1 )
            break
        endif
        mk_i = ( <mk_i> - 1 )
    repeat
    if ( <mk_cut> = <mk_skip> )
        if ( ( <char_array> [ ( <mk_cut> - 1 ) ] ) = "\\" )
            mk_cut = ( <mk_cut> - 1 )
            mk_skip = <mk_cut>
        endif
    endif
    dadmod_mk_join mk_chars = <char_array> mk_from = 0 mk_to = <mk_cut>
    mk_a = <mk_joined>
    dadmod_mk_join mk_chars = <char_array> mk_from = <mk_skip> mk_to = <mk_n>
    mk_b = <mk_joined>
    mk_m = 0
    if ( <mk_n> > <mk_skip> )
        mk_m = 1
    endif
    return mk_first = <mk_a> mk_rest = <mk_b> mk_more = <mk_m>
endscript
script dadmod_mk_send_budget
    GetPreferenceString pref_type = network network_id
    mk_name_len = 16
    if GotParam ui_string
        THUGPRO_StrLen String = <ui_string>
        mk_name_len = <length>
    endif
    mk_b = ( ( TEXT_ELEMENT_MAX_LENGTH ) - <mk_name_len> - 11 )
    if ( <mk_b> < 30 )
        mk_b = 30
    endif
    return mk_budget = <mk_b>
endscript
script entered_chat_message
    Change dadmod_mk_chat = 0
    if ScreenElementExists id = keyboard_current_string
        GetTextElementString id = keyboard_current_string
        if GotParam String
            dadmod_mk_is_cmd mk_text = <String>
            if ( <mk_cmd> = 0 )
                dadmod_mk_send_budget
                THUGPRO_StrLen String = <String>
                if ( <length> > <mk_budget> )
                    destroy_onscreen_keyboard
                    DestroyIfObjectExist id = bg_container
                    SpawnScript dadmod_mk_send_parts params = { mk_text = <String> mk_max = <mk_budget> }
                    return
                endif
            endif
        endif
    endif
    entered_chat_message_orig <...>
endscript
script dadmod_mk_send_parts
    Get_FontColor_ValueAndName
    mk_left = <mk_text>
    begin
        dadmod_mk_split mk_text = <mk_left> mk_max = <mk_max>
        FormatText TextName = mk_line "%c%s" c = <value> s = <mk_first>
        SendChatMessage String = <mk_line>
        if ( <mk_more> = 0 )
            break
        endif
        mk_left = <mk_rest>
        wait 0.75 seconds
    repeat 4
endscript
script create_console_message
    if GotParam text
        THUGPRO_StrLen String = <text>
        if ( <length> > ( TEXT_ELEMENT_MAX_LENGTH ) )
            dadmod_mk_console_long <...>
            return
        endif
    endif
    create_console_message_orig <...>
endscript
script dadmod_mk_console_long
    IsChatMessage = 0
    SplitConsoleMessage String = <text>
    if ( <IsChatMessage> = 1 )
        if GotParam split_msg
            dadmod_mk_is_cmd mk_text = <split_msg>
            if ( <mk_cmd> = 1 )
                create_console_message_orig <...>
                return
            endif
            mk_col = ""
            StringToCharArray String = <split_msg>
            GetArraySize <char_array>
            if ( <array_size> > 2 )
                if ( ( <char_array> [ 0 ] ) = "\\" )
                    if ( ( <char_array> [ 1 ] ) = "c" )
                        dadmod_mk_join mk_chars = <char_array> mk_from = 0 mk_to = 3
                        mk_col = <mk_joined>
                    endif
                endif
            endif
            FormatText TextName = mk_pre "%n\\c0 : " n = <split_name>
            THUGPRO_StrLen String = <mk_pre>
            mk_max = ( ( TEXT_ELEMENT_MAX_LENGTH ) - <length> - 4 )
            if ( <mk_max> < 20 )
                create_console_message_orig <...>
                return
            endif
            mk_left = <split_msg>
            mk_k = 0
            begin
                dadmod_mk_split mk_text = <mk_left> mk_max = <mk_max>
                if ( <mk_k> = 0 )
                    FormatText TextName = mk_line "%p%s" p = <mk_pre> s = <mk_first>
                else
                    FormatText TextName = mk_line "%p%c%s" p = <mk_pre> c = <mk_col> s = <mk_first>
                endif
                create_console_message_orig <...> text = <mk_line>
                if ( <mk_more> = 0 )
                    break
                endif
                mk_left = <mk_rest>
                mk_k = 1
            repeat 4
            return
        endif
    endif
    mk_left = <text>
    begin
        dadmod_mk_split mk_text = <mk_left> mk_max = ( ( TEXT_ELEMENT_MAX_LENGTH ) - 2 )
        create_console_message_orig <...> text = <mk_first>
        if ( <mk_more> = 0 )
            break
        endif
        mk_left = <mk_rest>
    repeat 4
endscript
