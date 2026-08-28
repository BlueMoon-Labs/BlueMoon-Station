
/mob/living/proc/run_armor_check(def_zone = null, attack_flag = MELEE, absorb_text = "Your armor absorbs the blow!", soften_text = "Your armor softens the blow!", armour_penetration, penetrated_text = "Your armor was penetrated!", silent=FALSE)
	var/armor = getarmor(def_zone, attack_flag)

	// BLUEMOON ADD START - characters_size_changes - броня хуже работает на персонажей большого размера
	var/user_size_armor_reduction = get_size(src)
	if(user_size_armor_reduction > 1)
		if(attack_flag in list(MELEE, BULLET, LASER)) // было бы смешно, если бы защита от размера не работала бы от радиации, потому что вы порвали рад костюм . . .
			if(!HAS_TRAIT(src, TRAIT_BLUEMOON_DEVOURER) && mob_weight > MOB_WEIGHT_LIGHT) // у пожирателей и лёгких уже дебаф к ХП, для них исключение
				user_size_armor_reduction = min(user_size_armor_reduction, 1.75) // Смайли сказал, что убирать всю броню слишком жёстко, потому работает 25% от изначальной брони, если размер более 175%
				armor = armor * (2 - user_size_armor_reduction) // За каждый % увеличения размера, броня работает на % хуже. Вплоть до того, что персонажи с размером +175% получают только 25% брони. Сделано для компенсации факта, что от увеличения размера уже повышается ХП, которое сродни наличию брони
	// BLUEMOON ADD END

	if(silent)
		return max(0, armor - armour_penetration)

	//the if "armor" check is because this is used for everything on /living, including humans
	if(armor && armour_penetration)
		armor = max(0, armor - armour_penetration)
		if(penetrated_text)
			to_chat(src, "<span class='danger'>[penetrated_text]</span>")
	else if(armor >= 100)
		if(absorb_text)
			to_chat(src, "<span class='danger'>[absorb_text]</span>")
	else if(armor > 0)
		if(soften_text)
			to_chat(src, "<span class='danger'>[soften_text]</span>")
	return armor


/mob/living/proc/getarmor(def_zone, type)
	return FALSE

//this returns the mob's protection against eye damage (number between -1 and 2) from bright lights
/mob/living/proc/get_eye_protection()
	return FALSE

//this returns the mob's protection against ear damage (0:no protection; 1: some ear protection; 2: has no ears)
/mob/living/proc/get_ear_protection()
	return FALSE

/mob/living/proc/is_mouth_covered(head_only = 0, mask_only = 0)
	return FALSE

/mob/living/proc/is_eyes_covered(check_glasses = 1, check_head = 1, check_mask = 1)
	return FALSE

/mob/living/proc/on_hit(obj/item/projectile/P)
	return BULLET_ACT_HIT

/mob/living/proc/handle_projectile_attack_redirection(obj/item/projectile/P, redirection_mode, silent = FALSE)
	P.ignore_source_check = TRUE
	switch(redirection_mode)
		if(REDIRECT_METHOD_DEFLECT)
			P.setAngle(SIMPLIFY_DEGREES(P.Angle + rand(120, 240)))
			if(!silent)
				visible_message("<span class='danger'>[P] gets deflected by [src]!</span>", \
					"<span class='userdanger'>You deflect [P]!</span>")
		if(REDIRECT_METHOD_REFLECT)
			P.setAngle(SIMPLIFY_DEGREES(P.Angle + 180))
			if(!silent)
				visible_message("<span class='danger'>[P] gets reflected by [src]!</span>", \
					"<span class='userdanger'>You reflect [P]!</span>")
		if(REDIRECT_METHOD_PASSTHROUGH)
			if(!silent)
				visible_message("<span class='danger'>[P] passes through [src]!</span>", \
					"<span class='userdanger'>[P] passes through you!</span>")
			return
		if(REDIRECT_METHOD_RETURN_TO_SENDER)
			if(!silent)
				visible_message("<span class='danger'>[src] deflects [P] back at their attacker!</span>", \
					"<span class='userdanger'>You deflect [P] back at your attacker!</span>")
			if(P.firer)
				P.setAngle(Get_Angle(src, P.firer))
			else
				P.setAngle(SIMPLIFY_DEGREES(P.Angle + 180))
		else
			CRASH("Invalid rediretion mode [redirection_mode]")

