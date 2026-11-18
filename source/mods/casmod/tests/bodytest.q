script dadmod_test_malebody
    dadmod_undo_save
    GetCurrentSkaterProfileIndex
    EditPlayerAppearance profile = <currentSkaterProfileIndex> target = SetPart targetParams = { part = body desc_id = MaleBody }
    RefreshSkaterModel Skater = 0 profile = <currentSkaterProfileIndex> no_board = no_board
    Skater : TurnOffSpecialItem
endscript
