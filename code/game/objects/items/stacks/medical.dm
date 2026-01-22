/obj/item/stack/medical
	name = "medical pack"
	singular_name = "medical pack"
	icon = 'icons/obj/stack_objects.dmi'
	amount = 12
	max_amount = 12
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	resistance_flags = FLAMMABLE
	max_integrity = 40
	novariants = FALSE
	item_flags = NOBLUDGEON
	var/self_delay = 50
	var/other_delay = 0
	var/repeating = FALSE
	/// Сколько физического урона лечим за применение
	var/heal_brute
	/// Сколько урона от ожогов лечим за применение
	var/heal_burn
	/// Насколько уменьшаем кровотечение за применение при порезах
	var/stop_bleeding
	/// Сколько санитизации применяем к ожогам за применение
	var/sanitization
	/// Сколько добавляем к flesh_healing для ожоговых ран за применение
	var/flesh_regeneration
	var/heal_dead = FALSE // можем ли мы лечить мёртвое тело
	var/heal_dead_multiplier = 1 // Эффективность лечения мёртвых

/obj/item/stack/medical/attack(mob/living/M, mob/user)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(begin_heal_loop), M, user, TRUE)

/// Используется для запуска рекурсивного цикла лечения. Возвращает TRUE если мы вошли в цикл, FALSE если нет
/obj/item/stack/medical/proc/begin_heal_loop(mob/living/patient, mob/living/user, auto_change_zone = TRUE)
	if(INTERACTING_WITH(user, patient))
		return FALSE
	if(iscarbon(patient))
		var/mob/living/carbon/carbon_patient = patient
		if(!has_healable_damage(carbon_patient))
			patient.balloon_alert(user, "нечего лечить")
			return FALSE

	var/heal_zone = check_zone(user.zone_selected)

	// Проверяем выбранную зону
	if(!try_heal_checks(patient, user, heal_zone, silent = TRUE))
		// Если выбранная зона не нуждается в лечении и включен автоматический режим
		if(iscarbon(patient) && auto_change_zone)
			// Ищем любую поврежденную часть тела
			var/mob/living/carbon/carbon_patient = patient
			var/list/damaged_limbs = list()
			for(var/obj/item/bodypart/limb as anything in carbon_patient.bodyparts)
				if(try_heal_checks(patient, user, limb.body_zone, silent = TRUE))
					damaged_limbs += limb.body_zone

			if(!length(damaged_limbs))
				if(carbon_patient.getBruteLoss_nonProsthetic() > 0 || carbon_patient.getFireLoss_nonProsthetic() > 0)
					return FALSE
				patient.balloon_alert(user, "полностью здоров[patient.ru_a()]")
				return FALSE

			// Берем первую поврежденную часть
			heal_zone = damaged_limbs[1]
			patient.balloon_alert(user, "лечим [ru_parse_zone(heal_zone)]...")
		else
			// В ручном режиме или для не-карбонов просто выходим
			return FALSE
	else
		// Выбранная часть тела повреждена, начинаем лечение
		pass()

	INVOKE_ASYNC(src, PROC_REF(try_heal), patient, user, heal_zone, FALSE, iscarbon(patient) && auto_change_zone)
	return TRUE

/**
 * Процедура, которая обрабатывает вывод сообщения о начале лечения и саму попытку лечения
 * Эта процедура рекурсивно вызывается, пока не закончатся заряды ИЛИ пока пациент не будет полностью вылечен
 * ИЛИ пока целевая зона не будет полностью вылечена (если auto_change_zone = FALSE)
 *
 * Аргументы:
 * * patient - моб, которого мы пытаемся вылечить
 * * user - моб, который пытается вылечить пациента
 * * healed_zone - зона, которую мы пытаемся вылечить на пациенте. Игнорируется если auto_change_zone = TRUE
 * * silent - если TRUE, не выводим сообщение о начале лечения пациента
 * * auto_change_zone - управляет поведением когда мы заканчиваем лечение зоны
 *   Если TRUE, выбирает следующую наиболее повреждённую зону. Если FALSE, даёт пользователю возможность выбрать новую зону
 * * continuous - если установлено в TRUE, будет проигрываться непрерывный звук лечения
 */
