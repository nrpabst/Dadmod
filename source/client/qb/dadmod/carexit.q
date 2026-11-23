script ToggleUserControlledVehicleMode
    ToggleUserControlledVehicleMode_orig <...>
    if ObjectExists id = skater
        if not Skater : Driving
            Skater : dadmod_shadow_restore
        endif
    endif
endscript
