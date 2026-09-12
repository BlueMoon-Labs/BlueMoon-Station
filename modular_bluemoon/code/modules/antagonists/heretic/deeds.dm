#define HERETIC_DEED_COOLDOWN (5 SECONDS)

/datum/antagonist/heretic
	var/datum/heretic_deed/deed

/datum/heretic_path
	var/deed_type

/// Дело пути: тематическое занятие вне боя, которое даёт очки знаний и запас силы.
/datum/heretic_deed
	var/name = "Дело пути"
	var/desc = ""
	var/hint = ""
	var/trace_name = "след Мансуса"
	var/trace_desc = "Здесь произошло что-то, чему нет обычного объяснения."
	var/trace_state = "sigil_ash"
	var/tier = 0
	var/progress = 0
	var/list/tier_goals = list(2, 3, 4)
	var/list/counted_keys = list()
	var/datum/weakref/heretic_ref
	COOLDOWN_DECLARE(progress_cooldown)

/datum/heretic_deed/proc/goal()
	return tier < length(tier_goals) ? tier_goals[tier + 1] : 0

/datum/heretic_deed/proc/complete()
	return tier >= length(tier_goals)

/datum/heretic_deed/proc/get_data()
	return list(
		"name" = name,
		"desc" = desc,
		"hint" = hint,
		"tier" = tier,
		"max_tier" = length(tier_goals),
		"progress" = progress,
		"goal" = goal(),
		"counted" = length(counted_keys),
	)

/datum/antagonist/heretic/proc/create_deed()
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(deed || !path?.deed_type)
		return deed
	deed = new path.deed_type
	deed.heretic_ref = WEAKREF(src)
	return deed

/datum/antagonist/heretic/proc/deed_key_for(atom/target)
	var/area/place = get_area(target)
	return place ? "[place.type]" : null

/datum/antagonist/heretic/proc/deed_error(key)
	if(role_removed || !deed)
		return "Путь не выбран."
	if(deed.complete())
		return "Дело пути завершено."
	if(key && (key in deed.counted_keys))
		return "Мансус уже видел это место."
	if(!COOLDOWN_FINISHED(deed, progress_cooldown))
		return "Слишком быстро: Мансус ещё не запомнил предыдущий след."
	return null

/datum/antagonist/heretic/proc/advance_deed(key, atom/trace_at, silent = FALSE)
	var/mob/living/user = owner?.current
	var/error_message = deed_error(key)
	if(error_message)
		if(!silent && user && deed && !deed.complete())
			to_chat(user, span_warning(error_message))
		return FALSE
	COOLDOWN_START(deed, progress_cooldown, HERETIC_DEED_COOLDOWN)
	if(key)
		deed.counted_keys += key
	deed.progress++
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

/datum/eldritch_knowledge/proc/on_deed_progress(mob/living/user)
	if(combat_resource_name)
		gain_combat_resource()

/datum/eldritch_knowledge/base_blood/on_deed_progress(mob/living/user)
	user?.adjustBruteLoss(-5)

/datum/eldritch_knowledge/base_moon/on_deed_progress(mob/living/user)
	return

/datum/eldritch_knowledge/base_cosmic/on_deed_progress(mob/living/user)
	return

/obj/effect/decal/cleanable/heretic_trace
	name = "след Мансуса"
	desc = "Здесь произошло что-то, чему нет обычного объяснения."
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
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
	name = "Угли чужого огня"
	desc = "Гасите чужое пламя Хваткой Мансуса: очаг пожара, зажжённый сварочник, зажигалку, свечу или факел, лежащие на полу. Каждый новый отдел засчитывается один раз."
	hint = "Кухня, инженерный, бар и мастерские полны открытого огня. Погашенное пламя оставляет выжженный отпечаток."
	trace_name = "выжженный отпечаток ладони"
	trace_desc = "На полу выгорел след ладони. Металл вокруг него холодный."
	trace_state = "sigil_ash"

/datum/heretic_deed/rust
	name = "Корни в чужом металле"
	desc = "Покрывайте ржавчиной новую поверхность Хваткой Мансуса в разных отделах станции. Каждый отдел засчитывается один раз."
	hint = "Ржавчина видна всем, поэтому выбирайте техтоннели и редко посещаемые углы."
	trace_name = "ржавый узор"
	trace_desc = "Ржавчина расходится от центра ровными кольцами, как от удара."
	trace_state = "sigil_rust"

