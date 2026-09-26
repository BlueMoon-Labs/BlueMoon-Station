/**
 * Проверяет, захвачена ли цель. Если да, то возвращает latexOrgan
 */
/datum/action/cooldown/latexmob/proc/get_latexOrgan_if_captured_by_LL(mob/living/carbon/human/owner)
	var/obj/item/organ/latexOrgan/organ = locate(/obj/item/organ/latexOrgan) in owner.internal_organs
	return organ
/**
 * Поиск антаг датума Living Latex среди всех остальных. Возвращает сам датум, если его нет, то False
 * На вход подавать того, в ком искать.
 */
/datum/action/cooldown/latexmob/proc/check_LL_antagDatum(mob/living/owner)
	var/datum/antagonist/living_latex/antag_datum = owner.mind ? locate(/datum/antagonist/living_latex) in owner.mind.antag_datums : FALSE
	return antag_datum
/**
 * Проверка на наличие прогрессбара не даёт спамить длительными процессами. Возвращает TRUE если прогрессбар есть.
 */
/datum/action/cooldown/latexmob/proc/protect_from_spam(mob/living/owner)
	if(owner.progressbars)
		SLOW_DOWN_ANTISPAM_MESSAGE(owner)
		return TRUE
	return FALSE
/**
 * Возвращает TRUE или FALSE в зависимости от того, кто контролирует текущее тело хоста
 * Зависит от переменной внутри датума living_latex под названием current_controller
 * Если она пуста, или содержит BODY_OWNER, то proc вернёт FALSE
 */

/datum/action/cooldown/latexmob/proc/is_venom_controlling(datum/antagonist/living_latex/LL)
	return LL?.current_controller == VENOM_USER

/**
 * Меняет расу хоста при смене контроля. Определяет само кого и куда.
 */
/datum/action/cooldown/latexmob/proc/swap_LL_species(datum/antagonist/living_latex/LL, mob/living/LL_mob)
	if(iscarbon(LL_mob.loc)) //Игрок LL на втором плане, захватывает тельце хоста
		var/mob/living/carbon/body = LL_mob.loc
		LL.old_host_spec = body.dna.species
		var/datum/species/new_species = LL.self_species
		new_species.copy_properties_from(body.dna.species)
		body.set_species(new_species)
	else //Игрок на LL возвращает контроль владельцу тела над телом(Локация LL = турф, а значит он за "рулём")
		LL_mob.set_species(LL.old_host_spec) // Возвращаем как было(в будущем опционально)

/**
 * Меняет backseat и тело host-а местами, вне зависимости от того, кто и где сидит.
 * Определение идёт на уровне сравнения LL_body с аргументом host_body. Если они равны, то становится понятно,
 * что игрок LL находится в теле host-а.
 */
/datum/action/cooldown/latexmob/proc/easy_latexmob_minds_swap(datum/mind/LL_mind, datum/mind/host_mind, mob/living/host_body, datum/antagonist/living_latex/LL, mob/living/simple_animal/latexmob/venom/backseat)
	var/mob/living/LL_body = LL_mind.current
	if(LL_body == host_body)
		var/datum/mind/captured_host_mind = backseat.mind //когда LL_body == bost_body то host_mind == LL_mind и надо найти целевой.
		if(checkplayerssd(backseat)) //хуманов с генетики можно, а ливнувших игроков нельзя
			return MERGING_SSD_ERROR(LL_mind.current)
		LL_mind.transfer_to(backseat, TRUE)
		captured_host_mind ? captured_host_mind.transfer_to(LL_body, TRUE) : null //Но и целевого может не быть, если тело - мартышка.
		LL.current_controller = BODY_OWNER
	else
		if(checkplayerssd(host_body))
			return MERGING_SSD_ERROR(LL_mind.current)
		LL_mind.transfer_to(host_body, TRUE) //Без TRUE выкинет LL_mind в госты и всё.
		host_mind ? host_mind.transfer_to(backseat, TRUE) : null //host_mind-а может не быть, в случае с мартышкой
		LL.current_controller = VENOM_USER

