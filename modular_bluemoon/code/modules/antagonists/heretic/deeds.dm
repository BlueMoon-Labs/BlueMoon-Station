#define HERETIC_DEED_TOO_FAST "Слишком быстро: Мансус ещё не запомнил предыдущий след."

/datum/antagonist/heretic
	var/datum/heretic_deed/deed

/datum/heretic_path
	var/deed_type

/// Дело пути: тематическое занятие вне боя, которое даёт очки знаний и запас силы.
/datum/heretic_deed
	var/name = "Дело пути"
	var/desc = ""
	var/hint = ""
	var/next_step = ""
	var/trace_name = "Mansus trace"
	var/trace_desc = "Здесь произошло что-то, чему нет обычного объяснения."
	var/trace_state = "sigil_ash"
	var/tier = 0
	var/progress = 0
	var/list/tier_goals = list(2, 2, 2)
	var/list/counted_keys = list()
	var/combat_hint
	var/list/combat_tiers = list()
	var/datum/weakref/heretic_ref
	/// Что не делает ремесло пути в незачтённом месте, пока идёт пауза между зачётами.
	var/craft_wait
	var/craft_wait_place = "в ещё не зачтённом отделе"
	COOLDOWN_DECLARE(progress_cooldown)

/datum/heretic_deed/New()
	. = ..()
	if(craft_wait)
		desc += " Между зачётами Мансусу нужно [HERETIC_DEED_COOLDOWN / (1 SECONDS)] с: пока он запоминает прошлый след, [craft_wait_place] [craft_wait]."

/datum/heretic_deed/proc/goal()
	return tier < length(tier_goals) ? tier_goals[tier + 1] : 0

/datum/heretic_deed/proc/complete()
	return tier >= length(tier_goals)

/datum/heretic_deed/proc/get_data()
	return list(
		"name" = name,
		"desc" = desc,
		"hint" = hint,
		"next_step" = next_step,
		"tier" = tier,
		"max_tier" = length(tier_goals),
		"progress" = progress,
		"goal" = goal(),
		"counted" = length(counted_keys),
		"combat_hint" = combat_hint,
		"combat_available" = !complete() && !((tier + 1) in combat_tiers),
	)

/datum/antagonist/heretic/proc/create_deed()
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(deed || !path?.deed_type)
		return deed
	deed = new path.deed_type
	deed.heretic_ref = WEAKREF(src)
	to_chat(owner?.current, span_notice("Дело пути «[deed.name]»: [deed.desc] [deed.hint] Для первой награды нужно [deed.goal()] действия. Эту подсказку можно перечитать, осмотрев кодекс."))
	return deed

/datum/antagonist/heretic/proc/deed_key_for(atom/target)
	var/area/place = get_area(target)
	return place ? "[place.type]" : null

/// chained: второй шаг того же действия, пауза между зачётами его не держит.
/datum/antagonist/heretic/proc/deed_error(key, chained = FALSE)
	if(role_removed || !deed)
		return "Путь не выбран."
	if(deed.complete())
		return "Дело пути завершено."
	if(key && (key in deed.counted_keys))
		return "Мансус уже видел это место."
	if(!chained && !COOLDOWN_FINISHED(deed, progress_cooldown))
		return HERETIC_DEED_TOO_FAST
	return null

/// Отказ ремеслу, которое засчиталось бы в дело, если бы не пауза между зачётами.
/datum/antagonist/heretic/proc/deed_wait_reason(key)
	var/error_message = deed_error(key)
	if(error_message != HERETIC_DEED_TOO_FAST)
		return null
	return "[error_message] Через [heretic_capture_seconds_left(deed.progress_cooldown)] с здесь можно будет продолжить дело."

