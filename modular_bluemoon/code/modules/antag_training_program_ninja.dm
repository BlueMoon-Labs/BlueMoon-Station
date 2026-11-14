/datum/antag_training_program/antag/ninja
	name = "Космический ниндзя"
	category = "Чужаки"
	desc = "Снаряжение одного из трёх путей Клана Паука, костюм с полным зарядом, дрейн энергии из щитка, SMES и батарей, учебный взлом консолей записей и связи в станционном макете, паучий заряд."
	icon = "user-ninja"
	color = "green"
	learn = "Три пути Клана Паука|Заряд костюма и дрейн энергии|Взлом консолей записей и связи|Паучий заряд"
	difficulty = 3
	sector = "station"
	antag_type = /datum/antagonist/ninja/training
	choice_prompt = "Путь"
	choices = list("classic" = "Классический", "ronin" = "Ронин", "wisdom" = "Мудрость")
	options = list("Полный заряд", "Новый паучий заряд", "Учебная цель: подрыв")
	var/static/list/path_outfits = list(
		"classic" = /datum/outfit/ninja,
		"ronin" = /datum/outfit/ninja_ronin,
		"wisdom" = /datum/outfit/ninja_wisdom,
	)
	var/static/list/path_hints = list(
		"classic" = "Энергокатана с рывками, сюрикены, энергосеть, ЭМИ-импульс, невидимость и адреналин.",
		"ronin" = "Двуручная энергонагината с рывками и отражением выстрелов, резонанс, оглушающий всех рядом, боевые сюрикены и адреналин. Броня крепче, взлом вдвое быстрее, заряда меньше.",
		"wisdom" = "Без оружия: спящий карп, ЭМИ-импульс, энергосеть и глубокая невидимость, реактивный ранец в рюкзаке. Заряда больше, расход меньше, взлом медленнее.",
	)

/datum/antag_training_program/antag/ninja/New()
	. = ..()
	option_hints = list(
		"Полный заряд" = "Батарея надетого костюма заполнится до предела, а адреналин снова будет готов. В раунде заряд берут только дрейном перчатками, а адреналин перезаряжают радием.",
		"Новый паучий заряд" = "Паучий заряд в руки. Он срабатывает только в месте, указанном заданием: сначала возьмите «Учебная цель: подрыв». В раунде заряд один, а место - отсек станции.",
		"Учебная цель: подрыв" = "Задание подорвать паучий заряд в станционном макете. Установите заряд на стену или предмет макета и дождитесь взрыва - задание засчитается.",
	)
	for(var/key in choices)
		option_hints[choice_option(key)] = "[path_hints[key]] Смена пути перевыдаёт роль и всё снаряжение: надетое и носимое заменяется комплектом пути."

/datum/antag_training_program/antag/ninja/apply_choice(datum/antagonist/ninja/training/role)
	role.path_outfit = path_outfits[choice] || path_outfits["classic"]
	role.path_key = choice
	role.path_name = choices[choice]

