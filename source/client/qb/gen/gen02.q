dadmod_gen02_names = [ IsTrue GotParam ScreenElementExists ]

script create_dadmod_gfx_items
    dadmod_ui_item id = gfx_windowed key = "gfx_windowed" label = "Display mode" kind = dispmode min = 0 max = 0 def = 0 desc = "Play in a window or fullscreen (a borderless window that fills the screen). Pick it, then press Apply. Alt+Enter switches it anytime." pdesc = "Window or fullscreen. Pick, then press Apply. Alt+Enter switches anytime."
    dadmod_ui_item id = gfx_res key = "gfx_res" label = "Resolution" kind = dispres min = 0 max = 0 def = 0 desc = "The window size the game draws at (the sizes that fit your screen). Fullscreen always uses your monitor's own size. Pick it, then press Apply." pdesc = "Window size. Fullscreen always uses your monitor's size. Pick, then Apply."
    dadmod_ui_item id = gfx_dispapply key = "none" label = "Apply" kind = dispapply min = 0 max = 0 def = 0 desc = "Makes the picked display mode and resolution happen now. Press it again within 15 seconds to keep them, or they go back." pdesc = "Apply the picks. Press again within 15 seconds to keep them."
    dadmod_ui_item id = gfx_clip key = "gfx_clip" label = "Distance clipping" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_clip desc = "Stops drawing parts of the level that are far away, which can help on a slow computer. Set how far with Clip distance. The same setting as Enable Distance Clipping in the THUG Pro launcher." pdesc = "Stops drawing far-away parts of the level. Can help on a slow computer."
    dadmod_ui_item id = gfx_clipdist key = "gfx_clipdist" label = "Clip distance" kind = num min = 5 max = 100 step = 5 def = 100 desc = "How far you can see while Distance clipping is on: 5 is close, 100 is far. The same setting as the Near/Far slider in the THUG Pro launcher." pdesc = "How far you see with Distance clipping on: 5 close, 100 far."
    dadmod_ui_item id = gfx_clipfog key = "gfx_clipfog" label = "Distance fog" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_clipfog desc = "Fades the far-away edge into fog so the level does not just stop. Only works while Distance clipping is on. The same setting as Enable Fog in the THUG Pro launcher." pdesc = "Fades the clipping edge into fog. Only works with Distance clipping on."
    dadmod_ui_item id = gfx_postfx key = "gfx_postfx" label = "Graphics effects" kind = reshade min = 0 max = 1 def = 0 list = gfx_postfx desc = "Shown only when ReShade is installed. dadmod uses dadmod's graphics effects; ReShade skips dadmod's screen effects so only ReShade's show."
    dadmod_ui_item id = gfx_aniso key = "gfx_aniso" label = "Texture filtering" kind = gfxlist min = 0 max = 4 def = 4 list = gfx_aniso desc = "Anisotropic filtering: keeps floors, roads and walls seen at an angle sharp instead of blurry. 16x looks best and costs very little. Changes show right away." pdesc = "Keeps floors and walls seen at an angle sharp. 16x looks best and costs very little."
    dadmod_ui_item id = gfx_lodbias key = "gfx_lodbias" label = "Texture sharpness" kind = gfxlist min = 0 max = 4 def = 0 list = gfx_lodbias desc = "Makes the game use more detailed texture copies at a distance. Higher is crisper but can shimmer when moving. Changes show right away." pdesc = "Uses more detailed textures at a distance. Higher is crisper but can shimmer."
    dadmod_ui_item id = gfx_uismooth key = "gfx_uismooth" label = "Smooth menu graphics" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_uismooth desc = "Smooths blocky scaled-up menu and HUD graphics. Changes show right away."
    dadmod_ui_item id = gfx_fxaa key = "gfx_fxaa" label = "FXAA" kind = gfxlist min = 0 max = 2 def = 0 list = gfx_fxaa desc = "Smooths jagged edges of the 3D scene (menus and HUD stay sharp). High quality runs it twice for smoother edges. Changes show right away." pdesc = "Smooths jagged edges of the 3D scene; menus and HUD stay sharp."
    dadmod_ui_item id = gfx_msaa key = "gfx_msaa" label = "MSAA (restart)" kind = gfxlist min = 0 max = 3 def = 0 list = gfx_msaa desc = "Proper anti-aliasing of geometry edges. Needs a restart of the game. Turns off ambient occlusion, haze, depth of field and outlines, which need the depth buffer." pdesc = "Smooths geometry edges. Needs a restart. Turns off the depth effects."
    dadmod_ui_item id = gfx_sharpen key = "gfx_sharpen" label = "Sharpening" kind = num min = 0 max = 10 def = 0 desc = "Contrast-adaptive sharpening (like AMD FidelityFX CAS): brings out texture detail without halos. 3 to 5 is a good start. Changes show right away." pdesc = "Brings out texture detail without halos. 3 to 5 is a good start."
    dadmod_ui_item id = gfx_bloom key = "gfx_bloom" label = "Bloom" kind = num min = 0 max = 10 def = 0 desc = "A soft glow around bright lights and sky. 2 to 4 is subtle. Changes show right away."
    dadmod_ui_item id = gfx_ssao key = "gfx_ssao" label = "Ambient occlusion" kind = num min = 0 max = 10 def = 0 desc = "Soft shadows where walls meet floors, under rails and in corners, so the world looks less flat. Needs the depth buffer, so it is off while MSAA is on. Changes show right away." pdesc = "Soft shadows in corners and under rails. Off while MSAA is on."
    dadmod_ui_item id = gfx_fog key = "gfx_fog" label = "Distance haze" kind = num min = 0 max = 10 def = 0 desc = "A light atmospheric haze that grows with distance and softens far-away pop-in. Needs the depth buffer, so it is off while MSAA is on. Changes show right away." pdesc = "Haze that grows with distance and softens pop-in. Off while MSAA is on."
    dadmod_ui_item id = gfx_dof key = "gfx_dof" label = "Depth of field" kind = num min = 0 max = 10 def = 0 desc = "Blurs things far away like a camera lens, keeping you and the area around you sharp. Needs the depth buffer, so it is off while MSAA is on. Changes show right away." pdesc = "Blurs far-away things like a camera lens. Off while MSAA is on."
    dadmod_ui_item id = gfx_outline key = "gfx_outline" label = "Outlines" kind = gfxlist min = 0 max = 2 def = 0 list = gfx_outline desc = "Dark outlines around shapes, or a full cartoon cel-shaded look. Needs the depth buffer, so it is off while MSAA is on. Changes show right away." pdesc = "Dark outlines, or a cartoon cel-shaded look. Off while MSAA is on."
    dadmod_ui_item id = gfx_mblur key = "gfx_mblur" label = "Motion blur" kind = num min = 0 max = 10 def = 0 desc = "Blends in a little of the last frame for a smooth, fast feel. High values leave ghost trails. Changes show right away." pdesc = "Blends in a little of the last frame. High values leave ghost trails."
    dadmod_ui_item id = gfx_skshadow key = "gfx_skshadow" label = "Skater shadow" kind = gfxlist min = 0 max = 3 def = 0 list = gfx_skshadow desc = "The shadow under your skater. Circle is a plain round spot. Full body is the shape of your skater, and the sharp ones show it in more detail. The same setting as Skater Shadow Quality in the THUG Pro launcher." pdesc = "A round spot, or your skater's full shape (sharper further right)."
    dadmod_ui_item id = gfx_particles key = "gfx_particles" label = "Particles" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_particles desc = "Sparks, smoke, splashes and other particle effects. Off can help on a slow computer. The same setting as Disable Particles in the THUG Pro launcher. Takes effect after a restart." pdesc = "Sparks, smoke and splashes. Takes effect after a restart."
    dadmod_ui_item id = gfx_levellights key = "gfx_levellights" label = "Level lights" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_levellights desc = "The lights placed around levels, like street lamps, that light up your skater and things near them. Shows from the next level you load. The same setting as Disable Level Lights in the THUG Pro launcher." pdesc = "Lights placed around levels. Shows from the next level you load."
    dadmod_ui_item id = gfx_skaterlights key = "gfx_skaterlights" label = "Skater lights" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_skaterlights desc = "THUG Pro's own extra lighting on skaters. The same setting as Disable Skater Lights in the THUG Pro launcher. Takes effect after a restart." pdesc = "THUG Pro's extra lighting on skaters. Takes effect after a restart."
    dadmod_ui_item id = gfx_tpscreenfx key = "gfx_tpscreenfx" label = "THUG Pro screen effects" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_tpscreenfx desc = "THUG Pro's own full-screen shader effects, separate from the dadmod effects on this page. The same setting as Disable Screen Effects in the THUG Pro launcher. Takes effect after a restart." pdesc = "THUG Pro's own screen shader effects. Takes effect after a restart."
    dadmod_ui_item id = gfx_preset key = "gfx_preset" label = "Color look" kind = gfxlist min = 0 max = 10 def = 0 list = gfx_preset desc = "A one-click color grade on top of the sliders. None leaves the colors as the game made them. Changes show right away." pdesc = "A one-click color grade on top of the sliders. None leaves the colors alone."
    dadmod_ui_item id = gfx_bright key = "gfx_bright" label = "Brightness" kind = num min = -10 max = 10 def = 0 desc = "Lifts or lowers the whole picture. 0 is normal. Changes show right away."
    dadmod_ui_item id = gfx_contrast key = "gfx_contrast" label = "Contrast" kind = num min = -10 max = 10 def = 0 desc = "Difference between darks and lights. 0 is normal. Changes show right away."
    dadmod_ui_item id = gfx_sat key = "gfx_sat" label = "Saturation" kind = num min = -10 max = 10 def = 0 desc = "Color strength. -10 is black and white, 0 is normal. Changes show right away."
    dadmod_ui_item id = gfx_vibrance key = "gfx_vibrance" label = "Vibrance" kind = num min = 0 max = 10 def = 0 desc = "Boosts dull colors while leaving already strong colors alone. 0 is off. Changes show right away." pdesc = "Boosts dull colors and leaves strong ones alone. 0 is off."
    dadmod_ui_item id = gfx_gamma key = "gfx_gamma" label = "Gamma" kind = num min = -10 max = 10 def = 0 desc = "Brightens or darkens the midtones without washing out blacks and whites. 0 is normal. Changes show right away." pdesc = "Brightens or darkens the midtones. 0 is normal."
    dadmod_ui_item id = gfx_temp key = "gfx_temp" label = "Color temperature" kind = num min = -10 max = 10 def = 0 desc = "Cooler (blue) below 0, warmer (orange) above 0. Changes show right away."
    dadmod_ui_item id = gfx_tint key = "gfx_tint" label = "Tint" kind = num min = -10 max = 10 def = 0 desc = "Greener below 0, more magenta above 0. Changes show right away."
    dadmod_ui_item id = gfx_pixelate key = "gfx_pixelate" label = "Pixelate" kind = gfxlist min = 0 max = 3 def = 0 list = gfx_pixelate desc = "Chunky retro pixels for the 3D scene, like an old console. Changes show right away."
    dadmod_ui_item id = gfx_crt key = "gfx_crt" label = "CRT TV" kind = gfxlist min = 0 max = 2 def = 0 list = gfx_crt desc = "Old TV look: scanlines, a shadow mask and optionally a curved screen. Covers menus and HUD too. Changes show right away." pdesc = "Old TV look: scanlines, a shadow mask, optionally a curved screen."
    dadmod_ui_item id = gfx_grain key = "gfx_grain" label = "Film grain" kind = num min = 0 max = 10 def = 0 desc = "Light film noise that hides blocky textures and color banding. Changes show right away."
    dadmod_ui_item id = gfx_chroma key = "gfx_chroma" label = "Chromatic aberration" kind = num min = 0 max = 10 def = 0 desc = "A faint red and blue color fringe toward the screen edges, like a real lens. Changes show right away." pdesc = "A faint red and blue fringe toward the screen edges, like a real lens."
    dadmod_ui_item id = gfx_vignette key = "gfx_vignette" label = "Vignette" kind = num min = 0 max = 10 def = 0 desc = "Darkens the corners of the screen a little, like a camera lens. Changes show right away."
    dadmod_ui_item id = gfx_galaxy key = "gfx_galaxy" label = "Sky" kind = gfxlist min = 0 max = 14 def = 0 list = gfx_galaxy desc = "Swap the sky. Dark skies also darken the map unless you pick a Time of day."
    dadmod_ui_item id = gfx_tod key = "gfx_tod" label = "Time of day" kind = gfxlist min = 0 max = 6 def = 0 list = gfx_tod desc = "Level / server follows the level, or the server when one runs a day/night fade. Pick a time to use your own, even when the server changes it."
    dadmod_ui_item id = gfx_skypop key = "gfx_skypop" label = "Sky boost" kind = num min = 0 max = 10 def = 0 desc = "Richer sky colors that match the time of day: deep blue days, orange sunsets, stars at night. 0 leaves the sky as the game draws it." pdesc = "Richer sky colors for the time of day, with stars at night. 0 is off."
    dadmod_ui_item id = gfx_lampadd key = "gfx_lampadd" label = "Add street light here" kind = gfxact min = 0 max = 0 def = 0 desc = "Adds a street light at the camera. Use the free camera to put it right at a lamp."
    dadmod_ui_item id = gfx_lampdel key = "gfx_lampdel" label = "Remove nearest street light" kind = gfxact min = 0 max = 0 def = 0 desc = "Removes the street light closest to the camera."
    dadmod_ui_item id = gfx_skydef key = "gfx_galaxy" label = "Default sky" kind = skyreset min = 0 max = 0 def = 0 desc = "Puts everything on this page back to default." pdesc = "Puts everything on this page back to default."
    dadmod_ui_item id = gfx_weather key = "gfx_weather" label = "Weather" kind = gfxlist min = 0 max = 5 def = 0 list = gfx_weather desc = "Rain, a thunderstorm, snow or fog over every level, or Random (changes every few minutes). Set how heavy with Intensity."
    dadmod_ui_item id = gfx_wxamt key = "gfx_wxamt" label = "Intensity" kind = num min = 1 max = 10 def = 5 desc = "How heavy the weather is: light rain to a downpour, a few flakes to a blizzard, thin to thick fog. Thunderstorms strike more often higher up."
    dadmod_ui_item id = gfx_fireworks key = "gfx_fireworks" label = "Fireworks" kind = gfxlist min = 0 max = 5 def = 0 list = gfx_fireworks desc = "Fireworks over the level when someone wins a game, or on wins and every 1, 3, 5 or 10 minutes."
    dadmod_ui_item id = gfx_fwnow key = "gfx_fireworks" label = "Launch fireworks now" kind = gfxfire min = 0 max = 0 def = 0 desc = "Fire a fireworks show right now."
    dadmod_ui_item id = gfx_lamplights key = "gfx_lamplights" label = "Lamp lights" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_lamplights desc = "Street lamp light at night: bulb glow and light on the ground and walls. Off also saves work."
    dadmod_ui_item id = gfx_lampposts key = "gfx_lampposts" label = "Extra lamp posts" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_lampposts desc = "The extra lamp posts added to some maps, with their light. Hide keeps the map's own lamps lit."
    dadmod_ui_item id = gfx_fps key = "gfx_fps" label = "FPS counter" kind = gfxlist min = 0 max = 2 def = 0 list = gfx_fps desc = "Frames per second in the top left corner. Tiny shows just the number, right in the corner. Changes show right away." pdesc = "Frames per second in the top left. Tiny shows just the number."
    dadmod_ui_item id = gfx_shotkey key = "gfx_shotkey" label = "Screenshot key (F11)" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_shotkey desc = "F11 saves a PNG screenshot to the dadmod screenshots folder."
    dadmod_ui_item id = gfx_shothud key = "gfx_shothud" label = "Screenshots show menus" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_shothud desc = "On: F11 screenshots include menus and the HUD. Off: just the game picture."
    dadmod_ui_item id = gfx_vsync key = "gfx_vsync" label = "V-sync" kind = dispvsync min = 0 max = 0 def = 0 desc = "Locks frames to your monitor to stop tearing. Pick it, then press Apply." pdesc = "Locks frames to your monitor. Pick, then press Apply."
    dadmod_ui_item id = gfx_framegen key = "gfx_framegen" label = "Frame generation" kind = gfxlist min = 0 max = 6 def = 0 list = gfx_framegen desc = "Adds smooth in-between frames for a 120 to 240 Hz monitor (the game itself still runs at 60). Auto matches your monitor, or pick a rate. Never goes faster than your monitor. Adds a tiny bit of input lag. Changes show right away." pdesc = "In-between frames. Auto matches your monitor, or pick 120 to 240 Hz."
    dadmod_ui_item id = gfx_mirror key = "gfx_mirror" label = "Mirror mode" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_mirror desc = "Flips the 3D view left to right, like skating a mirrored copy of the level, and swaps left and right steering to match. Menus, the HUD and text stay normal." pdesc = "Flips the 3D view left to right and swaps steering to match."
    dadmod_ui_item id = gfx_levelsfx key = "gfx_levelsfx" label = "Level sounds" kind = num min = 0 max = 100 def = 100 step = 5 desc = "Volume of water, crowds, machines, cars and other sounds that come from things in a map. 0 turns them off. Skaters' own sounds stay as they are. Changes apply right away."
    dadmod_ui_item id = gfx_tricksfx key = "gfx_tricksfx" label = "Special trick sounds" kind = num min = 0 max = 100 def = 100 step = 5 desc = "Volume of the sound clips some special tricks play, like the guitar grind. 0 turns them off. Changes apply right away, even to a clip that is playing."
    dadmod_ui_item id = gfx_telesfx key = "gfx_telesfx" label = "Teleporter sounds" kind = num min = 0 max = 100 def = 100 step = 5 desc = "Volume of the sounds teleporters and teleporting elevators play in some levels. 0 turns them off. Changes apply to the next teleport."
    dadmod_ui_item id = gfx_bginput key = "gfx_bginput" label = "Background input" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_bginput desc = "On: your controller keeps playing the game while another window (browser, Discord) is in front. Off: input only works while the game window is in front. Changes apply right away."
    dadmod_ui_item id = gfx_deadzone key = "gfx_deadzone" label = "Stick dead zone" kind = num min = 0 max = 10 def = 0 desc = "Ignores small stick movements so a worn stick stops drifting your skater. 0 is off; raise it until drifting stops. Changes apply right away."
    dadmod_ui_item id = gfx_abswap key = "gfx_abswap" label = "Swap A/B and X/Y" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_abswap desc = "For Nintendo-style controllers: swaps A with B and X with Y so the buttons match the labels on your pad. Changes apply right away."
    dadmod_ui_item id = gfx_launchbinds key = "gfx_launchbinds" label = "Use launcher button layout" kind = gfxlist min = 0 max = 1 def = 0 list = gfx_launchbinds desc = "On uses the button bindings you set in the THUG Pro launcher. Off uses the standard dadmod Xbox-style layout. Changes apply right away."
    dadmod_ui_item id = gfx_bind_kb key = "none" label = "Keyboard bindings" kind = uiaction min = 0 max = 0 def = 0 action = dadmod_binds_kb_open desc = "Pick the key for each action while skating. Changes apply right away."
    dadmod_ui_item id = gfx_bind_pad key = "none" label = "Controller bindings" kind = uiaction min = 0 max = 0 def = 0 action = dadmod_binds_pad_open desc = "Pick the controller button for each action. Changes apply right away."
    dadmod_ui_item id = gfx_padpopup key = "gfx_padpopup" label = "Controller popups" kind = gfxlist min = 0 max = 1 def = 1 list = gfx_padpopup desc = "Shows a short message when a controller is plugged in or unplugged."
    dadmod_ui_item id = gfx_reset key = "gfx_aniso" label = "Reset graphics" kind = gfxreset min = 0 max = 0 def = 0 desc = "Puts every graphics setting back to its default (16x texture filtering, F11 screenshots on, effects off). Weather settings are not changed" pdesc = "Puts every graphics setting back to its default. Weather is not changed."
endscript

script dadmod_ui_text
    dadmod_ui_get key = <key> def = <def> raw
    switch <kind>
    case color
        GetArraySize dadmod_ui_palette
        if (<value> < 0)
            value = 0
        endif
        if not (<value> < <array_size>)
            value = 0
        endif
        return text = ( ( dadmod_ui_palette [ <value> ] ) . name ) value = <value>
    case rainbow
        if (<value> < 0)
            value = 0
        endif
        if (<value> > 11)
            value = 11
        endif
        return text = ( dadmod_ui_rainbow_names [ <value> ] ) value = <value>
    case theme
        GetArraySize dadmod_ui_theme_names
        if (<value> < 0)
            value = 0
        endif
        if not (<value> < <array_size>)
            value = 0
        endif
        return text = ( dadmod_ui_theme_names [ <value> ] ) value = <value>
    case ctheme
        GetArraySize dadmod_ui_theme_names
        if (<value> < 1)
            value = 1
        endif
        if not (<value> < <array_size>)
            value = 1
        endif
        return text = ( dadmod_ui_theme_names [ <value> ] ) value = <value>
    case reset
        return text = "" value = <def>
    case gfxreset
        return text = "" value = <def>
    case gfxfire
        return text = "" value = <def>
    case gfxact
        return text = "" value = <def>
    case dispmode
        THUGRECOMP_DisplayLive key = "mode" step = 0
        return text = <text> value = 0
    case dispres
        THUGRECOMP_DisplayLive key = "res" step = 0
        return text = <text> value = 0
    case dispvsync
        THUGRECOMP_DisplayLive key = "vsync" step = 0
        return text = <text> value = 0
    case dispapply
        THUGRECOMP_DisplayLive key = "apply" step = 0
        return text = <text> value = 0
    case skyreset
        return text = "" value = <def>
    case gfxlist
        names = [ "?" ]
        GetArraySize dadmod_gfx_lists
        j = 0
        begin
            if (<j> = <array_size>)
                break
            endif
            if ( ( ( dadmod_gfx_lists [ <j> ] ) . list ) = <list> )
                names = ( ( dadmod_gfx_lists [ <j> ] ) . names )
                break
            endif
            j = ( <j> + 1 )
        repeat
        GetArraySize <names>
        if (<value> < 0)
            value = 0
        endif
        if not (<value> < <array_size>)
            value = 0
        endif
        return text = ( <names> [ <value> ] ) value = <value>
    case truerainbow
        return text = "" value = <def>
    case colorreset
        return text = "" value = <def>
    case thmode
        if (<value> < 0)
            value = 0
        endif
        if (<value> > 5)
            value = 5
        endif
        return text = ( dadmod_ui_thmode_names [ <value> ] ) value = <value>
    case fx
        if (<value> < 0)
            value = 0
        endif
        if (<value> > 5)
            value = 5
        endif
        return text = ( dadmod_ui_fx_names [ <value> ] ) value = <value>
    case titlefx
        names = [ "Off" "Breathe" "Pulse" "Fade" "Two-tone" "Strobe" "Scan" "Confetti" "Mosaic" "Matrix" "Decode" "Per letter" "Match menu" ]
        if (<value> < 0)
            value = 0
        endif
        if (<value> > 12)
            value = 12
        endif
        return text = ( <names> [ <value> ] ) value = <value>
    case barfx
        names = [ "Glitch" "Still" "Breathe" "Pulse" "Rainbow" "Two-tone" "Strobe" "Neon" "Heartbeat" "Police" "Slide" ]
        if (<value> < 0)
            value = 0
        endif
        if (<value> > 10)
            value = 10
        endif
        return text = ( <names> [ <value> ] ) value = <value>
    case angle
        dadmod_ui_scan_dir value = <value>
        return text = ( dadmod_ui_scan_dir_names [ <dir> ] ) value = ( <dir> * 45 )
    default
        FormatText TextName = text "%a" a = <value>
        return text = <text> value = <value>
    endswitch
endscript

