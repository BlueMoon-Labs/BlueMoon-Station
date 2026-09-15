// Киберпсихоз: стойкий /datum/cyberpsychosis на человеке, обрабатывается SSobj.
// Идея зеркалит ДНК-механику (code/datums/dna.dm): состояние (нагрузка) каждый
// раз заново пересчитывается из вшитых кибераугментов (/obj/item/organ/cyberimp,
// хирургические импланты: anti-drop, тулсет и т.д.), а не копится в вакууме.
// Подкожные чипы /obj/item/implant нагрузку НЕ дают. Базовые эффекты построены
// на уже существующей системе психоза BlueMoon (GLOB.psychosis_pool_by_tier /
// GLOB.psychosis_hallucination_list), блюр и "noname"-восприятие чужих - по
// образцу хардкрита (BM_FILTER_HARDCRIT) и /datum/hallucination/delusion.
// Дефайны - в code/__BLUEMOONCODE/_DEFINES/.

/datum/cyberpsychosis
	/// Владелец (живой человек).
	var/mob/living/carbon/human/owner
	/// Итоговая кибернагрузка = сумма cyber_load имплантов.
	var/load = 0
	/// Временная кибер-перегрузка от ЭМИ (emp_act): накапливается, спадает
	/// сама со временем или сбрасывается приемом псикодина. Складывается с load.
	var/temp_overload = 0
	/// Текущая стадия (CYBERPSYCHOSIS_TIER_*).
	var/stage = CYBERPSYCHOSIS_TIER_NONE
	/// world.time следующего рандомного "приступа" галлюцинации.
	var/next_hallucination = 0
	/// world.time следующего приступа берсерка (критическая стадия).
	var/next_rampage = 0
	/// world.time следующего "волны" дебафа мудлета (раз в 5 минут).
	var/next_mood_wave = 0
	/// Идёт ли сейчас активное окно муд-дебафа (30 секунд).
	var/mood_wave_active = FALSE
	/// Базовые cooldown'ы (в децисекундах, как и world.time).
	var/hallucination_cooldown = 60 SECONDS
	var/rampage_cooldown = 26 SECONDS
	/// Активные image-оверлеи на чужих людей для эффекта "все - Unknown".
	var/list/image/perception_images = list()
	/// Включён ли сейчас оверлей "все - Unknown" (на MODERATE мерцает).
	var/perception_active = FALSE
	/// world.time следующего roll'а мерцания восприятия (MODERATE).
	var/next_perception_toggle = 0
	/// Рация-источник оповещений (живёт столько же, сколько датум).
	var/obj/item/radio/station_radio
	/// Оповещение на MODERATE уже ушло в мед-канал (единичное, без повторов).
	var/moderate_alert_sent = FALSE
	/// Оповещение на CRITICAL уже ушло в мед/сб-каналы (единичное).
	var/critical_alert_sent = FALSE

/datum/cyberpsychosis/New(mob/living/carbon/human/H)
	owner = H
	station_radio = new /obj/item/radio(owner)
	station_radio.subspace_transmission = TRUE
	station_radio.canhear_range = 0
	station_radio.extra_channels = list(RADIO_CHANNEL_MEDICAL = 1, RADIO_CHANNEL_SECURITY = 1)
	station_radio.recalculateChannels()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_global_mob_death))
	START_PROCESSING(SSobj, src)

/datum/cyberpsychosis/Destroy()
	clear_all_effects()
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	QDEL_NULL(station_radio)
	owner = null
	return ..()

/datum/cyberpsychosis/process(delta_time)
	if(!owner || QDELETED(owner))
		qdel(src)
		return
	if(owner.stat == DEAD)
		// Труп не чувствует киберпсихоза, но датум живёт - вдруг оживят.
		return
	// Стадия/нагрузка могли измениться вне наших хуков (отторжение импланта
	// из этого же датума, принудительный слом из другого модуля) - пересчитываем.
	decay_temp_overload(delta_time)
	update_stage(FALSE)
	if(stage == CYBERPSYCHOSIS_TIER_NONE)
		if(temp_overload > 0)
			// Стадии нет, но ЭМИ-перегрузка ещё не разрядилась - держимся
			// в процессе, чтобы дать ей спокойно спасть.
			return
		// Пока нагрузки нет (стадия NONE) - датум зря в цикле обработки.
		STOP_PROCESSING(SSobj, src)
		return
	if(owner.client)
		if(stage >= CYBERPSYCHOSIS_TIER_MODERATE)
			if(stage == CYBERPSYCHOSIS_TIER_MODERATE)
				// На MODERATE "Unknown"-восприятие мерцает: каждые ~1.5-2 минуты
				// с шансом ~30% оверлей включается/выключается.
				if(world.time >= next_perception_toggle)
					next_perception_toggle = world.time + rand(90 SECONDS, 120 SECONDS)
					if(prob(30))
						perception_active = !perception_active
				if(perception_active)
					update_other_perception()
				else
					clear_other_perception()
			else
				perception_active = TRUE
				update_other_perception()
		if(world.time >= next_hallucination)
			next_hallucination = world.time + rand(hallucination_cooldown * 0.8, hallucination_cooldown * 1.2)
			fire_hallucination()
		update_mood_wave()
	if(stage >= CYBERPSYCHOSIS_TIER_CRITICAL && owner.stat == CONSCIOUS)
		if(world.time >= next_rampage)
			next_rampage = world.time + rand(rampage_cooldown * 0.6, rampage_cooldown * 1.6)
			rampage()

