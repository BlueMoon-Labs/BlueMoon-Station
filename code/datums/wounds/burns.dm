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

	// BLUEMOON ADD START - синтетическая конечность: оплавленная изоляция и перегрев цепей.
	/// Физический объём повреждённой проводки, который чинится кабелем (аналог flesh_damage)
	var/insulation_damage = 0
	/// Стартовый объём изоляции для расчёта прогресса при осмотре/сканере
	var/insulation_max = 0
	/// Перегрев цепей — растёт, пока проводка повреждена и не охлаждается; опасен, но уменьшается холодом/починкой (восстанавливаемо)
	var/overheat = 0
	/// Скорость роста перегрева по тяжести ожога (аналог infestation_rate)
	var/overheat_rate = 0
	/// Наногель нанесён — постепенно восстанавливает проводку, пока не исчерпается
	var/nanogel_active = FALSE
	/// Оставшийся ресурс наногеля (тики постепенного восстановления)
	var/nanogel_potency = 0
	// BLUEMOON ADD END

/datum/wound/burn/wound_injury(datum/wound/burn/old_wound = null)
	. = ..()

/datum/wound/burn/handle_process()
	. = ..()

	// Синтетическая конечность обрабатывается отдельно от органики
	if(limb.is_robotic_limb())
		handle_process_synthetic()
		return

	// Труп с инфекцией не борется: заражение - это реакция живых тканей. Лечение при этом
	// продолжает работать (санитайзеры, мазь, регенерирующая сетка ниже по проку), чтобы
	// медик мог обработать тело перед дефибрилляцией, а вот рост заражения, токсины,
	// потеря конечности и сообщения о ней на мёртвом теле останавливаются.
	var/reacting = !victim_appears_dead()

	if(strikes_to_lose_limb == 0)
		if(!reacting)
			return
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

	if(!reacting)
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

/// Обработка ожога синтетической конечности: перегрев цепей растёт со временем (опасность
/// по тяжести, как инфекция у органики), но полностью восстанавливается охлаждением и починкой.
/datum/wound/burn/proc/handle_process_synthetic()
	// Наногель постепенно восстанавливает проводку и слегка охлаждает цепи
	if(nanogel_active && nanogel_potency > 0)
		insulation_damage = max(0, insulation_damage - 0.5)
		overheat = max(0, overheat - 0.05)
		nanogel_potency -= 0.25
		if(prob(4))
			victim.visible_message("<span class='notice'>Наногель на [limb.ru_name_v] мягко светится, восстанавливая проводку.</span>")
		if(nanogel_potency <= 0)
			nanogel_active = FALSE
			to_chat(victim, "<span class='notice'>Наногель на [limb.ru_name_v] полностью исчерпан.</span>")

	// Починенная проводка больше не греется — конечность оживает, цепи остывают сами
	if(insulation_damage <= 0)
		disabling = FALSE
		overheat = max(0, overheat - 0.5)
		if(overheat <= 0)
			to_chat(victim, "<span class='green'>Повреждённая проводка на [limb.ru_name_v] восстановлена!</span>")
			qdel(src)
		return

	// Холод остужает повреждённые цепи, комнатный жар — продолжает разогревать их.
	if(victim.bodytemperature < (BODYTEMP_NORMAL - 10))
		overheat = max(0, overheat - 0.3)
	else
		overheat = min(6, overheat + overheat_rate)

	// Мёртвый синтетик не коротит дальше: гейт ниже по образцу органики
	var/reacting = !victim_appears_dead()
	if(!reacting)
		return

	// Перегрев отключает конечность, но это обратимо: остыла — снова слушается
	disabling = (overheat >= 4)

	switch(overheat)
		if(0 to 1)
			// стабильно, можно спокойно чинить кабелем
		if(1 to 2)
			if(prob(12))
				victim.visible_message("<span class='warning'>Из [limb.ru_name_v] персонажа [victim] пробегает слабая искра.</span>", "<span class='warning'>Вы чувствуете лёгкое покалывание в [limb.ru_name_v].</span>")
				do_sparks(rand(3, 5), FALSE, victim.loc)
		if(2 to 4)
			if(prob(15))
				victim.adjustFireLoss(0.3)
				do_sparks(rand(5, 8), FALSE, victim.loc)
			if(prob(10))
				to_chat(victim, "<span class='warning'>Сервоприводы [limb.ru_name_v] работают нестабильно из-за перегрева.</span>")
		if(4 to INFINITY)
			if(prob(25))
				victim.adjustFireLoss(0.6)
				do_sparks(rand(6, 10), FALSE, victim.loc)
			if(prob(10))
				victim.visible_message("<span class='danger'>Из [limb.ru_name_v] персонажа [victim] вырывается сноп искр!</span>", "<span class='userdanger'>Системы [limb.ru_name_v] аварийно отключаются от перегрева!</span>")

