/// Силы генокрада, которые зовут призраков или действуют на станцию: тип -> причина отказа.
GLOBAL_LIST_INIT(antag_training_blocked_changeling_powers, list(
	/datum/action/changeling/spiders = "из кладки вырастают пауки, которых заселяют призраки",
))

/datum/antag_training_program/antag/changeling
	name = "Генокрад"
	category = "Предатели экипажа"
	desc = "Эмпориум способностей с полными химикатами и геномом, поглощение учебных целей удушающим захватом и смена облика, улей и банк ДНК только для генокрадов полигона. Упражнение «Поглощение и облик» в лаборатории ведёт от захвата до облика жертвы по шагам."
	icon = "dna"
	color = "purple"
	learn = "Эмпориум способностей|Химикаты и очки генома|Поглощение удушающим захватом|Облик жертвы через Transform|Улей и банк ДНК"
	difficulty = 2
	order = 4
	antag_type = /datum/antagonist/changeling/training
	options = list("Пополнить химикаты и геном", "Сбросить способности", "Цель для поглощения")

/datum/antag_training_program/antag/changeling/New()
	. = ..()
	var/datum/antagonist/changeling/training/sample = antag_type
	option_hints = list(
		"Пополнить химикаты и геном" = "Химикаты - до [initial(sample.chem_storage)], очки генома - до [initial(sample.maxgeneticpoints)], купленные способности остаются. В раунде химикаты копятся сами, а потраченные очки генома возвращает только «Readapt» в эмпориуме.",
		"Сбросить способности" = "Снимает купленные способности и возвращает очки генома, как «Readapt» в эмпориуме; переадаптация, заработанная поглощением, сохраняется. В раунде «Readapt» открывается только после поглощения.",
		"Цель для поглощения" = "Рядом встанет учебная цель. Возьмите её в захват, усильте его до удушающего и нажмите «Absorb DNA»: три этапа, всё это время держите захват. Цель умрёт, её облик и ДНК станут вашими, а поглощения откроют способности эмпориума; облик примите кнопкой «Transform». Манекен не становится зомби-генокрадом. С шагами и оценкой это упражнение «Поглощение и облик» в лаборатории.",
	)

/datum/antag_training_program/antag/changeling/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/changeling/training/changeling = role(session)
	if(!changeling)
		to_chat(user, span_warning("Роль генокрада снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Пополнить химикаты и геном")
			changeling.refill()
		if("Сбросить способности")
			changeling.training_readapt()
		if("Цель для поглощения")
			absorb_target(session, user)
	return TRUE

/datum/antag_training_program/antag/changeling/proc/absorb_target(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user, "Цель не встала: достигнут предел целей или идёт сброс. Удалите лишние цели в разделе «Цели».")
	if(dummy)
		to_chat(user, span_notice("[dummy.real_name] стоит в зоне «[dummy_zone_name(session, dummy)]». Возьмите цель в захват, усильте его до удушающего и нажмите «Absorb DNA»."))
	return dummy

/datum/antag_training_arena
	/// Банк ДНК улья генокрадов этой арены вместо GLOB.hivemind_bank раунда.
	var/list/changeling_hive_bank = list()

/datum/antagonist/changeling/training
	name = "Учебный генокрад"
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
	give_objectives = FALSE
	var/datum/antag_training_session/training
	var/static/trainee_count = 0

/datum/antagonist/changeling/training/generate_name()
	changelingID = "Учебный генокрад [++trainee_count]"

/datum/antagonist/changeling/training/on_gain()
	. = ..()
	chem_charges = chem_storage

/datum/antagonist/changeling/training/threat()
	return 0

/datum/antagonist/changeling/training/power_refusal(datum/action/changeling/ability)
	var/power_type = ispath(ability) ? ability : ability.type
	for(var/blocked_type in GLOB.antag_training_blocked_changeling_powers)
		if(ispath(power_type, blocked_type))
			return "На полигоне недоступно: [initial(ability.name)] - [GLOB.antag_training_blocked_changeling_powers[blocked_type]]. Очки генома не списаны."
	return null

/datum/antagonist/changeling/training/hive_bank()
	return training?.arena?.changeling_hive_bank || list()

/datum/antagonist/changeling/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/changeling/training/proc/brief()
	to_chat(owner.current, briefing())
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ling_aler.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/antagonist/changeling/training/proc/briefing()
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/changeling_absorb
	return jointext(list(
		span_boldnotice("Тренировка генокрада. Вы - [changelingID]."),
		span_notice("Кнопка «Cellular Emporium» открывает эмпориум: способности покупаются за очки генома, часть требует поглощённых ДНК. Химикаты и геном на старте полные. Spread Infestation на полигоне не продаётся: её пауков заселяют призраки."),
		span_notice("Поглощение: удушающий захват учебной цели и «Absorb DNA». Цель умирает, её облик и ДНК становятся вашими, а «Transform» надевает облик любой поглощённой жертвы. Манекены не превращаются в зомби-генокрадов."),
		span_notice("Упражнение «[initial(exercise.name)]» в лаборатории проводит через захват, поглощение и смену облика с подсказками и оценкой: пульт, вкладка «Упражнения»."),
		span_notice("После покупки Hivemind Communication говорите «[MODE_TOKEN_CHANGELING] сообщение»: улей и его банк ДНК связывают только генокрадов этого полигона. Генокрады смены вас не слышат и не чуют, вы их тоже."),
		span_notice("«Пульт полигона», раздел «Моя роль»: пополнить химикаты и геном, сбросить способности, цель для поглощения."),
	), "<br>")

/datum/antagonist/changeling/training/proc/refill()
	chem_charges = chem_storage
	geneticpoints = maxgeneticpoints
	SStgui.update_uis(cellular_emporium)
	to_chat(owner.current, span_notice("Химикаты: [chem_charges] из [chem_storage], очки генома: [geneticpoints] из [maxgeneticpoints]."))

/datum/antagonist/changeling/training/proc/training_readapt()
	var/earned = can_respec
	can_respec = TRUE
	. = readapt()
	can_respec = earned

/datum/antagonist/changeling/training/Destroy()
	training = null
	return ..()

/datum/antag_training_exercise/drill/changeling_absorb
	id = "changeling_absorb"
	name = "Поглощение и облик"
	desc = "Учебная цель встаёт рядом с вами в лаборатории. Возьмите её удушающим захватом, поглотите способностью «Absorb DNA» и примите её облик через «Transform»."
	sector = "laboratory"
	program = /datum/antag_training_program/antag/changeling
	difficulty = 2
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/checked/changeling/grab, /datum/antag_training_exercise_step/drill/checked/changeling/absorb, /datum/antag_training_exercise_step/drill/checked/changeling/transform)

