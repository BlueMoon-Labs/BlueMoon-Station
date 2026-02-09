// check PROCESSING_SUBSYSTEM_DEF(aura)
#define BONFIRE_HEALING_POWER_SMALL 0.17	// ~ 0.5 hp per second
#define BONFIRE_HEALING_POWER_MEDIUM 0.33  	// ~ 1 hp per second
#define BONFIRE_HEALING_POWER_HIGH 0.5 		// ~ 1.5 hp per second

/obj/structure/bonfire/prelit/ash
	name = "ashen bonfire"
	desc = "Томно тлеющий меч, вонзенный в умиротворенно горящую кучу вулканического пепла. Сам по себе удивителен тот факт, что она так хорошо горит. \
			Вблизи пламени этого необычного костровища ощущается безопасность и покой."
	icon = 'modular_bluemoon/icons/obj/structures/ashen_bonfire.dmi'
	icon_state = "ashen_bonfire"
	burn_icon = "ashen_bonfire"
	max_integrity = 100
	var/obj/item/melee/smith/coiled_sword/sword
	var/legendary_sword = FALSE
	var/healing_power = BONFIRE_HEALING_POWER_MEDIUM
	var/global/list/travel_bonfires = list()
	COOLDOWN_DECLARE(travel_cd)

/obj/structure/bonfire/prelit/ash/Initialize(mapload, obj/item/melee/smith/coiled_sword/S)
	. = ..()
	if(istype(S))
		S.forceMove(src)
		sword = S
	else
		sword = new(src)
	begin_restoration()

/obj/structure/bonfire/prelit/ash/Destroy()
	travel_bonfires -= src
	visible_message("<i>Пепел затухает навсегда, теряя свои необычные свойства, а меч покрывается еле-заметными трещинами.</i>")
	for(var/i = 1 to 5)
		new /obj/effect/decal/cleanable/ash(get_turf(src))
	if(istype(sword) && !QDELETED(sword))
		sword.forceMove(drop_location())
		sword.take_damage(sword.max_integrity/3, sound_effect = 0)
		if(QDELETED(sword))
			visible_message(span_warning("Хрупкий витой меч рассыпается в прах."))
	. = ..()

/obj/structure/bonfire/prelit/ash/examine(mob/user)
	. = ..()
	if(legendary_sword)
		. += span_engradio("Раскаленный до красна клинок ярко переливается в густых языках пламени!")
	else
		switch(healing_power)
			if(BONFIRE_HEALING_POWER_SMALL)
				. += span_engradio("Слабое пламя трепетно колышется от малейшего дуновения ветра...")
			if(BONFIRE_HEALING_POWER_MEDIUM)
				. += span_engradio("Умеренное пламя ощущается стабильным и спокойным.")
			if(BONFIRE_HEALING_POWER_HIGH)
				. += span_engradio("Пышные языки пламени бурно возносятся вверх!")

/obj/structure/bonfire/prelit/ash/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/rods))
		return
	else
		. = ..()