/obj/item/stack/medical/proc/try_heal(mob/living/patient, mob/living/user, healed_zone, silent = FALSE, auto_change_zone = TRUE, continuous = FALSE)
	if(patient == user)
		if(!silent)
			user.visible_message("<span class='notice'>[user] начинает наносить \the [src] на себя...</span>", "<span class='notice'>Вы начали наносить \the [src] на себя...</span>")
		if(!do_mob(user, patient, self_delay * (auto_change_zone ? 1 : 0.9), extra_checks=CALLBACK(src, PROC_REF(can_heal), patient, user, healed_zone)))
			return
		if(!auto_change_zone)
			healed_zone = check_zone(user.zone_selected)
		if(!try_heal_checks(patient, user, healed_zone))
			return
	else if(other_delay)
		if(!silent)
			user.visible_message("<span class='notice'>[user] начинает наносить \the [src] на [patient].</span>", "<span class='notice'>Вы начали наносить \the [src] на [patient]...</span>")
		if(!do_mob(user, patient, other_delay * (auto_change_zone ? 1 : 0.9), extra_checks=CALLBACK(src, PROC_REF(can_heal), patient, user, healed_zone)))
			return
		if(!auto_change_zone)
			healed_zone = check_zone(user.zone_selected)
		if(!try_heal_checks(patient, user, healed_zone))
			return
	else
		if(!silent)
			user.visible_message("<span class='notice'>[user] наносит \the [src] на [patient].</span>", "<span class='notice'>Вы наносите \the [src] на [patient].</span>")

	if(iscarbon(patient))
		if(!heal_carbon_new(patient, user, healed_zone))
			return
	else if(isanimal(patient))
		if(!heal_animal(patient, user))
			return
	else
		return

	if(!use(1) || !repeating || amount <= 0)
		return

	log_combat(user, patient, "healed", src.name)

	// first, just try looping - we can keep healing the current target or user changed their target
	var/preferred_target = check_zone(user.zone_selected)
	if(try_heal_checks(patient, user, preferred_target, silent = TRUE))
		if(preferred_target != healed_zone)
			patient.balloon_alert(user, "переключаем на [ru_parse_zone(preferred_target)]...")
		try_heal(patient, user, preferred_target, TRUE, auto_change_zone, TRUE)
		return

	// second, handle what happens otherwise
	if(!iscarbon(patient))
		// behavior 0: non-carbons have no limbs so we can assume they are fully healed
		patient.balloon_alert(user, "полностью вылечен[patient.ru_a()]")
	else if(auto_change_zone)
		// behavior 1: automatically pick another zone to heal
		try_heal_auto_change_zone(patient, user, preferred_target, healed_zone)
	else
		// behavior 2: assess injury, giving the user time to manually pick another zone
		try_heal_manual_target(patient, user)

/obj/item/stack/medical/proc/try_heal_auto_change_zone(mob/living/carbon/patient, mob/living/user, preferred_target, last_zone)
	var/list/other_affected_limbs = list()
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		if(!try_heal_checks(patient, user, limb.body_zone, silent = TRUE))
			continue
		other_affected_limbs += limb.body_zone

	if(!length(other_affected_limbs))
		if(patient.getBruteLoss_nonProsthetic() > 0 || patient.getFireLoss_nonProsthetic() > 0)
			return
		patient.balloon_alert(user, "полностью вылечен[patient.ru_a()]")
		return

	var/next_picked = (preferred_target in other_affected_limbs) ? preferred_target : other_affected_limbs[1]
	if(next_picked != last_zone)
		patient.balloon_alert(user, "переключаем на [ru_parse_zone(next_picked)]...")
	try_heal(patient, user, next_picked, silent = TRUE, auto_change_zone = TRUE, continuous = TRUE)

/obj/item/stack/medical/proc/try_heal_manual_target(mob/living/carbon/patient, mob/living/user)
	patient.balloon_alert(user, "оцениваем состояние...")
	if(!do_after(user, 1 SECONDS, patient))
		return
	var/new_zone = check_zone(user.zone_selected)
	if(!try_heal_checks(patient, user, new_zone))
		return
	patient.balloon_alert(user, "лечим [ru_parse_zone(new_zone)]...")
	try_heal(patient, user, new_zone, silent = TRUE, auto_change_zone = FALSE, continuous = TRUE)


