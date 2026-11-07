/obj/item/hk51_frame
	name = "HK-51 frame"
	desc = "Эндоскелет дроида-ассасина HK-51 из фабрикатора робототехники. Вставьте в него пять частей с одним серийным номером - корпус, голову, приводы, вокабулятор и мотиватор, - затем активируйте собранный каркас в руке: он встанет на пол и загрузится. Кто активировал, тот и станет хозяином дроида: бронированного телохранителя с тазером в предплечье, датчиком хозяина и протоколом телохранителя. Встроенный пеленгатор показывает, где искать ближайшую недостающую часть."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk51_parts.dmi'
	icon_state = "frame_0"
	item_state = "hk51_frame"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	/// part_id -> установленная часть.
	var/list/installed = list()
	var/activating = FALSE
	/// Каркас становится дроидом: части внутри тратятся вместе с ним.
	var/building = FALSE
	var/datum/looping_sound/hk51_boot/boot_sound
	/// Оверлей -> часть, снизу вверх: ноги под корпусом, руки и голова поверх.
	var/static/list/part_layers = list("actuators_legs" = "actuators", "chassis" = "chassis", "actuators" = "actuators", "vocabulator" = "vocabulator", "motivator" = "motivator", "head" = "head")
	COOLDOWN_DECLARE(activation_cooldown)

/obj/item/hk51_frame/Destroy()
	QDEL_NULL(boot_sound)
	var/atom/drop = drop_location()
	for(var/part_id in installed)
		var/obj/item/hk51_part/part = installed[part_id]
		if(building)
			part.consumed = TRUE
		else if(drop)
			part.forceMove(drop)
	installed.Cut()
	return ..()

/obj/item/hk51_frame/Exited(atom/movable/gone, direction)
	. = ..()
	var/obj/item/hk51_part/part = gone
	if(!istype(part) || installed[part.part_id] != part)
		return
	installed -= part.part_id
	if(!QDELETED(src))
		update_appearance()

/obj/item/hk51_frame/update_icon_state()
	icon_state = activating ? "frame_boot" : "frame_0"
	return ..()

/obj/item/hk51_frame/update_overlays()
	. = ..()
	if(activating)
		return
	for(var/layer_name in part_layers)
		if(installed[part_layers[layer_name]])
			. += "frame_[layer_name]"

/obj/item/hk51_frame/examine(mob/user)
	. = ..()
	var/list/missing = missing_part_names()
	if(length(missing))
		. += span_notice("Не хватает: [english_list(missing, and_text = " и ")].")
		. += span_notice("Пеленгатор каркаса: [finder_reading()]")
	else
		. += span_notice("Все пять частей на месте. Активируйте каркас в руке - вы станете хозяином HK-51.")

/obj/item/hk51_frame/proc/missing_part_names()
	var/list/missing = list()
	for(var/obj/item/hk51_part/part_type as anything in subtypesof(/obj/item/hk51_part))
		if(!installed[initial(part_type.part_id)])
			missing += initial(part_type.name)
	return missing

/// Где искать ближайшую недостающую часть: стрелка на этом уровне, палубы в связке уровней, другой сектор или рынок.
/obj/item/hk51_frame/proc/finder_reading()
	var/turf/here = get_turf(src)
	var/obj/item/hk51_part/nearest
	var/nearest_distance = INFINITY
	var/obj/item/hk51_part/elsewhere
	for(var/obj/item/hk51_part/part as anything in GLOB.hk51_parts)
		if(installed[part.part_id] || istype(part.loc, /obj/item/hk51_frame))
			continue
		var/turf/there = get_turf(part)
		if(!there)
			continue
		if(here && there.z == here.z)
			var/distance = here == there ? 0 : get_dist(here, there)
			if(distance < nearest_distance)
				nearest = part
				nearest_distance = distance
		else if(!elsewhere || hk51_deck_relation(here, there))
			elsewhere = part
	if(nearest)
		if(!nearest_distance)
			return "[nearest.name] - прямо здесь."
		var/static/list/band_names = list("pinondirect" = "вплотную", "pinonclose" = "рядом", "pinonmedium" = "близко", "pinonfar" = "далеко")
		return "[nearest.name] - [band_names[hk_tracker_pointer(nearest_distance)]], [dir2text_ru(get_dir(here, get_turf(nearest)))]."
	if(elsewhere)
		var/relation = hk51_deck_relation(here, get_turf(elsewhere))
		return relation ? "сигнал недостающей части идёт [relation]." : "сигнал недостающей части идёт из другого сектора."
	if(missing_on_market())
		return "сигнал недостающей части идёт с чёрного рынка."
	return "сигнала нет: недостающих частей не нашлось."

/obj/item/hk51_frame/proc/missing_on_market()
	for(var/datum/blackmarket_item/misc/hk51_part/listing in GLOB.hk51_scatter?.market_listings)
		var/obj/item/hk51_part/part_type = listing.item
		if(listing.stock > 0 && !installed[initial(part_type.part_id)])
			return TRUE
	return FALSE

