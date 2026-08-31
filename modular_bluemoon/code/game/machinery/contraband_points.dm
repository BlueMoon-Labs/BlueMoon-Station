// ============================================
// КОНСТАНТЫ НАСТРОЙКИ ПЛАТФОРМЫ
// ============================================
#define CONTRABAND_PAD_WARMUP_TIME (3 SECONDS)
#define CONTRABAND_PAD_BEAM_DURATION (2 SECONDS)
#define CONTRABAND_PAD_LINK_RANGE 4
#define CONTRABAND_PAD_EFFICIENCY_BONUS 0.25

// ============================================
// ПЛАТФОРМА СДАЧИ КОНТРАБАНДЫ
// ============================================
/obj/machinery/vanguard/contraband
	name = "contraband exchange pad"
	desc = "A machine designed to send contraband to CentCom for processing. Can be upgraded with better parts."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "lpad-idle"
	density = FALSE
	anchored = TRUE
	var/idle_state = "lpad-idle"
	var/warmup_state = "lpad-idle"
	var/sending_state = "lpad-beam"
	var/warmup_time = CONTRABAND_PAD_WARMUP_TIME
	var/cargo_hold_id
	layer = TABLE_LAYER
	circuit = /obj/item/circuitboard/machine/contrabandpad

	// Множитель эффективности (рассчитывается в RefreshParts)
	var/efficiency_multiplier = 1.0

/obj/machinery/vanguard/contraband/RefreshParts()
	var/total_rating = 0
	var/part_count = 0

	for(var/obj/item/stock_parts/part in component_parts)
		if(istype(part, /obj/item/stock_parts/scanning_module) || istype(part, /obj/item/stock_parts/manipulator))
			total_rating += part.rating
			part_count++

	// Формула: multiplier = 1.0 + ((average_rating - 1) * CONTRABAND_PAD_EFFICIENCY_BONUS)
	// T1 = 1.0x (без бонуса)
	// T2 = 1.25x
	// T3 = 1.50x
	// T4 = 1.75x
	// T5 = 2.00x
	// T6 = 2.25x
	if(part_count > 0)
		var/average_rating = total_rating / part_count
		efficiency_multiplier = 1.0 + ((average_rating - 1) * CONTRABAND_PAD_EFFICIENCY_BONUS)
	else
		efficiency_multiplier = 1.0

/obj/machinery/vanguard/contraband/proc/get_efficiency()
	var/total_rating = 0
	var/part_count = 0
	for(var/obj/item/stock_parts/part in component_parts)
		if(istype(part, /obj/item/stock_parts/scanning_module) || istype(part, /obj/item/stock_parts/manipulator))
			total_rating += part.rating
			part_count++
	if(part_count > 0)
		return ((total_rating / part_count) - 1) * CONTRABAND_PAD_EFFICIENCY_BONUS
	return 0

/obj/machinery/vanguard/contraband/proc/get_adjusted_value(atom/movable/AM, base_value)
	return round(base_value * efficiency_multiplier)

// ============================================
// ОСМОТР
// ============================================

/obj/machinery/vanguard/contraband/examine(mob/user)
	. = ..()
	. += "\nDisplay shows you current efficiency of the exchange pad: [span_green("[get_efficiency() * 100]% bonus")]"

// ============================================
// СБОРКА / РАЗБОРКА (стандартные процедуры)
// ============================================

/obj/machinery/vanguard/contraband/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "lpad-idle-off", "lpad-idle", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

// ============================================
// АНИМАЦИЯ
// ============================================

/obj/machinery/vanguard/contraband/proc/play_beam()
	icon_state = sending_state
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/machinery/vanguard/contraband, reset_icon)), CONTRABAND_PAD_BEAM_DURATION)

/obj/machinery/vanguard/contraband/proc/reset_icon()
	icon_state = idle_state