/obj/item/stack/medical/proc/can_heal(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	return patient.can_inject(user, !silent)

/obj/item/stack/medical/proc/has_healable_damage(mob/living/carbon/patient)
	if(heal_brute && patient.getBruteLoss_nonProsthetic() > 0)
		return TRUE
	if(heal_burn && patient.getFireLoss_nonProsthetic() > 0)
		return TRUE

	if((stop_bleeding || flesh_regeneration || sanitization) && LAZYLEN(patient.all_wounds))
		return TRUE

	return FALSE

/// Проверяет множество условий для определения возможности лечения пациента, включая can_heal
/// Даёт обратную связь если мы не можем вылечить пациента (если только silent не TRUE)
/obj/item/stack/medical/proc/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!can_heal(patient, user, healed_zone, silent))
		return FALSE

	if(!heal_dead && patient.stat == DEAD)
		if(!silent)
			to_chat(user, "<span class='warning'>[patient] мертв[patient.ru_a()]! Вы не можете [patient.ru_emu()] помочь.</span>")
		return FALSE

	if(iscarbon(patient))
		var/mob/living/carbon/carbon_patient = patient
		var/obj/item/bodypart/affecting = carbon_patient.get_bodypart(healed_zone)
		if(!affecting)
			if(!silent)
				to_chat(user, "<span class='warning'>У [patient] отсутствует \a [ru_parse_zone(healed_zone)]!</span>")
			return FALSE
		if(!affecting.is_organic_limb(FALSE))
			if(!silent)
				to_chat(user, "<span class='notice'>\The [src] не сработает для механической конечности!</span>")
			return FALSE

		var/can_heal_brute = heal_brute && affecting.brute_dam > 0
		var/can_heal_burn = heal_burn && affecting.burn_dam > 0
		var/can_suture_bleeding = stop_bleeding && LAZYLEN(affecting.wounds)
		var/can_heal_burn_wounds = (flesh_regeneration || sanitization) && LAZYLEN(affecting.wounds)

		if(!can_heal_brute && !can_heal_burn && !can_heal_burn_wounds && !can_suture_bleeding)
			if(!silent)
				if(!can_heal_brute && stop_bleeding)
					to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [patient] не требует перевязки или лечения ушибов!</span>")
				else if(!can_heal_burn && (flesh_regeneration || sanitization))
					to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [patient] полностью обработан[patient.ru_a()], дайте время на заживление!</span>")
				else if(!affecting.brute_dam && !affecting.burn_dam)
					to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [patient] не повреждён[patient.ru_a()]!</span>")
				else
					to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [patient] нельзя вылечить при помощи \the [src].</span>")
			return FALSE
		return TRUE

	if(isanimal(patient))
		if(!heal_brute)
			if(!silent)
				to_chat(user, "<span class='warning'>Вы не можете вылечить [patient] при помощи \the [src]!</span>")
			return FALSE
		var/mob/living/simple_animal/critter = patient
		if(!critter.healable)
			if(!silent)
				to_chat(user, "<span class='notice'>Вы не можете применить \the [src] на [patient]!</span>")
			return FALSE
		if(critter.health == critter.maxHealth)
			if(!silent)
				to_chat(user, "<span class='notice'>[patient] полностью здоров[patient.ru_a()].</span>")
			return FALSE
		return TRUE

	return FALSE

/obj/item/stack/medical/proc/heal_carbon_new(mob/living/carbon/C, mob/user, healed_zone)
	var/efficiency = 1
	if(C.stat == DEAD)
		efficiency = heal_dead_multiplier

	var/obj/item/bodypart/affecting = C.get_bodypart(healed_zone)
	if(!affecting)
		return FALSE

	if(!affecting.is_organic_limb(FALSE))
		return FALSE

	var/healed_something = FALSE

	if((affecting.brute_dam && heal_brute) || (affecting.burn_dam && heal_burn))
		user.visible_message("<span class='green'>[user] наносит \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>", "<span class='green'>Вы наносите \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>")
		if(affecting.heal_damage(heal_brute*efficiency, heal_burn*efficiency))
			C.update_damage_overlays()
		healed_something = TRUE

	if(LAZYLEN(affecting.wounds))
		for(var/datum/wound/iter_wound as anything in affecting.wounds)
			if(stop_bleeding > 0 && (istype(iter_wound, /datum/wound/slash) || istype(iter_wound, /datum/wound/pierce)))
				iter_wound.blood_flow -= stop_bleeding * efficiency
				if(!healed_something)
					user.visible_message("<span class='green'>[user] обрабатывает раны на [ru_kogo_zone(affecting.name)] [C].</span>", "<span class='green'>Вы обрабатываете раны на [ru_kogo_zone(affecting.name)] [C].</span>")
				healed_something = TRUE

			if((flesh_regeneration > 0 || sanitization > 0) && istype(iter_wound, /datum/wound/burn))
				var/datum/wound/burn/burn_wound = iter_wound
				if(flesh_regeneration > 0)
					burn_wound.flesh_healing += flesh_regeneration * efficiency
				if(sanitization > 0)
					burn_wound.sanitization += sanitization * efficiency
				if(!healed_something)
					user.visible_message("<span class='green'>[user] обрабатывает раны на [ru_kogo_zone(affecting.name)] [C].</span>", "<span class='green'>Вы обрабатываете раны на [ru_kogo_zone(affecting.name)] [C].</span>")
				healed_something = TRUE

	return healed_something

