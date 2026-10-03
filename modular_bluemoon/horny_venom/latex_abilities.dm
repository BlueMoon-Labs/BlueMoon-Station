//Способности

/datum/action/cooldown/latexmob
	name = "generic latexmob proc"
	desc = "Вы не должны это видеть в игре. Это базовый прок холдер, он содержит базовые свойства."
	icon_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	button_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	background_icon_state = "background"
	button_icon_state = "no_icon"
	var/stage_required
	var/stage = 0
	var/finall_stage = 3
	var/points_need_to_upgrade = 1
	var/points_need_to_purchase = 1
	var/delay
	var/datum/antagonist/living_latex/my_living_latex
	var/is_internal_ability = FALSE //если эта способность должна быть доступна только изнутри захваченного моба

/datum/action/cooldown/latexmob/proc/update_stage()
	if(!owner)
		return
	my_living_latex.evolve_points -= points_need_to_upgrade
	++stage //сначала увеличивает на 1, потом возвращает результат сложения
	button_icon_state = initial(button_icon_state) + "_[stage]" //initial нужен чтобы из Infiltrate_1 не получалось Infiltrate_1_2_3 которое сломает всю логику
	UpdateButtons()

/datum/action/cooldown/latexmob/Activate(atom/target)
	if(!isbackseatmob(owner) && is_internal_ability) //backseatmob появляется только когда игрок внутри
		return FALSE
	if(owner.mind && !my_living_latex)
		my_living_latex = check_LL_antagDatum(owner)
		delay = my_living_latex.mergingDelay
	else
		return FALSE

/datum/action/cooldown/latexmob/takeControl
	stage_required = 3
	button_icon_state = "Infiltrate"
	name = "Захватить контроль над телом"
	desc = "Возьмите тело под свой контроль и управляйте им как своим"
	is_internal_ability = TRUE

/datum/action/cooldown/latexmob/takeControl/Activate()
	. = ..()
	var/mob/living/body = is_venom_controlling(my_living_latex) ? owner : owner.loc
	var/obj/item/organ/latexOrgan/organ = get_latexOrgan_if_captured_by_LL(body)
	if(!organ)
		return
	var/mob/living/simple_animal/latexmob/venom/backseat = organ.ObserverBackseat
	swap_LL_species(my_living_latex, owner)
	if(!swap_minds(my_living_latex, owner, backseat))
		swap_LL_species(my_living_latex, owner)
		return FALSE
	my_living_latex.evolve_points = 0 //BURN IT ALL, BACK TO ZERO. Делаю эту абилку самой дорогой.
	return TRUE

/datum/action/cooldown/latexmob/venomAction
	name = "Поглотить/освободить"
	desc = "Станьте одним целым с кем-то."
	button_icon_state = "Infiltrate"
	stage_required = 1
	var/pick_only_simplemob = TRUE
	var/can_absorb_alive = FALSE
	var/absorbed_mobs_counter = 1

/datum/action/cooldown/latexmob/venomAction/update_stage()
	. = ..()
	if(stage == 2)
		can_absorb_alive = TRUE
	if(stage == 3)
		pick_only_simplemob = FALSE