/datum/heretic_deed/flesh
	name = "Жатва"
	desc = "Поглощайте Хваткой Мансуса извлечённые органы, лежащие на полу. Каждый вид органа засчитывается один раз."
	hint = "Хирургия, генетика и разделочный стол кухни дают органы без единого удара."
	trace_name = "багровый потёк"
	trace_desc = "Кровь на полу стянулась в узор, похожий на сосуды."
	trace_state = "sigil_flesh"

/datum/heretic_deed/void
	name = "Тишина в зале"
	desc = "Гасите Хваткой Мансуса работающие светильники в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Лампа мигает и перегорает, а на стекле остаётся иней. Ремонт вернёт свет, но след останется."
	trace_name = "иней на полу"
	trace_desc = "Пол под лампой покрыт инеем, хотя воздух вокруг тёплый."
	trace_state = "sigil_void"

/datum/heretic_deed/blade
	name = "Клятва стали"
	desc = "Поглощайте Хваткой Мансуса лежащие на полу острые предметы. Каждый вид предмета засчитывается один раз."
	hint = "Кухонные ножи, скальпели, осколки стекла и топоры годятся. Клинки еретиков не принимаются."
	trace_name = "стальная стружка"
	trace_desc = "На полу рассыпана тонкая стальная стружка, будто предмет источили за секунду."
	trace_state = "sigil_blade"

/datum/heretic_deed/moon
	name = "Свидетели"
	desc = "Пусть члены экипажа видят ваши отражения хотя бы несколько секунд. Каждый свидетель засчитывается один раз."
	hint = "Отражение в коридоре или на глазах у одной жертвы работает одинаково: важно, чтобы его заметили."
	trace_name = "серебристый отпечаток"
	trace_desc = "На полу поблёскивает пятно, похожее на след отражения."
	trace_state = "sigil_moon"

/datum/heretic_deed/cosmic
	name = "Небо над отделами"
	desc = "Зажигайте звёзды в разных отделах станции. Каждый отдел засчитывается один раз."
	hint = "Звезда не обязана жить долго: важно, где она была зажжена."
	trace_name = "звёздная пыль"
	trace_desc = "Пол припорошён мерцающей пылью, которая не собирается щёткой."
	trace_state = "sigil_cosmic"

/datum/heretic_deed/lock
	name = "Чужие замки"
	desc = "Открывайте Хваткой Мансуса закрытые шлюзы и запертые шкафы в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Открытая ладонь нужна для этого дела. Каждое открытие оставляет царапины у замка."
	trace_name = "царапины у замка"
	trace_desc = "Вокруг замка глубокие царапины, будто ключ искали вслепую."
	trace_state = "sigil_lock"

/datum/heretic_deed/tide
	name = "Соль на полу"
	desc = "Вызывайте воду Пучины Хваткой Мансуса из раковин, душевых и баков с водой в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Каждая раковина на станции помнит море. Солёная лужа остаётся до уборки."
	trace_name = "лужа солёной воды"
	trace_desc = "Вода на полу пахнет морем. Солёные разводы по краям."
	trace_state = "sigil_tide"

/datum/heretic_deed/glass
	name = "Трещины"
	desc = "Оставляйте Хваткой Мансуса трещины на окнах и зеркалах в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Трещина не разбивает стекло, но её видно. Зеркала подходят так же, как окна."
	trace_name = "стеклянная крошка"
	trace_desc = "На полу блестит стеклянная крошка, хотя рядом ничего не разбито."
	trace_state = "sigil_glass"

/datum/heretic_deed/blood
	name = "Чужие подписи"
	desc = "Читайте Хваткой Мансуса чужую кровь на полу. Каждый человек засчитывается один раз."
	hint = "Лазарет, арена и коридоры после драк полны чужих подписей."
	trace_name = "засохшая подпись"
	trace_desc = "Кровь засохла ровной линией, похожей на подпись."
	trace_state = "sigil_blood"

/datum/heretic_deed/echo
	name = "Голоса из динамиков"
	desc = "Заставляйте Хваткой Мансуса интеркомы шептать в разных отделах. Каждый отдел засчитывается один раз."
	hint = "Шёпот слышат все рядом. Выбирайте момент, когда зал пуст, или пусть слышат."
	trace_name = "отголосок"
	trace_desc = "Здесь до сих пор слышен едва различимый шёпот, хотя динамик молчит."
	trace_state = "sigil_echo"

#undef HERETIC_DEED_COOLDOWN
