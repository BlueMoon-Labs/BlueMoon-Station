#define PERCENT_FASTER_FROM_MANIPULATOR 25
#define BIN_ADD_SLOTS_COUNT 1

/obj/machinery/medipen_refiller
	name = "Medipen Refiller"
	desc = "A machine that refills used medipens with chemicals."
	icon = 'icons/obj/machines/medipen_refiller.dmi'
	icon_state = "medipen_refiller"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/medipen_refiller
	idle_power_usage = 100
	active_power_usage = 800
	use_power = IDLE_POWER_USE
	// Exact types: allowing a base medipen must not also allow its restricted subtypes.
	var/list/allowed = list(
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/reagent_containers/hypospray/medipen/ekit,
		/obj/item/reagent_containers/hypospray/medipen/firelocker,
		/obj/item/reagent_containers/hypospray/medipen/stimpack,
		/obj/item/reagent_containers/hypospray/medipen/blood_loss,
		/obj/item/reagent_containers/hypospray/medipen/morphine,
		/obj/item/reagent_containers/hypospray/medipen/penacid,
		/obj/item/reagent_containers/hypospray/medipen/salacid,
		/obj/item/reagent_containers/hypospray/medipen/oxandrolone,
		/obj/item/reagent_containers/hypospray/medipen/salbutamol,
		/obj/item/reagent_containers/hypospray/medipen/ferrocortex,
	)
	var/max_medipens = 2
	var/refill_time = 120 SECONDS
	var/speed_up_percent = 0
	// Slots keep their indices when a medipen is removed.
	var/list/medipens = list(null)
	// Medipen => timer ID, start time and duration. Reagents only change on completion.
	var/list/refill_jobs = list()
	var/datum/looping_sound/machine_work/soundloop // Working sound

/obj/machinery/medipen_refiller/Initialize(mapload)
	. = ..()
	update_icon()
	soundloop = new(src, !!length(refill_jobs))

/obj/machinery/medipen_refiller/Destroy()
	eject_all()
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/medipen_refiller/RefreshParts()
	var/bin_rating = 0
	var/manipulator_rating = 0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		bin_rating += bin.rating
	for(var/obj/item/stock_parts/manipulator/manipulator in component_parts)
		manipulator_rating += manipulator.rating
	max_medipens = initial(max_medipens) + BIN_ADD_SLOTS_COUNT * max((round_down(bin_rating) - 1), 0)
	speed_up_percent = clamp(ceil((manipulator_rating - 1) * PERCENT_FASTER_FROM_MANIPULATOR), 0, 95)
	refill_time = max(round(initial(refill_time) * (1 - speed_up_percent / 100), 1), 1 SECONDS)
	for(var/slot in max_medipens + 1 to length(medipens))
		eject_medipen(slot)
	medipens.len = max_medipens

/obj/machinery/medipen_refiller/examine(mob/user)
	. = ..()
	. += span_notice("Количество слотов: [max_medipens]. Время заправки: [DisplayTimeText(refill_time)].")
	if(speed_up_percent)
		. += span_notice("- Машина работает на [span_nicegreen("[speed_up_percent]%")] быстрее.")
	. += span_info("Alt-click для извлечения медипена.")

/obj/machinery/medipen_refiller/is_operational()
	return ..() && anchored && !panel_open

/obj/machinery/medipen_refiller/on_stat_update(old_value)
	. = ..()
	if(!is_operational())
		cancel_all_refills()

/obj/machinery/medipen_refiller/process()
	if(!is_operational())
		cancel_all_refills()
	if(!length(refill_jobs))
		return machine_sleep()

/obj/machinery/medipen_refiller/update_icon_state()
	icon_state = panel_open ? "medipen_refiller_open" : "medipen_refiller"

/obj/machinery/medipen_refiller/update_overlays()
	. = ..()
	if(length(refill_jobs))
		. += "overlay_active"

