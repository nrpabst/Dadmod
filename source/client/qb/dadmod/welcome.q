dadmod_welcomed = 0

script dadmod_welcome
    Create_Panel_Message {
    text = "Dadmod @DADMOD_VERSION@ beta"
    id = dadmod_welcome_text
    font_face = crillee
    scale = 0.3
    style = dadmod_welcome_style
    rgba = [ 128 128 128 255 ]
    Pos = (165.0,3.4e+02)
    }
    KillSpawnedScript Name = dadmod_welcome_matrix
    SpawnScript dadmod_welcome_matrix
    Change dadmod_upd_front = 1
    dadmod_update_watch_start
endscript

script dadmod_welcome_matrix
    t = 0.0
    begin
        if not ScreenElementExists id = dadmod_welcome_text
            break
        endif
        if ( <t> > 3.4 )
            break
        endif
        if ( <t> > 2.9 )
            THUGRECOMP_ScanText text = "Dadmod @DADMOD_VERSION@ beta" mode = 5 t = ( <t> * 30.0 ) reveal = 0.0
            SetScreenElementProps id = dadmod_welcome_text text = <text>
        else
            if ( <t> > 0.9 )
                SetScreenElementProps id = dadmod_welcome_text text = "Dadmod @DADMOD_VERSION@ beta"
            else
                THUGRECOMP_ScanText text = "Dadmod @DADMOD_VERSION@ beta" mode = 5 t = ( <t> * 30.0 ) reveal = ( <t> / 0.9 )
                SetScreenElementProps id = dadmod_welcome_text text = <text>
            endif
        endif
        t = ( <t> + 0.0167 )
        wait 1 gameframe
    repeat
endscript

script dadmod_welcome_style
    DoMorph time = 0 scale = 0.3 alpha = 0
    DoMorph time = 0.15 scale = 0.3 alpha = 1
    DoMorph time = 0.75 scale = 0.3 alpha = 1
    DoMorph time = 2.0 scale = 0.3 alpha = 1
    DoMorph time = 0.5 scale = 0.3 alpha = 0
    Die
endscript