script dadmod_ui_item step = 1
    if not GotParam list
        list = none
    endif
    if GotParam dadmod_pause
        if GotParam pdesc
            desc = <pdesc>
        endif
    endif
    if (<kind> = reshade)
        if not THUGRECOMP_ReShadeInfo
            return
        endif
        kind = gfxlist
    endif
    if (<kind> = gfxreset)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_gfx_reset
        }
        return
    endif
    if (<kind> = gfxact)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_gfx_action
        pad_choose_params = { key = <key> }
        }
        return
    endif
    if (<kind> = skyreset)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_sky_default
        }
        return
    endif
    if (<kind> = gfxfire)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_gfx_fireworks
        }
        return
    endif
    if (<kind> = colorreset)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_ui_reset_colors
        }
        return
    endif
    if (<kind> = uiaction)
        if ( (<action> = dadmod_theme_open) or (<action> = dadmod_binds_kb_open) or (<action> = dadmod_binds_pad_open) )
            FormatText TextName = shown "%s  >" s = <label>
        else
            shown = <label>
        endif
        make_thugpro_menu_item {
        text = <shown>
        sub_label = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = <action>
        }
        return
    endif
    if (<kind> = truerainbow)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_ui_true_rainbow
        }
        return
    endif
    if (<kind> = reset)
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        description_text = <desc>
        pad_choose_script = dadmod_ui_reset_one
        pad_choose_params = { key = <key> value = <def> }
        }
        return
    endif
    if (<kind> = dispapply)
        dadmod_ui_text key = <key> kind = <kind> def = <def> list = <list>
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        extra_text = <text>
        description_text = <desc>
        pad_choose_script = dadmod_disp_apply
        }
        return
    endif
    dadmod_ui_text key = <key> kind = <kind> def = <def> list = <list>
    if GotParam dadmod_grey
        make_thugpro_menu_item {
        text = <label>
        id = <id>
        extra_text = <text>
        description_text = <desc>
        not_focusable = not_focusable
        }
        return
    endif
    make_thugpro_menu_item {
    text = <label>
    id = <id>
    extra_text = <text>
    description_text = <desc>
    option_arrows
    option_arrows_callback = dadmod_ui_change
    option_arrows_callback_params = { key = <key> kind = <kind> min = <min> max = <max> step = <step> def = <def> list = <list> }
    pad_choose
    }
endscript

script dadmod_ui_change
    GetTags
    if ( ( <kind> = dispmode ) or ( <kind> = dispres ) or ( <kind> = dispvsync ) )
        dstep = 1
        if GotParam left
            dstep = -1
        endif
        if (<kind> = dispmode)
            THUGRECOMP_DisplayLive key = "mode" step = <dstep>
        else
            if (<kind> = dispvsync)
                THUGRECOMP_DisplayLive key = "vsync" step = <dstep>
            else
                THUGRECOMP_DisplayLive key = "res" step = <dstep>
            endif
        endif
        dadmod_disp_rows
        return
    endif
    dadmod_ui_rb_need
    dadmod_ui_get key = "ui_rainbow" def = 0 raw
    need_before = ( <value> * 4 + <rb_spd> * 2 + <rb_dir> )
    dadmod_ui_text key = <key> kind = <kind> def = <def> list = <list>
    if (<kind> = rainbow)
        if GotParam left
            dadmod_ui_effect_step value = <value> left
        else
            dadmod_ui_effect_step value = <value>
        endif
    else
        cur = <value>
        if GotParam left
            value = ( <value> - <step> )
        else
            value = ( <value> + <step> )
        endif
        if (<kind> = num)
            if (<value> > <max>)
                value = <max>
            endif
            if (<value> < <min>)
                value = <min>
            endif
        else
            if (<value> > <max>)
                value = <min>
            endif
            if (<value> < <min>)
                value = <max>
            endif
        endif
        if (<key> = "gfx_tod")
            order = [ 0 6 1 2 3 5 4 ]
            i = 0
            begin
                if (<i> > 6)
                    i = 0
                    break
                endif
                if ( ( <order> [ <i> ] ) = <cur> )
                    break
                endif
                i = ( <i> + 1 )
            repeat
            if GotParam left
                i = ( <i> - 1 )
            else
                i = ( <i> + 1 )
            endif
            if (<i> < 0)
                i = 6
            endif
            if (<i> > 6)
                i = 0
            endif
            value = ( <order> [ <i> ] )
        endif
    endif
    THUGRECOMP_SettingSave key = <key> value = <value>
    if (<key> = "gfx_skshadow")
        dadmod_shadow_refresh
    endif
    if (<key> = "ui_rainbow")
        if (<value> = 10)
            dadmod_ui_random_roll
        endif
    endif
    Change dadmod_dirty = 1
    if (<key> = "gfx_tod")
        dadmod_tod_kali_follow tod = <value>
        Change dadmod_tod_last = <value>
        dadmod_tod_refresh
    endif
    dadmod_ui_text key = <key> kind = <kind> def = <def> list = <list>
    thugpro_menu_item_update_extra_text id = <id> text = <text>
    dadmod_ui_apply
    dadmod_ui_repaint
    if ( ( <key> = "desc_color" ) or ( <key> = "desc_accent_color" ) )
        dadmod_desc_panel_refresh
    endif
    if ( ( <key> = "ui_hl_style" ) or ( <key> = "ui_br_color" ) )
        if (dadmod_layout_node > -1)
            dadmod_layout_open node = ( dadmod_layout_node ) focus_id = <id>
            return
        endif
    endif
    dadmod_ui_rb_need
    dadmod_ui_get key = "ui_rainbow" def = 0 raw
    if not ( ( <value> * 4 + <rb_spd> * 2 + <rb_dir> ) = <need_before> )
        if (dadmod_layout_node > -1)
            dadmod_layout_open node = ( dadmod_layout_node ) focus_id = <id>
        endif
    endif
endscript

script dadmod_ui_true_rainbow
    THUGRECOMP_SettingSave key = "ui_rainbow" value = 5
    THUGRECOMP_SettingSave key = "ui_rb_angle" value = 0
    THUGRECOMP_SettingSave key = "ui_rb_speed" value = 4
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    endif
endscript

script dadmod_gfx_reset
    THUGRECOMP_GfxReset
    dadmod_tod_kali_follow tod = 0
    Change dadmod_tod_last = 0
    dadmod_tod_refresh
    if ScreenElementExists id = dadmod_gfx_menu
        dadmod_pause_graphics
        return
    endif
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    endif
endscript

dadmod_pause_group_last = -1

script dadmod_sky_default
    THUGRECOMP_SettingSave key = "gfx_galaxy" value = 0
    THUGRECOMP_SettingSave key = "gfx_tod" value = 0
    THUGRECOMP_SettingSave key = "gfx_skypop" value = 0
    THUGRECOMP_SettingSave key = "gfx_lamps" value = 0
    THUGRECOMP_SettingSave key = "gfx_weather" value = 0
    THUGRECOMP_SettingSave key = "gfx_wxamt" value = 5
    THUGRECOMP_SettingSave key = "gfx_todfog" value = 0
    THUGRECOMP_SettingSave key = "gfx_fogamt" value = 5
    THUGRECOMP_SettingSave key = "gfx_fireworks" value = 0
    dadmod_tod_kali_follow tod = 0
    Change dadmod_tod_last = 0
    dadmod_tod_refresh
    Change dadmod_dirty = 1
    if ScreenElementExists id = dadmod_gfx_group_menu
        if (dadmod_pause_group_last > -1)
            dadmod_pause_gfx_group group = ( dadmod_pause_group_last )
            return
        endif
    endif
    if ScreenElementExists id = dadmod_skywx_menu
        dadmod_pause_skywx_menu focus_id = gfx_skydef_pause
        return
    endif
    if ScreenElementExists id = dadmod_menu
        dadmod_menu
        return
    endif
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    endif
endscript

script dadmod_gfx_action
    THUGRECOMP_SettingSave key = <key> value = 1
endscript

script dadmod_gfx_fireworks
    THUGRECOMP_SettingSave key = "gfx_fwnow" value = 1
endscript

script dadmod_ui_main_defaults
    THUGRECOMP_SettingSave key = "ui_side" value = 2
    THUGRECOMP_SettingSave key = "ui_size" value = 100
    THUGRECOMP_SettingSave key = "ui_scale" value = 120
    THUGRECOMP_SettingSave key = "ui_x" value = 0
    THUGRECOMP_SettingSave key = "ui_y" value = 0
    THUGRECOMP_SettingSave key = "ui_logo" value = 0
    THUGRECOMP_MenuOpt key = "deck" step = 0
    if (<text> = "Off")
        THUGRECOMP_MenuOpt key = "deck" step = 1
    endif
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node ) focus_id = mui_main_def
    endif
endscript

script dadmod_ui_reset_one
    THUGRECOMP_SettingSave key = <key> value = <value>
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    endif
endscript

dadmod_ui_defaults = [
{ key = "ui_text" value = 0 }
{ key = "ui_focus" value = 0 }
{ key = "ui_bar" value = 0 }
{ key = "ui_title" value = 0 }
{ key = "ui_rainbow" value = 0 }
{ key = "ui_bright" value = 100 }
{ key = "ui_text_fx" value = 0 }
{ key = "ui_focus_fx" value = 0 }
{ key = "ui_bar_fx" value = 0 }
{ key = "ui_title_fx" value = 0 }
{ key = "ui_rb_speed" value = 4 }
{ key = "ui_rb_theme" value = 0 }
{ key = "ui_colortheme" value = 1 }
{ key = "ui_theme_mode" value = 0 }
{ key = "ui_fx_speed" value = 5 }
{ key = "ui_rb_angle" value = 0 }
{ key = "ui_item0_fx" value = 0 }
{ key = "ui_item1_fx" value = 0 }
{ key = "ui_item2_fx" value = 0 }
{ key = "ui_item3_fx" value = 0 }
{ key = "ui_item4_fx" value = 0 }
{ key = "ui_item5_fx" value = 0 }
{ key = "ui_item6_fx" value = 0 }
{ key = "ui_item7_fx" value = 0 }
{ key = "ui_sat" value = 100 }
{ key = "ui_scale" value = 120 }
{ key = "ui_x" value = 0 }
{ key = "ui_side" value = 2 }
{ key = "ui_size" value = 100 }
{ key = "ui_y" value = 0 }
{ key = "ui_item0" value = 0 }
{ key = "ui_item1" value = 0 }
{ key = "ui_item2" value = 0 }
{ key = "ui_item3" value = 0 }
{ key = "ui_item4" value = 0 }
{ key = "ui_item5" value = 0 }
{ key = "ui_item6" value = 0 }
{ key = "ui_item7" value = 0 }
]

dadmod_ui_color_keys = [ "ui_text" "ui_focus" "ui_bar" "ui_title" "ui_rainbow" "ui_bright" "ui_sat" "ui_text_fx" "ui_focus_fx" "ui_bar_fx" "ui_title_fx" "ui_rb_speed" "ui_rb_theme" "ui_colortheme" "ui_theme_mode" "ui_fx_speed" "ui_rb_angle" "ui_item0_fx" "ui_item1_fx" "ui_item2_fx" "ui_item3_fx" "ui_item4_fx" "ui_item5_fx" "ui_item6_fx" "ui_item7_fx" "ui_item0" "ui_item1" "ui_item2" "ui_item3" "ui_item4" "ui_item5" "ui_item6" "ui_item7" ]

script dadmod_ui_reset_colors
    GetArraySize dadmod_ui_defaults
    i = 0
    begin
        if (<i> = <array_size>)
            break
        endif
        k = ( ( dadmod_ui_defaults [ <i> ] ) . key )
        GetArraySize dadmod_ui_color_keys
        n = <array_size>
        j = 0
        begin
            if (<j> = <n>)
                break
            endif
            if ( ( dadmod_ui_color_keys [ <j> ] ) = <k> )
                THUGRECOMP_SettingSave key = <k> value = ( ( dadmod_ui_defaults [ <i> ] ) . value )
                break
            endif
            j = ( <j> + 1 )
        repeat
        GetArraySize dadmod_ui_defaults
        i = ( <i> + 1 )
    repeat
    THUGRECOMP_SettingSave key = "desc_color" value = 0
    THUGRECOMP_SettingSave key = "desc_accent_color" value = 0
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_ui_colours_menu
    endif
endscript

script dadmod_ui_reset
    GetArraySize dadmod_ui_defaults
    i = 0
    begin
        if (<i> = <array_size>)
            break
        endif
        THUGRECOMP_SettingSave key = ( ( dadmod_ui_defaults [ <i> ] ) . key ) value = ( ( dadmod_ui_defaults [ <i> ] ) . value )
        i = ( <i> + 1 )
    repeat
    Change dadmod_dirty = 1
    dadmod_ui_apply
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_ui_menu
    endif
endscript

script dadmod_desc_setting
    if THUGRECOMP_SettingLoad key = <key>
        return setting = <value>
    endif
    return setting = <def>
endscript

script dadmod_desc_panel_right
    Change dadmod_desc_is_strip = 0
    dadmod_desc_setting key = "desc_x" def = 470
    x = <setting>
    dadmod_desc_setting key = "desc_y" def = 125
    y = <setting>
    dadmod_desc_setting key = "desc_w" def = 230
    w = <setting>
    dadmod_desc_setting key = "desc_scale" def = 100
    sc = ( 0.16 * <setting> / 100.0 )
    dadmod_desc_setting key = "desc_alpha" def = 65
    pa = ( <setting> / 100.0 )
    dadmod_desc_setting key = "desc_accent" def = 1
    accent_on = <setting>
    dadmod_desc_setting key = "desc_align" def = 1
    ij = [ center top ]
    if (<setting> = 0)
        ij = [ left top ]
    endif
    if (<setting> = 2)
        ij = [ right top ]
    endif
    text_rgba = [ 128 128 128 128 ]
    dadmod_ui_color key = "desc_color"
    if GotParam color
        text_rgba = <color>
        RemoveParameter color
    endif
    bg_rgba = [ 0 0 0 128 ]
    dadmod_ui_color key = "desc_bg"
    if GotParam color
        bg_rgba = <color>
        RemoveParameter color
    endif
    accent_rgba = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
    dadmod_ui_color key = "desc_accent_color"
    if GotParam color
        accent_rgba = <color>
        RemoveParameter color
    endif
    if ScreenElementExists id = desc_text_container
        DestroyScreenElement id = desc_text_container
    endif
    CreateScreenElement {
    id = desc_text_container
    parent = current_menu_anchor
    type = ContainerElement
    pos = ( (1.0,0.0) * <x> + (0.0,1.0) * <y> )
    }
    desc_text_container : SetTags dadmod_box = 1 box_w = <w> box_scale = <sc> panel_alpha = <pa> accent_on = <accent_on>
    CreateScreenElement {
    local_id = panel
    parent = desc_text_container
    type = SpriteElement
    texture = white
    rgba = <bg_rgba>
    alpha = 0.0
    just = [ center top ]
    pos = (0.0,0.0)
    scale = ( (0.25,0.0) * ( <w> + 24 ) + (0.0,10.0) )
    z_priority = 1010
    }
    CreateScreenElement {
    local_id = accent
    parent = desc_text_container
    type = SpriteElement
    texture = white
    rgba = <accent_rgba>
    alpha = 0.0
    just = [ center top ]
    pos = (0.0,0.0)
    scale = ( (0.25,0.0) * ( <w> + 24 ) + (0.0,0.5) )
    z_priority = 1011
    }
    CreateScreenElement {
    local_id = text
    parent = desc_text_container
    type = TextBlockElement
    font = bebas
    text = ""
    dims = ( (1.0,0.0) * ( <w> / <sc> ) )
    allow_expansion
    just = [ center top ]
    internal_just = <ij>
    scale = <sc>
    pos = (0.0,12.0)
    rgba = <text_rgba>
    alpha = 0.0
    z_priority = 1020
    }
endscript

script dadmod_desc_fit_later
    wait 1 gameframe
    dadmod_desc_fit
endscript

script dadmod_desc_fit
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    desc_text_container : GetTags
    GetScreenElementDims id = { desc_text_container child = text }
    h = ( <height> + 24 )
    panel_scale = ( (0.25,0.0) * ( <box_w> + 24 ) + (0.0,0.25) * <h> )
    if GotParam hide
        DoScreenElementMorph id = { desc_text_container child = panel } alpha = 0.0 time = 0.15
        if ScreenElementExists id = { desc_text_container child = accent }
            DoScreenElementMorph id = { desc_text_container child = accent } alpha = 0.0 time = 0.15
        endif
    else
        DoScreenElementMorph id = { desc_text_container child = panel } scale = <panel_scale> alpha = <panel_alpha> time = 0.12
        if (<accent_on> = 1)
            if ScreenElementExists id = { desc_text_container child = accent }
                DoScreenElementMorph id = { desc_text_container child = accent } alpha = 1.0 time = 0.12
            endif
        endif
    endif
endscript

script thugpro_menu_desc_text_focus
    if not GotParam text
        return
    endif
    Change dadmod_desc_seq = ( dadmod_desc_seq + 1 )
    THUGRECOMP_TextClip text = <text> max = 90
    short = <clipped>
    dadmod_box = 0
    if ScreenElementExists id = desc_text_container
        desc_text_container : GetTags
    endif
    if not (<dadmod_box> = 1)
        text = <short>
    endif
    if ScreenElementExists id = desc_text_container
        DoScreenElementMorph {
        id = { desc_text_container child = text }
        alpha = 0.8
        time = 0.2
        }
        SetScreenElementProps {
        id = { desc_text_container child = text }
        text = <text>
        }
        KillSpawnedScript Name = dadmod_desc_fit_later
        SpawnScript dadmod_desc_fit_later
        if (<short> = "")
            dadmod_desc_strip alpha = 0.0
        else
            dadmod_desc_strip alpha = 0.4
        endif
    endif
    if ScreenElementExists id = tp_helper_text
        DoScreenElementMorph {
        id = tp_helper_text
        alpha = 0.8
        time = 0.2
        }
        SetScreenElementProps {
        id = tp_helper_text
        text = <short>
        }
    endif
endscript

script dadmod_desc_panel_refresh
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    dadmod_desc_panel_right
    SetScreenElementProps id = { desc_text_container child = text } text = "Description box preview: this is where the text for the selected option shows up."
    DoScreenElementMorph id = { desc_text_container child = text } alpha = 0.8 time = 0.1
    KillSpawnedScript Name = dadmod_desc_fit_later
    SpawnScript dadmod_desc_fit_later
endscript

script dadmod_offline_ui_live
    dadmod_ui_apply
    dadmod_ui_repaint
    dadmod_desc_panel_refresh
    if GotParam main
        if ScreenElementExists id = startup_menu
            create_main_menu
        endif
    endif
endscript

script thugpro_menu_create_helper_text parent = current_menu_anchor
    if not LevelIs Load_MainMenu
        dadmod_desc_panel_right
        return
    endif
    Change dadmod_desc_is_strip = 1
    if ScreenElementExists id = desc_text_container
        DestroyScreenElement id = desc_text_container
    endif
    CreateScreenElement {
    id = desc_text_container
    parent = <parent>
    type = ContainerElement
    pos = (320.0,398.0)
    }
    CreateScreenElement {
    local_id = text
    parent = desc_text_container
    type = TextElement
    font = bebas
    text = ""
    scale = 0.15
    alpha = 0.0
    just = [ center center ]
    internal_just = [ center center ]
    z_priority = 1020
    }
    CreateScreenElement {
    local_id = panel
    parent = desc_text_container
    type = SpriteElement
    texture = white
    alpha = 0.0
    just = [ center center ]
    rgba = [ 0 0 0 128 ]
    scale = (200.0,10.0)
    }
endscript

script dadmod_desc_strip alpha = 0.0
    if not IsTrue dadmod_desc_is_strip
        return
    endif
    if not ScreenElementExists id = { desc_text_container child = panel }
        return
    endif
    DoScreenElementMorph id = { desc_text_container child = panel } alpha = <alpha> time = 0.2
endscript

dadmod_desc_seq = 0

dadmod_desc_is_strip = 0

script thugpro_menu_desc_text_unfocus
    if ScreenElementExists id = desc_text_container
        DoScreenElementMorph id = { desc_text_container child = text } alpha = 0.0 time = 0.2
        SetScreenElementProps id = { desc_text_container child = text } text = " "
        dadmod_desc_strip alpha = 0.0
        KillSpawnedScript Name = dadmod_desc_fit_later
        KillSpawnedScript Name = dadmod_desc_hide_later
        SpawnScript dadmod_desc_hide_later params = { seq = ( dadmod_desc_seq ) }
    endif
    if ScreenElementExists id = tp_helper_text
        DoScreenElementMorph id = tp_helper_text alpha = 0.0 time = 0.2
        SetScreenElementProps id = tp_helper_text text = " "
    endif
endscript

script dadmod_desc_hide_later
    wait 2 gameframes
    if not (<seq> = ( dadmod_desc_seq ))
        return
    endif
    if not ScreenElementExists id = desc_text_container
        return
    endif
    if desc_text_container : GetSingleTag dadmod_box
        dadmod_desc_fit hide
    endif
endscript

