dadmod_remove_items = [
{ part = skater_m_legs text = "Remove Pants" desc_id = Boxers }
{ part = skater_f_legs text = "Remove Pants" desc_id = none }
{ part = shoes text = "Remove Shoes" desc_id = BareFeet }
{ part = skater_m_hands text = "Remove Gloves" desc_id = Hands }
{ part = skater_f_hands text = "Remove Gloves" desc_id = Hands }
]
script dadmod_part_remove_item
    dadmod_part_clear_item <...>
    GetArraySize dadmod_remove_items
    <dm_i> = 0
    begin
        <r> = ( dadmod_remove_items [ <dm_i> ] )
        if ChecksumEquals a = ( <r> . part ) b = <array>
            GetArraySize <array>
            <dm_j> = 0
            begin
                if ChecksumEquals a = ( ( <array> [ <dm_j> ] ) . desc_id ) b = ( <r> . desc_id )
                    make_thugpro_menu_item {
                    text = ( <r> . text )
                    pad_choose_script = dadmod_choose_part
                    pad_choose_params = { structure = ( <array> [ <dm_j> ] ) desc_id = ( <r> . desc_id ) part = <array> }
                    focus_script = dadmod_preview_part
                    focus_params = { structure = ( <array> [ <dm_j> ] ) desc_id = ( <r> . desc_id ) part = <array> }
                    pad_back_scripts = <callback>
                    pad_back_params = <callback_params>
                    }
                    return
                endif
                <dm_j> = ( <dm_j> + 1 )
            repeat <array_size>
            return
        endif
        <dm_i> = ( <dm_i> + 1 )
    repeat <array_size>
endscript
dadmod_clear_items = [ ]
script dadmod_part_clear_item
    if not ArrayContains array = dadmod_clear_items contains = <array>
        return
    endif
    make_thugpro_menu_item {
    text = "Null"
    pad_choose_script = dadmod_clear_part
    pad_choose_params = { part = <array> }
    }
endscript
script dadmod_clear_part
    dadmod_preview_revert
    dadmod_undo_save
    dadmod_me
    EditPlayerAppearance profile = <me> target = ClearPart targetParams = { part = <part> }
    RefreshSkaterModel Skater = 0 profile = <me> no_board = no_board
    Skater : TurnOffSpecialItem
endscript