/**
 * Функция формата тумблер туда-обратно, завязанная на mind-ах.
 * Сработает один раз - махнёт один майнд в тело, а тот, что был на его месте - на backseat
 * Сработает второй раз, то вернёт обратно.
 * Если у цели нет mind-а(мартышки и прочие неразумные), то без лишних проверок позволяет захватить контроль
 */
/datum/action/cooldown/latexmob/proc/swap_minds(datum/antagonist/living_latex/LL, mob/living/ability_owner, mob/living/simple_animal/latexmob/venom/backseat)
	if(!ability_owner || !backseat || !LL)
		return FALSE
	var/mob/living/body = is_venom_controlling(LL) ? ability_owner : ability_owner.loc //Кто контролирует тело? Латекс? Нет? Ну тогда руль явно у body owner
	easy_latexmob_minds_swap(ability_owner.mind, body.mind, body, LL, backseat)
	return TRUE

/datum/action/cooldown/latexmob/proc/swap_LL_body_to_new_form(mob/living/old_body, mob_typepath, turf/location)
	var/mob/living/new_body = new mob_typepath(location)
	old_body.mind.transfer_to(new_body)
	new_body.name = old_body.name
	qdel(old_body)
	return(new_body)

/datum/action/cooldown/latexmob/proc/LL_mob_choice_with_radial_menu(mob/living/simple_animal/latexmob/owner, var/pick_only_simplemob, var/list/use_custom_list)
	var/list/choices = list()
	var/list/choices_img = list()
	var/list/targets = use_custom_list ? use_custom_list : oview(1, owner)
	for(var/mob/living/C in targets)
		if(ishuman(C) && pick_only_simplemob)
			continue
		choices += C
		var/image/choice_image = image(icon = C.icon, icon_state = C.icon_state)
		choice_image.overlays = C.overlays
		choices_img[C.name] = choice_image
	var/choice = show_radial_menu(owner, owner, choices_img)

	if(!choice)
		owner.balloon_alert(owner, "Не найдено подходящей цели!")
		return null

	return choices[choices_img.Find(choice)]

/datum/action/cooldown/latexmob/proc/do_absorb_simple_mob(mob/living/simple_animal/absorbed_mob, mob/living/simple_animal/latexmob/absorber, datum/antagonist/living_latex/LL, datum/action/cooldown/latexmob/venomAction/my_action)
	var/absorbed_mobs_modifier = max(1 - (my_action.absorbed_mobs_counter - 1) * 0.1, 0.1)
	absorber.loc = absorbed_mob.loc
	var/additional_points = (absorbed_mob.maxHealth * 0.001) * absorbed_mobs_modifier
	LL.evolve_points += additional_points
	my_action.absorbed_mobs_counter ++
	absorber.balloon_alert(absorber, "<span class='warning'>Вы получили [additional_points] очков. Итого: [LL.evolve_points] очков</span>")
	qdel(absorbed_mob)

/mob/proc/LL_build_latex_icon(icon_file, icon_state)
	if(!icon_file || !icon_state)
		return null

	var/icon/mask = getIconMask(src)
	if(!mask)
		return null

	var/icon/overlay_icon = icon(icon_file, icon_state)

	overlay_icon.UseAlphaMask(mask)

	return overlay_icon

/mob/proc/LL_apply_latex_overlay(icon_file, icon_state, alpha)
	if(!icon_file || !icon_state)
		return

	var/icon/latex_icon = LL_build_latex_icon(icon_file, icon_state)
	if(!latex_icon)
		return

	var/mutable_appearance/MA = mutable_appearance(latex_icon)
	MA.alpha = alpha
	MA.layer = layer + 0.1

	add_overlay(MA)
	return MA