script make_thugpro_menu_item {
    parent_id = current_menu
    Dims = (3.2e+02,20.5)
    Just = [ LEFT , CENTER ]
    text_just = [ LEFT , CENTER ]
    text_alpha = 1.0
    Scale = 1.0
    width_ajustment = 1.0
    focus_script = NullScript
    unfocus_script = NullScript
    focus_params = { }
    unfocus_params = { }
    child_texture_offset = (-183.0,1e+01)
    child_texture_alpha = 0.0
    child_texture_scale = 0.8
    extra_text_scale = 0.2
    extra_text_align = CENTER
    }
    if GotParam id
        if not GotParam dadmod_ins_inner
            dadmod_ins_check id = <id>
            if (<dadmod_ins> = 1)
                make_thugpro_menu_item <...> dadmod_ins_inner
                dadmod_ins_items
                return
            endif
        endif
    endif
    if not GotParam dadmod_replay
        dadmod_capture_item <...>
        if (<captured> = 1)
            return
        endif
    endif
    if not GotParam dadmod_rebuild
        dadmod_keep_item <...>
    endif
    if GotParam #"0x1d710c47"
        make_thugpro_menu_item_orig <...>
        return
    endif
    if GotParam #"0x8f12a08c"
        make_thugpro_menu_item_orig <...>
        return
    endif
    if ScreenElementExists ID = <ID>
        RemoveParameter ID
    endif
    if GotParam helper_text
        edmsg2 "@FIXME: \\c2'%a', got param helper_text!" #"0x174841bc" = <TEXT>
    endif
    if GotParam ID
        container_id = <ID>
    else
        FormatText TextName = auto_id "autoid_%a_%b" #"0x174841bc" = randomrange (0.0,2048.0) #"0x8e411006" = randomrange (0.0,8096.0)
        FormatText ChecksumName = container_id "%a" #"0x174841bc" = <auto_id>
    endif
    if GotParam not_focusable
        <text_alpha> = 0.4
        if GotParam heading_alpha
            <text_alpha> = <heading_alpha>
        endif
        <focusable> = not_focusable
    endif
    if not ScreenElementExists ID = { <parent_id> child = 0 }
        <first_item> = first_item
        <actually_first_item> = first_item
    endif
    if GotParam line_top
        <first_item> = first_item
    endif
    if GotParam line_bot
        <last_item> = last_item
    endif
    if <parent_id> : GetSingleTag boxed
    endif
    if GotParam no_box
        RemoveParameter boxed
    endif
    if <parent_id> : GetSingleTag SCROLLING
    endif
    if <parent_id> : GetSingleTag wide_extra_text
    endif
    if <parent_id> : GetSingleTag colorful
    endif
    if <parent_id> : GetSingleTag menu_item_max_width
        <max_width> = <menu_item_max_width>
        RemoveParameter menu_item_max_width
    endif
    if GotParam centered
        text_just = [ CENTER , CENTER ]
        text_offset = (158.0,0.0)
    endif
    if <parent_id> : GetSingleTag width_ajustment
        Printf "Got width_ajustment style from parent menu!"
    endif
    <bar_scale> = ( ( (0.32,0.0) * <width_ajustment> ) + (0.0,0.24) )
    <box_line_width> = ( (8e+01,0.0) * <width_ajustment> )
    <box_line_pos> = ( ( (3.2e+02,0.0) * <width_ajustment> ) + (-4.0,0.0) )
    <option_arrow_left_offset> = (2e+01,1e+01)
    <option_arrow_right_offset> = ( (1.4e+02,1e+01) - (4.0,0.0) )
    <extra_text_offset> = ( (8e+01,0.0) + (-4.0,1e+01) )
    if GotParam wide_extra_text
        <extra_text_offset> = ( <extra_text_offset> - (2e+01,0.0) )
        <option_arrow_left_offset> = ( <option_arrow_left_offset> - (4e+01,0.0) )
    endif
    <option_arrow_left_offset> = ( <option_arrow_left_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    <option_arrow_right_offset> = ( <option_arrow_right_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    <extra_text_offset> = ( <extra_text_offset> + ( <width_ajustment> * (3.2e+02,0.0) ) - (3.2e+02,0.0) )
    CreateScreenElement {
    TYPE = ContainerElement
    ID = <container_id>
    Parent = <parent_id>
    Scale = <Scale>
    z_priority = 1000
    Dims = <Dims>
    Just = <Just>
    <focusable>
    }
    <container_id> : SetTags Parent = <parent_id>
    <container_id> : SetTags dadmod_base_scale = <Scale>
    if GotParam sub_label
        <container_id> : SetTags dadmod_sub = <sub_label>
    endif
    if GotParam not_focusable
        <container_id> : SetTags dadmod_nf = 1
    endif
    if not GotParam not_counted
        if <parent_id> : GetSingleTag menu_item_count
            <container_id> : SetTags menu_item_index = <menu_item_count>
            <parent_id> : SetTags menu_item_count = ( <menu_item_count> + 1 )
        endif
    endif
    if GotParam actually_first_item
        <container_id> : SetTags first_item = <actually_first_item>
    endif
    if GotParam child_texture_persistent
        <container_id> : SetTags child_texture_persistent = 1
    endif
    if GotParam sub_label
        dadmod_hl_style
        if (<hl> = 3)
            TEXT = <sub_label>
        endif
    endif
    if GotParam TEXT
        GetUpperCaseString <TEXT>
        CreateScreenElement {
        TYPE = TextElement
        local_id = TEXT
        Parent = <container_id>
        TEXT = <TEXT>
        Font = Crillee
        Scale = 0.2
        Pos = <text_offset>
        Just = <text_just>
        Alpha = <text_alpha>
        rgba = ( ( THUGPRO_GlobalThemeInfo ) . UNHIGHLIGHTED_TEXT_COLOR )
        z_priority = 1002
        }
        <container_id> : SetTags dadmod_txt = <TEXT>
        if GotParam centered
            <container_id> : SetTags dadmod_center = 1
        endif
        if GotParam max_width
            truncate_string ID = { <container_id> child = TEXT } max_width = <max_width>
        endif
    endif
    if GotParam extra_text
        RemoveParameter UpperCaseString
        GetUpperCaseString <extra_text>
        GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <extra_text_offset>
        CreateScreenElement {
        TYPE = TextElement
        local_id = extra_text
        Parent = <container_id>
        TEXT = <extra_text>
        Font = Crillee
        Scale = <extra_text_scale>
        Pos = <Pos>
        internal_just = [ CENTER CENTER ]
        Just = [ CENTER CENTER ]
        rgba = [ 90 90 90 90 ]
        z_priority = 1006
        Alpha = <text_alpha>
        }
        <container_id> : SetTags dadmod_xbase = <extra_text_scale>
        if GotParam dadmod_nofit
            <container_id> : SetTags dadmod_nofit = 1
        endif
        if GotParam option_arrows
            GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <option_arrow_left_offset>
            CreateScreenElement {
            TYPE = SpriteElement
            local_id = left_arrow
            Parent = <container_id>
            Just = [ CENTER , CENTER ]
            Alpha = 0.0
            rgba = [ 128 128 128 128 ]
            Texture = left_arrow
            Pos = <Pos>
            Scale = 0.4
            z_priority = 1002
            }
            GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <option_arrow_right_offset>
            CreateScreenElement {
            TYPE = SpriteElement
            local_id = right_arrow
            Parent = <container_id>
            Just = [ CENTER , CENTER ]
            Alpha = 0.0
            rgba = [ 128 128 128 128 ]
            Texture = right_arrow
            Pos = <Pos>
            Scale = 0.4
            z_priority = 1002
            }
        endif
    endif
    if GotParam child_texture
        GetStackedScreenElementPos #"0x7323e97c" ID = <container_id> offset = <child_texture_offset>
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = ICON
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = <child_texture_alpha>
        Texture = <child_texture>
        Pos = <Pos>
        Scale = <child_texture_scale>
        rgba = <child_texture_rgba>
        z_priority = 1004
        }
    endif
    if not GotParam no_bar
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = Bar
        Parent = <container_id>
        Just = <Just>
        Alpha = 0.0
        Texture = new_menu_bar
        Pos = (-5.0,2.5)
        Scale = <bar_scale>
        z_priority = 500
        }
    endif
    if GotParam boxed
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = line_left
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = 1.0
        Texture = WHITE
        Pos = (-4.0,0.0)
        Scale = (0.1,5.7)
        z_priority = 600
        }
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = line_right
        Parent = <container_id>
        Just = [ CENTER , CENTER ]
        Alpha = 1.0
        Texture = WHITE
        Pos = <box_line_pos>
        Scale = (0.1,5.7)
        z_priority = 600
        }
        if not GotParam SCROLLING
            if GotParam first_item
                CreateScreenElement {
                TYPE = SpriteElement
                local_id = line_top
                Parent = <container_id>
                Just = <Just>
                Alpha = 1.0
                Texture = WHITE
                Pos = (-4.0,-11.0)
                Scale = ( <box_line_width> + (0.0,0.1) )
                z_priority = 600
                }
            endif
            if GotParam last_item
                CreateScreenElement {
                TYPE = SpriteElement
                local_id = line_bot
                Parent = <container_id>
                Just = <Just>
                Alpha = 1.0
                Texture = WHITE
                Pos = (-4.0,11.0)
                Scale = ( <box_line_width> + (0.0,0.1) )
                z_priority = 600
                }
            endif
        endif
        if GotParam colorful
            <background_rgba> = ( ( THUGPRO_GlobalThemeInfo ) . HIGHLIGHTED_TEXT_COLOR )
        else
            <background_rgba> = ( ( THUGPRO_GlobalThemeInfo ) . UNHIGHLIGHTED_TEXT_COLOR )
        endif
        CreateScreenElement {
        TYPE = SpriteElement
        local_id = background
        Parent = <container_id>
        Pos = (-4.0,0.0)
        Scale = ( <box_line_width> + (0.0,5.7) )
        Just = <Just>
        Texture = WHITE
        Alpha = 0.5
        rgba = [ 20 20 20 128 ]
        z_priority = 400
        }
    endif
    if GotParam not_focusable
        return
    endif
    SetScreenElementProps {
    ID = <container_id>
    event_handlers = [
    { Focus thugpro_menu_item_focus }
    { unfocus thugpro_menu_item_unfocus }
    { Focus <focus_script> Params = <focus_params> }
    { unfocus <unfocus_script> Params = <unfocus_params> }
    ]
    replace_handlers
    }
    if GotParam description_text
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = [
        { Focus thugpro_menu_desc_text_focus Params = { TEXT = <description_text> } }
        { unfocus thugpro_menu_desc_text_unfocus }
        ]
        }
    endif
    if GotParam option_arrows
        if GotParam option_arrows_callback
            if GotParam option_arrows_callback_params
                if GotParam pad_choose
                    handlers = [
                    { pad_left <option_arrows_callback> Params = ( { LEFT } + <option_arrows_callback_params> ) }
                    { pad_right <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    { pad_choose <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    ]
                else
                    handlers = [
                    { pad_left <option_arrows_callback> Params = ( { LEFT } + <option_arrows_callback_params> ) }
                    { pad_right <option_arrows_callback> Params = ( { RIGHT } + <option_arrows_callback_params> ) }
                    ]
                endif
            else
                if GotParam pad_choose
                    handlers = [
                    { pad_left <option_arrows_callback> Params = { LEFT } }
                    { pad_right <option_arrows_callback> Params = { RIGHT } }
                    { pad_choose <option_arrows_callback> Params = { RIGHT } }
                    ]
                else
                    handlers = [
                    { pad_left <option_arrows_callback> Params = { LEFT } }
                    { pad_right <option_arrows_callback> Params = { RIGHT } }
                    ]
                endif
            endif
            SetScreenElementProps {
            ID = <container_id>
            event_handlers = <handlers>
            }
        endif
    endif
    if GotParam pad_back_script
        if GotParam pad_choose_params
            handlers = [ { pad_back <pad_back_script> Params = <pad_back_params> } ]
        else
            handlers = [ { pad_back <pad_back_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
    endif
    if GotParam pad_choose_script
        if GotParam pad_choose_params
            handlers = [ { pad_choose <pad_choose_script> Params = <pad_choose_params> } ]
        else
            handlers = [ { pad_choose <pad_choose_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
        if not GotParam no_sound
            SetScreenElementProps {
            ID = <container_id>
            event_handlers = [ { pad_choose generic_menu_pad_choose_sound } ]
            }
        endif
    endif
    if GotParam pad_option_script
        if GotParam pad_option_params
            handlers = [ { pad_option <pad_option_script> Params = <pad_option_params> } ]
        else
            handlers = [ { pad_option <pad_option_script> } ]
        endif
        SetScreenElementProps {
        ID = <container_id>
        event_handlers = <handlers>
        }
    endif
    if GotParam dadmod_rebuild
        dadmod_keep_link h = <dadmod_rebuild> item = <container_id>
    else
        dadmod_keep_link h = ( dadmod_keep_last ) item = <container_id>
    endif
    return { menu_item_id = <container_id> }
endscript

dadmod_cap_count = 0

script dadmod_capture_item
    if ScreenElementExists id = <parent_id>
        if <parent_id> : GetSingleTag Anchor
            if GotParam text
                THUGRECOMP_MenuSeen menu = <Anchor> text = <text>
            endif
            if THUGRECOMP_MenuHasOrder menu = <Anchor>
                Change dadmod_cap_count = ( dadmod_cap_count + 1 )
                FormatText ChecksumName = holder "dadmod_cap_%i" i = ( dadmod_cap_count )
                CreateScreenElement {
                type = ContainerElement
                parent = root_window
                id = <holder>
                alpha = 0.0
                }
                <holder> : SetTags <...>
                THUGRECOMP_CapturePush id = <holder> text = <text>
                return captured = 1
            endif
        endif
    endif
    return captured = 0
endscript

script dadmod_replay_all
    if not ScreenElementExists id = <menu_parent>
        THUGRECOMP_CaptureClear
        return
    endif
    if not <menu_parent> : GetSingleTag Anchor
        return
    endif
    begin
        if not THUGRECOMP_CaptureNext menu = <Anchor>
            break
        endif
        h = <id>
        if (<hide> = 0)
            dadmod_replay_item h = <h> grey = <grey> stock = <stock>
        endif
        if ScreenElementExists id = <h>
            DestroyScreenElement id = <h>
        endif
    repeat
endscript

script dadmod_replay_item
    <h> : GetTags
    if (<grey> = 1)
        make_thugpro_menu_item <...> dadmod_replay not_focusable = not_focusable
    else
        make_thugpro_menu_item <...> dadmod_replay
    endif
endscript

script thugpro_menu_finalize {
    Parent = current_menu
    }
    dadmod_skc_et_items
    dadmod_replay_all menu_parent = <Parent>
    thugpro_menu_find_last_item { Parent = <Parent> }
    if GotParam last_item_id
        SetScreenElementProps ID = <last_item_id> TAGS = { last_item = last_item }
    endif
    if <Parent> : GetSingleTag boxed
        <Parent> : GetSingleTag width_ajustment
        if not <Parent> : GetSingleTag SCROLLING
            thugpro_menu_mark_last_item { ID = <last_item_id> width_ajustment = <width_ajustment> Parent = <Parent> }
        endif
    endif
    thugpro_menu_update_counter_text <...>
    dadmod_move_hint_menu
    SetScreenElementProps ID = root_window TAGS = { menu_state = ON }
    if not GotParam no_animate
        RunScriptOnScreenElement ID = <Parent> animate_in_fade
    endif
    if not GotParam no_focus
        if ScreenElementExists id = <Parent>
            if GotParam focus_target
                FireEvent TYPE = Focus Target = <Parent> data = { child_id = <focus_target> }
            else
                FireEvent TYPE = Focus Target = <Parent>
            endif
        endif
    endif
    KillSpawnedScript Name = dadmod_fit_all
    SpawnScript dadmod_fit_all
endscript

dadmod_keep_n = 0

dadmod_keep_last = none

dadmod_reorder_on = 0

dadmod_reorder_pick = -1

dadmod_reorder_menu = none

script dadmod_keep_item
    Change dadmod_keep_last = none
    if not ScreenElementExists id = current_menu_anchor
        return
    endif
    if not ScreenElementExists id = <parent_id>
        return
    endif
    if not <parent_id> : GetSingleTag Anchor
        return
    endif
    if not current_menu_anchor : GetSingleTag dadmod_keep_menu
        Change dadmod_keep_n = 0
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_keep_menu = <Anchor> }
    endif
    if not GotParam stock
        stock = ( dadmod_keep_n )
    endif
    FormatText ChecksumName = keep_h "dadmod_keep_%i" i = ( dadmod_keep_n )
    if ScreenElementExists id = <keep_h>
        DestroyScreenElement id = <keep_h>
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = current_menu_anchor
    id = <keep_h>
    alpha = 0.0
    }
    <keep_h> : SetTags <...>
    Change dadmod_keep_last = <keep_h>
    Change dadmod_keep_n = ( dadmod_keep_n + 1 )
endscript

script dadmod_keep_link
    if ScreenElementExists id = <h>
        SetScreenElementProps id = <h> tags = { dadmod_item = <item> }
    endif
endscript

script dadmod_reorder_keys
    if ScreenElementExists id = startup_menu
        return
    endif
    if not ScreenElementExists id = current_menu_anchor
        Change dadmod_reorder_on = 0
        return
    endif
    if IsTrue dadmod_reorder_on
        live = 0
        if current_menu_anchor : GetSingleTag dadmod_reorder_live
            live = <dadmod_reorder_live>
        endif
        if (<live> = 0)
            Change dadmod_reorder_on = 0
        endif
    endif
    dadmod_pad_chord
    if THUGRECOMP_KeyPressed key = "F9"
        SpawnScript dadmod_reorder_toggle
    endif
    if (<chord> = 1)
        SpawnScript dadmod_reorder_toggle
    endif
    if IsTrue dadmod_reorder_on
        if THUGRECOMP_KeyPressed key = "F10"
            SpawnScript dadmod_reorder_undo
        endif
        if THUGRECOMP_KeyPressed key = "F12"
            SpawnScript dadmod_reorder_reset
        endif
        if (<chord> = 2)
            SpawnScript dadmod_reorder_undo
        endif
        if (<chord> = 3)
            SpawnScript dadmod_reorder_reset
        endif
    endif
endscript

script dadmod_reorder_toggle
    if not ScreenElementExists id = current_menu_anchor
        return
    endif
    if IsTrue dadmod_reorder_on
        Change dadmod_reorder_on = 0
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
        THUGRECOMP_Log text = "menu reorder: done"
        return
    endif
    if not current_menu_anchor : GetSingleTag dadmod_keep_menu
        return
    endif
    if ( ( dadmod_keep_n ) < 2 )
        return
    endif
    if current_menu_anchor : GetSingleTag dadmod_reorder_live
        if not THUGRECOMP_ReorderPermInit menu = <dadmod_keep_menu> count = ( dadmod_keep_n )
            return
        endif
    else
        if not THUGRECOMP_ReorderPermInit menu = <dadmod_keep_menu> count = ( dadmod_keep_n ) fresh = 1
            return
        endif
    endif
    Change dadmod_reorder_menu = <dadmod_keep_menu>
    Change dadmod_reorder_pick = -1
    Change dadmod_reorder_on = 1
    THUGRECOMP_Log text = "menu reorder: move mode on"
    dadmod_reorder_rebuild
endscript

script dadmod_reorder_rebuild
    n = ( dadmod_keep_n )
    i = 0
    begin
        if (<i> = <n>)
            break
        endif
        FormatText ChecksumName = h "dadmod_keep_%i" i = <i>
        if ScreenElementExists id = <h>
            if <h> : GetSingleTag dadmod_item
                if ScreenElementExists id = <dadmod_item>
                    DestroyScreenElement id = <dadmod_item>
                endif
            endif
        endif
        i = ( <i> + 1 )
    repeat
    THUGRECOMP_ReorderPermInit menu = ( dadmod_reorder_menu ) count = <n>
    pos = 0
    begin
        if (<pos> = <n>)
            break
        endif
        if THUGRECOMP_ReorderPermAt pos = <pos>
            FormatText ChecksumName = h "dadmod_keep_%i" i = <idx>
            if ScreenElementExists id = <h>
                dadmod_reorder_make h = <h> pos = <pos>
            endif
        endif
        pos = ( <pos> + 1 )
    repeat
    if IsTrue dadmod_reorder_on
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_reorder_live = 1 }
    else
        SetScreenElementProps id = current_menu_anchor tags = { dadmod_reorder_live = 0 }
    endif
    thugpro_menu_finalize no_animate
    if GotParam focus_pos
        SpawnScript dadmod_reorder_refocus params = { focus_pos = <focus_pos> n = <n> }
    endif
endscript

script dadmod_reorder_refocus
    wait 2 gameframes
    if not ScreenElementExists id = current_menu
        return
    endif
    if GetScreenElementChildren id = current_menu
        GetArraySize <children>
        k = ( <array_size> - <n> + <focus_pos> )
        if (<k> > -1)
            if (<k> < <array_size>)
                FireEvent Type = unfocus target = current_menu
                FireEvent Type = Focus target = current_menu data = { child_id = ( <children> [ <k> ] ) }
            endif
        endif
    endif
endscript

script dadmod_reorder_make
    dadmod_ro_holder = <h>
    <dadmod_ro_holder> : GetTags
    RemoveParameter dadmod_item
    if IsTrue dadmod_reorder_on
        RemoveParameter option_arrows
        RemoveParameter option_arrows_callback
        RemoveParameter option_arrows_callback_params
        RemoveParameter pad_choose
        RemoveParameter not_focusable
        focus_script = NullScript
        unfocus_script = NullScript
        focus_params = { }
        unfocus_params = { }
        if GotParam text
            if ( ( dadmod_reorder_pick ) = <pos> )
                FormatText TextName = text "\\c4> %s <" s = <text>
            endif
        endif
        if ( ( dadmod_reorder_pick ) = <pos> )
            description_text = "Now choose where to put it"
        else
            if dadmod_on_pad
                description_text = "Move mode: \\b9+\\bh undo, \\b9+\\be stock order, \\b9+\\bg done. Pick an option, then where it goes"
            else
                description_text = "Move mode: pick an option, then where it goes. F10 undo, F12 stock order, F9 done"
            endif
        endif
        pad_choose_script = dadmod_reorder_choose
        pad_choose_params = { pos = <pos> }
    endif
    make_thugpro_menu_item <...> dadmod_rebuild = <dadmod_ro_holder> dadmod_replay
    return made_id = <menu_item_id>
endscript

script dadmod_reorder_choose
    if ( ( dadmod_reorder_pick ) = -1 )
        Change dadmod_reorder_pick = <pos>
    else
        THUGRECOMP_ReorderPermMove from = ( dadmod_reorder_pick ) to = <pos>
        Change dadmod_reorder_pick = -1
        dadmod_reorder_save
    endif
    dadmod_reorder_rebuild focus_pos = <pos>
endscript

script dadmod_reorder_save
    THUGRECOMP_ReorderBegin menu = ( dadmod_reorder_menu )
    n = ( dadmod_keep_n )
    pos = 0
    begin
        if (<pos> = <n>)
            break
        endif
        if THUGRECOMP_ReorderPermAt pos = <pos>
            FormatText ChecksumName = h "dadmod_keep_%i" i = <idx>
            t = "-"
            if ScreenElementExists id = <h>
                if <h> : GetSingleTag text
                    t = <text>
                endif
            endif
            THUGRECOMP_ReorderAdd text = <t>
        endif
        pos = ( <pos> + 1 )
    repeat
    THUGRECOMP_ReorderSave
endscript

script dadmod_reorder_undo
    if THUGRECOMP_ReorderUndo menu = ( dadmod_reorder_menu )
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
    endif
endscript

script dadmod_reorder_reset
    if THUGRECOMP_ReorderReset menu = ( dadmod_reorder_menu )
        THUGRECOMP_ReorderPermPush
        n = ( dadmod_keep_n )
        pos = 0
        begin
            if (<pos> = <n>)
                break
            endif
            i = 0
            begin
                if (<i> = <n>)
                    break
                endif
                FormatText ChecksumName = h "dadmod_keep_%i" i = <i>
                if ScreenElementExists id = <h>
                    if <h> : GetSingleTag stock
                        if (<stock> = <pos>)
                            THUGRECOMP_ReorderPermSet pos = <pos> idx = <i>
                        endif
                    endif
                endif
                i = ( <i> + 1 )
            repeat
            pos = ( <pos> + 1 )
        repeat
        Change dadmod_reorder_pick = -1
        dadmod_reorder_rebuild
    endif
endscript

script dadmod_move_hint_menu
    anchor_id = helper_text_anchor
    if ScreenElementExists id = dadmod_helper_store
        dadmod_helper_store : GetSingleTag anchor_id
    endif
    dadmod_move_hint anchor_id = <anchor_id>
endscript

script dadmod_move_hint_off anchor_id = helper_text_anchor
    if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_undo } }
        DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_undo } }
    endif
    if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_stock } }
        DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_stock } }
    endif
    if GotParam all
        if ScreenElementExists id = { <anchor_id> child = { line1 child = dadmod_hint_move } }
            DestroyScreenElement id = { <anchor_id> child = { line1 child = dadmod_hint_move } }
        endif
    endif
endscript

script dadmod_hint_text
    if ScreenElementExists id = { <anchor_id> child = { line1 child = <name> } }
        SetScreenElementProps id = { <anchor_id> child = { line1 child = <name> } } text = <text>
        return
    endif
    CreateScreenElement {
    Type = textElement
    parent = { <anchor_id> child = line1 }
    local_id = <name>
    font = dialog
    text = <text>
    rgba = [ 70 70 70 108 ]
    scale = 0.75
    z_priority = 2100
    Pos = (0.0,0.0)
    not_focusable
    }
endscript

script dadmod_move_hint
    if not GotParam anchor_id
        anchor_id = helper_text_anchor
    endif
    if not ScreenElementExists id = <anchor_id>
        return
    endif
    if not ScreenElementExists id = { <anchor_id> child = line1 }
        return
    endif
    ok = 0
    if not ScreenElementExists id = startup_menu
        if ScreenElementExists id = current_menu_anchor
            if current_menu_anchor : GetSingleTag dadmod_keep_menu
                if ( ( dadmod_keep_n ) > 1 )
                    ok = 1
                endif
            endif
        endif
    endif
    if (<ok> = 0)
        dadmod_move_hint_off all = 1 anchor_id = <anchor_id>
        return
    endif
    on = 0
    if IsTrue dadmod_reorder_on
        on = 1
    endif
    if ( ( GLOBAL_CtrlLayout ) = 0 )
        if (<on> = 1)
            t1 = "F9 = Done"
            t2 = "F10 = Undo"
            t3 = "F12 = Stock order"
        else
            t1 = "F9 = Reorder"
        endif
    else
        if (<on> = 1)
            t1 = "\\b9+\\bg = Done"
            t2 = "\\b9+\\bh = Undo"
            t3 = "\\b9+\\be = Stock order"
        else
            t1 = "\\b9+\\bg = Reorder"
        endif
    endif
    dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_move text = <t1>
    if (<on> = 1)
        dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_undo text = <t2>
        dadmod_hint_text anchor_id = <anchor_id> name = dadmod_hint_stock text = <t3>
    else
        dadmod_move_hint_off anchor_id = <anchor_id>
    endif
