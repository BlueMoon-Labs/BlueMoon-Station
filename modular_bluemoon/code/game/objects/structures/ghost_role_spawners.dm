// Антаг-датумы для разных гостролек, чтобы различать их в орбит панели
/datum/antagonist/ghost_role/inteq
	name = "InteQ Ship Crew"

/datum/antagonist/ghost_role/ghost_cafe
	name = "Ghost Cafe"
	var/area/adittonal_allowed_area

/datum/antagonist/ghost_role/tarkov
	name = "Port Tarkov"

/datum/antagonist/ghost_role/centcom_intern
	name = "Centcom Intern"

/datum/antagonist/ghost_role/ds2
	name = "DS-2 personnel"

/datum/antagonist/ghost_role/space_hotel
	name = "Space Hotel"

/datum/antagonist/ghost_role/hermit
	name = "Hermit"

/datum/antagonist/ghost_role/lavaland_syndicate
	name = "Lavaland Syndicate"

/datum/antagonist/ghost_role/traders
	name  = "Traders"

/datum/antagonist/ghost_role/black_mesa
	name  = "black mesa staff"

/datum/antagonist/ghost_role/hecu
	name  = "HECU squad"

/datum/antagonist/ghost_role/losthecu
	name  = "HECU lost grunt"


mob/living/proc/ghost_cafe_traits(switch_on = FALSE, additional_area)
	if(switch_on)
		AddElement(/datum/element/ghost_role_eligibility, free_ghosting = TRUE)
		AddElement(/datum/element/dusts_on_catatonia)
		var/list/Not_dust_area = list(/area/centcom/holding/exterior,  /area/hilbertshotel)
		if(additional_area)
			Not_dust_area += additional_area
		AddElement(/datum/element/dusts_on_leaving_area, Not_dust_area)

		ADD_TRAIT(src, TRAIT_SIXTHSENSE, GHOSTROLE_TRAIT)
		ADD_TRAIT(src, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
		ADD_TRAIT(src, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT) //The mob can't be made into a random antag, they are still eligible for ghost roles popups.

		var/datum/action/toggle_dead_chat_mob/D = new(src)
		D.Grant(src)
		var/datum/action/disguise/disguise_action = new(src)
		disguise_action.Grant(src)

	else
		RemoveElement(/datum/element/ghost_role_eligibility, free_ghosting = TRUE)
		RemoveElement(/datum/element/dusts_on_catatonia)
		var/datum/antagonist/ghost_role/ghost_cafe/GC = mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe)
		if(GC)
			RemoveElement(/datum/element/dusts_on_leaving_area, list(/area/centcom/holding/exterior,  /area/hilbertshotel, GC.adittonal_allowed_area))
		else
			RemoveElement(/datum/element/dusts_on_leaving_area, list(/area/centcom/holding/exterior,  /area/hilbertshotel))

		REMOVE_TRAIT(src, TRAIT_SIXTHSENSE, GHOSTROLE_TRAIT)
		REMOVE_TRAIT(src, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
		REMOVE_TRAIT(src, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)

		var/datum/action/toggle_dead_chat_mob/D = locate(/datum/action/toggle_dead_chat_mob) in actions
		if(D)
			D.Remove(src)
		var/datum/action/disguise/disguise_action = locate(/datum/action/disguise) in actions
		if(disguise_action)
			if(disguise_action.currently_disguised)
				remove_alt_appearance("ghost_cafe_disguise")
			disguise_action.Remove(src)

/obj/effect/mob_spawn/qareen/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode == "Extended")
		return . = ..()
	else
		return to_chat(user, "<span class='warning'>Игра за ЕРП-антагонистов допускается лишь в Режим Extended!</span>")

/obj/effect/mob_spawn/qareen //not grief antag u little shits
	name = "Qareen - The Horny Spirit"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	short_desc = "Вы Карен!"
	flavour_text = "Вы Карен! Дух похоти! Мирный антагонист! Для общения с другими Карен используйте :q. Ваш прежде мирской дух был запитан \
	инопланетной энергией и преобразован в qareen. Вы не являетесь ни живым, ни мёртвым, а чем-то посередине. Вы способны \
	взаимодействовать с обоими мирами. Вы неуязвимы и невидимы для живых, но не для призраков."
	mob_name = "Qaaren"
	mob_type = 	/mob/living/simple_animal/qareen
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	important_info = "НЕ ГРИФЕРИТЬ, ИНАЧЕ ВАС ЗАБАНЯТ!!"
	death = FALSE
	roundstart = FALSE
	random = FALSE
	uses = 1
	category = "special"

