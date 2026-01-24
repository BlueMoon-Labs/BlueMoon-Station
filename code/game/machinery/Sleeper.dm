/obj/machinery/sleep_console
	name = "sleeper console"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "console"
	density = FALSE

/obj/machinery/sleeper
	name = "sleeper"
	desc = "Закрываемое устройство для стабилизации и лечения пациентов."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	density = FALSE
	state_open = TRUE
	circuit = /obj/item/circuitboard/machine/sleeper

	var/efficiency = 1
	var/min_health = -25
	var/list/available_chems
	var/controls_inside = FALSE
	var/list/possible_chems = list(
		list(/datum/reagent/medicine/epinephrine, /datum/reagent/medicine/morphine, /datum/reagent/medicine/salbutamol, /datum/reagent/medicine/charcoal, /datum/reagent/medicine/salglu_solution),
		list(/datum/reagent/medicine/oculine,/datum/reagent/medicine/inacusiate),
		list(/datum/reagent/medicine/mutadone, /datum/reagent/medicine/mannitol),
		list(/datum/reagent/medicine/omnizine),
		list(/datum/reagent/medicine/atropine),
		list(/datum/reagent/medicine/perfluorodecalin, /datum/reagent/medicine/neurine, /datum/reagent/medicine/sal_acid, /datum/reagent/medicine/oxandrolone)
	)
	var/list/chem_buttons	//Used when emagged to scramble which chem is used, eg: antitoxin -> morphine
	var/scrambled_chems = FALSE //Are chem buttons scrambled? used as a warning
	var/enter_message = "<span class='notice'><b>Прохладный воздух окутывает вас. Вы немеете и ваши чувства отходят глубоко внутрь.</b></span>"
	payment_department = ACCOUNT_MED
	fair_market_price = 5

/obj/machinery/sleeper/Initialize(mapload)
	. = ..()
	// if(mapload)
	// 	component_parts -= circuit
	// 	QDEL_NULL(circuit)
	occupant_typecache = GLOB.typecache_living
	update_icon()
	reset_chem_buttons()
	RefreshParts()

/obj/machinery/sleeper/RefreshParts()
	var/E
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		E += B.rating
	var/I
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		I += M.rating

	efficiency = initial(efficiency)* E
	min_health = initial(min_health) - (10*(E-1)) // CIT CHANGE - changes min health equation to be min_health - (matterbin rating * 10)
	available_chems = list()
	I = clamp(I, 1, possible_chems.len)
	for(var/i in 1 to I)
		available_chems |= possible_chems[i]
	reset_chem_buttons()

/obj/machinery/sleeper/update_icon_state()
	if(state_open)
		icon_state = "[initial(icon_state)]-open"
	else
		icon_state = initial(icon_state)

/obj/machinery/sleeper/container_resist(mob/living/user)
	visible_message("<span class='notice'>[occupant] выходит из [src]!</span>",
		"<span class='notice'>Вы выбираетесь из [src]!</span>")
	open_machine()

/obj/machinery/sleeper/Exited(atom/movable/user)
	if (!state_open && user == occupant)
		container_resist(user)

/obj/machinery/sleeper/relaymove(mob/user)
	if (!state_open)
		container_resist(user)

/obj/machinery/sleeper/open_machine()
	if(!state_open && !panel_open)
		// flick("[initial(icon_state)]-anim", src)
		..()

/obj/machinery/sleeper/close_machine(mob/user)
	if((isnull(user) || istype(user)) && state_open && !panel_open)
		// flick("[initial(icon_state)]-anim", src)
		..(user)
		var/mob/living/mob_occupant = occupant
		if(mob_occupant && mob_occupant.stat != DEAD)
			to_chat(occupant, "[enter_message]")

/obj/machinery/sleeper/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(is_operational() && occupant)
		var/datum/reagent/R = pick(reagents.reagent_list) //cit specific
		inject_chem(R.type, occupant)
		open_machine()
	//Is this too much? Cit specific
	if(severity >= 80)
		var/chem = pick(available_chems)
		available_chems -= chem
		available_chems += get_random_reagent_id()
		reset_chem_buttons()