/datum/antag_training_program/antag/ninja/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/ninja/training/ninja = role(session)
	if(!ninja)
		to_chat(user, span_warning("Роль ниндзя снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Полный заряд")
			ninja.full_charge()
		if("Новый паучий заряд")
			issue_charge(session, user)
		if("Учебная цель: подрыв")
			assign_bombing(session, user, ninja)
	return TRUE

/datum/antag_training_program/antag/ninja/proc/issue_charge(datum/antag_training_session/session, mob/living/user)
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return null
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/grenade/plastic/c4/ninja/training/charge = session.arena.issue_item(/obj/item/grenade/plastic/c4/ninja/training, get_turf(user), 1, session)
	if(!charge)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return null
	user.put_in_hands(charge)
	to_chat(user, span_notice("Паучий заряд у вас. Он сработает только там, куда указывает задание «Учебная цель: подрыв»."))
	return charge

/datum/antag_training_program/antag/ninja/proc/assign_bombing(datum/antag_training_session/session, mob/living/user, datum/antagonist/ninja/training/ninja)
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	var/turf/spot = station?.landmark_turf("vault")
	if(!spot)
		to_chat(user, span_warning("Место подрыва - в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."))
		return FALSE
	ninja.assign_bombing(get_area(spot))
	return TRUE

/datum/antagonist/ninja/training
	name = "Учебный космический ниндзя"
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
	silent = TRUE
	give_objectives = FALSE
	var/datum/antag_training_session/training
	var/path_outfit = /datum/outfit/ninja
	var/path_key = "classic"
	var/path_name = "Классический"
	var/datum/objective/plant_explosive/antag_training/bomb_objective

/datum/antagonist/ninja/training/on_gain()
	. = ..()
	greet()

/datum/antagonist/ninja/training/threat()
	return 0

/datum/antagonist/ninja/training/choosePath(mob/living/carbon/human/ninja = owner.current)
	if(!istype(ninja))
		return
	ninja_outfit = path_outfit
	give_equipment = TRUE
	ninja.delete_equipment()
	equip_space_ninja(ninja)
	for(var/obj/item/implant/explosive/microbomb in ninja.implants)
		qdel(microbomb)
	var/obj/item/grenade/plastic/c4/ninja/issued = ninja.l_store
	if(istype(issued) && !istype(issued, /obj/item/grenade/plastic/c4/ninja/training))
		qdel(issued)
		ninja.equip_to_slot_or_del(new /obj/item/grenade/plastic/c4/ninja/training(ninja), ITEM_SLOT_LPOCKET)

/datum/antagonist/ninja/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/ninja/training/proc/brief()
	to_chat(owner.current, briefing())
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ninja_greeting.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/antagonist/ninja/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка космического ниндзя. Путь «[path_name]»."),
		span_notice("«Toggle Ninja Suit» запускает костюм: он запирается на вас и открывает способности. Каждая тратит заряд батареи, а включённый костюм расходует его и сам."),
		span_notice("Заряд пополняется дрейном: включите перчатки кнопкой «Toggle interaction» и коснитесь пустой рукой щитка или SMES в щитовой макета, батареи или кабеля под током. Консоли связи в кабинете главы и записей охраны в серверной макета - учебные: взлом пройдёт как в раунде, но станция о нём не узнает. В раунде взлом записей объявляет арестованным весь экипаж, взлом связи насылает на станцию новую угрозу, а ИИ станции узнаёт о взломе сразу."),
		span_notice("Микробомбы на полигоне нет: после смерти вы восстановитесь в вестибюле хаба. В раунде она взрывается, когда вы умираете."),
		span_notice("«Пульт полигона», раздел «Моя роль»: полный заряд, паучий заряд, учебная цель подрыва и смена пути."),
	), "<br>")

/datum/antagonist/ninja/training/proc/full_charge()
	var/mob/living/carbon/human/body = owner.current
	var/obj/item/clothing/suit/space/space_ninja/suit = istype(body) ? body.wear_suit : null
	if(!istype(suit) || !suit.cell)
		to_chat(body, span_warning("Наденьте костюм ниндзя: заряжается батарея надетого костюма."))
		return FALSE
	suit.cell.give(suit.cell.maxcharge)
	suit.a_boost = TRUE
	to_chat(body, span_notice("Заряд костюма: [DisplayEnergy(suit.cell.charge)]. Адреналин готов."))
	return TRUE

/datum/antagonist/ninja/training/proc/assign_bombing(area/target_area)
	drop_bombing()
	bomb_objective = new
	bomb_objective.owner = owner
	bomb_objective.detonation_location = target_area
	bomb_objective.explanation_text = "Учебный подрыв: взорвите паучий заряд в станционном макете."
	objectives += bomb_objective
	to_chat(owner.current, span_notice("Учебная цель: подорвите паучий заряд в станционном макете. Нет заряда - кнопка «Новый паучий заряд». В раунде место - один отсек станции, и только там заряд срабатывает."))

/datum/antagonist/ninja/training/proc/drop_bombing()
	if(!bomb_objective)
		return
	objectives -= bomb_objective
	QDEL_NULL(bomb_objective)

/datum/antagonist/ninja/training/proc/charge_detonated(turf/blast_turf)
	if(!bomb_objective || bomb_objective.completed || !blast_turf || get_area(blast_turf) != bomb_objective.detonation_location)
		return FALSE
	bomb_objective.completed = TRUE
	to_chat(owner.current, span_notice("Учебный подрыв выполнен. В раунде задание засчитывается в момент взрыва."))
	return TRUE