/datum/action/cooldown/latexmob/venomAction/Activate()
	. = ..()
	if(protect_from_spam(owner))
		return DEFAULT_ABILITY_ERROR_MESSAGE(owner)

	if(islatexmob(owner) && !isbackseatmob(owner))
		var/mob/living/carbon/target_host = LL_mob_choice_with_radial_menu(owner, pick_only_simplemob)

		// Первая ветка поглощения простого моба
		if(isanimal(target_host))
			if(target_host && can_merge_target(owner, target_host, pick_only_simplemob, can_absorb_alive))
				var/absorb_delay = 5 SECONDS
				var/finished = owner.LL_apply_animated_latex_overlay_with_progressbar(DEFAULT_LL_OVERLAY_ICON, DEFAULT_LL_OVERLAY_ICON_STATE, absorb_delay, target_host)
				if(finished)
					do_absorb_simple_mob(target_host, owner, my_living_latex, src)
			return

		// Вторая ветка слияния
		if(target_host && can_merge_target(owner, target_host, pick_only_simplemob, can_absorb_alive))
			if(checkplayerssd(target_host))
				return MERGING_SSD_ERROR(owner)
			handle_merging(target_host)
			enter_in_host(my_living_latex, owner, delay, target_host)
	else
		var/mob/living/simple_animal/latexmob/venom/user = owner
		if(ishuman(user.body))
			exit_from_host(user.body.loc, owner.mind, user.body, delay, my_living_latex)
		else
			return DEFAULT_ABILITY_ERROR_MESSAGE(owner)

	return

/datum/action/cooldown/latexmob/ferral_form
	name = "Форма животного"
	desc = "Принять форму животного"
	button_icon_state = "ferral_form"
	stage_required = 2
	var/melee_damage = 5
	var/list/forms_list = list()

/datum/action/cooldown/latexmob/ferral_form/update_stage()
	. = ..()
	melee_damage = melee_damage * 1.25

/datum/action/cooldown/latexmob/ferral_form/Activate()
	. = ..()
	var/mob/living/owner_mob = owner
	var/old_body_health = owner_mob.health
	var/mob/living/simple_animal/latexmob/new_body
	if(istype(owner, /mob/living/simple_animal) && !istype(owner, /mob/living/simple_animal/latexmob/ferral))
		LL_mob_choice_with_radial_menu(owner, use_custom_list = forms_list)
		new_body = swap_LL_body_to_new_form(owner, /mob/living/simple_animal/latexmob/ferral, owner.loc)
		if(forms_list.len == 0)
			forms_list += new_body
		new_body.health = old_body_health
		new_body.melee_damage_lower = melee_damage - 2
		new_body.melee_damage_upper = melee_damage

	else if(istype(owner, /mob/living/simple_animal/latexmob/ferral))
		new_body = swap_LL_body_to_new_form(owner, /mob/living/simple_animal/latexmob, owner.loc)
		new_body.health = old_body_health

	else
		return DEFAULT_ABILITY_ERROR_MESSAGE(owner)

	my_living_latex.grant_abilities(new_body)

/datum/action/cooldown/latexmob/medscan
	name = "Проверить здоровье"
	desc = "Позволяет вам понять состояние своего носителя и реагенты в его крови. С более высокой стадией вашего развития этот сканер станет лучше."
	button_icon_state = "medscan"
	stage_required = 1
	var/is_simple = TRUE
	var/list/modes = list("chem", "heal", "wound")

/datum/action/cooldown/latexmob/medscan/update_stage()
	. = ..()
	if(stage == 2)
		is_simple = FALSE
	if(stage == 3)
		var/datum/atom_hud/H = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		H.add_hud_to(owner)

/datum/action/cooldown/latexmob/medscan/Activate()
	. = ..()
	var/mob/living/carbon/host = owner.loc
	if(is_simple)
		healthscan(owner, istype(host) ? host : owner)
	else
		var/mode = tgui_input_list(owner, "Выбор режима", "Режим анализа", modes, default = "heal")
		switch(mode)
			if("heal")
				healthscan(owner, istype(host) ? host : owner, advanced = TRUE)
			if("chem")
				chemscan(owner, istype(host) ? host : owner)
			if("wound")
				woundscan(owner, istype(host) ? host : owner)

/datum/action/cooldown/latexmob/heal
	name = "Лечение"
	desc = "Впрыскивает в кровь носителя реагенты на выбор, для лечения или иных нужд. Чем выше стадия - тем больше выбора реагентов."
	button_icon_state = "heal"
	stage_required = 1
	cooldown_time = 30 SECONDS
	var/datum/inject_menu/inject_menu

