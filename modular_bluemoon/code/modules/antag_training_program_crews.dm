#define ANTAG_TRAINING_WARMONGER_RESIST 0.5

/// Программа роли «только набор»: снаряжение и облик спавнера роли, своя команда без целей.
/datum/antag_training_program/antag/crew
	abstract_type = /datum/antag_training_program/antag/crew
	category = "Команды"
	choice_prompt = "Снаряжение"
	var/team_type
	/// Ключ выбора -> снаряжение спавнера.
	var/list/kits = list()
	/// Вид из спавнера; null - вид куклы участника.
	var/species_type
	var/greet_sound
	var/role_text
	var/missing_text = "Корабль, лут-пады, заложники за выкуп и цели экипажа на полигоне не воспроизводятся: здесь только снаряжение и облик роли."
	var/datum/team/team
	var/original_species
	/// Облик куклы до первого набора: наборы беглецов меняют имя, пол, кожу, волосы и глаза.
	var/list/original_look

/datum/antag_training_program/antag/crew/proc/training_team()
	if(QDELETED(team))
		team = new team_type
	return team

/datum/antag_training_program/antag/crew/grant_role(datum/antag_training_session/session)
	var/mob/living/carbon/human/body = session.avatar_mind?.current
	if(!ishuman(body) || !kits[choice])
		return FALSE
	equip_kit(session, body)
	return ..()

/datum/antag_training_program/antag/crew/proc/equip_kit(datum/antag_training_session/session, mob/living/carbon/human/body)
	original_species ||= body.dna.species.type
	body.delete_equipment()
	for(var/obj/item/implant/implant as anything in body.implants)
		qdel(implant)
	var/species = species_type || original_species
	if(species_type || body.dna.species.type != species)
		body.set_species(species)
	restore_look(session, body)
	var/name_before_kit = body.real_name
	body.equipOutfit(kits[choice])
	avatar_name = body.real_name != name_before_kit ? body.real_name : null
	customize(body)
	body.regenerate_icons()

/datum/antag_training_program/antag/crew/proc/restore_look(datum/antag_training_session/session, mob/living/carbon/human/body)
	if(!original_look)
		original_look = list("real_name" = body.real_name, "gender" = body.gender, "skin_tone" = body.skin_tone, "hair_style" = body.hair_style, "facial_hair_style" = body.facial_hair_style, "hair_color" = body.hair_color, "facial_hair_color" = body.facial_hair_color, "left_eye_color" = body.left_eye_color, "right_eye_color" = body.right_eye_color)
		return
	for(var/field in original_look - "real_name")
		body.vars[field] = original_look[field]
	var/look_name = (!session.character_preferences && session.return_name) || original_look["real_name"]
	if(body.real_name != look_name)
		body.fully_replace_character_name(null, look_name)
	var/eyes_type = body.dna.species.mutanteyes
	var/obj/item/organ/eyes/eyes = body.getorganslot(ORGAN_SLOT_EYES)
	if(eyes_type && eyes?.type != eyes_type)
		var/obj/item/organ/eyes/fresh_eyes = new eyes_type
		fresh_eyes.Insert(body, drop_if_replaced = FALSE)
	body.update_body()
	body.update_hair()

/// Что спавнер роли делает с телом сверх снаряжения.
/datum/antag_training_program/antag/crew/proc/customize(mob/living/carbon/human/body)
	return

/datum/antag_training_program/antag/crew/proc/brief(datum/antagonist/role)
	var/mob/living/carbon/human/body = role.owner?.current
	if(!ishuman(body))
		return
	var/obj/item/card/id/card = body.wear_id
	if(istype(card) && card.registered_name && card.registered_name != body.real_name)
		card.registered_name = body.real_name
		card.update_label()
	if(greet_sound)
		SEND_SOUND(body, sound(greet_sound))
	to_chat(body, briefing())

