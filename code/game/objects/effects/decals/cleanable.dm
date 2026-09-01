/obj/effect/decal/cleanable/Destroy()
	lose_cleanbot_targetable()
	blood_DNA = null
	GLOB.cleanable_decals -= src
	return ..()

/obj/effect/decal/cleanable
	gender = PLURAL
	layer = ABOVE_NORMAL_TURF_LAYER
	/// Is this kind of cleanable decal persistent
	var/persistent = FALSE
	/// Can we stack multiple in one tile?
	var/persistence_allow_stacking = FALSE
	/// Are we deleted by turf changes?
	var/wiped_by_floor_change = FALSE

	var/list/random_icon_states = null
	var/blood_state = "" //I'm sorry but cleanable/blood code is ass, and so is blood_DNA
	var/bloodiness = 0 //0-100, amount of blood in this decal, used for making footprints and affecting the alpha of bloody footprints
	var/mergeable_decal = TRUE //when two of these are on a same tile or do we need to merge them into just one?
	var/beauty = 0
	/// Порядковый номер создания. По нему кап на турфе выбирает самую старую декаль.
	var/decal_creation_order = 0
	var/static/decal_creation_counter = 0
	/// Декаль, которую кап в жертвы не берёт: авторская работа игрока или маппера. В счёт
	/// переполнения она входит, поэтому турф из одних таких декалей остаётся сверх капа.
	var/cap_exempt = FALSE

/obj/effect/decal/cleanable/Initialize(mapload, list/datum/disease/diseases)
	. = ..()
	GLOB.cleanable_decals += src
	decal_creation_counter++
	decal_creation_order = decal_creation_counter
	if(mapload)
		cap_exempt = TRUE
	LAZYINITLIST(blood_DNA) //Kinda needed
	if (random_icon_states && (icon_state == initial(icon_state)) && length(random_icon_states) > 0)
		icon_state = pick(random_icon_states)
	create_reagents(300, NONE, NO_REAGENTS_VALUE)
	if(loc && isturf(loc))
		for(var/obj/effect/decal/cleanable/C in loc)
			if(C != src && C.type == type && !QDELETED(C))
				if (replace_decal(C))
					return INITIALIZE_HINT_QDEL
		// На маплоаде кап не применяем: qdel неинициализированных соседей ломает SSatoms.
		// Мертворождённой декали (родитель вернул QDEL) он тоже ни к чему.
		if(!mapload && . != INITIALIZE_HINT_QDEL)
			enforce_turf_decal_cap()

	if(LAZYLEN(diseases))
		var/list/datum/disease/diseases_to_add = list()
		for(var/datum/disease/D in diseases)
			if(D.spread_flags & DISEASE_SPREAD_CONTACT_FLUIDS)
				diseases_to_add += D
		if(LAZYLEN(diseases_to_add))
			AddComponent(/datum/component/infective, diseases_to_add)

	// Прямое добавление как у tg: нулевой таймер на каждую декаль давал залп из
	// 2000+ addtimer одним тиком при загрузке дебриса персистенса (TIMER BURST 9746).
	if(beauty)
		AddElement(/datum/element/beauty, beauty)
	if(isturf(loc))
		become_cleanbot_targetable()

/**
 * A data list is passed into this.
 * This should return null to skip saving, or the type of data to save. Type must be /cleanable.
 */
/obj/effect/decal/cleanable/proc/PersistenceSave(list/data)
	return type

/**
 * Loads from a data list.
 */
/obj/effect/decal/cleanable/proc/PersistenceLoad(list/data)
	return

/obj/effect/decal/cleanable/proc/replace_decal(obj/effect/decal/cleanable/C) // Returns true if we should give up in favor of the pre-existing decal
	return mergeable_decal

/// Приводит число декалей на турфе к CLEANABLE_DECAL_TURF_CAP. Это не инвариант турфа, а разовая
/// досылка: путь, оставляющий декаль на чужом турфе насовсем, обязан звать её сам (см. gibs/streak).
/obj/effect/decal/cleanable/proc/enforce_turf_decal_cap()
	var/others = 0
	var/obj/effect/decal/cleanable/same_type
	var/obj/effect/decal/cleanable/oldest
	for(var/obj/effect/decal/cleanable/other in loc)
		if(other == src || QDELETED(other))
			continue
		others++
		if(other.cap_exempt)
			continue
		if(other.type == type && (!same_type || other.decal_creation_order < same_type.decal_creation_order))
			same_type = other
		if(!oldest || other.decal_creation_order < oldest.decal_creation_order)
			oldest = other
	// src уже лежит на турфе, поэтому соседям остаётся на одно место меньше.
	var/excess = others - (CLEANABLE_DECAL_TURF_CAP - 1)
	if(excess <= 0)
		return
	var/obj/effect/decal/cleanable/victim = same_type || oldest
	if(!victim)
		return
	absorb_cleanable(victim, victim.type == type)
	for(var/i in 2 to excess)
		victim = find_cap_victim()
		if(!victim)
			return
		absorb_cleanable(victim, victim.type == type)

/// Жертва капа: самая старая декаль нашего типа, иначе самая старая вообще. cap_exempt в жертвы
/// не годится; сам src на cap_exempt не проверяется - новый рисунок вытесняет старую грязь.
/obj/effect/decal/cleanable/proc/find_cap_victim()
	var/obj/effect/decal/cleanable/same_type
	var/obj/effect/decal/cleanable/oldest
	for(var/obj/effect/decal/cleanable/other in loc)
		if(other == src || QDELETED(other) || other.cap_exempt)
			continue
		if(other.type == type && (!same_type || other.decal_creation_order < same_type.decal_creation_order))
			same_type = other
		if(!oldest || other.decal_creation_order < oldest.decal_creation_order)
			oldest = other
	return same_type || oldest