/obj/machinery/medipen_refiller/proc/update_refilling()
	var/refil_count = length(refill_jobs)
	active_power_usage = initial(active_power_usage)
	if(refil_count)
		soundloop.start()
		active_power_usage *= refil_count
		use_power = ACTIVE_POWER_USE
	else
		soundloop.stop()
		use_power = IDLE_POWER_USE
	machine_wake()
	update_icon()

/obj/machinery/medipen_refiller/proc/cancel_refill(obj/item/reagent_containers/hypospray/medipen/pen)
	var/list/job = refill_jobs[pen]
	if(!job)
		return
	if(job["timer"])
		deltimer(job["timer"])
	refill_jobs -= pen
	update_refilling()

/obj/machinery/medipen_refiller/proc/cancel_all_refills()
	for(var/obj/item/reagent_containers/hypospray/medipen/pen as anything in refill_jobs.Copy())
		cancel_refill(pen)

/obj/machinery/medipen_refiller/proc/start_refill(slot)
	var/obj/item/reagent_containers/hypospray/medipen/pen = medipens[slot]
	if(!is_operational() || QDELETED(pen) || pen.loc != src || !(pen.type in allowed))
		return FALSE
	if(refill_jobs[pen] || !pen.reagents || pen.reagents.total_volume || !length(pen.list_reagents))
		return FALSE
	var/list/job = list("start" = world.time, "duration" = refill_time)
	refill_jobs[pen] = job
	job["timer"] = addtimer(CALLBACK(src, PROC_REF(finish_refill), pen, job), refill_time, TIMER_STOPPABLE)
	update_refilling()
	return TRUE

/obj/machinery/medipen_refiller/proc/finish_refill(obj/item/reagent_containers/hypospray/medipen/pen, list/job)
	// A cancelled or replaced job must never refill a removed/reinserted medipen.
	if(refill_jobs[pen] != job)
		return
	job["timer"] = null
	if(world.time < job["start"] + job["duration"] || !is_operational() || QDELETED(pen) || pen.loc != src || !(pen in medipens) || !(pen.type in allowed) || !pen.reagents || pen.reagents.total_volume)
		cancel_refill(pen)
		return
	pen.reagents.maximum_volume = initial(pen.volume)
	pen.reagent_flags = initial(pen.reagent_flags)
	pen.reagents.add_reagent_list(pen.list_reagents)
	pen.update_icon()
	cancel_refill(pen)
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

/obj/machinery/medipen_refiller/proc/insert_medipen(obj/item/reagent_containers/hypospray/medipen/pen, mob/user, slot)
	if(!istype(pen) || !(pen.type in allowed))
		to_chat(user, span_warning("Этот тип медипена не поддерживается."))
		return FALSE
	if(panel_open || !anchored)
		to_chat(user, span_warning("Закройте панель и закрепите машину."))
		return FALSE
	if(!slot)
		for(var/index in 1 to max_medipens)
			if(!medipens[index])
				slot = index
				break
	if(!slot || medipens[slot])
		to_chat(user, span_warning("Нет свободного слота."))
		return FALSE
	if(!user.transferItemToLoc(pen, src))
		return FALSE
	medipens[slot] = pen
	playsound(src, 'sound/machines/eject.ogg', 50, TRUE)
	start_refill(slot)
	return TRUE

/obj/machinery/medipen_refiller/proc/eject_medipen(slot, mob/user)
	var/obj/item/reagent_containers/hypospray/medipen/pen = medipens[slot]
	if(!pen)
		return
	cancel_refill(pen)
	medipens[slot] = null
	pen.forceMove(drop_location())
	pen.randomize_pixel_position()
	if(user)
		playsound(src, 'sound/machines/eject.ogg', 50, TRUE)
		if(Adjacent(user) && user.can_hold_items())
			user.put_in_hands(pen)

/obj/machinery/medipen_refiller/proc/eject_all()
	cancel_all_refills()
	for(var/slot in 1 to length(medipens))
		eject_medipen(slot)