/obj/machinery/sleeper/MouseDrop_T(mob/target, mob/user)
	if(user.stat || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target) || !user.IsAdvancedToolUser())
		return
	if(isliving(user))
		var/mob/living/L = user
		if(!(L.mobility_flags & MOBILITY_STAND))
			return
	close_machine(target)

/obj/machinery/sleeper/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(..())
		return
	if(occupant)
		to_chat(user, "<span class='warning'>[src] сейчас занят изнутри!</span>")
		return
	if(state_open)
		to_chat(user, "<span class='warning'>[src] должен быть закрыт для [panel_open ? "закрытия" : "открытия"] люка техобслуживания!</span>")
		return
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-o", initial(icon_state), I))
		return
	return FALSE

/obj/machinery/sleeper/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(default_change_direction_wrench(user, I))
		return TRUE

/obj/machinery/sleeper/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	if(default_pry_open(I))
		return TRUE
	if(default_deconstruction_crowbar(I))
		return TRUE

/obj/machinery/sleeper/default_pry_open(obj/item/I) //wew
	. = !(state_open || panel_open || (flags_1 & NODECONSTRUCT_1)) && I.tool_behaviour == TOOL_CROWBAR
	if(.)
		I.play_tool_sound(src, 50)
		visible_message("<span class='notice'>[usr] вскрывает [src].</span>", "<span class='notice'>Вы вскрываете [src].</span>")
		open_machine()

/obj/machinery/sleeper/ui_state(mob/user)
	if(controls_inside)
		return GLOB.default_state
	return GLOB.notcontained_state

/obj/machinery/sleeper/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Sleeper", name)
		ui.open()

/obj/machinery/sleeper/AltClick(mob/user)
	if(!user.canUseTopic(src, !issilicon(user)))
		return
	if(state_open)
		close_machine()
	else
		open_machine()

/obj/machinery/sleeper/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click для того, чтобы [state_open ? "закрыть" : "открыть"].</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>Статус-дисплей сообщает: \n\
		- Эффективность дозировок: <b>[efficiency*100]%</b>.</span>"

/obj/machinery/sleeper/process()
	..()
	check_nap_violations()

/obj/machinery/sleeper/nap_violation(mob/violator)
	open_machine()

/obj/machinery/sleeper/ui_data()
	var/list/data = list()
	data["occupied"] = occupant ? 1 : 0
	data["open"] = state_open

	data["chems"] = list()
	for(var/chem in available_chems)
		var/datum/reagent/R = GLOB.chemical_reagents_list[chem]
		var/chem_name = R.name
		if(istype(R, /datum/reagent/medicine/salglu_solution))
			chem_name = "Saline-Glucose"
		data["chems"] += list(list("name" = chem_name, "id" = R.type, "allowed" = chem_allowed(chem)))

	data["occupant"] = list()
	var/mob/living/mob_occupant = occupant
	if(mob_occupant)
		data["occupant"]["name"] = mob_occupant.name
		switch(mob_occupant.stat)
			if(CONSCIOUS)
				data["occupant"]["stat"] = "В сознании"
				data["occupant"]["statstate"] = "good"
			if(SOFT_CRIT)
				data["occupant"]["stat"] = "В сознании"
				data["occupant"]["statstate"] = "average"
			if(UNCONSCIOUS)
				data["occupant"]["stat"] = "Без сознания" // 15.09.2023. Отметка. Перевести
				data["occupant"]["statstate"] = "average"
			if(DEAD)
				data["occupant"]["stat"] = "М[mob_occupant.gender == FEMALE ? "ертва" : "ёртв"]"
				data["occupant"]["statstate"] = "bad"
		data["occupant"]["health"] = mob_occupant.health
		data["occupant"]["maxHealth"] = mob_occupant.maxHealth
		data["occupant"]["minHealth"] = HEALTH_THRESHOLD_DEAD
		data["occupant"]["bruteLoss"] = mob_occupant.getBruteLoss()
		data["occupant"]["oxyLoss"] = mob_occupant.getOxyLoss()
		data["occupant"]["toxLoss"] = mob_occupant.getToxLoss()
		data["occupant"]["fireLoss"] = mob_occupant.getFireLoss()
		data["occupant"]["cloneLoss"] = mob_occupant.getCloneLoss()
		data["occupant"]["brainLoss"] = mob_occupant.getOrganLoss(ORGAN_SLOT_BRAIN)
		data["occupant"]["is_robotic_organism"] = HAS_TRAIT(mob_occupant, TRAIT_ROBOTIC_ORGANISM)
		data["occupant"]["reagents"] = list()
		if(mob_occupant.reagents && mob_occupant.reagents.reagent_list.len)
			for(var/datum/reagent/R in mob_occupant.reagents.reagent_list)
				data["occupant"]["reagents"] += list(list("name" = R.name, "volume" = R.volume))
	return data