// ============================================
// КОНСОЛЬ УПРАВЛЕНИЯ ПЛАТФОРМОЙ
// ============================================
/obj/machinery/computer/vanguard_control/contraband
	name = "contraband exchange terminal"
	desc = "A console for exchanging contraband for bounty points. Points are credited to the ID card of the user."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	icon_screen = "request"
	icon_keyboard = "id_key"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/computer/contrabandpad

	var/obj/machinery/vanguard/contraband/pad
	var/sending = FALSE
	var/status_report = "Ready for delivery."
	var/mob/living/last_user

	// Таблица стоимости контрабанды в очках
	var/list/contraband_values = list(
		//Pistols
		/obj/item/gun/ballistic/automatic/pistol = 500,
		/obj/item/gun/ballistic/automatic/pistol/modular = 750,
		/obj/item/gun/ballistic/automatic/pistol/m1911 = 0,
		/obj/item/gun/ballistic/automatic/pistol/m1911/kitchengun = 600,
		/obj/item/gun/ballistic/automatic/pistol/deagle = 1500,
		/obj/item/gun/ballistic/automatic/pistol/APS = 600,
		/obj/item/gun/ballistic/automatic/pistol/antitank = 2500,
		/obj/item/gun/ballistic/automatic/pistol/m9mmpistol = 0,
		/obj/item/gun/ballistic/automatic/pistol/enforcergold = 0,
		/obj/item/gun/ballistic/automatic/pistol/enforcerred = 0,
		/obj/item/gun/ballistic/automatic/pistol/enforcer = 0,
		/obj/item/gun/ballistic/automatic/pistol/m22pistol = 0,
		/obj/item/gun/ballistic/automatic/pistol/deagle2 = 1500,
		/obj/item/gun/syringe/syndicate = 1500,
		/obj/item/gun/ballistic/automatic/pistol/hl9mm = 500,
		//revolvers
		/obj/item/gun/ballistic/revolver = 500,
		/obj/item/gun/ballistic/revolver/detective = 0,
		/obj/item/gun/ballistic/revolver/requiem = 10000,
		/obj/item/gun/ballistic/revolver/mateba = 1000,
		/obj/item/gun/ballistic/revolver/nagant = 750,
		/obj/item/gun/ballistic/revolver/russian = 0,
		/obj/item/gun/ballistic/revolver/doublebarrel = 0,
		/obj/item/gun/ballistic/revolver/mws = 0,
		/obj/item/gun/ballistic/revolver/grenadelauncher = 2000,
		/obj/item/gun/ballistic/automatic/gyropistol = 50000,
		/obj/item/gun/ballistic/automatic/speargun = 10000,
		/obj/item/gun/ballistic/rocketlauncher = 25000,
		/obj/item/gun/ballistic/revolver/r22lr = 0,
		/obj/item/gun/ballistic/revolver/r45l = 0,
		/obj/item/gun/ballistic/revolver/inteq = 750, //наценка за контробанду врага!
		//Automatic rifles & some misc weapon
		/obj/item/gun/ballistic/automatic/acr5m30 = 1500,
		/obj/item/gun/ballistic/automatic/m16a4 = 2500,
		/obj/item/gun/ballistic/automatic/ak47 = 3500,
		/obj/item/gun/ballistic/automatic/ak47/homemade = 3000,
		/obj/item/gun/ballistic/automatic/m1garand = 1000,
		/obj/item/gun/ballistic/automatic/fal = 2500,
		/obj/item/gun/ballistic/automatic/m46a1 = 4000,
		/obj/item/gun/ballistic/automatic/autoaegis = 3000,
		/obj/item/gun/ballistic/automatic/caelus = 5000,
		/obj/item/gun/ballistic/automatic/kaijukill = 10000,
		/obj/item/gun/ballistic/automatic/m9smg = 1000,
		/obj/item/gun/ballistic/automatic/ak12 = 2000,
		/obj/item/gun/ballistic/automatic/c20r = 2500,
		/obj/item/gun/ballistic/automatic/mini_uzi = 750,
		/obj/item/gun/ballistic/automatic/m90 = 3000,
		/obj/item/gun/ballistic/automatic/tommygun = 2000,
		/obj/item/gun/ballistic/automatic/ar = 5000,
		/obj/item/gun/ballistic/automatic/l6_saw = 10000,
		/obj/item/gun/ballistic/automatic/shotgun/bulldog = 2500,
		/obj/item/gun/ballistic/automatic/sniper_rifle = 5000,
		/obj/item/gun/ballistic/automatic/surplus = 500,
		/obj/item/gun/ballistic/automatic/laser = 1500,
		/obj/item/gun/ballistic/automatic/laser/lasgun = 0,
		/obj/item/gun/energy/laser/scatter = 1500,
		/obj/item/gun/energy/laser/sniper = 1000,
		/obj/item/gun/energy/laser/canceller = 3500, //bonus point for InteQ tech!
		/obj/item/gun/energy/pulse/pistol/inteq = 5000,
		/obj/item/gun/ballistic/automatic/c20r/toy = 0,
		/obj/item/gun/ballistic/automatic/proto = 3000,
		/obj/item/gun/ballistic/automatic/shotgun/aa12 = 2500,
		/obj/item/gun/ballistic/automatic/l6_saw/toy = 0,
		/obj/item/gun/ballistic/automatic/sniper_rifle/toy = 0,
		/obj/item/gun/ballistic/automatic/mp5 = 2000,
		/obj/item/gun/ballistic/automatic/mp7 = 2000,
		/obj/item/gun/ballistic/automatic/scar = 4000,
		/obj/item/gun/ballistic/automatic/p90 = 1500,
		/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1 = 3500,
		// Mele weapons
		/obj/item/melee/rapier/karakurt = 1500,
		/obj/item/melee/baseball_bat/ablative/inteq = 2000,
		/obj/item/katana = 1500,
		/obj/item/melee/baseball_bat/ablative/syndi = 1000,
		/obj/item/dualsaber = 5000,
		/obj/item/dualsaber/toy = 0,
		/obj/item/dualsaber/hypereutactic = 0,
		/obj/item/melee/transforming/energy/axe = 50000, //this is shit-spawn
		/obj/item/melee/transforming/energy/sword = 2000,
		/obj/item/melee/transforming/energy/sword/pirate = 1500,
		/obj/item/pickaxe/drill/jackhammer/angle_grinder = 5000,
		/obj/item/melee/transforming/plasmasword = 3500,
		/obj/item/plasmascythe = 7500,
		/obj/item/inteq_sledgehammer = 5000,
		/obj/item/kitchen/knife/backstabber = 3000,
		/obj/item/crowbar/freeman = 5000,
		/obj/item/crowbar/freeman/ultimate = 7500,
		/obj/item/wrench/shepard = 5000,
		//Suits & unders
		/obj/item/clothing/suit/space/hardsuit/syndi = 2500,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite = 4000,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter = 5000,
		/obj/item/clothing/suit/space/hardsuit/wizard = 3000,
		/obj/item/clothing/suit/space/hardsuit/soviet = 3000,
		/obj/item/clothing/suit/space/hardsuit/shielded = 5000,
		/obj/item/clothing/suit/space/hardsuit/lavaknight = 2000,
		/obj/item/clothing/suit/space/hardsuit/shielded/syndi = 7500,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 7500,
		/obj/item/clothing/suit/space/hardsuit/syndi/inteq = 4500,
		/obj/item/clothing/suit/space/hardsuit/shielded/syndi/inteq = 12500,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 750,
		/obj/item/clothing/suit/space/syndicate/inteq = 750,
		/obj/item/clothing/head/helmet/space/syndicate = 500,
		/obj/item/clothing/suit/space/syndicate = 500,
		/obj/item/clothing/suit/armor/inteq = 300,
		/obj/item/clothing/suit/armor/inteq/honorable_vanguard = 500,
		/obj/item/clothing/suit/hooded/wintercoat/syndicate/inteq = 300,
		/obj/item/clothing/under/inteq = 150,
		/obj/item/clothing/under/syndicate = 100,
		/obj/item/clothing/mask/gas/inteq = 200,
		/obj/item/clothing/head/helmet/swat/inteq = 300,
		/obj/item/clothing/shoes/chameleon/noslip = 1000,
		/obj/item/encryptionkey/inteq = 1000,
		/obj/item/clothing/glasses/thermal/syndi = 1500,
		/obj/item/headsetupgrader = 500,
		/obj/item/clothing/suit/space/hardsuit/contractor = 10000,
		/obj/item/armorkit/helmet/inteq = 750,
		/obj/item/armorkit/inteq = 750,
		/obj/item/clothing/suit/armor/hank = 2000,
		/obj/item/clothing/head/helmet/hank = 2000,
		/obj/item/storage/box/inteq_kit/conversion_kit = 250,
		/obj/item/storage/belt/military/inteq = 500,
		/obj/item/clothing/head/helmet/infiltrator/inteq = 750,
		//Other stuff
		/obj/item/storage/toolbox/syndicate = 100,
		/obj/item/storage/toolbox/inteq = 200,
		/obj/item/storage/toolbox/inteq/cooler = 300,
		/obj/item/storage/backpack/satchel/flat = 300,
		/obj/item/toy/cards/deck/syndicate = 200,
		/obj/item/storage/box/syndie_kit/space = 150,
		/obj/item/storage/box/syndie_kit = 100,
		/obj/item/storage/box/inteq_kit = 200,
		/obj/item/card/id/syndicate = 750,
		/obj/item/card/id/inteq = 1250,
		/obj/item/mod/control/pre_equipped/inteq = 5000,
		/obj/item/mod/control/pre_equipped/syndicate_empty = 2500,
		/obj/item/mod/control/pre_equipped/syndicate_empty/elite = 5000,
		/obj/item/mod/control/pre_equipped/elite = 5000,
		/obj/item/mod/control/pre_equipped/nuclear = 2500,
		/obj/item/mod/control/pre_equipped/traitor = 2500,
		/obj/item/grenade/plastic/c4 = 300,
		/obj/item/grenade/plastic/x4 = 600,
		/obj/item/cartridge/virus/detomatix = 200,
		/obj/item/camera_bug = 1000,
		/obj/item/sbeacondrop/powersink = 5000,
		/obj/item/card/emag = 3000,
		/obj/item/grenade/syndieminibomb = 1500,
		/obj/item/compressionkit = 2000,
		/obj/item/chameleon = 1500,
		/obj/item/doorCharge = 500,
		/obj/item/storage/box/inteq_kit/revolver = 250,
		/obj/item/guardiancreator = 3000,
		//broken stuff
		/obj/item/broken/inteq_sledgehammer = 2500,
		/obj/item/broken/dualsaber = 2500,
		/obj/item/broken/energy_sword = 1000,
		/obj/item/broken/inteq_elite = 3750,
		/obj/item/broken/makarov = 250,
		/obj/item/broken/c20r = 1250,
		/obj/item/broken/bulldog = 1250,
		/obj/item/broken/ushm = 2500,
		/obj/item/broken/sniper_rifle = 2500,
		/obj/item/broken = 10000000,
		//Mechs
		/obj/vehicle/sealed/mecha/combat/five_stars = 50000,
		/obj/vehicle/sealed/mecha/combat/durand/zeus = 25000,
		/obj/vehicle/sealed/mecha/combat/gygax/dark = 12500,
		/obj/vehicle/sealed/mecha/combat/gygax/dark/loaded/hermes = 20000,
		/obj/vehicle/sealed/mecha/combat/marauder/mauler = 25000,
		/obj/vehicle/sealed/mecha/combat/marauder/mauler/loaded/ares = 50000,
		/obj/vehicle/sealed/mecha/combat/durand/tu802 = 15000
	)

