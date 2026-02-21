/obj/item/choice_beacon/vehicle
	name = "Vehicle Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать транспорт."
	radial_menu = TRUE
	var/list/vehicle_list = list()
	var/group_path = /obj/item/choice_beacon/vehicle // Маяки этого типа будут содержать все vehicle_list своих подтипов

/obj/item/choice_beacon/vehicle/Initialize(mapload)
	if(type == group_path)

		// Понятия не имею, как написать это по другому. Ни через оператор : ни через initial нельзя получить переменную /list
		var/static/list/vehicle_list_cache
		if(!vehicle_list_cache)
			vehicle_list_cache = list()
			for(var/path in typesof(/obj/item/choice_beacon/vehicle))
				var/obj/item/choice_beacon/vehicle/beacon = new path(null)
				vehicle_list_cache[beacon.type] = LAZYCOPY(beacon.vehicle_list)
				qdel(beacon)

		for(var/path in typesof(type))
			merge_assoc_list(vehicle_list, vehicle_list_cache[path])

	return ..()

/obj/item/choice_beacon/vehicle/generate_display_names()
	return vehicle_list

/obj/item/choice_beacon/vehicle/spawn_option(atom/choice, mob/living/M)
	. = ..()
	if(ispath(choice, /obj/vehicle/sealed/mecha) || istype(choice, /obj/vehicle/sealed/mecha))
		var/obj/effect/pod_landingzone/effect = .
		var/sound = pick_titanfall_sound()
		if(sound)
			playsound(get_turf(effect), sound, 100, FALSE)
		effect.say("Stand by for TitanFall!")

#define TF_BASE_W	100 // Базовое значение веса
#define TF_MIN_W	5 // Минимальный шанс в пуле
#define TF_DECAY	60   // Насколько режем выбранный
#define TF_RECOVER	8   // Насколько поднимаем все остальные за вызов
#define TF_MAX_W	TF_BASE_W // Макимальный вес

// Смысл этого прока в том, что бы максимально разнообразить звуки через снижение веса выпавшего звука на TF_DECAY
// И «регенерации» веса ранее выпадавших звуков на TF_RECOVER
/obj/item/choice_beacon/vehicle/proc/pick_titanfall_sound()
	var/static/list/weights = list(
			'modular_bluemoon/sound/effects/titanfall/titanfall1.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall2.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall3.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_female1.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_female2.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_female3.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male1.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male2.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male3.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male4.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male5.ogg' = TF_BASE_W,
			'modular_bluemoon/sound/effects/titanfall/titanfall_male6.ogg' = TF_BASE_W,
		)

	var/static/last_sound
	var/last_sound_weight
	// Если мы уже выбирали, то запоминаем вес и снижаем его в списке до 0, запрещая выпадение
	if(last_sound)
		last_sound_weight = weights[last_sound]
		weights[last_sound] = 0

	var/sound = pickweight(weights)

	// Возвращаем вес на место, если убирали
	if(last_sound_weight)
		weights[last_sound] = last_sound_weight

	if(!sound)
		return null

	// Запоминаем выбранный
	last_sound = sound

	// 1) восстанавливаем остальные (мягкий дрейф обратно к равномерности)
	for(var/k in weights)
		if(k == sound)
			continue
		var/w = weights[k]
		if(w < TF_MAX_W)
			weights[k] = min(TF_MAX_W, w + TF_RECOVER)

	// 2) режем выбранный
	var/new_w = weights[sound] - TF_DECAY
	weights[sound] = max(TF_MIN_W, new_w)

	return sound

#undef TF_BASE_W
#undef TF_MIN_W
#undef TF_DECAY
#undef TF_RECOVER
#undef TF_MAX_W

/obj/item/choice_beacon/vehicle/clown_car
	name = "Clown Car Beacon"
	vehicle_list = list(
		"Clown car" = /obj/vehicle/sealed/car/clowncar
	)

////////////////////////	ПАКТ	////////////////////////
/obj/item/choice_beacon/vehicle/pact
	name = "PACT Vehicle Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать транспорт с Фрегатов Туманности Синие Луны. За ПАКТ!"
	group_path = /obj/item/choice_beacon/vehicle/pact

////////////////////////	МЕХИ	////////////////////////
/obj/item/choice_beacon/vehicle/pact/mech
	name = "PACT Mech Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать один из мехов с Фрегатов Туманности Синие Луны. За ПАКТ!"
	group_path = /obj/item/choice_beacon/vehicle/pact/mech

/obj/item/choice_beacon/vehicle/pact/mech/combat
	name = "Combat Mech Beacon"
	vehicle_list = list(
		"Main Battle Mech Durand Mk1A1" = /obj/vehicle/sealed/mecha/combat/durand/loaded,
		"Main Battle Mech mk. I" = /obj/vehicle/sealed/mecha/combat/gygax/loaded
	)

/obj/item/choice_beacon/vehicle/pact/mech/medical
	name = "Medical Pact Mech Beacon"
	vehicle_list = list(
		"Vey-Med Odysseus" = /obj/vehicle/sealed/mecha/medical/odysseus/loaded,
		"Vey-Med Gygax" = /obj/vehicle/sealed/mecha/medical/medigax/loaded
	)

/obj/item/choice_beacon/vehicle/pact/mech/cargo
	name = "Cargo Pact Mech Beacon"
	vehicle_list = list(
		"Autonomous Power Loader Unit MK-I" = /obj/vehicle/sealed/mecha/working/ripley/loaded,
		"Autonomous Power Loader Unit MK-II" = /obj/vehicle/sealed/mecha/working/ripley/mkii/loaded
	)

/obj/item/choice_beacon/vehicle/pact/mech/engineer
	name = "Engineer Pact Mech Beacon"
	vehicle_list = list(
		"Autonomous Power Loader Unit MK-II-F" = /obj/vehicle/sealed/mecha/working/ripley/firefighter/loaded
	)

/obj/item/choice_beacon/vehicle/misc_mech
	name = "Mech Beacon"
	desc = "To summon your own steel titan."
	group_path = /obj/item/choice_beacon/vehicle/misc_mech

/obj/item/choice_beacon/vehicle/misc_mech/ert
	name = "ERT Mech Beacon"
	desc = "To summon your own steel titan."
	vehicle_list = list(
		"Marauder" = /obj/vehicle/sealed/mecha/combat/marauder/loaded,
		"Seraph" = /obj/vehicle/sealed/mecha/combat/marauder/seraph
	)

/obj/item/choice_beacon/vehicle/misc_mech/nri
	name = "NRI Mech Beacon"
	desc = "To summon your own steel titan. For the Emperor!"
	vehicle_list = list(
		"TU-802 Solntsepyok" = /obj/vehicle/sealed/mecha/combat/durand/tu802,
		"Savannah-Ivanov" = /obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded
	)

/obj/item/choice_beacon/vehicle/misc_mech/sol
	name = "SolFed Mech Beacon"
	desc = "Feel the power of the tesla. Glory to the Humanity!"
	vehicle_list = list(
		"TU-802 Solntsepyok" = /obj/vehicle/sealed/mecha/combat/durand/tu802,
		"Savannah-Ivanov" = /obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded
	)