/datum/antagonist/heretic/proc/advance_deed(key, atom/trace_at, silent = FALSE, chained = FALSE)
	var/mob/living/user = owner?.current
	var/error_message = deed_error(key, chained)
	if(error_message)
		if(!silent && user && deed && !deed.complete())
			to_chat(user, span_warning(error_message))
		return FALSE
	COOLDOWN_START(deed, progress_cooldown, HERETIC_DEED_COOLDOWN)
	if(key)
		deed.counted_keys += key
	deed.progress++
	log_game("[key_name(owner)] продвигает дело [deed.name]: ступень [deed.tier + 1], [deed.progress]/[deed.goal()], [trace_at ? "объект [trace_at.type], место [AREACOORD(trace_at)]" : "место [AREACOORD(user)]"].")
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	var/datum/eldritch_knowledge/base_knowledge = get_knowledge(path.knowledge[1])
	base_knowledge?.on_deed_progress(user)
	var/turf/trace_turf = get_turf(trace_at)
	if(trace_turf)
		var/obj/effect/decal/cleanable/heretic_trace/trace = new(trace_turf)
		trace.apply_deed(deed, path)
	if(deed.progress < deed.goal())
		if(user)
			to_chat(user, span_notice("[deed.name]: [deed.progress] из [deed.goal()] на ступени [deed.tier + 1]."))
		refresh_book_ui()
		return TRUE
	deed.tier++
	deed.progress = 0
	knowledge_points += HERETIC_DEED_KNOWLEDGE
	var/reward_text = "[HERETIC_DEED_KNOWLEDGE] очко знаний"
	if(deed.tier >= HERETIC_DEED_SIDE_TIER)
		side_knowledge_points += HERETIC_DEED_SIDE_KNOWLEDGE
		reward_text += " и [HERETIC_DEED_SIDE_KNOWLEDGE] побочное"
	if(user)
		to_chat(user, span_eldritch("[deed.name]: ступень [deed.tier] из [length(deed.tier_goals)] завершена. Вы получили [reward_text]."))
		user.playsound_local(get_turf(user), 'sound/effects/magic.ogg', 30, TRUE)
	log_game("[key_name(owner)] завершает ступень [deed.tier] дела [deed.name] на пути [selected_path].")
	refresh_book_ui()
	return TRUE

/datum/antagonist/heretic/proc/deed_data()
	return deed?.get_data()

/datum/antagonist/heretic/proc/advance_combat_deed(mob/living/victim, path_id)
	var/mob/living/user = owner?.current
	if(role_removed || selected_path != path_id || !deed?.combat_hint || deed.complete() || QDELETED(user) || user.incapacitated() || QDELETED(victim) || victim.stat == DEAD || !victim.mind || victim.mind != hunt_target || !heretic_can_affect(user, victim, chargecost = 0))
		return FALSE
	var/challenge_tier = deed.tier + 1
	if(challenge_tier in deed.combat_tiers)
		return FALSE
	if(!advance_deed("hunt:[REF(victim.mind)]", victim, silent = TRUE))
		return FALSE
	deed.combat_tiers += challenge_tier
	to_chat(user, span_notice("Приём пути по цели охоты засчитан в дело. Повторный приём по этой же цели дело уже не продвинет."))
	refresh_book_ui()
	return TRUE

/datum/eldritch_knowledge/proc/on_deed_progress(mob/living/user)
	if(combat_resource_name)
		gain_combat_resource()

/datum/eldritch_knowledge/base_blood/on_deed_progress(mob/living/user)
	heretic_heal_damage(user, 5)

/datum/eldritch_knowledge/base_moon/on_deed_progress(mob/living/user)
	return

/datum/eldritch_knowledge/base_cosmic/on_deed_progress(mob/living/user)
	return

/obj/effect/decal/cleanable/heretic_trace
	name = "Mansus trace"
	desc = "Здесь произошло что-то, чему нет обычного объяснения."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_ash"
	alpha = 120
	mergeable_decal = FALSE
	layer = ABOVE_NORMAL_TURF_LAYER

