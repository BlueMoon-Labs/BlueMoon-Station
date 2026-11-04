/datum/action/cooldown/latexmob
	name = "Living latex"
	icon_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	button_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	background_icon_state = "background"
	button_icon_state = "no_icon"
	var/stage_required = 0
	var/stage = 0
	var/finall_stage = LATEX_MAX_STAGE
	var/points_need_to_upgrade = 1
	var/points_need_to_purchase = 1
	var/datum/antagonist/living_latex/my_living_latex
	var/is_internal_ability = FALSE

/datum/action/cooldown/latexmob/Destroy()
	my_living_latex = null
	return ..()

/datum/action/cooldown/latexmob/proc/update_stage()
	my_living_latex.evolve_points -= points_need_to_upgrade
	stage++
	var/upgraded_icon = "[initial(button_icon_state)]_[stage]"
	if(upgraded_icon in icon_states(icon_icon))
		button_icon_state = upgraded_icon
	UpdateButtons()

/datum/action/cooldown/latexmob/Activate(atom/target)
	if(QDELETED(owner) || !owner.mind || owner.stat == DEAD)
		return FALSE
	if(!my_living_latex)
		my_living_latex = check_LL_antagDatum(owner)
	if(QDELETED(my_living_latex) || my_living_latex.owner != owner.mind)
		return FALSE
	if(is_internal_ability && !my_living_latex.host_organ)
		return FALSE
	return TRUE

/datum/action/cooldown/latexmob/takeControl
	stage_required = 3
	button_icon_state = "Infiltrate"
	name = "Захватить контроль над телом"
	desc = "Обменяться управлением с носителем. Его тело и импланты сохраняются."
	is_internal_ability = TRUE

/datum/action/cooldown/latexmob/takeControl/Activate()
	if(!..())
		return FALSE
	if(my_living_latex.current_controller != VENOM_USER && my_living_latex.stage < stage_required)
		return FALSE
	if(!my_living_latex.host_organ.swap_control())
		return FALSE
	my_living_latex.evolve_points = 0
	return TRUE

/datum/action/cooldown/latexmob/venomAction
	name = "Поглотить/освободить"
	desc = "Выбрать цель рядом. Повторное нажатие прерывает обволакивание или освобождает носителя."
	button_icon_state = "Infiltrate"
	stage_required = 1
	var/pick_only_simplemob = TRUE
	var/can_absorb_alive = FALSE
	var/absorbed_mobs_counter = 1
	var/busy = FALSE

/datum/action/cooldown/latexmob/venomAction/update_stage()
	. = ..()
	can_absorb_alive = stage >= 2
	pick_only_simplemob = stage < 3

/datum/action/cooldown/latexmob/venomAction/Activate()
	if(!..())
		return FALSE
	if(my_living_latex.capture)
		QDEL_NULL(my_living_latex.capture)
		return TRUE
	if(my_living_latex.host_organ)
		my_living_latex.host_organ.release()
		return TRUE
	if(busy || !islatexmob(owner) || isbackseatmob(owner))
		return FALSE
	var/mob/living/simple_animal/latexmob/user = owner
	if(user.mimicry_in_use)
		user.go_back()
	busy = TRUE
	var/mob/living/target = LL_mob_choice_with_radial_menu(user, pick_only_simplemob)
	if(QDELETED(src))
		return FALSE
	busy = FALSE
	return try_target(target)

/datum/action/cooldown/latexmob/venomAction/proc/try_target(mob/living/target)
	if(busy || !can_merge_target(owner, target, pick_only_simplemob, can_absorb_alive))
		return FALSE
	if(ishuman(target))
		var/datum/latex_capture/attempt = new(my_living_latex, owner, target)
		if(!attempt.start())
			qdel(attempt)
			return FALSE
		return TRUE
	busy = TRUE
	var/mob/living/simple_animal/latexmob/user = owner
	var/finished = user.LL_apply_animated_latex_overlay_with_progressbar(DEFAULT_LL_OVERLAY_ICON, DEFAULT_LL_OVERLAY_ICON_STATE, LATEX_ABSORB_DELAY, target)
	if(QDELETED(src))
		return FALSE
	busy = FALSE
	if(!finished)
		return FALSE
	return do_absorb_simple_mob(target, user, my_living_latex, src)

/datum/action/cooldown/latexmob/traces
	name = "Следы латекса"
	desc = "Включить или выключить следы при касании."

/datum/action/cooldown/latexmob/traces/Activate()
	if(!..())
		return FALSE
	my_living_latex.leave_traces = !my_living_latex.leave_traces
	owner.balloon_alert(owner, my_living_latex.leave_traces ? "следы включены" : "следы выключены")
	return TRUE

/datum/action/cooldown/latexmob/ferral_form
	name = "Форма животного"
	desc = "Переключиться между сгустком и маленьким латексным существом."
	button_icon_state = "ferral_form"
	stage_required = 2
	var/melee_damage = LATEX_FORM_DAMAGE

/datum/action/cooldown/latexmob/ferral_form/update_stage()
	. = ..()
	melee_damage *= LATEX_FORM_DAMAGE_STEP

