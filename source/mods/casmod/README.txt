Edit Skater mods (2026-10-30), all our own code. Built by build/obsspawn_test_make.sh into data/dadmod_casidle.qb
(loaded after the menu level's own scripts) plus a few flags in thugpro_qb.prx.

- gen_mixmatch.py: rebuilds the Edit Skater option lists from plain THUG Pro's (work/decompiled_vanilla,
  from "THUG Pro - vanilla"): male and female versions of hair, hat hair, skin color, shirts, backpacks, gloves
  and pants for any skater, male/female ped heads, torsos, accessories and pants, Ped Body, menu titles.
  Same idea as ken's "CAS Mod v2" and Kali's split options, none of their code or data.
- find_unsafe_parts.py (run on the VM side, needs the THUG2 + Original + Dev folders): finds parts whose model a
  player with stock Kali + THUG2 may not have loaded -> unsafe_parts.txt (list, desc_id, offline|never).
- hide_unsafe_parts.py (build step): those parts get `hidden` in the normal menus.
- offline.q: Edit Skater main menu (table driven). The name is left over from the removed Offline Only menu.
- logo_adjust.q: our logo/tattoo move, rotate and size scripts (±300, 1 steps, size 1..500 shown as %).
- sexchange.q: changing sex keeps the current look.
- Facial Hair stays male only (no female part: a female skater crashed).
qb.py has no comment syntax, so notes live here. A first port that copied ken's lists is archived in
work/archive/casmod_copy_20261030 (not used).

undress.q (ours, 2026-10-31)
  "Remove Clothes" entry in the Edit Skater main menu (added to edit_skater_main_entries in offline.q).
  dadmod_remove_clothes sets every clothing slot to the game's own bare/none option
  (male: Shirtless + Briefs, female: torso none = sport bra + legs none = bare legs),
  bare feet, bare hands, no socks/glasses/pads/backpack/accessories, lower legs Full Legs.
  Hat is left alone on purpose: hats clear the hair part, so removing one leaves the skater bald.
  Every desc_id used is in the stock lists, so it is safe online.
  Appended to the casidle cat line in build/obsspawn_test_make.sh.

sexchange.q rewrite (2026-10-31)
  The first version only flipped is_male, so the model kept the old sex's body/head/clothes and nothing changed.
  Now cas_apply_skater_sex merges the current appearance with dadmod_sex_base_male/female
  (body, head, hair, torso, legs, hands, lower legs, body_shape; values = stock default skaters),
  clears the old sex's parts (dadmod_sex_only_*), and keeps everything shared
  (shoes, socks, hat, glasses, pads, accessories, tattoos, board, eyes, scaling).
  Torso and backpack carry over when the other sex's list has the same desc_id.
  If a hat is worn, the new hair is cleared (same as picking a hat in the stock menu).
  Old version kept as sexchange.q.before_20261031_swap.

Crazy Bright (2026-11-01) was removed on 2026-11-02 at Noah's request ("it does nothing").
  Sources archived in archive/casglow_removed_20261102 (next to work/).

