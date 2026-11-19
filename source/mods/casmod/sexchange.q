dadmod_neutral_scale_info = {
scale = 1.0
}
script dadmod_sex_pick_male
    return base = { body_shape = dadmod_neutral_scale_info sleeves = <sleeves> bare_torso = <bare_torso> skater_m_jaw = <skater_m_jaw> skater_m_lower_legs = <skater_m_lower_legs> skater_m_hands = <skater_m_hands> skater_m_legs = <skater_m_legs> skater_m_torso = <skater_m_torso> skater_m_hair = <skater_m_hair> skater_m_head = <skater_m_head> body = <body> }
endscript
script dadmod_sex_pick_female
    return base = { body_shape = <body_shape> sleeves = <sleeves> bare_torso = <bare_torso> skater_f_lower_legs = <skater_f_lower_legs> skater_f_hands = <skater_f_hands> skater_f_legs = <skater_f_legs> skater_f_torso = <skater_f_torso> skater_f_hair = <skater_f_hair> skater_f_head = <skater_f_head> body = <body> }
endscript
dadmod_sex_only_male = [ skater_m_head skater_m_hair skater_m_hat_hair skater_m_torso skater_m_legs skater_m_hands skater_m_lower_legs skater_m_jaw skater_m_backpack ped_m_head ped_f_head ]
dadmod_sex_only_female = [ skater_f_head skater_f_hair skater_f_hat_hair skater_f_torso skater_f_legs skater_f_hands skater_f_lower_legs skater_f_backpack ped_m_head ped_f_head ]
script dadmod_sex_carry_part
    dadmod_me
    if not GetPlayerAppearancePart player = <me> part = <from>
        return
    endif
    if not GotParam desc_id
        return
    endif
    <found> = 0
    GetArraySize <to>
    <dm_i> = 0
    begin
        if ChecksumEquals a = ( ( <to> [ <dm_i> ] ) . desc_id ) b = <desc_id>
            <found> = 1
            break
        endif
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
    if ( <found> = 0 )
        return
    endif
    return carry_desc = <desc_id>
endscript
script cas_apply_skater_sex apply_male = 1
    dadmod_me
    GetSkaterProfileInfo player = <me>
    if ( <is_male> = <apply_male> )
        return
    endif
    dadmod_undo_save
    if ( <apply_male> = 1 )
        <src> = ( appearance_custom_skater_male_06 )
        dadmod_sex_pick_male <src>
        <drop> = dadmod_sex_only_female
        dadmod_sex_carry_part from = skater_f_torso to = skater_m_torso
        <torso_part> = skater_m_torso
        if GotParam carry_desc
            <torso_desc> = <carry_desc>
        endif
        RemoveParameter carry_desc
        dadmod_sex_carry_part from = skater_f_backpack to = skater_m_backpack
        <pack_part> = skater_m_backpack
        if GotParam carry_desc
            <pack_desc> = <carry_desc>
        endif
        <hair_part> = skater_m_hair
    else
        <src> = ( appearance_custom_skater_female )
        dadmod_sex_pick_female <src>
        <drop> = dadmod_sex_only_male
        dadmod_sex_carry_part from = skater_m_torso to = skater_f_torso
        <torso_part> = skater_f_torso
        if GotParam carry_desc
            <torso_desc> = <carry_desc>
        endif
        RemoveParameter carry_desc
        dadmod_sex_carry_part from = skater_m_backpack to = skater_f_backpack
        <pack_part> = skater_f_backpack
        if GotParam carry_desc
            <pack_desc> = <carry_desc>
        endif
        <hair_part> = skater_f_hair
    endif
    GetPlayerAppearance player = <me>
    <swapped> = { <profile> <base> }
    SetPlayerAppearance player = <me> appearance_structure = <swapped>
    SetSkaterProfileProperty player = <me> is_male <apply_male>
    GetArraySize <drop>
    <dm_i> = 0
    begin
        EditPlayerAppearance profile = <me> target = ClearPart targetParams = { part = ( <drop> [ <dm_i> ] ) }
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
    if GotParam torso_desc
        cas_handle_disqualifications part = <torso_part> desc_id = <torso_desc>
        EditPlayerAppearance profile = <me> target = SetPart targetParams = { part = <torso_part> desc_id = <torso_desc> }
    endif
    if GotParam pack_desc
        EditPlayerAppearance profile = <me> target = SetPart targetParams = { part = <pack_part> desc_id = <pack_desc> }
    endif
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <me> part = hat
        if GotParam desc_id
            if not ChecksumEquals a = <desc_id> b = none
                EditPlayerAppearance profile = <me> target = ClearPart targetParams = { part = <hair_part> }
            endif
        endif
    endif
    RefreshSkaterModel Skater = 0 profile = <me> no_board = no_board
    Skater : TurnOffSpecialItem
endscript