/datum/action/cooldown/latexmob/ferral_form/Activate()
	if(!..() || my_living_latex.capture || my_living_latex.host_organ)
		return FALSE
	if(!islatexmob(owner) || !isturf(owner.loc) || owner.stat != CONSCIOUS)
		return FALSE
	var/mob/living/simple_animal/latexmob/user = owner
	if(user.mimicry_in_use)
		return FALSE
	var/health_fraction = user.health / user.maxHealth
	var/form = istype(user, /mob/living/simple_animal/latexmob/ferral) ? /mob/living/simple_animal/latexmob : /mob/living/simple_animal/latexmob/ferral
	var/mob/living/simple_animal/latexmob/new_body = swap_LL_body_to_new_form(user, form, get_turf(user))
	if(!new_body)
		return FALSE
	new_body.adjustBruteLoss(new_body.maxHealth * (1 - health_fraction))
	new_body.melee_damage_lower = melee_damage - LATEX_FORM_DAMAGE_SPREAD
	new_body.melee_damage_upper = melee_damage
	return TRUE

/datum/action/cooldown/latexmob/medscan
	name = "Проверить здоровье"
	desc = "Проверить здоровье носителя или собственного тела."
	button_icon_state = "medscan"
	stage_required = 1

/datum/action/cooldown/latexmob/medscan/Activate()
	if(!..())
		return FALSE
	var/mob/living/subject = my_living_latex.host_organ?.owner || owner
	healthscan(owner, subject, advanced = stage >= 2)
	if(stage >= 3)
		chemscan(owner, subject)
	return TRUE

/datum/action/cooldown/latexmob/heal
	name = "Лечение"
	desc = "Вводить реагенты в носителя за очки эволюции."
	button_icon_state = "heal"
	stage_required = 1
	var/datum/inject_menu/inject_menu

/datum/action/cooldown/latexmob/heal/update_stage()
	. = ..()
	if(stage >= 2)
		my_living_latex.avaible_reagents |= my_living_latex.second_stage_reagents
	if(stage >= 3)
		my_living_latex.avaible_reagents |= my_living_latex.last_stage_reagents

/datum/action/cooldown/latexmob/heal/Activate()
	if(!..())
		return FALSE
	if(!inject_menu)
		inject_menu = new(my_living_latex)
	inject_menu.ui_interact(owner)
	return TRUE

/datum/action/cooldown/latexmob/heal/Destroy()
	QDEL_NULL(inject_menu)
	return ..()

/datum/action/cooldown/latexmob/stasis
	name = "Стазис"
	desc = "Прижаться к полу или скрыть присутствие в носителе от сканера."
	button_icon_state = "Stasis"
	stage_required = 2

/datum/action/cooldown/latexmob/stasis/Activate()
	if(!..() || my_living_latex.capture)
		return FALSE
	if(my_living_latex.host_organ)
		my_living_latex.hide_latexorgan_on_healscan = !my_living_latex.hide_latexorgan_on_healscan
		my_living_latex.host_organ.update_hiding_state()
		return TRUE
	if(!islatexmob(owner) || owner.stat != CONSCIOUS)
		return FALSE
	owner.layer = owner.layer == ABOVE_NORMAL_TURF_LAYER ? MOB_LAYER : ABOVE_NORMAL_TURF_LAYER
	return TRUE

/datum/action/cooldown/latexmob/leak_out
	name = "Проползти под шлюзом"
	desc = "Проползти под соседним шлюзом."
	button_icon_state = "leak_out"
	stage_required = 3

/datum/action/cooldown/latexmob/leak_out/Activate()
	if(!..() || !islatexmob(owner) || !isturf(owner.loc) || my_living_latex.capture)
		return FALSE
	var/list/doors = list()
	for(var/obj/machinery/door/airlock/door in orange(1, owner))
		if(owner.Adjacent(door))
			doors += door
	if(!length(doors))
		return FALSE
	var/obj/machinery/door/airlock/door = pick(doors)
	var/mob/living/user = owner
	if(!do_after(user, LATEX_LEAK_DELAY, target = door) || QDELETED(door) || !user.Adjacent(door))
		return FALSE
	return user.forceMove(get_turf(door))

/datum/action/cooldown/latexmob/human_form
	name = "Сформировать человеческое тело"
	desc = "Создать собственное тело живого латекса."
	button_icon_state = "human_form"
	stage_required = 3

/datum/action/cooldown/latexmob/human_form/Activate()
	if(!..() || !islatexmob(owner) || !isturf(owner.loc) || my_living_latex.capture || my_living_latex.host_organ)
		return FALSE
	var/mob/living/simple_animal/latexmob/user = owner
	if(user.mimicry_in_use)
		return FALSE
	var/mob/living/carbon/human/body = new(get_turf(user))
	body.set_species(/datum/species/jelly/living_latex)
	body.name = my_living_latex.latex_name
	body.real_name = body.name
	var/datum/mind/latex_mind = user.mind
	latex_mind.transfer_to(body)
	if(latex_mind.current != body)
		qdel(body)
		return FALSE
	body.AddComponent(/datum/component/latex_contact)
	user.drop_all_held_items()
	qdel(user)
	return TRUE
