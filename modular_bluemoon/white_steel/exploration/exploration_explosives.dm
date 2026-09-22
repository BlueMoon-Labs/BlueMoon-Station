/obj/item/grenade/exploration
	name = "Breaching charge"
	desc = "Used by vanguard mercenarys for breaching. Requires detonation device nearby to work"
	icon_state = "plasticexp-explosive0"
	item_state = "sheet-plastitaniumglass"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'
	item_flags = NOBLUDGEON
	flags_1 = NONE
	w_class = WEIGHT_CLASS_SMALL
	var/atom/target = null
	var/mutable_appearance/plastic_overlay
	var/light_exp_range = 5
	var/heavy_range = 2
	var/devastation_range = 0
	var/list/attached_detonators = list()

/obj/item/grenade/exploration/Initialize()
	. = ..()
	plastic_overlay = mutable_appearance(icon, "[icon_state]", HIGH_OBJ_LAYER)

/obj/item/grenade/exploration/Destroy()
	for(var/obj/item/exploration_detonator/detonator in attached_detonators)
		detonator.linked_explosives -= src
	attached_detonators = null
	. = ..()

/obj/item/grenade/exploration/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/exploration_detonator))
		var/obj/item/exploration_detonator/detonator = W
		detonator.linked_explosives |= src
		attached_detonators |= detonator
		to_chat(user, span_notice("Связываю [src] и [W]."))
		return
	. = ..()

/obj/item/grenade/exploration/afterattack(atom/movable/AM, mob/user, flag)
	. = ..()

	if(!length(attached_detonators))
		to_chat(user, span_notice("[src] должен быть связан с детонатором сначала!"))
		return

	if(!flag)
		return
	if(ismob(AM))
		return

	to_chat(user, span_notice("Начинаю устанавливать [src]."))

	if(do_after(user, 30, target = AM))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return
		target = AM

		message_admins("[ADMIN_LOOKUPFLW(user)] planted [name] on [target.name] at [ADMIN_VERBOSEJMP(target)]")
		log_game("[key_name(user)] planted [name] on [target.name] at [AREACOORD(user)]")

		notify_ghosts("[user] устанавливает [src] на [target]!", source = target, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Щас бахнет")

		moveToNullspace()	//Yep

		if(istype(AM, /obj/item)) //your crappy throwing star can't fly so good with a giant brick of c4 on it.
			var/obj/item/I = AM
			I.throw_speed = max(1, (I.throw_speed - 3))
			I.throw_range = max(1, (I.throw_range - 3))
			if(I.embedding)
				I.embedding["embed_chance"] = 0
				I.updateEmbedding()
		else if(istype(AM, /mob/living))
			plastic_overlay.layer = FLOAT_LAYER

		target.add_overlay(plastic_overlay, TRUE)
		to_chat(user, span_notice("Устанавливаю заряд."))

/obj/item/grenade/exploration/attack_self(mob/user)
	if(QDELETED(src))
		return
	to_chat(user, span_warning("[src] не взводится в руке. Установи заряд на поверхность и подорви его детонатором."))

/obj/item/grenade/exploration/prime(mob/living/lanced_by)
	if(QDELETED(src))
		return
	SEND_SIGNAL(src, COMSIG_GRENADE_PRIME, lanced_by)
	var/turf/location
	if(target)
		if(!QDELETED(target))
			location = get_turf(target)
			target.cut_overlay(plastic_overlay, TRUE)
			target.ex_act(EXPLODE_HEAVY, target)
	else if(!QDELETED(src))
		location = get_turf(src)
	if(location)
		log_game("[key_name(lanced_by)] detonated [name] at [AREACOORD(location)].")
		explosion(location, devastation_range, heavy_range, light_exp_range, attacker = lanced_by)
	if(isliving(target) && !QDELETED(target))
		var/mob/living/M = target
		M.gib()
	qdel(src)

/obj/item/exploration_detonator
	name = "Detonation device"
	desc = "One crosed wire... and CABLOOE!"
	icon = 'modular_bluemoon/white/valtos/icons/objects.dmi'
	icon_state = "detonator"
	w_class = WEIGHT_CLASS_SMALL
	var/range = 16
	var/list/linked_explosives = list()

/obj/item/exploration_detonator/Destroy()
	. = ..()
	for(var/obj/item/grenade/exploration/explosive in linked_explosives)
		explosive.attached_detonators -= src
	linked_explosives = null

/obj/item/exploration_detonator/attack_self(mob/user)
	. = ..()
	if(.)
		return
	var/turf/user_turf = get_turf(user)
	if(!user_turf)
		return
	var/explosives_trigged = 0
	var/station_blocked = FALSE
	for(var/obj/item/grenade/exploration/exploration in linked_explosives)
		if(QDELETED(exploration) || QDELETED(exploration.target))
			continue
		var/turf/target_turf = get_turf(exploration.target)
		if(isnull(target_turf) || target_turf.z != user_turf.z)
			continue
		if(is_station_level(target_turf.z) && !(obj_flags & EMAGGED))
			station_blocked = TRUE
			continue
		if(get_dist(exploration.target, user) <= range)
			addtimer(CALLBACK(exploration, TYPE_PROC_REF(/obj/item/grenade/exploration, prime), user), 10)
			explosives_trigged ++
	if(station_blocked)
		to_chat(user, span_warning("Файрволл станции блокирует подрыв зарядов, установленных на станции."))
	to_chat(user, span_notice("[explosives_trigged] зарядов было активировано."))

/obj/item/exploration_detonator/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, "<span class'warning'>Взламываю протоколы безопасности [src]. Теперь эта штука может взрывать и на станции.</span>")