endscript

script dadmod_helper_seen
    if ScreenElementExists id = dadmod_helper_store
        DestroyScreenElement id = dadmod_helper_store
    endif
    CreateScreenElement {
    type = ContainerElement
    parent = root_window
    id = dadmod_helper_store
    alpha = 0.0
    }
    dadmod_helper_store : SetTags <...>
    if ( ( GLOBAL_CtrlLayout ) = 0 )
        if not GotParam spacing_between
            return spacing_between = 26
        endif
        if ( <spacing_between> < 26 )
            return spacing_between = 26
        endif
    endif
endscript

script dadmod_helper_refresh
    if not ScreenElementExists id = dadmod_helper_store
        return
    endif
    dadmod_helper_store : GetTags
    if not GotParam anchor_id
        anchor_id = helper_text_anchor
    endif
    if not ScreenElementExists id = <anchor_id>
        return
    endif
    if GotParam parent
        if not ScreenElementExists id = <parent>
            return
        endif
    endif
    create_helper_text <...>
endscript

script dadmod_prompt_tick
    dadmod_char_guide_tick
    if not THUGRECOMP_InputDevice
        return
    endif
    if ScreenElementExists id = keyboard_anchor
        return
    endif
    if THUGRECOMP_BindPoll
        return
    endif
    if THUGRECOMP_InputDevice apply = 1
        Change GLOBAL_CtrlLayout = <layout>
        dadmod_helper_refresh
    endif
endscript

script dadmod_btn
    if THUGRECOMP_ButtonText <...>
        return btn = <text>
    endif
    return btn = "?"
endscript

script dadmod_on_pad
    THUGRECOMP_InputDevice
    if (<device> = 1)
        return true
    endif
    return false
endscript

script dadmod_pad_chord
    chord = 0
    if THUGRECOMP_PadHeld button = "back"
        if THUGRECOMP_PadPressed button = "leftshoulder"
            chord = 1
        endif
        if THUGRECOMP_PadPressed button = "rightshoulder"
            chord = 2
        endif
        if THUGRECOMP_PadPressed button = "lefttrigger"
            chord = 3
        endif
    endif
    return chord = <chord>
endscript

script keyboard_key_focus
    if ObjectExists id = <id>
        DoScreenElementMorph id = <id> time = 0.05 scale = ( <org_scale> * 1.05 )
    endif
endscript

script keyboard_text_focus
    SetProps rgba = ( ( THUGPRO_GlobalThemeInfo ) . MENU_TITLE_COLOR )
endscript

script thugpro_menu_item_update_extra_text
    if ScreenElementExists id = { <id> child = extra_text }
        if GotParam text
            GetUpperCaseString <text>
            SetScreenElementProps id = { <id> child = extra_text } text = <text>
        else
            if GotParam off
                SetScreenElementProps id = { <id> child = extra_text } text = "OFF"
            else
                SetScreenElementProps id = { <id> child = extra_text } text = "ON"
            endif
        endif
        dadmod_fit_extra id = <id>
    endif
endscript

script dadmod_hl_style
    fxs = ( dadmod_ui_fx )
    if StructureContains structure = <fxs> hl
        return hl = ( <fxs> . hl )
    endif
    return hl = 0
endscript

script dadmod_hl_measure
    GetScreenElementDims id = <id>
    iw = <width>
    GetScreenElementDims id = { <id> child = text }
    lw = 0.0
    if (<iw> > 0)
        lw = ( <width> * 320.0 / <iw> )
    endif
    RemoveParameter dadmod_center
    <id> : GetTags
    left = 0.0
    if GotParam dadmod_center
        left = ( 158.0 - <lw> / 2.0 )
    endif
    return lw = <lw> left = <left>
endscript

script dadmod_hl_clear
    if ScreenElementExists id = { <id> child = dadmod_hl_u }
        DestroyScreenElement id = { <id> child = dadmod_hl_u }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_m }
        DestroyScreenElement id = { <id> child = dadmod_hl_m }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_l }
        DestroyScreenElement id = { <id> child = dadmod_hl_l }
    endif
    if ScreenElementExists id = { <id> child = dadmod_hl_r }
        DestroyScreenElement id = { <id> child = dadmod_hl_r }
    endif
endscript

script dadmod_hl_focus
    dadmod_hl_style
    if (<hl> = 0)
        return
    endif
    if not ScreenElementExists id = <id>
        return
    endif
    if ScreenElementExists id = { <id> child = bar }
        DoScreenElementMorph id = { <id> child = bar } alpha = 0.0 time = 0
        RunScriptOnScreenElement id = { <id> child = bar } dadmod_hl_hide_bar
    endif
    Change random_effect_break_loop = 1
    dadmod_hl_clear id = <id>
    RemoveParameter dadmod_base_scale
    RemoveParameter dadmod_slid
    dadmod_grown = 0
    <id> : GetTags
    bs = 1.0
    if GotParam dadmod_base_scale
        bs = <dadmod_base_scale>
    endif
    switch <hl>
    case 1
        if (<dadmod_grown> = 0)
            <id> : SetTags dadmod_grown = 1
            dadmod_hl_grow id = <id> s = 1.15
        endif
    case 2
        slid = 0
        if GotParam dadmod_slid
            slid = <dadmod_slid>
        endif
        if (<slid> = 0)
            <id> : SetTags dadmod_slid = 1
            RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_slide params = { dx = 12.0 }
        endif
    case 3
        dadmod_hl_brackets id = <id> on = 1
    case 4
        RunScriptOnScreenElement id = <id> dadmod_hl_decorate params = { id = <id> kind = 4 }
    case 5
        RunScriptOnScreenElement id = <id> dadmod_hl_decorate params = { id = <id> kind = 5 }
    case 6
        dadmod_hl_spotlight id = <id>
    case 7
        <id> : SetTags dadmod_bounce = 1
        RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_bounce params = { item = <id> }
    endswitch
endscript

script dadmod_hl_unfocus
    if not ScreenElementExists id = <id>
        return
    endif
    dadmod_hl_clear id = <id>
    RemoveParameter dadmod_base_scale
    RemoveParameter dadmod_slid
    dadmod_grown = 0
    <id> : GetTags
    if GotParam dadmod_base_scale
        DoScreenElementMorph id = <id> scale = <dadmod_base_scale> time = 0.08
    endif
    if GotParam dadmod_slid
        if (<dadmod_slid> = 1)
            <id> : SetTags dadmod_slid = 0
            if ScreenElementExists id = { <id> child = text }
                RunScriptOnScreenElement id = { <id> child = text } dadmod_hl_slide params = { dx = -12.0 }
            endif
        endif
    endif
    if (<dadmod_grown> = 1)
        <id> : SetTags dadmod_grown = 0
        dadmod_hl_grow id = <id> s = ( 1.0 / 1.15 )
    endif
    <id> : SetTags dadmod_bounce = 0
    dadmod_hl_brackets id = <id> on = 0
    dadmod_hl_style
    if (<hl> = 6)
        if ScreenElementExists id = { <id> child = text }
            DoScreenElementMorph id = { <id> child = text } alpha = 0.2 time = 0.1
        endif
    endif
endscript

script dadmod_hl_slide
    DoMorph time = 0.08 Pos = { ( (1.0,0.0) * <dx> ) relative }
endscript

script dadmod_hl_bounce
    begin
        if not ScreenElementExists id = <item>
            break
        endif
        RemoveParameter dadmod_bounce
        <item> : GetTags
        if not GotParam dadmod_bounce
            break
        endif
        if (<dadmod_bounce> = 0)
            break
        endif
        DoMorph time = 0.18 Pos = { (0.0,-3.0) relative }
        DoMorph time = 0.18 Pos = { (0.0,3.0) relative }
    repeat
endscript

script dadmod_hl_decorate
    wait 4 gameframes
    if not ScreenElementExists id = <id>
        return
    endif
    if not ( ( dadmod_ui_focused ) = <id> )
        return
    endif
    dadmod_hl_clear id = <id>
    dadmod_hl_measure id = <id>
    col = ( dadmod_ui_bar_rgba )
    switch <kind>
    case 3
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_l parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> - 6.0 ) ) just = [ center center ] scale = (0.3,2.2) rgba = <col> z_priority = 1003 }
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_r parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> + <lw> + 6.0 ) ) just = [ center center ] scale = (0.3,2.2) rgba = <col> z_priority = 1003 }
    case 4
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_u parent = <id> texture = white2 Pos = ( (1.0,0.0) * <left> + (0.0,9.0) ) just = [ left center ] scale = ( (1.0,0.0) * ( <lw> / 8.0 ) + (0.0,0.25) ) rgba = <col> z_priority = 1003 }
    case 5
        CreateScreenElement { Type = SpriteElement local_id = dadmod_hl_m parent = <id> texture = white2 Pos = ( (1.0,0.0) * ( <left> - 9.0 ) ) just = [ center center ] scale = (0.8,0.8) rot_angle = 45 rgba = <col> z_priority = 1003 }
    endswitch
endscript

script dadmod_hl_spotlight
    p = <id>
    RemoveParameter Parent
    <id> : GetTags
    if not GotParam Parent
        return
    endif
    if GetScreenElementChildren id = <Parent>
        GetArraySize <children>
        i = 0
        begin
            if (<i> = <array_size>)
                break
            endif
            c = ( <children> [ <i> ] )
            if ScreenElementExists id = { <c> child = text }
                RemoveParameter dadmod_nf
                <c> : GetTags
                if not GotParam dadmod_nf
                    if (<c> = <p>)
                        DoScreenElementMorph id = { <c> child = text } alpha = 1.0 time = 0.1
                    else
                        DoScreenElementMorph id = { <c> child = text } alpha = 0.2 time = 0.1
                    endif
                endif
            endif
            i = ( <i> + 1 )
        repeat
    endif
endscript

script dadmod_hl_hide_bar
    wait 2 gameframes
    DoMorph time = 0 alpha = 0.0
    wait 6 gameframes
    DoMorph time = 0 alpha = 0.0
endscript

script dadmod_hl_brackets
    RemoveParameter dadmod_txt
    RemoveParameter dadmod_plain
    <id> : GetTags
    if not GotParam dadmod_txt
        return
    endif
    if (<on> = 1)
        if not GotParam dadmod_plain
            <id> : SetTags dadmod_plain = <dadmod_txt>
            RemoveParameter dadmod_sub
            <id> : GetTags
            bl = <dadmod_txt>
            if GotParam dadmod_sub
                bl = <dadmod_sub>
            endif
            dadmod_hl_bracket_code
            dadmod_hl_text_managed
            if (<bcode> = "scan")
                <id> : SetTags dadmod_txt = <bl> dadmod_brk = "scan"
                RunScriptOnScreenElement id = <id> dadmod_hl_brk_scan params = { id = <id> bl = <bl> }
                return
            endif
            if (<managed> = 1)
                if (<bcode> = "")
                    bcode = "\\cc"
                endif
                <id> : SetTags dadmod_txt = <bl> dadmod_brk = <bcode>
            else
                if (<bcode> = "")
                    FormatText TextName = bt "> %s <" s = <bl>
                else
                    FormatText TextName = bt "%c> \\c0%s %c<" c = <bcode> s = <bl>
                endif
                <id> : SetTags dadmod_txt = <bt>
                if ScreenElementExists id = { <id> child = text }
                    SetScreenElementProps id = { <id> child = text } text = <bt>
                endif
            endif
        endif
    else
        if GotParam dadmod_plain
            <id> : SetTags dadmod_txt = <dadmod_plain> dadmod_brk = ""
            <id> : RemoveTags tags = [ dadmod_plain ]
            dadmod_hl_text_managed
            if (<managed> = 0)
                if ScreenElementExists id = { <id> child = text }
                    SetScreenElementProps id = { <id> child = text } text = <dadmod_plain>
                endif
            endif
        endif
    endif
endscript

script dadmod_hl_text_managed
    dadmod_ui_get key = "ui_rainbow" def = 0
    if (<value> > 4)
        if (<value> < 9)
            return managed = 1
        endif
    endif
    if (<value> = 0)
        dadmod_ui_get key = "ui_colortheme" def = 0
        if (<value> > 0)
            dadmod_ui_get key = "ui_theme_mode" def = 0
            if ( ( <value> = 2 ) or ( <value> = 4 ) or ( <value> = 5 ) )
                return managed = 1
            endif
        endif
    endif
    return managed = 0
endscript

script dadmod_hl_bracket_code
    dadmod_ui_get key = "ui_br_color" def = 10
    switch <value>
    case 1
        return bcode = "\\cc"
    case 2
        return bcode = "\\cg"
    case 3
        return bcode = "\\cb"
    case 4
        return bcode = "\\c5"
    case 5
        return bcode = "\\cf"
    case 6
        return bcode = "\\cd"
    case 7
        return bcode = "\\c6"
    case 8
        return bcode = "\\cu"
    case 9
        return bcode = "\\c7"
    case 10
        return bcode = "scan"
    endswitch
    return bcode = ""
endscript

script dadmod_hl_brk_code t = 0
    codes = [ "\\cg" "\\cb" "\\ce" "\\c5" "\\cf" "\\c4" "\\cd" "\\c6" "\\cu" "\\cs" "\\c7" "\\cl" ]
    dadmod_ui_get key = "ui_br_speed" def = 5
    k = ( <t> * 0.4 * <value> )
    CastToInteger k
    dadmod_ui_mod v = <k> m = 12
    return brk_code = ( <codes> [ <v> ] )
endscript

script dadmod_hl_brk_scan
    k = 0
    begin
        if not ScreenElementExists id = <id>
            break
        endif
        if not ( ( dadmod_ui_focused ) = <id> )
            break
        endif
        RemoveParameter dadmod_brk
        <id> : GetTags
        if not GotParam dadmod_brk
            break
        endif
        if not (<dadmod_brk> = "scan")
            break
        endif
        dadmod_hl_text_managed
        if (<managed> = 0)
            dadmod_hl_brk_code t = ( <k> * 0.5 )
            FormatText TextName = bt "%c> \\c0%s %c<" c = <brk_code> s = <bl>
            if ScreenElementExists id = { <id> child = text }
                SetScreenElementProps id = { <id> child = text } text = <bt>
            endif
        endif
        k = ( <k> + 1 )
        wait 0.1 seconds
    repeat
endscript

script dadmod_hl_grow
    dadmod_hl_grow_child id = { <id> child = text } s = <s>
    dadmod_hl_grow_child id = { <id> child = left_arrow } s = <s>
    dadmod_hl_grow_child id = { <id> child = right_arrow } s = <s>
    dadmod_hl_grow_child id = { <id> child = icon } s = <s>
endscript

script dadmod_hl_grow_child
    if ScreenElementExists id = <id>
        RunScriptOnScreenElement id = <id> dadmod_hl_grow_morph params = { s = <s> }
    endif
endscript

script dadmod_hl_grow_morph
    DoMorph time = 0.08 scale = <s> relative_scale
endscript

dadmod_layout_block_begin = "Dadmod menus built from dadmod_layout.txt (Host Manager > Dadmod Menus). Items come from dadmod_item_catalog (layout_catalog.q, generated by gen_layout.py)"

dadmod_layout_node = -1

script create_dadmod_setup_menu
    dadmod_layout_open node = 0
endscript

script dadmod_layout_back
    if THUGRECOMP_PadHeld button = "y"
        if ( ( dadmod_ui_focused ) = mmopt_spotpick )
            return
        endif
    endif
    Change dadmod_mm_armed = none
    if (<parent> < 0)
        Change dadmod_layout_node = -1
        dadmod_back_to_main
    else
        dadmod_layout_open node = <parent>
    endif
endscript

script dadmod_layout_open node = 0
    THUGRECOMP_LayoutInfo node = <node>
    Change dadmod_layout_node = <node>
    me = <node>
    hmode = 0
    has_eff = 0
    i = 0
    begin
        if (<i> = <count>)
            break
        endif
        if THUGRECOMP_LayoutChild node = <me> index = <i>
            if (<type> = 1)
                if (<hmode> = 0)
                    hmode = 1
                endif
                if ( ( <key> = "mmopt_spotpick" ) or ( <key> = "mmopt_anim" ) )
                    hmode = 2
                endif
                if (<key> = "mui_rainbow")
                    has_eff = 1
                endif
            endif
        endif
        i = ( <i> + 1 )
    repeat
    switch <hmode>
    case 1
        helper = generic_helper_text_up_down_adjust
    case 2
        helper = dadmod_mm_helper_text
    default
        helper = generic_helper_text
    endswitch
    off_page = 0
    if (<has_eff> = 1)
        dadmod_ui_get key = "ui_rainbow" def = 0 raw
        if (<value> = 0)
            off_page = 1
        endif
        if (<value> = 11)
            off_page = 2
        endif
    endif
    rows = <count>
    if ( <rows> > 13 )
        rows = 13
    endif
    if ( <rows> < 1 )
        rows = 1
    endif
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_layout
    scrolling
    num_items_to_show = <rows>
    menu_title = <title>
    menu_style = MENU_STYLE_LEFT
    helper_text = <helper>
    pad_back_script = dadmod_layout_back
    pad_back_params = { parent = <parent> }
    show_description_panel
    show_gradient
    }
    i = 0
    begin
        if (<i> = <count>)
            break
        endif
        if THUGRECOMP_LayoutChild node = <me> index = <i>
            dadmod_layout_entry <...>
        endif
        i = ( <i> + 1 )
    repeat
    dadmod_desc_panel_right
    if GotParam focus_id
        thugpro_menu_finalize focus_target = <focus_id> no_animate
    else
        thugpro_menu_finalize
    endif
    Change dadmod_mm_armed = none
endscript

script dadmod_layout_static_ok
    switch <type>
    case 1
        keys = [ "mui_rainbow" "mui_hl_style" "mui_br_color" "mui_br_speed" "mui_c_text" "mui_c_textfx" "mui_c_focus" "mui_c_focusfx" "mui_c_bar" "mui_c_barfx" "mui_c_title" "mui_c_titlefx" "mui_c_fxspeed" "mui_rb_speed" "mui_rb_angle" ]
        GetArraySize <keys>
        i = 0
        begin
            if (<i> = <array_size>)
                break
            endif
            if ( ( <keys> [ <i> ] ) = <key> )
                return static_ok = 1
            endif
            i = ( <i> + 1 )
        repeat
    case 2
        if ( ( <label> = "Your colors" ) or ( <label> = "Highlight" ) or ( <label> = "Text" ) )
            return static_ok = 1
        endif
    endswitch
    return static_ok = 0
endscript

script dadmod_layout_entry
    if (<hide> = 1)
        return
    endif
    if (<type> = 2)
        if (<label> = "Theme")
            dadmod_ui_get key = "ui_rainbow" def = 0 raw
            dadmod_ui_effect_resolve v = <value>
            if not (<v> = 9)
                return
            endif
        endif
    endif
    mmc = 0
    if (<type> = 0)
        if ( ( <label> = "Main menu colors" ) or ( <label> = "Main screen options" ) )
            mmc = 1
            dadmod_ui_get key = "ui_rainbow" def = 0 raw
            if not (<value> = 0)
                return
            endif
        endif
    endif
    if GotParam off_page
        if (<off_page> = 1)
            if (<mmc> = 0)
                if not (<type> = 1)
                    return
                endif
                if not ( ( <key> = "mui_rainbow" ) or ( <key> = "mui_hl_style" ) or ( <key> = "mui_br_color" ) or ( <key> = "mui_br_speed" ) or ( <key> = "mui_c_focus" ) )
                    return
                endif
            endif
        endif
        if (<off_page> = 2)
            dadmod_layout_static_ok type = <type> key = <key> label = <label>
            if (<static_ok> = 0)
                return
            endif
        endif
    endif
    switch <type>
    case 0
        if (<desc> = "")
            FormatText TextName = desc "Opens %s" s = <label>
        endif
        FormatText TextName = shown "%s  >" s = <label>
        make_thugpro_menu_item {
        text = <shown>
        sub_label = <label>
        description_text = <desc>
        pad_choose_script = dadmod_layout_open
        pad_choose_params = { node = <child> }
        }
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    case 1
        dadmod_layout_item name = <key> label = <label> grey = <grey>
    case 2
        make_thugpro_menu_item {
        text = <label>
        not_focusable = not_focusable
        centered
        heading_alpha = 0.55
        }
    default
        make_thugpro_menu_item {
        text = " "
        not_focusable = not_focusable
        }
    endswitch
endscript

script dadmod_layout_item
    GetArraySize dadmod_item_catalog
    j = 0
    begin
        if (<j> = <array_size>)
            return
        endif
        e = ( dadmod_item_catalog [ <j> ] )
        if ( ( <e> . name ) = <name> )
            break
        endif
        j = ( <j> + 1 )
    repeat
    p = ( <e> . p )
    if GotParam dadmod_pause
        p = ( <p> + { dadmod_pause = 1 } )
    endif
    if not (<label> = "")
        p = ( <p> + { label = <label> } )
    endif
    b = ( <e> . b )
    switch <b>
    case 0
        dadmod_mmopt_item <p>
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    case 1
        if ( ( <p> . key ) = "ui_br_color" )
            dadmod_hl_style
            if not (<hl> = 3)
                return
            endif
        endif
        if ( ( <p> . key ) = "ui_br_speed" )
            dadmod_hl_style
            if not (<hl> = 3)
                return
            endif
            dadmod_ui_get key = "ui_br_color" def = 10
            if not (<value> = 10)
                return
            endif
        endif
        dadmod_ui_should_grey key = ( <p> . key )
        if (<grey_it> = 1)
            return
        endif
        if (<grey> = 1)
            grey_it = 1
        endif
        if (<grey_it> = 1)
            p = ( <p> + { dadmod_grey = 1 } )
        endif
        dadmod_ui_item <p>
        if (<grey_it> = 1)
            dadmod_layout_grey_last
        endif
    default
        if (<label> = "")
            label = "Reset Menu UI"
        endif
        make_thugpro_menu_item {
        text = <label>
        id = mui_reset
        description_text = "Puts every Menu UI setting back to stock"
        pad_choose_script = dadmod_ui_reset
        }
        if (<grey> = 1)
            dadmod_layout_grey_last
        endif
    endswitch
endscript

script dadmod_layout_live
    if (dadmod_layout_node > -1)
        if ScreenElementExists id = desc_text_container
            dadmod_layout_open node = ( dadmod_layout_node )
        endif
    endif
endscript

script dadmod_layout_grey_last
    if GetScreenElementChildren id = current_menu
        GetArraySize <children>
        c = ( <children> [ ( <array_size> - 1 ) ] )
        SetScreenElementProps id = <c> not_focusable
        if ScreenElementExists id = { <c> child = text }
            SetScreenElementProps id = { <c> child = text } alpha = 0.4
        endif
    endif
endscript

dadmod_tod_states = [ afternoon morning afternoon evening night night night ]

dadmod_tod_requested = afternoon

dadmod_tod_custom = 0

dadmod_tod_last = -1

dadmod_tod_watch_on = 0

dadmod_tod_evening_lights = {
state_length = 140000
sun_theta = 0.0
sun_phi = 1.9e+02
sun_red = 255.0
sun_green = 110.0
sun_blue = 60.0
lev_red = 78
lev_green = 70
lev_blue = 76
sky_red = 70
sky_green = 48
sky_blue = 60
fog_on = 1
fog_red = 70
fog_green = 46
fog_blue = 52
fog_alpha = 40
fog_dist = 6000
ambient_red = 34
ambient_green = 30
ambient_blue = 38
ambient_mod_factor_lo = 0.3
ambient_mod_factor_hi = 0.0
heading_0 = 50
pitch_0 = 340
red_0 = 110
green_0 = 78
blue_0 = 52
mod_factor_0_lo = 0.6
mod_factor_0_hi = 0.0
heading_1 = 240
pitch_1 = 330
red_1 = 36
green_1 = 34
blue_1 = 52
mod_factor_1_lo = 0.3
mod_factor_1_hi = 0.0
headlights_on = 1
bloom_on = 1
bloom1 = 35
bloom2 = 45
bloom_color = [ 160 , 110 , 90 ]
entry_script = nullscript
}

