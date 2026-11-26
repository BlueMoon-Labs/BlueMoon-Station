GLOBAL_LIST_INIT(heretic_robe_armor, list(
	PATH_ASH = /datum/armor/heretic_ash,
	PATH_BLADE = /datum/armor/heretic_blade,
	PATH_BLOOD = /datum/armor/heretic_blood,
	PATH_COSMIC = /datum/armor/heretic_cosmic,
	PATH_DANCE = /datum/armor/heretic_dance,
	PATH_ECHO = /datum/armor/heretic_echo,
	PATH_FLESH = /datum/armor/heretic_flesh,
	PATH_GLASS = /datum/armor/heretic_glass,
	PATH_LEAD = /datum/armor/heretic_lead,
	PATH_LOCK = /datum/armor/heretic_lock,
	PATH_MOON = /datum/armor/heretic_moon,
	PATH_RUST = /datum/armor/heretic_rust,
	PATH_SAND = /datum/armor/heretic_sand,
	PATH_SPIRIT = /datum/armor/heretic_spirit,
	PATH_TIDE = /datum/armor/heretic_tide,
	PATH_VOID = /datum/armor/heretic_void,
	PATH_WAX = /datum/armor/heretic_wax,
))

/// Профиль брони мантии пути; без пути - общий.
/proc/heretic_robe_armor_type(path_id)
	return (path_id && GLOB.heretic_robe_armor[path_id]) || /datum/armor/eldritch

/// Чем броня пути отличается от общей мантии: «крепче против ..., слабее против ...».
/proc/heretic_robe_armor_traits(path_id)
	var/static/list/rating_names = list(
		MELEE = "ударов",
		BULLET = "пуль",
		LASER = "лазеров",
		ENERGY = "энергии",
		BOMB = "взрывов",
		BIO = "токсинов",
		FIRE = "огня",
		ACID = "кислоты",
	)
	var/datum/armor/profile = new_tg_get_armor_by_type(heretic_robe_armor_type(path_id))
	var/datum/armor/base = new_tg_get_armor_by_type(/datum/armor/eldritch)
	var/list/stronger = list()
	var/list/weaker = list()
	for(var/rating in rating_names)
		var/delta = profile.vars[rating] - base.vars[rating]
		if(delta > 0)
			stronger += rating_names[rating]
		else if(delta < 0)
			weaker += rating_names[rating]
	var/list/parts = list()
	if(length(stronger))
		parts += "крепче против [english_list(stronger)]"
	if(length(weaker))
		parts += "слабее против [english_list(weaker)]"
	return length(parts) ? jointext(parts, ", ") : "держит всё поровну"

/// Меняется только вклад профиля: наборы и пластины, вшитые в мантию, остаются.
/proc/heretic_swap_armor_profile(obj/item/clothing/item, new_type)
	if(isnull(item.armor))
		item.set_armor_type(new_type)
		return
	if(item.armor_type == new_type)
		return
	var/datum/armor/old_profile = new_tg_get_armor_by_type(item.armor_type)
	var/datum/armor/new_profile = new_tg_get_armor_by_type(new_type)
	item.armor_type = new_type
	var/datum/armor/modifiers = item.armor.detachArmor(old_profile)
	item.normal_set_armor(modifiers.attachArmor(new_profile))

/obj/item/clothing/suit/hooded/cultrobes/eldritch
	/// Путь, под который сейчас настроена броня; null - общая броня.
	var/armor_path

/// Броня следует за путём надевшего еретика, у остальных она общая.
/obj/item/clothing/suit/hooded/cultrobes/eldritch/proc/set_path_armor(path_id)
	armor_path = (path_id && GLOB.heretic_robe_armor[path_id]) ? path_id : null
	heretic_swap_armor_profile(src, heretic_robe_armor_type(armor_path))

/obj/item/clothing/suit/hooded/cultrobes/eldritch/examine(mob/user)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[armor_path]
	if(path)
		. += span_notice("Броня мантии настроена под путь «[path.name]»: [heretic_robe_armor_traits(path.id)].")
	else
		. += span_notice("Броня общая: еретик перекроит её под свой путь, когда возьмёт мантию.")
