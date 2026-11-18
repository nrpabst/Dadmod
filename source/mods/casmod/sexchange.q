dadmod_neutral_scale_info = {
scale = 1.0
}
dadmod_sex_base_male = {
body = { desc_id = MaleBody }
skater_m_head = { desc_id = #"Light Head 4" }
skater_m_hair = { desc_id = Buzzed h = 20 s = 0 v = 10 use_default_hsv = 0 }
skater_m_torso = { desc_id = #"T-shirt" h = 0 s = 50 v = 50 use_default_hsv = 1 }
skater_m_legs = { desc_id = #"Cargo Shorts" h = 220 s = 21 v = 24 use_default_hsv = 0 }
skater_m_hands = { desc_id = Hands h = 0 s = 50 v = 50 use_default_hsv = 1 }
skater_m_lower_legs = { desc_id = none h = 0 s = 50 v = 50 use_default_hsv = 1 }
skater_m_jaw = { desc_id = none }
bare_torso = { desc_id = none }
sleeves = { desc_id = none }
body_shape = dadmod_neutral_scale_info
}
dadmod_sex_base_female = {
body = { desc_id = FemaleBody }
skater_f_head = { desc_id = #"Light Head 1" }
skater_f_hair = { desc_id = Cropped h = 40 s = 0 v = 30 use_default_hsv = 0 }
skater_f_torso = { desc_id = #"Baseball-T" h = 320 s = 32 v = 54 use_default_hsv = 0 }
skater_f_legs = { desc_id = Regular }
skater_f_hands = { desc_id = Hands }
skater_f_lower_legs = { desc_id = none }
bare_torso = { desc_id = none }
sleeves = { desc_id = none }
body_shape = female_scale_info
}
dadmod_sex_only_male = [ skater_m_head skater_m_hair skater_m_hat_hair skater_m_torso skater_m_legs skater_m_hands skater_m_lower_legs skater_m_jaw skater_m_backpack ped_m_head ped_f_head ]
dadmod_sex_only_female = [ skater_f_head skater_f_hair skater_f_hat_hair skater_f_torso skater_f_legs skater_f_hands skater_f_lower_legs skater_f_backpack ped_m_head ped_f_head ]
script dadmod_sex_carry_part
    GetCurrentSkaterProfileIndex
    if not GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = <from>
        return
    endif
    if not GotParam desc_id
        return
    endif
    <found> = 0
    GetArraySize <to>
    <i> = 0
    begin
        if ChecksumEquals a = ( ( <to> [ <i> ] ) . desc_id ) b = <desc_id>
            <found> = 1
            break
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
    if ( <found> = 0 )
        return
    endif
    return carry_desc = <desc_id>
endscript
script cas_apply_skater_sex apply_male = 1
    GetCurrentSkaterProfileIndex
    GetSkaterProfileInfo player = <currentSkaterProfileIndex>
    if ( <is_male> = <apply_male> )
        return
    endif
    dadmod_undo_save
    if ( <apply_male> = 1 )
        <base> = ( dadmod_sex_base_male )
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
        <base> = ( dadmod_sex_base_female )
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
    GetPlayerAppearance player = <currentSkaterProfileIndex>
    <swapped> = { <profile> <base> }
    SetPlayerAppearance player = <currentSkaterProfileIndex> appearance_structure = <swapped>
    SetSkaterProfileProperty player = <currentSkaterProfileIndex> is_male <apply_male>
    GetArraySize <drop>
    <i> = 0
    begin
        EditPlayerAppearance profile = <currentSkaterProfileIndex> target = ClearPart targetParams = { part = ( <drop> [ <i> ] ) }
        <i> = ( <i> + 1 )
    repeat <array_size>
    if GotParam torso_desc
        cas_handle_disqualifications part = <torso_part> desc_id = <torso_desc>
        EditPlayerAppearance profile = <currentSkaterProfileIndex> target = SetPart targetParams = { part = <torso_part> desc_id = <torso_desc> }
    endif
    if GotParam pack_desc
        EditPlayerAppearance profile = <currentSkaterProfileIndex> target = SetPart targetParams = { part = <pack_part> desc_id = <pack_desc> }
    endif
    RemoveParameter desc_id
    if GetPlayerAppearancePart player = <currentSkaterProfileIndex> part = hat
        if GotParam desc_id
            if not ChecksumEquals a = <desc_id> b = none
                EditPlayerAppearance profile = <currentSkaterProfileIndex> target = ClearPart targetParams = { part = <hair_part> }
            endif
        endif
    endif
    RefreshSkaterModel Skater = 0 profile = <currentSkaterProfileIndex> no_board = no_board
    Skater : TurnOffSpecialItem
endscript
