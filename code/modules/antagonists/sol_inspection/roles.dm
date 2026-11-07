/datum/objective/sol_inspection_return
	name = "complete the SOL inspection"
	explanation_text = "Проведите инспекцию станции на наличие нелегальных майнеров и вернитесь живыми на ЦК на инспекционном шаттле."
	var/datum/antagonist/sol_inspector/inspector

/datum/objective/sol_inspection_return/check_completion()
	if(!inspector || inspector.suspended)
		return FALSE
	return inspector.inspection_team?.is_returned_inspector(inspector.owner)

/datum/antagonist/sol_inspector
	name = "Инспекция Солнечной Федерации"
	job_rank = ROLE_TRAITOR
	roundend_category = "Инспекция Солнечной Федерации"
	antagpanel_category = "Солнечная Федерация"
	show_to_ghosts = TRUE
	soft_antag = TRUE
	var/datum/team/sol_inspection/inspection_team
	var/suspended = FALSE

/datum/antagonist/sol_inspector/get_team()
	return inspection_team

/datum/antagonist/sol_inspector/create_team(datum/team/sol_inspection/new_team)
	if(!istype(new_team))
		stack_trace("SOL inspector added without a SOL inspection team.")
		return
	inspection_team = new_team

/datum/antagonist/sol_inspector/on_gain()
	if(!locate(/datum/objective/sol_inspection_return) in objectives)
		var/datum/objective/sol_inspection_return/return_objective = new
		return_objective.owner = owner
		return_objective.inspector = src
		objectives += return_objective
	. = ..()

/datum/antagonist/sol_inspector/greet()
	to_chat(owner, span_boldannounce("Вы входите в инспекционную группу Солнечной Федерации."))
	to_chat(owner, span_notice("Проверьте станцию, Лаваленд и ксеноархеологическую экспедицию на наличие нелегальных БС-майнеров, криптомайнеров и слиперов с управлением внутри капсулы. Штраф за майнер, слипер или Gygax — 25 000 кредитов, за Durand — 50 000; деньги поступают на общий счёт ваших ID-карт. После завершённой проверки незаконная техника немедленно изымается со вспышкой искр. Durand вне арсенала запрещён до красного кода, Gygax — до янтарного. Слиперы с внутренним управлением нелегальны при любом уровне тревоги."))
	to_chat(owner, span_notice("Возврат на ЦК открывается через 30 минут после прибытия в сектор станции — либо досрочно, как только общая сумма взысканий достигнет 100 000 кредитов. Пункт назначения появляется на бортовой консоли, а по истечении срока шаттл уходит автоматически ещё через 3 минуты, даже если никто не воспользуется консолью."))
	to_chat(owner, span_warning("Не создавайте нарушения сами: если нелегальный объект собрал член инспекции, проверка выявит саботаж и потребует его ареста. Для успеха не требуется собирать определённую сумму штрафов."))
	to_chat(owner, span_warning("Не применяйте незаконную силу. Ваше вооружение предназначено только для защиты."))
	owner.announce_objectives()

/datum/outfit/sol_inspection
	name = "SOL Inspection Team"

	id = /obj/item/card/id/sol
	uniform = /obj/item/clothing/under/rank/security/officer/formal/sol
	suit = /obj/item/clothing/suit/armor/vest/warden/peacekeeper{name = "Peacekeeper Armored Trench Coat"}
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses
	mask = /obj/item/clothing/mask/gas/sechailer/swat/spacepol
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/color/black/forensic
	ears = /obj/item/radio/headset/sol
	back = /obj/item/storage/backpack/satchel/leather
	belt = /obj/item/storage/belt/security/full
	suit_store = /obj/item/gun/ballistic/automatic/pistol/deagle
	backpack_contents = list(/obj/item/storage/box/survival/centcom = 1, /obj/item/storage/firstaid/tactical/vanguard = 1, /obj/item/sol_inspection_scanner = 1, /obj/item/ammo_box/magazine/m50 = 3)
	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom)

