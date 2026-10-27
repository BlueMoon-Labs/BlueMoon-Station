/obj/item/mod/control/pre_equipped/holographic
	theme = /datum/mod_theme/holographic

/obj/item/mod/control/pre_equipped/holographic/Initialize(mapload, new_theme, new_skin)
	. = ..()
	name = "Holographic MOD"

/obj/item/mod/control/build_worn_icon(default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state, style_flags = NONE, use_mob_overlay_icon = TRUE, alpha_mask)
	if(!isinhands && theme?.hide_worn_sprites && !visual_skin)
		return mutable_appearance('icons/effects/effects.dmi', "nothing", layer = -default_layer)
	return ..()

/obj/item/clothing/mod_part/build_worn_icon(default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state, style_flags = NONE, use_mob_overlay_icon = TRUE, alpha_mask)
	if(!isinhands && mod?.theme?.hide_worn_sprites && !mod.visual_skin && !paint_skin)
		return mutable_appearance('icons/effects/effects.dmi', "nothing", layer = -default_layer)
	return ..()

/obj/item/mod/module/holographic
	name = "MOD holographic field projector"
	desc = "Создаёт герметичный голографический костюм без теплоизоляции."
	icon_state = "rad_protection"
	removable = FALSE

/obj/item/mod/module/holographic/on_install()
	. = ..()
	mod.need_to_conseal |= GLOB.body_hardlight_layers
	mod.need_to_conseal |= GLOB.mutant_overlay_layers

