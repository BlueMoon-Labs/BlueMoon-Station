//Мультитул переключает режимы на месте, а не пересоздаёт себя. Подмена объекта рвала всё,
//что держит ссылку именно на этот предмет: семейную реликвию, цели антагонистов, отпечатки,
//закладки в сумке. Так же сделаны медицинские инструменты третьего поколения.
#define ARMYKNIFE_FOLDED 1
#define ARMYKNIFE_SCREWDRIVER 2
#define ARMYKNIFE_WIRECUTTER 3
#define ARMYKNIFE_BLADE 4
///Складные отвёртка и кусачки медленнее полноценного инструмента - так было и до переделки.
#define ARMYKNIFE_TOOL_SPEED 1.1

/obj/item/armyknife
	name = "Army Multitool"
	desc = "Нехитрый инструмент с ножичком, отвёрткой и кусачками. Сейчас всё сложено."
	icon_state = "armyknife_fold"
	icon = 'modular_splurt/icons/obj/items_and_weapons.dmi'
	custom_materials = list(/datum/material/iron=300, /datum/material/plastic=300)
	force = 2
	w_class = WEIGHT_CLASS_TINY
	throwforce = 3
	throw_speed = 4
	throw_range = 5
	attack_verb = list("whacked")
	hitsound = 'sound/weapons/genhit.ogg'
	usesound = list('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg')
	///Текущий разложенный инструмент, см. ARMYKNIFE_*.
	var/mode = ARMYKNIFE_FOLDED

/obj/item/armyknife/Initialize(mapload)
	. = ..()
	set_mode(mode)

/obj/item/armyknife/attack_self(mob/user)
	playsound(get_turf(user), 'sound/weapons/batonextend.ogg', 50, 1)
	switch(mode)
		if(ARMYKNIFE_FOLDED)
			set_mode(ARMYKNIFE_SCREWDRIVER)
			to_chat(user, span_notice("Вы раскладываете отвёртку."))
		if(ARMYKNIFE_SCREWDRIVER)
			set_mode(ARMYKNIFE_WIRECUTTER)
			to_chat(user, span_notice("Вы складываете отвёртку и раскладываете кусачки."))
		if(ARMYKNIFE_WIRECUTTER)
			set_mode(ARMYKNIFE_BLADE)
			to_chat(user, span_notice("Вы складываете кусачки и раскладываете нож."))
		else
			set_mode(ARMYKNIFE_FOLDED)
			to_chat(user, span_notice("Вы складываете нож."))
	add_fingerprint(user)

/obj/item/armyknife/proc/set_mode(new_mode)
	mode = new_mode
	//Общее для всех режимов, дальше каждый переопределяет своё.
	flags_1 &= ~CONDUCT_1
	sharpness = SHARP_NONE
	throwforce = initial(throwforce)
	toolspeed = ARMYKNIFE_TOOL_SPEED
	lefthand_file = initial(lefthand_file)
	righthand_file = initial(righthand_file)
	switch(mode)
		if(ARMYKNIFE_SCREWDRIVER)
			desc = "Нехитрый инструмент с ножичком, отвёрткой и кусачками. Сейчас разложена отвёртка."
			icon_state = "armyknife_screw"
			item_state = "screwdriver"
			lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
			righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
			force = 4
			w_class = WEIGHT_CLASS_SMALL
			tool_behaviour = TOOL_SCREWDRIVER
			attack_verb = list("stabbed", "screwed", "jabbed", "whacked")
			hitsound = 'sound/weapons/bladeslice.ogg'
			usesound = list('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg')
		if(ARMYKNIFE_WIRECUTTER)
			desc = "Нехитрый инструмент с ножичком, отвёрткой и кусачками. Сейчас разложены кусачки."
			icon_state = "armyknife_cutter"
			item_state = "cutters"
			lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
			righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
			force = 4
			w_class = WEIGHT_CLASS_SMALL
			tool_behaviour = TOOL_WIRECUTTER
			attack_verb = list("cut", "whacked")
			hitsound = 'sound/weapons/bladeslice.ogg'
			usesound = 'sound/items/wirecutter.ogg'
		if(ARMYKNIFE_BLADE)
			desc = "Нехитрый инструмент с ножичком, отвёрткой и кусачками. Сейчас разложен нож."
			icon_state = "armyknife_blade"
			item_state = "switchblade_ext"
			lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
			righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
			flags_1 |= CONDUCT_1
			force = 10
			w_class = WEIGHT_CLASS_SMALL
			throwforce = 5
			tool_behaviour = TOOL_KNIFE
			toolspeed = initial(toolspeed)
			sharpness = SHARP_EDGED
			attack_verb = list("stabbed", "slashed", "cut")
			hitsound = 'sound/weapons/bladeslice.ogg'
			usesound = list('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg')
		else
			desc = initial(desc)
			icon_state = initial(icon_state)
			item_state = initial(item_state)
			force = initial(force)
			w_class = initial(w_class)
			tool_behaviour = null
			toolspeed = initial(toolspeed)
			attack_verb = list("whacked")
			hitsound = initial(hitsound)
			usesound = list('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg')
	update_appearance()
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_inv_hands()

#undef ARMYKNIFE_FOLDED
#undef ARMYKNIFE_SCREWDRIVER
#undef ARMYKNIFE_WIRECUTTER
#undef ARMYKNIFE_BLADE
#undef ARMYKNIFE_TOOL_SPEED

/datum/design/armyknife
	name = "Army Multitool"
	id = "armyknife"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron=300, /datum/material/plastic=300)
	build_path = /obj/item/armyknife
	category = list("initial","Tools","Tool Designs")
