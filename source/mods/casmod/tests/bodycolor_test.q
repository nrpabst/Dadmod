dadmod_bc_saved = { }
dadmod_bc_parts = [
{ part = skater_m_hands h = 0 }
{ part = skater_f_hands h = 0 }
{ part = bare_torso h = 120 }
{ part = body h = 240 }
{ part = skater_m_lower_legs h = 60 }
{ part = skater_f_lower_legs h = 60 }
{ part = left_sleeve_tattoo h = 300 }
{ part = right_sleeve_tattoo h = 300 }
{ part = chest_tattoo h = 180 }
{ part = back_tattoo h = 180 }
{ part = left_leg_tattoo h = 30 }
{ part = right_leg_tattoo h = 30 }
{ part = socks_lower h = 90 }
]
script dadmod_bc_test_on
    GetCurrentSkaterProfileIndex
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    Change dadmod_bc_saved = <profile>
    GetArraySize dadmod_bc_parts
    <i> = 0
    begin
        <e> = ( dadmod_bc_parts [ <i> ] )
        SetPlayerAppearanceColor player = <currentSkaterProfileIndex> part = ( <e> . part ) h = ( <e> . h ) s = 100 v = 70 use_default_hsv = 0
        <i> = ( <i> + 1 )
    repeat <array_size>
    RefreshSkaterModel profile = <currentSkaterProfileIndex> Skater = 0
endscript
script dadmod_bc_test_off
    GetCurrentSkaterProfileIndex
    SetPlayerAppearance player = <currentSkaterProfileIndex> appearance_structure = dadmod_bc_saved
    RefreshSkaterModel profile = <currentSkaterProfileIndex> Skater = 0
endscript
