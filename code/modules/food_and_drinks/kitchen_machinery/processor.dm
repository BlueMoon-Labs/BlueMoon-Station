
/obj/machinery/processor
	name = "food processor"
	desc = "Промышленный измельчитель для переработки мяса и прочей еды. Во время работы держите руки подальше от загрузочной зоны."
	icon = 'icons/obj/machines/kitchen.dmi'
	base_icon_state = "processor"
	icon_state = "processor"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 50
	circuit = /obj/item/circuitboard/machine/processor
	var/broken = FALSE
	var/processing = FALSE
	var/rating_speed = 1
	var/rating_amount = 1
	var/quality_increase = 5

/obj/machinery/processor/RefreshParts()
	quality_increase = 0
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		rating_amount = B.rating
		quality_increase += B.rating * 5
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		rating_speed = M.rating

/obj/machinery/processor/examine_display_content(mob/user)
	. += "– Выдаёт <b>[rating_amount]</b> шт. сырья на скорости <b>[rating_speed*100]%</b>."

/obj/machinery/processor/proc/process_food(datum/food_processor_process/recipe, atom/movable/what)
	if (recipe.output && loc && !QDELETED(src))
		var/obj/item/reagent_containers/food/food_input = what
		for(var/i = 0, i < rating_amount, i++)
			var/obj/item/reagent_containers/food/food_output = new recipe.output(drop_location())
			food_output.adjust_food_quality(food_input.food_quality + quality_increase)
	if (ismob(what))
		var/mob/themob = what
		themob.gib(TRUE,TRUE,TRUE)
	else
		qdel(what)

/obj/machinery/processor/proc/select_recipe(X)
	for (var/type in subtypesof(/datum/food_processor_process) - /datum/food_processor_process/mob)
		var/datum/food_processor_process/recipe = new type()
		if (!istype(X, recipe.input) || !istype(src, recipe.required_machine))
			continue
		return recipe

/obj/machinery/processor/attackby(obj/item/O, mob/user, params)
	if(processing)
		to_chat(user, span_warning("[src] уже занимается переработкой!"))
		return TRUE
	if(default_deconstruction_screwdriver(user, "[base_icon_state]_open", base_icon_state, O))
		return

	if(default_pry_open(O))
		return

	if(default_unfasten_wrench(user, O))
		return

	if(default_deconstruction_crowbar(O))
		return

	if(istype(O, /obj/item/storage/bag/tray))
		var/obj/item/storage/T = O
		var/loaded = 0
		for(var/obj/item/reagent_containers/food/snacks/S in T.contents)
			var/datum/food_processor_process/P = select_recipe(S)
			if(P)
				if(SEND_SIGNAL(T, COMSIG_TRY_STORAGE_TAKE, S, src))
					loaded++

		if(loaded)
			to_chat(user, span_notice("Вы загружаете в [src] предметов: [loaded]."))
		return

	var/datum/food_processor_process/P = select_recipe(O)
	if(P)
		user.visible_message("[user] помещает [O] в [src].", \
			"Вы помещаете [O] в [src].")
		user.transferItemToLoc(O, src, TRUE)
		return TRUE
	else
		if(user.a_intent != INTENT_HARM)
			to_chat(user, span_warning("Это вряд ли получится измельчить!"))
			return TRUE
		else
			return ..()

/obj/machinery/processor/interact(mob/user)
	if(processing)
		to_chat(user, span_warning("[src] уже занимается переработкой!"))
		return TRUE
	if(user.a_intent == INTENT_GRAB && ismob(user.pulling) && select_recipe(user.pulling))
		if(user.grab_state < GRAB_AGGRESSIVE)
			to_chat(user, span_warning("Вам понадобится хватка покрепче для этого!"))
			return
		var/mob/living/pushed_mob = user.pulling
		visible_message(span_warning("[user] засовывает [pushed_mob] в [src]!"))
		pushed_mob.forceMove(src)
		user.stop_pulling()
		return
	if(contents.len == 0)
		to_chat(user, span_warning("Внутри [src] ничего нет!"))
		return TRUE
	processing = TRUE
	user.visible_message("[user] включает [src].", \
		span_notice("Вы включаете [src]."), \
		span_italics("Вы слышите работу кухонного комбайна."))
	playsound(src.loc, 'sound/machines/blender.ogg', 50, 1)
	use_power(500)
	var/total_time = 0
	for(var/O in src.contents)
		var/datum/food_processor_process/P = select_recipe(O)
		if (!P)
			log_admin("DEBUG: [O] in processor doesn't have a suitable recipe. How did it get in there? Please report it immediately!!!")
			continue
		total_time += P.time
	var/duration = (total_time / rating_speed)
	Shake(2, 2, duration)
	addtimer(CALLBACK(src, PROC_REF(complete_processing)), duration)