/obj/structure/bonfire/prelit/ash/proc/begin_restoration()
	if(QDELETED(sword))
		return
	var/mutable_appearance/sword_underlay = mutable_appearance('modular_bluemoon/icons/obj/structures/ashen_bonfire.dmi', "sword_inserted")
	sword_underlay.pixel_y = 16
	underlays += sword_underlay
	for(var/mob/living/L in view(src, 1))
		to_chat(L, span_engradio("<span class='italics'>Ты ощущаешь необычное спокойствие и умиротворение от теплого костра..."))
	// quality ranges in /dofinish() intercept and are really awfully organized.
	if(isnull(sword.quality)) // simply spawned
		healing_power = BONFIRE_HEALING_POWER_MEDIUM
	else if(sword.quality <= 1) // awful - normal
		healing_power = BONFIRE_HEALING_POWER_SMALL
	else if(1 < sword.quality && sword.quality < 7.5) // above-average - excellent
		healing_power = BONFIRE_HEALING_POWER_MEDIUM
	else if(7.5 <= sword.quality && sword.quality < 10) // masterwork
		healing_power = BONFIRE_HEALING_POWER_HIGH
	else if(10 <= sword.quality) //legendary
		healing_power = BONFIRE_HEALING_POWER_HIGH
		legendary_sword = TRUE
		var/mutable_appearance/big_fire_overlay = mutable_appearance('icons/obj/hydroponics/equipment.dmi', "bonfire_on_fire_intense", ABOVE_OBJ_LAYER)
		big_fire_overlay.pixel_y = 8
		add_overlay(big_fire_overlay)
	AddComponent( \
					/datum/component/aura_healing, \
					range = 1, \
					brute_heal = healing_power, \
					burn_heal = healing_power, \
					toxin_heal = healing_power, \
					suffocation_heal = healing_power, \
					stamina_heal = healing_power, \
					blood_heal = healing_power, \
					organ_healing = list(ORGAN_SLOT_BRAIN = healing_power), \
					simple_heal = healing_power, \
					healing_color = COLOR_ORANGE, \
					stackable = FALSE, \
				)

/obj/structure/bonfire/prelit/ash/process()
	if(legendary_sword && prob(10))
		for(var/mob/living/carbon/human/H in view(src, 1))
			var/datum/wound/W = pick(H.all_wounds)
			if(W)
				W.remove_wound()
				to_chat(H, span_engradio("Тепло пламени костра трепетно затягивает твои раны."))
				break
	. = ..()

/obj/structure/bonfire/prelit/ash/StartBurning()
	. = ..()
	if(!burning)
		visible_message(span_danger("[src] не смог разгореться."))
		addtimer(CALLBACK(src, PROC_REF(extinguish)), 1 SECONDS, TIMER_DELETE_ME)

/obj/structure/bonfire/prelit/ash/extinguish()
	. = ..()
	qdel(src)

/obj/structure/bonfire/prelit/ash/on_attack_hand(mob/user, act_intent, unarmed_attack_flags)
	if(!ishuman(user))
		return
	if(healing_power < BONFIRE_HEALING_POWER_MEDIUM)
		return
	if(!travel_bonfires[src])
		if(tgui_alert(user, "Позволить ли костру перемещать существ? Достаточно лишь прикоснуться к клинку...", \
							"Костры перемещения", \
							list("Позволить", "Оставить как есть")) == "Позволить")
			var/bonfire_name = tgui_input_text(user, null, "Название костра", max_length = MAX_NAME_LEN, encode = TRUE)
			if(!bonfire_name)
				return
			for(var/b in travel_bonfires)
				if(travel_bonfires[b] == bonfire_name)
					to_chat(user, span_warning("Костер с таким именем уже существует."))
					return
			travel_bonfires[src] = bonfire_name
			playsound(user, 'modular_bluemoon/sound/effects/bonfire_lit.ogg', 100, FALSE)
			to_chat(user, span_engradio("Отныне костер является точкой перемещения."))
		return
	/**
	 * travel_bonfires[объект] = название
	 * Игроку должен выводиться список названий костров.
	 * Так как я не нашел процедуры поиска ключа по значению (объекта по названию), приходится импровизировать.
	 * Создаем новый список, меняя местами названия и объекты. Названия уникальны, поэтому проблем быть не должно.
	 * available_travel_bonfires[название] = объект
	 */
	var/list/available_travel_bonfires = list()
	for(var/obj/structure/bonfire/prelit/ash/b in (travel_bonfires - src))
		if(is_centcom_level(b.z))
			continue
		available_travel_bonfires[travel_bonfires[b]] += b
	if(isemptylist(available_travel_bonfires))
		to_chat(user, span_warning("Нет доступных костров для перемещения."))
		return
	var/obj/structure/bonfire/prelit/ash/travel_to = tgui_input_list(user, "Выберите один из доступных костров перемещения", "Костры перемещения", available_travel_bonfires)
	travel_to = available_travel_bonfires[travel_to]
	if(!istype(travel_to))
		return
	if(!COOLDOWN_FINISHED(src, travel_cd))
		to_chat(user, span_warning("Пламя костра пока что не готово перенести еще одну душу. Подожди немного."))
		return
	var/list/tiles_around = list()
	for(var/A in orange(1, get_turf(travel_to)))
		if(istype(A, /turf/open/floor))
			var/turf/T = A
			if(T.is_blocked_turf())
				continue
			tiles_around += T
	if(isemptylist(tiles_around))
		to_chat(user, span_warning("Выбранный костер не имеет подходящего места для перемещения."))
		return
	if(QDELETED(user) || QDELETED(src) || QDELETED(travel_to) || !Adjacent(user) || user.incapacitated() || user.stat >= UNCONSCIOUS)
		return
	COOLDOWN_START(src, travel_cd, 30 SECONDS)
	bonfire_travel(user, travel_to, tiles_around)

