/datum/antag_training_program/antag/nukeop
	name = "Ядерный оперативник InteQ"
	category = "Чужаки"
	sector = "station"
	antag_type = /datum/antagonist/nukeop/training
	desc = "Аплинк-рация оперативника без подкреплений и боргов, учебные бомба и диск в хранилище станционного макета, короткий отсчёт и учебный взрыв, роль лидера и клоуна-оперативника."
	icon = "radiation"
	color = "red"
	learn = "Аплинк-рация оперативника|Диск и бомба в хранилище|Взвод бомбы и отсчёт|Роль лидера|Клоун-оперативник и его магазин"
	difficulty = 2
	choice_prompt = "Сменить роль"
	choices = list("operative" = "Оперативник", "leader" = "Лидер", "clownop" = "Клоун-оперативник")
	options = list("Пополнить ТК", "Вернуть бомбу и диск")
	var/nuke_code
	var/datum/team/nuclear/training/team
	var/datum/objective/antag_training/detonation_objective
	var/datum/weakref/session_ref
	var/datum/weakref/bomb_ref
	var/datum/weakref/disk_ref
	var/datum/weakref/code_paper_ref

/datum/antag_training_program/antag/nukeop/New()
	. = ..()
	nuke_code = random_nukecode()
	var/obj/machinery/nuclearbomb/real_bomb = /obj/machinery/nuclearbomb
	var/telecrystals = antag_training_nukeop_telecrystals()
	option_hints = list(
		"Пополнить ТК" = "Счёт аплинк-рации пополнится до [telecrystals] ТК, а потерянная рация выдаётся заново. В раунде кредиты дают один раз, их распределяет лидер.",
		"Вернуть бомбу и диск" = "Учебные бомба и диск вернутся в хранилище станционного макета, бомба - выключенной, даже если отсчёт уже идёт. Если макет выгружался, они появятся заново.",
	)
	option_hints[choice_option("operative")] = "Оперативник: аплинк-рация, пистолет, учебный пинпоинтер диска, код бомбы в заметках. Смена роли перевыдаёт роль, команда, код и купленное остаются."
	option_hints[choice_option("leader")] = "Лидер: ещё перчатки крав-мага, карта лидера, командная рация и бумага с кодом. Устройство объявления войны не выдаётся: в раунде оно объявляет станции войну с базы, у настоящей бомбы отсчёт не меньше [initial(real_bomb.minimum_timer_set)] с."
	option_hints[choice_option("clownop")] = "Клоун-оперативник: боевые клоунские ботинки, маска клоуна, гудок и цветок со смазкой, пистолета в наборе нет, а аплинк-рация открывает магазин клоунов-оперативников - бананиевые меч и щит, пирожковая пушка, бомбанан. Подкрепления клоунов и Clown Bomb на полигоне не продаются. Смена роли перевыдаёт роль, команда, код и купленное остаются. В раунде клоуны-оперативники - отдельный режим вместо ядерного отряда."

/proc/antag_training_nukeop_telecrystals()
	var/datum/outfit/inteq/training/kit = /datum/outfit/inteq/training
	return initial(kit.tc)

/datum/antag_training_program/antag/nukeop/grant_role(datum/antag_training_session/session)
	if(choice != "clownop")
		return ..()
	if(QDELETED(session.avatar_mind) || !session.avatar_mind.current)
		return FALSE
	var/datum/antagonist/nukeop/training/clownop/clown = new
	clown.training = session
	apply_choice(clown)
	return !!session.avatar_mind.add_antag_datum(clown)

/datum/antag_training_program/antag/nukeop/apply_choice(datum/antagonist/nukeop/training/role)
	role.leader = (choice == "leader")
	if(role.leader)
		role.nukeop_outfit = /datum/outfit/inteq/training/leader
	else if(!istype(role, /datum/antagonist/nukeop/training/clownop))
		role.nukeop_outfit = /datum/outfit/inteq/training

/datum/antag_training_program/antag/nukeop/setup(datum/antag_training_session/session)
	session_ref = WEAKREF(session)
	. = ..()
	if(.)
		INVOKE_ASYNC(src, PROC_REF(stock_vault), session)