/datum/outfit/sol_inspection/post_equip(mob/living/carbon/human/inspector, visualsOnly = FALSE, client/preference_source)
	. = ..()
	if(visualsOnly)
		return

	var/obj/item/radio/headset/radio = inspector.ears
	if(radio)
		QDEL_NULL(radio.keyslot2)
		radio.keyslot2 = new /obj/item/encryptionkey/heads/qm(radio)
		radio.recalculateChannels()
		radio.set_frequency(FREQ_SOL)
		radio.freqlock = TRUE

	inspector.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/id_card = inspector.wear_id
	if(id_card)
		id_card.registered_name = inspector.real_name
		id_card.assignment = "Всеобщее Бюро Контроля"
		id_card.update_label()

/datum/outfit/sol_inspection/commander
	name = "SOL Inspection Commander"

	uniform = /obj/item/clothing/under/rank/captain/sol
	ears = /obj/item/radio/headset/sol/command
	head = /obj/item/clothing/head/HoS/beret/sol/cap

/datum/outfit/sol_inspection/inspector
	name = "SOL Inspector"

/datum/outfit/sol_inspection/guard
	name = "SOL Inspection Guard"

	uniform = /obj/item/clothing/under/rank/security/officer/solfed_military
	ears = /obj/item/radio/headset/sol/bowman
	head = /obj/item/clothing/head/HoS/beret/sol/security

/obj/effect/mob_spawn/human/sol_inspector
	name = "капсула инспектора СОЛа"
	desc = "Капсула стазиса сотрудника Всеобщего Бюро Контроля."
	mob_name = "инспектор СОЛа"
	job_description = "Инспектор Солнечной Федерации"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	anchored = TRUE
	density = FALSE
	can_load_appearance = TRUE
	loadout_enabled = FALSE
	show_flavour = FALSE
	skip_reentry_check = TRUE
	short_desc = "Вы член инспекционной группы Солнечной Федерации."
	flavour_text = "Проверяйте станцию на нелегальные майнеры и нарушения эксплуатации мехов."
	important_info = "После инспекции вернитесь на свой шаттл живым."
	assignedrole = "Sol Inspection Team"
	category = "sol"
	outfit = /datum/outfit/sol_inspection/inspector
	var/datum/team/sol_inspection/inspection_team
	var/inspection_role = "inspector"

/obj/effect/mob_spawn/human/sol_inspector/commander
	name = "капсула командира инспекции СОЛа"
	outfit = /datum/outfit/sol_inspection/commander
	inspection_role = "commander"

/obj/effect/mob_spawn/human/sol_inspector/guard
	name = "капсула охраны инспекции СОЛа"
	outfit = /datum/outfit/sol_inspection/guard
	inspection_role = "guard"

/obj/effect/mob_spawn/human/sol_inspector/allow_spawn(mob/user, silent = FALSE)
	return inspection_team && !inspection_team.returned_home && ..()

/obj/effect/mob_spawn/human/sol_inspector/create(ckey, name, load_character, spawn_type)
	if(!inspection_team || inspection_team.returned_home)
		return
	return ..()

/obj/effect/mob_spawn/human/sol_inspector/special(mob/living/carbon/human/new_spawn)

	var/rank = get_rank(new_spawn.gender)
	var/datum/species/species = new_spawn.dna?.species
	var/generated_name = species ? species.random_name(new_spawn.gender, TRUE, TRUE) : random_unique_name(new_spawn.gender)
	new_spawn.fully_replace_character_name(new_spawn.real_name, "[rank] [generated_name]")

	var/obj/item/card/id/id_card = new_spawn.wear_id
	if(id_card)
		id_card.registered_name = new_spawn.real_name
		id_card.registered_account = inspection_team.account
		inspection_team.account.bank_cards |= id_card
		id_card.update_label()

	new_spawn.account_id = inspection_team.account.account_id
	new_spawn.mind.add_antag_datum(/datum/antagonist/sol_inspector, inspection_team)

/obj/effect/mob_spawn/human/sol_inspector/proc/get_rank(gender)
	switch(inspection_role)
		if("commander")
			return gender == FEMALE ? "Командующая" : "Командующий"
		if("guard")
			return gender == FEMALE ? "Охранница" : "Охранник"
		else
			return gender == FEMALE ? "Инспекторша" : "Инспектор"