/// Забирает содержимое поглощаемой декали и удаляет её. Форензика переносится всегда, а реагенты,
/// кровавость и болезни - только при full_merge, то есть между декалями одного типа.
/obj/effect/decal/cleanable/proc/absorb_cleanable(obj/effect/decal/cleanable/absorbed, full_merge = FALSE)
	if(QDELETED(absorbed) || absorbed == src)
		return
	// transfer_fingerprints_to() присваивает fingerprintslast, а не сливает: свой след новее.
	var/own_last_toucher = fingerprintslast
	absorbed.transfer_fingerprints_to(src)
	if(own_last_toucher)
		fingerprintslast = own_last_toucher
	if(LAZYLEN(absorbed.suit_fibers))
		LAZYINITLIST(suit_fibers)
		suit_fibers |= absorbed.suit_fibers
	if(LAZYLEN(absorbed.blood_DNA))
		transfer_blood_dna(absorbed.blood_DNA)
	if(full_merge)
		if(reagents && absorbed.reagents?.total_volume)
			// no_react: реакция посреди Initialize может удалить нас самих.
			absorbed.reagents.trans_to(src, absorbed.reagents.total_volume, no_react = TRUE)
		bloodiness = max(bloodiness, absorbed.bloodiness)
		for(var/datum/component/infective/infection in absorbed.GetComponents(/datum/component/infective))
			// Пустой список болезней компонент превращает в list(null) и потом рантаймит на нём.
			if(!LAZYLEN(infection.diseases))
				continue
			var/expire_in = infection.expire_time ? max(infection.expire_time - world.time, 1) : null
			AddComponent(/datum/component/infective, infection.diseases.Copy(), expire_in)
		update_icon()
	qdel(absorbed)

/obj/effect/decal/cleanable/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/reagent_containers/glass) || istype(W, /obj/item/reagent_containers/food/drinks))
		if(src.reagents && W.reagents)
			. = 1 //so the containers don't splash their content on the src while scooping.
			if(!src.reagents.total_volume)
				to_chat(user, "<span class='notice'>[src] isn't thick enough to scoop up!</span>")
				return
			if(W.reagents.total_volume >= W.reagents.maximum_volume)
				to_chat(user, "<span class='notice'>[W] is full!</span>")
				return
			to_chat(user, "<span class='notice'>You scoop up [src] into [W]!</span>")
			reagents.trans_to(W, reagents.total_volume)
			if(!reagents.total_volume) //scooped up all of it
				qdel(src)
				return
	if(W.get_temperature()) //todo: make heating a reagent holder proc
		if(istype(W, /obj/item/clothing/mask/cigarette))
			return
		else
			var/hotness = W.get_temperature()
			reagents.expose_temperature(hotness)
			to_chat(user, "<span class='notice'>You heat [name] with [W]!</span>")
	else
		return ..()

// BLUEMOON ADD START: puddle-created decals are capped at LIQUID_DECAL_CAP units,
// so scooping them can't duplicate a liquid puddle into an exploit.
/obj/effect/decal/cleanable/proc/cap_liquid_reagents()
	if(!reagents || !reagents.total_volume)
		return
	var/excess = reagents.total_volume - LIQUID_DECAL_CAP
	if(excess <= 0)
		return
	for(var/datum/reagent/R in reagents.reagent_list)
		var/remove_amount = min(R.volume, excess)
		reagents.remove_reagent(R.type, remove_amount)
		excess -= remove_amount
		if(excess <= 0)
			break
// BLUEMOON ADD END

/obj/effect/decal/cleanable/ex_act(severity, target, origin)
	if(reagents)
		for(var/datum/reagent/R in reagents.reagent_list)
			R.on_ex_act(severity)
	..()

/obj/effect/decal/cleanable/fire_act(exposed_temperature, exposed_volume)
	if(reagents)
		reagents.expose_temperature(exposed_temperature)
	..()


//Add "bloodiness" of this blood's type, to the human's shoes
//This is on /cleanable because fuck this ancient mess
/obj/effect/decal/cleanable/Crossed(atom/movable/O)
	..()
	if(ishuman(O))
		var/mob/living/carbon/human/H = O
		if(H.shoes && blood_state && bloodiness && !HAS_TRAIT(H, TRAIT_LIGHT_STEP))
			var/obj/item/clothing/shoes/S = H.shoes
			if(!istype(S))
				return
			var/add_blood = 0
			if(bloodiness >= BLOOD_GAIN_PER_STEP)
				add_blood = BLOOD_GAIN_PER_STEP
			else
				add_blood = bloodiness
			bloodiness -= add_blood
			S.bloody_shoes[blood_state] = min(MAX_SHOE_BLOODINESS,S.bloody_shoes[blood_state]+add_blood)
			if(blood_DNA && blood_DNA.len)
				S.add_blood_DNA(blood_DNA)
				S.add_blood_overlay()
			S.blood_state = blood_state
			update_icon()
			H.update_inv_shoes()

/obj/effect/decal/cleanable/proc/can_bloodcrawl_in()
	if((blood_state != BLOOD_STATE_OIL) && (blood_state != BLOOD_STATE_NOT_BLOODY))
		return bloodiness
	else
		return FALSE