/datum/action/cooldown/latexmob/heal/update_stage()
	. = ..()
	if(stage == 2)
		my_living_latex.avaible_reagents += my_living_latex.second_stage_reagents
	if(stage == 3)
		my_living_latex.avaible_reagents += my_living_latex.last_stage_reagents

/datum/action/cooldown/latexmob/heal/Grant(var/mob/user)
	. = ..()
	if(owner.mind)
		my_living_latex = check_LL_antagDatum(owner)
	if(!my_living_latex)
		CRASH("inject menu cant locate living latex datum")
	inject_menu = new /datum/inject_menu(owner, my_living_latex)
	if(!inject_menu)
		CRASH("inject_menu action created with non menu")

/datum/inject_menu
	var/name = "Injecting menu"
	var/data
	var/datum/antagonist/living_latex/living_latex
	var/datum/owner
	var/last_action_time = 0
	var/cooldown_duration = 50 // 5 секунд

/datum/inject_menu/New(my_owner, my_living_latex)
	living_latex = my_living_latex
	owner = my_owner

/datum/inject_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/inject_menu/ui_data(mob/user)
	var/list/data = list()
	var/list/reagents = list()

	for(var/type_of_reagent in living_latex.avaible_reagents)
		var/list/reag = list()
		var/datum/reagent/R = new type_of_reagent
		reag["name"] = R.name
		reagents += list(reag)
		qdel(R)

	data["subject"] = living_latex.owner.current
	data["reagents"] = reagents
	data["cooldown_remaining"] = max(0, (last_action_time + cooldown_duration - world.time) / 10)
	data["evolve_poins"] = living_latex.evolve_points
	return data

/datum/inject_menu/ui_act(action, params)
	if(..())
		return

	if(world.time < last_action_time + cooldown_duration)
		to_chat(owner, "Подождите [round((last_action_time + cooldown_duration - world.time) / 10)] секунд перед следующей инъекцией.")
		return

	if(action == "inject")
		var/reagent_name = params["reagent_name"]
		living_latex.inject_reagent(reagent_name)
		last_action_time = world.time

/datum/inject_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "InjectMenu", name)
		ui.open()

/datum/action/cooldown/latexmob/heal/Activate()
	inject_menu.ui_interact(owner)

/datum/action/cooldown/latexmob/stasis
	name = "Стазис"
	desc = "Позволяет спрятаться на время от сканеров и какого-либо обнаружения вне тела хозяина. Полностью отключает все ваши способности на время."
	button_icon_state = "Stasis"
	stage_required = 2

/datum/action/cooldown/latexmob/stasis/Activate()
	. = ..()
	if(owner.stat != CONSCIOUS && isanimal(owner))
		return
	if (owner.layer != ABOVE_NORMAL_TURF_LAYER)
		owner.layer = ABOVE_NORMAL_TURF_LAYER
		if(isbackseatmob(owner))
			my_living_latex.hide_latexorgan_on_healscan = TRUE
			owner.balloon_alert(owner, "Ваше присутствие в теле скрыто от сканеров!")
			return
		else
			owner.visible_message("<span class='name'>[owner] прижимается к земле!</span>")
			owner.balloon_alert(owner, "Вы начинаете прятаться!")
	else
		owner.layer = MOB_LAYER
		my_living_latex.hide_latexorgan_on_healscan = FALSE
		if(!isbackseatmob(owner))
			owner.visible_message("[owner] медленно поднимается с земли...")
		owner.balloon_alert(owner, "Вы перестаёте прятаться!")
	return TRUE

/datum/action/cooldown/latexmob/leak_out
	name = "Проползти под шлюзом"
	desc = "Позволяет вашему гибкому телу проползать под шлюзами."
	button_icon_state = "leak_out"
	stage_required = 3