Color on anything (2026-11-02)
  The engine has no idea of no_color (its checksum isn't in any exe/dll); color is only limited by the menus.
  gen_mixmatch.py now adds "<text> Color" for every part option that had none (eyes, ped heads, deck graphic,
  tattoos); stock color_parts options (grip/truck/wheel) count as already having one.
  gen_partmenu.py also copies vanilla edit_skater_create_options_menu and drops BareFeet and Hands
  from its "grey out color" list (none and Shirtless have no model, so they stay grey).

Quality of life (2026-11-02, qol.q + gen_partmenu.py hooks)
  Preview while scrolling: every part item has focus_script dadmod_preview_part; it waits 8 frames
    (token debounce) then cas_set_part. The first focus after a menu opens is skipped (dadmod_preview_armed).
  Lists open on the worn item: dadmod_part_menu_ready returns focus_target = worn desc_id (items use desc_id as id).
  L3/R3 (stick clicks) in part lists fire pad_up/pad_down dadmod_page_size (10) times.
  Undo: dadmod_undo_save snapshots the whole appearance + sex when a part/color menu opens and before
    Remove Clothes / sex change. "Undo Last Change" (main list + bottom of every options list) swaps back;
    pressing it again redoes.
  Copy Color / Paste Color at the bottom of every color menu (colormenu_get_hsv / colormenu_set_hsv).

Tidy menus (2026-11-02)
  gen_mixmatch.py: plain "<part> Color" options dropped (each part list has a Color item at the top now,
  qol.q dadmod_part_color_item, returns to the part list); lists sorted into GROUPS with yellow header lines
  (dadmod_header entries, greyed by the edit_skater_create_options_menu copy); text colors:
  male \ca light blue, female \cl pink, ped \cb orange, logo/adjust \c7 purple, Color item \c6 cyan.
  Undo: the part list -> Color -> back trip counts as one change (dadmod_undo_hold).

Goal (Noah, 2026-11-02): dadmod should eventually install alongside the Kali mod, so Edit Skater changes
must keep working with Kali's lists and options (e.g. Kali's "Null" parts) instead of replacing them.
  Null pants (Kali's "Null" in the pants lists) also set the lower legs to none, so the whole legs go
  (cas_set_part copy + qol.q dadmod_after_set_part; Kali's lists are untouched). Briefly reverted, then
  Noah confirmed this is what he wants.
  Preview fix (2026-11-02): scrolling only previews. Select (dadmod_choose_part) keeps the item; backing out
  (dadmod_part_menu_back) puts back the appearance saved when the list opened or at the last select.
  Selected marker (2026-11-02): the worn/selected item in a part list shows green with "> " (dadmod_mark_selected,
  called when the list opens and on select; the old item's text is put back).
  Hair color stays (2026-11-03): cas_set_part copy calls dadmod_before_set_part (saves h/s/v of hair, hat hair
  or facial hair if it has a custom color) and dadmod_after_set_part puts it on the new style before the refresh.
  Color picking presets/recent colors (2026-11-03): built and then removed at Noah's request; the old version is in
  archive/casmod_colorpick_20261103.

No Kali Edit Skater scripts (2026-11-03). Compared Dev (Kali) with THUG Pro - vanilla (decompiled_vanilla/thugpro_qb is
the plain thugpro_qb.prx). Kali's Edit Skater changes and what replaces them:
  - color menu (thugpro_color_menu_add_options_to_menu with "Kalimod" label, randomize, reset): ownmenus.q has our own
    (Color / Brightness / Saturation sliders, Random Color, Default Color).
  - unlimited scaling (scalingmenu_constraints 0..999999): ownmenus.q, our own limits 0..1000000 for every part (Noah 2026-11-18: truly unlimited; 2026-11-19: one number per press, 6 with the stick pushed hard).
  - sex change warning box (confirm_skater_sexchange) and an extra call in launch_pre_cas_menu: plain THUG Pro copies
    from gen_partmenu.py.
  - logo/texture position menus (posmenu_*): already ours (logo_adjust.q); options lists, part menu, options menu: ours.
  Kali's part LISTS (skater_*/ped_*/shoes etc. in procrastination.q) stay: they're data the game and other Kali players
  need to agree on, and dadmod must install alongside Kali.
Analog sliders (2026-11-03): color and scale sliders move dadmod_analog_boost (6) steps per tick when the d-pad
  (ControllerPressed left/right) isn't held, i.e. on the analog stick; d-pad stays 1 step.

Slider fix (2026-11-03): the analog-speed wrappers (dadmod_color_step / dadmod_scale_step) made every
slider stick between two values, so the sliders call the stock step scripts again. The wrappers are
still defined in ownmenus.q but unused. Middle color slider label is "Brightness".

Analog sliders v2 (2026-11-03): dadmod_stick_step finds the controller bound to skater 0 and reads
GetAnalogueInfo leftx; if |leftx| > dadmod_stick_threshold (0.3) the step is dadmod_analog_boost (6), else 1.
dadmod_color_step and dadmod_scale_step are full own step scripts (no global swapping, no stock step call).

Color tags on the Edit Skater lists (2026-11-03): the Color item inside part lists is gone. gen_partmenu.py
makes every option in edit_skater_create_options_menu through dadmod_es_item (qol.q). Part-list options
(create_part_cas_menu with parts, no logo_parts) get a small lowercase "color" tag (own crillee text child dadmod_tag, scale 0.13, at the right edge); pad_right highlights it
(tag dadmod_side = 1), pad_left/unfocus clears it, and X (dadmod_es_choose) opens the color menu when it
is highlighted, otherwise the part list. Returning from either focuses the same option again (focus_target).

Undo / Redo buttons (2026-11-03): "Undo Last Change" menu items are gone. dadmod_undo_keys puts
pad_expand (Y / Triangle) = dadmod_undo and pad_square (X / Square) = dadmod_redo on current_menu in the
main Edit Skater menu, option lists, part lists, color and scale menus. One level each way: undo moves the
current look into the redo slot, redo moves it back; any new change clears redo. Helper bar shows
\b0 = Undo, \b1 = Redo (generic_helper_text_cas / _cas_z overridden, color menu uses dadmod_helper_text_color).

Analog sliders v3 (2026-11-03): v2 (own step scripts as the slider callback) also stuck the sliders, so
every slider calls the stock step script again. Instead dadmod_stick_watch (spawned when a color or
scale menu opens, one at a time) checks the stick each frame and switches the stock increment globals
between 1 and 6; it stops and resets them to 1 when the sliders are gone.

Color tag only when in use (2026-11-03): dadmod_es_color_in_use hides the tag when the part (for the
skater's sex) isn't worn or is none, hides Hair color while a hat is on, and shows Hat Hair color only
while a hat is on.
  A small right_arrow sprite (dadmod_tag_arrow) sits left of the tag while the option is focused and the tag is not picked.

Section lines (2026-11-03): each group header (except the first) gets a thin white line along its top edge (dadmod_es_section_line, alpha 0.4).
  Group headers are centered (make_thugpro_menu_item centered flag).

Groups everywhere (2026-11-03): Deck Options got groups (BOARD, GRIP TAPE, TRUCKS, WHEELS); Offline Only
(hide_unsafe_parts.py) got BODY / HEADS / TORSOS / ACCESSORIES / PANTS headers and orange ped text; the main
Edit Skater menu (offline.q edit_skater_main_entries, entries with "header") got SKATER / PARTS /
SIZE AND GRAPHICS / QUICK / OFFLINE, centered with section lines.

Offline Only removed (2026-11-03): the menu entry is gone (it crashed with custom menu levels). Parts that other
players may not have stay hidden from the normal lists (hide_unsafe_parts.py still runs). Face Mapping moved to SKATER.
Offline Only fully removed (2026-11-03, Noah): the Offline Only part menu, its options list, the dadmod_offline
part flag and the Play Online guard (dadmod_play_online_guard) are gone; Play Online calls stock
select_network_play_multi again. Backups: *.before_20261103_offlinegone.

Main Edit Skater menu back to stock look (2026-11-03): no headers or section lines; stock order, then Remove Clothes last.

2026-11-07: the color tag also hides when the part is a bare/empty piece (dadmod_es_bare_descs: none, null,
Hands = no gloves, BareFeet = no shoes). The Female Shirt list gets a "Null" item (removeitems.q
dadmod_part_clear_item / dadmod_clear_part) that clears skater_f_torso with the stock ClearPart edit,
the same thing the stock ped heads do to hidden parts, so other players' games handle it.

Backpack lists turn the skater around (2026-11-07): dadmod_turn_check (in dadmod_part_menu_ready) spins the skater 180
for dadmod_turn_parts; dadmod_turn_back (in dadmod_part_menu_back) spins back.

2026-11-07: female shirt list has no "Remove Shirt" (Sport Bra is the same) and no "Null": ClearPart on skater_f_torso just
falls back to the Sport Bra, which is the torso base. dadmod_clear_items is empty but kept for later.

2026-11-07: the selected marker survives the menu highlight styles. The bracket highlight (menuui/hlstyle.q)
redraws the focused item's text every 0.1s from its dadmod_txt / dadmod_plain tags, which wiped the marker one frame
after X. dadmod_mark_set_text now writes the marked text into those tags and re-runs dadmod_hl_brackets.

2026-11-07: male shirt list has no "Remove Shirt" either; the stock Shirtless item does the same thing.

2026-11-07: second color tag. Sleeves Color and Shoelace Color are no longer their own options: the shirt / shoes
item shows "color  sleeves" (or "color  laces"), Right steps color -> sleeves, Left steps back (dadmod_es_side, side 0/1/2;
gen_mixmatch.py fold_color_parts adds dadmod_extra to the item). Grip Tape / Truck / Wheel Color and the Pack Color twins
are dropped: their own item's color tag colors the same part.

2026-11-07: "adjust" tag. Each Adjust option (front/back logo, tattoo positions) is now a tag on its logo / tattoo
item instead of its own line: "Shirt Front Logo   adjust", "Chest Tattoo   color  adjust". A logo item (no color tag)
shows only "adjust". dadmod_extra = { label dx run params } ("script" is a QB keyword, it can't be a key) (gen_mixmatch.py extra_tag) runs its script on that side.

All own code (2026-11-18, Noah: "rewrite those casmod scripts into dadmod"). The Edit Skater qb used to carry copies of THUG
Pro's skate shop scripts and option lists (gen_mixmatch.py / gen_partmenu.py read decompiled_vanilla), so the installer had to
rebuild it from each player's Skateshop_scripts.prx and failed on any other version (CAS mods, newer Kali). Now:
  - lists.q: our own option lists (short rows: t text, p parts [male female], sex = m/f/p/l text color, lp logo parts,
    x = sleeves/laces/adjust second tag, xt its title, xc its color parts, sz scale bone group, cam, cb back camera, ok
    allowed boards, pre ped desc prefix, mo male only, hdr group header). dadmod_es_row turns a row into a menu item.
  - menus.q: our own options / part / color / scale menus (dadmod_es_*). They keep the stock menu names (edit_skater_options,
    edit_skater_part, edit_skater_color, scaling) because the menu camera and menu_order.txt key on them. They call the
    player's own cas_set_part (via dadmod_set_part, which adds the hair-color keep and Null-pants step after it and refreshes
    again if either changed something), thugpro_scaling_menu_add_options_to_menu and create_part_cas_pos_menu.
    Helper bars are built at run time from dadmod_help_words (dadmod_help_build; also sets generic_helper_text_cas and
    generic_helper_text_color_menu, which the stock Edit Skater menu and the Adjust menu use).
  - mainmenu/casidle.q: our own SkateshopCasIdle (camera + idle anims per screen, keeps a frozen skater paused).
  - sexchange.q reads the new sex's base parts from the game's own default skaters (appearance_custom_skater_male_06 /
    appearance_custom_skater_female) instead of a copy of them.
  - launch_pre_cas_menu and confirm_skater_sexchange are no longer replaced: the player's own versions run.
  - The old color/scale step scripts (unused since the v3 analog sliders) are gone.
Check: no 32-byte run of the built qb occurs in THUG Pro / Kali scripts (client package audit, tools/stock_audit.py).
The client package ships data\dadmod_casidle.qb as a normal file (no recipe).
