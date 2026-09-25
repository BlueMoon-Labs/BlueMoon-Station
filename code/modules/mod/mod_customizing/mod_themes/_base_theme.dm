/// Global proc that sets up all MOD themes as singletons in a list and returns it.
/proc/setup_mod_themes()
	. = list()
	for(var/path in typesof(/datum/mod_theme))
		var/datum/mod_theme/new_theme = new path()
		.[path] = new_theme

/// MODsuit theme, instanced once and then used by MODsuits to grab various statistics.
/datum/mod_theme
	/// Theme name for the MOD.
	var/name = "standard"
	/// Description added to the MOD.
	var/desc = "Гражданский костюм от Nakamura Engineering, не предлагает многого, кроме немного более быстрого передвижения."
	/// Extended description on examine_more
	var/extended_desc = "Модульный костюм третьего поколения от Nakamura Engineering, \
		этот костюм является основным выбором по всей галактике для гражданских применений. Эти костюмы обеспечивают кислород, \
		пригодны для космоса, устойчивы к огню и химическим угрозам, и иммунизированы против всего — \
		от чихания до биологического оружия. Однако их боевые применения крайне минимальны, так как по умолчанию \
		не установлена бронепластина, а их приводы лишь немного увеличивают скорость по сравнению с обычной."
	/// Default skin of the MOD.
	var/default_skin = "standard"
	/// Armor shared across the MOD pieces.
	var/armor = /datum/armor/mod
	/// Resistance flags shared across the MOD pieces.
	var/resistance_flags = NONE
	/// Max heat protection shared across the MOD pieces.
	var/max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	/// Max cold protection shared across the MOD pieces.
	var/min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	/// Permeability shared across the MOD pieces.
	var/permeability_coefficient = 0.01
	/// Siemens shared across the MOD pieces.
	var/siemens_coefficient = 0.5
	/// How much modules can the MOD carry without malfunctioning.
	var/complexity_max = DEFAULT_MAX_COMPLEXITY
	/// How much battery power the MOD uses by just being on
	var/cell_drain = DEFAULT_CHARGE_DRAIN
	/// Slowdown of the MOD when not active.
	var/slowdown_inactive = 0
	/// Slowdown of the MOD when active.
	var/slowdown_active = 0
	/// Theme used by the MOD TGUI.
	var/ui_theme = "ntos"
	/// Allowed items in the chestplate's suit storage.
	var/list/allowed = ALLOWED_DEFAULT
	/// List of inbuilt modules. These are different from the pre-equipped suits, you should mainly use these for unremovable modules with 0 complexity.
	var/list/inbuilt_modules = list()
	/// Modules blacklisted from the MOD.
	var/list/module_blacklist = list()
	var/hardlight_color = MOD_STANDART_COLOR
	var/datum/overlay_effect/hardlight_effect = /datum/overlay_effect/mod_effect
	var/max_armor_module_count = 2
	var/can_activate_without_deploy_all_parts = TRUE
	var/need_block_storage_when_not_active = FALSE
	var/compatible_with_armor_modules = TRUE
	var/overwrite_desc = FALSE
	/// List of skins with their appropriate clothing flags.
	var/list/skins = list(
		"standard" = MOD_PRESET_DEFAULT,
		"civilian" = MOD_PRESET_DEFAULT,
		"lustwish" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/proc/apply_theme_stats(obj/item/mod/control/modsuit, new_skin)
	for(var/obj/item/piece in modsuit.get_mod_parts(include_cell = FALSE, include_mod = TRUE))
		piece.normal_set_armor(armor)
		piece.resistance_flags = resistance_flags
		piece.heat_protection = NONE
		piece.cold_protection = NONE
		piece.max_heat_protection_temperature = max_heat_protection_temperature
		piece.min_cold_protection_temperature = min_cold_protection_temperature
		piece.permeability_coefficient = permeability_coefficient
		piece.siemens_coefficient = siemens_coefficient

	var/obj/item/clothing/mod_part/suit/chestplate = modsuit.get_chestplate()
	modsuit.max_armor_module_count = max_armor_module_count
	modsuit.slowdown_inactive = slowdown_inactive
	modsuit.slowdown_active = slowdown_active
	chestplate.allowed += allowed

/datum/mod_theme/proc/apply_theme_skin(obj/item/mod/control/modsuit, new_skin)
	modsuit.skin = new_skin || default_skin
	modsuit.ui_theme = ui_theme
	for(var/obj/item/piece in modsuit.get_mod_parts(include_cell = FALSE, include_mod = TRUE))
		piece.name = "[name] [piece.name]"
		piece.desc = "[piece.desc] [desc]"
		if(overwrite_desc) //Если кого-то из донатеров будет корёжить, что их "особое" описание совмещается с дефолтным, от куска МОДа.
			piece.desc = "[desc]"
		piece.icon_state = "[modsuit.skin]-[initial(piece.icon_state)]"
		piece.item_state = "[modsuit.skin]-[initial(piece.item_state)]"

/datum/mod_theme/proc/setup_theme(obj/item/mod/control/modsuit, new_skin, need_update_stat = TRUE)
	apply_theme_skin(modsuit, new_skin)
	if(!need_update_stat)
		return TRUE
	modsuit.extended_desc = extended_desc
	modsuit.complexity_max = complexity_max
	modsuit.cell_drain = cell_drain
	modsuit.initial_modules += inbuilt_modules
	modsuit.hardlight_effect = new hardlight_effect

	var/datum/overlay_effect/mod_effect = modsuit.hardlight_effect
	mod_effect.apply_color(hardlight_color)
	apply_theme_stats(modsuit, new_skin)
	return TRUE

/datum/mod_theme/simple_civilian
	cell_drain = CIVILIAN_LOW_CHARGE_DRAIN

/datum/mod_theme/engineering
	allowed = ALLOWED_ENGINERING
	siemens_coefficient = 0

/datum/mod_theme/engineering/fire_protected
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/datum/mod_theme/cargo_default
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cell_drain = VERY_HIGHT_CHARGE_DRAIN
	hardlight_color = MOD_CARGO_BLUE
	allowed = ALLOWED_CARGO

/datum/mod_theme/centcom
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	allowed = ALLOWED_SECURITY
	complexity_max = CENTCOM_MAX_COMPLEXITY
	hardlight_color = MOD_COMMAND_COLOR

/datum/mod_theme/station_combat
	siemens_coefficient = 0
	allowed = ALLOWED_SECURITY
	hardlight_color = MOD_SEC_COLOR
	resistance_flags = FIRE_PROOF|ACID_PROOF
	complexity_max = STATION_COMBAT_MAX_COMPLEXITY
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT

/datum/mod_theme/station_medbay
	allowed = ALLOWED_MEDICAL
	resistance_flags = FIRE_PROOF|ACID_PROOF
	hardlight_color = MOD_MEDBAY_COLOR
	cell_drain = CIVILIAN_LOW_CHARGE_DRAIN
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT

/datum/mod_theme/antagonist
	complexity_max = ANTAG_MAX_COMPLEXITY
	siemens_coefficient = 0
	allowed = ALLOWED_ANTAG
	compatible_with_armor_modules = FALSE
	hardlight_effect = /datum/overlay_effect/mod_effect/white_noize