/// Накапливает временную перегрузку от ЭМИ и тут же пересчитывает стадию.
/// amount - CYBERPSYCHOSIS_EMP_OVERLOAD_PER_IMPLANT за каждый задетый имплант.
/datum/cyberpsychosis/proc/add_emp_overload(amount)
	temp_overload = max(temp_overload + amount, 0)
	update_stage(FALSE)
	if(temp_overload > 0)
		START_PROCESSING(SSobj, src)

/// Самостоятельный спад ЭМИ-перегрузки: весь стэк от одного импульса (по
/// 0.5 за имплант) уходит за CYBERPSYCHOSIS_EMP_OVERLOAD_DECAY_TIME.
/datum/cyberpsychosis/proc/decay_temp_overload(delta_time)
	var/decay_rate = CYBERPSYCHOSIS_EMP_OVERLOAD_PER_IMPLANT / CYBERPSYCHOSIS_EMP_OVERLOAD_DECAY_TIME
	temp_overload = max(0, temp_overload - delta_time * decay_rate)

/// Сброс временной перегрузки (прием псикодина).
/datum/cyberpsychosis/proc/clear_temp_overload()
	if(!temp_overload)
		return
	temp_overload = 0
	update_stage(FALSE)

/// Пересчитывает стадию по текущей нагрузке. Смена стадии выполняет
/// вход/выход эффектов (сообщения, муд, блюр, оверлеи, фильтр как хардкрит).
/// Пороги сдвигаются вверх у owner'а с квирком «Совместимость с имплантами»
/// (TRAIT_IMPLANT_COMPATIBILITY): 12/20/27 вместо базовых 8/15/20.
/datum/cyberpsychosis/proc/update_stage(alert = TRUE, new_load = null)
	if(!owner || QDELETED(owner))
		return
	if(!isnull(new_load))
		load = new_load
	var/has_compat = HAS_TRAIT(owner, TRAIT_IMPLANT_COMPATIBILITY)
	var/mild_load = CYBERPSYCHOSIS_MILD_LOAD + (has_compat ? CYBERPSYCHOSIS_MILD_COMPATIBLE_OFFSET : 0)
	var/moderate_load = CYBERPSYCHOSIS_MODERATE_LOAD + (has_compat ? CYBERPSYCHOSIS_MODERATE_COMPATIBLE_OFFSET : 0)
	var/critical_load = CYBERPSYCHOSIS_CRITICAL_LOAD + (has_compat ? CYBERPSYCHOSIS_CRITICAL_COMPATIBLE_OFFSET : 0)
	var/new_stage = CYBERPSYCHOSIS_TIER_NONE
	var/effective_load = load + temp_overload
	if(effective_load >= critical_load)
		new_stage = CYBERPSYCHOSIS_TIER_CRITICAL
	else if(effective_load >= moderate_load)
		new_stage = CYBERPSYCHOSIS_TIER_MODERATE
	else if(effective_load >= mild_load)
		new_stage = CYBERPSYCHOSIS_TIER_MILD
	if(new_stage == stage)
		return
	if(stage >= CYBERPSYCHOSIS_TIER_MODERATE)
		clear_other_perception()
		perception_active = FALSE
		owner.set_blurriness(0)
		if(stage >= CYBERPSYCHOSIS_TIER_CRITICAL)
			owner.remove_filter("cyberpsychosis")
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_mild)
	stage = new_stage
	if(stage == CYBERPSYCHOSIS_TIER_NONE)
		mood_wave_active = FALSE
		next_mood_wave = 0
		if(alert)
			to_chat(owner, "<span class='notice'>Гул в голове затих. Вы снова контролируете себя.</span>")
		return
	// Первая волна муд-дебафа и первый приступ приходят с небольшой задержкой
	// после входа в стадию, а не мгновенно.
	next_mood_wave = world.time + rand(3 SECONDS, 6 SECONDS)
	switch(stage)
		if(CYBERPSYCHOSIS_TIER_MILD)
			next_hallucination = world.time + rand(30 SECONDS, 45 SECONDS)
			if(alert)
				to_chat(owner, "<span class='warning'>В голове поселяется тихое жужжание. Слишком много железа в теле?</span>")
		if(CYBERPSYCHOSIS_TIER_MODERATE)
			perception_active = TRUE
			next_perception_toggle = world.time + rand(90 SECONDS, 120 SECONDS)
			owner.set_blurriness(4)
			update_other_perception()
			next_hallucination = world.time + rand(20 SECONDS, 35 SECONDS)
			if(alert)
				to_chat(owner, "<span class='boldwarning'>Люди вокруг перестают быть людьми. Разве это были люди?</span>")
			shake_camera(owner, 2, 2)
			send_moderate_alerts()
		if(CYBERPSYCHOSIS_TIER_CRITICAL)
			perception_active = TRUE
			owner.set_blurriness(6)
			owner.add_filter("cyberpsychosis", 2, CYBERPSYCHOSIS_CRITICAL_FILTER)
			next_hallucination = world.time + rand(10 SECONDS, 25 SECONDS)
			next_rampage = world.time + 4 SECONDS
			if(alert)
				to_chat(owner, "<span class='userdanger'>РАЗУМ РАСПАДАЕТСЯ! ЖЕЛЕЗО ТРЕБУЕТ КРОВИ!</span>")
			shake_camera(owner, 3, 3)
			send_critical_alerts()

