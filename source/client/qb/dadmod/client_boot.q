dadmod_client_build = 1
script dadmod_client_boot_check
    THUGRECOMP_ClientLog text = "dadmod client scripts are loaded"
endscript

script load_level_handle_loading_screen
    Change SHOW_STARTUP_LOADING_SCREEN = 0
endscript

script mem_card_message_pause
    if IsTrue in_autoload
        return
    endif
    mem_card_message_pause_orig <...>
endscript

script mcmess_CheckingCard
    if IsTrue in_autoload
        return
    endif
    mcmess_CheckingCard_orig <...>
endscript

script mcmess_LoadingData
    if IsTrue in_autoload
        return
    endif
    mcmess_LoadingData_orig <...>
endscript

script load_update_level_select_textures_to_main_memory
    load_update_level_select_textures_to_main_memory_orig <...>
    if ScriptExists dadmod_levelthumbs_load
        dadmod_levelthumbs_load <...>
    endif
endscript
