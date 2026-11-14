GLOBAL_LIST_INIT(blood_oath_types, list(
	/datum/blood_oath/heist,
	/datum/blood_oath/vendetta,
	/datum/blood_oath/liberation,
	/datum/blood_oath/blood_debt,
	/datum/blood_oath/exposure,
	/datum/blood_oath/initiation,
	/datum/blood_oath/compromat,
	/datum/blood_oath/brother_sign,
	/datum/blood_oath/discord,
	/datum/blood_oath/hijack,
))

/datum/blood_oath
	var/name
	var/key
	var/weight = 10
	/// null - все режимы; иначе список ROUNDTYPE_*
	var/list/round_types
	var/requires_violence = FALSE
	/// Что делать, одной строкой: для списка клятв и админ-панели
	var/summary
	var/story
	var/list/datum/blood_oath_step/steps = list()
	/// Действие-венец или пассивка /datum/blood_bond_passive
	var/capstone_type
	/// Действия связи, которые клятва даёт с первой минуты
	var/list/extra_actions
	/// Станционные вещи, которые каждый живой брат получает при клятве
	var/list/kit_items
	var/vow_type
	/// Обет предложения; при клятве переходит к команде
	var/datum/blood_vow/vow
	var/datum/team/brother_team/team
	var/datum/mind/target_mind
	/// Уровень согласия, с которым подобрана target_mind
	var/target_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	/// Все имена цели с момента подбора: ID-карта на старое имя тоже в счёт
	var/list/target_names = list()
	/// world.time, с которого у тела цели нет игрока
	var/target_away_since
	/// Братьям уже сказали, что замены ушедшей цели нет
	var/target_lost = FALSE
	/// world.time следующего поиска замены, пока её нет
	var/next_target_search_at = 0

/datum/blood_oath/Destroy()
	QDEL_LIST(steps)
	QDEL_NULL(vow)
	target_mind = null
	target_names.Cut()
	team = null
	return ..()

/datum/blood_oath/proc/available(datum/team/brother_team/for_team)
	if(round_types && !(GLOB.round_type in round_types))
		return FALSE
	if(requires_violence && !brother_team_violence_allowed(for_team))
		return FALSE
	return TRUE

/datum/blood_oath/proc/kit_text()
	var/list/labels = list()
	for(var/item_type in kit_items)
		labels |= GLOB.brother_kit_labels[item_type]
	return labels.Join(", ")

/// Подбор целей и шагов заново; подтипы зовут родителя первым
/datum/blood_oath/proc/prepare(datum/team/brother_team/for_team)
	team = for_team
	target_mind = null
	target_names.Cut()
	target_away_since = null
	target_lost = FALSE
	QDEL_LIST(steps)
	return TRUE

/// Новая цель-человек по правилам клятвы или null
/datum/blood_oath/proc/find_target(datum/team/brother_team/for_team)
	return null

/// Требования клятвы к цели сверх общих
/datum/blood_oath/proc/target_allowed(datum/mind/candidate)
	return TRUE

/datum/blood_oath/proc/set_target(datum/mind/new_target)
	target_mind = new_target
	target_names = list(new_target.name)
	target_away_since = null
	target_lost = FALSE
	return TRUE

/datum/blood_oath/proc/target_known_name(checked_name)
	return checked_name && (checked_name == target_mind?.name || (checked_name in target_names))

/// История клятвы от текущей цели
/datum/blood_oath/proc/update_story()
	return

/// Клятва дана этой цели: при клятве и при смене цели
/datum/blood_oath/proc/target_sworn()
	return

/datum/blood_oath/proc/redescribe()
	update_story()
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		oath_step.describe()

/datum/blood_oath/proc/sealed_count()
	. = 0
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		if(oath_step.sealed)
			.++

/// Цель ушла из раунда, стала антагонистом или больше не подходит: подобрать другую. TRUE, если шаги сменились
/datum/blood_oath/proc/check_target()
	var/datum/blood_oath_step/current = current_step()
	if(!target_mind || team?.oath != src || team.training || !current || current.keeps_target())
		return FALSE
	var/reason = target_gone_reason()
	if(reason)
		if(target_lost && world.time < next_target_search_at)
			return FALSE
		return replace_target(reason)
	target_lost = FALSE
	if(!(target_mind.name in target_names))
		target_names += target_mind.name
		redescribe()
		team.refresh_brother_uis(static_data = TRUE)
	return FALSE

/// Причина для лога или null; труп - не уход
/datum/blood_oath/proc/target_gone_reason()
	var/mob/living/body = target_mind.current
	if(QDELETED(body) || !body.loc)
		return "left the round"
	if(brother_mind_is_antagonist(target_mind))
		return "became an antagonist"
	if(!target_allowed(target_mind))
		return "no longer fits the oath"
	var/mob/redirect = body.audiovisual_redirect
	if(body.stat == DEAD || body.key || GET_CLIENT(body) || (redirect && GET_CLIENT(redirect)))
		target_away_since = null
		return null
	if(isnull(target_away_since))
		target_away_since = world.time
		return null
	return world.time - target_away_since >= BROTHER_GHOST_GRACE ? "left the body" : null

