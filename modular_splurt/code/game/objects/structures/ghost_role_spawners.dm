/obj/effect/mob_spawn/human/ash_walker
	var/gender_bias

/obj/effect/mob_spawn/human/ash_walker/equip(mob/living/carbon/human/H)
	if(!isnull(gender_bias) && prob(90))
		H.gender = gender_bias
	return ..()

/obj/effect/mob_spawn/human/ash_walker/western
	job_description = "Western Ashwalker's"
	short_desc = "Вы магмовый скиталец ЖЕНСКОГО пола. Ваше племя поклоняется материнскому Тендрилу."
	flavour_text = "Ваш прошлый дом и материнский Тендрил были разрушены чужаками с Холодных Звёзд и те из ваших сородичей, кто остались \
	в живых, покинули южные моря на поиски нового дома. Эти земли хороши для вашего нового дома, ибо обилие Тендрилов дарует этим землям \
	изобилие пищи и материалов для выживания, а также восстановления утерянных знаний и взращивание нового потомства. Однако вы здесь не \
	одни, туземные сородичи обеспокоены вашим присутствием, а особенно знаниями, которыми вы обладаете. Может есть возможность с ними \
	договорится? При этом всём чужаки с Небесных Крепостей добрались и до этих земель. \n\n\
	Будьте на чеку, не дайте трудам потомков, отдавших свои жизни ради вас, пасть Пеплом за зря. Цикл должен продолжаться!"
	important_info = "Защищайте Тендрил своего племени. Охота на шахтёров допустима только в Динамик."
	mob_species = /datum/species/lizard/ashwalker/western
	gender_bias = FEMALE
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/ash_walker/eastern
	job_description = "Eastern Ashwalker's"
	short_desc = "Вы магмовый скиталец МУЖСКОГО пола. Ваше племя поклоняется материнскому Тендрилу."
	flavour_text = "Ваше племя поклоняется матери Некрополю, как вашей Спасительнице и Наставнице. Священные стены дворца Некрополя \
	дали вашему Тендрилу и вашему Роду защиту. Испокон веков, ваша священная обитель дарует вам Дар Перерождения, из цикла в цикл за \
	жертвоприношения матери Некрополю, ради продолжения Великой Охоты. Однако не так давно на ваши земли вторглось Чужеродное Племя. \
	Несмотря на ваше кровное родство в поклонении Великой Матери, не дайте иноземцам осквернить ваше святилище их изуверскими традициями. \
	Сверх этого, с небесных крепостей из Холодного Камня, на ваши земли спустились скитальцы с далёких Звёзд. Их рудокопы накладывают \
	священные пальцы на Некрополь, свои грязные лапы. Не дайте им украсть дары великой матери и лишить вас пищи. \n\n\
	Охота должна быть здравой, цикл должен продолжаться, грядущие поколения должны жить!"
	important_info = "Защищайте Тендрил своего племени. Охота на шахтёров допустима только в Динамик."
	mob_species = /datum/species/lizard/ashwalker/eastern
	gender_bias = MALE
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/ash_walkers_slave
	name = "Ashwalkers Slave"
	mob_name = "Ashwalkers Slave"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	short_desc = "Вы раб или рабыня Пепельных Ящеров с Лаваленда."
	flavour_text = "Вам всё нравится."
	important_info = "Выполняйте ЛЮБЫЕ требования Эшей. Желание сбежать на станцию должно быть минимальным."
	assignedrole = "Ash Walker"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	loadout_enabled = FALSE
	category = "offstation"

/obj/effect/mob_spawn/human/ash_walkers_slave/special_post_appearance(mob/living/new_spawn)
	. = ..()
	new_spawn.grant_language(/datum/language/draconic, source = LANGUAGE_MIND)
	if(!HAS_TRAIT(new_spawn, TRAIT_ROBOTIC_ORGANISM))
		var/obj/item/organ/lungs/ashwalker/lungs = new /obj/item/organ/lungs/ashwalker()
		lungs.Insert(new_spawn, drop_if_replaced = FALSE)
		var/obj/item/organ/eyes/night_vision/eyes = new /obj/item/organ/eyes/night_vision()
		eyes.Insert(new_spawn, drop_if_replaced = FALSE)
	else
		if(!new_spawn.put_in_hands(new /obj/item/device/cooler/lavaland/charged(new_spawn)))
			to_chat(new_spawn, span_reallybig("Не забудьте забрать охладитель под собой.")) // чтобы не упустили из виду при резком спавне
		new_spawn.put_in_hands(new /obj/item/stock_parts/cell/bluespace(new_spawn))