/datum/action/cooldown/latexmob/leak_out/Activate()
	. = ..()
	if(!istype(owner, /mob/living/simple_animal/latexmob))
		return LEAK_OUT_ERROR_MESSAGE(owner)
	var/list/nearby_things = range(1, get_turf(src))
	var/list/valid_doors = list()
	for(var/atom/thing in nearby_things)
		if(!istype(thing, /obj/machinery/door/airlock))
			continue
		valid_doors.Add(thing)
	if(valid_doors.len >= 1)
		var/choice = pick(valid_doors)
		if(do_after(usr, 1.5 SECONDS, usr))
			owner.forceMove(get_turf(choice))
	else
		return NO_AIRLOCK_NEABY(owner)

/datum/action/cooldown/latexmob/human_form
	name = "Сформировать человеческое тело"
	desc = "Вы накопили достаточно биоматериала, чтобы сформировать свое собственное отдельное тело"
	button_icon_state = "human_form"
	stage_required = 3
	var/list/human_visuals_storage = list() //Игрок должен иметь возможность удобного выбора внешки и сохранять её.

/datum/action/cooldown/latexmob/human_form/Activate()
	. = ..()

/datum/action/cooldown/latexmob/mimicry
	name = "Мимикрия"
	desc = "Возможность мимикрировать под элементы окружения, или одежду для маскировки."
	stage_required = 2
	finall_stage = 4
	var/obj/copied_object
	var/list/avaible_types_for_mimicry = list()
	var/alist/components_list = alist(
		/datum/component/latex_mimicry/crate 			= /obj/structure/closet/crate,
		/datum/component/latex_mimicry/closet 			= /obj/structure/closet,
		/datum/component/latex_mimicry/chair 			= /obj/structure/chair,
		/datum/component/latex_mimicry/food_container   = /obj/item/reagent_containers/food,
		/datum/component/latex_mimicry/washing_machine  = /obj/machinery/washing_machine,
		/datum/component/latex_mimicry/sleeper          = /obj/machinery/sleeper,
		/datum/component/latex_mimicry/vending_machine  = /obj/machinery/vending,
		/datum/component/latex_mimicry/computer         = /obj/machinery/computer,
		/datum/component/latex_mimicry/book             = /obj/item/book,
		/datum/component/latex_mimicry/clothing         = /obj/item/clothing,
		/datum/component/latex_mimicry 	                = /obj/item,
	)

/datum/action/cooldown/latexmob/mimicry/proc/choose_component_datum(/obj/copied_object)
	for(var/mimicry_type in components_list)
		if(copied_object.parent_type == components_list[mimicry_type] || copied_object.type == components_list[mimicry_type])
			return mimicry_type

	owner.balloon_alert(owner, "Слишком сложный объект!")
	return FALSE

/datum/action/cooldown/latexmob/mimicry/update_stage()
	. = ..()
	if(stage == 3)
		avaible_types_for_mimicry += my_living_latex.advanced_mimicry_types
	if(stage == 4)
		avaible_types_for_mimicry += my_living_latex.superior_special_mimicry_types

/datum/action/cooldown/latexmob/mimicry/Activate(atom/target, var/try_copy = FALSE)
	. = ..()

	if(avaible_types_for_mimicry.len == 0)
		avaible_types_for_mimicry += my_living_latex.base_mimicry_types

	if(!copied_object && try_copy == FALSE)
		owner.balloon_alert(owner, "Нажмите Ctrl+Click по объекту!")
		return
	if(islatexmob(owner) && try_copy == FALSE)
		var/mob/living/simple_animal/latexmob/my_mob = owner
		var/mimicry_in_use = my_mob?.mimicry_in_use
		var/datum/component/latex_mimicry/choosed_mimicry_datum = choose_component_datum(copied_object)
		if(!choosed_mimicry_datum)
			return
		if(!mimicry_in_use)
			my_mob.do_mimicry(copied_object.appearance, copied_object.type, list_of_shapes, choosed_mimicry_datum)
		else
			my_mob.go_back()
		my_mob.mimicry_in_use = !mimicry_in_use