/obj/effect/mob_spawn/qareen/wendigo //not grief antag u little shits
	name = "Woman Wendigo - The Horny Creature"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	short_desc = "Вы Вендиго!"
	flavour_text = "Вендиго. Озабоченный монстр-женщина. Является мирным антагонистом. Если вас тихо-мирно просят сдаться и решить проблемы словами - \
	вы охотно соглашаетесь. Если на вас объявляют охоту по факту вашего существования - жалуетесь администрации. Во внутриигровом \
	плане вы являетесь актёрам, которого прислали ПАКТ."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo-Woman"
	mob_type = /mob/living/carbon/wendigo

/obj/effect/mob_spawn/qareen/wendigo_man //not grief antag u little shits
	name = "Man Werefox - The Horny Creature"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	short_desc = "Вы Лисоборотень!"
	flavour_text = "Озабоченный монстр-мужчина. Является мирным антагонистом. Если вас тихо-мирно просят сдаться и решить проблемы словами - \
	вы охотно соглашаетесь. Если на вас объявляют охоту по факту вашего существования - жалуетесь администрации. Во внутриигровом \
	плане вы являетесь актёрам, которого прислали ПАКТ."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo-Man"
	mob_type = /mob/living/carbon/wendigo/man

/obj/effect/mob_spawn/qareen/wendigo_lore //not grief antag u little shits
	name = "Wendigo - The Horny Creature"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	short_desc = "Вы таинственное нечто необъятных размеров, редкие свидетели прозвали вас Вендиго!"
	flavour_text = "Вендиго. Огромный, рогатый, четвероногий, озабоченный монстр. Является мирным антагонистом. Если вас тихо-мирно просят сдаться и решить проблемы словами - \
	вы охотно соглашаетесь. Если на вас объявляют охоту по факту вашего существования - жалуетесь администрации. Во внутриигровом \
	плане вы являетесь актёрам, которого прислали ПАКТ."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo"
	mob_type = /mob/living/simple_animal/wendigo

/datum/outfit/job/actor_changeling
	name = "Actor Changeling"

	id = /obj/item/card/id/syndicate/advanced

	glasses = /obj/item/clothing/glasses/hud/slaver
	uniform = /obj/item/clothing/under/syndicate/combat
	shoes = /obj/item/clothing/shoes/jackboots/tall
	belt = /obj/item/storage/belt/utility/atmostech
	gloves = /obj/item/clothing/gloves/combat
	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double

	accessory = list(/obj/item/clothing/accessory/permit/special/deviant/lust/changeling)

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie

	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom,
		/obj/item/implant/weapons_auth,
		/obj/item/implant/radio/centcom,
		)

/obj/effect/mob_spawn/human/changeling_extended //not grief antag u little shits
	name = "Changeling - The Horny Creature"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	short_desc = "Вы таинственное нечто и абсолютно идеальный организм, который питается возбуждением своих жертв!"
	flavour_text = "ЕРП-генокрад. Является мирным антагонистом. Если вас тихо-мирно просят сдаться и решить проблемы словами - \
	вы охотно соглашаетесь. Если на вас объявляют охоту по факту вашего существования - жалуетесь администрации. Во внутриигровом \
	плане вы являетесь актёрам, которого прислали ПАКТ."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_clockwork"
	mob_name = "Changeling"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	use_outfit_name = TRUE
	outfit = /datum/outfit/job/actor_changeling
	category = "special"

/obj/effect/mob_spawn/human/changeling_extended/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode == "Extended")
		return . = ..()
	else
		return to_chat(user, "<span class='warning'>Игра за ЕРП-антагонистов допускается лишь в режим Extended!</span>")

/obj/effect/mob_spawn/human/changeling_extended/special(mob/living/new_spawn)
	. = ..()
	var/mob/living/carbon/human/H = new_spawn
	H.mind.make_XenoChangeling()