/obj/machinery/computer/vanguard_control/contraband/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/vanguard_control/contraband/LateInitialize()
	. = ..()
	pad = locate() in range(CONTRABAND_PAD_LINK_RANGE, src)

/obj/machinery/computer/vanguard_control/contraband/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if(.)
		return TRUE

	if(!istype(I))
		return FALSE

	if(!istype(I.buffer, /obj/machinery/vanguard/contraband))
		to_chat(user, "<span class='warning'>Your multitool doesn't have a valid contraband pad in its buffer!</span>")
		return TRUE

	pad = I.buffer
	to_chat(user, "<span class='notice'>You link [src] with [pad] using [I].</span>")
	return TRUE

/obj/machinery/computer/vanguard_control/contraband/proc/get_contraband_value(atom/movable/AM)
	var/best_value = 0
	var/best_depth = -1
	for(var/typepath in contraband_values)
		if(istype(AM, typepath))
			// Считаем глубину наследования по количеству "/" в текстовом представлении пути
			var/depth = length(splittext("[typepath]", "/"))
			if(depth > best_depth)
				best_depth = depth
				best_value = contraband_values[typepath]
	return best_value

/obj/machinery/vanguard/contraband/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if(.)
		return TRUE

	I.buffer = src
	to_chat(user, "<span class='notice'>You add [src] to [I]'s buffer. Now use the multitool on a contraband exchange terminal to link them.</span>")
	return TRUE

