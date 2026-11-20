/obj/item/robot_module/cargo
	added_channels = list(RADIO_CHANNEL_SUPPLY = 1)

/obj/item/robot_module/syndicatejack
	added_channels = list(RADIO_CHANNEL_SYNDICATE = 1) // Probably already handled by other code when spawned with pre-set module, but whatever.

/obj/item/robot_module/standard/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // Spawn with the default skin, no radial UI.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/stand_skin_profiles
	if(!stand_skin_profiles)
		stand_skin_profiles = list(
			"Standard" = list(
				"cyborg_base_icon" = "robot",
				"cyborg_icon_override" = 'icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "robot")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_sd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_sd")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_standard",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_standard")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_standard",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_standard")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinasd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "marinasd")
			),
			"Heavy" = list(
				"cyborg_base_icon" = "heavysd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "heavysd")
			),
			"Eyebot" = list(
				"cyborg_base_icon" = "eyebotsd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "eyebotsd")
			),
			"RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_sd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_sd")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootystandard",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandard")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootystandardM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandardM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootystandardS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandardS")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-clerc",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-clerc")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_standard",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_standard")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy")
			),
			"Robo-Brain" = list(
				"cyborg_base_icon" = "robobrain",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robobrain")
			),
			"Cyclone" = list(
				"cyborg_base_icon" = "cyclone",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "cyclone")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor-b")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahanclown",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanclown")
			)
		)
	var/static/list/stand_icons
	if(!stand_icons)
		stand_icons = get_borg_skin_preview_icons(stand_skin_profiles)
		stand_icons = sort_list(stand_icons)

	var/list/selectable_stand_icons = get_selectable_borg_icons(stand_icons, R.client)
	var/stand_borg_icon = show_radial_menu(R, R , selectable_stand_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(!stand_borg_icon)
		return
	if(apply_donator_borg_icon(stand_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	var/list/skin_profile = stand_skin_profiles[stand_borg_icon]
	if(skin_profile)
		apply_borg_skin_profile(skin_profile)
	return ..()

/obj/item/robot_module/clown/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // Spawn with the default skin, no radial UI.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/clown_skin_profiles
	if(!clown_skin_profiles)
		clown_skin_profiles = list(
			"Standard" = list(
				"cyborg_base_icon" = "clown",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "clown")
			),
			"ClownMan" = list(
				"cyborg_base_icon" = "clownman",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "clownman")
			),
			"ClownBot" = list(
				"cyborg_base_icon" = "clownbot",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "clownbot")
			),
			"Garish" = list(
				"cyborg_base_icon" = "garish",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "garish")
			),
			"Clowne" = list(
				"cyborg_base_icon" = "clownkeep",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "clownkeep")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marina_mommy",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "marina_mommy")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootyclown",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandard")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootyclownM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandardM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootyclownS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootystandardS")
			),
			"Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaurclown",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaurclown")
			),
			"Kitty Clown" = list(
				"cyborg_base_icon" = "kittyclown",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/kitty_clown.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/kitty_clown.dmi', icon_state = "kittyclown")
			)
		)
	var/static/list/clown_icons
	if(!clown_icons)
		clown_icons = get_borg_skin_preview_icons(clown_skin_profiles)
		clown_icons = sort_list(clown_icons)

	var/list/selectable_clown_icons = get_selectable_borg_icons(clown_icons, R.client)
	var/clown_borg_icon = show_radial_menu(R, R , selectable_clown_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(!clown_borg_icon)
		return
	if(apply_donator_borg_icon(clown_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	var/list/skin_profile = clown_skin_profiles[clown_borg_icon]
	if(skin_profile)
		apply_borg_skin_profile(skin_profile)
	return ..()

/// Cargo Borgs! ///
/obj/item/robot_module/cargo
	name="Cargo"
	basic_modules = list(
		/obj/item/stamp,
		/obj/item/stamp/denied,
		/obj/item/pen,
		/obj/item/clipboard/cyborg,
		/obj/item/stack/packageWrap/cyborg,
		/obj/item/stack/wrapping_paper/xmas/cyborg,
		/obj/item/assembly/flash/cyborg,
		/obj/item/hand_labeler/cyborg,
		/obj/item/dest_tagger,
		/obj/item/crowbar/cyborg,
		/obj/item/extinguisher,
		/obj/item/export_scanner,
		/obj/item/gripper,
		/obj/item/cyborg_clamp,
		/obj/item/gps/cyborg
	)
	emag_modules = list(
		/obj/item/stamp/chameleon,
		/obj/item/borg/stun
	)
	cyborg_base_icon = "cargoborg"
	moduleselect_icon = "cargo"
	moduleselect_alternate_icon = 'modular_splurt/icons/mob/screen_cyborg.dmi'
	hat_offset = 3

/obj/item/robot_module/cargo/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // Spawn with the default skin, no radial UI.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/cargo_skin_profiles
	if(!cargo_skin_profiles)
		cargo_skin_profiles = list(
			"Default" = list(
				"cyborg_base_icon" = "cargoborg",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_cargo.dmi',
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "cargoborg")
			),
			"Bird" = list(
				"cyborg_base_icon" = "bird_cargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_cargo.dmi',
				"hat_offset" = 4,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "bird_cargo")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_cargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_cargo.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "missm_cargo")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_cargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_cargo.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "zoomba_cargo")
			),
			"Cargohound" = list(
				"cyborg_base_icon" = "cargohound",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_splurt/icons/mob/widerobots_cargo.dmi', "cargohound", -16)
			),
			"Cargohound Dark" = list(
				"cyborg_base_icon" = "cargohounddark",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_splurt/icons/mob/widerobots_cargo.dmi', "cargohounddark", -16)
			),
			"Vale" = list(
				"cyborg_base_icon" = "valecargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_splurt/icons/mob/widerobots_cargo.dmi', "valecargo", -16)
			),
			"Borgi" = list(
				"cyborg_base_icon" = "borgi-cargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobots_cargo.dmi', icon_state = "borgi-cargo")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakecargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobots_cargo.dmi', icon_state = "drakecargo")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_cargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_cargo.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "assaultron_cargo")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekacargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekacargo")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekacargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekacargo")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekacargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekacargo")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tcargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tcargo")
			),
			"K4T (alt)" = list(
				"cyborg_base_icon" = "k4tcargo_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tcargo_alt1")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixcargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobots_cargo.dmi',
				"sleeper_overlay" = "vixcargo-sleeper",
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_splurt/icons/mob/widerobots_cargo.dmi', "vixcargo", -16)
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "caraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "caraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "caraptor-b")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_crg",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_crg-b")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahancargo",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahancargo")
			),
			"Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaurcargo",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaurcargo")
			)
		)
	var/static/list/cargo_icons
	if(!cargo_icons)
		cargo_icons = get_borg_skin_preview_icons(cargo_skin_profiles)

	var/list/selectable_cargo_icons = get_selectable_borg_icons(cargo_icons, R.client)
	var/cargo_borg_icon = show_radial_menu(R, R , selectable_cargo_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(!cargo_borg_icon)
		return
	if(apply_donator_borg_icon(cargo_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(cargo_skin_profiles[cargo_borg_icon]))
		return FALSE
	return ..()
/// End Cargo Borg ///

/obj/item/robot_module/Initialize()
	basic_modules += /obj/item/sucking_machine/pleasuremaw
	. = ..()

/obj/item/robot_module/syndicate_medical/slaver
	name = "Slaver Medical Combat"

/obj/item/robot_module/syndicate_medical/slaver/Initialize()
	var/list/extra_tools = list(
		/obj/item/slaver/gizmo
	)
	LAZYADD(basic_modules, extra_tools)
	. = ..()

/obj/item/robot_module/medical/Initialize()
	var/list/extra = list(
		/obj/item/dogborg/jaws/small,
		/obj/item/storage/bag/borgdelivery,
		/obj/item/analyzer/nose,
		/obj/item/soap/synthtongue,
		/obj/item/shockpaddles/cyborg/hound
	)
	LAZYADD(basic_modules, extra)
	. = ..()

/obj/item/robot_module/peacekeeper/Initialize()
	var/list/extra = list(
		/obj/item/dogborg/jaws/small,
		/obj/item/storage/bag/borgdelivery,
		/obj/item/analyzer/nose,
		/obj/item/soap/synthtongue
	)
	LAZYADD(basic_modules, extra)
	. = ..()

/obj/item/robot_module/security/Initialize()
	var/list/extra = list(
		/obj/item/storage/bag/borgdelivery,
		/obj/item/dogborg/jaws/big,
		/obj/item/dogborg/pounce,
		/obj/item/soap/synthtongue,
		/obj/item/analyzer/nose,
		/obj/item/holosign_creator/security
	)
	LAZYADD(basic_modules, extra)
	. = ..()

/obj/item/robot_module/butler/Initialize()
	var/list/extra = list(
		/obj/item/dogborg/jaws/small,
		/obj/item/analyzer/nose,
		/obj/item/soap/synthtongue/scrubpup,
		/obj/item/gripper/service,
		/obj/item/kitchen/rollingpin,
		/obj/item/kitchen/unrollingpin,
		/obj/item/kitchen/knife/butcher,
		/obj/item/kitchen/efink,
		/obj/item/kitchen/knife
	)
	LAZYADD(basic_modules, extra)
	. = ..()

/obj/item/robot_module/roleplay/Initialize()
	LAZYREMOVE(basic_modules, /obj/item/extinguisher/mini)
	var/list/extra = list(
		/obj/item/extinguisher,
		/obj/item/lightreplacer/cyborg,
		/obj/item/healthanalyzer/advanced,
		/obj/item/reagent_containers/borghypo
	)
	LAZYADD(basic_modules, extra)
	. = ..()