/obj/effect/mob_spawn/human/slavers
	name = "Slaver"
	short_desc = "Вы работорговец, похищающий и насилующий экипаж. \
	В Extended вы профессиональный актер и получили своеобразное разрешение на свою деятельность. \
	В Dynamic Light вы являетесь настоящим работорговцем, желающим срубить кредитов и удовлетворить все свои грязные фантазии."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	mob_name = "Slaver"
	roundstart = FALSE
	assignedrole = "Slaver"
	category = "Slavers"
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	use_outfit_name = TRUE
	outfit = /datum/outfit/slaver
	antagonist_type = /datum/antagonist/slaver
	category = "special"
	var/first_time = TRUE
	var/isLeader = FALSE

	important_info = "В режим игры Extended вы являетесь ЕРП-антагонистом, в Dynamic Light - минорным антагонистом.\n\
	<B><span class='adminhelp'>Important:</span> Вы можете похищать экипаж, но лишь с преференсами Noncon YES. \
	Если у игрока стоит ASK, вы ОБЯЗАНЫ спросить в LOOC разрешения.\n\
	<span class='adminnotice'>Ни при каких обстоятельствах не играйте в Extended ради прибыли - вы ЕРП-антагонист и вы должны веселить народ, а не запирать их в четырёх стенах до выкупа.</span></B>"

	addition_warning = "Вам поручено проникнуть на станцию и похищать членов экипажа. Как только вы вернетесь в убежище, их можно будет поработить и оценить с помощью консоли.\n\
	Станция может выбрать, платить ли выкуп, и если они это сделают, вы можете отвести похищенного к консоли \
	и экспортировать его обратно. Вашей команде будет перечислен выкуп для покупки нового снаряжения.\n\
	<span class='big warning'>Убедитесь, что вы вернули все предметы похищенного, прежде чем экспортировать их.</span>\n\
	<span class='adminnotice'>У вас есть специальный HUD, который показывает согласие каждого сотрудника в правом нижнем углу. \
	Галочка означает, что вы можете похитить его. Крестик означает «не делать этого». Вопросительный знак означает «сначала спросите».</span>"

	var/announce_text = "Приветствую, Командование Космической Станции.\n\
	На связи Центральное Командование и к вашему сектору были закреплены наши очень хорошие партнёры, которые занимаются развлечением тех сотрудников, кому не хватает адреналина.\n\
	Они оказывают любые и даже экстремальные услуги, каждый из них имеет разрешение на свою деятельность! Если актёров слишком заносит или будут иные проблемы - обращайтесь. \
	Мы поможем вам с ними разобраться!\n\
	Донесите информацию о том, что данные сотрудники авторизованы со стороны ЦК: Командованию и Службе Безопасности. \
	Это в первую очередь актёры для вас, а для экипажа - стрессовое, но развлечение. \
	Поэтому вы должны демонстрировать свою с ними, якобы, настоящую, но на самом деле фиктивную, фальшивую борьбу. \
	Как только Работорговцы начнут проявлять активность, максимум ваших возможностей - поставить Синий Код и просить сотрудников остерегаться незнакомцев. \
	Допустимо применять КЗ в отношении актеров, но с оглядкой на полученный им разрешающий документ (пермит).\n\
	Вам были высланы кредиты для оплаты, которую нужно будет производить как минимум после двадцати минут заключения сотрудников на их аванпосту."

/obj/effect/mob_spawn/human/slavers/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode in list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT))
		if(GLOB.master_mode == ROUNDTYPE_EXTENDED)
			if(isLeader)
				outfit = /datum/outfit/slaver/leader/extended
			else
				outfit = /datum/outfit/slaver/extended

		return ..()
	else
		to_chat(user, span_warning("Игра за слейверов допускается лишь в режим Extended или Dynamic Light!"))
		return

/obj/effect/mob_spawn/human/slavers/special(mob/living/new_spawn)
	var/datum/antagonist/slaver/slaver = new antagonist_type
	var/obj/effect/mob_spawn/human/slavers/all_avaible_spawnpods = list(locate(/obj/effect/mob_spawn/human/slavers))
	var/obj/effect/mob_spawn/human/slavers/one_is_spawnpods = pick(all_avaible_spawnpods)
	if(GLOB.master_mode == ROUNDTYPE_EXTENDED)
		slaver.slaver_outfit = outfit
		slaver.send_to_spawnpoint = FALSE
		if(one_is_spawnpods.first_time)
			print_command_report(src.announce_text, "Central Command")
			var/datum/bank_account/cargo_bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
			cargo_bank.adjust_money(50000)
			for(var/obj/effect/mob_spawn/human/slavers/S in all_avaible_spawnpods)
				S.first_time = FALSE
	slaver.equip_outfit = FALSE
	antagonist_type = slaver
	return ..()

