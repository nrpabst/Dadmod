dadmod_es_head = [
{ hdr t = "FACE" }
{ t = "Face" p = [ skater_m_head skater_f_head ] }
{ t = "Eyes" p = [ eyes eyes ] }
{ t = "Facial Hair" p = [ skater_m_jaw skater_m_jaw ] mo }
{ hdr t = "HAIR" }
{ t = "Male Hair" sex = m p = [ skater_m_hair skater_m_hair ] }
{ t = "Female Hair" sex = f p = [ skater_f_hair skater_f_hair ] }
{ t = "Male Hat Hair" sex = m p = [ skater_m_hat_hair skater_m_hat_hair ] }
{ t = "Female Hat Hair" sex = f p = [ skater_f_hat_hair skater_f_hat_hair ] }
{ hdr t = "HEADWEAR" }
{ t = "Hats" p = [ hat hat ] }
{ t = "Hat Logo" sex = l p = [ hat hat ] lp = [ hat_logo hat_logo ] }
{ t = "Glasses" p = [ glasses glasses ] }
{ hdr t = "PED HEADS" }
{ t = "Male Ped Heads" sex = p p = [ ped_m_head ped_m_head ] pre = "Ped Head" }
{ t = "Female Ped Heads" sex = p p = [ ped_f_head ped_f_head ] pre = "Ped Head" }
]
dadmod_es_deck = [
{ hdr t = "BOARD" }
{ t = "Board Type" p = [ board board ] cam = board }
{ t = "Deck Graphic" p = [ deck_graphic deck_graphic ] ok = board_allow_graphic cam = board }
{ hdr t = "GRIP TAPE" }
{ t = "Grip Tape" p = [ griptape griptape ] ok = board_allow_griptape cam = board_griptape }
{ hdr t = "TRUCKS" }
{ t = "Trucks" p = [ truck_texture truck_texture ] ok = board_allow_truck_texture cam = board }
{ hdr t = "WHEELS" }
{ t = "Wheels" p = [ wheel_texture wheel_texture ] ok = board_allow_wheel_texture cam = board }
]
dadmod_es_torso = [
{ hdr t = "SHIRT" }
{ t = "Male Shirt Style" sex = m p = [ skater_m_torso skater_m_torso ] x = sleeves xt = "Male Shirt Sleeves Color" xc = [ sleeves sleeves ] }
{ t = "Female Shirt Style" sex = f p = [ skater_f_torso skater_f_torso ] x = sleeves xt = "Female Shirt Sleeves Color" xc = [ sleeves sleeves ] }
{ hdr t = "LOGOS" }
{ t = "Shirt Front Logo" sex = l p = [ skater_m_torso skater_f_torso ] lp = [ front_logo front_logo ] x = adjust xt = "Adjust Front Logo" }
{ t = "Shirt Back Logo" sex = l p = [ skater_m_torso skater_f_torso ] lp = [ back_logo back_logo ] x = adjust xt = "Adjust Back Logo" }
{ hdr t = "GEAR" }
{ t = "Elbowpads" p = [ elbowpads elbowpads ] }
{ t = "Backpack" p = [ skater_m_backpack skater_f_backpack ] }
{ t = "Male Backpack" sex = m p = [ skater_m_backpack skater_m_backpack ] }
{ t = "Female Backpack" sex = f p = [ skater_f_backpack skater_f_backpack ] }
{ t = "Left Accessory" p = [ accessory1 accessory1 ] }
{ t = "Right Accessory" p = [ accessory2 accessory2 ] }
{ t = "Male Gloves" sex = m p = [ skater_m_hands skater_m_hands ] }
{ t = "Female Gloves" sex = f p = [ skater_f_hands skater_f_hands ] }
{ t = "Misc Items" p = [ accessory3 accessory3 ] }
{ hdr t = "PEDS" }
{ t = "Male Ped Torso" sex = p p = [ ped_m_torso ped_m_torso ] }
{ t = "Female Ped Torso" sex = p p = [ ped_f_torso ped_f_torso ] }
{ t = "Male Ped Accessory" sex = p p = [ ped_m_accessories ped_m_accessories ] }
{ t = "Female Ped Accessory" sex = p p = [ ped_f_accessories ped_f_accessories ] }
{ t = "Ped Body" sex = p p = [ ped_body ped_body ] }
]
dadmod_es_legs = [
{ hdr t = "PANTS" }
{ t = "Male Pants" sex = m p = [ skater_m_legs skater_m_legs ] }
{ t = "Female Pants" sex = f p = [ skater_f_legs skater_f_legs ] }
{ t = "Kneepads" p = [ kneepads kneepads ] }
{ hdr t = "FEET" }
{ t = "Socks" p = [ socks socks ] }
{ t = "Shoes" p = [ shoes shoes ] x = laces xt = "Shoelace Color" xc = [ shoe_laces shoe_laces ] }
{ hdr t = "PEDS" }
{ t = "Male Ped Pants" sex = p p = [ ped_m_legs ped_m_legs ] }
{ t = "Female Ped Pants" sex = p p = [ ped_f_legs ped_f_legs ] }
]
dadmod_es_tattoo = [
{ hdr t = "HEAD AND BODY" }
{ t = "Head Tattoo" p = [ head_tattoo head_tattoo ] }
{ t = "Chest Tattoo" p = [ chest_tattoo chest_tattoo ] x = adjust xt = "Adjust Chest Tattoo" }
{ t = "Back Tattoo" p = [ back_tattoo back_tattoo ] x = adjust xt = "Adjust Back Tattoo" }
{ hdr t = "ARMS" }
{ t = "L Bicep Tattoo" p = [ left_bicep_tattoo left_bicep_tattoo ] x = adjust xt = "Adjust L Bicep Tattoo" }
{ t = "R Bicep Tattoo" p = [ right_bicep_tattoo right_bicep_tattoo ] x = adjust xt = "Adjust R Bicep Tattoo" }
{ t = "R Sleeve Tattoo" p = [ right_sleeve_tattoo right_sleeve_tattoo ] x = adjust xt = "Adjust R Sleeve Tattoo" }
{ t = "L Sleeve Tattoo" p = [ left_sleeve_tattoo left_sleeve_tattoo ] x = adjust xt = "Adjust L Sleeve Tattoo" }
{ t = "L Forearm Tattoo" p = [ left_forearm_tattoo left_forearm_tattoo ] x = adjust xt = "Adjust L Forearm Tattoo" }
{ t = "R Forearm Tattoo" p = [ right_forearm_tattoo right_forearm_tattoo ] x = adjust xt = "Adjust R Forearm Tattoo" }
{ hdr t = "LEGS" }
{ t = "L Leg Tattoo" p = [ left_leg_tattoo left_leg_tattoo ] x = adjust xt = "Adjust L Leg Tattoo" }
{ t = "R Leg Tattoo" p = [ right_leg_tattoo right_leg_tattoo ] x = adjust xt = "Adjust R Leg Tattoo" }
]
dadmod_es_scale = [
{ text = "Copy Scales From..." pad_choose_script = dadmod_skc_scales_menu pad_choose_params = { } }
{ text = "Undo Copy Scales" pad_choose_script = dadmod_skc_scales_undo pad_choose_params = { } }
{ hdr t = "BODY" }
{ t = "Body" sz = object_scaling cam = General cb = General }
{ t = "Chest" sz = torso_bone_group cam = torso cb = torso }
{ t = "Waist" sz = stomach_bone_group cam = torso cb = torso }
{ hdr t = "HEAD" }
{ t = "Head Top" sz = headtop_bone_group cam = head cb = head }
{ t = "Face" sz = head_bone_group cam = head cb = head }
{ t = "Nose" sz = nose_bone_group cam = head cb = head }
{ t = "Jaw" sz = jaw_bone_group cam = head cb = head }
{ hdr t = "ARMS" }
{ t = "Biceps" sz = upper_arm_bone_group cam = torso cb = torso }
{ t = "Forearms" sz = lower_arm_bone_group cam = torso cb = torso }
{ t = "Hands" sz = hands_bone_group cam = torso cb = torso }
{ hdr t = "LEGS" }
{ t = "Thighs" sz = upper_leg_bone_group cam = Legs cb = Legs }
{ t = "Calves" sz = lower_leg_bone_group cam = Legs cb = Legs }
{ t = "Feet" sz = feet_bone_group cam = Legs cb = Legs }
{ hdr t = "BOARD" }
{ t = "Wheels" sz = wheels_bone_group p = [ board board ] ok = board_allow_wheel_scale cam = board cb = Legs }
{ t = "Board" sz = board_bone_group p = [ board board ] cam = board cb = Legs }
]
script dadmod_es_row cam_pos = General
    <r> = <row>
    if StructureContains structure = <r> hdr
        FormatText TextName = shown "\\c5%s" s = ( <r> . t )
        return item = { dadmod_header text = <shown> pad_choose_script = nullscript pad_choose_params = { } }
    endif
    <shown> = ( <r> . t )
    if StructureContains structure = <r> sex
        <sx> = ( <r> . sex )
        switch <sx>
        case m
            FormatText TextName = shown "\\ca%s" s = ( <r> . t )
        case f
            FormatText TextName = shown "\\cl%s" s = ( <r> . t )
        case p
            FormatText TextName = shown "\\cb%s" s = ( <r> . t )
        default
            FormatText TextName = shown "\\c7%s" s = ( <r> . t )
        endswitch
    endif
    <home> = <cam_pos>
    if StructureContains structure = <r> cb
        <home> = ( <r> . cb )
    endif
    <back> = { cam_pos = <home> options_array = <options_array> }
    <pp> = { callback_params = <back> callback = dadmod_es_options_menu title = ( <r> . t ) }
    if StructureContains structure = <r> p
        <pp> = { <pp> parts = ( <r> . p ) }
    endif
    if StructureContains structure = <r> cam
        <pp> = { <pp> cam = ( <r> . cam ) }
    endif
    if StructureContains structure = <r> ok
        <pp> = { <pp> allowed_items = ( <r> . ok ) }
    endif
    if StructureContains structure = <r> pre
        <pp> = { <pp> desc_prefix = ( <r> . pre ) }
    endif
    <go> = dadmod_es_part_menu
    if StructureContains structure = <r> lp
        <pp> = { <pp> show_logos logo_parts = ( <r> . lp ) }
    endif
    if StructureContains structure = <r> sz
        <go> = dadmod_es_scale_menu
        <pp> = { <pp> bone_group = ( <r> . sz ) scaling_params = { affectXYZ affectX affectY affectZ } }
    endif
    <item> = { pad_choose_params = <pp> pad_choose_script = <go> text = <shown> }
    if StructureContains structure = <r> mo
        <item> = { <item> male_only }
    endif
    if StructureContains structure = <r> x
        <xk> = ( <r> . x )
        switch <xk>
        case sleeves
            <tag> = { label = "sleeves" dx = (26.0,0.0) }
        case laces
            <tag> = { label = "laces" dx = (22.0,0.0) }
        default
            <tag> = { label = "adjust" dx = (24.0,0.0) }
        endswitch
        <xp> = { callback_params = <back> callback = dadmod_es_options_menu title = ( <r> . xt ) }
        if ChecksumEquals a = <xk> b = adjust
            <run> = create_part_cas_pos_menu
            if StructureContains structure = <r> lp
                <xp> = { <xp> parts = ( <r> . lp ) }
            else
                <xp> = { <xp> parts = ( <r> . p ) }
            endif
        else
            <run> = dadmod_part_color_go
            <xp> = { <xp> parts = ( <r> . p ) color_parts = ( <r> . xc ) }
        endif
        <item> = { <item> dadmod_extra = { run = <run> params = <xp> label = ( <tag> . label ) dx = ( <tag> . dx ) } }
    endif
    return item = <item>
endscript