/// Описание проводки при осмотре синтетической конечности
/datum/wound/burn/proc/get_examine_description_synthetic(mob/user)
	var/insulation_left = insulation_max > 0 ? (insulation_damage / insulation_max) : 0
	var/wire_state
	if(insulation_left <= 0.25)
		wire_state = "проводка почти полностью выгорела"
	else if(insulation_left <= 0.6)
		wire_state = "проводка сильно оплавлена"
	else
		wire_state = "проводка частично оплавлена"
	var/heat_state
	if(overheat >= 4)
		heat_state = "<span class='danger'>из контактов бьют снопы искр от перегрева</span>"
	else if(overheat > 1)
		heat_state = "<span class='warning'>контакты ещё искрят от перегрева</span>"
	else
		heat_state = "<span class='notice'>цепи уже остыли</span>"
	return "<B>[victim.ru_ego(TRUE)] [limb.ru_name] [wire_state], [heat_state].</B>"

/// Показания сканера для синтетической конечности
/datum/wound/burn/proc/get_scanner_description_synthetic(mob/user)
	. = "Тип: [ru_name]\nТяжесть: [severity_text()]\n"
	. += "<div class='ml-3'>"
	. += "Повреждение проводки: [round(insulation_damage, 0.1)] ед.\n"
	. += "Перегрев цепей: [round(overheat, 0.1)]/6 ед.\n"
	if(nanogel_active)
		. += "Наногель: <span class='notice'>АКТИВЕН ([round(nanogel_potency, 0.1)] ед.)</span>\n"
	if(overheat >= 4)
		. += "Состояние: <span class='danger'>АВАРИЙНОЕ — конечность отключается, высокий нагрев.</span>\n"
	else if(overheat > 1)
		. += "Состояние: <span class='warning'>ПЕРЕГРЕВ — возможны искры и разряды при починке.</span>\n"
	else
		. += "Состояние: <span class='green'>СТАБИЛЬНО — безопасно восстанавливать кабелем.</span>\n"
	. += "Рекомендуемое лечение: [treat_text]\n"
	. += "Остудите конечность (холод/космос), затем восстановите провода кабелем.\n"
	. += "</div>"

/datum/wound/burn/get_examine_description(mob/user)
	if(limb.is_robotic_limb())
		return get_examine_description_synthetic(user)

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

/datum/wound/burn/get_scanner_description(mob/user)
	if(limb.is_robotic_limb())
		return get_scanner_description_synthetic(user)

	if(strikes_to_lose_limb == 0)
		var/oopsie = "Тип: [name]\nТяжесть: [severity_text()]"
		oopsie += "<div class='ml-3'>Степень инфекции: <span class='deadsay'>Полное заражение. Конечность утрачена. Немедленно ампутируйте или аугментируйте её.</span></div>"
		return oopsie

	. = ..()
	. += "<div class='ml-3'>"

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

/*
	new burn common procs
*/