/obj/effect/mob_spawn/human/slavers/master
	name = "Slaver Master"
	desc = "Вы - руководитель отряда наемников, занимающихся похищением экипажа со станций ПАКТа."
	outfit = /datum/outfit/slaver/leader
	antagonist_type = /datum/antagonist/slaver/leader
	isLeader = TRUE

/obj/item/clothing/glasses/hud/slaver/upgraded
	flash_protect = 1

/datum/outfit/slaver/extended
	name = "Actor Slaver"
	accessory = list(/obj/item/clothing/accessory/permit/special/deviant/lust/slavers)
	backpack_contents = list(/obj/item/storage/box/survival,\
							/obj/item/kitchen/knife/combat/survival)

/datum/outfit/slaver/leader/extended
	name = "Actor Slaver Leader"
	accessory = list(/obj/item/clothing/accessory/permit/special/deviant/lust/slavers)
	backpack_contents = list(/obj/item/storage/box/survival,\
							/obj/item/kitchen/knife/combat/survival)

////////////////////////////////////
// Проки для выдачи трейтов и навыков отдельным гостролям, например, DS-2

/obj/effect/mob_spawn/human/ds2/syndicate/enginetech/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn.mind, TRAIT_KNOW_ENGI_WIRES, GHOSTROLE_TRAIT)
	new_spawn.mind.add_skill_modifier(list(/datum/skill_modifier/job/level/wiring/expert, /datum/skill_modifier/job/affinity/wiring))

/obj/effect/mob_spawn/human/ds2/syndicate/researcher/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn.mind, TRAIT_KNOW_CYBORG_WIRES, GHOSTROLE_TRAIT)
	ADD_TRAIT(new_spawn.mind, TRAIT_MECHA_EXPERT, GHOSTROLE_TRAIT)
	new_spawn.mind.add_skill_modifier(list(/datum/skill_modifier/job/level/wiring/trained, /datum/skill_modifier/job/affinity/wiring))

/obj/effect/mob_spawn/human/ds2/syndicate/stationmed/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn.mind, TRAIT_KNOW_MED_SURGERY_T2, GHOSTROLE_TRAIT)
	ADD_TRAIT(new_spawn.mind, TRAIT_QUICK_CARRY, GHOSTROLE_TRAIT)
	ADD_TRAIT(new_spawn.mind, TRAIT_REAGENT_EXPERT, GHOSTROLE_TRAIT)

/obj/effect/mob_spawn/human/inteqspace/engineer/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn.mind, TRAIT_KNOW_ENGI_WIRES, GHOSTROLE_TRAIT)
	ADD_TRAIT(new_spawn.mind, TRAIT_KNOW_CYBORG_WIRES, GHOSTROLE_TRAIT)
	new_spawn.mind.add_skill_modifier(list(/datum/skill_modifier/job/level/wiring/expert, /datum/skill_modifier/job/affinity/wiring))

////////////////////////////////////

/obj/effect/mob_spawn/human/ert
	name = "Emergency Response Team Solder"
	short_desc = "Вы - Член экспедиционного корпуса НТ,ваша задача: Уничтожить логово InteQ. Не покидайте гейт без одобрения администрации. Не пытайтесь в одиночку начать штурм, противник имеют глубоко спланированную оборону, так что дождитесь подкрепления со станции ПАКТа"
	roundstart = FALSE
	death = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	outfit = /datum/outfit/ert/security/green
	assignedrole = "Emergency Response Team Solder"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	category = "ERT"

/obj/effect/mob_spawn/human/ert/engineer
	name = "Emergency Response Team Engineer"
	assignedrole = "Emergency Response Team Engineer"
	outfit = /datum/outfit/ert/engineer

/obj/effect/mob_spawn/human/ert/commander
	name = "Emergency Response Team Commander"
	assignedrole = "Emergency Response Team Commander"
	outfit = /datum/outfit/ert/commander