//Portable dangerous-environment sleepers: Spawns in exposed to ash storms shelter.
//Characters in this role could have been conscious for a long time, surviving on the planet. They may also know Draconic language by contacting with ashwalkers.
/obj/effect/mob_spawn/human/wandering_hermit
	name = "Portable Dangerous-Environment Sleeper"
	desc = "The glass is slightly cracked, but there is still air inside. You can see somebody inside. They seems to be sleeping deeply."
	job_description = "Wandering Hermit"
	icon = 'icons/obj/lavaland/spawners.dmi'
	icon_state = "cryostasis_sleeper"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	mob_name = "a wandering hermit"
	short_desc = "You are a hermit abandoned by fate."
	flavour_text = "You've survived weeks in this hellish place. Maybe you want to live here with ash tribe or return to civilisation. \
	Only you know how you got to this planetoid, whether this place in which you woke up was one of your shelters, or you just stumbled upon it."
	can_load_appearance = TRUE
	antagonist_type = /datum/antagonist/ghost_role/hermit
	category = "offstation"

/obj/effect/mob_spawn/human/wandering_hermit/Destroy()
	var/obj/structure/fluff/empty_sleeper/S = new(drop_location())
	S.setDir(dir)
	return ..()

/obj/effect/mob_spawn/human/wandering_hermit/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn,TRAIT_EXEMPT_HEALTH_EVENTS,GHOSTROLE_TRAIT)
	new_spawn.grant_language(/datum/language/draconic)

//Splurt-Specific Space Hotel Staff
/obj/effect/mob_spawn/human/hotel_staff/splurt
	name = "Staff Sleeper"
	desc = "A sleeper designed for long-term stasis between guest visits."
	mob_name = "hotel staff member"
	job_description = "Hotel Staff"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "Вы - член обслуживающего персонала космического отеля."
	flavour_text = "Вы нанялись в качестве персонала общего профиля для уборки, готовки, обслуживания гостей и всего, что прикажет менеджер на время пребывания на борту космического отеля. Ни в коем случае не грубите, не хамите и не ругайтесь с посетителями. Помните, что в вашем случае, клиент всегда прав."
	important_info = "Персоналу отеля запрещается покидать его (кроме неординарных случаев или установки телепада)."
	assignedrole = "Hotel Staff"
	death = FALSE
	roundstart = FALSE
	random = TRUE
	loadout_enabled = TRUE
	can_load_appearance = TRUE
	id_job = "Hotel Staff"
	id = /obj/item/card/id/away/hotel/splurt
	uniform = /obj/item/clothing/under/suit/red
	shoes = /obj/item/clothing/shoes/laceup
	head = /obj/item/clothing/head/hotel
	/* BlueMoon Edit Start: Giving hotel staff their own version of bartender PDA - Flauros
	r_pocket = /obj/item/pda
	*/
	r_pocket = /obj/item/pda/hotelstaff
	// BlueMoon Edit End
	back = /obj/item/storage/backpack/satchel
	ears = /obj/item/radio/headset/headset_srv/hotel
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
						/obj/item/storage/ifak=1)
	make_bank_account = TRUE

/obj/effect/mob_spawn/human/hotel_staff/splurt/security
	name = "Hotel Security Sleeper"
	mob_name = "hotel security member"
	job_description = "Hotel Security"
	short_desc = "Вы - охранник космического отеля."
	flavour_text = "Вы были назначены в этот отель, чтобы защищать интересы компании Nanotrasen, недавно выкупившей его. Ведите себя вежливо, не размахивайте оружием и бронёй, не грубите посетителям."
	important_info = "Персоналу отеля запрещается покидать его (кроме неординарных случаев или установки телепада). Не ведите себя как СБ со станции - вы обычный гражданский и не обучены для борьбы с террористами, предателями, аномалиями и другими неординарными сущностями."
	id_job = "Hotel Security"
	uniform = /obj/item/clothing/under/rank/security/officer/blueshirt
	shoes = /obj/item/clothing/shoes/jackboots
	suit = /obj/item/clothing/suit/armor/vest/blueshirt
	head = /obj/item/clothing/head/helmet/blueshirt
	back = /obj/item/storage/backpack/satchel/sec
	belt = /obj/item/storage/belt/security/full
	id = /obj/item/card/id/away/hotel/splurt/security