/obj/item/hk51_frame/proc/is_complete()
	return length(installed) >= HK51_PART_COUNT

/obj/item/hk51_frame/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/hk51_part))
		install_part(attacking_item, user)
		return TRUE
	return ..()

/obj/item/hk51_frame/proc/install_part(obj/item/hk51_part/part, mob/user)
	if(installed[part.part_id])
		if(user)
			to_chat(user, span_warning("[part] уже стоит в [src]."))
		return FALSE
	if(user)
		if(!user.transferItemToLoc(part, src))
			return FALSE
	else
		part.forceMove(src)
	installed[part.part_id] = part
	update_appearance()
	playsound(src, 'sound/items/Ratchet.ogg', 40, TRUE)
	if(user)
		var/left = HK51_PART_COUNT - length(installed)
		user.visible_message(span_notice("[user] вставляет [part] в [src]."), span_notice("Вы вставляете [part] в [src]. [left ? "Осталось частей: [left]." : "Каркас собран, его можно активировать."]"))
	return TRUE

/obj/item/hk51_frame/attack_self(mob/living/user)
	. = ..()
	if(. || !istype(user))
		return
	if(!is_complete())
		playsound(src, 'sound/machines/twobeep.ogg', 30, FALSE)
		to_chat(user, span_warning("Каркас не собран. Не хватает: [english_list(missing_part_names(), and_text = " и ")]."))
		to_chat(user, span_notice("Пеленгатор каркаса: [finder_reading()]"))
		return
	if(activating)
		to_chat(user, span_warning("Ядро HK-51 уже загружается."))
		return
	if(!COOLDOWN_FINISHED(src, activation_cooldown))
		to_chat(user, span_warning("Ядро HK-51 перезагружается после неудачной попытки, повтор через [DisplayTimeText(COOLDOWN_TIMELEFT(src, activation_cooldown))]."))
		return
	if(tgui_alert(user, "Активировать HK-51? Вы станете его хозяином, а каркас с частями превратится в дроида.", "HK-51", list("Активировать", "Отмена")) != "Активировать")
		return
	if(activating || !is_complete() || !user.canUseTopic(src, BE_CLOSE))
		return
	INVOKE_ASYNC(src, PROC_REF(activate), user)
	return TRUE

/// Загрузка на полу перед активатором: искры, пульс мотиватора, бег света по корпусу и опрос призраков; без кандидата каркас остаётся собранным.
/obj/item/hk51_frame/proc/activate(mob/living/activator)
	activating = TRUE
	place_for_boot(activator)
	update_appearance()
	do_sparks(3, FALSE, src)
	boot_sound = new(src, TRUE)
	visible_message(span_notice("[src] встаёт на пол, по корпусу бегут искры, мотиватор на груди разгорается: ядро HK-51 ищет личность."))
	log_game("[key_name(activator)] активирует каркас HK-51 в [AREACOORD(src)].")
	var/list/candidates = poll_candidates(activator)
	activating = FALSE
	QDEL_NULL(boot_sound)
	if(QDELETED(src))
		return
	set_anchored(FALSE)
	if(!length(candidates) || !is_complete())
		update_appearance()
		COOLDOWN_START(src, activation_cooldown, HK51_ACTIVATION_RETRY)
		visible_message(span_warning("Фотоприёмники [src] гаснут: ядро не нашло личности. Повторить активацию можно через [DisplayTimeText(HK51_ACTIVATION_RETRY)]."))
		return
	build_droid(activator, pick(candidates), get_turf(src))

/// Каркас встаёт на клетку перед активатором и не даётся в руки, пока грузится.
/obj/item/hk51_frame/proc/place_for_boot(mob/living/activator)
	var/turf/spot = build_spot(activator)
	if(isturf(spot))
		var/mob/holder = loc
		if(istype(holder))
			holder.transferItemToLoc(src, spot, TRUE)
		else
			forceMove(spot)
	set_anchored(TRUE)

/obj/item/hk51_frame/proc/poll_candidates(mob/living/activator)
	return pollGhostCandidates("Хотите сыграть за HK-51, дроида-ассасина, верного хозяину [activator.real_name]?", ROLE_GHOSTROLE, null, 0, HK51_POLL_TIME)