/obj/machinery/computer/vanguard_control/contraband/proc/recalc()
	if(sending)
		return FALSE

	var/total_value = 0
	if(pad)
		for(var/atom/movable/AM in get_turf(pad))
			if(AM == pad)
				continue
			var/base_value = get_contraband_value(AM)
			if(base_value > 0)
				total_value += pad.get_adjusted_value(AM, base_value)

	if(total_value > 0)
		var/mult_text = ""
		if(pad && pad.efficiency_multiplier > 1.0)
			mult_text = " (with [pad.efficiency_multiplier]x efficiency bonus)"
		status_report = "Contraband detected. Value: [total_value] points[mult_text]."
		playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	else
		status_report = "No applicable contraband found."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)

/obj/machinery/computer/vanguard_control/contraband/proc/start_sending()
	if(sending)
		return
	sending = TRUE
	status_report = "Sending contraband..."

	if(pad)
		pad.icon_state = pad.warmup_state
		addtimer(CALLBACK(pad, TYPE_PROC_REF(/obj/machinery/vanguard/contraband, play_beam)), pad.warmup_time)

	addtimer(CALLBACK(src, PROC_REF(send)), pad ? pad.warmup_time : CONTRABAND_PAD_WARMUP_TIME)

/obj/machinery/computer/vanguard_control/contraband/proc/stop_sending()
	sending = FALSE
	if(pad)
		pad.icon_state = pad.idle_state