/obj/effect/decal/cleanable/heretic_trace/proc/apply_deed(datum/heretic_deed/deed, datum/heretic_path/path)
	name = deed.trace_name
	desc = deed.trace_desc
	icon_state = deed.trace_state

/obj/effect/decal/cleanable/heretic_trace/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		. += span_eldritch("След вашего дела. Мансус запомнил это место.")
	else
		. += span_warning("Стоит сообщить об этом службе безопасности.")

/datum/heretic_deed/ash
	next_step = "Положите зажжённую зажигалку на пол в ещё не зачтённом отделе и коснитесь её Хваткой Мансуса."
	name = "Угли чужого огня"
	desc = "Гасите пламя Хваткой Мансуса: очаг пожара (коснитесь горящего пола), зажжённый сварочник, зажигалку, свечу или факел, лежащие на полу. Своя зажигалка, брошенная на пол, тоже подходит; огонь в руках даёт уголёк, но в дело не засчитывается. Каждый новый отдел засчитывается один раз."
	hint = "Кухня, инженерный, бар и мастерские полны открытого огня. Погашенное пламя оставляет выжженный отпечаток."
	trace_name = "scorched handprint"
	trace_desc = "На полу выгорел след ладони. Металл вокруг него холодный."
	trace_state = "sigil_ash"

/datum/heretic_deed/rust
	next_step = "Коснитесь Хваткой Мансуса металлического пола в ещё не зачтённом отделе."
	name = "Корни в чужом металле"
	desc = "Покрывайте ржавчиной новую поверхность Хваткой Мансуса в разных отделах станции. Каждый отдел засчитывается один раз."
	hint = "Ржавчина видна всем, поэтому выбирайте техтоннели и редко посещаемые углы."
	trace_name = "rust pattern"
	trace_desc = "Ржавчина расходится от центра ровными кольцами, как от удара."
	trace_state = "sigil_rust"

/datum/heretic_deed/flesh
	next_step = "Положите извлечённый орган ещё не зачтённого вида на пол и коснитесь его Хваткой Мансуса."
	name = "Жатва"
	desc = "Поглощайте Хваткой Мансуса извлечённые органы, лежащие на полу. Каждый вид органа засчитывается один раз."
	hint = "Хирургия, генетика и разделочный стол кухни дают органы без единого удара."
	trace_name = "crimson streak"
	trace_desc = "Кровь на полу стянулась в узор, похожий на сосуды."
	trace_state = "sigil_flesh"

/datum/heretic_deed/void
	next_step = "Коснитесь Хваткой Мансуса включённого светильника в ещё не зачтённом отделе."
	name = "Тишина в зале"
	desc = "Гасите Хваткой Мансуса работающие светильники в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Лампа мигает и перегорает, а на стекле остаётся иней. Ремонт вернёт свет, но след останется."
	trace_name = "frost on the floor"
	trace_desc = "Пол под лампой покрыт инеем, хотя воздух вокруг тёплый."
	trace_state = "sigil_void"

/datum/heretic_deed/blade
	next_step = "Способностью «Вызов» бросьте вызов человеку, которого ещё не вызывали. Он должен быть не дальше 5 клеток, и последние 10 секунд никто из вас не должен получать урон."
	name = "Вызовы"
	desc = "Бросайте вызов на дуэль членам экипажа способностью «Вызов». Каждый новый человек засчитывается один раз, а принятый вызов идёт в дело за два шага."
	craft_wait_place = "новому человеку"
	craft_wait = "вызов не бросить"
	hint = "Вызванный видит окно с вашим именем - это улика. Если он откажется или промолчит 20 секунд, стоя не дальше 5 клеток от вас, клинок собьёт его с ног на 3 секунды, а шаг дела всё равно засчитается; снова вызвать его можно через 5 минут. Принятый вызов уводит вас обоих в изнанку, где чужие не мешают, а на месте вызова остаётся разрыв."
	trace_name = "blade scratch"
	trace_desc = "На полу процарапана короткая черта, будто по нему чиркнули кончиком клинка."
	trace_state = "sigil_blade"