/mob/living/bullet_act(obj/item/projectile/P, def_zone, piercing_hit = FALSE)
	var/totaldamage = P.damage
	var/final_percent = 0
	if(P.original != src || P.firer != src)
		var/list/returnlist = list()
		var/returned = mob_run_block(P, P.damage, "the [P.name]", ATTACK_TYPE_PROJECTILE, P.armour_penetration, P.firer, def_zone, returnlist)
		final_percent = returnlist[BLOCK_RETURN_PROJECTILE_BLOCK_PERCENTAGE]
		if(returned & BLOCK_SHOULD_REDIRECT)
			handle_projectile_attack_redirection(P, returnlist[BLOCK_RETURN_REDIRECT_METHOD])
			return BULLET_ACT_FORCE_PIERCE
		if(returned & BLOCK_REDIRECTED)
			return BULLET_ACT_FORCE_PIERCE
		if(returned & BLOCK_SUCCESS)
			P.on_hit(src, final_percent, def_zone, piercing_hit)
			return BULLET_ACT_BLOCK
		totaldamage = block_calculate_resultant_damage(totaldamage, returnlist)

	var/armor = run_armor_check(def_zone, P.flag, null, null, P.armour_penetration, null)

	// BLUEMOON ADD START - больших и тяжёлых существ проблематично нормально оглушить
	if(src.mob_weight > MOB_WEIGHT_HEAVY)
		if(P.damage_type == STAMINA)
			totaldamage *= 0.75
	// BLUEMOON ADD END

	if(!P.nodamage)
		// BLUEMOON ADD START - GAMMA two-bucket damage formula with randomization
		// Bucket 1: BR% — стандартная броня с рандомом ±30%
		// Bucket 2: BRC% — мультипликативная защита, только для BULLET
		var/armor_roll = armor * rand(70, 130) * 0.01

		// Минимальный урон 15 для расчёта — защита от слишком лёгкого поглощения дроби
		var/effective_damage_for_calc = max(P.damage, 15.0)

		// Шанс полного поглощения пули бронёй
		var/absorption_chance = 0
		if(P.flag == BULLET)
			absorption_chance = (armor_roll / effective_damage_for_calc) * 30
			absorption_chance = clamp(absorption_chance, 0, 85)
			// AP снижает шанс поглощения
			absorption_chance *= (1 - min(P.armour_penetration * 0.01, 0.9))
			// HP увеличивает шанс поглощения — броня лучше держит экспансивные пули
			if(P.armour_penetration < 0)
				absorption_chance *= (1 + min(abs(P.armour_penetration) * 0.005, 0.3))

		var/armor_factor = 1 - min(armor_roll * 0.01, 0.9)

		// BRC — второй бакет, только для пуль, снижается пробитием
		var/brc_factor = 1.0
		if(P.flag == BULLET)
			var/brc_effective = brc_mitigation * (1 - min(P.armour_penetration * 0.01, 1.0))
			var/brc_roll = brc_effective * rand(90, 110) * 0.01
			brc_factor = 1 - min(brc_roll * 0.01, 0.9)

		totaldamage = totaldamage * armor_factor * brc_factor
		var/absorbed_damage = P.damage - totaldamage

		// Проверка полного поглощения — либо математически либо через шанс
		var/fully_absorbed = (totaldamage < 1.0)
		if(!fully_absorbed && P.flag == BULLET && prob(absorption_chance))
			fully_absorbed = TRUE
			absorbed_damage = P.damage

		// BLUEMOON ADD START - overkill_ratio используется и для proc-шанса стамины, и для масштабирования заброневой травмы
		// Насколько броня "с запасом" гасит этот конкретный выстрел. 1.0 = впритык, выше = с запасом
		var/overkill_ratio = armor_roll / effective_damage_for_calc

		// Получаем bodypart для оценки текущего состояния зоны (заброневая травма масштабируется от него)
		var/obj/item/bodypart/hit_bodypart = null
		var/zone_damage_fraction = 0
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			hit_bodypart = H.get_bodypart(check_zone(def_zone))
			if(hit_bodypart && hit_bodypart.max_damage > 0)
				zone_damage_fraction = clamp(hit_bodypart.get_damage() / hit_bodypart.max_damage, 0, 1)
		// BLUEMOON ADD END

		if(fully_absorbed && P.flag == BULLET)
			// BLUEMOON EDIT START - stamina при полном поглощении: всегда, сила обратно
			// пропорциональна overkill_ratio. Диапазон 0.25-0.60:
			//   overkill=1.0 (впритык) → mult=0.60 → absorbed=30 → stamina=18
			//   overkill=3.5 (Джаггернаут) → mult=0.42 → absorbed=30 → stamina=12.7
			// Одна очередь 5 выстрелов даёт ~20-43% от порога падения (120 ед.)
			var/stamina_kinetic_mult = clamp(0.60 - ((overkill_ratio - 1.0) * 0.07), 0.25, 0.60)
			var/kinetic_stam = absorbed_damage * stamina_kinetic_mult
			if(kinetic_stam >= 1.0)
				apply_damage(kinetic_stam, STAMINA, def_zone, 0)
			// BLUEMOON EDIT END

			// BLUEMOON EDIT START - заброневая травма: фикс ролла перелома.
			// БЫЛО: apply_damage(1, BRUTE, ..., wound_bonus=kinetic_wound)
			//   При damage=1 и exponent=1.6: hi=round(1^1.6)=1, lo=max(1/1.5,25)=25
			//   BYOND инвертирует rand(25,1) → rand(1,25), среднее ~13
			//   Даже с wound_bonus=30 ролл ~43 — никогда не давало SEV/CRIT
			// СТАЛО: painless_wound_roll(WOUND_BLUNT, phantom_dmg, 0, 0)
			//   phantom_dmg = absorbed_damage / overkill_ratio
			//   Чем увереннее броня поглотила (высокий overkill), тем меньше удар по кости
			//   При absorbed=30, overkill=3.5 (Джаггернаут) → phantom≈8.6 → только MOD
			//   При absorbed=20, overkill=1.2 (Жилет СБ) → phantom≈17 → SEV 22%+
			var/wound_proc_chance = 0
			if(absorbed_damage >= 15)
				wound_proc_chance = 75 + (zone_damage_fraction * 25)
			else if(absorbed_damage >= 1)
				wound_proc_chance = 10 + (zone_damage_fraction * 50)

			if(wound_proc_chance > 0 && prob(wound_proc_chance) && hit_bodypart)
				var/phantom_dmg = absorbed_damage / max(overkill_ratio, 1.0)
				phantom_dmg = clamp(phantom_dmg, 0, WOUND_MAX_CONSIDERED_DAMAGE)
				if(phantom_dmg >= WOUND_MINIMUM_DAMAGE)
					hit_bodypart.painless_wound_roll(WOUND_BLUNT, phantom_dmg, 0, 0)
			// BLUEMOON EDIT END




		else
			// Частичное пробитие — остаточная кинетика от поглощённой части
			if(P.flag == BULLET && absorbed_damage >= 1.0)
				var/kinetic_stam = absorbed_damage * 0.40
				if(kinetic_stam >= 1.0)
					apply_damage(kinetic_stam, STAMINA, def_zone, 0)

				// BLUEMOON ADD START - заброневая травма при частичном пробитии.
				// Шанс растёт линейно с долей уже накопленного урона зоны — побитая конечность легче травмируется снова
				var/partial_wound_chance = 5 + (zone_damage_fraction * 35)
				if(prob(partial_wound_chance))
					var/partial_wound_bonus = round(absorbed_damage * 0.08)
					if(partial_wound_bonus > 0)
						P.wound_bonus += partial_wound_bonus
				// BLUEMOON ADD END

				// BLUEMOON ADD START - дополнительный НЕЗАВИСИМЫЙ шанс на перелом (WOUND_BLUNT) при частичном пробитии.
				// Пуля прошла навылет (PIERCE), но по касательной задела кость - оба ранения могут сосуществовать.
				// Используем painless_wound_roll т.к. урон по кости уже учтён через totaldamage ниже, нам нужен только сам ролл.
				if(hit_bodypart && absorbed_damage >= 1.0)
					var/bone_chip_chance = 8 + (zone_damage_fraction * 30) + (absorbed_damage * 0.4)
					bone_chip_chance = clamp(bone_chip_chance, 0, 60)
					if(prob(bone_chip_chance))
						hit_bodypart.painless_wound_roll(WOUND_BLUNT, max(absorbed_damage, WOUND_MINIMUM_DAMAGE), 0, 0)
				// BLUEMOON ADD END

			if(totaldamage >= 1.0)
				// BLUEMOON ADD START - частичное пробитие пулей оставляет пулевую дырку (WOUND_PIERCE), а не перелом,
				// если патрон сам не задавал sharpness явно (не перетираем дробь/спецбоеприпасы с осознанным SHARP_EDGED и т.п.)
				var/applied_sharpness = P.sharpness
				if(P.flag == BULLET && applied_sharpness == SHARP_NONE)
					applied_sharpness = SHARP_POINTY
				apply_damage(totaldamage, P.damage_type, def_zone, 0, wound_bonus = P.wound_bonus, bare_wound_bonus = P.bare_wound_bonus, sharpness = applied_sharpness)
				// BLUEMOON ADD END
				if(P.dismemberment)
					var/original_damage = P.damage
					P.damage = totaldamage
					check_projectile_dismemberment(P, def_zone)
					P.damage = original_damage
		// BLUEMOON ADD END

	// Пересчёт final_percent с учётом обоих бакетов для on_hit отображения
	var/missing = 100 - final_percent
	if(missing > 0)
		// BLUEMOON EDIT START - учитываем оба бакета в отображении блока
		var/armor_block_portion = missing * min(armor * 0.01, 0.9)
		var/after_armor = missing - armor_block_portion
		var/brc_block_portion = 0
		if(P.flag == BULLET)
			var/brc_effective_display = brc_mitigation * (1 - min(P.armour_penetration * 0.01, 1.0))
			brc_block_portion = after_armor * min(brc_effective_display * 0.01, 0.9)
		final_percent += armor_block_portion + brc_block_portion
		// BLUEMOON EDIT END

	return P.on_hit(src, final_percent, def_zone) ? BULLET_ACT_HIT : BULLET_ACT_BLOCK