/obj/machinery/computer/vanguard_control/contraband/proc/send()
	playsound(loc, 'sound/machines/wewewew.ogg', 70, TRUE)

	if(!sending || !pad)
		stop_sending()
		return

	// Проверяем пользователя и его ID до удаления предметов
	var/obj/item/card/id/user_id
	if(last_user && !QDELETED(last_user))
		user_id = last_user.get_idcard()
	else
		status_report = "User has left!"
		last_user = null
		stop_sending()
		return

	if(!user_id)
		status_report = "No ID card found on user!"
		last_user = null
		stop_sending()
		return

	// Теперь можно безопасно удалять предметы и начислять очки
	var/total_value = 0
	var/items_sent = 0

	for(var/atom/movable/AM in get_turf(pad))
		if(AM == pad)
			continue
		var/base_value = get_contraband_value(AM)
		if(base_value > 0)
			var/adjusted_value = pad.get_adjusted_value(AM, base_value)
			total_value += adjusted_value
			items_sent++
			qdel(AM)

	if(items_sent > 0)
		user_id.contraband_points += total_value
		to_chat(last_user, "<span class='notice'>[total_value] bounty point\s credited to your ID card.</span>")
		status_report = "Contraband processed! [total_value] points distributed."
		pad.visible_message("<span class='notice'>[pad] activates and beams away the contraband!</span>")
		playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	else
		status_report = "No applicable contraband found. Aborting."

	last_user = null
	stop_sending()