/obj/effect/mob_spawn/human/hotel_staff/splurt/manager
	name = "Hotel Manager Sleeper"
	mob_name = "hotel manager"
	job_description = "Hotel Manager"
	short_desc = "Вы - менеджер космического отеля."
	flavour_text = "Вы управляете одним из объектов успешной сети Космических Отелей. Недавно ваша материнская компания была выкуплена Nanotrasen и вам поручили обслуживать некоторые из их станций; в результате вы получили в свое распоряжение набор модных технологий! Защищайте интересы своей материнской компании и следите за тем, чтобы ваш персонал работал на должном уровне, и постарайтесь сделать так, чтобы ваши гости были довольны!"
	important_info = "Персоналу отеля запрещается покидать его (кроме неординарных случаев или установки телепада)."
	objectives = "Don't abandon your assigned hotel. Cater to visiting guests. Maintain good corporate relations and remember: The customer is always right!"
	id_job = "Hotel Manager"
	uniform = /obj/item/clothing/under/suit/black
	suit = /obj/item/clothing/suit/toggle/lawyer/black
	head = /obj/item/clothing/head/beret/black
	ears = /obj/item/radio/headset/headset_srv/hotel/manager
	id = /obj/item/card/id/away/hotel/splurt/manager
	l_pocket = /obj/item/door_remote/away

/obj/effect/mob_spawn/human/hotel_staff/splurt/guest
	name = "Guest Sleeper"
	desc = "Телепортационная штука для гостей."
	uses = -1
	icon = 'icons/obj/telescience.dmi'
	icon_state = "lpad-idle"
	short_desc = "Вы - гость дорогого космического отеля."
	flavour_text = "Вы заплатили кучу денег за пребывание в этом месте и вы ДОЛЖНЫ оторваться по полной!!"
	job_description = "Hotel Tourist"
	id_job = "Hotel Tourist"
	id = /obj/item/card/id/away/hotel/splurt/tourist
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/rank/civilian/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	head = /obj/item/clothing/head/beret/black
	r_pocket = /obj/item/pda
	back = /obj/item/storage/backpack
	make_bank_account = TRUE // BLUEMOON ADD
	starting_money = 10000 // BLUEMOON ADD

//Forgotten syndicate ship

/obj/effect/mob_spawn/human/inteqspace
	name = "InteQ Ship Crew Member"
	roundstart = FALSE
	death = FALSE
	show_flavour = FALSE
	loadout_enabled = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы - Оперативник Авангарда InteQ на старом корабле, застрявшем во враждебном космосе."
	flavour_text = "Ваш корабль причалил после долгого перерыва где-то во враждебном пространстве, сообщив о неисправности. Вы застряли здесь, зная, что рядом находится станция Nanotrasen. Почините корабль, найдите способ обеспечить его энергией и выполняйте приказы Капитана."
	important_info = "Установите полную власть над локальным сектором, защитите корабль и секретные документы в рюкзаке ценой своей жизни."
	can_load_appearance = TRUE
	outfit = /datum/outfit/inteqspace/inteq_crew
	assignedrole = ROLE_GHOSTROLE_INTEQ
	antagonist_type = /datum/antagonist/ghost_role/inteq
	loadout_enabled = TRUE
	category = "inteq"

/obj/effect/mob_spawn/human/inteqspace/engineer
	name = "InteQ Field Engineer"
	short_desc = "Вы - Полевой Инженер Авангарда InteQ, очнувшийся на захваченной базе в враждебном космосе."
	flavour_text = "Вы очнулись в техническом отсеке базы InteQ, которая теперь под контролем врага. Корабль InteQ причалил рядом после долгого перерыва. Ваша задача – починить корабль и базу, а так же обеспечить его энергией. Снабдите Авангард ресурсами и технологиями и выполняйте приказы Капитана."
	important_info = "Установите полную власть над локальным сектором, защитите корабль и секретные документы в рюкзаке ценой своей жизни."
	can_load_appearance = TRUE
	outfit = /datum/outfit/inteqspace/inteq_engineer

/obj/effect/mob_spawn/human/inteqspace/dyson_gate
	name = "InteQ Dyson Sphere Crew Member"
	short_desc = "Вы - Оперативник  InteQ на обшивке Дайсон Сферы, и на вашей части базы произошло ЧП."
	flavour_text = "Вы являетесь частью персонала,что обслуживает аванпост на обшивке Дайсон Сферы. За вашу смену произошло много ЧП и сейчас на базе орудуют монстры, что явились снаружи. \
					Пакт каким то образом смогли получить коды от Гейта и начали развертывать свои силы."
	important_info = "Востановите ваш аванпост и приготовтесь отражать нападение. Не нападайте на лагерь Пакта, пока они сами не нападут."

