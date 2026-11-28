script dadmod_serverlog_tick
    net = 0
    host = 0
    if InNetGame
        net = 1
        if IsHost
            host = 1
        endif
    endif
    lv = "none"
    GetLevelStructureName
    if StructureContains structure = ( <level_structure_name> ) level
        FormatText TextName = lv "%a" a = ( <level_structure_name> . level )
    endif
    THUGRECOMP_ServerLogTick net = <net> host = <host> level = <lv>
endscript