/datum/blood_oath/proc/replace_target(reason)
	var/datum/mind/lost = target_mind
	var/datum/blood_oath/replaced = sealed_count() ? retarget() : remake()
	if(!replaced)
		next_target_search_at = world.time + BROTHER_TARGET_RETRY_INTERVAL
		if(!target_lost)
			target_lost = TRUE
			team.notify("Нить к [lost.name] оборвалась, а другой цели клятва пока не нашла.")
			log_game("Blood brothers [team.name]: oath [key] target [key_name(lost)] [reason], no replacement yet.")
		return FALSE
	var/datum/team/brother_team/oath_team = team
	oath_team.notify("Нить к [lost.name] оборвалась. Клятва нашла новую цель: [replaced.target_mind.name].")
	log_game("Blood brothers [oath_team.name]: oath [key] target [key_name(lost)] [reason], new target [key_name(replaced.target_mind)].")
	if(replaced != src)
		qdel(src)
	oath_team.refresh_brother_uis(static_data = TRUE)
	return TRUE

/// Без печатей клятва подбирается заново целиком; обет команды остаётся
/datum/blood_oath/proc/remake()
	var/datum/blood_oath/fresh = new type
	fresh.vow_type = vow_type
	if(!fresh.prepare(team))
		qdel(fresh)
		return null
	team.oath = fresh
	fresh.on_sworn()
	return fresh

/// Скреплённые шаги остаются, нескреплённые собираются на новую цель того же согласия
/datum/blood_oath/proc/retarget()
	var/datum/mind/found = find_target(team)
	if(!found || !set_target(found))
		return null
	for(var/step_index in 1 to length(steps))
		var/datum/blood_oath_step/old_step = steps[step_index]
		if(old_step.sealed)
			continue
		var/datum/blood_oath_step/new_step = new old_step.type
		new_step.oath = src
		steps[step_index] = new_step
		new_step.describe()
		new_step.on_sworn()
		qdel(old_step)
	update_story()
	target_sworn()
	return src

/datum/blood_oath/proc/add_step(datum/blood_oath_step/new_step)
	new_step.oath = src
	steps += new_step
	new_step.describe()
	return new_step

/datum/blood_oath/proc/get_weight(datum/team/brother_team/for_team)
	return weight

/// Цель-человек всё ещё годится: зовётся при подписи
/datum/blood_oath/proc/revalidate()
	if(!target_mind)
		return TRUE
	return brother_target_valid(team, target_mind, target_opt_in_level, require_station = FALSE) && target_allowed(target_mind)

/datum/blood_oath/proc/on_sworn()
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		oath_step.on_sworn()
	if(target_mind)
		target_sworn()

/datum/blood_oath/proc/on_team_tick()
	if(check_target())
		return
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		if(!oath_step.sealed)
			oath_step.on_team_tick()

/datum/blood_oath/proc/current_step()
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		if(!oath_step.sealed)
			return oath_step
	return null

/datum/blood_oath/proc/finale_extra_complete()
	return TRUE

/datum/blood_oath/proc/finale_extra_text()
	return null

/datum/blood_oath/proc/is_target(datum/mind/checked)
	return checked && checked == target_mind

/datum/blood_oath/proc/allows_blood_for_blood(mob/living/target)
	return FALSE

/datum/blood_oath/proc/capstone_payload()
	return capstone_type ? blood_bond_ability_data(capstone_type) : null

/datum/blood_oath_step
	var/name
	var/desc
	var/sealed = FALSE
	var/sealed_by
	var/datum/blood_oath/oath

/datum/blood_oath_step/Destroy()
	oath = null
	return ..()

/// TRUE или строка-причина; без побочных эффектов, окно зовёт каждую секунду
/datum/blood_oath_step/proc/can_seal(mob/living/sealer)
	return "условие не задано"

/// sealable - уже посчитанный can_seal(viewer) или null
/datum/blood_oath_step/proc/condition_text(mob/living/viewer, sealable)
	return null

/datum/blood_oath_step/proc/sealable_now(mob/living/viewer, sealable)
	return (isnull(sealable) ? can_seal(viewer) : sealable) == TRUE

/// Шаг держит цель, даже если её тело пропало
/datum/blood_oath_step/proc/keeps_target()
	return FALSE

/// Тексты шага, когда цели клятвы уже подобраны
/datum/blood_oath_step/proc/describe()
	return

/datum/blood_oath_step/proc/on_sworn()
	return

/datum/blood_oath_step/proc/on_team_tick()
	return

/datum/blood_oath_step/proc/on_sealed(datum/mind/sealer)
	return

/datum/blood_bond_passive/circle
	name = "Круг троих"
	desc = "Пока все трое братьев не дальше 3 клеток друг от друга и никого из вас не ранили последние 10 секунд, каждый лечит по 2 единицы ушибов и ожогов раз в 2 секунды. Если кто-то из троих при смерти, круг не лечит."
	bond_how = "Работает само: держитесь втроём рядом."