/obj/item/stack/medical/proc/heal_animal(mob/living/simple_animal/M, mob/user)
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			return FALSE
		efficiency = heal_dead_multiplier

	if(!M.healable)
		return FALSE
	if(M.health == M.maxHealth)
		return FALSE

	user.visible_message("<span class='green'>[user] наносит \the [src] на [M].</span>", "<span class='green'>Вы наносите \the [src] на [M].</span>")
	if(AmBloodsucker(M))
		return TRUE
	M.heal_bodypart_damage((heal_brute/2)*efficiency)
	return TRUE

/obj/item/stack/medical/proc/heal(mob/living/M, mob/user)
	return

/obj/item/stack/medical/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")

/obj/item/stack/medical/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "Терапевтическая упаковка геля и повязок для работы с травмами от тупых предметов."
	icon_state = "brutepack"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	heal_brute = 40
	self_delay = 40
	other_delay = 20
	grind_results = list(/datum/reagent/medicine/styptic_powder = 10)

/obj/item/stack/medical/bruise_pack/one
	amount = 1

/obj/item/stack/medical/bruise_pack/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is bludgeoning себя with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (BRUTELOSS)

/obj/item/stack/medical/gauze
	name = "medical gauze"
	desc = "Моток эластичной ткани, идеальной для стабилизации любых видов ранений, от порезов до ожогов и переломов костей."
	gender = PLURAL
	singular_name = "medical gauze"
	icon_state = "gauze"
	heal_brute = 5
	self_delay = 50
	other_delay = 20
	amount = 15
	max_amount = 15
	absorption_rate = 0.25
	absorption_capacity = 5
	splint_factor = 0.35
	custom_price = PRICE_REALLY_CHEAP
	grind_results = list(/datum/reagent/cellulose = 2)

// Марля актуальна только для ран, которые обрабатываются самими ранами
/obj/item/stack/medical/gauze/try_heal(mob/living/M, mob/user, healed_zone, silent = FALSE, auto_change_zone = TRUE, continuous = FALSE)
	var/obj/item/bodypart/limb = M.get_bodypart(check_zone(user.zone_selected))
	if(!limb)
		to_chat(user, "<span class='notice'>Нечего перевязывать!</span>")
		return
	if(!LAZYLEN(limb.wounds))
		to_chat(user, "<span class='notice'>[user==M ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [M]"] не требует перевязки!</span>")
		return

	var/gauzeable_wound = FALSE
	for(var/i in limb.wounds)
		var/datum/wound/woundies = i
		if(woundies.wound_flags & ACCEPTS_GAUZE)
			gauzeable_wound = TRUE
			break
	if(!gauzeable_wound)
		to_chat(user, "<span class='notice'>[user==M ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [M]"] не требует перевязки!</span>")
		return

	if(limb.current_gauze && (limb.current_gauze.absorption_capacity * 0.8 > absorption_capacity)) // игнорируем если новая повязка меньше чем на 20% лучше текущей, чтобы кто-то не перевязывал её 5 раз подряд
		to_chat(user, "<span class='warning'>Повязка, что наложена на [user==M ? "вашей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа[M]"], пока ещё хорошем состоянии!</span>")
		return

	user.visible_message("<span class='warning'>[user] пытается перевязать рану на [limb.ru_name_v] персонажа [M] с помощью [src]...</span>", "<span class='warning'>Вы пытаетесь перевязать раны на [user == M ? "вашей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [M]"] с помощью [src]...</span>")

	if(!do_after(user, (user == M ? self_delay : other_delay), target=M))
		return

	user.visible_message("<span class='green'>[user] наносит [src] на конечность персонажа [M]</span>", "<span class='green'>Вы пытаетесь перевязать раны на [user == M ? "своей конечности" : "конечности персонажа [M]"].</span>")
	limb.apply_gauze(src)

