dadmod_undress_male = [
{ part = skater_m_torso desc_id = Shirtless }
{ part = skater_m_legs desc_id = Briefs }
{ part = skater_m_lower_legs desc_id = #"Full Legs" }
{ part = skater_m_hands desc_id = Hands }
{ part = skater_m_backpack desc_id = none }
{ part = shoes desc_id = BareFeet }
{ part = socks desc_id = none }
{ part = glasses desc_id = none }
{ part = kneepads desc_id = none }
{ part = elbowpads desc_id = none }
{ part = accessory1 desc_id = none }
{ part = accessory2 desc_id = none }
{ part = accessory3 desc_id = none }
]
dadmod_undress_female = [
{ part = skater_f_torso desc_id = none }
{ part = skater_f_legs desc_id = none }
{ part = skater_f_lower_legs desc_id = #"Full Legs" }
{ part = skater_f_hands desc_id = Hands }
{ part = skater_f_backpack desc_id = none }
{ part = shoes desc_id = BareFeet }
{ part = socks desc_id = none }
{ part = glasses desc_id = none }
{ part = kneepads desc_id = none }
{ part = elbowpads desc_id = none }
{ part = accessory1 desc_id = none }
{ part = accessory2 desc_id = none }
{ part = accessory3 desc_id = none }
]
script dadmod_remove_clothes
    dadmod_undo_save
    GetCurrentSkaterProfileIndex
    GetSkaterSex player = <currentSkaterProfileIndex>
    <outfit> = dadmod_undress_female
    if ( <is_male> )
        <outfit> = dadmod_undress_male
    endif
    GetArraySize <outfit>
    <i> = 0
    begin
        <slot> = ( <outfit> [ <i> ] )
        cas_handle_disqualifications part = ( <slot> . part ) desc_id = ( <slot> . desc_id )
        EditPlayerAppearance {
        profile = <currentSkaterProfileIndex>
        target = SetPart targetParams = { part = ( <slot> . part ) desc_id = ( <slot> . desc_id ) }
        }
        <i> = ( <i> + 1 )
    repeat <array_size>
    RefreshSkaterModel profile = <currentSkaterProfileIndex> Skater = 0 no_board = no_board
    Skater : TurnOffSpecialItem
endscript
