/datum/antag_training_program/antag/crew/fugitive
	name = "Беглец"
	category = "Чужаки"
	desc = "Беглый заключённый, культист Ялп Элора, Уолдо или сбойный синтетик в снаряжении своей предыстории. Только набор: охотники, их корабль и машина захвата на полигоне не воспроизводятся."
	icon = "person-running"
	color = "yellow"
	learn = "Беглый заключённый и культист Ялп Элора|Уолдо и сбойный синтетик|Снаряжение каждой предыстории"
	difficulty = 1
	antag_type = /datum/antagonist/fugitive/training
	team_type = /datum/team/fugitive/training
	choice_prompt = "Предыстория"
	choices = list("prisoner" = "Беглый заключённый", "cultist" = "Культист Ялп Элора", "waldo" = "Уолдо", "synth" = "Сбойный синтетик")
	kits = list("prisoner" = /datum/outfit/prisoner, "cultist" = /datum/outfit/yalp_cultist, "waldo" = /datum/outfit/waldo, "synth" = /datum/outfit/synthetic)
	role_text = "В раунде беглецы телепортируются в техтоннели станции, а позже за ними прилетают охотники. Беглецы - не антагонисты, которым можно убивать кого угодно, но ради свободы им можно почти всё. Цель - не попасть в машину захвата охотников до конца смены."
	missing_text = "Охотники, их корабль и машина захвата, а также лидер с маяком аугментаций на полигоне не воспроизводятся: здесь только снаряжение и облик предыстории."
	option_hints = list(
		"Предыстория: Беглый заключённый" = "Оранжевая роба, кеды и заточка в кармане; имя - номер заключённого ЦК.",
		"Предыстория: Культист Ялп Элора" = "Ряса священника, красные перчатки и маска тики Ялп Элора.",
		"Предыстория: Уолдо" = "Полосатый свитер, шапка и очки Уолдо, гарнитура и заклинание Knock. Одежда проклята и не снимается, внешность и имя становятся Уолдо.",
		"Предыстория: Сбойный синтетик" = "Белый комбинезон, гарнитура и светящиеся кибернетические глаза.",
	)

/datum/antag_training_program/antag/crew/fugitive/apply_choice(datum/antagonist/fugitive/training/role)
	role.backstory = choice

/datum/antag_training_program/antag/crew/fugitive/equip_kit(datum/antag_training_session/session, mob/living/carbon/human/body)
	body.mind?.RemoveSpell(/obj/effect/proc_holder/spell/aoe_turf/knock)
	return ..()

/datum/antag_training_program/antag/crew/hunter
	name = "Охотник за беглецами"
	category = "Чужаки"
	desc = "Космополиция, космические контрабандисты или охотники за головами со снаряжением своего спавнера. Только набор: корабль охотников, машина захвата и беглецы раунда на полигоне не воспроизводятся."
	icon = "binoculars"
	color = "blue"
	learn = "Космополиция и контрабандисты|Три вида охотников за головами|Снаряжение и ловушки отряда"
	difficulty = 1
	antag_type = /datum/antagonist/fugitive_hunter/training
	team_type = /datum/team/fugitive_hunters/training
	choice_prompt = "Отряд"
	choices = list("space cop" = "Космополиция", "russian" = "Контрабандист", "bounty armor" = "Охотник за головами в броне", "bounty hook" = "Охотник за головами с дробовиком", "bounty synth" = "Синтетик-охотник за головами")
	kits = list("space cop" = /datum/outfit/spacepol, "russian" = /datum/outfit/russiancorpse/hunter, "bounty armor" = /datum/outfit/bountyarmor, "bounty hook" = /datum/outfit/bountyhook, "bounty synth" = /datum/outfit/bountysynth)
	var/list/backstories = list("space cop" = "space cop", "russian" = "russian", "bounty armor" = "bounty hunters", "bounty hook" = "bounty hunters", "bounty synth" = "bounty hunters")
	role_text = "В раунде охотников вызывают вслед за беглецами: они прилетают на своём корабле, ловят беглецов живыми или мёртвыми и сажают в машину захвата. Охотники - не антагонисты, которым можно убивать кого угодно, но ради поимки могут пройти через станцию."
	missing_text = "Корабль охотников, машина захвата и беглецы раунда на полигоне не воспроизводятся: здесь только снаряжение отряда. Ловушки охотников срабатывают на учебных беглецов."
	option_hints = list(
		"Отряд: Космополиция" = "Форма и бронежилет полиции, шлем, противогаз с громкоговорителем, пистолет M1911 с запасным магазином, наручники, имплант защиты разума и карта со всеми доступами.",
		"Отряд: Контрабандист" = "Советская форма, медвежья шкура или ушанка, противогаз, перчатки, гарнитура и винтовка Мосина.",
		"Отряд: Охотник за головами в броне" = "Броня-скафандр охотника, огнемёт с баком плазмы, стяжки, имплант защиты разума.",
		"Отряд: Охотник за головами с дробовиком" = "Наряд пугала, двуствольный дробовик и шесть травматических патронов, стяжки, имплант защиты разума.",
		"Отряд: Синтетик-охотник за головами" = "Вид синтетика, броня ОМОНа, аптечка, четыре ловушки на беглецов, указатель на корабль охотников, имплант защиты разума.",
	)

/datum/antag_training_program/antag/crew/hunter/apply_choice(datum/antagonist/fugitive_hunter/training/role)
	role.backstory = backstories[choice]

/datum/team/fugitive/training
	name = "Training fugitives"
	show_roundend_report = FALSE

/datum/team/fugitive/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/fugitive/training/roundend_report()
	return

/datum/team/fugitive_hunters/training
	name = "Training fugitive hunters"
	show_roundend_report = FALSE

/datum/team/fugitive_hunters/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/fugitive_hunters/training/roundend_report()
	return

/datum/antagonist/fugitive/training
	name = "Учебный беглец"
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
	silent = FALSE
	var/datum/antag_training_session/training

/datum/antagonist/fugitive/training/threat()
	return 0

/datum/antagonist/fugitive/training/forge_objectives()
	return

/datum/antagonist/fugitive/training/offer_own_character()
	return

/datum/antagonist/fugitive/training/create_team(datum/team/fugitive/new_team)
	fugitive_team = antag_training_crew_team(training)

/datum/antagonist/fugitive/training/greet(back_story)
	antag_training_crew_greet(src, training)

/datum/antagonist/fugitive/training/Destroy()
	. = ..()
	fugitive_team = null
	training = null

/datum/antagonist/fugitive_hunter/training
	name = "Учебный охотник за беглецами"
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
	silent = FALSE
	var/datum/antag_training_session/training

/datum/antagonist/fugitive_hunter/training/threat()
	return 0

/datum/antagonist/fugitive_hunter/training/forge_objectives()
	return

/datum/antagonist/fugitive_hunter/training/create_team(datum/team/fugitive_hunters/new_team)
	hunter_team = antag_training_crew_team(training)
	hunter_team?.backstory = backstory

/datum/antagonist/fugitive_hunter/training/greet()
	antag_training_crew_greet(src, training)

/datum/antagonist/fugitive_hunter/training/Destroy()
	. = ..()
	hunter_team = null
	training = null
