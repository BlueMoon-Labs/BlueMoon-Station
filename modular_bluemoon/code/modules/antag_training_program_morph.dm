/datum/antag_training_program/creature/morph
	name = "Морф"
	category = "Существа"
	desc = "Тело морфа: копия облика предметов и существ, засады, поедание предметов и трупов, восстановление новым морфом после смерти."
	icon = "shapes"
	color = "violet"
	learn = "Копия облика предметов и существ|Засады|Поедание предметов и трупов|Возвращение новым морфом"
	difficulty = 1
	mob_type = /mob/living/simple_animal/hostile/morph
	antag_type = /datum/antagonist/morph/training
	options = list("Полное здоровье и маскировка", "Предметы для копии", "Цель для засады")
	var/static/list/form_types = list(
		/obj/item/storage/toolbox/mechanical,
		/obj/item/extinguisher,
		/obj/item/crowbar/red,
		/obj/item/clipboard,
		/obj/item/reagent_containers/food/drinks/soda_cans/cola,
	)

/datum/antag_training_program/creature/morph/New()
	. = ..()
	option_hints = list(
		"Полное здоровье и маскировка" = "Здоровье до максимума, который растёт от съеденного, и сброс задержки облика: новый можно принять сразу. В раунде морф лечится только поеданием трупов, а облик меняет не чаще раза в [MORPH_COOLDOWN / (1 SECONDS)] с.",
		"Предметы для копии" = "Обычные станционные предметы ([length(form_types)] шт.) лягут вокруг вас: Shift+клик по любому - копия его облика. Копировать можно и мебель, машины, существ - всё, кроме эффектов и других морфов.",
		"Цель для засады" = "Рядом встанет бегущий манекен и будет ходить поперёк площадки: примите облик предмета на его пути и нападите, когда он подойдёт. Съесть можно только мёртвого, и съеденный остаётся в общем лимите целей полигона. В безопасном центре и переходах кнопка не работает: встаньте на одну из площадок.",
	)

/// Учебный морф не глотает других участников полигона и их вещи.
/mob/living/simple_animal/hostile/morph/proc/training_eat_refused(atom/movable/food)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena || !food)
		return FALSE
	var/refusal = arena.foreign_part_refusal(food, arena.session_of(src), src)
	if(!refusal)
		return FALSE
	to_chat(src, span_warning(refusal))
	return TRUE

/datum/antag_training_program/creature/morph/refill(mob/living/simple_animal/hostile/morph/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	body.morph_time = 0

/datum/antag_training_program/creature/morph/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/hostile/morph/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле морфа. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Полное здоровье и маскировка")
			refill(body)
			to_chat(body, span_notice("Здоровье восполнено, облик можно сменить сразу."))
		if("Предметы для копии")
			return issue_forms(session, body)
		if("Цель для засады")
			return spawn_prey(session, body)
	return TRUE

/datum/antag_training_program/creature/morph/proc/issue_forms(datum/antag_training_session/session, mob/living/simple_animal/hostile/morph/body)
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/list/spots = list()
	for(var/turf/open/spot in orange(1, body))
		if(session.arena.owns_area(get_area(spot)) && !spot.is_blocked_turf())
			spots += spot
	if(!length(spots))
		spots += get_turf(body)
	var/issued = 0
	for(var/form_type in form_types)
		if(session.arena.issue_item(form_type, spots[(issued % length(spots)) + 1], 1, session))
			issued++
	if(!issued)
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	to_chat(body, span_notice("Вокруг вас предметы для копии ([issued] шт.): Shift+клик по любому принимает его облик."))
	return TRUE

/datum/antag_training_program/creature/morph/proc/spawn_prey(datum/antag_training_session/session, mob/living/simple_animal/hostile/morph/body)
	var/mob/living/carbon/human/prey = spawn_prey_near(session, body, "runner", "Цель для засады встаёт рядом с вами, а в центре и переходах её нет: встаньте на одну из площадок.")
	if(!prey)
		return FALSE
	to_chat(body, span_notice("[prey.real_name] ходит поперёк площадки. Примите облик предмета на его пути и ждите."))
	return TRUE

/datum/antagonist/morph/training
	name = "Учебный морф"
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
	ui_name = null
	var/datum/antag_training_session/training

/datum/antagonist/morph/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/morph/training/threat()
	return 0

/datum/antagonist/morph/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/morph/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/morph/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка морфа."),
		span_notice("Shift+клик по предмету или существу рядом - принять его облик, Shift+клик по себе - вернуть свой. Облик меняется не чаще раза в [MORPH_COOLDOWN / (1 SECONDS)] с. В облике вы быстрее, но не бьёте и не едите, а осмотр вблизи выдаёт неладное."),
		span_notice("Атака по предмету или трупу съедает его: труп лечит и прибавляет здоровья и силы. Съеденные предметы выплёвывает кнопка «Сплюнуть предмет», а после смерти выпадает всё съеденное. Других участников полигона и их вещи морф не глотает."),
		span_notice("«Пульт полигона», раздел «Моя роль»: полное здоровье со сбросом задержки облика, предметы для копии рядом и бегущая цель для засады. Труп для еды - «Тело для ритуала» в разделе «Цели». После смерти вы появитесь новым морфом в вестибюле хаба."),
	), "<br>")

/datum/antagonist/morph/training/Destroy()
	training = null
	return ..()