/// if someone is using ointment on our burns
/datum/wound/burn/proc/ointment(obj/item/stack/medical/ointment/I, mob/user)
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
	if(!COOLDOWN_FINISHED(I, uv_cooldown))
		to_chat(user, "<span class='notice'>[I] ещё перезаряжается!</span>")
		return
	if(infestation <= 0 || infestation < sanitization)
		to_chat(user, "<span class='notice'>На конечности персонажа [victim] нет инфекции!</span>")
		return

	user.visible_message("<span class='notice'>[user] просвечивает ожоги персонажа [victim] с помощью [I].</span>", "<span class='notice'>Вы подсвечиваете ожоги [user == victim ? "на вашей конечности" : "конечности персонажа [victim]"] с помощью [I].</span>", vision_distance=COMBAT_MESSAGE_RANGE)
	sanitization += I.uv_power
	COOLDOWN_START(I, uv_cooldown, I.uv_cooldown_length)

/// Восстановление перегоревшей проводки на синтетической конечности кабелем.
/// Пока цепи перегреты, есть риск получить разряд; успех также снимает часть перегрева.
/datum/wound/burn/proc/reinsulate(obj/item/stack/cable_coil/I, mob/user)
	if(insulation_damage <= 0)
		to_chat(user, "<span class='notice'>Проводка на [limb.ru_name_v] персонажа [victim] уже восстановлена!</span>")
		return
	var/self_penalty_mult = (user == victim ? 1.4 : 1)
	// Чем тяжелее ожог, тем дольше возиться с проводкой
	var/treat_time = base_treat_time * severity * self_penalty_mult
	user.visible_message("<span class='notice'>[user] начинает восстанавливать обгоревшую проводку на [limb.ru_name_v] персонажа [victim] с помощью [I]...</span>", "<span class='notice'>Вы начинаете восстанавливать обгоревшую проводку на [user == victim ? "своей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, treat_time, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(insulation_damage <= 0)
		to_chat(user, "<span class='notice'>Проводка уже восстановлена!</span>")
		return
	if(overheat > 1 && prob(overheat * 15))
		user.visible_message("<span class='danger'>[user] задевает перегретую цепь на [limb.ru_name_v] персонажа [victim], и сноп искр бьёт в стороны!</span>", "<span class='danger'>Перегретая цепь на [user == victim ? "вашей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [victim]"] бьёт вас током — попытка сорвана!</span>")
		do_sparks(rand(5, 9), FALSE, victim.loc)
		limb.receive_damage(burn = 1 + severity, wound_bonus = CANT_WOUND)
		return
	user.visible_message("<span class='green'>[user] восстанавливает проводку на [limb.ru_name_v] персонажа [victim].</span>", "<span class='green'>Вы восстанавливаете проводку на [user == victim ? "своей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [victim]"].</span>")
	I.use(1)
	var/insulation_fixed = 5
	insulation_damage = max(0, insulation_damage - insulation_fixed)
	overheat = max(0, overheat - 1) // починка убирает источник нагрева
	limb.heal_damage(0, insulation_fixed, 0, TRUE, FALSE)
	if(insulation_damage > 0)
		try_treating(I, user)
	else
		to_chat(user, "<span class='green'>Вы полностью восстановили проводку на [user == victim ? "своей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [victim]"].</span>")
		qdel(src)

/// Альтернатива кабелю: наногель наносится один раз и дальше постепенно восстанавливает
/// проводку и охлаждает цепи, пока ресурс не исчерпается.
/datum/wound/burn/proc/nanogel_treatment(obj/item/stack/medical/nanogel/I, mob/user)
	if(nanogel_active)
		to_chat(user, "<span class='notice'>Наногель уже работает на [limb.ru_name_v] персонажа [victim]!</span>")
		return
	if(insulation_damage <= 0)
		to_chat(user, "<span class='notice'>Проводка на [limb.ru_name_v] персонажа [victim] уже восстановлена!</span>")
		return
	user.visible_message("<span class='notice'>[user] наносит наногель на [limb.ru_name_v] персонажа [victim]...</span>", "<span class='notice'>Вы наносите наногель на [user == victim ? "свою [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [victim]"]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	if(insulation_damage <= 0)
		to_chat(user, "<span class='notice'>Проводка уже восстановлена!</span>")
		return
	I.use(1)
	nanogel_active = TRUE
	nanogel_potency = 10
	user.visible_message("<span class='green'>[user] завершает обработку наногелем.</span>", "<span class='green'>Вы завершаете обработку наногелем.</span>")
	victim.visible_message("<span class='notice'>Наногель проникает в оплавленную проводку на [limb.ru_name_v] и начинает постепенное восстановление.</span>")

/// Обработка лечения синтетической конечности (отдельно от органики)
/datum/wound/burn/proc/treat_synthetic(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/cable_coil))
		reinsulate(I, user)
	else if(istype(I, /obj/item/stack/medical/nanogel))
		nanogel_treatment(I, user)
	else
		to_chat(user, "<span class='warning'>Проводку синтетической конечности восстанавливают кабелем или наногелем.")

/// Пока наногель уже работает, не перехватываем его — иначе он не достанется другой ране
/// (например, повреждению гидравлики) или штатной обработке внутренних порогов.
/datum/wound/burn/try_treating(obj/item/I, mob/user)
	if(limb.is_robotic_limb() && istype(I, /obj/item/stack/medical/nanogel) && nanogel_active)
		return FALSE
	return ..()

/datum/wound/burn/treat(obj/item/I, mob/user)
	if(limb.is_robotic_limb())
		treat_synthetic(I, user)
		return
	if(!check_armor_for_treatment(I, user))
		return
	if(istype(I, /obj/item/stack/medical/ointment))
		ointment(I, user)
	else if(istype(I, /obj/item/stack/medical/mesh))
		mesh(I, user)
	else if(istype(I, /obj/item/flashlight/pen/paramedic))
		uv(I, user)

/datum/wound/burn/on_stasis()
	. = ..()
	if(limb.is_robotic_limb())
		return
	if(flesh_healing > 0)
		flesh_damage = max(0, flesh_damage - 0.2)
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>Ваша [limb.ru_name] была очищена от ожогов!</span>")
		qdel(src)
		return
	if(sanitization > 0)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE * 0.2)

/datum/wound/burn/on_synthflesh(amount)
	if(limb.is_robotic_limb())
		return
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
		desc = "Изоляция проводов частично оплавлена, видны оголённые контакты."
		treat_text = "Восстановить провода кабелем или нанести наногель для постепенного восстановления."
		examine_desc = "оплавлена, видны оголённые провода"
		occur_text = "шипит от перегрева, изоляция плавится"
		infestation_rate = 0
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/stack/medical/nanogel)
		insulation_damage = flesh_damage
		insulation_max = flesh_damage
		overheat = 1
		overheat_rate = 0.01

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
		desc = "Проводка сильно оплавлена, частые короткие замыкания."
		treat_text = "Заменить провода кабелем или нанести наногель для постепенного восстановления."
		examine_desc = "обуглена, из трещин видны искрящие провода"
		occur_text = "вспыхивает короткими замыканиями, разбрызгивая расплавленную изоляцию"
		infestation_rate = 0
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/stack/medical/nanogel)
		insulation_damage = flesh_damage
		insulation_max = flesh_damage
		overheat = 2
		overheat_rate = 0.02

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
		desc = "Проводка выгорела, цепь конечности нестабильна."
		treat_text = "Полностью заменить проводку кабелем или нанести наногель для постепенного восстановления."
		examine_desc = "представляет собой обгоревший клубок проводов"
		occur_text = "взрывается каскадом коротких замыканий, разбрасывая искры"
		infestation_rate = 0
		treatable_by = list(/obj/item/stack/cable_coil, /obj/item/stack/medical/nanogel)
		insulation_damage = flesh_damage
		insulation_max = flesh_damage
		overheat = 3
		overheat_rate = 0.04

	return ..()
// BLUEMOON ADD END