/obj/item/clothing/neck/eldritch_amulet
	mob_overlay_icon = 'modular_bluemoon/icons/obj/heretic_medallion_worn.dmi'
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_righthand.dmi'

/obj/item/clothing/neck/eldritch_amulet/update_icon_state()
	. = ..()
	icon_state = "watching_eye_closed"
	if(!ishuman(loc))
		return
	var/mob/living/carbon/human/wearer = loc
	if(wearer.wear_neck == src && HAS_TRAIT_FROM(wearer, trait, REF(src)))
		icon_state = trait == TRAIT_XRAY_VISION ? "watching_eye_open" : "watching_eye"
	wearer.update_inv_neck()
	wearer.update_inv_hands()

/datum/heretic_path
	var/robe_state
	var/robe_worn_icon
	var/hood_worn_icon
	var/robe_tint = "#ffffff"

/datum/heretic_path/ash
	robe_state = "ash_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_ash_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_ash_worn.dmi'

/datum/heretic_path/rust
	robe_state = "rust_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_rust_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_rust_worn.dmi'

/datum/heretic_path/flesh
	robe_state = "flesh_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_flesh_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_flesh_worn.dmi'

/datum/heretic_path/void
	robe_state = "void_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_void_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_void_worn.dmi'

/datum/heretic_path/blade
	robe_state = "blade_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_blade_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_blade_worn.dmi'

/datum/heretic_path/moon
	robe_state = "moon_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_moon_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_moon_worn.dmi'

/datum/heretic_path/cosmic
	robe_state = "cosmic_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_cosmic_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_cosmic_worn.dmi'

/datum/heretic_path/lock
	robe_state = "lock_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_lock_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_lock_worn.dmi'

/datum/heretic_path/tide
	robe_state = "tide_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_tide_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_tide_worn.dmi'

/obj/item/clothing/suit/hooded/cultrobes/eldritch
	var/robe_path

/datum/heretic_path/glass
	robe_state = "glass_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_glass_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_glass_worn.dmi'

/datum/heretic_path/blood
	robe_state = "blood_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_blood_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_blood_worn.dmi'

/datum/heretic_path/echo
	robe_state = "echo_armor"
	robe_worn_icon = 'modular_bluemoon/icons/obj/heretic_robes_echo_worn.dmi'
	hood_worn_icon = 'modular_bluemoon/icons/obj/heretic_hoods_echo_worn.dmi'

/obj/item/melee/sickly_blade/echo
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_echo_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_echo_righthand.dmi'
	// Рисунок привязан к верхнему левому углу, без полей старого серпа.
	held_offset_x = 8
	held_offset_y = -2

/obj/item/melee/sickly_blade/glass
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_glass_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_glass_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	held_offset_x = 0
	held_offset_y = 0

/obj/item/melee/sickly_blade/blood
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_blood_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_blood_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	held_offset_x = 0
	held_offset_y = 0

/obj/item/clothing/suit/hooded/cultrobes/eldritch/equipped(mob/user, slot)
	. = ..()
	attune_robes(user)

/// Мантия сохраняет облик на полу и принимает путь следующего еретика при надевании.
/obj/item/clothing/suit/hooded/cultrobes/eldritch/proc/attune_robes(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
	if(!path?.robe_state || robe_path == path.id)
		return FALSE
	robe_path = path.id
	icon = 'modular_bluemoon/icons/obj/heretic_robes.dmi'
	mob_overlay_icon = path.robe_worn_icon
	color = path.robe_tint
	if(hood)
		hood.icon = 'modular_bluemoon/icons/obj/heretic_hoods.dmi'
		hood.mob_overlay_icon = path.hood_worn_icon
		hood.color = color
		hood.icon_state = path.robe_state
		hood.item_state = null
		hood.update_icon()
	update_icon()
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		wearer.update_inv_wear_suit()
		wearer.update_inv_head()
		wearer.update_inv_hands()
	return TRUE

/obj/item/clothing/suit/hooded/cultrobes/eldritch/update_icon_state()
	var/datum/heretic_path/path = GLOB.heretic_paths[robe_path]
	if(!path?.robe_state)
		return ..()
	icon_state = path.robe_state
	if(ishuman(hood?.loc))
		var/mob/living/carbon/human/wearer = hood.loc
		if(wearer.head == hood)
			icon_state += "_t"
	// В руках сохраняется существующий спрайт свёрнутой мантии.
	item_state = initial(item_state)

/datum/eldritch_knowledge/armor/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = new(loc)
	robes.attune_robes(user)
	return TRUE

/datum/antagonist/heretic/proc/attune_robes(mob/user)
	for(var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes in user.GetAllContents(/obj/item/clothing/suit/hooded/cultrobes/eldritch))
		robes.attune_robes(user)

/obj/item/melee/sickly_blade/ash
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_ash_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_ash_righthand.dmi'

/obj/item/melee/sickly_blade/rust
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_rust_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_rust_righthand.dmi'

/obj/item/melee/sickly_blade/flesh
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_flesh_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_flesh_righthand.dmi'

/obj/item/melee/sickly_blade/void
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_void_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_void_righthand.dmi'

/obj/item/melee/sickly_blade/duelist
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_blade_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_blade_righthand.dmi'

/obj/item/melee/sickly_blade/moon
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_moon_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_moon_righthand.dmi'

/obj/item/melee/sickly_blade/cosmic
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_cosmic_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_cosmic_righthand.dmi'

/obj/item/melee/sickly_blade
	var/held_offset_x = -1
	var/held_offset_y = -6

/obj/item/melee/sickly_blade/lock
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_lock_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_lock_righthand.dmi'

/obj/item/melee/sickly_blade/tide
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_tide_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_tide_righthand.dmi'
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	held_offset_x = 0
	held_offset_y = 0

/obj/item/melee/sickly_blade/tide/update_overlays()
	. = ..()
	var/mutable_appearance/glimmer = mutable_appearance(icon, "tide_blade_glow")
	glimmer.color = "#91e8e0"
	glimmer.alpha = 160
	. += glimmer

/obj/item/clothing/suit/hooded/cultrobes/eldritch/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(isinhands || robe_path != PATH_TIDE)
		return
	var/mutable_appearance/bubbles = mutable_appearance('modular_bluemoon/icons/obj/heretic_tide_effects.dmi', "tide_grasp")
	bubbles.appearance_flags = RESET_COLOR | PIXEL_SCALE
	bubbles.color = "#8adbd4"
	bubbles.alpha = 130
	bubbles.transform = matrix() * 0.5
	bubbles.pixel_y = 3
	. += bubbles

/obj/item/melee/sickly_blade/build_worn_icon(default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state, style_flags = NONE, use_mob_overlay_icon = TRUE, alpha_mask)
	var/mutable_appearance/held = ..()
	if(isinhands && held)
		// Компенсируем обрезку прозрачных полей исходного полотна 64x64.
		held.pixel_x += held_offset_x
		held.pixel_y += held_offset_y
	return held