dadmod_tod_night_moon = {
state_length = 140000
sun_theta = 0.0
sun_phi = 2e+02
sun_red = 0.0
sun_green = 0.0
sun_blue = 0.0
lev_red = 52
lev_green = 58
lev_blue = 78
sky_red = 14
sky_green = 20
sky_blue = 34
fog_red = 10
fog_green = 14
fog_blue = 24
fog_alpha = 30
fog_dist = 9000
ambient_red = 26
ambient_green = 30
ambient_blue = 44
ambient_mod_factor_lo = 0.3
ambient_mod_factor_hi = 0.0
heading_0 = 330
pitch_0 = 330
red_0 = 70
green_0 = 80
blue_0 = 110
mod_factor_0_lo = 0.3
mod_factor_0_hi = 0.0
heading_1 = 151
pitch_1 = 330
red_1 = 20
green_1 = 24
blue_1 = 36
mod_factor_1_lo = 0.15
mod_factor_1_hi = 0.0
headlights_on = 1
bloom_on = 1
bloom1 = 20
bloom2 = 40
bloom_color = [ 90 , 100 , 150 ]
entry_script = nullscript
}

dadmod_tod_dawn_lights = {
state_length = 140000
sun_theta = 0.0
sun_phi = -1.5e+01
sun_red = 200.0
sun_green = 120.0
sun_blue = 110.0
lev_red = 64
lev_green = 62
lev_blue = 80
sky_red = 40
sky_green = 34
sky_blue = 52
fog_red = 40
fog_green = 34
fog_blue = 46
fog_alpha = 32
fog_dist = 8000
ambient_red = 34
ambient_green = 34
ambient_blue = 50
ambient_mod_factor_lo = 0.3
ambient_mod_factor_hi = 0.0
heading_0 = 70
pitch_0 = 350
red_0 = 120
green_0 = 90
blue_0 = 100
mod_factor_0_lo = 0.35
mod_factor_0_hi = 0.0
heading_1 = 250
pitch_1 = 330
red_1 = 30
green_1 = 36
blue_1 = 56
mod_factor_1_lo = 0.15
mod_factor_1_hi = 0.0
headlights_on = 1
bloom_on = 1
bloom1 = 22
bloom2 = 40
bloom_color = [ 150 , 110 , 130 ]
entry_script = nullscript
}

script dadmod_tod_value
    value = 0
    if THUGRECOMP_SettingLoad key = "gfx_todnow"
    endif
    dadmod_tod_client_allowed
    if (<allowed> = 0)
        value = 0
    endif
    if (<value> < 0)
        value = 0
    endif
    if (<value> > 6)
        value = 0
    endif
    return tod = <value>
endscript

script thugpro_change_time_of_day
    if (dadmod_tod_upd = 1)
        <from_update> = 1
    endif
    Change dadmod_tod_requested = <tod_state>
    dadmod_tod_value
    Change dadmod_tod_last = <tod>
    custom = 0
    if (<tod> = 5)
        tod_manager_set_default_params night_params = dadmod_tod_evening_lights
        custom = 1
    endif
    if (<tod> = 4)
        tod_manager_set_default_params night_params = dadmod_tod_night_moon
        custom = 1
    endif
    if (<tod> = 6)
        tod_manager_set_default_params night_params = dadmod_tod_dawn_lights
        custom = 1
    endif
    if (<custom> = 1)
        Change dadmod_tod_custom = 1
    else
        if IsTrue dadmod_tod_custom
            tod_manager_set_default_params
            Change dadmod_tod_custom = 0
        endif
    endif
    if (<tod> > 0)
        tod_state = ( dadmod_tod_states [ <tod> ] )
    endif
    Change tod_manager_inactive = 0
    TODManager_SetActive 1
    SpawnScript thugpro_tod_level_specific_hack_before
    switch <tod_state>
    case afternoon
        Change LEVEL_TOD_STATE = afternoon
        TODManager_SetTODInstant afternoon
        set_current_tod_values tod_state = afternoon
    case night
        Change LEVEL_TOD_STATE = night
        TODManager_SetTODInstant night
        set_current_tod_values tod_state = night
    case morning
        Change LEVEL_TOD_STATE = morning
        TODManager_SetTODInstant morning
        set_current_tod_values tod_state = morning
    case evening
        Change LEVEL_TOD_STATE = evening
        TODManager_SetTODInstant evening
        set_current_tod_values tod_state = evening
    default
        Change LEVEL_TOD_STATE = afternoon
        TODManager_SetTODInstant afternoon
        set_current_tod_values tod_state = afternoon
    endswitch
    SpawnScript thugpro_tod_level_specific_hack_after
endscript

script dadmod_tod_refresh
    Change dadmod_tod_fading = 0
    if LevelIs Load_MainMenu
        return
    endif
    if not InNetGame
        THUGPRO_SetLightUpdateState unpause
    endif
    TODManager_ResetLevelLights
    thugpro_change_time_of_day tod_state = ( dadmod_tod_requested ) from_local
    if not InNetGame
        KillSpawnedScript Name = dadmod_tod_lights_settle
        SpawnScript dadmod_tod_lights_settle
    endif
endscript

script dadmod_tod_lights_settle
    wait 60 gameframes
    THUGPRO_SetLightUpdateState pause
endscript

script dadmod_tod_watch_start
    if IsTrue dadmod_tod_watch_on
        return
    endif
    dadmod_balance_apply
    Change dadmod_tod_watch_on = 1
    SpawnScript dadmod_tod_watch NotSessionSpecific = 1
    SpawnScript dadmod_balance_net_watch NotSessionSpecific = 1
    SpawnScript dadmod_mirror_watch NotSessionSpecific = 1
    dadmod_wx_watch_start
endscript

script dadmod_balance_meter_side
    arrows = [ (0.0,-17.0) (1e+01,-17.0) (2e+01,-15.0) (3e+01,-11.0) (4e+01,-6.0) (5e+01,1.0) (6e+01,12.0) ]
    info = ( balance_meter_info )
    info = ( <info> + { arrow_positions = <arrows> } )
    Change balance_meter_info = <info>
endscript

script dadmod_mirror_spin
    mir = 0
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        mir = <value>
    endif
    if (<mir> = 1)
        switch ( GLOBAL_ShoulderSpinButtons )
        case L2_R2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R2 spin_button_right = L2 shoulder_spin_enabled = 1 }
        case L1_R1
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R1 spin_button_right = L1 shoulder_spin_enabled = 1 }
        case R1_R2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = R1 spin_button_right = R2 shoulder_spin_enabled = 1 }
        case L1_L2
            THUGPRO_SetSkaterPhysicsParams { spin_button_left = L1 spin_button_right = L2 shoulder_spin_enabled = 1 }
        endswitch
    else
        thugpro_set_ShoulderSpinButtons value = ( GLOBAL_ShoulderSpinButtons )
    endif
    return mir = <mir>
endscript

script dadmod_mirror_watch
    last = -1
    lastmir = -1
    lastspin = none
    lastsk = 0
    n = 0
    lastbal = -1
    lastmm = -1
    begin
        wait 1 gameframe
        mm = 0
        if LevelIs Load_MainMenu
            mm = 1
        endif
        if not (<mm> = <lastmm>)
            THUGRECOMP_SettingSave key = "gfx_mainmenu" value = <mm>
            lastmm = <mm>
        endif
        dadmod_reorder_keys
        dadmod_prompt_tick
        dadmod_walkcam_tick
        dadmod_mouse_tick
        n = (<n> + 1)
        if (<n> > 15)
            n = 0
            sk = 0
            if ObjectExists id = skater
                sk = 1
            endif
            mir = 0
            if THUGRECOMP_SettingLoad key = "gfx_mirror"
                mir = <value>
            endif
            again = 0
            if not (<mir> = <lastmir>)
                again = 1
            endif
            if not (<sk> = <lastsk>)
                again = 1
            endif
            if not (( GLOBAL_ShoulderSpinButtons ) = <lastspin>)
                again = 1
            endif
            if (<again> = 1)
                dadmod_mirror_spin
                lastmir = <mir>
                lastsk = <sk>
                lastspin = ( GLOBAL_ShoulderSpinButtons )
            endif
            dadmod_balance_flags
        endif
        bal = 0
        if ObjectExists id = skater
            if skater : OnRail
                bal = 1
            endif
            if skater : OnLip
                bal = 1
            endif
        endif
        if not (<bal> = <lastbal>)
            THUGRECOMP_SettingSave key = "gfx_balancing" value = <bal>
            lastbal = <bal>
        endif
        up = 0
        if ScreenElementExists id = current_menu_anchor
            up = 1
        endif
        if ScreenElementExists id = current_menu
            up = 1
        endif
        if ScreenElementExists id = dialog_box_anchor
            up = 1
        endif
        if ScreenElementExists id = keyboard_anchor
            up = 1
        endif
        if ScreenElementExists id = quit_dialog_anchor
            up = 1
        endif
        if not (<up> = <last>)
            THUGRECOMP_SettingSave key = "gfx_menuup" value = <up>
            last = <up>
        endif
    repeat
endscript

script dadmod_tod_server_state
    st = 0
    if InNetGame
        TODManager_GetCurrentTODParams
        if GotParam tod_params
            if StructureContains structure = <tod_params> current_state_name
                switch ( <tod_params> . current_state_name )
                case morning
                    st = 1
                case afternoon
                    st = 2
                case evening
                    st = 3
                case night
                    st = 4
                endswitch
            endif
        endif
    endif
    THUGRECOMP_SettingSave key = "gfx_servertod" value = <st>
endscript

script dadmod_tod_watch
    begin
        wait 30 gameframes
        dadmod_tod_server_state
        GetLevelStructureName
        if StructureContains structure = ( <level_structure_name> ) level
            FormatText TextName = lk "gfx_level_%a" a = ( <level_structure_name> . level )
            THUGRECOMP_SettingSave key = <lk> value = 1
        endif
        if not LevelIs Load_MainMenu
            if ObjectExists id = skater
                dadmod_tod_kali_watch
                dadmod_tod_value
                if not (<tod> = ( dadmod_tod_last ))
                    from = ( dadmod_tod_last )
                    Change dadmod_tod_last = <tod>
                    dadmod_tod_refresh
                else
                    if IsTrue dadmod_tod_fading
                        tod = 0
                    endif
                    if (<tod> > 0)
                        if not ( ( LEVEL_TOD_STATE ) = ( dadmod_tod_states [ <tod> ] ) )
                            dadmod_tod_refresh
                        endif
                    endif
                endif
            endif
        endif
    repeat
endscript

dadmod_tod_fading = 0