/datum/outfit/inteqspace/inteq_crew/post_equip(mob/living/carbon/human/H)
	H.faction |= ROLE_INTEQ

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_GHOST_INTEQ)
	R.freqlock = TRUE
	R.independent = TRUE

/datum/outfit/inteqspace/inteq_engineer/post_equip(mob/living/carbon/human/H)
	H.faction |= ROLE_INTEQ

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_GHOST_INTEQ)
	R.freqlock = TRUE
	R.independent = TRUE

/obj/effect/mob_spawn/human/inteqspace/special(mob/living/new_spawn)
	. = ..()
	new_spawn.grant_language(/datum/language/old_codes, source = LANGUAGE_MIND)

	var/obj/item/implant/anchor/ghost_anchor = new
	ghost_anchor.implant(new_spawn, null, TRUE)

/obj/effect/mob_spawn/human/inteqspace/hostage
	name = "InteQ Hostage"
	short_desc = "Вы - оказались в больших неприятностях в плену."
	flavour_text = "Вы плохо помните как вы тут оказались, возможно вас накачали чем то. Вы до конца не уверены, продали ли вас в рабство либо похитили, в любом случае у вас большие неприятности. Люди с оружием которые пришли сюда вряд ли собираются вас спасти, возможно это отряд головорезов, что избавляется от свидетелей, по всей видимости те выполняют приказ, им лучше не попадаться на глаза. Если вы находитесь тут то вряд ли похитители хотят вас убить, если дать им повод то вы пополните ряды ваших коллег по несчастью."
	important_info = "Запрещено пытаться сбежать и сопротивляться без веских причин как серьёзная угроза жизни от агентов InteQ. Побег только с разрешения администрации."
	can_load_appearance = TRUE
	outfit = /datum/outfit/inteqspace/inteq_hostage

/obj/effect/mob_spawn/human/inteqspace/hostage/New()
	. = ..()
	if(GLOB.master_mode == "Extended")
		important_info = "Запрещено пытаться сбежать и сопротивляться без веских причин как серьёзная угроза жизни от сотрудников Космической Полиции и Солнечной. Побег только с разрешения администрации."
		category = "sol"

/obj/effect/mob_spawn/human/inteqspace/captain
	name = "InteQ Ship Captain"
	short_desc = "Вы - Лидер Авангарда InteQ на старом корабле, застрявшем во враждебном космосе."
	flavour_text = "Ваш корабль причалил после долгого перерыва где-то во враждебном пространстве, сообщив о неисправности. Вы застряли здесь, зная, что рядом находится станция Nanotrasen. Командуйте своим экипажем и исследуйте свою территорию, чтобы закрепить свое местоположение."
	important_info = "Установите полную власть над локальным сектором, защитите корабль и секретные документы в рюкзаке ценой своей жизни."
	can_load_appearance = TRUE
	outfit = /datum/outfit/inteqspace/inteq_captain

/datum/outfit/inteqspace/inteq_captain/post_equip(mob/living/carbon/human/H)
	H.faction |= ROLE_INTEQ

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_GHOST_INTEQ)
	R.freqlock = TRUE
	R.independent = TRUE

/obj/effect/mob_spawn/human/inteqspace/captain/dyson_gate
	name = "InteQ Dyson Sphere Captain"
	short_desc = "Вы -Глава Авангарда InteQ в отпуске, и проходите его в выделенной для вас Зоне."
	flavour_text = "Прошло уже три дня, как вы развлекались с одной из «игрушек», что вы прихватили из карцеров на базе. Но сейчас там обьявлен полный карантин и вам туда не пройти. Вы можете продолжить свой неожиданный отпуск или подняться выше, на орбитальную часть, где находиться аванпост с остатками сил."
	important_info = "Не пытайтесь проникнуть в подземную часть базы, где обьявлена биологическая тревога. Не напдайте на лагерь Пакта, пока они сами не нападут."

/obj/effect/mob_spawn/human/inteqspace/captain/Destroy()
	new/obj/structure/fluff/empty_sleeper/syndicate/captain(get_turf(src))
	return ..()

/datum/outfit/inteqspace
	implants = list(/obj/item/implant/weapons_auth)
	back = /obj/item/storage/backpack/duffelbag/syndie/inteq

/datum/outfit/inteqspace/inteq_crew
	name = "InteQ Ship Crew Member"

	suit = /obj/item/clothing/suit/armor/inteq
	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	gloves = /obj/item/clothing/gloves/combat

	head = /obj/item/clothing/head/helmet/swat/inteq
	mask = /obj/item/clothing/mask/gas/inteq
	ears = /obj/item/radio/headset/ghost_inteq
	belt = /obj/item/storage/belt/military/assault/inteq_crew

	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double

	id = /obj/item/card/id/inteq/crew_id
	backpack_contents = list(/obj/item/paper/fluff/ruins/forgottenship/password)
	implants = list(/obj/item/implant/deathrattle/inteqcrew, /obj/item/implant/weapons_auth)

