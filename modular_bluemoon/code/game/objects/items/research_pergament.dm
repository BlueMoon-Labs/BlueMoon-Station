// ============================================
// GLOBAL LIST
// ============================================
GLOBAL_LIST_EMPTY(simple_research)

// ============================================
// DATUM - Simple Research
// ============================================
/datum/simple_research
	var/research_item
	var/skilled_item
	var/list/required_items = list()

// Research definitions
/datum/simple_research/scanner
	research_item = /obj/item/stock_parts/scanning_module
	skilled_item = /obj/item/stock_parts/scanning_module/adv

/datum/simple_research/capacitor
	research_item = /obj/item/stock_parts/capacitor
	skilled_item = /obj/item/stock_parts/capacitor/adv

/datum/simple_research/servo
	research_item = /obj/item/stock_parts/manipulator
	skilled_item = /obj/item/stock_parts/manipulator/nano

/datum/simple_research/micro_laser
	research_item = /obj/item/stock_parts/micro_laser
	skilled_item = /obj/item/stock_parts/micro_laser/high

/datum/simple_research/matter_bin
	research_item = /obj/item/stock_parts/matter_bin
	skilled_item = /obj/item/stock_parts/matter_bin/adv

/datum/simple_research/cell
	research_item = /obj/item/stock_parts/cell
	skilled_item = /obj/item/stock_parts/cell/high

/datum/simple_research/cable
	research_item = /obj/item/stack/cable_coil/random/five
	skilled_item = /obj/item/stack/cable_coil

/datum/simple_research/part_replacer
	research_item = /obj/item/storage/part_replacer
	required_items = list(/datum/simple_research/cable)

/datum/simple_research/protolathe
	research_item = /obj/item/circuitboard/machine/protolathe
	required_items = list(/datum/simple_research/part_replacer)

/datum/simple_research/circuit_imprinter
	research_item = /obj/item/circuitboard/machine/circuit_imprinter/hacked
	required_items = list(/datum/simple_research/part_replacer)

/datum/simple_research/rdconsole
	research_item = /obj/item/circuitboard/computer/rdconsole
	required_items = list(
		/datum/simple_research/protolathe,
		/datum/simple_research/circuit_imprinter
	)

/datum/simple_research/inducer
	research_item = /obj/item/inducer
	skilled_item = /obj/item/inducer/syndicate
	required_items = list(
		/datum/simple_research/cell,
	)

/datum/simple_research/pacman
	research_item = /obj/item/circuitboard/machine/pacman
	required_items = list(/datum/simple_research/cell)

/datum/simple_research/smes
	research_item = /obj/item/circuitboard/machine/smes
	required_items = list(/datum/simple_research/pacman)

/datum/simple_research/drill
	research_item = /obj/item/pickaxe/drill
	skilled_item = /obj/item/pickaxe/drill/diamonddrill

/datum/simple_research/chem_dispenser
	research_item = /obj/item/circuitboard/machine/chem_dispenser
	required_items = list(/datum/simple_research/igniter)

/datum/simple_research/igniter
	research_item = /obj/item/assembly/igniter

/datum/simple_research/multitool
	research_item = /obj/item/multitool
	skilled_item = /obj/item/multitool/abductor

/datum/simple_research/pipe_dispenser
	research_item = /obj/item/pipe_dispenser
	skilled_item = /obj/item/pipe_dispenser/bluespace
	required_items = list(
		/datum/simple_research/multitool,
	)

// ============================================
// RESEARCH PAPER ITEM
// ============================================
/obj/item/research_paper
	name = "research paper"
	desc = "Одни люди хотят вернуться к более простым технологиям, а другие лишь начинают изучать эти простые технологии."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_SMALL
	var/list/discovered_items = list()
	var/static/list/shape_list = list("пирамида", "куб", "сфера")
	var/static/list/shape_parts = list("грани", "ребра", "вершины")
	var/static/list/thinking_list = list("задумыватся", "думать", "размышлять", "рассуждать", "медитировать", "размышлять")
	var/static/list/radial_icons_cache

/obj/item/research_paper/New()
	..()
	if(!GLOB.simple_research.len)
		var/list/possible_combinations = list()
		for(var/shape_one in shape_list)
			for(var/shape_two in shape_list)
				for(var/shape_three in shape_list)
					possible_combinations += "[shape_one][shape_two][shape_three]"

		for(var/datum_path in subtypesof(/datum/simple_research))
			var/shape_pattern = pick_n_take(possible_combinations)
			GLOB.simple_research["[shape_pattern]"] = datum_path

	if(!radial_icons_cache)
		radial_icons_cache = list(
			"пирамида" = image(icon = 'icons/obj/bureaucracy.dmi', icon_state = "pyramid"),
			"куб" = image(icon = 'icons/obj/bureaucracy.dmi', icon_state = "cube"),
			"сфера" = image(icon = 'icons/obj/bureaucracy.dmi', icon_state = "sphere")
		)