/mob/living/proc/check_projectile_dismemberment(obj/item/projectile/P, def_zone)
	return FALSE

/obj/item/proc/get_volume_by_throwforce_and_or_w_class()
		if(throwforce && w_class)
				return clamp((throwforce + w_class) * 5, 30, 100)// Add the item's throwforce to its weight class and multiply by 5, then clamp the value between 30 and 100
		else if(w_class)
				return clamp(w_class * 8, 20, 100) // Multiply the item's weight class by 8, then clamp the value between 20 and 100
		else
				return FALSE

/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	var/zone = ran_zone(BODY_ZONE_CHEST, 65)//Hits a random part of the body, geared towards the chest
	if(!isitem(AM))
		// Filled with made up numbers for non-items.
		if(mob_run_block(AM, 30, "\the [AM.name]", ATTACK_TYPE_THROWN, 0, throwingdatum?.thrower, throwingdatum?.thrower?.zone_selected, list()) & BLOCK_SUCCESS)
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE
			return TRUE
		else
			playsound(loc, 'sound/weapons/genhit.ogg', 50, TRUE, -1) //Item sounds are handled in the item itself
		log_combat(AM, src, "hit ")
		return ..()

	var/obj/item/thrown_item = AM
	if(thrown_item.thrownby == WEAKREF(src)) //No throwing stuff at yourself to trigger hit reactions
		return ..()

	if(throwingdatum?.thrower)
		if(mob_run_block(AM, thrown_item.throwforce, "\the [thrown_item.name]", ATTACK_TYPE_THROWN, 0, throwingdatum.thrower, throwingdatum.thrower.zone_selected, list()))
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE
	else
		if(mob_run_block(AM, thrown_item.throwforce, "\the [thrown_item.name]", ATTACK_TYPE_THROWN, 0, null, zone, list()))
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE

	// zone moved up because things need it early while checking it from the thrower is unnecessary
	var/nosell_hit = SEND_SIGNAL(thrown_item, COMSIG_MOVABLE_IMPACT_ZONE, src, zone, throwingdatum, blocked, FALSE)
	if(nosell_hit)
		skipcatch = TRUE
		hitpush = FALSE

	if(blocked)
		return BLOCK_SUCCESS

	var/mob/thrown_by = thrown_item.thrownby?.resolve()
	if(thrown_by)
		log_combat(thrown_by, src, "threw and hit", thrown_item)
	else
		log_combat(thrown_item, src, "hit ")
	if(nosell_hit)
		return ..()
	visible_message(span_danger("[src] is hit by [thrown_item]!"), \
					span_userdanger("You're hit by [thrown_item]!"))
	if(!thrown_item.throwforce)
		return
	var/armor = run_armor_check(zone, MELEE, "Your armor has protected your [parse_zone(zone)].", "Your armor has softened hit to your [parse_zone(zone)].", thrown_item.armour_penetration, "", FALSE)
	apply_damage(thrown_item.throwforce, thrown_item.damtype, zone, armor, sharpness = thrown_item.get_sharpness(), wound_bonus = (nosell_hit * CANT_WOUND))
	if(QDELETED(src)) //Damage can delete the mob.
		return
	if(lying) // physics says it's significantly harder to push someone by constantly chucking random furniture at them if they are down on the floor.
		hitpush = FALSE
	return ..()