/obj/machinery/computer/vanguard_control/contraband/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "computer", "computer", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

// ============================================
// TGUI
// ============================================

/obj/machinery/computer/vanguard_control/contraband/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContrabandExchange", name)
		ui.open()

/obj/machinery/computer/vanguard_control/contraband/ui_data(mob/user)
	var/list/data = list()
	data["pad"] = pad ? TRUE : FALSE
	data["sending"] = sending
	data["status_report"] = status_report

	data["efficiency_multiplier"] = 1.0
	if(pad)
		data["efficiency_multiplier"] = pad.efficiency_multiplier

	var/mob/living/L = user
	var/obj/item/card/id/user_id = L?.get_idcard()
	data["user_has_id"] = user_id ? TRUE : FALSE
	data["user_points"] = user_id ? user_id.contraband_points : 0

	var/total_value = 0
	var/list/items_on_pad = list()
	if(pad)
		for(var/atom/movable/AM in get_turf(pad))
			if(AM == pad)
				continue
			var/base_value = get_contraband_value(AM)
			if(base_value > 0)
				var/adjusted_value = pad.get_adjusted_value(AM, base_value)
				total_value += adjusted_value
				items_on_pad += list(list(
					"name" = AM.name,
					"base_value" = base_value,
					"adjusted_value" = adjusted_value
				))

	data["total_value"] = total_value
	data["items_on_pad"] = items_on_pad

	return data

/obj/machinery/computer/vanguard_control/contraband/ui_act(action, params)
	if(..())
		return
	if(!usr.canUseTopic(src, BE_CLOSE))
		return

	switch(action)
		if("recalc")
			recalc()
		if("send")
			last_user = usr
			start_sending()
		if("stop")
			stop_sending()
			last_user = null
	return TRUE

/obj/item/card/contraband_point_card
	name = "Bounty points card"
	desc = "A small card for transferring bounty points. Swipe your ID card over it to start the process."
	icon_state = "data_1"
	var/points = 100

/obj/item/card/contraband_point_card/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		var/obj/item/card/id/id_card = I
		to_chat(user, span_info("You swipe [id_card] on [src] and start the transfer process."))
		var/choice = alert(user, "Do you want to transfer points to or from the point card's storage?", "Bounty Points Transfer", "From Point Card/Storage", "To Point Card/Storage", "Cancel")
		if(choice != "Cancel")
			var/amount = input(user, "How much do you want to transfer? ID Balance: [id_card.contraband_points], Transfer Card Balance: [points]", "Transfer Points") as num|null
			if(!amount || amount <= 0)
				return
			amount = round(amount, 1)
			if(choice == "To Point Card/Storage")
				if(amount && amount <= id_card.contraband_points)
					id_card.contraband_points -= amount
					points += amount
					to_chat(user, span_info("You transfer [amount] points to [src] from [id_card]."))
			else if(choice == "From Point Card/Storage")
				if(amount && amount <= points)
					id_card.contraband_points += amount
					points -= amount
					to_chat(user, span_info("You transfer [amount] points to [id_card] from [src]."))
	..()

/obj/item/card/contraband_point_card/examine(mob/user)
	. = ..()
	. += "There's [points] point\s on the card."

#undef CONTRABAND_PAD_WARMUP_TIME
#undef CONTRABAND_PAD_BEAM_DURATION
#undef CONTRABAND_PAD_LINK_RANGE
#undef CONTRABAND_PAD_EFFICIENCY_BONUS