/datum/antag_training_program/antag/nukeop/proc/stock_vault(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena?.sectors["station"]
	if(!station?.load() || QDELETED(src) || QDELETED(session) || session.finished)
		return FALSE
	return !place_kit(session)

/datum/antag_training_program/antag/nukeop/proc/training_team()
	if(team)
		return team
	team = new
	team.memorized_code = nuke_code
	detonation_objective = new
	detonation_objective.team = team
	detonation_objective.explanation_text = "Учебная задача: вставьте учебный диск в учебную бомбу в хранилище станционного макета, введите код, взведите бомбу и дождитесь учебного взрыва."
	team.objectives += detonation_objective
	return team

/datum/antag_training_program/antag/nukeop/proc/training_bomb()
	var/obj/machinery/nuclearbomb/training/bomb = bomb_ref?.resolve()
	return QDELETED(bomb) ? null : bomb

/datum/antag_training_program/antag/nukeop/proc/training_disk()
	var/obj/item/disk/nuclear/training/disk = disk_ref?.resolve()
	return QDELETED(disk) ? null : disk

/// Ставит учебные бомбу и диск в хранилище макета, создавая недостающие. Возвращает причину отказа или null.
/datum/antag_training_program/antag/nukeop/proc/place_kit(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena?.sectors["station"]
	var/turf/vault = station?.landmark_turf("vault")
	if(!vault)
		return "Хранилище - в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."
	var/turf/disk_spot = get_step(vault, SOUTH)
	if(!isfloorturf(disk_spot) || !session.arena.owns_area(get_area(disk_spot)))
		disk_spot = vault
	var/obj/machinery/nuclearbomb/training/bomb = training_bomb()
	if(bomb)
		bomb.reset_training()
		bomb.forceMove(vault)
	else
		bomb = session.arena.issue_item(/obj/machinery/nuclearbomb/training, vault, 1, session)
		if(!bomb)
			return "Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."
		bomb.r_code = nuke_code
		bomb.program_ref = WEAKREF(src)
		bomb_ref = WEAKREF(bomb)
	var/obj/item/disk/nuclear/training/disk = training_disk()
	if(disk)
		var/mob/holder = disk.loc
		if(ismob(holder))
			holder.temporarilyRemoveItemFromInventory(disk, TRUE)
		disk.forceMove(disk_spot)
	else
		disk = session.arena.issue_item(/obj/item/disk/nuclear/training, disk_spot, 1, session)
		if(!disk)
			return "Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."
		disk_ref = WEAKREF(disk)
	return null

/datum/antag_training_program/antag/nukeop/proc/nuke_detonated(obj/machinery/nuclearbomb/training/bomb)
	if(detonation_objective && !detonation_objective.completed)
		detonation_objective.completed = TRUE
		for(var/datum/mind/member as anything in team?.members)
			var/datum/antagonist/nukeop/training/operative = member.has_antag_datum(/datum/antagonist/nukeop/training)
			operative?.update_static_data_for_all_viewers()
	var/datum/antag_training_session/session = session_ref?.resolve()
	if(!session || place_kit(session))
		bomb.reset_training()

/datum/antag_training_program/antag/nukeop/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/nukeop/training/operative = role(session)
	if(!operative)
		to_chat(user, span_warning("Роль оперативника снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Пополнить ТК")
			return refill_uplink(session, user, operative)
		if("Вернуть бомбу и диск")
			if(world.time < session.next_supply_at)
				to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
				return FALSE
			session.next_supply_at = world.time + 1 SECONDS
			var/problem = place_kit(session)
			if(problem)
				to_chat(user, span_warning(problem))
				return FALSE
			to_chat(user, span_notice("Учебные бомба и диск - в хранилище станционного макета, бомба выключена. Код: [nuke_code]."))
	return TRUE

/datum/antag_training_program/antag/nukeop/proc/refill_uplink(datum/antag_training_session/session, mob/living/user, datum/antagonist/nukeop/training/operative)
	var/telecrystals = antag_training_nukeop_telecrystals()
	var/datum/component/uplink/hidden = operative.training_uplink()
	if(hidden)
		hidden.telecrystals = max(hidden.telecrystals, telecrystals)
		SStgui.update_uis(hidden)
		to_chat(user, span_notice("На счету аплинк-рации [hidden.telecrystals] ТК."))
		return TRUE
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/inteq/uplink/radio/nuclear/training/radio = session.arena.issue_item(/obj/item/inteq/uplink/radio/nuclear/training, get_turf(user), 1, session)
	if(!radio)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	user.put_in_hands(radio)
	operative.uplink_ref = WEAKREF(radio)
	operative.sync_uplink()
	to_chat(user, span_notice("Новая аплинк-рация на [telecrystals] ТК у вас."))
	return TRUE

/datum/antag_training_program/antag/nukeop/Destroy()
	var/obj/machinery/nuclearbomb/training/bomb = training_bomb()
	if(bomb)
		qdel(bomb)
	var/obj/item/disk/nuclear/training/disk = training_disk()
	if(disk)
		qdel(disk)
	bomb_ref = null
	disk_ref = null
	code_paper_ref = null
	session_ref = null
	detonation_objective = null
	QDEL_NULL(team)
	return ..()

/datum/antagonist/nukeop/training
	name = "Учебный ядерный оперативник InteQ"
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
	always_new_team = TRUE
	send_to_spawnpoint = FALSE
	nukeop_outfit = /datum/outfit/inteq/training
	var/datum/antag_training_session/training
	var/leader = FALSE
	var/datum/weakref/uplink_ref

/datum/antagonist/nukeop/training/threat()
	return 0

/datum/antagonist/nukeop/training/create_team(datum/team/nuclear/new_team)
	var/datum/antag_training_program/antag/nukeop/program = training?.program
	nuke_team = istype(program) ? program.training_team() : new /datum/team/nuclear/training
	assign_nuke()

/datum/antagonist/nukeop/training/assign_nuke()
	var/datum/antag_training_program/antag/nukeop/program = training?.program
	if(nuke_team && istype(program))
		nuke_team.memorized_code = program.nuke_code

/datum/antagonist/nukeop/training/give_alias()
	return

/datum/antagonist/nukeop/training/equip_op()
	var/mob/living/carbon/human/body = owner.current
	if(istype(body))
		var/datum/outfit/antag_training/participant_kit = /datum/outfit/antag_training
		var/obj/item/pocketed = body.l_store
		if(pocketed?.type == initial(participant_kit.l_pocket) && body.back)
			body.temporarilyRemoveItemFromInventory(pocketed, TRUE)
			if(!SEND_SIGNAL(body.back, COMSIG_TRY_STORAGE_INSERT, pocketed, null, TRUE, TRUE))
				pocketed.forceMove(body.drop_location())
		// Одежда участника и обувь с маской прежней роли полигона уступают слоты новому набору.
		var/datum/outfit/new_kit = nukeop_outfit
		var/list/swapped = list(initial(participant_kit.uniform), initial(participant_kit.shoes))
		for(var/datum/outfit/kit as anything in list(/datum/outfit/inteq/training, /datum/outfit/inteq/training/clownop))
			swapped |= list(initial(kit.shoes), initial(kit.mask))
		for(var/obj/item/worn as anything in list(body.w_uniform, body.shoes, body.wear_mask))
			if(worn && (worn.type in swapped) && worn.type != initial(new_kit.shoes) && worn.type != initial(new_kit.mask))
				body.temporarilyRemoveItemFromInventory(worn, TRUE)
				qdel(worn)
	return ..()

/datum/antagonist/nukeop/training/memorize_code()
	var/code = nuke_team?.memorized_code
	if(!code)
		return
	antag_memory += "<b>Код учебной бомбы</b>: [code]<br>"
	var/mob/living/carbon/human/body = owner.current
	if(!leader || !istype(body))
		return
	var/datum/antag_training_program/antag/nukeop/program = training?.program
	if(istype(program))
		var/obj/item/paper/previous_paper = program.code_paper_ref?.resolve()
		if(previous_paper)
			qdel(previous_paper)
	var/obj/item/paper/code_paper = new(body.drop_location())
	code_paper.name = "training nuclear bomb code"
	code_paper.add_raw_text("Код учебной бомбы: <b>[code]</b>")
	body.put_in_hands(code_paper)
	if(istype(program))
		program.code_paper_ref = WEAKREF(code_paper)

/datum/antagonist/nukeop/training/on_gain()
	. = ..()
	sync_uplink()
	var/datum/antag_training_program/antag/nukeop/program = training?.program
	if(istype(program))
		for(var/obj/item/pinpointer/nuke_training/pinpointer in owner.current?.GetAllContents())
			pinpointer.program_ref = WEAKREF(program)
	greet()

/datum/antagonist/nukeop/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/nukeop/training/proc/brief()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ops.ogg', 100, FALSE)
	to_chat(owner.current, briefing())

/datum/antagonist/nukeop/training/proc/role_title()
	return leader ? "лидера" : "оперативника"

/datum/antagonist/nukeop/training/proc/briefing()
	var/obj/machinery/nuclearbomb/real_bomb = /obj/machinery/nuclearbomb
	var/list/lines = list(
		span_boldnotice("Тренировка [role_title()] ядерного отряда InteQ. Команда «[nuke_team?.syndicate_name]» учебная: в отряды раунда она не входит, и оперативники раунда в неё не попадают."),
		span_notice("Учебные бомба и диск - в хранилище станционного макета. Код учебной бомбы: <b>[nuke_team?.memorized_code]</b>, он записан в заметках роли. Вставьте диск, введите код, задайте время и взведите бомбу: учебный отсчёт - [ANTAG_TRAINING_NUKE_TIMER / (1 SECONDS)] с, у настоящей бомбы - не меньше [initial(real_bomb.minimum_timer_set)] с. Учебный взрыв - только вспышка и звук для участников полигона, после него бомба и диск возвращаются в хранилище."),
		span_notice("Аплинк-рация в рюкзаке: [antag_training_nukeop_telecrystals()] ТК, магазин оперативников без подкреплений и боргов. Голопаразиты, маяк сингулярности и всё, что зовёт призраков или действует на станцию, на полигоне не продаются: кредиты за них не списываются. Учебный пинпоинтер в кармане ведёт к учебному диску."),
		span_notice("Микробомбы в теле нет: в раунде она взрывает оперативника при смерти. Устройства объявления войны тоже нет: в раунде лидер объявляет станции войну с базы, и отряд получает дополнительные ТК."),
	)
	if(leader)
		lines += span_notice("В раунде лидер выбирает имя команды, распределяет ТК, а его карта открывает шлюз шаттла. Бумага с кодом - в руках, перчатки крав-мага и карта лидера - в рюкзаке.")
	lines += role_notes()
	lines += span_notice("«Пульт полигона», раздел «Моя роль»: пополнить ТК, вернуть бомбу и диск в хранилище, сменить роль на оперативника, лидера или клоуна-оперативника.")
	return jointext(lines, "<br>")

/// Строки приветствия, которые добавляет подтип роли.
/datum/antagonist/nukeop/training/proc/role_notes()
	return list()

/// Магазин аплинк-рации - для этой роли: рация одна на смены роли, меняется только набор товаров.
/datum/antagonist/nukeop/training/proc/shop_flag()
	return UPLINK_NUKE_OPS

/datum/antagonist/nukeop/training/proc/sync_uplink()
	var/datum/component/uplink/hidden = training_uplink()
	if(!hidden || hidden.uplink_flag == shop_flag())
		return hidden
	hidden.uplink_flag = shop_flag()
	hidden.update_items()
	SStgui.update_uis(hidden)
	return hidden

/// Компонент учебной аплинк-рации; ссылку ищет заново, если рацию выдали прежней роли.
/datum/antagonist/nukeop/training/proc/training_uplink()
	var/obj/item/radio = uplink_ref?.resolve()
	if(QDELETED(radio))
		radio = locate(/obj/item/inteq/uplink/radio/nuclear/training) in owner?.current?.GetAllContents()
		uplink_ref = radio ? WEAKREF(radio) : null
	return radio?.GetComponent(/datum/component/uplink)

/datum/antagonist/nukeop/training/Destroy()
	training = null
	uplink_ref = null
	objectives.Cut()
	. = ..()
	nuke_team = null

/// Учебный клоун-оперативник: клоунский набор и магазин клоунов-оперативников в той же аплинк-рации.
/datum/antagonist/nukeop/training/clownop
	name = "Учебный клоун-оперативник InteQ"
	nukeop_outfit = /datum/outfit/inteq/training/clownop

/datum/antagonist/nukeop/training/clownop/on_gain()
	ADD_TRAIT(owner, TRAIT_CLOWN_MENTALITY, CLOWNOP_TRAIT)
	return ..()

/datum/antagonist/nukeop/training/clownop/on_removal()
	REMOVE_TRAIT(owner, TRAIT_CLOWN_MENTALITY, CLOWNOP_TRAIT)
	return ..()

/datum/antagonist/nukeop/training/clownop/role_title()
	return "клоуна-оперативника"

/datum/antagonist/nukeop/training/clownop/shop_flag()
	return UPLINK_CLOWN_OPS

/datum/antagonist/nukeop/training/clownop/role_notes()
	return list(span_notice("Клоунский набор: боевые клоунские ботинки, маска клоуна, гудок и цветок со смазкой, пистолета в наборе нет. Аплинк-рация открывает магазин клоунов-оперативников: бананиевые меч и щит, пирожковая пушка, бомбанан. Подкрепления клоунов зовут призрака, а Clown Bomb выпускает полсотни клоунов мимо лимита целей - на полигоне они не продаются. В раунде клоуны-оперативники - отдельный режим вместо ядерного отряда."))

/datum/team/nuclear/training
	show_roundend_report = FALSE

/datum/team/nuclear/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src
	name = "[syndicate_name] Training Team"

/datum/team/nuclear/training/roundend_report()
	return

/datum/team/nuclear/training/antag_check_extras()
	return

/datum/team/nuclear/training/is_gamemode_hero()
	return FALSE

/datum/team/nuclear/training/Destroy(force, ...)
	QDEL_LIST(objectives)
	members.Cut()
	return ..()

/datum/outfit/inteq/training
	name = "InteQ Operative - Training"
	l_pocket = /obj/item/pinpointer/nuke_training
	uplink_type = /obj/item/inteq/uplink/radio/nuclear/training

/datum/outfit/inteq/training/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	var/obj/item/radio/headset = H.ears
	if(istype(headset))
		headset.set_frequency(FREQ_INTEQ)
		headset.freqlock = TRUE
		if(command_radio)
			headset.command = TRUE
	if(visualsOnly)
		return
	if(tc && !(locate(uplink_type) in H.GetAllContents()))
		H.equip_to_slot_or_del(new uplink_type(H, null, tc), ITEM_SLOT_BACKPACK)
	if(!LAZYLEN(H.implants) || !(locate(/obj/item/implant/weapons_auth) in H.implants))
		var/obj/item/implant/weapons_auth/weapons_auth = new
		weapons_auth.implant(H)
	H.faction |= ROLE_INTEQ
	H.update_icons()

/datum/outfit/inteq/training/leader
	name = "InteQ Leader - Training"
	command_radio = TRUE
	backpack_contents = list(/obj/item/storage/box/survival/command = 1, /obj/item/kitchen/knife/combat/survival = 1, /obj/item/clothing/gloves/krav_maga/combatglovesplus = 1, /obj/item/card/id/inteq/nuke_leader = 1)

/datum/outfit/inteq/training/clownop
	name = "InteQ Clown Operative - Training"
	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	mask = /obj/item/clothing/mask/gas/clown_hat
	belt = null
	r_pocket = /obj/item/bikehorn
	backpack_contents = list(/obj/item/storage/box/survival/command = 1, /obj/item/kitchen/knife/combat/survival = 1, /obj/item/reagent_containers/spray/waterflower/lube = 1)

/obj/item/inteq/uplink/radio/nuclear/training
	item_state = "walkietalkie"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	uplink_component = /datum/component/uplink/antag_training/nuclear

/datum/component/uplink/antag_training/nuclear
	name = "InteQ Uplink"
	allow_restricted = FALSE

/datum/component/uplink/antag_training/nuclear/blocked_reason(datum/uplink_item/item)
	if(istype(item, /datum/uplink_item/explosives/clown_bomb_clownops))
		return "бомба выпускает полсотни клоунов мимо лимита целей полигона"
	return ..()

/obj/item/pinpointer/nuke_training
	name = "training disk pinpointer"
	desc = "Учебный пинпоинтер оперативника: ведёт к учебному диску своего полигона. В раунде такой ищет настоящий диск, а после взвода бомбы переключается на шаттл отряда."
	icon_state = "pinpointer_syndicate"
	item_state = "pinpointer_black"
	var/datum/weakref/program_ref

/obj/item/pinpointer/nuke_training/scan_for_target()
	var/datum/antag_training_program/antag/nukeop/program = program_ref?.resolve()
	var/obj/item/disk/nuclear/training/disk = program?.training_disk()
	if(disk == target)
		return
	if(disk)
		set_target(disk)
	else
		unset_target()

/obj/item/pinpointer/nuke_training/Destroy()
	program_ref = null
	return ..()

/obj/item/disk/nuclear/training
	name = "training nuclear authentication disk"
	desc = "Учебный диск ядерной аутентификации: подходит только к учебной бомбе полигона. Настоящий диск на станции охраняет капитан, и он не даёт себя увезти."
	persistence_replacement = null
	fake = TRUE
	stationloving = FALSE

/obj/item/disk/nuclear/training/examine(mob/user)
	. = ..()
	for(var/line in .)
		if(findtext(line, "It's a fake!"))
			. -= line
	. += span_notice("Учебный диск: подходит только к учебной бомбе полигона.")

/obj/item/disk/nuclear/training/examine_more(mob/user)
	. = ..()
	for(var/line in .)
		if(findtext(line, "serial number"))
			. -= line
	. += span_notice("Серийные номера учебные: диск взводит только учебную бомбу полигона.")

/obj/machinery/nuclearbomb/training
	name = "training nuclear fission explosive"
	desc = "Учебная ядерная бомба InteQ: тот же пульт, диск и код, но вместо взрыва - вспышка для участников полигона."
	timer_set = ANTAG_TRAINING_NUKE_TIMER / (1 SECONDS)
	minimum_timer_set = ANTAG_TRAINING_NUKE_TIMER / (1 SECONDS)
	maximum_timer_set = ANTAG_TRAINING_NUKE_TIMER / (1 SECONDS)
	proper_bomb = FALSE
	var/datum/weakref/program_ref

/obj/machinery/nuclearbomb/training/Initialize(mapload)
	. = ..()
	GLOB.nuke_list -= src
	GLOB.poi_list -= src
	QDEL_NULL(core)

/obj/machinery/nuclearbomb/training/Destroy()
	program_ref = null
	return ..()

/obj/machinery/nuclearbomb/training/examine(mob/user)
	. = ..()
	var/obj/machinery/nuclearbomb/real_bomb = /obj/machinery/nuclearbomb
	. += span_notice("Учебный отсчёт - [timer_set] с, у настоящей бомбы - не меньше [initial(real_bomb.minimum_timer_set)] с. Учебный взрыв не трогает станцию.")

/obj/machinery/nuclearbomb/training/disk_check(obj/item/disk/nuclear/D)
	if(istype(D, /obj/item/disk/nuclear/training))
		return TRUE
	say("Ошибка аутентификации: учебная бомба принимает только учебный диск.")
	return FALSE

/obj/machinery/nuclearbomb/training/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/screwdriver/nuke))
		to_chat(user, span_warning("Учебная бомба не разбирается: ядра в ней нет."))
		return
	return ..()

/obj/machinery/nuclearbomb/training/Exited(atom/movable/AM, atom/newloc)
	. = ..()
	if(AM == auth)
		auth = null
		update_ui_mode()

/obj/machinery/nuclearbomb/training/set_safety()
	safety = !safety
	if(safety)
		timing = FALSE
		detonation_timer = null
		countdown.stop()
	update_icon()

/obj/machinery/nuclearbomb/training/set_active()
	if(safety)
		to_chat(usr, span_danger("Предохранитель ещё включён."))
		return
	timing = !timing
	if(timing)
		detonation_timer = world.time + timer_set * (1 SECONDS)
		countdown.start()
		log_game("[key_name(usr)] взводит учебную бомбу на полигоне в [AREACOORD(src)].")
	else
		detonation_timer = null
		countdown.stop()
	update_icon()

/obj/machinery/nuclearbomb/training/explode()
	if(safety)
		timing = FALSE
		return
	exploding = TRUE
	update_icon()
	var/turf/blast = get_turf(src)
	log_game("Учебная бомба взорвана на полигоне в [AREACOORD(blast)].")
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	for(var/datum/antag_training_session/member as anything in arena?.members)
		var/mob/body = member.current_body
		if(QDELETED(body))
			continue
		if(isliving(body))
			var/mob/living/witness = body
			witness.flash_act(1, TRUE, visual = TRUE, override_protection = TRUE)
		body.playsound_local(get_turf(body), 'sound/effects/explosion_distant.ogg', 70, FALSE)
		shake_camera(body, 1 SECONDS, 2)
		to_chat(body, span_userdanger("Учебная бомба взорвана. В раунде этот взрыв уничтожил бы станцию и закончил смену; учебные бомба и диск возвращаются в хранилище."))
	var/datum/antag_training_program/antag/nukeop/program = program_ref?.resolve()
	if(program)
		program.nuke_detonated(src)
	else
		reset_training()

/obj/machinery/nuclearbomb/training/actually_explode()
	return

/obj/machinery/nuclearbomb/training/really_actually_explode(off_station)
	return

/obj/machinery/nuclearbomb/training/proc/reset_training()
	auth?.forceMove(drop_location())
	timing = FALSE
	exploding = FALSE
	exploded = FALSE
	safety = TRUE
	yes_code = FALSE
	detonation_timer = null
	numeric_input = ""
	anchored = FALSE
	countdown.stop()
	update_ui_mode()
	update_icon()
	SStgui.update_uis(src)
