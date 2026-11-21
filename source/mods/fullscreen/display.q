script dadmod_disp_rows
    if ScreenElementExists id = gfx_windowed
        THUGRECOMP_DisplayLive key = "mode" step = 0
        thugpro_menu_item_update_extra_text id = gfx_windowed text = <text>
    endif
    if ScreenElementExists id = gfx_res
        THUGRECOMP_DisplayLive key = "res" step = 0
        thugpro_menu_item_update_extra_text id = gfx_res text = <text>
    endif
    if ScreenElementExists id = gfx_vsync
        THUGRECOMP_DisplayLive key = "vsync" step = 0
        thugpro_menu_item_update_extra_text id = gfx_vsync text = <text>
    endif
    THUGRECOMP_DisplayLive key = "apply" step = 0
    if ScreenElementExists id = gfx_dispapply
        thugpro_menu_item_update_extra_text id = gfx_dispapply text = <text>
    endif
    return disp_wait = <wait>
endscript
script dadmod_disp_apply
    THUGRECOMP_DisplayLive key = "apply" step = 1
    dadmod_disp_rows
    if (<disp_wait> > 0)
        KillSpawnedScript Name = dadmod_disp_countdown
        SpawnScript dadmod_disp_countdown
    endif
endscript
script dadmod_disp_countdown
    begin
        wait 0.5 seconds
        dadmod_disp_rows
        if (<disp_wait> = 0)
            wait 0.5 seconds
            dadmod_disp_rows
            break
        endif
    repeat
endscript
