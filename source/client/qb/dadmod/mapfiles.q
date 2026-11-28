dadmod_mapfile_levels = [ #"0x001202e3" #"0x341caf9f" #"0x6552c592" #"0xe0d4e51a" #"0xf06d95da" #"0x73babdd0" #"0x1a69989e" #"0x16a10a9a" #"0x896a81b2" #"0x27eeac8d" #"0x2843fdc8" Load_dadmod_THPGTraining Load_dadmod_THPGLarxPhilly Load_dadmod_THPGLarxBaltimore Load_dadmod_THPGLarxWashington ]
dadmod_mapfile_files = [ "data\\pre\\Streetsscn.prx" "data\\pre\\THPS2NYscn.prx" "data\\pre\\THPS2SSscn.prx" "data\\pre\\THPS2Bullringscn.prx" "data\\pre\\THPS2_SHscn.prx" "data\\pre\\THPS2ChopperDropscn.prx" "data\\pre\\P8Trainingscn.prx" "data\\pre\\P8Suburbsscn.prx" "data\\pre\\P8Downtownscn.prx" "data\\pre\\P8CarFactoryscn.prx" "data\\pre\\P8CreteParkscn.prx" "data\\pre\\THPGTrainingscn.prx" "User\\Data\\Levels\\Philly\\Philly.scn.xbx" "User\\Data\\Levels\\Baltimore\\Baltimore.scn.xbx" "User\\Data\\Levels\\WashingtonDC\\WashingtonDC.scn.xbx" ]
script dadmod_level_files_ok
    GetArraySize dadmod_mapfile_levels
    <i> = 0
    begin
        if ( ( dadmod_mapfile_levels [ <i> ] ) = <level> )
            if THUGRECOMP_GameFileExists file = ( dadmod_mapfile_files [ <i> ] )
                return files_ok = 1
            endif
            return
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
    return files_ok = 1
endscript