/obj/machinery/medipen_refiller/Exited(atom/movable/gone, atom/newloc)
	. = ..()
	var/slot = medipens.Find(gone)
	if(slot)
		cancel_refill(gone)
		medipens[slot] = null

/obj/machinery/medipen_refiller/handle_atom_del(atom/deleted)
	. = ..()
	var/slot = medipens.Find(deleted)
	if(slot)
		cancel_refill(deleted)
		medipens[slot] = null

/obj/machinery/medipen_refiller/attackby(obj/item/item, mob/user, params)
	if(user.a_intent != INTENT_HARM && istype(item, /obj/item/reagent_containers/hypospray/medipen))
		insert_medipen(item, user)
		return TRUE
	return ..()

/obj/machinery/medipen_refiller/screwdriver_act(mob/living/user, obj/item/item)
	. = ..()
	if(!anchored)
		balloon_alert(user, "Прикрути!")
		return TRUE
	if(default_deconstruction_screwdriver(user, "medipen_refiller_open", "medipen_refiller", item))
		eject_all()
		update_icon()
	return TRUE

/obj/machinery/medipen_refiller/wrench_act(mob/living/user, obj/item/item)
	. = ..()
	var/result = default_unfasten_wrench(user, item, 2 SECONDS)
	if(result == SUCCESSFUL_UNFASTEN)
		eject_all()
	return result != CANT_UNFASTEN

/obj/machinery/medipen_refiller/can_be_unfasten_wrench(mob/user, silent = FALSE)
	. = ..()
	if(. == FAILED_UNFASTEN)
		return .
	if(!panel_open)
		if(!silent)
			balloon_alert(user, "Открути панель")
		return FAILED_UNFASTEN

/obj/machinery/medipen_refiller/crowbar_act(mob/living/user, obj/item/item)
	. = ..()
	if(default_deconstruction_crowbar(item))
		return TRUE

/obj/machinery/medipen_refiller/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, no_tk = TRUE, silent = TRUE))
		return
	// First, an attempt to take full medipens
	var/empty = TRUE
	for(var/slot in 1 to length(medipens))
		if(medipens[slot])
			empty = FALSE
			var/obj/item/reagent_containers/hypospray/medipen/pen = medipens[slot]
			if(pen.reagents.total_volume > 0)
				eject_medipen(slot, user)
				return
	if(!empty)
		for(var/slot in 1 to length(medipens))
			if(medipens[slot])
				eject_medipen(slot, user)
				return

/obj/machinery/medipen_refiller/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/medipen_refiller/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedipenRefiller", name)
		ui.open()

/obj/machinery/medipen_refiller/ui_data(mob/user)
	var/list/slots = list()
	for(var/slot in 1 to max_medipens)
		var/obj/item/reagent_containers/hypospray/medipen/pen = medipens[slot]
		var/list/job = pen ? refill_jobs[pen] : null
		slots += list(list(
			"id" = slot,
			"name" = pen ? capitalize(pen.name) : null,
			"filling" = !!job,
			"filled" = pen?.reagents?.total_volume > 0,
			"progress" = job ? clamp((world.time - job["start"]) / job["duration"], 0, 1) : 0,
			//"remaining" = job ? max(ceil((job["start"] + job["duration"] - world.time) / 10), 0) : 0,
		))
	return list("slots" = slots, "operational" = is_operational(), "refillTime" = round(refill_time / 10), "speedUp" = speed_up_percent)

/obj/machinery/medipen_refiller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/slot = text2num(params["slot"])
	if(!isnum(slot) || slot != round(slot) || slot < 1 || slot > max_medipens)
		return
	switch(action)
		if("insert")
			insert_medipen(usr.get_active_held_item(), usr, slot)
		if("eject")
			eject_medipen(slot, usr)
		if("start")
			start_refill(slot)
		if("stop")
			if(medipens[slot])
				cancel_refill(medipens[slot])
		else
			return
	return TRUE

#undef PERCENT_FASTER_FROM_MANIPULATOR
#undef BIN_ADD_SLOTS_COUNT