/obj/machinery/processor/proc/complete_processing()
	// process_food() гибает или удаляет объект, то есть выносит его из contents прямо
	// в обходе по contents - индекс проматывается, и каждый второй загруженный предмет
	// молча не обрабатывался и оставался в машине
	for(var/atom/movable/O in src.contents.Copy())
		var/datum/food_processor_process/P = select_recipe(O)
		if (!P)
			log_admin("DEBUG: [O] in processor doesn't have a suitable recipe. How do you put it in?")
			continue
		process_food(P, O)
	processing = FALSE
	visible_message("[src] завершает переработку.")

/obj/machinery/processor/verb/eject()
	set category = "Object"
	set name = "Eject Contents"
	set src in oview(1)

	var/mob/living/L = usr
	if(!istype(L) || !CHECK_MOBILITY(L, MOBILITY_USE))
		return
	empty()
	add_fingerprint(usr)

/obj/machinery/processor/proc/empty()
	for (var/obj/O in src)
		O.forceMove(drop_location())
	for (var/mob/M in src)
		M.forceMove(drop_location())

/obj/machinery/processor/container_resist(mob/living/user)
	user.forceMove(drop_location())
	user.visible_message(span_notice("[user] выбирается из [src]!"))

/obj/machinery/processor/slime
	name = "slime processor"
	desc = "Промышленный измельчитель с наклейкой \"Присвоено научным отделом\". Во время работы держите руки подальше от зоны загрузки слаймов."
	base_icon_state = "processor_slime"
	icon_state = "processor_slime"
	circuit = /obj/item/circuitboard/machine/processor/slime

/obj/machinery/processor/slime/adjust_item_drop_location(atom/movable/AM)
	var/static/list/slimecores = subtypesof(/obj/item/slime_extract)
	var/i = 0
	if(!(i = slimecores.Find(AM.type))) // If the item is not found
		return
	if (i <= 16) // If in the first 12 slots
		AM.pixel_x = -12 + ((i%4)*8)
		AM.pixel_y = -12 + (round(i/4)*8)
		return i
	var/ii = i - 16
	AM.pixel_x = -8 + ((ii%3)*8)
	AM.pixel_y = -8 + (round(ii/3)*8)
	return i

/obj/machinery/processor/slime/process()
	if(processing)
		return
	var/mob/living/simple_animal/slime/picked_slime
	for(var/mob/living/simple_animal/slime/slime in range(1,src))
		if(slime.loc == src)
			continue
		if(istype(slime, /mob/living/simple_animal/slime))
			if(slime.stat)
				picked_slime = slime
				break
	if(!picked_slime)
		return
	var/datum/food_processor_process/P = select_recipe(picked_slime)
	if (!P)
		return

	visible_message("[picked_slime] затягивает внутрь [src].")
	picked_slime.forceMove(src)

/obj/machinery/processor/slime/process_food(datum/food_processor_process/recipe, atom/movable/what)
	var/mob/living/simple_animal/slime/S = what
	if (istype(S))
		var/C = S.cores
		if(S.stat != DEAD)
			S.forceMove(drop_location())
			S.visible_message(span_notice("[C] выбирается из [src]!"))
			return
		for(var/i in 1 to (C+rating_amount-1))
			var/atom/movable/item = new S.coretype(drop_location())
			adjust_item_drop_location(item)
			SSblackbox.record_feedback("tally", "slime_core_harvested", 1, S.colour)
	..()