/obj/machinery/sleeper/ui_act(action, params)
	if(..())
		return
	var/mob/living/mob_occupant = occupant
	check_nap_violations()
	switch(action)
		if("door")
			if(state_open)
				close_machine()
			else
				open_machine()
			. = TRUE
		if("inject")
			var/chem = text2path(params["chem"])
			if(!is_operational() || !mob_occupant || isnull(chem))
				return
			if(mob_occupant.health < min_health && chem != /datum/reagent/medicine/epinephrine)
				return
			if(inject_chem(chem, usr))
				. = TRUE
				if(scrambled_chems && prob(5))
					to_chat(usr, "<span class='warning'>Обнаружено изменение маршрутов химической системы, результаты могут не соответствовать ожидаемым!</span>")

/obj/machinery/sleeper/emag_act(mob/user)
	. = ..()
	obj_flags |= EMAGGED
	scramble_chem_buttons()
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='warning'>Вы взломали протоколы интерфейса слипера!</span>")
	return TRUE

/obj/machinery/sleeper/proc/inject_chem(chem, mob/user)
	if((chem in available_chems) && chem_allowed(chem))
		occupant.reagents.add_reagent(chem_buttons[chem], 10) //emag effect kicks in here so that the "intended" chem is used for all checks, for extra FUUU
		if(user)
			playsound(src, pick('sound/items/medi/hypospray.ogg','sound/items/medi/hypospray2.ogg'), 50, TRUE, 2)
			log_combat(user, occupant, "injected [chem] into", addition = "via [src]")
		return TRUE

/obj/machinery/sleeper/proc/chem_allowed(chem)
	var/mob/living/mob_occupant = occupant
	if(!mob_occupant || !mob_occupant.reagents)
		return
	var/amount = mob_occupant.reagents.get_reagent_amount(chem) + 10 <= 20 * efficiency
	var/occ_health = mob_occupant.health > min_health || chem == /datum/reagent/medicine/epinephrine
	return amount && occ_health

/obj/machinery/sleeper/proc/reset_chem_buttons()
	scrambled_chems = FALSE
	LAZYINITLIST(chem_buttons)
	for(var/chem in available_chems)
		chem_buttons[chem] = chem

/obj/machinery/sleeper/proc/scramble_chem_buttons()
	scrambled_chems = TRUE
	var/list/av_chem = available_chems.Copy()
	for(var/chem in av_chem)
		chem_buttons[chem] = pick_n_take(av_chem) //no dupes, allow for random buttons to still be correct


/obj/machinery/sleeper/syndie
	icon_state = "sleeper_s"
	controls_inside = TRUE