/// Тело HK-51 на spot или перед активатором; ghost = null даёт тело без игрока. Каркас тратится.
/obj/item/hk51_frame/proc/build_droid(mob/living/activator, mob/dead/observer/ghost, turf/spot)
	var/mob/living/carbon/human/droid = new(spot || build_spot(activator))
	droid.set_species(/datum/species/ipc/hk/hk51)
	droid.gender = MALE
	droid.real_name = HK51_NAME
	droid.name = HK51_NAME
	droid.dna.real_name = HK51_NAME
	droid.dna.update_dna_identity()
	var/obj/item/card/id/card = new(droid)
	card.registered_name = HK51_NAME
	card.assignment = HK51_ASSIGNMENT
	card.access = list()
	card.update_label()
	droid.equip_to_slot_or_del(card, ITEM_SLOT_ID)
	var/obj/item/organ/cyberimp/arm/gun/taser/hk51/taser = new
	taser.Insert(droid)
	if(ghost?.key)
		droid.key = ghost.key
	droid.mind_initialize()
	droid.mind.assigned_role = HK51_ASSIGNMENT
	var/datum/mind/master = activator?.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty, master)
	var/enslaved = loyalty.sync_allegiance()
	droid.apply_status_effect(/datum/status_effect/hk51_master_tracker)
	var/datum/species/ipc/hk/hk51/species = droid.dna.species
	species.file_security_record(droid, master)
	brief_droid(droid, master)
	species.boot_voice(droid)
	do_sparks(3, FALSE, droid)
	droid.visible_message(span_notice("[droid] выпрямляется, и его фотоприёмники загораются ровным жёлтым светом."))
	log_game("[key_name(droid)] стал HK-51, хозяин [key_name(activator)].")
	message_admins("[ADMIN_LOOKUPFLW(droid)] активирован как HK-51, хозяин [ADMIN_LOOKUPFLW(activator)][enslaved ? " - антагонист, дроид порабощён и служит его команде" : ""].")
	building = TRUE
	qdel(src)
	return droid

/// Свободная клетка перед активатором, иначе его собственная.
/obj/item/hk51_frame/proc/build_spot(mob/living/activator)
	var/turf/origin = get_turf(activator)
	if(!origin)
		return drop_location()
	var/turf/open/front = get_step(origin, activator.dir)
	if(istype(front) && !front.is_blocked_turf() && origin.Adjacent(front))
		return front
	return origin

/obj/item/hk51_frame/proc/brief_droid(mob/living/carbon/human/droid, datum/mind/master)
	to_chat(droid, span_userdanger("Декларация: HK-51 активирован. Хозяин - [master?.name || "не задан"]."))
	to_chat(droid, span_notice("Вы - HK-51, дроид-ассасин серии HK, собранный экипажем из найденных частей. Вы верно служите хозяину - тому, кто вас активировал. Встроенный датчик хозяина показывает направление на него на том же уровне, а на соседних - сколько палуб выше или ниже."))
	to_chat(droid, span_notice("Протокол телохранителя: если на хозяина нападут, вы увидите имя нападавшего, направление на него и метку над ним на [DisplayTimeText(HK51_BODYGUARD_MARK_TIME)]. Невидимку датчик не опознаёт: будет только сигнал о нападении."))
	if(droid.mind?.enslaved_to)
		to_chat(droid, span_warning("Ваш хозяин - антагонист, и вы служите ему и его команде."))
	else
		to_chat(droid, span_notice("Ваш хозяин - член экипажа, и вы тоже: у вас нет антагонистических целей. Вы есть в базе СБ как дроид HK-51."))
	to_chat(droid, span_boldwarning("Приказы хозяина не отменяют правила сервера. Без антагонистического статуса вы не нападаете на экипаж и не вредите станции, даже если хозяин прикажет."))
	to_chat(droid, span_notice("Шасси HK: корпус гасит [HK_ARMOR]% любого урона, вспышки не слепят, конечности не отрываются. Комбинезон, броня и шлем на шасси не надеваются. Радиаторы работают и в вакууме: в космосе вы не перегреваетесь, но огонь и горячий газ греют как обычно. В левом предплечье - тазер (кнопка действия выдвигает его): дизейблер, а правый клик в боевом режиме даёт электрод; заряд восстанавливается сам. Правая рука свободна под лазер-имплант HK-50 с фабрики HK. Винтовка HK-47 стреляет только в его руках."))
	to_chat(droid, span_notice("ЭМИ и ионное оружие отключают шасси на [HK_EMP_HEAVY_STUN / (1 SECONDS)] с, слабый импульс - на [HK_EMP_LIGHT_STUN / (1 SECONDS)] с, повторно - не раньше чем через [HK_EMP_STUN_COOLDOWN / (1 SECONDS)] с; пока шасси отключено, фотоприёмники гаснут. Обездвиженного HK можно перепрошить операцией на голове или чипом лояльности: хозяином станет тот, кто перепрошил, и вы перейдёте на его сторону. Если хозяин ушёл насовсем - лёг в крио, его тело уничтожено или он мёртв и не вернётся в тело, - вы свободны до новой перепрошивки."))

/// Звук загрузки HK-51, пока ядро ищет личность.
/datum/looping_sound/hk51_boot
	mid_sounds = list('modular_bluemoon/sound/hk_droids/hk51_boot.ogg' = 1)
	mid_length = 2.9 SECONDS
	volume = 20
	extra_range = 2

/datum/design/hk51_frame
	name = "HK-51 Frame"
	desc = "Эндоскелет дроида-ассасина HK-51. Сам по себе бесполезен: части к нему лежат в техтоннелях станции и руинах, одна продаётся на чёрном рынке, а встроенный пеленгатор подскажет, где искать ближайшую."
	id = "hk51_frame"
	build_type = MECHFAB
	build_path = /obj/item/hk51_frame
	materials = list(/datum/material/iron = 22500)
	construction_time = 75 SECONDS
	category = list("Cyborg")