/obj/item/stack/medical/gauze/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER || I.get_sharpness())
		if(get_amount() < 2)
			to_chat(user, "<span class='warning'>Вам необходимо как минимум две марлевых повязки!</span>")
			return
		new /obj/item/stack/sheet/cloth(user.drop_location())
		user.visible_message("[user] разрезает [src] на части с помощью [I].", \
					 "<span class='notice'>Вы разрезаете [src] на части с помощью [I].</span>", \
					 "<span class='italics'>Вы слышите звук разрезания ткани.</span>")
		use(2)
	else if(I.is_drainable() && I.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine))
		if(!I.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine, 5))
			to_chat(user, "<span class='warning'>Не хватает стерилизина в [I], чтобы обработать [src]!</span>")
			return
		user.visible_message("<span class='notice'>[user] обрабатывает [src] с помощью содержимого [I].</span>", "<span class='notice'>Вы выливаете содержимое [I] на [src], обрабатывая это.</span>")
		I.reagents.remove_reagent(/datum/reagent/space_cleaner/sterilizine, 5)
		new /obj/item/stack/medical/gauze/adv/one(user.drop_location())
		use(1)
	else
		return ..()

/obj/item/stack/medical/gauze/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] пытается обвязать \the [src] вокруг [user.ru_ego()] шеи! Похоже, [user.ru_who()] не совсем понимает, как пользоваться медикаментами!</span>")
	return OXYLOSS

/obj/item/stack/medical/gauze/one
	amount = 1

/obj/item/stack/medical/gauze/improvised
	name = "improvised gauze"
	singular_name = "improvised gauze"
	heal_brute = 0
	desc = "Моток грубо обрезанной ткани от чего-то делавшего хорошую работу в стабилизации ран. Делает это не так хорошо, чем полноценная повязка."
	self_delay = 60
	other_delay = 30
	absorption_rate = 0.15
	absorption_capacity = 4
	splint_factor = 0.15

/obj/item/stack/medical/gauze/adv
	name = "sterilized medical gauze"
	singular_name = "sterilized medical gauze"
	desc = "Моток эластичной стерилизованной ткани. Экстремально эффективна для остановки кровотечений и стабилизации ожогов."
	heal_brute = 7
	self_delay = 45
	other_delay = 15
	absorption_rate = 0.5
	absorption_capacity = 12
	splint_factor = 0.5

/obj/item/stack/medical/gauze/adv/one
	amount = 1

/obj/item/stack/medical/gauze/cyborg
	custom_materials = null
	is_cyborg = TRUE
	source = /datum/robot_energy_storage/medical
	cost = 250

/obj/item/stack/medical/suture
	name = "suture"
	desc = "Стандартная стерилизованная нить для закрытия порезов, рваных ран и остановок кровотечения."
	gender = PLURAL
	singular_name = "suture"
	icon_state = "suture"
	self_delay = 30
	other_delay = 10
	amount = 15
	max_amount = 15
	repeating = TRUE
	heal_brute = 13
	stop_bleeding = 0.6
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/suture/emergency
	name = "emergency suture"
	desc = "Моток дешёвой нити, не очень хорошей для латания ран, но неплохо подходящей против кровотечений."
	heal_brute = 10
	amount = 5
	max_amount = 5

/obj/item/stack/medical/suture/one
	amount = 1

/obj/item/stack/medical/suture/five
	amount = 5

/obj/item/stack/medical/suture/medicated
	name = "medicated suture"
	icon_state = "suture_purp"
	desc = "Нить, смоченная в лекарствах, помогающих в заживлении самых тяжёлых рваных ран."
	heal_brute = 20
	stop_bleeding = 1
	grind_results = list(/datum/reagent/medicine/polypyr = 2)
	heal_dead = TRUE
	heal_dead_multiplier = 0.65