/mob/living/fire_act()
	adjust_fire_stacks(3)
	IgniteMob()

/mob/living/proc/grabbedby(mob/living/carbon/user, supress_message = FALSE)
	if(user == anchored || !isturf(user.loc))
		return FALSE

	//normal vore check.
	if(user.pulling && user.grab_state == GRAB_AGGRESSIVE && user.voremode)
		if(ismob(user.pulling))
			var/mob/P = user.pulling
			user.vore_attack(user, P, src) // User, Pulled, Predator target (which can be user, pulling, or src)
			return

	if(user == src) //we want to be able to self click if we're voracious
		return FALSE

	if(!user.pulling || user.pulling != src)
		user.start_pulling(src, supress_message = supress_message)
		return

	if(!(status_flags & CANPUSH) || HAS_TRAIT(src, TRAIT_PUSHIMMUNE))
		to_chat(user, "<span class='warning'>[src] can't be grabbed more aggressively!</span>")
		return FALSE

	if(user.grab_state >= GRAB_AGGRESSIVE && HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, "<span class='notice'>You don't want to risk hurting [src]!</span>")
		return FALSE

	grippedby(user)

//proc to upgrade a simple pull into a more aggressive grab.
/mob/living/proc/grippedby(mob/living/carbon/user, instant = FALSE)
	// Без активного pull этой цели (напр. сверхтяж: can_be_pulled вернул FALSE) нельзя повышать grab_state —
	// иначе у атакующего остаётся модификатор скорости «в грабе» без реальной цели (так ломает tackle с перчатками).
	if(user.pulling != src)
		return FALSE
	if(user.grab_state < GRAB_KILL)
		user.DelayNextAction(CLICK_CD_GRABBING, flush = TRUE)
		playsound(src, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

		if(user.grab_state) //only the first upgrade is instantaneous
			var/old_grab_state = user.grab_state
			var/grab_upgrade_time = instant ? 0 : 30
			visible_message("<span class='danger'>[user] starts to tighten [user.ru_ego()] grip on [src]!</span>", \
				"<span class='userdanger'>[user] starts to tighten [user.ru_ego()] grip on you!</span>", target = user,
				target_message = "<span class='danger'>You start to tighten your grip on [src]!</span>")
			switch(user.grab_state)
				if(GRAB_AGGRESSIVE)
					log_combat(user, src, "attempted to neck grab", addition="neck grab")
				if(GRAB_NECK)
					log_combat(user, src, "attempted to strangle", addition="kill grab")
			if(!do_mob(user, src, grab_upgrade_time))
				return FALSE
			if(!user.pulling || user.pulling != src || user.grab_state != old_grab_state || user.a_intent != INTENT_GRAB)
				return FALSE
			if(user.voremode && user.grab_state == GRAB_AGGRESSIVE)
				return FALSE
		user.setGrabState(user.grab_state + 1)
		switch(user.grab_state)
			if(GRAB_AGGRESSIVE)
				var/add_log = ""
				if(HAS_TRAIT(user, TRAIT_PACIFISM))
					visible_message("<span class='danger'>[user] has firmly gripped [src]!</span>",
						"<span class='danger'>[user] has firmly gripped you!</span>", target = user,
						target_message = "<span class='danger'>You have firmly gripped [src]!</span>")
					add_log = " (pacifist)"
				else
					visible_message("<span class='danger'>[user] has grabbed [src] aggressively!</span>", \
									"<span class='userdanger'>[user] has grabbed you aggressively!</span>", target = user, \
									target_message = "<span class='danger'>You have grabbed [src] aggressively!</span>")
					update_mobility()
				stop_pulling()
				log_combat(user, src, "grabbed", addition="aggressive grab[add_log]")
			if(GRAB_NECK)
				log_combat(user, src, "grabbed", addition="neck grab")
				visible_message("<span class='danger'>[user] has grabbed [src] by the neck!</span>",\
								"<span class='userdanger'>[user] has grabbed you by the neck!</span>", target = user, \
								target_message = "<span class='danger'>You have grabbed [src] by the neck!</span>")
				update_mobility() //we fall down
				if(!buckled && !density)
					Move(user.loc)
			if(GRAB_KILL)
				log_combat(user, src, "strangled", addition="kill grab")
				visible_message("<span class='danger'>[user] is strangling [src]!</span>", \
								"<span class='userdanger'>[user] is strangling you!</span>", target = user, \
								target_message = "<span class='danger'>You are strangling [src]!</span>")
				update_mobility() //we fall down
				if(!buckled && !density)
					Move(user.loc)
		user.set_pull_offsets(src, grab_state)
		return TRUE

/mob/living/on_attack_hand(mob/user, act_intent = user.a_intent, attackchain_flags)
	..() //Ignoring parent return value here.
	SEND_SIGNAL(src, COMSIG_MOB_ATTACK_HAND, user, act_intent)
	if((user != src) && act_intent != INTENT_HELP && (mob_run_block(user, 0, user.name, ATTACK_TYPE_UNARMED | ATTACK_TYPE_MELEE | ((attackchain_flags & ATTACK_IS_PARRY_COUNTERATTACK)? ATTACK_TYPE_PARRY_COUNTERATTACK : NONE), null, user, check_zone(user.zone_selected), null) & BLOCK_SUCCESS))
		log_combat(user, src, "attempted to touch")
		visible_message("<span class='warning'>[user] attempted to touch [src]!</span>",
			"<span class='warning'>[user] attempted to touch you!</span>", target = user,
			target_message = "<span class='warning'>You attempted to touch [src]!</span>")
		return TRUE

/mob/living/attack_hulk(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(user.a_intent == INTENT_HARM)
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			to_chat(user, "<span class='notice'>You don't want to hurt [src]!</span>")
			return TRUE
		var/hulk_verb = pick("smash","pummel")
		if(user != src && (mob_run_block(user, 15, "the [hulk_verb]ing", ATTACK_TYPE_MELEE, null, user, check_zone(user.zone_selected), null) & BLOCK_SUCCESS))
			return TRUE
		..()
	return FALSE

/mob/living/attack_slime(mob/living/simple_animal/slime/M)
	if(!SSticker.HasRoundStarted())
		to_chat(M, "You cannot attack people before the game has started.")
		return

	if(M.buckled)
		if(M in buckled_mobs)
			M.Feedstop()
		return // can't attack while eating!

	if(HAS_TRAIT(M, TRAIT_PACIFISM))
		to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
		return FALSE

	var/damage = rand(5, 35)
	if(M.is_adult)
		damage = rand(20, 40)
	var/list/block_return = list()
	if(mob_run_block(M, damage, "the [M.name]", ATTACK_TYPE_MELEE, null, M, check_zone(M.zone_selected), block_return) & BLOCK_SUCCESS)
		return FALSE
	damage = block_calculate_resultant_damage(damage, block_return)

	if (stat != DEAD)
		log_combat(M, src, "attacked")
		M.do_attack_animation(src)
		visible_message("<span class='danger'>The [M.name] glomps [src]!</span>", \
				"<span class='userdanger'>The [M.name] glomps [src]!</span>", null, COMBAT_MESSAGE_RANGE, null,
				M, "<span class='danger'>You glomp [src]!</span>")
		return TRUE

/mob/living/attack_animal(mob/living/simple_animal/M)
	M.face_atom(src)
	if(!M.CheckActionCooldown(CLICK_CD_MELEE))
		return
	M.DelayNextAction()
	if(M.melee_damage_upper == 0)
		M.visible_message("<span class='notice'>\The [M] [M.friendly_verb_continuous] [src]!</span>",
			"<span class='notice'>You [M.friendly_verb_simple] [src]!</span>", target = src,
			target_message = "<span class='notice'>\The [M] [M.friendly_verb_continuous] you!</span>")
		return FALSE
	else
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
			return FALSE
		var/damage = rand(M.melee_damage_lower, M.melee_damage_upper)
		var/list/return_list = list()
		if(mob_run_block(M, damage, "the [M.name]", ATTACK_TYPE_MELEE, M.armour_penetration, M, check_zone(M.zone_selected), return_list) & BLOCK_SUCCESS)
			return FALSE
		damage = block_calculate_resultant_damage(damage, return_list)
		if(M.attack_sound)
			playsound(src, M.attack_sound, 50, 1, 1)
		M.do_attack_animation(src)
		visible_message("<span class='danger'>\The [M] [M.attack_verb_continuous] [src]!</span>", \
						"<span class='userdanger'>\The [M] [M.attack_verb_continuous] you!</span>", null, COMBAT_MESSAGE_RANGE, null,
						M, "<span class='danger'>You [M.attack_verb_simple] [src]!</span>")
		log_combat(M, src, "attacked")
		return damage

/mob/living/attack_paw(mob/living/carbon/monkey/M)
	if(!M.CheckActionCooldown(CLICK_CD_MELEE))
		return
	M.DelayNextAction()
	if (M.a_intent == INTENT_HARM)
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
			return FALSE
		if(M.is_muzzled() || (M.wear_mask && M.wear_mask.flags_cover & MASKCOVERSMOUTH))
			to_chat(M, "<span class='warning'>You can't bite with your mouth covered!</span>")
			return FALSE
		if(mob_run_block(M, 0, "the [M.name]", ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED, 0, M, check_zone(M.zone_selected), null) & BLOCK_SUCCESS)
			return FALSE
		M.do_attack_animation(src, ATTACK_EFFECT_BITE)
		if (prob(75))
			log_combat(M, src, "attacked")
			playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
			visible_message("<span class='danger'>[M.name] bites [src]!</span>", \
					"<span class='userdanger'>[M.name] bites you!</span>", null, COMBAT_MESSAGE_RANGE, null,
					M, "<span class='danger'>You bite [src]!</span>")
			return TRUE
		else
			visible_message("<span class='danger'>[M.name] has attempted to bite [src]!</span>", \
				"<span class='userdanger'>[M.name] has attempted to bite [src]!</span>", null, COMBAT_MESSAGE_RANGE, null,
				M, "<span class='danger'>You have attempted to bite [src]!</span>")
			return TRUE
	return FALSE

/mob/living/attack_larva(mob/living/carbon/alien/larva/L)
	switch(L.a_intent)
		if(INTENT_HELP)
			visible_message("<span class='notice'>[L.name] rubs its head against [src].</span>",
				"<span class='notice'>[L.name] rubs its head against you.</span>", target = L, \
				target_message = "<span class='notice'>You rub your head against [src].</span>")
			return FALSE

		else
			if(HAS_TRAIT(L, TRAIT_PACIFISM))
				to_chat(L, "<span class='notice'>You don't want to hurt anyone!</span>")
				return FALSE
			if(L != src && (mob_run_block(L, rand(1, 3), "the [L.name]", ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED, 0, L, check_zone(L.zone_selected), null) & BLOCK_SUCCESS))
				return FALSE
			L.do_attack_animation(src)
			if(prob(90))
				log_combat(L, src, "attacked")
				visible_message("<span class='danger'>[L.name] bites [src]!</span>", \
					"<span class='userdanger'>[L.name] bites you!</span>", null, COMBAT_MESSAGE_RANGE, null, L, \
					"<span class='danger'>You bite [src]!</span>")
				playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
				return TRUE
			else
				visible_message("<span class='danger'>[L.name] has attempted to bite [src]!</span>", \
					"<span class='userdanger'>[L.name] has attempted to bite you!</span>", null, COMBAT_MESSAGE_RANGE, null, L, \
					"<span class='danger'>You have attempted to bite [src]!</span>")

/mob/living/attack_alien(mob/living/carbon/alien/humanoid/M)
	if((M != src) && M.a_intent != INTENT_HELP && (mob_run_block(M, 0, "the [M.name]", ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED, 0, M, check_zone(M.zone_selected), null) & BLOCK_SUCCESS))
		visible_message("<span class='danger'>[M] attempted to touch [src]!</span>",
			"<span class='danger'>[M] attempted to touch you!</span>")
		return FALSE
	switch(M.a_intent)
		if (INTENT_HELP)
			if(!isalien(src)) //I know it's ugly, but the alien vs alien attack_alien behaviour is a bit different.
				visible_message("<span class='notice'>[M] caresses [src] with its scythe like arm.</span>",
					"<span class='notice'>[M] caresses you with its scythe like arm.</span>", target = M,
					target_message = "<span class='notice'>You caress [src] with your scythe like arm.</span>")
			return FALSE
		if (INTENT_GRAB)
			grabbedby(M)
			return FALSE
		if(INTENT_HARM)
			if(HAS_TRAIT(M, TRAIT_PACIFISM))
				to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
				return FALSE
			if(!isalien(src))
				M.do_attack_animation(src)
			return TRUE
		if(INTENT_DISARM)
			if(!isalien(src))
				M.do_attack_animation(src, ATTACK_EFFECT_DISARM)
			return TRUE

/mob/living/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return
	..()

/mob/living/wave_ex_act(power, datum/wave_explosion/explosion, dir)
	if(power > EXPLOSION_POWER_NORMAL_MOB_GIB)
		gib()
		return power
	adjustBruteLoss(EXPLOSION_POWER_STANDARD_SCALE_MOB_DAMAGE(power, explosion.mob_damage_mod))
	return power

//Looking for irradiate()? It's been moved to radiation.dm under the rad_act() for mobs.

/mob/living/acid_act(acidpwr, acid_volume)
	take_bodypart_damage(acidpwr * min(1, acid_volume * 0.1))
	return TRUE

///As the name suggests, this should be called to apply electric shocks.
/mob/living/proc/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	SEND_SIGNAL(src, COMSIG_LIVING_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, flags)
	shock_damage *= siemens_coeff
	if((flags & SHOCK_TESLA) && HAS_TRAIT(src, TRAIT_TESLA_SHOCKIMMUNE))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE
	if(shock_damage < 1)
		return FALSE
	if(!(flags & SHOCK_ILLUSION))
		adjustFireLoss(shock_damage)
	else
		adjustStaminaLoss(shock_damage)
	visible_message(
		"<span class='danger'>[src] was shocked by \the [source]!</span>", \
		"<span class='userdanger'>You feel a powerful shock coursing through your body!</span>", \
		"<span class='hear'>You hear a heavy electrical crack.</span>" \
	)
	return shock_damage

/mob/living/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/O in contents)
		O.emp_act(severity)

/mob/living/singularity_act()
	var/gain = 20
	investigate_log("([key_name(src)]) has been consumed by the singularity.", INVESTIGATE_SINGULO) //Oh that's where the clown ended up!
	gib()
	return(gain)

/mob/living/narsie_act()
	if(status_flags & GODMODE || QDELETED(src))
		return

	if(is_servant_of_ratvar(src) && !stat)
		to_chat(src, "<span class='userdanger'>You resist Nar'Sie's influence... but not all of it. <i>Run!</i></span>")
		adjustBruteLoss(35)
		if(src && reagents)
			reagents.add_reagent(/datum/reagent/toxin/heparin, 5)
		return FALSE
	// if(GLOB.cult_narsie && GLOB.cult_narsie.souls_needed[src])
	// 	GLOB.cult_narsie.souls_needed -= src
	// 	GLOB.cult_narsie.souls += 1
	// 	if((GLOB.cult_narsie.souls == GLOB.cult_narsie.soul_goal) && (GLOB.cult_narsie.resolved == FALSE))
	// 		GLOB.cult_narsie.resolved = TRUE
	// 		sound_to_playing_players('sound/machines/alarm.ogg')
	// 		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), CULT_VICTORY_MASS_CONVERSION), 120)
	// 		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ending_helper)), 270)
	if(client)
		makeNewConstruct(/mob/living/simple_animal/hostile/construct/harvester, src, cultoverride = TRUE)
	else
		switch(rand(1, 6))
			if(1)
				new /mob/living/simple_animal/hostile/construct/armored/hostile(get_turf(src))
			if(2)
				new /mob/living/simple_animal/hostile/construct/wraith/hostile(get_turf(src))
			if(3 to 6)
				new /mob/living/simple_animal/hostile/construct/builder/hostile(get_turf(src))
	spawn_dust()
	gib()
	return TRUE


/mob/living/ratvar_act()
	if(status_flags & GODMODE)
		return
	if(stat == DEAD || is_servant_of_ratvar(src))
		return
	if(is_eligible_servant(src))
		add_servant_of_ratvar(src)
		to_chat(src, "<span class='heavy_brass'>Ratvar's influence invades your mind, praise the Justiciar!</span>")
	else
		to_chat(src, "<span class='userdanger'>A blinding light boils you alive! <i>Run!</i></span>")
		adjust_fire_stacks(20)
		adjustFireLoss(35)
		IgniteMob()
	if(iscultist(src))
		to_chat(src, "<span class='userdanger'>You resist Ratvar's influence... but not all of it! <i>Run!</i></span>")
		adjustFireLoss(35)
		if(src && reagents)
			reagents.add_reagent(/datum/reagent/fuel/holyoil, 5)
		return FALSE


//called when the mob receives a bright flash
/mob/living/proc/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/tiled/flash, override_protection = 0)
	if((override_protection || get_eye_protection() < intensity) && (override_blindness_check || !(HAS_TRAIT(src, TRAIT_BLIND))))
		overlay_fullscreen("flash", type)
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "flash", 25), 25, TIMER_DELETE_ME)
		return TRUE
	return FALSE

//called when the mob receives a loud bang
/mob/living/proc/soundbang_act()
	return FALSE

//to damage the clothes worn by a mob
/mob/living/proc/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	return


/mob/living/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!used_item)
		used_item = get_active_held_item()
	..()


/mob/living/proc/getBruteLoss_nonProsthetic()
	return getBruteLoss()

/mob/living/proc/getFireLoss_nonProsthetic()
	return getFireLoss()

/mob/living/proc/set_last_attacker(mob/attacker)
	lastattacker = attacker.real_name
	lastattackerckey = attacker.ckey
	SEND_SIGNAL(src, COMSIG_LIVING_ATTACKER_SET, attacker)
	SEND_SIGNAL(attacker, COMSIG_LIVING_SET_AS_ATTACKER, src)
