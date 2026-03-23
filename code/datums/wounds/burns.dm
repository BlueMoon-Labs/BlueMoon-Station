

// TODO: well, a lot really, but specifically I want to add potential fusing of clothing/equipment on the affected area, and limb infections, though those may go in body part code
/datum/wound/burn
	a_or_from = "from"
	wound_type = WOUND_BURN
	processes = TRUE
	sound_effect = 'sound/effects/wounds/sizzle1.ogg'
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE)

	treatable_by = list(/obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh) // sterilizer and alcohol will require reagent treatments, coming soon

		// Flesh damage vars
	/// How much damage to our flesh we currently have. Once both this and infestation reach 0, the wound is considered healed
	var/flesh_damage = 5
	/// Our current counter for how much flesh regeneration we have stacked from regenerative mesh/synthflesh/whatever, decrements each tick and lowers flesh_damage
	var/flesh_healing = 0

		// Infestation vars (only for severe and critical)
	/// How quickly infection breeds on this burn if we don't have disinfectant
	var/infestation_rate = 0
	/// Our current level of infection
	var/infestation = 0
	/// Our current level of sanitization/anti-infection, from disinfectants/alcohol/UV lights. While positive, totally pauses and slowly reverses infestation effects each tick
	var/sanitization = 0

	/// Once we reach infestation beyond WOUND_INFESTATION_SEPSIS, we get this many warnings before the limb is completely paralyzed (you'd have to ignore a really bad burn for a really long time for this to happen)
	var/strikes_to_lose_limb = 3

	// BLUEMOON ADD START - переменные для синтетических конечностей
	var/synthetic_mode = FALSE
	var/exposed_wiring = 0          // количество оголённых проводов
	var/short_circuit_risk = 0      // риск короткого замыкания
	var/internal_damage = 0         // внутренние повреждения цепей (требуют наногеля)
	var/nanogel_active = FALSE      // Активен ли наногель на этой ране
	var/nanogel_potency = 0         // Оставшаяся "сила" наногеля (лечебный потенциал)
	// BLUEMOON ADD END

/datum/wound/burn/wound_injury(datum/wound/burn/old_wound = null)
	. = ..()
	// BLUEMOON ADD START - определяем режим по типу конечности (а не расе жертвы)
	if(limb && limb.is_robotic_limb())
		synthetic_mode = TRUE
		exposed_wiring = flesh_damage * 2
		internal_damage = flesh_damage