/obj/structure/bonfire/prelit/ash/proc/bonfire_travel(mob/living/carbon/human/user, obj/structure/bonfire/prelit/ash/travel_to, list/tiles_around)
	playsound(user, 'modular_bluemoon/sound/effects/bonfire_lit.ogg', 100, FALSE)
	// just like warp whistle
	user.status_flags |= GODMODE
	ADD_TRAIT(user, TRAIT_MOBILITY_NOMOVE, "bonfire")
	ADD_TRAIT(user, TRAIT_MOBILITY_NOUSE, "bonfire")
	ADD_TRAIT(user, TRAIT_MOBILITY_NOPICKUP, "bonfire")
	user.update_mobility()
	ADD_TRAIT(user, TRAIT_LIVING_NO_DENSITY, "bonfire")
	user.update_density()
	var/image/fog_animation = image('icons/effects/chemsmoke.dmi', src, "", layer = GASFIRE_LAYER, pixel_x = -32, pixel_y = -32)
	fog_animation.color = COLOR_LIGHT_ORANGE
	fog_animation.alpha = 150
	flick_overlay(fog_animation, GLOB.clients, 7 SECONDS)
	var/user_alpha = user.alpha
	animate(user, alpha = 10, 5 SECONDS)
	sleep(6 SECONDS)
	if(QDELETED(user))
		return
	if(QDELETED(travel_to) || user.mob_transforming)
		to_chat(user, span_warning("Что-то случилось... перемещение не удалось."))
	else if(do_teleport(user, pick(tiles_around), channel = TELEPORT_CHANNEL_MAGIC))
		COOLDOWN_START(travel_to, travel_cd, 35 SECONDS)
		playsound(user, 'modular_bluemoon/sound/effects/bonfire_lit.ogg', 100, FALSE)
		fog_animation = image('icons/effects/chemsmoke.dmi', travel_to, "", layer = GASFIRE_LAYER, pixel_x = -32, pixel_y = -32)
		fog_animation.color = COLOR_LIGHT_ORANGE
		fog_animation.alpha = 150
		flick_overlay(fog_animation, GLOB.clients, 6 SECONDS)
	else
		to_chat(user, span_warning("Что-то случилось... перемещение не удалось."))
	if(user.alpha == 10) // если за 6 секунд прозрачность перонажа изменилась по неизвестным причинам, то лучше не трогать
		animate(user, alpha = user_alpha, 5 SECONDS)
	sleep(5 SECONDS)
	REMOVE_TRAIT(user, TRAIT_MOBILITY_NOMOVE, "bonfire")
	REMOVE_TRAIT(user, TRAIT_MOBILITY_NOUSE, "bonfire")
	REMOVE_TRAIT(user, TRAIT_MOBILITY_NOPICKUP, "bonfire")
	user.update_mobility()
	REMOVE_TRAIT(user, TRAIT_LIVING_NO_DENSITY, "bonfire")
	user.update_density()
	user.status_flags &= ~GODMODE

#undef BONFIRE_HEALING_POWER_SMALL
#undef BONFIRE_HEALING_POWER_MEDIUM
#undef BONFIRE_HEALING_POWER_HIGH