/datum/heretic_deed/moon
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса свободного пола и оставьте двойника там, где его увидит экипаж ещё не зачтённого отдела станции."
	name = "Алиби"
	desc = "Ставьте Хваткой Мансуса в намерении «Помощь» двойника на посту: отдел станции засчитывается, когда двойника увидит член экипажа. Каждый отдел засчитывается один раз, вне станции двойник в дело не идёт."
	hint = "Двойник один, новый заменяет старого. Он стоит до 10 минут, бродит в пределах двух клеток, при осмотре выглядит как вы и говорит за вас через «Голос двойника». Внимательный заметит, что он не моргает. Двойник рассеивается от 30 урона, нулевого жезла или вспышки рядом."
	trace_name = "silvery print"
	trace_desc = "На полу поблёскивает пятно, похожее на след отражения."
	trace_state = "sigil_moon"

/datum/heretic_deed/cosmic
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса пола в ещё не зачтённом отделе: там загорится путеводная звезда."
	name = "Небо над отделами"
	desc = "Зажигайте Хваткой Мансуса в намерении «Помощь» путеводные звёзды на полу разных отделов станции. Каждый отдел засчитывается один раз."
	craft_wait = "путеводная звезда не зажигается"
	hint = "Держатся четыре путеводные звезды, по одной на отдел; новая вытесняет самую старую. Экипаж может заметить холодную точку света без тени, а удар или нулевой жезл её гасят. К путеводным звёздам ведёт Звёздная дорога."
	trace_name = "stardust"
	trace_desc = "Пол припорошён мерцающей пылью, которая не собирается щёткой."
	trace_state = "sigil_cosmic"

/datum/heretic_deed/lock
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса шлюза в ещё не зачтённом отделе: он станет вашим порогом."
	name = "Чужие замки"
	desc = "Помечайте Хваткой Мансуса в намерении «Помощь» шлюзы в разных отделах станции, а с Открытой ладонью ещё и отпирайте ею шлюзы и шкафы. Каждый отдел засчитывается один раз."
	craft_wait = "шлюз не помечается"
	hint = "Держатся четыре порога, новый вытесняет самый старый. Экипаж может заметить, что замок помеченного шлюза щёлкает сам по себе, а нулевой жезл снимает пометку. Каждый зачёт оставляет царапины у замка."
	trace_name = "scratches by the lock"
	trace_desc = "Вокруг замка глубокие царапины, будто ключ искали вслепую."
	trace_state = "sigil_lock"

/datum/heretic_deed/tide
	next_step = "Откройте Хваткой Мансуса прорыв у раковины, душа или бака с водой в ещё не зачтённом отделе."
	name = "Прорывы"
	desc = "Открывайте Хваткой Мансуса прорывы у раковин, душей и баков с водой в разных отделах: вода из источника не уходит в слив и 5 минут стоит вокруг него. Каждый отдел засчитывается один раз."
	craft_wait = "прорыв не открывается"
	hint = "Держатся три прорыва, новый вытесняет самый старый. Экипаж может заметить, что вода не уходит в слив и темнее обычной; гаечный ключ или нулевой жезл по источнику закрывают прорыв."
	trace_name = "puddle of salt water"
	trace_desc = "Вода на полу пахнет морем. Солёные разводы по краям."
	trace_state = "sigil_tide"

/datum/heretic_deed/glass
	next_step = "Настройте Хваткой Мансуса окно или зеркало в ещё не зачтённом отделе."
	name = "Глазки"
	desc = "Настраивайте Хваткой Мансуса окна и зеркала в разных отделах: стекло остаётся целым и становится вашим глазком. Каждый отдел засчитывается один раз."
	craft_wait = "стекло не настраивается"
	hint = "Держится шесть глазков, новый вытесняет самый старый. Экипаж может заметить, что в стекле отражается чужая комната, а нулевой жезл снимает настройку. Зеркала подходят так же, как окна."
	trace_name = "stray reflection"
	trace_desc = "На полу лежит чужой блик: свет падает не оттуда, где стоит окно."
	trace_state = "sigil_glass"