/obj/item/stack/medical/suture/medicated/one
	amount = 1

/obj/item/stack/medical/suture/one
	amount = 1

/obj/item/stack/medical/ointment
	name = "ointment"
	desc = "Стандартная мазь от ожогов, вполне эфффективная против ожогов второй степени при бинтовании, впрочем, также стабилизирует и более серьёзные ожоги. Не прям хороша для полного заживления ожогов."
	gender = PLURAL
	singular_name = "ointment"
	icon_state = "ointment"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount = 12
	max_amount = 12
	self_delay = 40
	other_delay = 20

	heal_burn = 10
	flesh_regeneration = 2.5
	sanitization = 0.4
	grind_results = list(/datum/reagent/medicine/kelotane = 10)

/obj/item/stack/medical/ointment/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] выдавливает \the [src] в свой рот! Он[user.ru_a()] вообще знает, что оно ядовито?!</span>")
	return TOXLOSS

/obj/item/stack/medical/mesh
	name = "regenerative mesh"
	desc = "Бактерицидная сетка для оборачивания ожогов."
	gender = PLURAL
	singular_name = "regenerative mesh"
	icon_state = "regen_mesh"
	self_delay = 30
	other_delay = 10
	amount = 15
	max_amount = 15
	heal_burn = 13
	repeating = TRUE
	sanitization = 0.75
	flesh_regeneration = 3
	var/is_open = TRUE /// Эта переменная определяет, была ли открыта стерильная упаковка сетки.
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/mesh/one
	amount = 1

/obj/item/stack/medical/mesh/five
	amount = 5

/obj/item/stack/medical/mesh/advanced
	name = "advanced regenerative mesh"
	desc = "Продвинутая стека со смесью экстракта алоэ и стрелизирующих агентов, для работы с ожогами."
	gender = PLURAL
	singular_name = "advanced regenerative mesh"
	icon_state = "aloe_mesh"
	heal_burn = 20
	sanitization = 1.25
	flesh_regeneration = 5
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	heal_dead = TRUE
	heal_dead_multiplier = 0.65

/obj/item/stack/medical/mesh/advanced/one
	amount = 1

/obj/item/stack/medical/mesh/Initialize(mapload)
	. = ..()
	if(amount == max_amount)	 // запечатываем только полные упаковки сетки
		is_open = FALSE
		update_icon()

/obj/item/stack/medical/mesh/advanced/update_icon_state()
	if(!is_open)
		icon_state = "aloe_mesh_closed"
	else
		return ..()

/obj/item/stack/medical/mesh/update_icon_state()
	if(!is_open)
		icon_state = "regen_mesh_closed"
	else
		return ..()

/obj/item/stack/medical/mesh/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!is_open)
		if(!silent)
			to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return FALSE
	return ..()

/obj/item/stack/medical/mesh/AltClick(mob/living/user)
	if(!is_open)
		to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return
	. = ..()

/obj/item/stack/medical/mesh/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!is_open && (user.get_inactive_held_item() == src))
		to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return
	. = ..()

/obj/item/stack/medical/mesh/attack_self(mob/user)
	if(!is_open)
		is_open = TRUE
		to_chat(user, "<span class='notice'>Вы раскрыли упакопку стерильной сетки.</span>")
		update_icon()
		playsound(src, 'sound/items/poster_ripped.ogg', 20, TRUE)
		return
	. = ..()

/obj/item/stack/medical/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "Сильнодействующий медицинский гель, при правильном применении на повреждённую кость провоцирует интенсивную реакцию сращивания костных тканей. Может быть применён напрямую, как и хирургическая лента, напрямую на кость в крайнем случае, что, впрочем, очень вредно пациенту и не рекомендуется."

	icon = 'icons/obj/surgery.dmi'
	icon_state = "bone-gel"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

	amount = 4
	self_delay = 20
	grind_results = list(/datum/reagent/medicine/bicaridine = 10)
	novariants = TRUE

/obj/item/stack/medical/bone_gel/attack(mob/living/M, mob/user)
	to_chat(user, "<span class='warning'>Костный гель может быть применён только на раздробленные конечности в [span_red("агрессивном")] хвате!</span>")
	return