/obj/item/research_paper/attack_self(mob/user)
	..()

	// ПРОВЕРКА: Может ли персонаж использовать research paper через TRAIT
	if(!HAS_TRAIT(user, TRAIT_KNOWS_RESEARCH))
		to_chat(user, "<span class='warning'>Вы не знаете, как использовать этот странный метод исследования!</span>")
		return

	var/research_level = get_research_level(user)
	var/research_time = max(30, 50 - (research_level * 5))

	var/shape_one = show_radial_menu(user, src, radial_icons_cache, require_near = TRUE)
	if(!shape_one)
		return

	to_chat(user, "<span class='notice'>Вы начинаете [pick(thinking_list)] о [shape_one]... а потом [pick(thinking_list)] об их [pick(shape_parts)]...</span>")

	if(!do_after(user, research_time, target = src))
		to_chat(user, "<span class='warning'>Вы перестали исследовать.</span>")
		return

	var/shape_two = show_radial_menu(user, src, radial_icons_cache, require_near = TRUE)
	if(!shape_two)
		return

	to_chat(user, "<span class='notice'>Выначинаете [pick(thinking_list)] о [shape_two]... а затем [pick(thinking_list)] об их [pick(shape_parts)]...</span>")

	if(!do_after(user, research_time, target = src))
		to_chat(user, "<span class='warning'>Вы перестали исследовать.</span>")
		return

	var/shape_three = show_radial_menu(user, src, radial_icons_cache, require_near = TRUE)
	if(!shape_three)
		return

	to_chat(user, "<span class='notice'>Вы начинаете [pick(thinking_list)] о [shape_three]... а затем [pick(thinking_list)] об их [pick(shape_parts)]...</span>")

	if(!do_after(user, research_time, target = src))
		to_chat(user, "<span class='warning'>Вы перестали исследовать.</span>")
		return

	var/datum/simple_research/find_research = GLOB.simple_research["[shape_one][shape_two][shape_three]"]
	if(!find_research)
		to_chat(user, "<span class='warning'>Ваши размышления зашли в тупик!</span>")
		add_research_exp(user, 1)
		return

	find_research = new find_research()

	var/failure_amount = find_research.required_items.len
	for(var/check_required in find_research.required_items)
		for(var/check_discovered in discovered_items)
			if(check_required == check_discovered)
				failure_amount--

	if(failure_amount > 0)
		to_chat(user, "<span class='warning'>Вы не можете исследовать это! Вам не хватает [failure_amount] необходимых предметов!</span>")
		qdel(find_research)
		add_research_exp(user, 2)
		return

	if(!(find_research.type in discovered_items))
		discovered_items += find_research.type

	var/obj/item/research_scrap/spawned_scrap = new(get_turf(src))

	if(find_research.skilled_item)
		if(research_level >= 5)
			spawned_scrap.spawning_item = find_research.skilled_item
			to_chat(user, "<span class='notice'>Ваш опыт позволяет вам создать усовершенствованную версию!</span>")
		else if(research_level >= 3 && prob(50))
			spawned_scrap.spawning_item = find_research.skilled_item
			to_chat(user, "<span class='notice'>Вам удалось создать усовершенствованную версию!</span>")
		else
			spawned_scrap.spawning_item = find_research.research_item
	else
		spawned_scrap.spawning_item = find_research.research_item

	to_chat(user, "<span class='notice'>Вы успешно исследовали что-то!</span>")
	add_research_exp(user, 5)
	qdel(find_research)

// Получение уровня
/obj/item/research_paper/proc/get_research_level(mob/user)
	if(!user.mind)
		return 0

	if(isnull(user.mind.research_exp))
		user.mind.research_exp = 0

	return round(user.mind.research_exp / 20)

// Добавление опыта
/obj/item/research_paper/proc/add_research_exp(mob/user, amount)
	if(!user.mind)
		return

	if(isnull(user.mind.research_exp))
		user.mind.research_exp = 0

	var/old_level = get_research_level(user)
	user.mind.research_exp += amount
	var/new_level = get_research_level(user)

	if(new_level > old_level)
		to_chat(user, "<span class='boldnotice'>Ваши навыки исследования улучшились! Теперь вы на уровне [new_level].</span>")

		switch(new_level)
			if(3)
				to_chat(user, "<span class='notice'>Теперь у вас есть возможность создавать усовершенствованные версии предметов!</span>")
			if(5)
				to_chat(user, "<span class='notice'>Теперь вы можете постоянно создавать усовершенствованные версии предметов!</span>")

// ============================================
// RESEARCH SCRAP ITEM
// ============================================
/obj/item/research_scrap
	name = "research scrap"
	desc = "На обрывке нарисованы небольшие эскизы предмета — если вы используете эти материалы, то, возможно, сможете изготовить предмет, изображенный на обрывке!"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "scrapres"
	var/obj/spawning_item
	var/list/material_satisfied = list(FALSE, FALSE)

/obj/item/research_scrap/examine(mob/user)
	..()
	var/obj/item/temp_item = new spawning_item()
	to_chat(user, "<span class='info'>На обрывке видны наброски \a [temp_item.name].</span>")
	qdel(temp_item)

/obj/item/research_scrap/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/metal))
		research_use(I, user, 2)
		return

	if(istype(I, /obj/item/stack/sheet/glass))
		research_use(I, user, 1)
		return

	return ..()

/obj/item/research_scrap/proc/research_use(obj/item/stack/sheet/attacking_stack, mob/user, number = 1)
	if(!attacking_stack || !istype(attacking_stack))
		return

	if(material_satisfied[number])
		to_chat(user, "<span class='warning'>Вы уже использовали [attacking_stack] на этом обрывке!</span>")
		return

	if(!attacking_stack.use(1))
		to_chat(user, "<span class='warning'>У вас недостаточно [attacking_stack]!</span>")
		return

	to_chat(user, "<span class='notice'>Ты использовал [attacking_stack] на [src].</span>")
	material_satisfied[number] = TRUE

	if(material_satisfied[1] && material_satisfied[2])
		new spawning_item(get_turf(src))
		to_chat(user, "<span class='notice'>Вы завершили [src] и создали элемент!</span>")

		if(user.mind)
			if(isnull(user.mind.research_exp))
				user.mind.research_exp = 0
			user.mind.research_exp += 3

		qdel(src)