/datum/antag_training_exercise/drill/changeling_absorb/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	prepare_target(session, "human", get_turf(session.current_body))
	return TRUE

/// Захват и облик сигналов не шлют: шаг проверяет их сам раз в секунду.
/datum/antag_training_exercise_step/drill/checked/changeling
	target_death = "цель умерла раньше поглощения"

/datum/antag_training_exercise_step/drill/checked/changeling/proc/changeling_role()
	var/datum/antag_training_program/antag/changeling/program = run?.session?.program
	return istype(program) ? program.role(run.session) : null

/datum/antag_training_exercise_step/drill/checked/changeling/grab
	name = "Возьмите цель удушающим захватом"
	hint = "Встаньте рядом с целью и щёлкните по ней с зажатым Ctrl, чтобы тащить. Включите намерение захвата (grab) и щёлкайте по цели пустой рукой: захват станет агрессивным, потом за шею, потом удушающим. Каждое усиление идёт несколько секунд, не отходите."

/datum/antag_training_exercise_step/drill/checked/changeling/grab/check()
	var/mob/living/carbon/human/body = participant()
	var/mob/living/target = exercise_target()
	return body && target && target.stat != DEAD && body.pulling == target && body.grab_state >= GRAB_KILL

/datum/antag_training_exercise_step/drill/checked/changeling/absorb
	name = "Поглотите цель способностью «Absorb DNA»"
	hint = "Не отпуская удушающий захват, нажмите «Absorb DNA» на панели способностей. Поглощение идёт в три этапа: всё это время стойте на месте и держите цель. Сорвался захват - усильте его снова и нажмите кнопку ещё раз."
	polling = FALSE
	var/true_absorbs_before

/datum/antag_training_exercise_step/drill/checked/changeling/absorb/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/datum/antagonist/changeling/changeling = changeling_role()
	if(isnull(true_absorbs_before) && changeling)
		true_absorbs_before = changeling.trueabsorbs

/// Поглощение убивает цель уже после записи её профиля: смерть с новым профилем и ростом настоящих поглощений и есть успех.
/datum/antag_training_exercise_step/drill/checked/changeling/absorb/on_target_death()
	var/datum/antagonist/changeling/changeling = changeling_role()
	var/mob/living/target = exercise_target()
	if(changeling && target && changeling.trueabsorbs > true_absorbs_before && changeling.get_dna(target.real_name))
		complete()
		return
	return ..()

/datum/antag_training_exercise_step/drill/checked/changeling/transform
	name = "Примите облик жертвы через «Transform»"
	hint = "Нажмите «Transform» на панели способностей и выберите в круговом меню облик поглощённой цели. Не хватает химикатов - «Пополнить химикаты и геном» в «Моей роли»."
	target_death = null

/datum/antag_training_exercise_step/drill/checked/changeling/transform/New()
	. = ..()
	var/datum/action/changeling/transform/power = /datum/action/changeling/transform
	hint = "Нажмите «Transform» на панели способностей и выберите в круговом меню облик поглощённой цели. Превращение стоит [initial(power.chemical_cost)] химикатов; не хватает - «Пополнить химикаты и геном» в «Моей роли»."

/datum/antag_training_exercise_step/drill/checked/changeling/transform/check()
	var/mob/living/carbon/human/body = participant()
	var/mob/living/target = exercise_target()
	var/datum/antagonist/changeling/changeling = changeling_role()
	var/datum/changelingprofile/profile = target && changeling?.get_dna(target.real_name)
	return istype(body) && profile && body.real_name == profile.name && body.dna.unique_enzymes == profile.dna.unique_enzymes