/obj/item/stack/medical/bone_gel/suicide_act(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.visible_message("<span class='suicide'>[C] выдавливает весь \the [src] внутрь своего рта! Это не правильное применение! Похоже, что [C.ru_who()] пытается совершить суицид!</span>")
		if(do_after(C, 2 SECONDS))
			C.emote("realagony")
			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				var/datum/wound/blunt/severe/oof_ouch = new
				oof_ouch.apply_wound(bone)
				var/datum/wound/blunt/critical/oof_OUCH = new
				oof_OUCH.apply_wound(bone)

			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				bone.receive_damage(brute=60)
			use(1)
			return (BRUTELOSS)
		else
			C.visible_message("<span class='suicide'>[C] проваливает затею как идиот и всё равно умудряется сдохнуть!</span>")
			return (BRUTELOSS)

/obj/item/stack/medical/bone_gel/cyborg
	custom_materials = null
	is_cyborg = TRUE
	source = /datum/robot_energy_storage/medical
	cost = 250

/obj/item/stack/medical/aloe
	name = "aloe cream"
	desc = "Лечащая паста для открытых ран."

	icon_state = "aloe_paste"
	self_delay = 20
	other_delay = 10
	novariants = TRUE
	amount = 20
	max_amount = 20
	var/heal = 3
	heal_brute = 3
	heal_burn = 3
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)

/obj/item/stack/medical/nanogel
	name = "nanogel"
	singular_name = "nanogel"
	desc = "Высокотехнологичный гель, при применении на отремонтированную снаружи роботическую конечность - нейтрализует остаточные внутренние повреждения, позволяя дальнейшее обслуживание без хирургии."
	self_delay = 150	// Мучительно медленно при использовании на себе, но не полностью запрещено, потому что антагонистам с роболимбами нужен способ справляться с порогами.
	other_delay = 30	// Довольно быстро при использовании на других.
	amount = 12
	max_amount = 12	// Две синтетические конечности стоит починки, если каждая часть тела имеет внутренние повреждения. Обычно, вероятно, больше 6-12.
	icon_state = "nanogel"
	var/being_applied = FALSE	// Запрет на накопление doafter.

/obj/item/stack/medical/nanogel/one
	amount = 1

/obj/item/stack/medical/nanogel/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!iscarbon(patient))
		if(!silent)
			to_chat(user, "<span class='warning'>Оно не поможет [patient]!</span>")
		return FALSE
	return ..()

/obj/item/stack/medical/nanogel/heal_carbon_new(mob/living/carbon/C, mob/user, healed_zone)
	if(!C)
		return FALSE
	var/obj/item/bodypart/affecting = C.get_bodypart(healed_zone)
	if(!affecting) // Отсутствует конечность?
		to_chat(user, "<span class='warning'>[C] не имеет \a [ru_parse_zone(healed_zone)]!</span>")
		return FALSE
	if(!affecting.is_robotic_limb())
		to_chat(user, "<span class='warning'>Это не поможет нероботическим конечностям!</span>")
		return FALSE
	if(!affecting.threshhold_brute_passed && !affecting.threshhold_burn_passed)
		to_chat(user, "<span class='warning'>Нет нужды намазывать гель на [affecting].</span>")
		return FALSE
	if(affecting.threshhold_brute_passed && affecting.brute_dam == affecting.threshhold_passed_mindamage)
		. = TRUE
		affecting.threshhold_brute_passed = FALSE
	if(affecting.threshhold_burn_passed && affecting.burn_dam == affecting.threshhold_passed_mindamage)
		. = TRUE
		affecting.threshhold_burn_passed = FALSE
	if(.)
		user.visible_message("<span class='green'>Наногель вступает в реакцию на теле [C], ремонтируя внутренние повреждения [affecting].</span>", "<span class='green'>Вы наблюдаете как наногель начинает работу по ремонту внутренних повреждений [affecting]</span>")
		return TRUE
	// Если дошли сюда: Провал, давайте скажем пользователю почему.
	to_chat(user, "<span class='warning'>[src] терпит неудачу в с [affecting] из-за остаточного урона [(affecting.threshhold_brute_passed && affecting.threshhold_burn_passed) ? "травм и ожогов" : "[affecting.threshhold_burn_passed ? "ожогами" : "травмами"]"]! Проведите внешне обслуживание перед применением.</span>")
	return FALSE