/obj/machinery/sleeper/syndie/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/sleeper/syndie(null)
	component_parts += new /obj/item/stock_parts/matter_bin/super(null)
	component_parts += new /obj/item/stock_parts/manipulator/pico(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	component_parts += new /obj/item/stack/cable_coil(null)
	RefreshParts()

/obj/machinery/sleeper/syndie/fullupgrade/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/sleeper/syndie(null)
	component_parts += new /obj/item/stock_parts/matter_bin/bluespace(null)
	component_parts += new /obj/item/stock_parts/manipulator/femto(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	component_parts += new /obj/item/stack/cable_coil(null)
	RefreshParts()

/obj/machinery/sleeper/old
	icon_state = "oldpod"

/obj/machinery/sleeper/party
	name = "party pod"
	desc = "Модель 'слипер'-устройства, однажды лечившее, пока длительное обследование не обнаружило факт инъекций летальных доз ацетатов. \
	Похоже, что это один из тех старых 'слиперов', переделанных в 'парти-под'. Использовать его может быть не лучшей идеей."
	icon_state = "partypod"
	idle_power_usage = 3000
	circuit = /obj/item/circuitboard/machine/sleeper/party
	var/leddit = FALSE //Get it like reddit and lead alright fine

	controls_inside = TRUE
	possible_chems = list(
		list(/datum/reagent/consumable/ethanol/beer, /datum/reagent/consumable/laughter),
		list(/datum/reagent/spraytan,/datum/reagent/barbers_aid),
		list(/datum/reagent/colorful_reagent,/datum/reagent/hair_dye),
		list(/datum/reagent/drug/space_drugs,/datum/reagent/baldium)
	)//Exclusively uses non-lethal, "fun" chems. At an obvious downside.
	var/spray_chems = list(
		/datum/reagent/spraytan, /datum/reagent/hair_dye, /datum/reagent/baldium, /datum/reagent/barbers_aid
	)//Chemicals that need to have a touch or vapor reaction to be applied, not the standard chamber reaction.
	enter_message = "<span class='notice'><b>Вас обволакивает музыка-фанк. Вы отрубаетесь, ощущая как волны крэнк-вайба растекаются внутри вас.</b></span>"

/obj/machinery/sleeper/party/inject_chem(chem, mob/user)
	if(leddit)
		occupant.reagents.add_reagent(/datum/reagent/toxin/leadacetate, 4) //You're injecting chemicals into yourself from a recalled, decrepit medical machine. What did you expect?
	else if (prob(20))
		occupant.reagents.add_reagent(/datum/reagent/toxin/leadacetate, rand(1,3))
	if(chem in spray_chems)
		var/datum/reagents/holder = new()
		holder.add_reagent(chem_buttons[chem], 10) //I hope this is the correct way to do this.
		holder.reaction(occupant, VAPOR, 0)
		holder.trans_to(occupant, 10)
		playsound(src.loc, 'sound/effects/spray2.ogg', 50, TRUE, -6)
		if(user)
			log_combat(user, occupant, "sprayed [chem] into", addition = "via [src]")
		return TRUE
	..()

/obj/machinery/sleeper/party/emag_act(mob/user)
	..()
	leddit = TRUE

/obj/machinery/sleeper/clockwork
	name = "soothing sleeper"
	desc = "Большое устройство-криокамера из латуни. Поверхность приятно холодная на ощупь."
	icon_state = "sleeper_clockwork"
	enter_message = "<span class='bold inathneq_small'>Вы слышите тихое гудение и щёлканье машины и погружаетесь в чувство покоя.</span>"
	possible_chems = list(
		list(/datum/reagent/medicine/epinephrine, /datum/reagent/medicine/salbutamol, /datum/reagent/medicine/bicaridine, /datum/reagent/medicine/kelotane, /datum/reagent/medicine/oculine, /datum/reagent/medicine/inacusiate, /datum/reagent/medicine/mannitol)
	) //everything is available at start
	fair_market_price = 0 //it's free

/obj/machinery/sleeper/clockwork/process()
	..()
	if(occupant && isliving(occupant))
		var/mob/living/L = occupant
		if(GLOB.clockwork_vitality) //If there's Vitality, the sleeper has passive healing
			GLOB.clockwork_vitality = max(0, GLOB.clockwork_vitality - 1)
			L.adjustBruteLoss(-1)
			L.adjustFireLoss(-1)
			L.adjustOxyLoss(-5)