/datum/antag_training_program/antag/crew/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка: [name]. [choices[choice]]."),
		span_notice(role_text),
		span_notice(option_hints[choice_option(choice)]),
		span_notice(missing_text),
		span_notice("«Пульт полигона», раздел «Моя роль»: [length(choices) > 1 ? "смена снаряжения, " : ""]кнопка текущего снаряжения выдаёт его заново."),
	), "<br>")

/datum/antag_training_program/antag/crew/Destroy()
	QDEL_NULL(team)
	return ..()

/proc/antag_training_crew_team(datum/antag_training_session/training)
	var/datum/antag_training_program/antag/crew/program = training?.program
	return istype(program) ? program.training_team() : null

/proc/antag_training_crew_greet(datum/antagonist/role, datum/antag_training_session/training)
	var/datum/antag_training_program/antag/crew/program = training?.program
	if(istype(program))
		antag_training_greet_on_login(role, CALLBACK(program, TYPE_PROC_REF(/datum/antag_training_program/antag/crew, brief), role))

/datum/antag_training_program/antag/crew/pirate
	name = "Космический пират"
	desc = "Скелет-пират в пиратском скафандре с плазменным оружием и гарнитурой пиратов, снаряжение матроса или капитана. Только набор: корабль, лут-пады и выкупы на полигоне не воспроизводятся."
	icon = "skull-crossbones"
	color = "brown"
	learn = "Пиратский скафандр и плазменное оружие|Гарнитура пиратов|Набор матроса и капитана"
	difficulty = 1
	antag_type = /datum/antagonist/pirate/training
	team_type = /datum/team/pirate/training
	species_type = /datum/species/skeleton/space
	greet_sound = 'sound/ambience/antag/pirate.ogg'
	choices = list("mate" = "Матрос", "captain" = "Капитан")
	kits = list("mate" = /datum/outfit/pirate/space, "captain" = /datum/outfit/pirate/space/captain)
	role_text = "В раунде пираты приходят на своём корабле, когда станция отказалась платить за крышу: грабят хранилище и отсеки, сдают добычу на лут-пад корабля и берут заложников за выкуп. Лишних жертв избегают, корабль берегут."

/datum/antag_training_program/antag/crew/pirate/New()
	var/datum/species/skeleton/space/skeleton = species_type
	option_hints = list(
		"Снаряжение: Матрос" = "Космический скелет: не дышит, не мёрзнет, держит вакуум, урон от ударов и ожогов - [round(100 * initial(skeleton.brutemod))]% обычного. Пиратский скафандр, лёгкий плазменный пистолет, гарнитура пиратов, карта с доступом пиратов, имплант допуска к оружию. Как у спавнера, снаряжение не снимается, кроме карты. Своя внешность заменяется скелетом.",
		"Снаряжение: Капитан" = "То же, что у матроса, но капитанский шлем и плазменная винтовка вместо пистолета.",
	)
	return ..()

/datum/antag_training_program/antag/crew/pirate/customize(mob/living/carbon/human/body)
	for(var/obj/item/worn in body.get_equipped_items(include_pockets = TRUE))
		if(!istype(worn, /obj/item/card/id))
			ADD_TRAIT(worn, TRAIT_NODROP, "pirate_antag")

/datum/antag_training_program/antag/crew/raider
	name = "Рейдер InteQ"
	desc = "Наёмник или авангард InteQ: форма, гарнитура и карта InteQ, имплант допуска к оружию, язык старых кодов. Только набор: корабль, лут-пады и заложники на полигоне не воспроизводятся."
	icon = "crosshairs"
	color = "orange"
	learn = "Форма, гарнитура и карта InteQ|Имплант допуска к оружию|Язык старых кодов"
	difficulty = 1
	antag_type = /datum/antagonist/raiders/training
	team_type = /datum/team/raiders/training
	greet_sound = 'modular_bluemoon/kovac_shitcode/sound/inteq_raiders_spawn.ogg'
	choices = list("raider" = "Наёмник", "vanguard" = "Авангард")
	kits = list("raider" = /datum/outfit/inteq_raider, "vanguard" = /datum/outfit/inteq_raider/vanguard)
	role_text = "В раунде рейдеры InteQ приходят на корабле «Колосс», когда капитан отказался платить: грабят станцию, сдают добычу на лут-пад и похищают членов экипажа на корабль. Лишних жертв избегают."
	option_hints = list(
		"Снаряжение: Наёмник" = "Форма InteQ, боевые ботинки, гарнитура InteQ на частоте InteQ, агентская карта InteQ, имплант допуска к оружию, язык старых кодов. Внешность - ваша, как у спавнера рейдеров.",
		"Снаряжение: Авангард" = "То же, что у наёмника, плюс броня и шлем авангарда, перчатки крав-мага в кармане, карта авангарда и командный режим гарнитуры.",
	)