/datum/antagonist/ninja/training/on_removal()
	var/mob/living/carbon/human/body = owner.current
	var/obj/item/clothing/suit/space/space_ninja/suit = istype(body) ? body.wear_suit : null
	if(istype(suit) && suit.affecting == body)
		suit.cancel_stealth()
		suit.unlock_suit(body)
		suit.s_initialized = FALSE
	if(path_key == "wisdom" && istype(owner.martial_art, /datum/martial_art/the_sleeping_carp))
		owner.martial_art.remove(body)
	return ..()

/datum/antagonist/ninja/training/Destroy()
	drop_bombing()
	QDEL_LIST(objectives)
	training = null
	return ..()

/// Задание подрыва полигона: засчитывается в окне роли, раунд его не засчитывает.
/datum/objective/plant_explosive/antag_training
	name = "training bombing"

/datum/objective/plant_explosive/antag_training/check_completion()
	return FALSE

/datum/objective/plant_explosive/antag_training/find_target(dupe_search_range, blacklist)
	return null

/obj/item/grenade/plastic/c4/ninja/training
	desc = "Паучий заряд полигона. Срабатывает только в месте учебного задания подрыва, сила взрыва как у настоящего."

/obj/item/grenade/plastic/c4/ninja/training/prime(mob/living/lanced_by)
	var/mob/bomber = detonator
	var/turf/blast_turf = target ? get_turf(target) : get_turf(src)
	detonator = null
	. = ..()
	var/datum/antagonist/ninja/training/ninja = bomber?.mind?.has_antag_datum(/datum/antagonist/ninja/training)
	ninja?.charge_detonated(blast_turf)

/// Макет консоли станционного макета: внешне консоль раунда, но не её подтип, поэтому ни записи, ни шаттл, ни поиск консолей раунда его не видят.
/obj/machinery/computer/antag_training_mockup
	name = "training console"
	desc = "Макет консоли. К сетям станции не подключён: на нём отрабатывают взлом перчатками ниндзя."
	/// Что в раунде сделал бы взлом настоящей консоли.
	var/round_effect

/obj/machinery/computer/antag_training_mockup/ninjadrain_act(obj/item/clothing/suit/space/space_ninja/ninja_suit, mob/living/carbon/human/ninja, obj/item/clothing/gloves/space_ninja/ninja_gloves)
	if(!ninja_suit || !ninja || !ninja_gloves)
		return INVALID_DRAIN
	to_chat(ninja, span_notice("Идёт учебный взлом: [src]..."))
	if(!do_after(ninja, ninja_suit.s_longdelay, target = src) || !ninja_gloves.candrain)
		return
	to_chat(ninja, span_notice("Учебный взлом выполнен. [round_effect]"))
	log_game("[key_name(ninja)] на тренировочном полигоне взламывает учебную консоль [src] перчатками ниндзя.")

/obj/machinery/computer/antag_training_mockup/ui_interact(mob/user, datum/tgui/ui)
	var/mob/living/carbon/human/ninja = user
	var/obj/item/clothing/gloves/space_ninja/gloves = istype(ninja) ? ninja.gloves : null
	if(istype(gloves) && gloves.candrain)
		return
	to_chat(user, span_warning("Макет консоли: к сетям станции не подключён. Взламывать его можно перчатками ниндзя."))

/obj/machinery/computer/antag_training_mockup/records
	name = "training security records console"
	desc = "Макет консоли записей охраны. К базе экипажа не подключён: на нём отрабатывают взлом перчатками ниндзя."
	icon_screen = "security"
	icon_keyboard = "security_key"
	light_color = LIGHT_COLOR_RED
	round_effect = "В раунде все записи охраны получили бы статус «Арест», а ИИ станции узнал бы о взломе с его начала."

/obj/machinery/computer/antag_training_mockup/comms
	name = "training communications console"
	desc = "Макет консоли связи. К сетям станции и ЦК не подключён: на нём отрабатывают взлом перчатками ниндзя."
	icon_screen = "comm"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	round_effect = "В раунде на станцию пришла бы новая угроза - одиночный оперативник, пираты или метеоры - с объявлением на всю станцию, а ИИ станции узнал бы о взломе с его начала."