/datum/heretic_deed/blood
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса свежей крови человека, чью кровь вы ещё не читали: пятна на полу, окровавленного предмета, шприца или пакета."
	name = "Чужие подписи"
	desc = "Читайте Хваткой Мансуса в намерении «Помощь» свежую чужую кровь: пятно на полу, окровавленный предмет, шприц или пакет с кровью. Каждый человек засчитывается один раз, а зачёт лечит вам 5 ушибов. Долг накапливается только на связанных противниках."
	craft_wait_place = "кровь нового человека"
	craft_wait = "не прочитать"
	hint = "Лазарет, арена и коридоры после драк полны чужих подписей. Прочитанная кровь на 3 минуты даёт след к её владельцу, а пятно на полу становится вашей меткой. Одновременно держатся три метки. Экипаж может заметить, что кровь не засыхает; уборка или нулевой жезл снимают метку."
	trace_name = "signature in blood"
	trace_desc = "Кровь на полу стянулась в ровную линию, похожую на подпись."
	trace_state = "sigil_blood"

/datum/heretic_deed/echo
	next_step = "Поставьте Хваткой Мансуса прослушку на интерком в ещё не зачтённом отделе."
	name = "Подслушка"
	desc = "Ставьте Хваткой Мансуса прослушку на интеркомы в разных отделах: интерком передаёт вам обычную речь рядом с собой с названием отдела. Каждый отдел засчитывается один раз."
	craft_wait = "прослушка не ставится"
	hint = "Держатся четыре прослушки, новая вытесняет самую старую. Экипаж может заметить, что динамик повторяет слова с задержкой; отвёртка или нулевой жезл снимают прослушку."
	trace_name = "lingering echo"
	trace_desc = "Здесь до сих пор слышен едва различимый повтор чужих слов, хотя динамик молчит."
	trace_state = "sigil_echo"

/datum/heretic_deed/ash
	combat_hint = "Поразите назначенную цель огненным следом Угасания."

/datum/heretic_deed/rust
	combat_hint = "Поразите назначенную цель ржавым клинком, стоя на ржавом полу."

/datum/heretic_deed/flesh
	combat_hint = "Прикажите ползуну атаковать назначенную цель и добейтесь его попадания."

/datum/heretic_deed/void
	combat_hint = "Задержите назначенную цель в Зимнем пределе, пока её не скуёт холод."

/datum/heretic_deed/blade
	combat_hint = "Отразите атаку назначенной цели парированием."

/datum/heretic_deed/moon
	combat_hint = "Направьте отражение на назначенную цель и добейтесь его попадания."

/datum/heretic_deed/cosmic
	combat_hint = "Поразите назначенную цель звёздной нитью."

/datum/heretic_deed/lock
	combat_hint = "Разомкните свою печать рядом с назначенной целью и попадите взрывом."

/datum/heretic_deed/glass
	combat_hint = "Поразите назначенную цель лучом, прошедшим через призму."

/datum/heretic_deed/blood
	combat_hint = "Взыщите долг с назначенной цели и нанесите ей урон."

/datum/heretic_deed/echo
	combat_hint = "Поразите назначенную цель отложенной звуковой волной."

/datum/heretic_deed/sand
	combat_hint = "Взорвите свои часы так, чтобы они поразили назначенную цель."

/datum/heretic_deed/wax
	combat_hint = "Поразите назначенную цель через её воскового двойника."

/datum/heretic_deed/spirit
	combat_hint = "Сместите душу назначенной цели и заставьте связь истощить её."

/datum/heretic_deed/tide
	combat_hint = "Поразите назначенную цель Сбросом давления."

#undef HERETIC_DEED_TOO_FAST