/datum/outfit/inteqspace/inteq_engineer
	name = "InteQ Field Engineer"

	suit = /obj/item/clothing/suit/armor/inteq
	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	gloves = /obj/item/clothing/gloves/combat

	head = /obj/item/clothing/head/helmet/swat/inteq
	mask = /obj/item/clothing/mask/gas/inteq
	glasses = /obj/item/clothing/glasses/welding
	ears = /obj/item/radio/headset/ghost_inteq
	belt = /obj/item/storage/belt/utility/inteq

	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double

	id = /obj/item/card/id/inteq/engineer
	backpack_contents = list(/obj/item/paper/fluff/ruins/forgottenship/password, /obj/item/restraints/handcuffs)
	implants = list(/obj/item/implant/deathrattle/inteqcrew, /obj/item/implant/weapons_auth)

/datum/outfit/inteqspace/inteq_hostage
	name = "InteQ Hostage"

	uniform = /obj/item/clothing/under/rank/prisoner
	shoes = /obj/item/clothing/shoes/sneakers/orange
	id = /obj/item/card/id/prisoner
	ears = /obj/item/radio/headset/ghost_inteq

/datum/outfit/inteqspace/inteq_captain
	name = "InteQ Ship Captain"

	suit = /obj/item/clothing/suit/armor/inteq/honorable_vanguard
	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	gloves = /obj/item/clothing/gloves/combat

	head = /obj/item/clothing/head/HoS/pmc_leader_beret
	mask = /obj/item/clothing/mask/gas/inteq
	ears = /obj/item/radio/headset/ghost_inteq/leader
	belt = /obj/item/storage/belt/military/assault/inteq_captain

	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double

	id = /obj/item/card/id/inteq/captain_id
	backpack_contents = list(/obj/item/documents/syndicate/red, /obj/item/paper/fluff/ruins/forgottenship/password)
	implants = list(/obj/item/implant/deathrattle/inteqcrew, /obj/item/implant/weapons_auth)

// Ghost Cafe Spawner (VR Version)

/obj/effect/mob_spawn/human/ghostcafeVR
	name = "Ghost Cafe VR Sleeper"
	uses = -1
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_name = "a ghost cafe VR visitor"
	roundstart = FALSE
	anchored = TRUE
	density = FALSE
	death = FALSE
	assignedrole = "Ghost Cafe VR Visitor"
	short_desc = "You are a Ghost Cafe VR Visitor!"
	flavour_text = "You know one thing for sure. You arent actually alive. Are you in a simulation?"
	skip_reentry_check = TRUE
	banType = ROLE_GHOSTCAFE
	can_load_appearance = 2 //(Forces player to load character appearance)
	antagonist_type = /datum/antagonist/ghost_role/ghost_cafe

/obj/effect/mob_spawn/human/ghostcafeVR/special(mob/living/carbon/human/new_spawn)
	if(new_spawn.client)
		new_spawn.client.prefs.copy_to(new_spawn)
		var/datum/outfit/O = new /datum/outfit/ghostcafeVR()
		O.equip(new_spawn, FALSE, new_spawn.client)
		SSjob.equip_loadout(null, new_spawn)
		SSjob.post_equip_loadout(null, new_spawn)
		SSquirks.AssignQuirks(new_spawn, new_spawn.client, TRUE, TRUE, null, FALSE, new_spawn)
		SSlanguage.AssignLanguage(new_spawn, new_spawn.client)
		ADD_TRAIT(new_spawn, TRAIT_SIXTHSENSE, GHOSTROLE_TRAIT)
		ADD_TRAIT(new_spawn, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
		ADD_TRAIT(new_spawn, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT) //The mob can't be made into a random antag, they are still eligible for ghost roles popups.

/datum/outfit/ghostcafeVR
	name = "ID, jumpsuit and shoes"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black

/datum/outfit/ghostcafeVR/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(isplasmaman(H))
		head = /obj/item/clothing/head/helmet/space/plasmaman
		uniform = /obj/item/clothing/under/plasmaman
		l_hand= /obj/item/tank/internals/plasmaman/belt/full
		mask = /obj/item/clothing/mask/breath
		return

/datum/outfit/ghostcafeVR/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.internal = H.get_item_for_held_index(1)
	H.update_action_buttons_icon(1)