/datum/wound/burn/handle_process()
	. = ..()

	// BLUEMOON ADD START - отдельная логика для синтетических конечностей
	if(synthetic_mode)
		return handle_process_synthetic()
	// BLUEMOON ADD END

	if(strikes_to_lose_limb == 0)
		victim.adjustToxLoss(0.5)
		if(prob(1))
			victim.visible_message("<span class='danger'>Инфекция на [limb.ru_name_v] персонажа [victim] тошнотворно пузырится!</span>", "<span class='warning'>Вы чувствуете, как инфекция на вашей - [limb.ru_name_v] пульсирует и распространяется по вашим тканям!</span>")
		return

	if(victim.reagents)
		if(victim.reagents.has_reagent(/datum/reagent/medicine/spaceacillin))
			sanitization += 0.9
		if(victim.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine/))
			sanitization += 0.9
		if(victim.reagents.has_reagent(/datum/reagent/medicine/mine_salve))
			sanitization += 0.3
			flesh_healing += 0.5

	if(limb.current_gauze)
		limb.seep_gauze(WOUND_BURN_SANITIZATION_RATE)

	if(flesh_healing > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		flesh_damage = max(0, flesh_damage - 1)
		flesh_healing = max(0, flesh_healing - bandage_factor) // good bandages multiply the length of flesh healing

	// here's the check to see if we're cleared up
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>Вы удалили инфекцию, что находилась на [limb.ru_name_v]!</span>")
		qdel(src)
		return

	// sanitization is checked after the clearing check but before the rest, because we freeze the effects of infection while we have sanitization
	if(sanitization > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE)
		sanitization = max(0, sanitization - (WOUND_BURN_SANITIZATION_RATE * bandage_factor))
		return

	infestation += infestation_rate

	switch(infestation)
		if(0 to WOUND_INFECTION_MODERATE)
		if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
			if(prob(30))
				victim.adjustToxLoss(0.2)
				if(prob(6))
					to_chat(victim, "<span class='warning'>Ваша [limb.ru_name] сочится гноем и волдырями...</span>")
		if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
			if(!disabling && prob(2))
				to_chat(victim, "<span class='warning'><b>Ваша [limb.ru_name] парализуется, пока вы пытаетесь бороться с инфекцией!</b></span>")
				disabling = TRUE
			else if(disabling && prob(8))
				to_chat(victim, "<span class='notice'>Ваша [limb.ru_name] все ещё в ужасном состоянии, хоть вы и вернули контроль над ней!</span>")
				disabling = FALSE
			else if(prob(20))
				victim.adjustToxLoss(0.5)
		if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
			if(!disabling && prob(3))
				to_chat(victim, "<span class='warning'><b>[limb.ru_name] внезапно теряет всякую чувствительность из-за гноящейся инфекции!</b></span>")
				disabling = TRUE
			else if(disabling && prob(3))
				to_chat(victim, "<span class='notice'>Ваша [limb.ru_name] едва снова ощущается. Вам придется напрячься, чтобы сохранить моторику!</span>")
				disabling = FALSE
			else if(prob(1))
				to_chat(victim, "<span class='warning'>Вы задумаетесь о жизни без вашей конечности...</span>")
				victim.adjustToxLoss(0.75)
			else if(prob(4))
				victim.adjustToxLoss(1)
		if(WOUND_INFECTION_SEPTIC to INFINITY)
			if(prob(infestation))
				switch(strikes_to_lose_limb)
					if(3 to INFINITY)
						to_chat(victim, "<span class='deadsay'>Кожа на вашей [limb.ru_name_v] буквально сползает, вы чувствуете себя ужасно!</span>")
					if(2)
						to_chat(victim, "<span class='deadsay'><b>Инфекция на вашей [limb.ru_name_v] обильно сочится, это отвратительно!</b></span>")
					if(1)
						to_chat(victim, "<span class='deadsay'><b>Ваша [limb.ru_name] целиком захвачена инфекций!</b></span>")
					if(0)
						to_chat(victim, "<span class='deadsay'><b>Последние нервные окончания на вашей [limb.ru_name_v] - затухают, инфекция целиком парализует сустав.</b></span>")
						threshold_penalty = 120 // piss easy to destroy
						var/datum/brain_trauma/severe/paralysis/sepsis = new (limb.body_zone)
						victim.gain_trauma(sepsis)
				strikes_to_lose_limb--

// BLUEMOON ADD START - процесс обработки ожогов для синтетических конечностей (проводка + наногель)
/datum/wound/burn/proc/handle_process_synthetic()
	if(strikes_to_lose_limb == 0)
		victim.adjustToxLoss(0.3)
		if(prob(2))
			victim.visible_message("<span class='danger'>[limb.ru_name_v] персонажа [victim] испускает сноп искр из повреждённой проводки!</span>",
								  "<span class='warning'>Вы чувствуете нестабильность в системе управления [limb.ru_name_v]!</span>")
		return

	// Очистка контактов кислотой (удаляет окислы и коррозию)
	if(victim.reagents)
		if(victim.reagents.has_reagent(/datum/reagent/toxin/acid))
			sanitization += 0.6  // кислота хорошо очищает контакты
			// Но кислота может повредить изоляцию при длительном воздействии
			if(prob(5))
				exposed_wiring = min(exposed_wiring + 1, exposed_wiring + 2)
				victim.visible_message("<span class='warning'>Кислота немного повредила изоляцию на [limb.ru_name_v]!</span>")

	if(limb.current_gauze)
		// Повязка временно снижает риск КЗ
		short_circuit_risk = max(0, short_circuit_risk - 0.2)
		limb.seep_gauze(WOUND_BURN_SANITIZATION_RATE * 0.3)

	// Естественное "остывание" не восстанавливает проводку
	if(flesh_healing > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		flesh_damage = max(0, flesh_damage - 1)
		exposed_wiring = max(0, exposed_wiring - bandage_factor)
		flesh_healing = max(0, flesh_healing - bandage_factor)

	if(nanogel_active && nanogel_potency > 0)
		// Постепенное восстановление внутренних цепей
		internal_damage = max(0, internal_damage - 0.25)
		flesh_healing += 0.15
		short_circuit_risk = max(0, short_circuit_risk - 0.1)
		flesh_damage = max(0, flesh_damage - 0.1)

		// Расходуем потенциал наногеля
		nanogel_potency -= 0.25

		// Визуальный эффект при активном лечении
		if(prob(5) && nanogel_potency > 5)
			victim.visible_message("<span class='notice'>Наногель на [limb.ru_name_v] мягко светится, восстанавливая цепи.</span>")

		// Наногель закончился
		if(nanogel_potency <= 0)
			nanogel_active = FALSE
			victim.visible_message("<span class='notice'>Наногель на [limb.ru_name_v] полностью исчерпан.</span>")

	// Проверка на "починку": нет оголённых проводов + низкий риск КЗ + нет внутренних повреждений
	if((flesh_damage <= 0) && (exposed_wiring <= 0) && (short_circuit_risk <= 1) && (internal_damage <= 0))
		to_chat(victim, "<span class='green'>Повреждённая проводка на [limb.ru_name_v] полностью восстановлена!</span>")
		qdel(src)
		return

	// Санитизация = очистка контактов от нагара/окислов
	if(sanitization > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		short_circuit_risk = max(0, short_circuit_risk - WOUND_BURN_SANITIZATION_RATE * 0.5)
		sanitization = max(0, sanitization - (WOUND_BURN_SANITIZATION_RATE * bandage_factor * 0.5))
		return

	// Накопление "загрязнения": окисление, коррозия, ослабление изоляции
	short_circuit_risk += infestation_rate

	switch(short_circuit_risk)
		if(0 to WOUND_INFECTION_MODERATE)
		if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
			if(prob(10))
				victim.visible_message("<span class='warning'>Из [limb.ru_name_v] персонажа [victim] пробегает слабая искра...</span>")
				victim.adjustFireLoss(0.2)
				do_sparks(rand(5, 9), FALSE, victim.loc)
		if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
			if(!disabling && prob(4))
				to_chat(victim, "<span class='warning'><b>Сервоприводы [limb.ru_name_v] дают сбои из-за нестабильного контакта!</b></span>")
				disabling = TRUE
				do_sparks(rand(5, 9), FALSE, victim.loc)
			else if(disabling && prob(12))
				to_chat(victim, "<span class='notice'>Сигнал к [limb.ru_name_v] стабилизировался.</span>")
				disabling = FALSE
			else if(prob(15))
				victim.adjustFireLoss(0.3)
		if(WOUND_INFECTION_CRITICAL to INFINITY)
			if(prob(short_circuit_risk * 0.6))
				switch(strikes_to_lose_limb)
					if(3 to INFINITY)
						to_chat(victim, "<span class='warning'>Изоляция на [limb.ru_name_v] плавится, датчики предупреждают о перегрузке!</span>")
					if(2)
						to_chat(victim, "<span class='danger'><b>Короткое замыкание в [limb.ru_name_v]! Система аварийно отключает контуры!</b></span>")
						victim.adjustFireLoss(0.5)
						do_sparks(rand(5, 9), FALSE, victim.loc)
					if(1)
						to_chat(victim, "<span class='deadsay'><b>Критический отказ проводки в [limb.ru_name_v]! Конечность может отключиться!</b></span>")
						do_sparks(rand(5, 9), FALSE, victim.loc)
					if(0)
						to_chat(victim, "<span class='deadsay'><b>Полный разрыв цепи в [limb.ru_name_v]. Конечность обездвижена.</b></span>")
						threshold_penalty = 120
						var/datum/brain_trauma/severe/paralysis/circuit_failure = new (limb.body_zone)
						victim.gain_trauma(circuit_failure)
				strikes_to_lose_limb--
// BLUEMOON ADD END

/datum/wound/burn/get_examine_description(mob/user)
	// BLUEMOON ADD START
	if(synthetic_mode)
		return get_examine_description_synthetic(user)
	// BLUEMOON ADD END

	if(strikes_to_lose_limb <= 0)
		return "<span class='deadsay'><B>[victim.ru_ego(TRUE)] [limb.ru_name] отмерла целиком.</B></span>"

	var/list/condition = list("[victim.ru_ego(TRUE)] [limb.ru_name] [examine_desc]")
	if(limb.current_gauze)
		var/bandage_condition
		switch(limb.current_gauze.absorption_capacity)
			if(0 to 1.25)
				bandage_condition = "изношенным "
			if(1.25 to 2.75)
				bandage_condition = "потрёпанным "
			if(2.75 to 4)
				bandage_condition = "грязноватым "
			if(4 to INFINITY)
				bandage_condition = "чистым "

		condition += " покрыт [bandage_condition] [limb.current_gauze.name]"
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				condition += ", <span class='deadsay'>с небольшими бесцветными пятнами вдоль вен!</span>"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				condition += ", <span class='deadsay'>с темными пятнами, расходящимися под кожей!</span>"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				condition += ", <span class='deadsay'>с с гниющими пульсирующими прожилками!</span>"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				return "<span class='deadsay'><B>[victim.ru_ego(TRUE)] [limb.ru_name] представляет собой месиво из перегноя и костей, с которых сползает заражённая кожа!</B></span>"
			else
				condition += "!"
	return "<B>[condition.Join()]</B>"

// BLUEMOON ADD START - описание для синтетических конечностей (проводка + наногель)
/datum/wound/burn/proc/get_examine_description_synthetic(mob/user)
    if(strikes_to_lose_limb <= 0)
        return "<span class='deadsay'><B>Системы управления [limb.ru_name_v] персонажа [victim] полностью отключены.</B></span>"

    var/list/condition = list("[victim.ru_ego(TRUE)] [limb.ru_name] [examine_desc]")

    if(limb.current_gauze)
        condition += " (временно заизолирована [limb.current_gauze.name])"

    // Визуальные признаки по уровню риска КЗ
    switch(short_circuit_risk)
        if(0 to WOUND_INFECTION_MODERATE)
            condition += ", <span class='notice'>с тусклыми следами нагара на контактах</span>"
        if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
            condition += ", <span class='warning'>с лёгким искрением оголённых контактов</span>"
        if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
            condition += ", <span class='danger'>с видимыми повреждёнными проводами и нестабильным сигналом</span>"
        if(WOUND_INFECTION_CRITICAL to INFINITY)
            return "<span class='deadsay'><B>[limb.ru_name] представляет собой клубок обгоревших проводов с постоянными короткими замыканиями. Требуется замена проводки!</B></span>"

    // Визуальные признаки активности наногеля
    if(nanogel_active)
        if(nanogel_potency > 8)
            condition += ", <span class='notice'>покрыта светящимся гелем с активными нанитами</span>"
        else if(nanogel_potency > 4)
            condition += ", <span class='notice'>покрыта гелем, который постепенно тускнеет</span>"
        else
            condition += ", <span class='notice'>покрыта почти высохшим гелем</span>"

    condition += "!"
    return "<B>[condition.Join()]</B>"
// BLUEMOON ADD END

/datum/wound/burn/get_scanner_description(mob/user)
	if(strikes_to_lose_limb == 0)
		var/oopsie = "Тип: [name]\nТяжесть: [severity_text()]"
		oopsie += "<div class='ml-3'>Степень инфекции: <span class='deadsay'>Полное заражение. Конечность утрачена. Немедленно ампутируйте или аугментируйте её.</span></div>"
		return oopsie

	. = ..()
	. += "<div class='ml-3'>"

	// BLUEMOON ADD START - сканер для синтетических конечностей
	if(synthetic_mode)
		. += get_synthetic_scanner_description(user)
		return .
	// BLUEMOON ADD END

	if(infestation <= sanitization && flesh_damage <= flesh_healing)
		. += "Дальнейшее лечение не требуется: Ожоги вскоре затянутся."
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				. += "Степень инфекции: Умеренная\n"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				. += "Степень инфекции: Тяжелая\n"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				. += "Степень инфекции: <span class='deadsay'>КРИТИЧЕСКАЯ</span>\n"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				. += "Степень инфекции: <span class='deadsay'>НЕМИНУЕМАЯ ПОТЕРЯ</span>\n"
		if(infestation > sanitization)
			. += "Удаление некротических тканей, антибиотики/антисептик, регенеративная сетка помогут избавиться от инфекции. Ультрафиолетовые пенлайты парамедиков также могут быть полезны.\n"

		if(flesh_damage > 0)
			. += "Обнаружены повреждения плоти: Нанесите мазь или регенеративную сетку для восстановления.\n"
	. += "</div>"

/datum/wound/burn/proc/get_synthetic_scanner_description(mob/user)
	. += "<b>▓ Диагностика синтетической конечности</b>\n"
	. += "─────────────────────────────────\n"

	// Общий статус
	if(exposed_wiring <= 0 && short_circuit_risk <= 1 && internal_damage <= 0 && !nanogel_active)
		. += "<span class='notice'>Статус:</span> <span class='green'>● Исправно. Ремонт завершён.</span>\n"
	else if(nanogel_active && internal_damage > 0)
		. += "<span class='notice'>Статус:</span> <span class='notice'>● Восстановление в процессе</span>\n"
	else
		. += "<span class='notice'>Статус:</span> <span class='danger'>● Требует ремонта</span>\n"

	. += "─────────────────────────────────\n"

	// Параметр 1: Оголённые провода
	. += "<b>Параметр: Внешняя проводка</b>\n"
	if(exposed_wiring <= 0)
		. += "  <span class='notice'>Состояние:</span> <span class='green'>[exposed_wiring] ед. (Норма)</span>\n"
	else if(exposed_wiring <= 4)
		. += "  <span class='notice'>Состояние:</span> <span class='warning'>[exposed_wiring] ед. (Повреждена)</span>\n"
	else
		. += "  <span class='notice'>Состояние:</span> <span class='danger'>[exposed_wiring] ед. (Критично)</span>\n"
	. += "  <span class='notice'>Решение:</span> <span class='notice'>Замена кабелей</span>\n"

	. += "─────────────────────────────────\n"

	// Параметр 2: Риск короткого замыкания
	. += "<b>Параметр: Контакты</b>\n"
	if(short_circuit_risk <= 1)
		. += "  <span class='notice'>Состояние:</span> <span class='green'>[round(short_circuit_risk, 0.1)] ед. (Норма)</span>\n"
	else if(short_circuit_risk <= 3)
		. += "  <span class='notice'>Состояние:</span> <span class='warning'>[round(short_circuit_risk, 0.1)] ед. (Загрязнены)</span>\n"
	else
		. += "  <span class='notice'>Состояние:</span> <span class='danger'>[round(short_circuit_risk, 0.1)] ед. (Критично)</span>\n"
	. += "  <span class='notice'>Решение:</span> <span class='notice'>Кислота или Мультитул</span>\n"

	. += "─────────────────────────────────\n"

	// Параметр 3: Внутренние повреждения цепей
	. += "<b>Параметр: Внутренние цепи</b>\n"
	if(internal_damage <= 0)
		. += "  <span class='notice'>Состояние:</span> <span class='green'>[round(internal_damage, 0.1)] ед. (Норма)</span>\n"
		if(nanogel_active)
			. += "  <span class='notice'>Статус:</span> <span class='green'>● Наногель завершил работу</span>\n"
	else
		. += "  <span class='notice'>Состояние:</span> <span class='danger'>[round(internal_damage, 0.1)] ед. (Повреждены)</span>\n"
		if(nanogel_active)
			. += "  <span class='notice'>Статус:</span> <span class='notice'>● Наногель активен ([round(nanogel_potency, 0.1)] ед. осталось, ~[round(nanogel_potency * 4)] сек)</span>\n"
		else
			. += "  <span class='notice'>Статус:</span> <span class='warning'>● Требуется нанесение наногеля</span>\n"
	. += "  <span class='notice'>Решение:</span> <span class='notice'>Наногель</span>\n"

	. += "─────────────────────────────────\n"

	// Рекомендации по лечению (приоритизированные)
	. += "<b>▓ Рекомендации по ремонту</b>\n"
	var/list/recommendations = list()
	var/step = 1

	if(exposed_wiring > 0)
		recommendations += "[step]. Заменить кабели — [exposed_wiring] ед."
		step++

	if(short_circuit_risk > 1)
		recommendations += "[step]. Очистить контакты:</span>"
		recommendations += "   • Кислота — быстро ([round(short_circuit_risk / 1.2, 1)] применений), есть риск повреждения"
		recommendations += "   • Мультитул — безопасно ([round(short_circuit_risk / 0.3, 1)] применений), дольше"
		step++

	if(internal_damage > 0 && exposed_wiring <= 0)
		if(!nanogel_active)
			recommendations += "[step]. Нанести наногель — [ceil(internal_damage / 3)] ед."
		else
			recommendations += "[step]. Ожидать завершения работы наногеля (~[round(nanogel_potency * 4)] сек)"
		step++

	if(recommendations.len > 0)
		. += "[recommendations.Join("\n")]\n"
	else
		. += "<span class='green'>● Дальнейшие действия не требуются</span>\n"

	. += "</div>"
	return .
/*
	new burn common procs
*/

/// if someone is using ointment on our burns
/datum/wound/burn/proc/ointment(obj/item/stack/medical/ointment/I, mob/user)
	// BLUEMOON ADD START - мази не работают на синтетических конечностях
	if(synthetic_mode)
		to_chat(user, "<span class='warning'>[I.name] неэффективна для ремонта электронных компонентов!</span>")
		return
	// BLUEMOON ADD END
	user.visible_message("<span class='notice'>[user] начинает применять [I] на конечности [victim]...</span>", "<span class='notice'>Вы начинаете применять [I] на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] применяет [I] на [victim].</span>", "<span class='green'>Вы применяете [I] на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"].</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration

	if((infestation <= 0 || sanitization >= infestation) && (flesh_damage <= 0 || flesh_healing > flesh_damage))
		to_chat(user, "<span class='notice'>Вы сделали всё, что можно было сделать с помощью с[I], теперь подождите, пока плоть на конечности персонажа [victim] восстановится.</span>")
	else
		try_treating(I, user)

/// if someone is using mesh on our burns
/datum/wound/burn/proc/mesh(obj/item/stack/medical/mesh/I, mob/user)
	// BLUEMOON ADD START
	if(synthetic_mode)
		to_chat(user, "<span class='warning'>Регенеративная сетка бесполезна для электронных повреждений!</span>")
		return
	// BLUEMOON ADD END

	user.visible_message("<span class='notice'>[user] пытается перевязать конечность - [limb.ru_name] - персонажа [victim] с помощью [I]...</span>", "<span class='notice'>Вы пытаетесь перевязать [user == victim ? "вашу [limb.ru_name]" : "конечность персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] применяет [I] на [victim].</span>", "<span class='green'>Вы применяете [I] на [user == victim ? "вашу конечность." : "конечность персонажа [victim]"]</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration

	if(sanitization >= infestation && flesh_healing > flesh_damage)
		to_chat(user, "<span class='notice'>Вы сделали всё, что возможно было сделать с помощью [I], теперь подождите, пока плоть на конечности персонажа [victim] восстановится.</span>")
	else
		try_treating(I, user)

/// Paramedic UV penlights
/datum/wound/burn/proc/uv(obj/item/flashlight/pen/paramedic/I, mob/user)
	// BLUEMOON ADD START
	if(synthetic_mode)
		to_chat(user, "<span class='warning'>УФ-излучение не покажет на электронные неисправности!</span>")
		return
	// BLUEMOON ADD END
	if(!COOLDOWN_FINISHED(I, uv_cooldown))
		to_chat(user, "<span class='notice'>[I] ещё перезаряжается!</span>")
		return
	if(infestation <= 0 || infestation < sanitization)
		to_chat(user, "<span class='notice'>На конечности персонажа [victim] нет инфекции!</span>")
		return

	user.visible_message("<span class='notice'>[user] просвечивает ожоги персонажа [victim] с помощью [I].</span>", "<span class='notice'>Вы подсвечиваете ожоги [user == victim ? "на вашей конечности" : "конечности персонажа [victim]"] с помощью [I].</span>", vision_distance=COMBAT_MESSAGE_RANGE)
	sanitization += I.uv_power
	COOLDOWN_START(I, uv_cooldown, I.uv_cooldown_length)

// BLUEMOON ADD START - процедуры лечения для синтетических конечностей (ПРОВОДКА + НАНОГЕЛЬ)

/// Замена/восстановление проводки
/datum/wound/burn/proc/replace_wiring(obj/item/stack/cable_coil/I, mob/user)
	if(exposed_wiring <= 0)
		to_chat(user, "<span class='notice'>На [limb.ru_name_v] нет оголённых проводов для замены!</span>")
		return
	var/self_penalty_mult = (user == victim ? 1.3 : 1)
	user.visible_message("<span class='notice'>[user] аккуратно заменяет повреждённые провода на [limb.ru_name_v] персонажа [victim]...</span>",
						"<span class='notice'>Вы заменяете повреждённые провода на [user == victim ? "своей конечности" : "конечности персонажа [victim]"]...</span>")
	if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(exposed_wiring <= 0) // повторная проверка после do_after
		to_chat(user, "<span class='notice'>Проводка уже восстановлена!</span>")
		return
	user.visible_message("<span class='green'>[user] завершает замену проводки на [limb.ru_name_v] персонажа [victim].</span>",
						"<span class='green'>Вы завершаете замену проводки.</span>")
	I.use(1)
	exposed_wiring = max(0, exposed_wiring - 2)
	flesh_healing += 1.5
	short_circuit_risk = max(0, short_circuit_risk - 0.5)
	if(exposed_wiring <= 0)
		victim.visible_message("<span class='notice'>Искры на [limb.ru_name_v] персонажа [victim] прекращаются.</span>")

/// Очистка контактов кислотой
/datum/wound/burn/proc/clean_contacts_acid(obj/item/I, mob/user)
	if(short_circuit_risk <= 1 && sanitization >= short_circuit_risk)
		to_chat(user, "<span class='notice'>Контакты на [limb.ru_name_v] уже чистые!</span>")
		return
	var/has_acid = (victim.reagents && victim.reagents.has_reagent(/datum/reagent/toxin/acid)) || (I.reagents && I.reagents.has_reagent(/datum/reagent/toxin/acid))
	if(!has_acid)
		to_chat(user, "<span class='warning'>Требуется кислота для очистки контактов!</span>")
		return
	user.visible_message("<span class='notice'>[user] обрабатывает контакты на [limb.ru_name_v] кислотой...</span>")
	if(!do_after(user, 40, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(short_circuit_risk <= 1)
		to_chat(user, "<span class='notice'>Контакты уже очищены!</span>")
		return
	if(prob(10))
		exposed_wiring = min(exposed_wiring + 1, exposed_wiring + 2)
		user.visible_message("<span class='warning'>Кислота повредила изоляцию!</span>")
	else
		sanitization += 1.2
		short_circuit_risk = max(0, short_circuit_risk - 0.5)
	user.visible_message("<span class='green'>[user] завершает обработку кислотой.</span>")

/// Очистка контактов мультитулом
/datum/wound/burn/proc/clean_contacts(obj/item/multitool/I, mob/user)
	if(short_circuit_risk <= 1 && sanitization >= short_circuit_risk)
		to_chat(user, "<span class='notice'>Контакты на [limb.ru_name_v] уже чистые!</span>")
		return
	user.visible_message("<span class='notice'>[user] очищает контакты на [limb.ru_name_v] персонажа [victim]...</span>")
	if(!do_after(user, 30, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(short_circuit_risk <= 1)
		to_chat(user, "<span class='notice'>Контакты уже очищены!</span>")
		return
	sanitization += 0.6
	short_circuit_risk = max(0, short_circuit_risk - 0.3)
	user.visible_message("<span class='green'>[user] завершает очистку контактов.</span>")

/// Экстренное "запаивание" сваркой
/datum/wound/burn/proc/emergency_weld(obj/item/weldingtool/I, mob/user)
	if(flesh_damage <= 0 && exposed_wiring <= 0)
		to_chat(user, "<span class='notice'>На [limb.ru_name_v] нет критических повреждений для сварки!</span>")
		return
	if(I.get_fuel() < 8)
		user.visible_message("<span class='danger'>В сварке не хватает топлива!</span>")
		return
	var/self_penalty_mult = (user == victim ? 1.8 : 1)
	user.visible_message("<span class='danger'>[user] экстренно запаивает повреждённые цепи на [limb.ru_name_v] персонажа [victim]...</span>")
	if(!do_after(user, base_treat_time * 1.5 * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(flesh_damage <= 0)
		to_chat(user, "<span class='notice'>Повреждения уже устранены!</span>")
		return
	if(!I.use(8))
		user.visible_message("<span class='danger'>В сварке не хватило топлива для экстренного запаивания!</span>")
		return
	user.visible_message("<span class='warning'>[user] завершает экстренный ремонт.</span>")
	flesh_damage = max(0, flesh_damage - 3)
	exposed_wiring = max(0, exposed_wiring - 1)
	short_circuit_risk = max(0, short_circuit_risk - 0.2)
	if(prob(15))
		short_circuit_risk += 0.5
		victim.visible_message("<span class='warning'>При пайке задета соседняя цепь на [limb.ru_name_v]!</span>")

/// Наногель для внутренних повреждений (одноразовое применение + HoT)
/datum/wound/burn/proc/nanogel_treatment(obj/item/stack/medical/nanogel/I, mob/user)
    // Нельзя применить, если наногель уже активен
    if(nanogel_active)
        to_chat(user, "<span class='notice'>Наногель уже активен на [limb.ru_name_v]!</span>")
        return

    // Сначала нужно починить внешнюю проводку
    if(exposed_wiring > 0)
        to_chat(user, "<span class='warning'>Сначала восстановите внешнюю проводку! Наногель не проникнет к внутренним цепям через оголённые провода.</span>")
        return

    var/self_penalty_mult = (user == victim ? 1.2 : 1)
    user.visible_message("<span class='notice'>[user] наносит наногель на [limb.ru_name_v] персонажа [victim]...</span>",
                        "<span class='notice'>Вы наносите наногель на [user == victim ? "свою конечность" : "конечность персонажа [victim]"]...</span>")
    if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
        return

    user.visible_message("<span class='green'>[user] завершает обработку наногелем.</span>",
                        "<span class='green'>Вы завершаете обработку наногелем.</span>")
    I.use(1)

    // Активируем наногель с запасом прочности
    nanogel_active = TRUE
    nanogel_potency = 12  // ~48 тиков лечения при расходе 0.25/тик

    victim.visible_message("<span class='notice'>Наногель проникает в микроповреждения цепей на [limb.ru_name_v] и начинает восстановительный процесс.</span>")

    // Мгновенный небольшой эффект при нанесении
    internal_damage = max(0, internal_damage - 1)
    short_circuit_risk = max(0, short_circuit_risk - 0.5)

/datum/wound/burn/treat(obj/item/I, mob/user)
	if(!victim.can_inject())
		to_chat(user, span_danger("Одежда на теле [victim] не позволяет применить [I]!</span>"))
		return

	// BLUEMOON ADD START - лечение синтетических конечностей
	if(synthetic_mode)
		return treat_synthetic(I, user)
	// BLUEMOON ADD END

	if(istype(I, /obj/item/stack/medical/ointment))
		ointment(I, user)
	else if(istype(I, /obj/item/stack/medical/mesh))
		mesh(I, user)
	else if(istype(I, /obj/item/flashlight/pen/paramedic))
		uv(I, user)

// BLUEMOON ADD START - обработка лечения для синтетических конечностей (ПРОВОДКА + НАНОГЕЛЬ)
/datum/wound/burn/proc/treat_synthetic(obj/item/I, mob/user)
	if(!victim.can_inject())
		to_chat(user, span_danger("Доступ к повреждённым компонентам [victim] закрыт!</span>"))
		return

	// Основной метод: кабели для внешней проводки
	if(istype(I, /obj/item/stack/cable_coil))
		replace_wiring(I, user)
	// Вспомогательные методы:
	else if(istype(I, /obj/item/multitool) || istype(I, /obj/item/screwdriver))
		clean_contacts(I, user)
	// Кислота для очистки контактов (более эффективно)
	else if(I.reagents && I.reagents.has_reagent(/datum/reagent/toxin/acid))
		clean_contacts_acid(I, user)
	else if(I.tool_behaviour == TOOL_WELDER || istype(I, /obj/item/weldingtool))
		emergency_weld(I, user)
	// Наногель для финальной обработки
	else if(istype(I, /obj/item/stack/medical/nanogel))
		nanogel_treatment(I, user)
	else
		to_chat(user, "<span class='warning'>[I] не подходит для ремонта повреждённой проводки!</span>")
// BLUEMOON ADD END

/datum/wound/burn/on_stasis()
	. = ..()
	// BLUEMOON ADD START - синтетические конечности не восстанавливаются в стазисе без ремонта
	if(synthetic_mode)
		return
	// BLUEMOON ADD END
	if(flesh_healing > 0)
		flesh_damage = max(0, flesh_damage - 0.2)
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>Ваша [limb.ru_name] была очищена от ожогов!</span>")
		qdel(src)
		return
	if(sanitization > 0)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE * 0.2)

/datum/wound/burn/on_synthflesh(amount)
	// BLUEMOON ADD START
	if(synthetic_mode)
		return
	// BLUEMOON ADD END
	flesh_healing += amount * 0.5 // 20u patch will heal 10 flesh standard

// we don't even care about first degree burns, straight to second
/datum/wound/burn/moderate
	name = "Second Degree Burns"
	ru_name = "Ожоги второй степени"
	ru_name_r = "ожогов второй степени"
	desc = "Пациент получил легкие ожоги, что привело к ослаблению целостности конечности и ощущению жжения."
	treat_text = "Нанести мазь или регенерирующую сетку на поврежденную область."
	examine_desc = "сильно обгорела и покрылась волдырями"
	occur_text = "шипит от образующихся красных ожоговых пятен"
	severity = WOUND_SEVERITY_MODERATE
	damage_mulitplier_penalty = 1.1
	threshold_minimum = 40
	threshold_penalty = 8 // burns cause significant decrease in limb integrity compared to other wounds
	status_effect_type = /datum/status_effect/wound/burn/moderate
	flesh_damage = 5
	scar_keyword = "burnmoderate"

// BLUEMOON ADD START
/datum/wound/burn/moderate/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Повреждение изоляции проводки"
		ru_name_r = "повреждения изоляции проводки"
		desc = "Изоляция проводов частично оплавлена, видны оголённые контакты. Риск лёгкого искрения."
		treat_text = "Заменить повреждённые кабели, очистить контакты кислотой, затем применить наногель для внутренних цепей."
		examine_desc = "оплавлена, видны оголённые провода с лёгким искрением"
		occur_text = "шипит от перегрева, изоляция плавится, пробегает слабая искра"
		infestation_rate = 0.02
		flesh_damage = 4
		exposed_wiring = 3
		short_circuit_risk = 1
		internal_damage = 2
		wound_flags = FLESH_WOUND
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/multitool, /obj/item/stack/medical/nanogel)
		treatable_tool = TOOL_WELDER
		synthetic_mode = TRUE
	return ..()
// BLUEMOON ADD END

/datum/wound/burn/severe
	name = "Third Degree Burns"
	ru_name = "Ожоги третьей степени"
	ru_name_r = "ожогов третьей степени"
	desc = "Пациент страдает от серьезных ожогов, ведущих к отмиранию тканей и ухудшению моторики."
	treat_text = "Немедленная дезинфекция и удаление некротической кожи с последующими обработкой мазью и перевязкой."
	examine_desc = "выглядит обугленной, с красными вкраплениями"
	occur_text = "быстро обугливается, обнажая потрескавшуюся кожу и плоть"
	severity = WOUND_SEVERITY_SEVERE
	damage_mulitplier_penalty = 1.2
	threshold_minimum = 75
	threshold_penalty = 10
	status_effect_type = /datum/status_effect/wound/burn/severe
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.05 // appx 13 minutes to reach sepsis without any treatment
	flesh_damage = 12.5
	scar_keyword = "burnsevere"

// BLUEMOON ADD START
/datum/wound/burn/severe/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Критическое повреждение проводки"
		ru_name_r = "критического повреждения проводки"
		desc = "Множество проводов оголено и повреждено. Частые короткие замыкания, нестабильная работа сервоприводов."
		treat_text = "Срочная замена кабелей, очистка контактов кислотой, затем наногель для внутренних цепей."
		examine_desc = "обуглена, из трещин видны искрящие пучки проводов"
		occur_text = "вспыхивает короткими замыканиями, разбрызгивая расплавленную изоляцию"
		infestation_rate = 0.04
		flesh_damage = 10
		exposed_wiring = 7
		short_circuit_risk = 3
		internal_damage = 5
		wound_flags = FLESH_WOUND
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/multitool, /obj/item/weldingtool, /obj/item/stack/medical/nanogel)
		treatable_tool = TOOL_WELDER
		synthetic_mode = TRUE
	return ..()
// BLUEMOON ADD END

/datum/wound/burn/critical
	name = "Catastrophic Burns"
	ru_name = "Ожоги четвертой степени"
	ru_name_r = "ожогов четвертой степени"
	desc = "Наблюдается практически полная потеря тканей и значительное обгорание костей и мышц пациента. Конечность может стать нефункциональной целиком."
	treat_text = "Немедленное хирургическое вмешательство. Удаление некроза, нанесение препаратов для восстановления тканей. Перевязывание конечности."
	examine_desc = "представляет собой месиво из костей, расплавленного жира и обугленных тканей"
	occur_text = "испаряется, пока плоть, кости и жир сплавляются в одну жуткую массу"
	severity = WOUND_SEVERITY_CRITICAL
	damage_mulitplier_penalty = 1.5
	sound_effect = 'sound/effects/wounds/sizzle2.ogg'
	threshold_minimum = 130
	threshold_penalty = 15
	status_effect_type = /datum/status_effect/wound/burn/critical
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.15 // appx 4.33 minutes to reach sepsis without any treatment
	flesh_damage = 20
	scar_keyword = "burncritical"

// BLUEMOON ADD START
/datum/wound/burn/critical/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Полный отказ проводки"
		ru_name_r = "полного отказа проводки"
		desc = "Проводка полностью выгорела. Постоянные короткие замыкания, конечность практически неработоспособна."
		treat_text = "Полная замена кабельной системы, капитальный ремонт цепей кислотой, наногель для восстановления. Только в мастерской."
		examine_desc = "представляет собой обгоревший клубок проводов с постоянными вспышками КЗ"
		occur_text = "взрывается каскадом коротких замыканий, разбрасывая искры и расплавленный пластик"
		infestation_rate = 0.08
		flesh_damage = 18
		exposed_wiring = 12
		short_circuit_risk = 6
		internal_damage = 10
		wound_flags = (FLESH_WOUND | MANGLES_FLESH)
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/multitool, /obj/item/weldingtool, /obj/item/stack/medical/nanogel)
		treatable_tool = TOOL_WELDER
		synthetic_mode = TRUE
	return ..()
// BLUEMOON ADD END