/datum/antag_training_program/antag/crew/vox
	name = "Вокс-мародёр"
	desc = "Вокс в синдикатской форме с гарнитурой пиратов и картой торговца. Только набор: корабль, лут-пады и цели похищения на полигоне не воспроизводятся."
	icon = "feather"
	color = "teal"
	learn = "Форма и снаряжение мародёра|Гарнитура пиратов|Карта торговца"
	difficulty = 1
	antag_type = /datum/antagonist/vox_scavengers/training
	team_type = /datum/team/vox_scavengers/training
	species_type = /datum/species/mammal/vox
	greet_sound = 'modular_bluemoon/kovac_shitcode/sound/vox_spawn.ogg'
	choices = list("scavenger" = "Мародёр")
	kits = list("scavenger" = /datum/outfit/vox_scavenger)
	role_text = "В раунде воксы приходят на корабле «Скипджек»: обносят станцию, торгуют или действуют скрытно, сдают добычу на лут-пад и иногда похищают членов экипажа. Конфликтов первыми не начинают, ни один вокс не должен остаться за бортом."
	option_hints = list(
		"Снаряжение: Мародёр" = "Вид вокса: дышит азотом, не носит перчатки, получает больше урона, но бьёт когтями и делает подкаты. Синдикатская форма, ботинки без носков, гарнитура пиратов на частоте пиратов, агентская карта торговца, имплант допуска к оружию. Своя внешность заменяется воксом.",
	)

/datum/antag_training_program/antag/crew/vox/customize(mob/living/carbon/human/body)
	body.set_bark("lizard")

/datum/antag_training_program/antag/crew/warmonger
	name = "Вармонгер"
	antag_type = /datum/antagonist/warmonger/training
	team_type = /datum/team/pirate/training/warmonger
	species_type = /datum/species/skeleton/space
	greet_sound = 'sound/ambience/antag/pirate_medieval.ogg'
	choices = list("warrior" = "Воин", "warlord" = "Военачальник")
	kits = list("warrior" = /datum/outfit/medieval, "warlord" = /datum/outfit/medieval/warlord)
	desc = "Скелет-воин с мечом, копьём, болами и тазером или военачальник с крюком, топором и силой халка; оба крепче обычного космического скелета. Только набор: корабль, лут-пады и дань на полигоне не воспроизводятся."
	icon = "fire"
	color = "red"
	learn = "Меч, копьё, болы и тазер воина|Крюк, топор и сила халка военачальника|Живучесть скелета"
	difficulty = 1
	role_text = "В раунде средневековые вармонгеры высаживаются со своего корабля и требуют дани: грабят станцию и сдают добычу на лут-пад. Говорят ЗАГЛАВНЫМИ, путаются в технике и запугивают слабых."

/datum/antag_training_program/antag/crew/warmonger/New()
	var/datum/species/skeleton/space/skeleton = species_type
	var/damage_share = round(100 * initial(skeleton.brutemod) * ANTAG_TRAINING_WARMONGER_RESIST)
	option_hints = list(
		"Снаряжение: Воин" = "Космический скелет, урон от ударов и ожогов - [damage_share]% обычного. Гамбезон, рыцарский доспех и шлем, клеймор, копьё, пояс с пятью болами, тазер и факел. Доспех, шлем, перчатки и сапоги не снимаются. Своя внешность заменяется скелетом.",
		"Снаряжение: Военачальник" = "Тот же скелет, но доспех и шлем военачальника, плащ, мясной крюк, абордажный топор, золотой пояс с болами, сила халка и гигантизм.",
	)
	return ..()