/// Снимает с owner'а все визуальные/механические эффекты киберпсихоза.
/// Вызывается при уничтожении датума.
/datum/cyberpsychosis/proc/clear_all_effects()
	clear_other_perception()
	perception_active = FALSE
	temp_overload = 0
	if(owner && !QDELETED(owner))
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_mild)
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "cyberpsychosis_kill", /datum/mood_event/cyberpsychosis_bloodlust)
		owner.set_blurriness(0)
		owner.remove_filter("cyberpsychosis")

/// Волны муд-дебафа: раз в 5 минут мудлет включается на 30 секунд и снимается.
/// Мудлет не висит постоянно - это "приступы", а не фоновое состояние.
/datum/cyberpsychosis/proc/update_mood_wave()
	if(world.time < next_mood_wave)
		return
	next_mood_wave = world.time + 5 MINUTES
	if(mood_wave_active)
		return
	mood_wave_active = TRUE
	switch(stage)
		if(CYBERPSYCHOSIS_TIER_MILD)
			SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_mild)
		if(CYBERPSYCHOSIS_TIER_MODERATE)
			SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_moderate)
		if(CYBERPSYCHOSIS_TIER_CRITICAL)
			SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_critical)
	addtimer(CALLBACK(src, PROC_REF(end_mood_wave)), 30 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/cyberpsychosis/proc/end_mood_wave()
	if(!owner || QDELETED(owner))
		return
	mood_wave_active = FALSE
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "cyberpsychosis", /datum/mood_event/cyberpsychosis_mild)

/// Кидает в owner случайную галлюцинацию из пула психоза с учётом стадии.
/// Отдельная система не дублируется: киберпсихоз переиспользует наработки
/// modular_bluemoon/.../psychosis_hallucinations.dm.
/datum/cyberpsychosis/proc/fire_hallucination()
	if(!length(GLOB.psychosis_pool_by_tier))
		build_psychosis_tier_pools()
	var/list/pool = GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_MILD].Copy()
	if(stage >= CYBERPSYCHOSIS_TIER_MODERATE)
		pool += GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_MODERATE]
	if(stage >= CYBERPSYCHOSIS_TIER_CRITICAL)
		pool += GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_SEVERE]
	var/picked = pickweight(pool)
	if(picked)
		new picked(owner, TRUE)
	return picked