script dadmod_tod_lerp
    u = ( 1.0 - <t> )
    p = <b>
    if StructureContains structure = <a> sun_theta
        if StructureContains structure = <b> sun_theta
            v = ( ( ( <a> . sun_theta ) * <u> ) + ( ( <b> . sun_theta ) * <t> ) )
            p = { <p> sun_theta = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_phi
        if StructureContains structure = <b> sun_phi
            pa = ( <a> . sun_phi )
            pb = ( <b> . sun_phi )
            if ( ( <pb> - <pa> ) > 180 )
                pa = ( <pa> + 360 )
            endif
            if ( ( <pa> - <pb> ) > 180 )
                pb = ( <pb> + 360 )
            endif
            v = ( ( <pa> * <u> ) + ( <pb> * <t> ) )
            p = { <p> sun_phi = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_red
        if StructureContains structure = <b> sun_red
            v = ( ( ( <a> . sun_red ) * <u> ) + ( ( <b> . sun_red ) * <t> ) )
            p = { <p> sun_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_green
        if StructureContains structure = <b> sun_green
            v = ( ( ( <a> . sun_green ) * <u> ) + ( ( <b> . sun_green ) * <t> ) )
            p = { <p> sun_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sun_blue
        if StructureContains structure = <b> sun_blue
            v = ( ( ( <a> . sun_blue ) * <u> ) + ( ( <b> . sun_blue ) * <t> ) )
            p = { <p> sun_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_lo
        if StructureContains structure = <b> ambient_mod_factor_lo
            v = ( ( ( <a> . ambient_mod_factor_lo ) * <u> ) + ( ( <b> . ambient_mod_factor_lo ) * <t> ) )
            p = { <p> ambient_mod_factor_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_mod_factor_hi
        if StructureContains structure = <b> ambient_mod_factor_hi
            v = ( ( ( <a> . ambient_mod_factor_hi ) * <u> ) + ( ( <b> . ambient_mod_factor_hi ) * <t> ) )
            p = { <p> ambient_mod_factor_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_lo
        if StructureContains structure = <b> mod_factor_0_lo
            v = ( ( ( <a> . mod_factor_0_lo ) * <u> ) + ( ( <b> . mod_factor_0_lo ) * <t> ) )
            p = { <p> mod_factor_0_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_0_hi
        if StructureContains structure = <b> mod_factor_0_hi
            v = ( ( ( <a> . mod_factor_0_hi ) * <u> ) + ( ( <b> . mod_factor_0_hi ) * <t> ) )
            p = { <p> mod_factor_0_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_lo
        if StructureContains structure = <b> mod_factor_1_lo
            v = ( ( ( <a> . mod_factor_1_lo ) * <u> ) + ( ( <b> . mod_factor_1_lo ) * <t> ) )
            p = { <p> mod_factor_1_lo = <v> }
        endif
    endif
    if StructureContains structure = <a> mod_factor_1_hi
        if StructureContains structure = <b> mod_factor_1_hi
            v = ( ( ( <a> . mod_factor_1_hi ) * <u> ) + ( ( <b> . mod_factor_1_hi ) * <t> ) )
            p = { <p> mod_factor_1_hi = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_red
        if StructureContains structure = <b> lev_red
            v = ( ( ( <a> . lev_red ) * <u> ) + ( ( <b> . lev_red ) * <t> ) )
            CastToInteger v
            p = { <p> lev_red = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_green
        if StructureContains structure = <b> lev_green
            v = ( ( ( <a> . lev_green ) * <u> ) + ( ( <b> . lev_green ) * <t> ) )
            CastToInteger v
            p = { <p> lev_green = <v> }
        endif
    endif
    if StructureContains structure = <a> lev_blue
        if StructureContains structure = <b> lev_blue
            v = ( ( ( <a> . lev_blue ) * <u> ) + ( ( <b> . lev_blue ) * <t> ) )
            CastToInteger v
            p = { <p> lev_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_red
        if StructureContains structure = <b> sky_red
            v = ( ( ( <a> . sky_red ) * <u> ) + ( ( <b> . sky_red ) * <t> ) )
            CastToInteger v
            p = { <p> sky_red = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_green
        if StructureContains structure = <b> sky_green
            v = ( ( ( <a> . sky_green ) * <u> ) + ( ( <b> . sky_green ) * <t> ) )
            CastToInteger v
            p = { <p> sky_green = <v> }
        endif
    endif
    if StructureContains structure = <a> sky_blue
        if StructureContains structure = <b> sky_blue
            v = ( ( ( <a> . sky_blue ) * <u> ) + ( ( <b> . sky_blue ) * <t> ) )
            CastToInteger v
            p = { <p> sky_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_red
        if StructureContains structure = <b> fog_red
            v = ( ( ( <a> . fog_red ) * <u> ) + ( ( <b> . fog_red ) * <t> ) )
            CastToInteger v
            p = { <p> fog_red = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_green
        if StructureContains structure = <b> fog_green
            v = ( ( ( <a> . fog_green ) * <u> ) + ( ( <b> . fog_green ) * <t> ) )
            CastToInteger v
            p = { <p> fog_green = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_blue
        if StructureContains structure = <b> fog_blue
            v = ( ( ( <a> . fog_blue ) * <u> ) + ( ( <b> . fog_blue ) * <t> ) )
            CastToInteger v
            p = { <p> fog_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_alpha
        if StructureContains structure = <b> fog_alpha
            v = ( ( ( <a> . fog_alpha ) * <u> ) + ( ( <b> . fog_alpha ) * <t> ) )
            CastToInteger v
            p = { <p> fog_alpha = <v> }
        endif
    endif
    if StructureContains structure = <a> fog_dist
        if StructureContains structure = <b> fog_dist
            v = ( ( ( <a> . fog_dist ) * <u> ) + ( ( <b> . fog_dist ) * <t> ) )
            CastToInteger v
            p = { <p> fog_dist = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_red
        if StructureContains structure = <b> ambient_red
            v = ( ( ( <a> . ambient_red ) * <u> ) + ( ( <b> . ambient_red ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_red = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_green
        if StructureContains structure = <b> ambient_green
            v = ( ( ( <a> . ambient_green ) * <u> ) + ( ( <b> . ambient_green ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_green = <v> }
        endif
    endif
    if StructureContains structure = <a> ambient_blue
        if StructureContains structure = <b> ambient_blue
            v = ( ( ( <a> . ambient_blue ) * <u> ) + ( ( <b> . ambient_blue ) * <t> ) )
            CastToInteger v
            p = { <p> ambient_blue = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_0
        if StructureContains structure = <b> heading_0
            v = ( ( ( <a> . heading_0 ) * <u> ) + ( ( <b> . heading_0 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_0
        if StructureContains structure = <b> pitch_0
            v = ( ( ( <a> . pitch_0 ) * <u> ) + ( ( <b> . pitch_0 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_0
        if StructureContains structure = <b> red_0
            v = ( ( ( <a> . red_0 ) * <u> ) + ( ( <b> . red_0 ) * <t> ) )
            CastToInteger v
            p = { <p> red_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_0
        if StructureContains structure = <b> green_0
            v = ( ( ( <a> . green_0 ) * <u> ) + ( ( <b> . green_0 ) * <t> ) )
            CastToInteger v
            p = { <p> green_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_0
        if StructureContains structure = <b> blue_0
            v = ( ( ( <a> . blue_0 ) * <u> ) + ( ( <b> . blue_0 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_0 = <v> }
        endif
    endif
    if StructureContains structure = <a> heading_1
        if StructureContains structure = <b> heading_1
            v = ( ( ( <a> . heading_1 ) * <u> ) + ( ( <b> . heading_1 ) * <t> ) )
            CastToInteger v
            p = { <p> heading_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> pitch_1
        if StructureContains structure = <b> pitch_1
            v = ( ( ( <a> . pitch_1 ) * <u> ) + ( ( <b> . pitch_1 ) * <t> ) )
            CastToInteger v
            p = { <p> pitch_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> red_1
        if StructureContains structure = <b> red_1
            v = ( ( ( <a> . red_1 ) * <u> ) + ( ( <b> . red_1 ) * <t> ) )
            CastToInteger v
            p = { <p> red_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> green_1
        if StructureContains structure = <b> green_1
            v = ( ( ( <a> . green_1 ) * <u> ) + ( ( <b> . green_1 ) * <t> ) )
            CastToInteger v
            p = { <p> green_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> blue_1
        if StructureContains structure = <b> blue_1
            v = ( ( ( <a> . blue_1 ) * <u> ) + ( ( <b> . blue_1 ) * <t> ) )
            CastToInteger v
            p = { <p> blue_1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom1
        if StructureContains structure = <b> bloom1
            v = ( ( ( <a> . bloom1 ) * <u> ) + ( ( <b> . bloom1 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom1 = <v> }
        endif
    endif
    if StructureContains structure = <a> bloom2
        if StructureContains structure = <b> bloom2
            v = ( ( ( <a> . bloom2 ) * <u> ) + ( ( <b> . bloom2 ) * <t> ) )
            CastToInteger v
            p = { <p> bloom2 = <v> }
        endif
    endif
    return p = <p>
endscript

script dadmod_tod_phase_params
    GetLevelStructureName
    switch <phase>
    case 1
        FormatText ChecksumName = n "%a_tod_morning_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_morning
        state = morning
    case 3
        FormatText ChecksumName = n "%a_tod_evening_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_evening
        state = evening
    case 4
        n = dadmod_tod_night_moon
        params = dadmod_tod_night_moon
        state = night
    case 5
        n = dadmod_tod_evening_lights
        params = dadmod_tod_evening_lights
        state = night
    case 6
        n = dadmod_tod_dawn_lights
        params = dadmod_tod_dawn_lights
        state = night
    default
        FormatText ChecksumName = n "%a_tod_afternoon_params" a = ( <level_structure_name> . level )
        params = tod_manager_default_afternoon
        state = afternoon
    endswitch
    if GlobalExists Name = <n> Type = structure
        params = ( <n> )
    else
        params = ( <params> )
    endif
    return params = <params> state = <state>
endscript

script dadmod_tod_fade
    Change dadmod_tod_fading = 1
    dadmod_tod_phase_params phase = <from>
    a = <params>
    sa = <state>
    dadmod_tod_phase_params phase = <to>
    b = <params>
    sb = <state>
    st = <sb>
    if (<sa> = night)
        st = night
    endif
    if not InNetGame
        THUGPRO_SetLightUpdateState unpause
    endif
    Change tod_manager_inactive = 0
    TODManager_SetActive 1
    i = 1
    begin
        if (<i> > 24)
            break
        endif
        t = ( <i> / 24.0 )
        dadmod_tod_lerp a = <a> b = <b> t = <t>
        switch <st>
        case morning
            tod_manager_set_default_params morning_params = <p>
        case evening
            tod_manager_set_default_params evening_params = <p>
        case night
            tod_manager_set_default_params night_params = <p>
        default
            tod_manager_set_default_params afternoon_params = <p>
        endswitch
        Change LEVEL_TOD_STATE = <st>
        TODManager_SetTODInstant <st>
        wait 20 gameframes
        if not IsTrue dadmod_tod_fading
            return
        endif
        if LevelIs Load_MainMenu
            Change dadmod_tod_fading = 0
            return
        endif
        i = ( <i> + 1 )
    repeat
    Change dadmod_tod_custom = 1
    Change dadmod_tod_fading = 0
    dadmod_tod_refresh
endscript

script dadmod_mirror_l2
    mir = 0
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        mir = <value>
    endif
    l2 = 0
    if GotParam spin_with_L2
        l2 = 1
    endif
    if (<mir> = 1)
        l2 = (1 - <l2>)
    endif
    return l2 = <l2>
endscript

script SwitchFootPogo_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Switch Foot Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = TruckRun
        OutAnim = Truckrun_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = SwitchFootPogo_Branches
        parent = 'Switch Foot Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script CasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Casper Spin'
        score = 100
        RotateY
        BalanceAnim = Casper_Range
        OutAnim = Casper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = CasperBranches
        parent = 'Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        }
    endif
endscript

script AntiCasperSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Anti Casper Spin'
        score = 100
        RotateY
        BalanceAnim = AntiCasper_Range
        OutAnim = AntiCasper_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = AntiCasperBranches
        parent = 'Anti Casper'
        Trickslack = 0
        BoardRotate = 1
        IsExtra
        Nollie
        }
    endif
endscript

script TruckSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'TruckSpin'
        score = 100
        RotateY
        BalanceAnim = Truckstand_Range
        OutAnim = Truckstand_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = TruckstandBranches
        parent = 'TruckStand'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script PogoSpin_Setup
    dadmod_mirror_l2 <...>
    if (<l2> = 1)
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        spin_with_L2 = 1
        }
    else
        manuallink {
        Name = 'Pogo Spin'
        score = 100
        RotateY
        BalanceIdle = Pogo_Bounce
        BoardRotate = 1
        OutAnim = Pogo_Out
        ExtraTricks = FlatlandBranches
        ExtraTricks2 = PogoBranches
        parent = 'Pogo'
        Trickslack = 0
        IsExtra
        }
    endif
endscript

script revert
    if not GotParam FSName
        FSName = 'FS Revert'
    endif
    if not GotParam BSName
        BSName = 'BS Revert'
    endif
    if not GotParam FSAnim
        FSAnim = RevertFS
    endif
    if not GotParam BSAnim
        BSAnim = RevertBS
    endif
    if IsSkaterOnVehicle
        goto vehicle_revert
    endif
    if IsOnMotoSkateboard
        FSAnim = RevertFS
        BSAnim = RevertBS
    endif
    if THUGRECOMP_SettingLoad key = "gfx_mirror"
        if (<value> = 1)
            a = <FSAnim>
            FSAnim = <BSAnim>
            BSAnim = <a>
        endif
    endif
    dadmod_bhra_revert_check
    OnExitRun ExitRevert
    InRevert
    ClearLipCombos
    KillExtraTricks
    SetTrickScore 100
    OnGroundExceptions NoEndRun
    LaunchStateChangeEvent state = Skater_InRevert
    ClearException Ollied
    if not GetGlobalFlag flag = SERVER_CHEAT_NO_REVERT_SPEED_LOSS
        SetSpecialFriction [ 0 , 0 , 5 , 10 , 15 , 25 ] duration = 0.667
    endif
    CanKickOff
    SetQueueTricks SkateToWalkTricks
    NollieOff
    PressureOff
    if GotParam LandPivot
        GetBoardTypeAndRevert Type = manuallink
        PlayAnim anim = GTurn
        if InAir
            SetTrickName 'Bunny Hop Revert'
        else
            SetTrickName 'Land Pivot'
        endif
        Obj_SetFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        GetBoardTypeAndRevert Type = revert
        if InAir
            FSName = 'Bunny Hop Revert'
            BSName = 'Bunny Hop Revert'
        endif
        if Obj_FlagSet FLAG_SKATER_REVERTFS
            Obj_ClearFlag FLAG_SKATER_REVERTFS
            PlayAnim anim = <FSAnim>
            SetTrickName <FSName>
        else
            if Obj_FlagSet FLAG_SKATER_REVERTBS
                Obj_ClearFlag FLAG_SKATER_REVERTBS
                PlayAnim anim = <BSAnim>
                SetTrickName <BSName>
            else
                if LastSpinWas Frontside
                    PlayAnim anim = <FSAnim>
                    SetTrickName <FSName>
                else
                    PlayAnim anim = <BSAnim>
                    SetTrickName <BSName>
                endif
            endif
        endif
    endif
    SetSkaterAirManualTricks
    Display Blockspin
    if not IsOnMotoSkateboard
        FlipAfter
        BoardRotateAfter
    endif
    wait 0.1 seconds
    SetException ex = Ollied scr = Ollie
    if not GotParam LandPivot
        ResetLandedFromVert
    endif
    if GotParam bhra_pv
        if GotParam LandPivot
            WaitAnim 100 Percent
        else
            WaitAnim 60 Percent
        endif
    else
        WaitAnim 100 Percent
    endif
    CanKickOn
    if GotParam bhra_air
        if not GotParam LandPivot
            if not GotParam bhra_pv
                if InAir
                    InAirExceptions
                    goto Airborne
                endif
                begin
                    DoNextManualTrick FromAir
                    wait 1 gameframe
                repeat 10
            endif
        endif
    endif
    if GotParam LandPivot
        PlayAnim anim = Manual_Range From = middle BlendPeriod = 0.0
        DoNextManualTrick SkipInitAnim LandPivotManual
    else
        DoNextManualTrick FromAir
    endif
    DoNextTrick
    OnGroundExceptions
    if GotParam bhra_air
        if GotParam LandPivot
            goto dadmod_bhra_pivot_land
        endif
        if GotParam bhra_pv
            goto dadmod_bhra_pivot_land params = { revert_style = 1 }
        endif
    endif
    LandSkaterTricks
    ClearEventBuffer
    if GotParam LandPivot
        PlayAnim anim = PutDownManual BlendPeriod = 0.3 speed = 2.5
        Obj_ClearFlag FLAG_SKATER_IN_LAND_PIVOT
    else
        if not Held x
            PlayAnim anim = CrouchIdleToIdle BlendPeriod = 0.0 speed = 0.7
        else
            PlayAnim anim = CrouchIdle BlendPeriod = 0.0 From = 0 To = 0.3 seconds
            BlendPeriodOut 0.3
        endif
    endif
    WaitAnimWhilstChecking AndManuals
    goto OnGroundAi
endscript

dadmod_added_levels = [ #"0x001202e3" #"0x341caf9f" #"0x6552c592" #"0xe0d4e51a" #"0xf06d95da" #"0x73babdd0" #"0x16a10a9a" #"0x1a69989e" #"0x896a81b2" #"0x27eeac8d" #"0x2843fdc8" Load_dadmod_THPGFDR Load_dadmod_THPGLove Load_dadmod_THPGSlums Load_dadmod_THPGBCity Load_dadmod_THPGHarbor Load_dadmod_THPGLansdowne Load_dadmod_THPGMonuments Load_dadmod_THPGMuseums Load_dadmod_THPGMuseumInt Load_dadmod_THPGPhilly Load_dadmod_THPGWashington Load_dadmod_THPGTraining Load_dadmod_THPGLarxPhilly Load_dadmod_THPGLarxBaltimore Load_dadmod_THPGLarxWashington ]

dadmod_added_level_creators = [ "tyler.thpsX" "letmynutzgo" "letmynutzgo" "letmynutzgo" "rodafy" "letmynutzgo" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Neversoft" "Larxian" "Larxian" "Larxian" ]

script dadmod_added_level_creator
    GetArraySize dadmod_added_levels
    <i> = 0
    begin
        if ( ( dadmod_added_levels [ <i> ] ) = <level> )
            return creator = ( dadmod_added_level_creators [ <i> ] )
        endif
        <i> = ( <i> + 1 )
    repeat <array_size>
endscript

Level_dadmod_Streets = {
game = THPS1
structure_name = Level_dadmod_Streets
load_script = #"0x001202e3"
Name = "Streets"
loading_time = 8.5
level = "Streets"
sky = "Streets_Sky"
wallride_hack
qb = "levels\\Streets\\Streets.qb"
level_qb = "levels\\Streets\\Streets_scripts.qb"
more_level_qbs = [
"levels\\Streets\\Streets_thugpro.qb"
]
pre = "Streets_scripts.pre"
scnpre = "Streetsscn.pre"
colpre = "Streetscol.pre"
default_level_stuff
}

script #"0x001202e3"
    load_level Level_dadmod_Streets
endscript

Level_dadmod_THPS2NY = {
game = THPS2
structure_name = Level_dadmod_THPS2NY
load_script = #"0x341caf9f"
Name = "New York City"
loading_time = 8.5
level = "THPS2NY"
sky = "THPS2NY_Sky"
nosun
wallride_hack
qb = "levels\\THPS2NY\\THPS2NY.qb"
level_qb = "levels\\THPS2NY\\THPS2NY_scripts.qb"
more_level_qbs = [
"levels\\THPS2NY\\THPS2NY_thugpro.qb"
]
pre = "THPS2NY_scripts.pre"
scnpre = "THPS2NYscn.pre"
colpre = "THPS2NYcol.pre"
default_level_stuff
}

script #"0x341caf9f"
    load_level Level_dadmod_THPS2NY
endscript

Level_dadmod_THPS2SS = {
game = THPS2
structure_name = Level_dadmod_THPS2SS
load_script = #"0x6552c592"
Name = "Skatestreet"
loading_time = 8.5
level = "THPS2SS"
sky = "default_sky"
indoor
nosun
wallride_hack
qb = "levels\\THPS2SS\\THPS2SS.qb"
level_qb = "levels\\THPS2SS\\THPS2SS_scripts.qb"
more_level_qbs = [
"levels\\THPS2SS\\THPS2SS_thugpro.qb"
]
pre = "THPS2SS_scripts.pre"
scnpre = "THPS2SSscn.pre"
colpre = "THPS2SScol.pre"
default_level_stuff
}

script #"0x6552c592"
    load_level Level_dadmod_THPS2SS
endscript

Level_dadmod_THPS2Bullring = {
game = THPS2
structure_name = Level_dadmod_THPS2Bullring
load_script = #"0xe0d4e51a"
Name = "Bullring"
loading_time = 8.5
level = "THPS2Bullring"
sky = "THPS2Bullring_Sky"
nosun
wallride_hack
qb = "levels\\THPS2Bullring\\THPS2Bullring.qb"
level_qb = "levels\\THPS2Bullring\\THPS2Bullring_scripts.qb"
more_level_qbs = [
"levels\\THPS2Bullring\\THPS2Bullring_thugpro.qb"
]
pre = "THPS2Bullring_scripts.pre"
scnpre = "THPS2Bullringscn.pre"
colpre = "THPS2Bullringcol.pre"
default_level_stuff
}

script #"0xe0d4e51a"
    load_level Level_dadmod_THPS2Bullring
endscript

Level_dadmod_THPS2_SH = {
game = THPS2
structure_name = Level_dadmod_THPS2_SH
load_script = #"0xf06d95da"
Name = "Skate Heaven"
loading_time = 8.5
level = "THPS2_SH"
sky = "default_sky"
nosun
qb = "levels\\THPS2_SH\\THPS2_SH.qb"
level_qb = "levels\\THPS2_SH\\THPS2_SH_scripts.qb"
more_level_qbs = [
"levels\\THPS2_SH\\THPS2_SH_thugpro.qb"
]
pre = "THPS2_SH_scripts.pre"
scnpre = "THPS2_SHscn.pre"
colpre = "THPS2_SHcol.pre"
default_level_stuff
}

script #"0xf06d95da"
    load_level Level_dadmod_THPS2_SH
endscript

Level_dadmod_THPS2ChopperDrop = {
game = THPS2
structure_name = Level_dadmod_THPS2ChopperDrop
load_script = #"0x73babdd0"
Name = "Chopper Drop"
loading_time = 8.5
level = "THPS2ChopperDrop"
sky = "THPS2ChopperDrop_Sky"
nosun
wallride_hack
qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop.qb"
level_qb = "levels\\THPS2ChopperDrop\\THPS2ChopperDrop_scripts.qb"
more_level_qbs = [
"levels\\THPS2ChopperDrop\\THPS2ChopperDrop_thugpro.qb"
]
pre = "THPS2ChopperDrop_scripts.pre"
scnpre = "THPS2ChopperDropscn.pre"
colpre = "THPS2ChopperDropcol.pre"
default_level_stuff
}

script #"0x73babdd0"
    load_level Level_dadmod_THPS2ChopperDrop
endscript

Level_dadmod_P8Training = {
game = THP8
structure_name = Level_dadmod_P8Training
load_script = #"0x1a69989e"
Name = "Training"
loading_time = 8.5
level = "P8Training"
sky = "P8Training_Sky"
qb = "levels\\P8Training\\P8Training.qb"
level_qb = "levels\\P8Training\\P8Training_scripts.qb"
more_level_qbs = [
"levels\\P8Training\\P8Training_thugpro.qb"
]
pre = "P8Training_scripts.pre"
scnpre = "P8Trainingscn.pre"
colpre = "P8Trainingcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
overview_cam_pos = (-698.3,4416.4,795.5)
overview_cam_angle = 0
}

script #"0x1a69989e"
    load_level Level_dadmod_P8Training
endscript

Level_dadmod_P8Suburbs = {
game = THP8
structure_name = Level_dadmod_P8Suburbs
load_script = #"0x16a10a9a"
Name = "Suburbs"
loading_time = 8.5
level = "P8Suburbs"
sky = "P8Suburbs_Sky"
qb = "levels\\P8Suburbs\\P8Suburbs.qb"
level_qb = "levels\\P8Suburbs\\P8Suburbs_scripts.qb"
more_level_qbs = [
"levels\\P8Suburbs\\P8Suburbs_thugpro.qb"
]
pre = "P8Suburbs_scripts.pre"
scnpre = "P8Suburbsscn.pre"
colpre = "P8Suburbscol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Suburbs_goals
overview_cam_pos = (-2032.6,4565.6,-2302.5)
overview_cam_angle = 0
}

script #"0x16a10a9a"
    load_level Level_dadmod_P8Suburbs
endscript

Level_dadmod_P8Downtown = {
game = THP8
structure_name = Level_dadmod_P8Downtown
load_script = #"0x896a81b2"
Name = "Downtown"
loading_time = 8.5
level = "P8Downtown"
sky = "P8Downtown_Sky"
qb = "levels\\P8Downtown\\P8Downtown.qb"
level_qb = "levels\\P8Downtown\\P8Downtown_scripts.qb"
more_level_qbs = [
"levels\\P8Downtown\\P8Downtown_thugpro.qb"
]
pre = "P8Downtown_scripts.pre"
scnpre = "P8Downtownscn.pre"
colpre = "P8Downtowncol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8Downtown_goals
overview_cam_pos = (2920.1,5821.6,-1341.0)
overview_cam_angle = 0
}

script #"0x896a81b2"
    load_level Level_dadmod_P8Downtown
endscript

Level_dadmod_P8CarFactory = {
game = THP8
structure_name = Level_dadmod_P8CarFactory
load_script = #"0x27eeac8d"
Name = "Car Factory"
loading_time = 8.5
level = "P8CarFactory"
sky = "P8CarFactory_Sky"
qb = "levels\\P8CarFactory\\P8CarFactory.qb"
level_qb = "levels\\P8CarFactory\\P8CarFactory_scripts.qb"
more_level_qbs = [
"levels\\P8CarFactory\\P8CarFactory_thugpro.qb"
]
pre = "P8CarFactory_scripts.pre"
scnpre = "P8CarFactoryscn.pre"
colpre = "P8CarFactorycol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CarFactory_goals
overview_cam_pos = (-2428.3,6098.0,3137.1)
overview_cam_angle = 0
}

script #"0x27eeac8d"
    load_level Level_dadmod_P8CarFactory
endscript

Level_dadmod_P8CretePark = {
game = THP8
structure_name = Level_dadmod_P8CretePark
load_script = #"0x2843fdc8"
Name = "Crete Park"
loading_time = 8.5
level = "P8CretePark"
sky = "P8CretePark_Sky"
qb = "levels\\P8CretePark\\P8CretePark.qb"
level_qb = "levels\\P8CretePark\\P8CretePark_scripts.qb"
more_level_qbs = [
"levels\\P8CretePark\\P8CretePark_thugpro.qb"
]
pre = "P8CretePark_scripts.pre"
scnpre = "P8CreteParkscn.pre"
colpre = "P8CreteParkcol.pre"
default_level_stuff
DisableGoalEditor
DisableGoalAttack
HasClassicGoals
goals_script = P8CretePark_goals
overview_cam_pos = (-7389.1,6911.9,-2279.5)
overview_cam_angle = 0
}

script #"0x2843fdc8"
    load_level Level_dadmod_P8CretePark
endscript

script create_thugpro_level_menu_item {
    pad_choose_script = level_select_valid_choice
    }
    if GotParam hidden
        return
    endif
    if GotParam level
        FormatText ChecksumName = id "menu_%a" a = <level>
    endif
    if not ScriptExists <level>
        focusable = not_focusable
        exclude = 1
    endif
    if GotParam level
        if InNetGame
            if ArrayContains array = dadmod_added_levels contains = <level>
                if ScriptExists dadmod_level_online_ok
                    dadmod_level_online_ok level = <level>
                endif
                if not GotParam ok
                    focusable = not_focusable
                    exclude = 1
                endif
            endif
        endif
    endif
    if LevelIs Load_MainMenu
        if ( in_server_options = 1 )
            level_callback_script = THUGPRO_LevelSelect_menu_exit
        else
            level_callback_script = level_select_change_level
        endif
    else
        level_callback_script = level_select_change_level
    endif
    if GotParam online_level
        pad_choose_params = { <...> level = <online_level> }
    else
        pad_choose_params = <...>
    endif
    if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
        GetIndexOfItemContaining { array = level_select_menu_level_info index = 0 Name = level value = <level> }
        if ( ( ( level_select_menu_level_info [ <index> ] ) . enabled ) = 1 )
            <checked> = checked
        else
            <checked> = unchecked
        endif
        <make_menu_item_script> = make_thugpro_menu_checkbox_item
        pad_option_script = level_select_valid_choice
        pad_option_params = { <...> }
    else
        pad_option_script = nullscript
        pad_option_params = { }
        <make_menu_item_script> = make_thugpro_menu_item
    endif
    if GotParam is_custompark
        current_menu_anchor : GetSingleTag custom_park_menu_index
        FormatText TextName = text <filename>
        FormatText ChecksumName = id "menu_custom_park_%i" i = <custom_park_menu_index>
        current_menu_anchor : SetTags custom_park_menu_index = ( <custom_park_menu_index> + 1 )
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = created_park_launch
            pad_option_script = level_select_valid_choice
            pad_option_params = { <...> }
        else
            level_callback_script = created_park_launch
            pad_choose_script = level_select_valid_choice
            pad_choose_params = { <...> }
        endif
    endif
    if GotParam is_premadepark
        FormatText TextName = text <Name>
        FormatText ChecksumName = id "menu_%s" s = <Name>
        RemoveParameter level_callback_script
        RemoveParameter pad_choose_script
        RemoveParameter pad_choose_params
        RemoveParameter pad_option_script
        RemoveParameter pad_option_params
        RemoveParameter focusable
        if GetGlobalFlag flag = FLAG_AUTO_LEVEL_MODE
            pad_choose_script = generic_menu_buzzer_sound
            pad_choose_params = { }
            <checked> = unchecked
            level_callback_script = maybe_load_premade_park
            pad_option_script = maybe_load_premade_park
            pad_option_params = { slot = <slot> }
        else
            level_callback_script = maybe_load_premade_park
            pad_choose_script = maybe_load_premade_park
            pad_choose_params = { slot = <slot> }
        endif
    endif
    if not GotParam creator
        if GotParam level
            dadmod_added_level_creator level = <level>
        endif
    endif
    if GotParam level
        if ScriptExists dadmod_levelthumb_for
            dadmod_levelthumb_for level = <level>
        endif
    endif
    <make_menu_item_script> {
    text = <text>
    extra_text = <creator>
    dadmod_nofit = 1
    id = <id>
    unfocus_script = thugpro_level_select_item_unfocus
    focus_script = thugpro_level_select_item_focus
    focus_params = { level = <level> text = <text> texture = <level_thumb> }
    pad_choose_script = <pad_choose_script>
    pad_choose_params = <pad_choose_params>
    pad_option_script = <pad_option_script>
    pad_option_params = <pad_option_params>
    <focusable>
    <checked>
    }
    if GotParam id
        if ScreenElementExists id = <id>
            <id> : SetTags dadmod_nofit = 1
        endif
    endif
endscript

dadmod_levelthumbs_booted = 0

script dadmod_levelthumbs_boot
    if ( dadmod_levelthumbs_booted = 1 )
        return
    endif
    Change dadmod_levelthumbs_booted = 1
    if ScriptExists dadmod_levelthumbs_load
        dadmod_levelthumbs_load
    endif
endscript

script Load_MainMenu
    Load_MainMenu_scene
    KillSpawnedScript Name = dadmod_menu_watch
    SpawnScript dadmod_menu_watch
    dadmod_noclip_boot
    dadmod_speed_boot
    dadmod_levelthumbs_boot
    dadmod_cars_boot
endscript

script Load_MainMenu_scene
    level = 1
    THUGRECOMP_MenuLevel
    THUGRECOMP_MenuOpt key = "ambient_level" step = 0 index = <level>
    if GotParam live_level
        if GlobalExists Name = <live_level> Type = structure
            Change thugpro_mainmenu_east_la = 1
            load_level <live_level>
            return
        endif
    endif
    if (<level> = 0)
        Change thugpro_mainmenu_east_la = 0
        load_level level_Mainmenu
        return
    endif
    Change thugpro_mainmenu_east_la = 1
    switch <level>
    case 2
        load_level level_Mainmenu_toystory_bedroom
    case 3
        load_level level_Mainmenu_tr
    case 4
        load_level level_Mainmenu_bo
    case 5
        load_level level_Mainmenu_ba
    case 6
        load_level level_Mainmenu_be
    case 7
        load_level level_Mainmenu_au
    case 8
        load_level level_Mainmenu_no
    case 9
        load_level level_Mainmenu_st
    case 10
        load_level level_Mainmenu_se
    case 11
        load_level level_Mainmenu_se2
    case 12
        load_level level_Mainmenu_la
    case 13
        load_level level_Mainmenu_sc
    case 14
        load_level level_Mainmenu_hn
    case 15
        load_level level_Mainmenu_vn
    case 16
        load_level level_Mainmenu_sc2
    case 17
        load_level level_Mainmenu_ph
    case 18
        load_level level_Mainmenu_dj
    case 19
        load_level level_Mainmenu_ca
    case 20
        load_level level_Mainmenu_ap
    case 21
        load_level level_Mainmenu_nj
    case 22
        load_level level_Mainmenu_ny
    case 23
        load_level level_Mainmenu_fl
    case 24
        load_level level_Mainmenu_sd
    case 25
        load_level level_Mainmenu_hi
    case 26
        load_level level_Mainmenu_vc
    case 27
        load_level level_Mainmenu_sj
    case 28
        load_level level_Mainmenu_ru
    case 29
        load_level level_Mainmenu_hh
    case 30
        load_level level_Mainmenu_practice
    case 31
        load_level level_Mainmenu_sch
    case 32
        load_level level_Mainmenu_alc
    case 33
        load_level level_Mainmenu_sf2
    case 34
        load_level level_Mainmenu_kon
    case 35
        load_level level_Mainmenu_lon
    case 36
        load_level level_Mainmenu_jnk
    case 37
        load_level level_Mainmenu_zoo
    case 38
        load_level level_Mainmenu_cnv
    case 39
        load_level level_Mainmenu_hof
    case 40
        load_level level_Mainmenu_vans
    case 41
        load_level level_Mainmenu_skatepark
    case 42
        load_level level_Mainmenu_sz
    case 43
        load_level level_Mainmenu_atlanta
    case 44
        load_level level_Mainmenu_kyoto
    case 45
        load_level level_Mainmenu_hisch
    case 46
        load_level level_Mainmenu_z_funpark
    case 47
        load_level level_Mainmenu_z_center
    case 48
        load_level level_Mainmenu_z_riod
    case 49
        load_level level_Mainmenu_z_sm
    case 50
        load_level level_Mainmenu_z_bh
    case 51
        load_level level_Mainmenu_z_sv2
    case 52
        load_level level_Mainmenu_z_sr
    case 53
        load_level level_Mainmenu_z_dt
    case 54
        load_level level_Mainmenu_z_ho
    case 55
        load_level level_Mainmenu_z_lv
    case 56
        load_level level_Mainmenu_z_oi
    case 57
        load_level level_Mainmenu_foun
    case 58
        load_level level_Mainmenu_rio
    case 59
        load_level level_Mainmenu_sub
    case 60
        load_level level_Mainmenu_tok
    case 61
        load_level level_Mainmenu_shp
    case 62
        load_level level_Mainmenu_si
    case 63
        load_level level_Mainmenu_oil
    case 64
        load_level level_Mainmenu_ware
    case 65
        load_level level_Mainmenu_z_ma
    case 66
        load_level level_Mainmenu_z_dn
    case 67
        load_level level_Mainmenu_burn
    case 68
        load_level level_Mainmenu_ros
    case 69
        load_level level_Mainmenu_z_ms
    case 70
        load_level level_Mainmenu_streets
    case 71
        load_level level_Mainmenu_thps2ny
    case 72
        load_level level_Mainmenu_thps2ss
    case 73
        load_level level_Mainmenu_thps2bullring
    case 74
        load_level level_Mainmenu_thps2_sh
    case 75
        load_level level_Mainmenu_thps2chopperdrop
    case 76
        load_level level_Mainmenu_p8training
    case 77
        load_level level_Mainmenu_p8suburbs
    case 78
        load_level level_Mainmenu_p8downtown
    case 79
        load_level level_Mainmenu_p8carfactory
    case 80
        load_level level_Mainmenu_p8cretepark
    case 81
        load_level level_Mainmenu_thpgtraining
    default
        load_level level_Mainmenu_EL
    endswitch
endscript

script dadmod_menu_level_menu
    THUGRECOMP_MenuOpt key = "level" step = 0
    cur = <index>
    default_skateshop_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_menulevel
    menu_title = "Menu level"
    menu_style = MENU_STYLE_LEFT
    helper_text = generic_helper_text
    pad_back_script = dadmod_menu_level_back
    show_description_panel
    show_gradient
    scrolling
    }
    GetArraySize dadmod_menu_level_list
    i = 0
    last_game = ""
    begin
        if (<i> = <array_size>)
            break
        endif
        e = ( dadmod_menu_level_list [ <i> ] )
        g = ( <e> . game )
        if not THUGRECOMP_MenuLevelHas index = ( <e> . i )
            g = <last_game>
        endif
        if not (<g> = <last_game>)
            FormatText TextName = h "- %s -" s = <g>
            make_thugpro_menu_item {
            text = <h>
            not_focusable
            }
            last_game = <g>
        endif
        if ( ( <e> . i ) = <cur> )
            FormatText TextName = t "%s  *" s = ( <e> . name )
            d = "The level behind the main menu now"
        else
            t = ( <e> . name )
            d = "Show this level behind the main menu. It loads right away"
        endif
        if THUGRECOMP_MenuLevelHas index = ( <e> . i )
        make_thugpro_menu_item {
        text = <t>
        description_text = <d>
        pad_choose_script = dadmod_menu_level_pick
        pad_choose_params = { pick = ( <e> . i ) }
        }
        endif
        i = ( <i> + 1 )
    repeat
    dadmod_desc_panel_right
    thugpro_menu_finalize
endscript

script dadmod_menu_level_pick
    THUGRECOMP_MenuOpt key = "level" pick = <pick>
    Change dadmod_mm_armed = none
    if GotParam pending
        if (<pending> = 1)
            Change dadmod_mm_reopen = 1
            SpawnScript dadmod_reload_menu_scene
            return
        endif
    endif
    dadmod_menu_level_back
endscript

script dadmod_menu_level_back
    if (dadmod_layout_node > -1)
        dadmod_layout_open node = ( dadmod_layout_node )
    else
        create_dadmod_setup_menu
    endif
endscript

script dadmod_cars_menu
    dialog_box_exit
    generic_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_cars
    scrolling
    num_items_to_show = 13
    menu_title = "cars"
    menu_style = MENU_STYLE_LEFT
    pad_back_script = dadmod_menu
    helper_text = generic_helper_text
    show_description_panel
    show_gradient
    boxed
    }
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        make_thugpro_menu_item {
        text = <dadmod_c2_no>
        not_focusable
        }
    endif
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_ko "Get out here. In a car: %b gets out, %c handbrake, %h horn" b = <dadmod_c2_xl> c = <dadmod_c2_hk> h = <dadmod_c2_hn>
    make_thugpro_menu_item {
    text = "Get Out"
    description_text = <dadmod_c2_ko>
    pad_choose_script = dadmod_cars_exit
    }
    make_thugpro_menu_item {
    text = "More Cars  >"
    description_text = "20 more cars. DadMod players see them, others see a green car"
    pad_choose_script = dadmod_cars_menu_extra
    }
    make_thugpro_menu_item {
    text = "Props  >"
    description_text = "Drive a traffic cone, a shopping cart, a robot and more"
    pad_choose_script = dadmod_cars_menu_props
    }
    dadmod_cars_item t = "TransAm" c = JunkerCar
    dadmod_cars_item t = "Custom Tuner" c = RallyCar
    dadmod_cars_item t = "Impala" c = ImpalaCar
    dadmod_cars_item t = "Police Car" c = PoliceCar
    dadmod_cars_item t = "NY Cab" c = TaxiNY
    dadmod_cars_item t = "Security Cart" c = SecurityCart
    dadmod_cars_item t = "Gardener Cart" c = GardnersCart
    dadmod_cars_item t = "El Camino" c = ElCaminoCar
    dadmod_cars_item t = "Lada" c = LadaCar
    dadmod_cars_item t = "Mini Baja" c = MiniBajaCar
    dadmod_cars_item t = "Limo" c = LimoCar
    dadmod_cars_item t = "Taurus" c = TaurusCar
    dadmod_cars_item t = "Pickup" c = PickupTruck
    dadmod_cars_item t = "Wrangler" c = WranglerCar
    dadmod_cars_item t = "Sports Car" c = SportsCar
    dadmod_cars_item t = "Forklift" c = Forklift
    dadmod_cars_item t = "Blimp" c = Blimp
    thugpro_menu_finalize
endscript

script dadmod_cars_item
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_d "Drive the %t: %a/%b gas/brake, %c/%e steer, %h handbrake, %o out. Everyone sees it" t = <t> a = <dadmod_c2_up> b = <dadmod_c2_dn> c = <dadmod_c2_lf> e = <dadmod_c2_rt> h = <dadmod_c2_hk> o = <dadmod_c2_xo>
    make_thugpro_menu_item {
    text = <t>
    description_text = <dadmod_c2_d>
    pad_choose_script = dadmod_cars_pick
    pad_choose_params = { dadmod_c2_c = <c> }
    }
endscript

script dadmod_cars_can_drive
    if not ObjectExists id = skater
        return dadmod_c2_no = "No skater right now"
    endif
    if ChangeLevelPending
        return dadmod_c2_no = "The level is changing"
    endif
    if IsTrue THUGPRO_ObserveOn
        return dadmod_c2_no = "Not while observing"
    endif
    if not ( ( GameModeEquals is_lobby ) or ( GameModeEquals is_singlesession ) )
        return dadmod_c2_no = "Cars work in free skate only"
    endif
    return dadmod_c2_ok = 1
endscript

script dadmod_cars_msg
    THUGRECOMP_Log text = <text>
    create_panel_message id = dadmod_cars_note text = <text> time = 2500
endscript

script dadmod_cars_pick
    if not GotParam dadmod_c2_c
        return
    endif
    exit_pause_menu
    KillSpawnedScript Name = dadmod_cars_go
    SpawnScript dadmod_cars_go params = { dadmod_c2_c = <dadmod_c2_c> } NotSessionSpecific = 1
endscript

script dadmod_cars_go
    wait 5 gameframes
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        dadmod_cars_msg text = <dadmod_c2_no>
        return
    endif
    if Skater : Driving
        KillSpawnedScript Name = dadmod_cars_wait_exit
        KillSpawnedScript Name = dadmod_cars_watch
        dadmod_cars_exit_now
        wait 10 gameframes
        if not ObjectExists id = skater
            return
        endif
        if Skater : Driving
            dadmod_cars_msg text = "Could not switch cars"
            return
        endif
        dadmod_c2_sw = 1
    endif
    if not GotParam dadmod_c2_sw
        if Skater : InAir
            dadmod_cars_msg text = "Land first, then pick the car"
            return
        endif
        if Skater : IsInBail
            dadmod_cars_msg text = "Get up first, then pick the car"
            return
        endif
    endif
    dadmod_cars_boot
    GetVehicleSetup control_type = <dadmod_c2_c>
    if not StructureContains structure = ( VehicleSetupMapping ) <dadmod_c2_c>
        if StructureContains structure = ( dadmod_c2_extra_map ) <dadmod_c2_c>
            VehicleSetup = ( dadmod_c2_extra_map . <dadmod_c2_c> )
        endif
    endif
    Skater : Obj_GetPosition
    VehicleSetup = { <VehicleSetup> control_type = <dadmod_c2_c> Pos = ( <Pos> + (0.0,20.0,0.0) ) }
    THUGRECOMP_CarsDrive gta = 0
    if StructureContains structure = ( dadmod_c2_physfix ) <dadmod_c2_c>
        dadmod_c2_pf = ( dadmod_c2_physfix . <dadmod_c2_c> )
        VehicleSetup = { <VehicleSetup> <dadmod_c2_pf> }
    endif
    if StructureContains structure = ( dadmod_c2_car_sounds ) <dadmod_c2_c>
        dadmod_c2_sn = ( dadmod_c2_car_sounds . <dadmod_c2_c> )
        VehicleSetup = { <VehicleSetup> sounds = <dadmod_c2_sn> }
    endif
    if StructureContains structure = <VehicleSetup> skater_anim
        VehicleSetup = { <VehicleSetup> skater_anim = Ped_SIT_Idle }
    endif
    dadmod_c2_hide = 1
    if StructureContains structure = <VehicleSetup> make_skater_visible
        dadmod_c2_hide = 0
    endif
    THUGRECOMP_Log text = "cars2: get in"
    LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
    LoadSound "Vehicles\\Vehicle_Tire_Loop"
    LoadSound "Terrains\\BonkMetal_11"
    dadmod_cars_load_sound c = <dadmod_c2_c>
    dadmod_c2_cd = 240
    dadmod_c2_ch = 55
    dadmod_c2_ca = 3.5
    if StructureContains structure = ( dadmod_c2_cams ) <dadmod_c2_c>
        dadmod_c2_cm = ( dadmod_c2_cams . <dadmod_c2_c> )
        dadmod_c2_cd = ( <dadmod_c2_cm> . d )
        dadmod_c2_ch = ( <dadmod_c2_cm> . h )
    endif
    Change vehicleCameraSetup = { alignment_rate = <dadmod_c2_ca> offset_height = <dadmod_c2_ch> offset_distance = <dadmod_c2_cd> angle = 0 }
    MakeSkaterGoto Switch_OnGroundAi params = { NewScript = TransAm VehicleSetup = <VehicleSetup> Exitable }
    dadmod_c2_k = 0
    begin
        if ObjectExists id = PlayerVehicleCamera
            break
        endif
        if ( <dadmod_c2_k> > 30 )
            THUGRECOMP_Log text = "cars2: no PlayerVehicleCamera after 30 frames"
            dadmod_cars_msg text = "The car didn't start"
            Change vehicleCameraSetup = { alignment_rate = 3.5 offset_height = 55 offset_distance = 240 angle = 0 }
            return
        endif
        dadmod_c2_k = ( <dadmod_c2_k> + 1 )
        wait 1 gameframe
    repeat
    Change vehicleCameraSetup = { alignment_rate = 3.5 offset_height = 55 offset_distance = 240 angle = 0 }
    PlayerVehicleCamera : VehicleCamera_Reset
    SetActiveCamera id = PlayerVehicleCamera
    dadmod_cars_prop_show VehicleSetup = <VehicleSetup>
    if ObjectExists id = skater
        Skater : SetTags dadmod_c2_hide = <dadmod_c2_hide>
        if ( <dadmod_c2_hide> = 1 )
            Skater : hide
        endif
    endif
    dadmod_cars_hint_off
    THUGRECOMP_CarsDrive on = 1
    KillSpawnedScript Name = dadmod_cars_wait_exit
    SpawnScript dadmod_cars_wait_exit NotSessionSpecific = 1
    KillSpawnedScript Name = dadmod_cars_watch
    SpawnScript dadmod_cars_watch params = { dadmod_c2_hide = <dadmod_c2_hide> } NotSessionSpecific = 1
endscript

script dadmod_cars_wait_exit
    wait 0.5 seconds
    WaitForEvent Type = ExitVehicleRequest
    KillSpawnedScript Name = dadmod_cars_watch
    dadmod_cars_exit_now
endscript

script dadmod_cars_watch dadmod_c2_hide = 0
    begin
        dadmod_cars_beat dadmod_c2_hide = <dadmod_c2_hide>
        wait 3 gameframes
    repeat 10
    begin
        dadmod_cars_beat dadmod_c2_hide = <dadmod_c2_hide>
        wait 3 gameframes
        if not ObjectExists id = skater
            KillSpawnedScript Name = dadmod_cars_wait_exit
            dadmod_cars_hint_off
            dadmod_cars_prop_hide
            break
        endif
        if not Skater : Driving
            KillSpawnedScript Name = dadmod_cars_wait_exit
            dadmod_cars_hint_off
            dadmod_cars_prop_hide
            if Skater : IsHidden
                Skater : unhide
            endif
            break
        endif
        if not ObjectExists id = PlayerVehicle
            KillSpawnedScript Name = dadmod_cars_wait_exit
            THUGRECOMP_Log text = "cars2: car gone while driving, cleaning up"
            dadmod_cars_exit_now
            break
        endif
        dadmod_cars_can_drive
        if GotParam dadmod_c2_no
            KillSpawnedScript Name = dadmod_cars_wait_exit
            THUGRECOMP_Log text = "cars2: left free skate or level changing, getting out"
            dadmod_cars_exit_now
            break
        endif
    repeat
endscript

script dadmod_cars_hint_off
    THUGRECOMP_CarsDrive on = 0
    if ScreenElementExists id = dadmod_cars_hint
        DestroyScreenElement id = dadmod_cars_hint
    endif
endscript

script dadmod_cars_beat dadmod_c2_hide = 0
    if ( <dadmod_c2_hide> = 1 )
        if ObjectExists id = skater
            if Skater : Driving
                if not Skater : IsHidden
                    Skater : hide
                endif
            endif
        endif
    endif
    dadmod_c2_m = 0
    if ScreenElementExists id = current_menu_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = dialog_box_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = keyboard_anchor
        dadmod_c2_m = 1
    endif
    if ScreenElementExists id = quit_dialog_anchor
        dadmod_c2_m = 1
    endif
    if GameIsPaused
        dadmod_c2_m = 1
    endif
    if ( <dadmod_c2_m> = 1 )
        THUGRECOMP_CarsDrive on = 0
    else
        THUGRECOMP_CarsDrive on = 1
        if GotParam horn
            dadmod_cars_horn
        endif
    endif
endscript

script dadmod_cars_exit
    exit_pause_menu
    KillSpawnedScript Name = dadmod_cars_exit_go
    SpawnScript dadmod_cars_exit_go NotSessionSpecific = 1
endscript

script dadmod_cars_exit_go
    wait 3 gameframes
    KillSpawnedScript Name = dadmod_cars_wait_exit
    KillSpawnedScript Name = dadmod_cars_watch
    if ObjectExists id = skater
        if not Skater : Driving
            dadmod_cars_hint_off
            dadmod_cars_msg text = "You're not in a car"
            return
        endif
    endif
    dadmod_cars_exit_now
endscript

script dadmod_cars_exit_now
    dadmod_cars_prop_hide
    dadmod_cars_hint_off
    if not ObjectExists id = skater
        return
    endif
    if not Skater : Driving
        return
    endif
    THUGRECOMP_Log text = "cars2: get out"
    if ObjectExists id = PlayerVehicle
        PlayerVehicle : Obj_GetPosition
        dadmod_c2_pos = <Pos>
        if ObjectExists id = PlayerVehicleCamera
            ToggleUserControlledVehicleMode
            if ObjectExists id = skater
                Skater : dadmod_shadow_restore
            endif
        else
            PlayerVehicle : Die
            dadmod_cars_cleanup
        endif
    else
        dadmod_cars_cleanup
    endif
    if GotParam dadmod_c2_pos
        Skater : Obj_SetPosition position = ( <dadmod_c2_pos> + (0.0,10.0,0.0) )
    endif
    Skater : UnpausePhysics
    Skater : SetSpeed 0
    MakeSkaterGoto Switch_OnGroundAi params = { NewScript = OnGroundAi }
    wait 2 gameframes
    if ObjectExists id = skater
        Skater : SetSpeed 0
    endif
endscript

script dadmod_cars_cleanup
    dadmod_cars_prop_hide
    Skater : GetCameraId
    if ObjectExists id = <CameraId>
        if not GameIsPaused
            <CameraId> : unpause
        endif
        SetActiveCamera id = <CameraId>
    endif
    if ObjectExists id = PlayerVehicleCamera
        PlayerVehicleCamera : Die
    endif
    Skater : UnsetDriving
    Skater : unhide
    Skater : ReturnBoardToSkater
    Skater : dadmod_shadow_restore
    Skater : ResetRigidBodyCollisionRadiusBoost
    GoalManager_HideAllGoalPeds 0
    Change driving_parked_car = 0
endscript

script dadmod_cars_rehide
    if ObjectExists id = skater
        if Skater : Driving
            Skater : GetTags
            if GotParam dadmod_c2_hide
                if ( <dadmod_c2_hide> = 1 )
                    Skater : hide
                    KillSpawnedScript Name = dadmod_cars_rehide_frames
                    SpawnScript dadmod_cars_rehide_frames NotSessionSpecific = 1
                endif
            endif
        endif
    endif
endscript

script dadmod_cars_rehide_frames
    begin
        wait 1 gameframe
        if not ObjectExists id = skater
            break
        endif
        if not Skater : Driving
            break
        endif
        Skater : hide
    repeat 15
endscript

script dadmod_cars_item_x
    THUGRECOMP_CarsKeys
    FormatText TextName = dadmod_c2_d "Drive the %t: %a/%b gas/brake, %h handbrake, %o out. DadMod players see it" t = <t> a = <dadmod_c2_up> b = <dadmod_c2_dn> h = <dadmod_c2_hk> o = <dadmod_c2_xo>
    make_thugpro_menu_item {
    text = <t>
    description_text = <dadmod_c2_d>
    pad_choose_script = dadmod_cars_pick
    pad_choose_params = { dadmod_c2_c = <c> }
    }
endscript

script dadmod_cars_menu_extra
    dadmod_cars_sub_menu title = "more cars" items = dadmod_cars_extra_items
endscript

script dadmod_cars_menu_props
    dadmod_cars_sub_menu title = "props" items = dadmod_cars_prop_items
endscript

script dadmod_cars_sub_menu
    dialog_box_exit
    generic_menu_cleanup
    thugpro_menu_create {
    menu_name = dadmod_cars_sub
    scrolling
    num_items_to_show = 13
    menu_title = <title>
    menu_style = MENU_STYLE_LEFT
    pad_back_script = dadmod_cars_menu
    helper_text = generic_helper_text
    show_description_panel
    show_gradient
    boxed
    }
    dadmod_cars_can_drive
    if GotParam dadmod_c2_no
        make_thugpro_menu_item {
        text = <dadmod_c2_no>
        not_focusable
        }
    endif
    make_thugpro_menu_item {
    text = "Get Out"
    description_text = "Get out of the car and back on your board, right where the car is"
    pad_choose_script = dadmod_cars_exit
    }
    <items>
    thugpro_menu_finalize
endscript

script dadmod_cars_handling_get
    return dadmod_c2_gta = 0
endscript

script dadmod_cars_boot
    if not StructureContains structure = ( VehicleSetupMapping ) dadmod_prop_cone
        dadmod_cars_boot_maps
    endif
    dadmod_cars_handling_get
    THUGRECOMP_CarsDrive gta = <dadmod_c2_gta>
    KillSpawnedScript Name = dadmod_cars_remote_props
    SpawnScript dadmod_cars_remote_props NotSessionSpecific = 1
endscript

script dadmod_cars_horn
    if not ObjectExists id = skater
        return
    endif
    if not Skater : Driving
        return
    endif
    if not IsStreamPlaying CarHorn
        Skater : Obj_PlayStream CarHorn vol = 100 dropoff = 300
    endif
    if InNetGame
        THUGRECOMP_CarsHornSend
        if OnServer
            dadmod_cars_horn_push
        endif
    endif
endscript

script dadmod_cars_horn_hear
    if not GotParam id
        return
    endif
    thugpro_slaphit_obj id = <id>
    if not GotParam o
        return
    endif
    if not ObjectExists id = <o>
        return
    endif
    if OnServer
        dadmod_cars_horn_push
    endif
    if IsStreamPlaying CarHorn
        return
    endif
    <o> : Obj_GetPosition
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Die
    endif
    CreateCompositeObject {
    Components = [
    {
    component = stream
    }
    ]
    params = { Name = dadmod_horn_src Pos = <Pos> }
    }
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Obj_PlayStream CarHorn vol = 100 dropoff = 300
        KillSpawnedScript Name = dadmod_cars_horn_src_die
        SpawnScript dadmod_cars_horn_src_die NotSessionSpecific = 1
    endif
endscript

script dadmod_cars_horn_src_die
    wait 3 seconds
    if ObjectExists id = dadmod_horn_src
        dadmod_horn_src : Die
    endif
endscript

script dadmod_cars_prop_show
    dadmod_cars_prop_hide
    if not GotParam VehicleSetup
        return
    endif
    if not StructureContains structure = <VehicleSetup> dadmod_prop_model
        return
    endif
    if not ObjectExists id = PlayerVehicle
        return
    endif
    PlayerVehicle : hide
    CreateCompositeObject {
    Components = [
    {
    component = lockobj
    }
    {
    component = model
    model = ( <VehicleSetup> . dadmod_prop_model )
    UseModelLights
    }
    ]
    params = { Name = dadmod_prop_vis }
    }
    if ObjectExists id = dadmod_prop_vis
        dadmod_prop_vis : Obj_LockToObject id = PlayerVehicle (0.0,0.0,0.0)
    endif
endscript

script dadmod_cars_prop_hide
    if ObjectExists id = dadmod_prop_vis
        dadmod_prop_vis : Die
    endif
endscript

script dadmod_cars_remote_props
    begin
        wait 10 gameframes
        if InNetGame
            dadmod_c2_i = 0
            begin
                dadmod_cars_remote_prop_one id = <dadmod_c2_i>
                dadmod_c2_i = ( <dadmod_c2_i> + 1 )
            repeat 16
        endif
    repeat
endscript

script dadmod_cars_remote_prop_one
    thugpro_slaphit_obj id = <id>
    if not GotParam o
        return
    endif
    MangleChecksums a = <o> b = dadmod_prop_remote
    dadmod_c2_pv = <mangled_id>
    dadmod_c2_want = 0
    if ObjectExists id = <o>
        MangleChecksums a = <o> b = NonLocalPlayerVehicle
        dadmod_c2_car = <mangled_id>
        if ObjectExists id = <dadmod_c2_car>
            <dadmod_c2_car> : GetTags
            if GotParam current_control_type
                if StructureContains structure = ( dadmod_c2_extra_map ) <current_control_type>
                    dadmod_c2_set = ( dadmod_c2_extra_map . <current_control_type> )
                    if StructureContains structure = <dadmod_c2_set> dadmod_prop_model
                        dadmod_c2_want = 1
                    endif
                endif
            endif
        endif
    endif
    if ( <dadmod_c2_want> = 0 )
        if ObjectExists id = <dadmod_c2_pv>
            <dadmod_c2_pv> : Die
        endif
        return
    endif
    if ObjectExists id = <dadmod_c2_pv>
        <dadmod_c2_pv> : GetTags
        if GotParam dadmod_c2_ct
            if ( <dadmod_c2_ct> = <current_control_type> )
                <dadmod_c2_car> : hide
                return
            endif
        endif
        <dadmod_c2_pv> : Die
    endif
    CreateCompositeObject {
    Components = [
    {
    component = lockobj
    }
    {
    component = model
    model = ( <dadmod_c2_set> . dadmod_prop_model )
    UseModelLights
    }
    ]
    params = { Name = <dadmod_c2_pv> }
    }
    if ObjectExists id = <dadmod_c2_pv>
        <dadmod_c2_pv> : SetTags dadmod_c2_ct = <current_control_type>
        <dadmod_c2_pv> : Obj_LockToObject id = <dadmod_c2_car> (0.0,0.0,0.0)
        <dadmod_c2_car> : hide
    endif
endscript

dadmod_car_hearse_setup = {
control_type = dadmod_car_hearse
model = "veh\\Veh_Hearse\\Veh_Hearse.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_woodie_setup = {
control_type = dadmod_car_woodie
model = "veh\\Veh_Woodie\\Veh_Woodie.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_sedan_setup = {
control_type = dadmod_car_sedan
model = "veh\\Veh_Sedan\\Veh_Sedan.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_smart_setup = {
control_type = dadmod_car_smart
model = "veh\\Veh_Smart_car\\Veh_Smart_Car.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_hippyvan_setup = {
control_type = dadmod_car_hippyvan
model = "veh\\veh_HippyVan\\veh_HippyVan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_benzvan_setup = {
control_type = dadmod_car_benzvan
model = "veh\\veh_Benz_Van\\veh_Benz_Van.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_minivan_setup = {
control_type = dadmod_car_minivan
model = "veh\\Veh_Minivan\\Veh_Minivan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_oldvan_setup = {
control_type = dadmod_car_oldvan
model = "veh\\Veh_OldVan\\Veh_OldVan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_suv_setup = {
control_type = dadmod_car_suv
model = "veh\\Veh_SUV\\Veh_SUV.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_rust_setup = {
control_type = dadmod_car_rust
model = "veh\\veh_rust\\veh_rust.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_liberty_setup = {
control_type = dadmod_car_liberty
model = "veh\\veh_liberty\\veh_liberty.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_bcntaxi_setup = {
control_type = dadmod_car_bcntaxi
model = "veh\\veh_barcelona_taxi\\veh_barcelona_taxi.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(33.0,25.0,1.5e+02)
(-33.0,25.0,1.5e+02)
(33.0,25.0,-65.0)
]
[
(28.0,55.0,62.0)
(-28.0,55.0,62.0)
(28.0,55.0,-2.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_neon_setup = {
control_type = dadmod_car_neon
model = "veh\\Veh_NeonType\\Veh_NeonType.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_dctruck_setup = {
control_type = dadmod_car_dctruck
model = "veh\\Veh_DCShoeTruck\\Veh_DCShoeTruck.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_tourbus_setup = {
control_type = dadmod_car_tourbus
model = "veh\\Veh_TourBus\\Veh_TourBus.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_atv_setup = {
control_type = dadmod_car_atv
model = "veh\\Veh_ATV\\Veh_ATV.mdl"
sounds = SE_ATV
make_skater_visible
skater_pos = (-0.65,-2.0,4.07)
skater_anim = Ped_Baha_Drive
suspension_center_of_mass = -21
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.6
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 25
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(37.0,3e+01,41.0)
(-37.0,3e+01,41.0)
(37.0,3e+01,-36.0)
]
[
(12.0,64.0,16.0)
(-12.0,64.0,16.0)
(12.0,64.0,-28.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 14
moment = 3570
spring_rate = 200
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -20
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -20
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 1.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 1.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_mardi_setup = {
control_type = dadmod_car_mardi
model = "veh\\Veh_Mardi\\Veh_Mardi.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_duck_setup = {
control_type = dadmod_car_duck
model = "veh\\Veh_Duck\\veh_duck.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_sub_setup = {
control_type = dadmod_car_sub
model = "veh\\veh_sub\\veh_sub.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_car_streetcar_setup = {
control_type = dadmod_car_streetcar
model = "veh\\veh_streetcar\\veh_streetcar.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_prop_cone_setup = {
control_type = dadmod_prop_cone
dadmod_prop_model = "Mdl_Cone\\Mdl_Cone.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_cart_setup = {
control_type = dadmod_prop_cart
dadmod_prop_model = "veh\\Veh_Trolley\\veh_trolley.mdl"
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
make_skater_visible
skater_pos = (-10.81,1.0,26.18)
skater_anim = Ped_SIT_Idle
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_scooter_setup = {
control_type = dadmod_prop_scooter
dadmod_prop_model = "veh\\Veh_Scooter\\Veh_Scooter.mdl"
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
make_skater_visible
skater_pos = (-10.81,1.0,26.18)
skater_anim = Ped_SIT_Idle
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_robot_setup = {
control_type = dadmod_prop_robot
dadmod_prop_model = "veh\\veh_smallrobot\\veh_smallrobot.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_robot2_setup = {
control_type = dadmod_prop_robot2
dadmod_prop_model = "veh\\veh_smallrobot2\\veh_smallrobot2.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_chest_setup = {
control_type = dadmod_prop_chest
dadmod_prop_model = "gameobjects\\pickups\\treasure_chest\\treasure_chest.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_bike_setup = {
control_type = dadmod_prop_bike
dadmod_prop_model = "veh\\Veh_CopperBike\\Veh_CopperBike.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_mini_setup = {
control_type = dadmod_prop_mini
dadmod_prop_model = "veh\\Veh_Mini\\Veh_Mini.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}

dadmod_prop_halfpipe_setup = {
control_type = dadmod_prop_halfpipe
dadmod_prop_model = "veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\veh_limo\\veh_limo.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}

dadmod_c2_cams = {
JunkerCar = { d = 240 h = 55 a = 3.2 }
RallyCar = { d = 255 h = 58 a = 4.0 }
ImpalaCar = { d = 255 h = 58 a = 3.0 }
PoliceCar = { d = 290 h = 66 a = 3.6 }
TaxiNY = { d = 345 h = 78 a = 3.2 }
SecurityCart = { d = 240 h = 55 a = 3.5 }
GardnersCart = { d = 240 h = 55 a = 3.5 }
ElCaminoCar = { d = 255 h = 58 a = 3.2 }
LadaCar = { d = 250 h = 57 a = 3.6 }
MiniBajaCar = { d = 240 h = 55 a = 4.0 }
LimoCar = { d = 320 h = 73 a = 2.6 }
TaurusCar = { d = 250 h = 57 a = 3.4 }
PickupTruck = { d = 290 h = 66 a = 3.0 }
WranglerCar = { d = 240 h = 55 a = 3.2 }
SportsCar = { d = 240 h = 55 a = 4.4 }
Forklift = { d = 240 h = 55 a = 3.5 }
dadmod_car_hearse = { d = 290 h = 66 a = 3.0 }
dadmod_car_woodie = { d = 270 h = 62 a = 3.0 }
dadmod_car_sedan = { d = 255 h = 58 a = 3.4 }
dadmod_car_smart = { d = 220 h = 52 a = 3.8 }
dadmod_car_hippyvan = { d = 290 h = 72 a = 2.8 }
dadmod_car_benzvan = { d = 300 h = 74 a = 2.8 }
dadmod_car_minivan = { d = 280 h = 66 a = 3.0 }
dadmod_car_oldvan = { d = 280 h = 68 a = 2.8 }
dadmod_car_suv = { d = 300 h = 70 a = 3.0 }
dadmod_car_rust = { d = 260 h = 60 a = 3.2 }
dadmod_car_liberty = { d = 255 h = 58 a = 3.4 }
dadmod_car_bcntaxi = { d = 270 h = 62 a = 3.2 }
dadmod_car_neon = { d = 250 h = 57 a = 3.6 }
dadmod_car_dctruck = { d = 380 h = 90 a = 2.4 }
dadmod_car_tourbus = { d = 470 h = 110 a = 2.2 }
dadmod_car_atv = { d = 220 h = 52 a = 4.0 }
dadmod_car_mardi = { d = 420 h = 100 a = 2.4 }
dadmod_car_duck = { d = 420 h = 100 a = 2.4 }
dadmod_car_sub = { d = 330 h = 80 a = 2.6 }
dadmod_car_streetcar = { d = 470 h = 110 a = 2.2 }
dadmod_prop_cone = { d = 130 h = 34 a = 4.0 }
dadmod_prop_cart = { d = 170 h = 42 a = 3.8 }
dadmod_prop_scooter = { d = 170 h = 42 a = 4.0 }
dadmod_prop_robot = { d = 150 h = 38 a = 4.0 }
dadmod_prop_robot2 = { d = 160 h = 40 a = 4.0 }
dadmod_prop_chest = { d = 140 h = 36 a = 4.0 }
dadmod_prop_bike = { d = 190 h = 48 a = 3.8 }
dadmod_prop_mini = { d = 210 h = 50 a = 3.8 }
dadmod_prop_halfpipe = { d = 700 h = 170 a = 2.2 }
}

dadmod_c2_extra_map = {
dadmod_car_hearse = dadmod_car_hearse_setup
dadmod_car_woodie = dadmod_car_woodie_setup
dadmod_car_sedan = dadmod_car_sedan_setup
dadmod_car_smart = dadmod_car_smart_setup
dadmod_car_hippyvan = dadmod_car_hippyvan_setup
dadmod_car_benzvan = dadmod_car_benzvan_setup
dadmod_car_minivan = dadmod_car_minivan_setup
dadmod_car_oldvan = dadmod_car_oldvan_setup
dadmod_car_suv = dadmod_car_suv_setup
dadmod_car_rust = dadmod_car_rust_setup
dadmod_car_liberty = dadmod_car_liberty_setup
dadmod_car_bcntaxi = dadmod_car_bcntaxi_setup
dadmod_car_neon = dadmod_car_neon_setup
dadmod_car_dctruck = dadmod_car_dctruck_setup
dadmod_car_tourbus = dadmod_car_tourbus_setup
dadmod_car_atv = dadmod_car_atv_setup
dadmod_car_mardi = dadmod_car_mardi_setup
dadmod_car_duck = dadmod_car_duck_setup
dadmod_car_sub = dadmod_car_sub_setup
dadmod_car_streetcar = dadmod_car_streetcar_setup
dadmod_prop_cone = dadmod_prop_cone_setup
dadmod_prop_cart = dadmod_prop_cart_setup
dadmod_prop_scooter = dadmod_prop_scooter_setup
dadmod_prop_robot = dadmod_prop_robot_setup
dadmod_prop_robot2 = dadmod_prop_robot2_setup
dadmod_prop_chest = dadmod_prop_chest_setup
dadmod_prop_bike = dadmod_prop_bike_setup
dadmod_prop_mini = dadmod_prop_mini_setup
dadmod_prop_halfpipe = dadmod_prop_halfpipe_setup
}

dadmod_c2_push_map = {
JunkerCar = TransCarSetup
RallyCar = CustomCarSetup
ImpalaCar = ImpalaCarSetup
TaxiNY = TaxiNYSetup
PoliceCar = PoliceCarSetup
SecurityCart = SecurityCartSetup
GardnersCart = GardnersCartSetup
ElCaminoCar = ElCaminoCarSetup
Blimp = BlimpSetup
LadaCar = LadaCarSetup
MiniBajaCar = MiniBajaCarSetup
LimoCar = LimoCarSetup
Forklift = ForkliftSetup
RCCar = RCCarSetup
TaurusCar = TaurusCarSetup
PickupTruck = PickupTruckSetup
WranglerCar = WranglerCarSetup
SportsCar = SportsCarSetup
OffroadCar = OffroadCarSetup
dadmod_car_hearse = { model = "veh\\Veh_Hearse\\Veh_Hearse.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_woodie = { model = "veh\\Veh_Woodie\\Veh_Woodie.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_sedan = { model = "veh\\Veh_Sedan\\Veh_Sedan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_smart = { model = "veh\\Veh_Smart_car\\Veh_Smart_Car.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_hippyvan = { model = "veh\\veh_HippyVan\\veh_HippyVan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_benzvan = { model = "veh\\veh_Benz_Van\\veh_Benz_Van.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_minivan = { model = "veh\\Veh_Minivan\\Veh_Minivan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_oldvan = { model = "veh\\Veh_OldVan\\Veh_OldVan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_suv = { model = "veh\\Veh_SUV\\Veh_SUV.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_rust = { model = "veh\\veh_rust\\veh_rust.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_liberty = { model = "veh\\veh_liberty\\veh_liberty.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_bcntaxi = { model = "veh\\veh_barcelona_taxi\\veh_barcelona_taxi.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_neon = { model = "veh\\Veh_NeonType\\Veh_NeonType.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_dctruck = { model = "veh\\Veh_DCShoeTruck\\Veh_DCShoeTruck.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_tourbus = { model = "veh\\Veh_TourBus\\Veh_TourBus.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_atv = { model = "veh\\Veh_ATV\\Veh_ATV.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_mardi = { model = "veh\\Veh_Mardi\\Veh_Mardi.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_duck = { model = "veh\\Veh_Duck\\veh_duck.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_sub = { model = "veh\\veh_sub\\veh_sub.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_streetcar = { model = "veh\\veh_streetcar\\veh_streetcar.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_cone = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_cart = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_scooter = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_robot = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_robot2 = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_chest = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_bike = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_mini = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_halfpipe = { model = "veh\\veh_limo\\veh_limo.mdl" skater_pos = (0.0,0.0,0.0) }
}

dadmod_c2_sounds = {
dadmod_snd_JunkerCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_RallyCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ImpalaCar = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PoliceCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaxiNY = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SecurityCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_GardnersCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ElCaminoCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LadaCar = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_MiniBajaCar = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LimoCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaurusCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PickupTruck = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_WranglerCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SportsCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 75
MaxEnginePitch = 160
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Forklift = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Blimp = {
EngineSound = SJ_BlimpEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hearse = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_woodie = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sedan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_smart = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hippyvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_benzvan = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_minivan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_oldvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_suv = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_rust = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_liberty = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_bcntaxi = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_neon = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_dctruck = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_tourbus = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 45
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_atv = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_mardi = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_duck = {
EngineSound = FerryEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sub = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_streetcar = {
EngineSound = TramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cone = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 90
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cart = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 85
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_scooter = {
EngineSound = SK6_BA_Scooter_Engine
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot2 = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_chest = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 80
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_bike = {
EngineSound = MotoIdle01
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_mini = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_halfpipe = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
}

dadmod_c2_car_sounds = {
JunkerCar = dadmod_snd_JunkerCar
RallyCar = dadmod_snd_RallyCar
ImpalaCar = dadmod_snd_ImpalaCar
PoliceCar = dadmod_snd_PoliceCar
TaxiNY = dadmod_snd_TaxiNY
SecurityCart = dadmod_snd_SecurityCart
GardnersCart = dadmod_snd_GardnersCart
ElCaminoCar = dadmod_snd_ElCaminoCar
LadaCar = dadmod_snd_LadaCar
MiniBajaCar = dadmod_snd_MiniBajaCar
LimoCar = dadmod_snd_LimoCar
TaurusCar = dadmod_snd_TaurusCar
PickupTruck = dadmod_snd_PickupTruck
WranglerCar = dadmod_snd_WranglerCar
SportsCar = dadmod_snd_SportsCar
Forklift = dadmod_snd_Forklift
Blimp = dadmod_snd_Blimp
dadmod_car_hearse = dadmod_snd_dadmod_car_hearse
dadmod_car_woodie = dadmod_snd_dadmod_car_woodie
dadmod_car_sedan = dadmod_snd_dadmod_car_sedan
dadmod_car_smart = dadmod_snd_dadmod_car_smart
dadmod_car_hippyvan = dadmod_snd_dadmod_car_hippyvan
dadmod_car_benzvan = dadmod_snd_dadmod_car_benzvan
dadmod_car_minivan = dadmod_snd_dadmod_car_minivan
dadmod_car_oldvan = dadmod_snd_dadmod_car_oldvan
dadmod_car_suv = dadmod_snd_dadmod_car_suv
dadmod_car_rust = dadmod_snd_dadmod_car_rust
dadmod_car_liberty = dadmod_snd_dadmod_car_liberty
dadmod_car_bcntaxi = dadmod_snd_dadmod_car_bcntaxi
dadmod_car_neon = dadmod_snd_dadmod_car_neon
dadmod_car_dctruck = dadmod_snd_dadmod_car_dctruck
dadmod_car_tourbus = dadmod_snd_dadmod_car_tourbus
dadmod_car_atv = dadmod_snd_dadmod_car_atv
dadmod_car_mardi = dadmod_snd_dadmod_car_mardi
dadmod_car_duck = dadmod_snd_dadmod_car_duck
dadmod_car_sub = dadmod_snd_dadmod_car_sub
dadmod_car_streetcar = dadmod_snd_dadmod_car_streetcar
dadmod_prop_cone = dadmod_snd_dadmod_prop_cone
dadmod_prop_cart = dadmod_snd_dadmod_prop_cart
dadmod_prop_scooter = dadmod_snd_dadmod_prop_scooter
dadmod_prop_robot = dadmod_snd_dadmod_prop_robot
dadmod_prop_robot2 = dadmod_snd_dadmod_prop_robot2
dadmod_prop_chest = dadmod_snd_dadmod_prop_chest
dadmod_prop_bike = dadmod_snd_dadmod_prop_bike
dadmod_prop_mini = dadmod_snd_dadmod_prop_mini
dadmod_prop_halfpipe = dadmod_snd_dadmod_prop_halfpipe
}

script dadmod_cars_load_sound
    LoadSound "Vehicles\\Vehicle_Tire_Loop"
    switch <c>
    case JunkerCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: JunkerCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case RallyCar
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: RallyCar engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case ImpalaCar
        LoadSound "Shared\\Auto\\LowriderLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: ImpalaCar engine LowriderLoop (Shared/Auto/LowriderLoop), tires Vehicle_Tire_Loop"
    case PoliceCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: PoliceCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case TaxiNY
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: TaxiNY engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case SecurityCart
        LoadSound "SD\\SD_CartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: SecurityCart engine SD_CartLoop (SD/SD_CartLoop), tires Vehicle_Tire_Loop"
    case GardnersCart
        LoadSound "SD\\SD_CartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: GardnersCart engine SD_CartLoop (SD/SD_CartLoop), tires Vehicle_Tire_Loop"
    case ElCaminoCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: ElCaminoCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case LadaCar
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: LadaCar engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case MiniBajaCar
        LoadSound "AU\\AU_KartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: MiniBajaCar engine AU_KartLoop (AU/AU_KartLoop), tires Vehicle_Tire_Loop"
    case LimoCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: LimoCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case TaurusCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: TaurusCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case PickupTruck
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: PickupTruck engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case WranglerCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: WranglerCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case SportsCar
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: SportsCar engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case Forklift
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: Forklift engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    case Blimp
        LoadSound "SJ\\SJ_BlimpEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: Blimp engine SJ_BlimpEngineLoop (SJ/SJ_BlimpEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_hearse
        LoadSound "Shared\\Auto\\LowriderLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_hearse engine LowriderLoop (Shared/Auto/LowriderLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_woodie
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_woodie engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_sedan
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_sedan engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_smart
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_smart engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_hippyvan
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_hippyvan engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_benzvan
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_benzvan engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_minivan
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_minivan engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_oldvan
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_oldvan engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_suv
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_suv engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_rust
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_rust engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_liberty
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_liberty engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_bcntaxi
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_bcntaxi engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_neon
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_neon engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_dctruck
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_dctruck engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_tourbus
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_tourbus engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_atv
        LoadSound "AU\\AU_KartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_atv engine AU_KartLoop (AU/AU_KartLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_mardi
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_mardi engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_duck
        LoadSound "Shared\\Misc\\FerryEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_duck engine FerryEngineLoop (Shared/Misc/FerryEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_sub
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_sub engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_streetcar
        LoadSound "Shared\\Auto\\TramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_streetcar engine TramEngineLoop (Shared/Auto/TramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_cone
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_cone engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_cart
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_cart engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_scooter
        LoadSound "Vehicles\\SK6_BA_Scooter_Engine" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_scooter engine SK6_BA_Scooter_Engine (Vehicles/SK6_BA_Scooter_Engine), tires Vehicle_Tire_Loop"
    case dadmod_prop_robot
        LoadSound "Shared\\Auto\\ZooTramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_robot engine ZooTramEngineLoop (Shared/Auto/ZooTramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_robot2
        LoadSound "Shared\\Auto\\ZooTramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_robot2 engine ZooTramEngineLoop (Shared/Auto/ZooTramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_chest
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_chest engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_bike
        LoadSound "Terrains\\MotoX\\MotoIdle01" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_bike engine MotoIdle01 (Terrains/MotoX/MotoIdle01), tires Vehicle_Tire_Loop"
    case dadmod_prop_mini
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_mini engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_halfpipe
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_halfpipe engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    default
        THUGRECOMP_Log text = "cars2: no engine sound entry for this car"
    endswitch
endscript

script dadmod_cars_boot_maps
    Change VehicleSetupMapping = {
JunkerCar = TransCarSetup
RallyCar = CustomCarSetup
ImpalaCar = ImpalaCarSetup
TaxiNY = TaxiNYSetup
PoliceCar = PoliceCarSetup
SecurityCart = SecurityCartSetup
GardnersCart = GardnersCartSetup
ElCaminoCar = ElCaminoCarSetup
Blimp = BlimpSetup
LadaCar = LadaCarSetup
MiniBajaCar = MiniBajaCarSetup
LimoCar = LimoCarSetup
Forklift = ForkliftSetup
RCCar = RCCarSetup
TaurusCar = TaurusCarSetup
PickupTruck = PickupTruckSetup
WranglerCar = WranglerCarSetup
SportsCar = SportsCarSetup
OffroadCar = OffroadCarSetup
dadmod_car_hearse = dadmod_car_hearse_setup
dadmod_car_woodie = dadmod_car_woodie_setup
dadmod_car_sedan = dadmod_car_sedan_setup
dadmod_car_smart = dadmod_car_smart_setup
dadmod_car_hippyvan = dadmod_car_hippyvan_setup
dadmod_car_benzvan = dadmod_car_benzvan_setup
dadmod_car_minivan = dadmod_car_minivan_setup
dadmod_car_oldvan = dadmod_car_oldvan_setup
dadmod_car_suv = dadmod_car_suv_setup
dadmod_car_rust = dadmod_car_rust_setup
dadmod_car_liberty = dadmod_car_liberty_setup
dadmod_car_bcntaxi = dadmod_car_bcntaxi_setup
dadmod_car_neon = dadmod_car_neon_setup
dadmod_car_dctruck = dadmod_car_dctruck_setup
dadmod_car_tourbus = dadmod_car_tourbus_setup
dadmod_car_atv = dadmod_car_atv_setup
dadmod_car_mardi = dadmod_car_mardi_setup
dadmod_car_duck = dadmod_car_duck_setup
dadmod_car_sub = dadmod_car_sub_setup
dadmod_car_streetcar = dadmod_car_streetcar_setup
dadmod_prop_cone = dadmod_prop_cone_setup
dadmod_prop_cart = dadmod_prop_cart_setup
dadmod_prop_scooter = dadmod_prop_scooter_setup
dadmod_prop_robot = dadmod_prop_robot_setup
dadmod_prop_robot2 = dadmod_prop_robot2_setup
dadmod_prop_chest = dadmod_prop_chest_setup
dadmod_prop_bike = dadmod_prop_bike_setup
dadmod_prop_mini = dadmod_prop_mini_setup
dadmod_prop_halfpipe = dadmod_prop_halfpipe_setup
}
    Change PlayerVehicleSounds = {
#"Default" = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
SE_ATV = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
NY_JunkCar = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BO_Gurney = {
EngineSound = ShoppingCartLoop
MinEngineVol = 0
MaxEngineVol = 80
MinEnginePitch = 80
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 1
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 200
}
BO_Segway = {
EngineSound = SK6_BO_JesseRide_Loop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BA_SteveOBull = {
EngineSound = SK6_BA_SteveOElecLoop
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BE_PaulieWheelchair = {
EngineSound = SK6_BE_Paulie_Loop
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
AU_AborigineCart = {
EngineSound = AU_KartLoop
MinEngineVol = 90
MaxEngineVol = 120
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
NO_Trike = {
EngineSound = SK6_NO_TrikeSqueak
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_JunkerCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_RallyCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ImpalaCar = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PoliceCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaxiNY = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SecurityCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_GardnersCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ElCaminoCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LadaCar = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_MiniBajaCar = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LimoCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaurusCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PickupTruck = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_WranglerCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SportsCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 75
MaxEnginePitch = 160
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Forklift = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Blimp = {
EngineSound = SJ_BlimpEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hearse = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_woodie = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sedan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_smart = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hippyvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_benzvan = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_minivan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_oldvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_suv = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_rust = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_liberty = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_bcntaxi = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_neon = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_dctruck = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_tourbus = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 45
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_atv = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_mardi = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_duck = {
EngineSound = FerryEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sub = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_streetcar = {
EngineSound = TramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cone = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 90
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cart = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 85
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_scooter = {
EngineSound = SK6_BA_Scooter_Engine
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot2 = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_chest = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 80
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_bike = {
EngineSound = MotoIdle01
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_mini = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_halfpipe = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
}
endscript