/datum/antag_training_program/antag/crew/warmonger/customize(mob/living/carbon/human/body)
	var/datum/species/skeleton = body.dna.species
	skeleton.brutemod *= ANTAG_TRAINING_WARMONGER_RESIST
	skeleton.burnmod *= ANTAG_TRAINING_WARMONGER_RESIST
	skeleton.coldmod *= ANTAG_TRAINING_WARMONGER_RESIST
	if(choice == "warlord")
		body.dna.add_mutation(/datum/mutation/human/hulk/superhuman)
		body.dna.add_mutation(GIGANTISM)

/datum/antag_training_program/antag/crew/warmonger/equip_kit(datum/antag_training_session/session, mob/living/carbon/human/body)
	var/datum/mutation/human/hulk/superhuman/hulk = body.dna.get_mutation(/datum/mutation/human/hulk/superhuman)
	if(hulk)
		body.dna.force_lose(hulk)
		body.dna.mutations -= hulk
		qdel(hulk)
		REMOVE_TRAITS_IN(body, TRAIT_HULK)
		SEND_SIGNAL(body, COMSIG_CLEAR_MOOD_EVENT, "hulk")
	body.dna.remove_mutation(GIGANTISM)
	return ..()

/// Учебная команда пиратов: вне списка команд раунда, без целей и отчёта.
/datum/team/pirate/training
	name = "Training pirate crew"
	show_roundend_report = FALSE

/datum/team/pirate/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/pirate/training/roundend_report()
	return

/datum/team/pirate/training/warmonger
	name = "Training warmongers"

/datum/team/raiders/training
	name = "Training InteQ raiders"
	show_roundend_report = FALSE

/datum/team/raiders/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/raiders/training/roundend_report()
	return

/datum/team/vox_scavengers/training
	name = "Training vox scavengers"
	show_roundend_report = FALSE

/datum/team/vox_scavengers/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/vox_scavengers/training/roundend_report()
	return

/datum/antagonist/pirate/training
	name = "Учебный космический пират"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/pirate/training/threat()
	return 0

/datum/antagonist/pirate/training/create_team(datum/team/pirate/new_team)
	crew = antag_training_crew_team(training)

/datum/antagonist/pirate/training/greet()
	antag_training_crew_greet(src, training)

/datum/antagonist/pirate/training/Destroy()
	. = ..()
	crew = null
	training = null

/datum/antagonist/raiders/training
	name = "Учебный рейдер InteQ"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/raiders/training/threat()
	return 0

/datum/antagonist/raiders/training/create_team(datum/team/raiders/new_team)
	crew = antag_training_crew_team(training)

/datum/antagonist/raiders/training/greet()
	antag_training_crew_greet(src, training)

/datum/antagonist/raiders/training/Destroy()
	. = ..()
	crew = null
	training = null

/datum/antagonist/vox_scavengers/training
	name = "Учебный вокс-мародёр"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/vox_scavengers/training/threat()
	return 0

/datum/antagonist/vox_scavengers/training/create_team(datum/team/vox_scavengers/new_team)
	crew = antag_training_crew_team(training)

/datum/antagonist/vox_scavengers/training/greet()
	antag_training_crew_greet(src, training)

/datum/antagonist/vox_scavengers/training/Destroy()
	. = ..()
	crew = null
	training = null

/datum/antagonist/warmonger/training
	name = "Учебный вармонгер"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/warmonger/training/threat()
	return 0

/datum/antagonist/warmonger/training/create_team(datum/team/pirate/new_team)
	crew = antag_training_crew_team(training)

/datum/antagonist/warmonger/training/greet()
	antag_training_crew_greet(src, training)

/datum/antagonist/warmonger/training/Destroy()
	. = ..()
	crew = null
	training = null

#undef ANTAG_TRAINING_WARMONGER_RESIST