/// Берсерк-приступ: owner бросается на случайного человека рядом. Аналог
/// "потери контроля" - персонаж сам не выбирает цель.
/datum/cyberpsychosis/proc/rampage()
	if(owner.stat != CONSCIOUS)
		return
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(CYBERPSYCHOSIS_OTHER_VIEW_RANGE, owner))
		if(H == owner || H.stat == DEAD)
			continue
		candidates += H
	if(!length(candidates))
		return
	var/mob/living/carbon/human/victim = pick(candidates)
	victim.visible_message(
		"<span class='danger'>[owner] с диким рыком бросается на [victim]!</span>",
		"<span class='userdanger'>[owner] кидается на вас!</span>")
	owner.do_attack_animation(victim)
	playsound(get_turf(owner), 'sound/weapons/genhit.ogg', 50, TRUE, -1)
	victim.apply_damage(rand(5, 10), BRUTE, "chest", 0, 0, 0, wound_bonus = 10)
	owner.DefaultCombatKnockdown(rand(5, 10))

/// Оповещает медотсек на средней стадии (единичное сообщение в мед-канал).
/datum/cyberpsychosis/proc/send_moderate_alerts()
	if(moderate_alert_sent)
		return
	moderate_alert_sent = TRUE
	broadcast_department_message(RADIO_CHANNEL_MEDICAL, "[owner.get_authentification_name("Unknown")] показывает признаки киберпсихоза, окажите мед помощь")

/// Оповещает на критической стадии: медотсек и службу безопасности (единичные).
/datum/cyberpsychosis/proc/send_critical_alerts()
	if(critical_alert_sent)
		return
	critical_alert_sent = TRUE
	var/name = owner.get_authentification_name("Unknown")
	broadcast_department_message(RADIO_CHANNEL_MEDICAL, "У [name] замечены серьёзные отклонения в показателях синапсов мозга, вызванные перегрузкой имплантов. Киберпсихоз! Срочно окажите медицинскую помощь!")
	broadcast_department_message(RADIO_CHANNEL_SECURITY, "[name] установил слишком много хрома. Киберпсих на станции, вышлите отряды захвата Max-Tac и доставьте члена экипажа в мед отсек")

/// Шлёт сообщение в департментный радио-канал станции от имени консоли.
/datum/cyberpsychosis/proc/broadcast_department_message(channel, message)
	if(!owner || QDELETED(owner) || !station_radio || QDELETED(station_radio))
		return
	station_radio.talk_into(station_radio, message, channel)

/// Убийство человека на критической стадии: огромный прилив настроения + выкрик.
/datum/cyberpsychosis/proc/on_global_mob_death(datum/source, mob/living/dead, gibbed)
	if(stage < CYBERPSYCHOSIS_TIER_CRITICAL)
		return
	if(!ishuman(dead) || dead == owner)
		return
	if(!owner || QDELETED(owner) || owner.stat != CONSCIOUS)
		return
	if(!dead.lastattackerckey || dead.lastattackerckey != owner.ckey)
		return
	owner.say(pick(list("Вот оно! Теперь я вижу!", "Смотри, мама, я особенный!", "Они.. Они повсюду!", "Адам Смешер бы завидовал мне!", "Это была чистая симфония железа и плоти!")))
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "cyberpsychosis_kill", /datum/mood_event/cyberpsychosis_bloodlust)

/// Каждый роботизированный орган/кибераугмент, получивший emp_act(), накапливает
/// у своего носителя временную ЭМИ-перегрузку (CYBERPSYCHOSIS_EMP_OVERLOAD_PER_IMPLANT
/// за одну порцию). ЭМИ-перегрузка складывается с постоянной нагрузкой cyber_load
/// и подталкивает стадию киберпсихоза вверх, пока не спадет или не будет снята
/// псикодином. Хук лежит на самом общем типе органа, поэтому стабильно срабатывает
/// и для кибераугментов, и для роботизированных замен внутренних органов.
/obj/item/organ/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF || status != ORGAN_ROBOTIC)
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!istype(H.cyberpsychosis) || QDELETED(H.cyberpsychosis))
		// Датума могло ещё не быть: перегрузка от ЭМИ сама по себе даёт тему
		// (например, так могут обойтись без кибер-нагрузки cyber_load).
		H.cyberpsychosis = new /datum/cyberpsychosis(H)
	H.cyberpsychosis.add_emp_overload(CYBERPSYCHOSIS_EMP_OVERLOAD_PER_IMPLANT)

/// Псикодин гасит временную ЭМИ-перегрузку киберпсихоза, возвращая стадию
/// к постоянной нагрузке. Прочее поведение реагента не трогаем.
/datum/reagent/medicine/psicodine/on_mob_add(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FEARLESS, type)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(istype(H.cyberpsychosis) && !QDELETED(H.cyberpsychosis))
			H.cyberpsychosis.clear_temp_overload()