/mob/proc/LL_apply_animated_latex_overlay_with_progressbar(icon_file, icon_state, delay, mob/absorb_target)
	var/mob/owner_mob = src
	var/mutable_appearance/overlay = absorb_target.LL_apply_latex_overlay(DEFAULT_LL_OVERLAY_ICON, DEFAULT_LL_OVERLAY_ICON_STATE)
	var/start_time = world.time
	var/finished = TRUE
	var/datum/progressbar/progbar
	var/list/overlays_to_del = list(overlay)
	progbar = new(owner_mob, delay, absorb_target)
	while(world.time < start_time + delay)
		stoplag(1)
		if(get_dist(absorb_target, owner_mob) > 1)
			owner_mob.balloon_alert(owner_mob, "Вы слишком далеко!")
			finished = FALSE
			break
		if(QDELETED(overlay) || QDELETED(owner_mob) || QDELETED(absorb_target))
			finished = FALSE
			break
		var/elapsed = world.time - start_time
		progbar.update(elapsed)
		// Линейная интерполяция: alpha = 0 + (elapsed / delay) * 255
		var/alpha = round(255 * elapsed / delay)
		alpha = max(0, min(255, alpha))  // ограничиваем диапазон
		overlay = absorb_target.LL_apply_latex_overlay(DEFAULT_LL_OVERLAY_ICON, DEFAULT_LL_OVERLAY_ICON_STATE, alpha)
		overlays_to_del += overlay
	for(var/target in overlays_to_del)
		absorb_target.cut_overlay(target) //их там реально много собирается
	progbar.end_progress()
	return finished

/datum/action/cooldown/latexmob/proc/can_LL_absorb_alive(mob/living/owner, can_absorb_alive, mob/living/target_host)
	if (!target_host)
		return FALSE
	if (target_host && (can_absorb_alive || target_host.stat == DEAD))
		return TRUE
	else if(!ishuman(target_host))
		MOB_IS_ALIVE_ERROR(owner)
		return FALSE

/datum/action/cooldown/latexmob/proc/can_merge_target(mob/living/user, mob/living/carbon/target_host, pick_only_simplemob, can_absorb_alive)
	if(pick_only_simplemob && isanimal(target_host) && can_LL_absorb_alive(user, can_absorb_alive, target_host))
		return TRUE
	check_one_meter_distance_to_mob(target_host, user)
	if(istype(target_host, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = target_host
		check_space_suit(H, user)
		return TRUE
	else
		return FALSE

/datum/action/cooldown/latexmob/proc/handle_merging(mob/living/target)
	if(checkplayerssd(target))
		HANDLE_MERGING_TO_HOST_MESSAGE(target)
	target.Stun(4 SECONDS)
	target.drop_all_held_items()
	target.stuttering += rand(5, 10)
	return TRUE

/datum/action/cooldown/latexmob/proc/exit_from_host(turf/target_turf, datum/mind/ability_owner_mind, mob/living/carbon/human/host_body, delay, datum/antagonist/living_latex/LL)
	var/obj/effect/temp_visual/latexmob/effect = new /obj/effect/temp_visual/latexmob/venom_out(target_turf)
	effect.dir = host_body.dir
	var/mob/living/simple_animal/latexmob = new /mob/living/simple_animal/latexmob(target_turf)
	var/obj/item/organ/latexOrgan/OrganToRemove = get_latexOrgan_if_captured_by_LL(host_body)
	if(OrganToRemove)
		OrganToRemove.Remove()
	else
		stack_trace("exit_from_host: no latexOrgan in [host_body]")
	ability_owner_mind.transfer_to(latexmob)
	LL.grant_abilities(latexmob)

/datum/action/cooldown/latexmob/proc/enter_in_host(datum/antagonist/living_latex/my_living_latex, mob/living/carbon/owner, delay, mob/living/carbon/human/target_host, datum/action/cooldown/latexmob/latexmob_action_ref)
	var/obj/effect/temp_visual/latexmob/effect =  new /obj/effect/temp_visual/latexmob/venom_in (target_host.loc)
	effect.dir = target_host.dir
	if(do_after(owner, delay, owner))
		my_living_latex.merging(target_host) //выполняет слияние хоста с латексным и даёт ссылку на моба внутри хоста.
		return
