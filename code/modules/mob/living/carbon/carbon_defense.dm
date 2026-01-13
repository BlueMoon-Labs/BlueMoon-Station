
/mob/living/carbon/get_eye_protection()
	var/number = ..()

	if(istype(src.head, /obj/item/clothing/head))			//are they wearing something on their head
		var/obj/item/clothing/head/HFP = src.head			//if yes gets the flash protection value from that item
		number += HFP.flash_protect

	if(istype(src.glasses, /obj/item/clothing/glasses))		//glasses
		var/obj/item/clothing/glasses/GFP = src.glasses
		number += GFP.flash_protect

	if(istype(src.wear_mask, /obj/item/clothing/mask))		//mask
		var/obj/item/clothing/mask/MFP = src.wear_mask
		number += MFP.flash_protect

	var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
	if(!E)
		number = INFINITY //Can't get flashed without eyes
	else
		number += E.flash_protect

	return number

/mob/living/carbon/get_ear_protection()
	var/number = ..()
	var/obj/item/organ/ears/E = getorganslot(ORGAN_SLOT_EARS)
	if(!E)
		number = INFINITY
	else
		number += E.bang_protect
	return number

/mob/living/carbon/is_mouth_covered(head_only = 0, mask_only = 0)
	if( (!mask_only && head && (head.flags_cover & HEADCOVERSMOUTH)) || (!head_only && wear_mask && (wear_mask.flags_cover & MASKCOVERSMOUTH)) )
		return TRUE

/mob/living/carbon/is_eyes_covered(check_glasses = 1, check_head = 1, check_mask = 1)
	if(check_glasses && glasses && (glasses.flags_cover & GLASSESCOVERSEYES))
		return TRUE
	if(check_head && head && (head.flags_cover & HEADCOVERSEYES))
		return TRUE
	if(check_mask && wear_mask && (wear_mask.flags_cover & MASKCOVERSMOUTH))
		return TRUE

/mob/living/carbon/check_projectile_dismemberment(obj/item/projectile/P, def_zone)
	var/obj/item/bodypart/affecting = get_bodypart(def_zone)
	if(affecting && affecting.dismemberable && affecting.get_damage() >= (affecting.max_damage - P.dismemberment))
		affecting.dismember(P.damtype)

/mob/living/carbon/proc/can_catch_item(skip_throw_mode_check)
	. = FALSE
	if(!HAS_TRAIT(src, TRAIT_AUTO_CATCH_ITEM) && !skip_throw_mode_check && !throw_mode)
		return
	if(get_active_held_item())
		return
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	return TRUE

/mob/living/carbon/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!skipcatch && can_catch_item() && isitem(AM) && isturf(AM.loc))
		var/obj/item/I = AM
		I.attack_hand(src)
		if(get_active_held_item() == I) //if our attack_hand() picks up the item...
			visible_message(span_warning("[src] catches [I]!"), \
							span_userdanger("You catch [I] in mid-air!"))
			throw_mode_off()
			return TRUE
	if(isitem(AM) && HAS_TRAIT_FROM(src, TRAIT_AUTO_CATCH_ITEM, RISING_BASS_TRAIT))
		visible_message(span_warning("[src] chops [AM] out of the air!"), \
						span_userdanger("You chop [AM] out of the air!"))
		return TRUE
	return ..()

/mob/living/carbon/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	var/totitemdamage = pre_attacked_by(I, user) * damage_multiplier
	var/impacting_zone = (user == src)? check_zone(user.zone_selected) : ran_zone(user.zone_selected)
	var/list/block_return = list()
	if((user != src) && (mob_run_block(I, totitemdamage, "the [I]", ((attackchain_flags & ATTACK_IS_PARRY_COUNTERATTACK)? ATTACK_TYPE_PARRY_COUNTERATTACK : NONE) | ATTACK_TYPE_MELEE, I.armour_penetration, user, impacting_zone, block_return) & BLOCK_SUCCESS))
		return FALSE
	totitemdamage = block_calculate_resultant_damage(totitemdamage, block_return)
	var/obj/item/bodypart/affecting = get_bodypart(impacting_zone)
	if(!affecting) //missing limb? we select the first bodypart (you can never have zero, because of chest)
		affecting = bodyparts[1]
	SEND_SIGNAL(I, COMSIG_ITEM_ATTACK_ZONE, src, user, affecting)
	send_item_attack_message(I, user, affecting.name, affecting, totitemdamage)
	I.do_stagger_action(src, user, totitemdamage)
	if(I.force)
		apply_damage(totitemdamage, I.damtype, affecting, wound_bonus = I.wound_bonus, bare_wound_bonus = I.bare_wound_bonus, sharpness = I.get_sharpness()) //CIT CHANGE - replaces I.force with totitemdamage
		if(I.damtype == BRUTE && affecting.is_organic_limb(FALSE))
			var/basebloodychance = affecting.brute_dam + totitemdamage
			if(prob(basebloodychance))
				I.add_mob_blood(src)
				var/turf/location = get_turf(src)
				add_splatter_floor(location)
				if(totitemdamage >= 10 && get_dist(user, src) <= 1)	//people with TK won't get smeared with blood
					user.add_mob_blood(src)

				if(affecting.body_zone == BODY_ZONE_HEAD)
					if(wear_mask && prob(basebloodychance))
						wear_mask.add_mob_blood(src)
						update_inv_wear_mask()
					if(wear_neck && prob(basebloodychance))
						wear_neck.add_mob_blood(src)
						update_inv_neck()
					if(head && prob(basebloodychance))
						head.add_mob_blood(src)
						update_inv_head()

		return TRUE //successful attack

/mob/living/carbon/attack_drone(mob/living/simple_animal/drone/user)
	return //so we don't call the carbon's attack_hand().

/mob/living/carbon/on_attack_hand(mob/living/carbon/human/user, act_intent, unarmed_attack_flags)
	. = ..()
	if(.) //was the attack blocked?
		return
	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			user.ContactContractDisease(D)

	for(var/thing in user.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(lying && surgeries.len)
		if(act_intent == INTENT_HELP || act_intent == INTENT_DISARM)
			for(var/datum/surgery/S in surgeries)
				if(S.next_step(user, act_intent))
					return TRUE

	for(var/i in all_wounds)
		var/datum/wound/W = i
		if(W.try_handling(user))
			return TRUE

/mob/living/carbon/attack_paw(mob/living/carbon/monkey/M)

	if(can_inject(M, TRUE))
		for(var/thing in diseases)
			var/datum/disease/D = thing
			if((D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN) && prob(85))
				M.ContactContractDisease(D)

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(M.a_intent == INTENT_HELP)
		help_shake_act(M)
		return TRUE

	. = ..()
	if(.) //successful monkey bite.
		for(var/thing in M.diseases)
			var/datum/disease/D = thing
			ForceContractDisease(D)
		return TRUE

/mob/living/carbon/attack_slime(mob/living/simple_animal/slime/M)
	. = ..()
	if(!.)
		return
	if(M.powerlevel > 0)
		var/stunprob = M.powerlevel * 7 + 10  // 17 at level 1, 80 at level 10
		if(prob(stunprob))
			M.powerlevel -= 3
			if(M.powerlevel < 0)
				M.powerlevel = 0

			visible_message("<span class='danger'>The [M.name] has shocked <b>[src]</b>!</span>", \
			"<span class='userdanger'>The [M.name] has shocked you!</span>", target = M,
			target_message = "<span class='danger'>You have shocked <b>[src]</b>!</span>")

			do_sparks(5, TRUE, src)
			var/power = M.powerlevel + rand(0,3)
			DefaultCombatKnockdown(power*20)
			if(stuttering < power)
				stuttering = power
			if (prob(stunprob) && M.powerlevel >= 8)
				adjustFireLoss(M.powerlevel * rand(6,10))
				updatehealth()

/mob/living/carbon/proc/dismembering_strike(mob/living/attacker, dam_zone)
	if(!attacker.limb_destroyer)
		return dam_zone
	var/obj/item/bodypart/affecting
	if(dam_zone && attacker.client)
		affecting = get_bodypart(ran_zone(dam_zone))
	else
		var/list/things_to_ruin = shuffle(bodyparts.Copy())
		for(var/B in things_to_ruin)
			var/obj/item/bodypart/bodypart = B
			if(bodypart.body_zone == BODY_ZONE_HEAD || bodypart.body_zone == BODY_ZONE_CHEST)
				continue
			if(!affecting || ((affecting.get_damage() / affecting.max_damage) < (bodypart.get_damage() / bodypart.max_damage)))
				affecting = bodypart
	if(affecting)
		dam_zone = affecting.body_zone
		if(affecting.get_damage() >= affecting.max_damage)
			affecting.dismember()
			return null
		return affecting.body_zone
	return dam_zone


/mob/living/carbon/blob_act(obj/structure/blob/B)
	if (stat == DEAD)
		return
	else
		show_message("<span class='userdanger'>Блоб атакует!</span>")
		adjustBruteLoss(10)

/mob/living/carbon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	if(isrobotic(src))
		//EMPs fuck robots over. Up to ~11.5 corruption per EMP if hit by the full power. They also get up to 15 burn damage per EMP (up to 2.5 per limb), plus short hardstun
		//Though, note that the burn damage is linear, while corruption is logarythmical, which means at lower severities you still get corruption, but far less burn / stun
		//Note than as compensation, they only take half the limb burn damage someone fully augmented would take, which would be up to 30 burn.

		adjustToxLoss(round(log(severity)*2.5, 0.1), toxins_type = TOX_SYSCORRUPT)

		// BLUEMOON ADD - кулдаун по получению ЕМП у синтетиков
		if(istype(src, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = src
			var/emp_shield_duration = 10 SECONDS
			if(HAS_TRAIT(H, TRAIT_SYSCLEANER_IN_PROGRESS))
				emp_shield_duration /= 2
			if(HAS_TRAIT(H, TRAIT_NANOBOT_REPAIR_IN_PROGRESS))
				emp_shield_duration /= 2
			if(HAS_TRAIT(H, TRAIT_BLUEMOON_EMP_VULNERABILITY))
				emp_shield_duration /= 4
			emp_shield_duration = clamp(emp_shield_duration, 1 SECONDS, 10 SECONDS)
			AddElement(/datum/element/empprotection, EMP_PROTECT_CONTENTS)
			H.physiology.hunger_mod *= 5
			addtimer(CALLBACK(H, PROC_REF(rollback_emp_protection)), emp_shield_duration)
			to_chat(H, span_boldwarning("Обнаружен ЭМИ-импульс - система переведена в режим повышенной защиты компонентов на [emp_shield_duration / 10] секунд."))

	for(var/X in internal_organs)
		var/obj/item/organ/O = X
		O.emp_act(severity)

/mob/living/carbon/proc/rollback_emp_protection()
	var/mob/living/carbon/human/H = src
	if(!istype(H))
		return
	RemoveElement(/datum/element/empprotection, EMP_PROTECT_CONTENTS)
	H.physiology.hunger_mod /= 5
	to_chat(H, span_boldwarning("Система повышенной защиты от ЭМИ отключена."))

///Adds to the parent by also adding functionality to propagate shocks through pulling and doing some fluff effects.
/mob/living/carbon/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	. = ..()
	if(!.)
		return
	//Propagation through pulling, fireman carry
	if(!(flags & SHOCK_ILLUSION))
		var/list/shocking_queue = list()
		if(iscarbon(pulling) && source != pulling)
			shocking_queue += pulling
		if(iscarbon(pulledby) && source != pulledby)
			shocking_queue += pulledby
		if(iscarbon(buckled) && source != buckled)
			shocking_queue += buckled
		for(var/mob/living/carbon/carried in buckled_mobs)
			if(source != carried)
				shocking_queue += carried
		//Found our victims, now lets shock them all
		for(var/victim in shocking_queue)
			var/mob/living/carbon/C = victim
			C.electrocute_act(shock_damage*0.75, src, 1, flags)
	//Stun
	var/should_stun = (!(flags & SHOCK_TESLA) || siemens_coeff > 0.5) && !(flags & SHOCK_NOSTUN)
	if(should_stun)
		Stun(40)
	//Jitter and other fluff.
	jitteriness += 1000
	do_jitter_animation(jitteriness)
	stuttering += 2
	addtimer(CALLBACK(src, PROC_REF(secondary_shock), should_stun), 20)
	return shock_damage

///Called slightly after electrocute act to reduce jittering and apply a secondary stun.
/mob/living/carbon/proc/secondary_shock(should_stun)
	jitteriness = max(jitteriness - 990, 10)
	if(should_stun)
		DefaultCombatKnockdown(60)

/mob/living/carbon/proc/help_shake_act(mob/living/carbon/M)
	if(on_fire)
		to_chat(M, "<span class='warning'>Вы не можете потушить [ru_ego()] голыми руками!!</span>")
		return

	if(M == src && check_self_for_injuries())
		return

// BLUEMOON ADD START - девайны для проигрывания определённого звука (вместо 2 или даже 3) при применении интента
#define SOUND_PAT 1
#define SOUND_BOOP 2

	var/sound_to_play = SOUND_PAT // чтобы проигрывался только 1 звук, а не 2-3
// BLUEMOON ADD END
	if(health >= 0 && !(HAS_TRAIT(src, TRAIT_FAKEDEATH)) || iszombie(src))
		var/friendly_check = FALSE
		if(mob_run_block(M, 0, M.name, ATTACK_TYPE_UNARMED, 0, null, null, null))
			return
		if(lying)
			if(buckled)
				// BLUEMOON ADD START
				if(istype(buckled, /obj/structure/table/optable) || istype(buckled, /obj/machinery/stasis))
					buckled.user_unbuckle_mob(src, M)
				else
				// BLUEMOON ADD END
					to_chat(M, "<span class='warning'>Для этого вам для начала нужно отстегнуть <b>[src]</b>!")
				return
			// BLUEMON ADD START - проверка для сверхтяжёлых персонажей
			if(src.mob_weight > MOB_WEIGHT_HEAVY)
				var/can_shake = FALSE
				if(M.mob_weight > MOB_WEIGHT_HEAVY) // другие сверхтяжёлые персонажи могут поднимать
					can_shake = TRUE
				if(ishuman(M))
					var/mob/living/carbon/human/user = M
					if(user.dna.check_mutation(HULK)) // халки могут поднимать
						can_shake = TRUE
					if(istype(user.back, /obj/item/mod/control)) // обычные персонажи с активированными клешнями из МОДа на спине могут поднимать
						var/obj/item/mod/control/MOD = user.back
						if(MOD.active || istype(MOD.selected_module, /obj/item/mod/module/clamp))
							can_shake = TRUE

				if(!can_shake)
					M.visible_message(span_warning("<b>[M]</b> пытается поднять <b>[src]</b> на ноги, но [ru_who()] слишком тяжёл[ru_aya()]!"), \
									span_warning("Вы пытаетесь поднять <b>[src]</b> на ноги, но [ru_who()] слишком тяжёл[ru_aya()]!"), target = src,
									target_message = span_notice("<b>[M]</b> трясёт тебя в однозначной попытке поднять, но не может!"))

					playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
					return
			// BLUEMOON ADD END

			M.visible_message("<span class='notice'><b>[M]</b> трясёт <b>[src]</b> в попытке поднять [ru_ego()] на ноги!</span>", \
							"<span class='notice'>Вы трясёте <b>[src]</b> в попытке поднять [ru_ego()] на ноги!</span>", target = src,
							target_message = "<span class='notice'><b>[M]</b> трясёт тебя в однозначной попытке поднять!</span>")

		else if(M.zone_selected == BODY_ZONE_PRECISE_GROIN) // BLUEMOON ADD — Дергать за хвосты.
			if(src.dna.features["mam_tail"] != "None")
				M.visible_message( \
					"<span class='warning'><b>[M]</b> дёргает хвост <b>[src]</b>!</span>", \
					"<span class='warning'>Ты дёргаешь <b>[src]</b> за хвост!</span>", target = src,
					target_message = "<span class='warning'><b>[M]</b> дёргает тебя за хвост!</span>")
				sound_to_play = SOUND_PAT

		else if(M.zone_selected == BODY_ZONE_PRECISE_MOUTH) // I ADDED BOOP-EH-DEH-NOSEH - Jon
			// BLUEMOON ADD START
			var/mob/living/carbon/human/H = src

			// Если персонажи слишком сильно различаются в росте, бупать не выйдет
			if(COMPARE_SIZES(src, M) >= 1.75)
				M.visible_message( \
						span_notice("<b>[M]</b> пытается достать до носа <b>[src]</b>, но не может!"), \
						span_warning("Ты пытаешься бупнуть <b>[src]</b> в нос, но не достаёшь!"), target = src,
						target_message = span_notice("<b>[M]</b> пытается дотянуть до твоего носа, но не может!"))

			// Если есть квирк "отдалённый", персонажу не нравятся бупы в нос
			else if(HAS_TRAIT(H, TRAIT_DISTANT)) //No mood buff since you're not really liking it.
				M.visible_message("<span class='warning'><b>[H]</b> резко осматривается на <b>[M]</b>, когда [ru_ego()] бупает в нос! Кажется, [ru_who()] раздражен[ru_a()]...</span>", \
					"<span class='warning'>Вы бупаете <b>[H]</b> в нос! Кажется, [ru_ego()] глаза презрительно смещаются в вашу сторону...</span>")
				sound_to_play = SOUND_BOOP // BLUEMOON EDIT - было playsound(src, 'sound/items/Nose_boop.ogg', 50, 0)
				H.add_lust(-5) //Why are you touching me?
				if(prob(20) && !HAS_TRAIT(H, TRAIT_PACIFISM) && !HAS_TRAIT(M, TRAIT_PACIFISM))
					M.visible_message("<span class='warning'><b>[H]</b> быстро выкручивает руку <b>[M]</b>!</span>", \
						"<span class='boldwarning'>Твоя рука выкручивается в хватке <b>[H]</b>! Может, тебе следовало понять тот явственный намек...</span>")
					// playsound(get_turf(H), 'sound/weapons/thudswoosh.ogg', 50, 1, -1) // BLUEMOON REMOVAL - звук проигрывается в конце
					M.emote("realagony")
					M.dropItemToGround(M.get_active_held_item())
					var/hand = pick(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
					M.apply_damage(50, STAMINA, hand)
					M.apply_damage(5, BRUTE, hand)
					M.Knockdown(60)//STOP TOUCHING ME! For those spam head pat individuals
					friendly_check = FALSE

			else
			// BLUEMOON ADD END
				M.visible_message( \
						"<span class='notice'><b>[M]</b> бупает носик <b>[src]</b>.</span>", \
						"<span class='notice'>Ты бупаешь носик <b>[src]</b>!</span>", target = src,
						target_message = "<span class='notice'><b>[M]</b> бупает твой носик!</span>")
				sound_to_play = SOUND_BOOP // BLUEMOON EDIT - было playsound(src, 'sound/items/Nose_boop.ogg', 50, 0)

		else if(check_zone(M.zone_selected) == BODY_ZONE_HEAD)
			var/mob/living/carbon/human/H = src
			var/datum/species/S
			if(ishuman(src))
				S = dna.species

			//SPLURT EDIT - Headpat traits
			if(M.has_quirk(/datum/quirk/dominant_aura) && H.has_quirk(/datum/quirk/well_trained))
				if(H.has_quirk(/datum/quirk/headpat_hater))
					H.remove_quirk(/datum/quirk/headpat_hater)
				if(!H.has_quirk(/datum/quirk/headpat_slut))
					H.add_quirk(/datum/quirk/headpat_slut)
				// BLUEMOON EDITED - I want to kill the guy behind it
				SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, QMOOD_WELL_TRAINED, /datum/mood_event/dominant/good_boy)

			// BLUEMOON ADD START - Если персонажи слишком сильно различаются в росте, гладить по голове не получится
			if(COMPARE_SIZES(src, M) >= 1.75)
				M.visible_message( \
						span_notice("<b>[M]</b> пытается достать до головы <b>[src]</b>, но не может!"), \
						span_warning("Ты пытаешься погладить <b>[src]</b> по голове, но не достаёшь!"), target = src,
						target_message = span_notice("<b>[M]</b> пытается дотянуть до твоей головы, но не может!"))
			// BLUEMOON ADD END

			else if(HAS_TRAIT(H, TRAIT_DISTANT)) //No mood buff since you're not really liking it. // BLUEMOON ADD - в начало добавлено else
				M.visible_message("<span class='warning'><b>[H]</b> резко осматривается на <b>[M]</b>, когда [ru_ego()] гладят по голове! Кажется, [ru_who()] раздражен[ru_a()]...</span>", \
					"<span class='warning'>Вы гладите <b>[H]</b> по голове! Кажется, [ru_ego()] глаза презрительно смещаются в вашу сторону...</span>")
				H.add_lust(-5) //Why are you touching me?
				if(prob(20) && !HAS_TRAIT(H, TRAIT_PACIFISM) && !HAS_TRAIT(M, TRAIT_PACIFISM)) // BLUEMOON EDIT - было 5%
					M.visible_message("<span class='warning'><b>[H]</b> быстро выкручивает руку <b>[M]</b>!</span>", \
						"<span class='boldwarning'>Твоя рука выкручивается в хватке <b>[H]</b>! Может, тебе следовало понять тот явственный намек...</span>")
					// playsound(get_turf(H), 'sound/weapons/thudswoosh.ogg', 50, 1, -1) // BLUEMOON REMOVAL - звук проигрывается в конце
					if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
						M.emote("scream")
					M.dropItemToGround(M.get_active_held_item())
					var/hand = pick(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
					M.apply_damage(50, STAMINA, hand)
					M.apply_damage(5, BRUTE, hand)
					M.Knockdown(60)//STOP TOUCHING ME! For those spam head pat individuals
					friendly_check = FALSE

			//BLUTEMOON ADD START (TRAIT_SPIKY)

			else if(HAS_TRAIT(H, TRAIT_SPIKY))
				if(M.gloves) // поглады в перчатках не наносят урон, но сообщение чуть-чуть отличается
					M.visible_message("<span class='notice'><b>[M]</b> похлопывает <b>[src]</b> по колючей голове рукой в перчатке!</span>", \
								"<span class='notice'>Ты гладишь <b>[src]</b> по голове, не боясь уколоться!</span>", target = src,
								target_message = "<span class='boldnotice'><b>[M]</b> гладит вас по голове, чтобы вы почувствовали себя лучше!</span>")
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "headpat", /datum/mood_event/headpat)
					return
				else
					M.visible_message("<span class='notice'><b>[M]</b> похлопывает <b>[src]</b> по колючей голове!</span>", \
								"<span class='notice'>Ты гладишь <b>[src]</b> по голове, рискуя пораниться!</span>", target = src,
								target_message = "<span class='boldnotice'><b>[M]</b> гладит вас по голове, чтобы вы почувствовали себя лучше!</span>")
					if(prob(50))
						M.visible_message("<span class='warning'><b>[M]</b> отдергивает руку от игл на голове <b>[H]</b>!</span>", \
							"<span class='boldwarning'>Ай! Иглы на голове <b>[H]</b> впиваются в твою руку!</span>")
						var/hand = pick(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
						M.apply_damage(7, STAMINA, hand)
						M.apply_damage(3, BRUTE, hand)
						friendly_check = TRUE // колючим все ещё могут нравиться поглады

			//BLUTEMOON ADD END (TRAIT_SPIKY)

			else
				friendly_check = TRUE
				if(iscatperson(H)) //felinids love headpats
					H.emote("purr")
				if(HAS_TRAIT(H, TRAIT_HEADPAT_SLUT))
					M.visible_message("<span class='notice'><b>[M]</b> похлопывает <b>[src]</b> по голове! Он[ru_a()] выглядит невероятно довольно!</span>", \
								"<span class='notice'>Ты гладишь <b>[src]</b> по голове, чтобы [ru_who()] почувствовал себя лучше! Кажется, он[ru_a()] принимает эту ласку слишком близко к сердцу...</span>", target = src,
								target_message = "<span class='boldnotice'><b>[M]</b> гладит вас по голове, чтобы вы почувствовали себя лучше!</span>")
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "lewd_headpat", /datum/mood_event/lewd_headpat)
					H.handle_post_sex(5, null, H) //Headpats are hot af
					H.client?.plug13.send_emote(PLUG13_EMOTE_BASIC, PLUG13_STRENGTH_MEDIUM, PLUG13_DURATION_SHORT)
				else
					M.visible_message("<span class='notice'><b>[M]</b> похлопывает <b>[src]</b> по голове!</span>", \
								"<span class='notice'>Ты гладишь <b>[src]</b> по голове, чтобы [ru_who()] почувствовал себя лучше!</span>", target = src,
								target_message = "<span class='boldnotice'><b>[M]</b> гладит вас по голове, чтобы вы почувствовали себя лучше!</span>")
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "headpat", /datum/mood_event/headpat)
					H.client?.plug13.send_emote(PLUG13_EMOTE_BASIC, PLUG13_STRENGTH_LOW_PLUS, PLUG13_DURATION_TINY)
					// LOW_PLUS потому что длительность TINY и привод не успеет особо разогнаться
			//SPLURT EDIT END

			if(!(client?.prefs.cit_toggles & NO_AUTO_WAG) && friendly_check)
				if(S?.can_wag_tail(src) && !dna.species.is_wagging_tail())
					var/static/list/many_tails = list("tail_human", "tail_lizard", "mam_tail")
					for(var/T in many_tails)
						if(S.mutant_bodyparts[T] && dna.features[T] != "None")
							nextsoundemote = world.time - 10
							emote("wag")

		else if(check_zone(M.zone_selected) == BODY_ZONE_R_ARM || check_zone(M.zone_selected) == BODY_ZONE_L_ARM)
			if((pulling == M) && (grab_state == GRAB_PASSIVE))
				M.visible_message( \
					"<span class='notice'><b>[M]</b> сжимает руку <b>[src]</b>.</span>", \
					"<span class='notice'>Ты сжимаешь руку <b>[src]</b>.</span>", target = src,
					target_message = "<span class='notice'><b>[M]</b> сжимает твою руку.</span>")
			else
				M.visible_message( \
					"<span class='notice'><b>[M]</b> пожимает руку <b>[src]</b>.</span>", \
					"<span class='notice'>Ты пожимаешь руку <b>[src]</b>.</span>", target = src,
					target_message = "<span class='notice'><b>[M]</b> пожимает твою руку.</span>")

			//BLUTEMOON ADD START (TRAIT_SPIKY)

		else
			var/mob/living/carbon/human/H = src
			if(HAS_TRAIT(H, TRAIT_SPIKY))
				M.visible_message("<span class='notice'><b>[M]</b> обнимает <b>[H]</b>!</span>", \
					"<span class='notice'>Ты пытаешься обнять <b>[H]</b>, избегая иголок!</span>", \
					target_message = "<span class='notice'><b>[M]</b> обнимает тебя!</span>")
				if(prob(50))
					M.visible_message("<span class='warning'><b>[M]</b> колется об иглы на теле <b>[H]</b>!</span>", \
					"<span class='boldwarning'>Иглы <b>[H]</b> впиваются тебе в тело!</span>")
					M.apply_damage(10, STAMINA)
					M.apply_damage(4, BRUTE)
					friendly_check = TRUE // колючим все ещё могут нравиться поглады

			//BLUTEMOON ADD END (TRAIT_SPIKY)

			else // к 5 строчкам ниже добавлен ещё один ТАБ, чтобы выполнялось if else для TRAIT_SPIKY
				M.visible_message("<span class='notice'><b>[M]</b> обнимает <b>[src]</b>!</span>", \
							"<span class='notice'>Ты обнимаешь <b>[src]</b>!</span>", target = src,\
							target_message = "<span class='notice'><b>[M]</b> обнимает тебя!</span>")
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "hug", /datum/mood_event/hug)
				M.client?.plug13.send_emote(PLUG13_EMOTE_BASIC, PLUG13_STRENGTH_LOW_PLUS, PLUG13_DURATION_TINY)
				friendly_check = TRUE

		if(friendly_check && (HAS_TRAIT(M, TRAIT_FRIENDLY) || HAS_TRAIT(src, TRAIT_FRIENDLY)))
			var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
			if(mood)
				new /obj/effect/temp_visual/heart(loc)
				if (mood.sanity >= SANITY_GREAT)
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/besthug, M)
				else if (mood.sanity >= SANITY_DISTURBED)
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/betterhug, M)

		AdjustAllImmobility(-60, FALSE)
		AdjustUnconscious(-60, FALSE)
		AdjustSleeping(-100, FALSE)
		if(combat_flags & COMBAT_FLAG_HARD_STAMCRIT)
			adjustStaminaLoss(-15)
		else
			set_resting(FALSE, FALSE)
		update_mobility()
		// playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1) // BLUEMOON REMOVAL
		// BLUEMOON ADD START - проигрышь только 1 звука
		switch(sound_to_play)
			if(SOUND_BOOP)
				playsound(src, 'sound/items/Nose_boop.ogg', 50, 1, -1)
			if(SOUND_PAT)
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
		//BLUEMOON ADD END

// BLUEMOON ADD START
#undef SOUND_PAT
#undef SOUND_BOOP
// BLUEMOON ADD END

/// Check ourselves to see if we've got any shrapnel, return true if we do. This is a much simpler version of what humans do, we only indicate we're checking ourselves if there's actually shrapnel
/mob/living/carbon/proc/check_self_for_injuries()
	if(stat == DEAD || stat == UNCONSCIOUS)
		return

	var/embeds = FALSE
	var/output = null
	for(var/X in bodyparts)
		var/obj/item/bodypart/LB = X
		for(var/obj/item/I in LB.embedded_objects)
			if(!embeds)
				embeds = TRUE
				// this way, we only visibly try to examine ourselves if we have something embedded, otherwise we'll still hug ourselves :)
				visible_message("<span class='notice'><b>[src]</b> осматривает себя.</span>", "")
				output = "<span class='notice'>Ты осматриваешь себя.</span><hr>"
			if(I.isEmbedHarmless())
				output += "\n\t <a href='?src=[REF(src)];embedded_object=[REF(I)];embedded_limb=[REF(LB)]' class='warning'>[I] врезался в вашу конечность - [LB.ru_name]!</a>"
			else
				output += "\n\t <a href='?src=[REF(src)];embedded_object=[REF(I)];embedded_limb=[REF(LB)]' class='warning'>[I] застрял в вашей конечности - [LB.ru_name]!</a>"

	if(output)
		to_chat(src, examine_block(output))

	return embeds

/mob/living/carbon/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/tiled/flash, override_protection = 0)
	. = ..()

	var/damage = override_protection ? intensity : intensity - get_eye_protection()
	if(.) // we've been flashed
		var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
		if (!eyes)
			return
		if(visual)
			return

		if (damage == 1)
			// BLUEMOON ADD START
			if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
				to_chat(src, span_warning("Визуальные сенсоры: опасность повреждения ярким светом, искусственная расфокусировка линзы активна. Вред предотвращен."))
			else
			// BLUEMOON ADD END
				to_chat(src, "<span class='warning'>Глаза немного щиплет.</span>")
				if(prob(40))
					eyes.applyOrganDamage(1)

		else if (damage == 2)
			// BLUEMOON ADD START
			if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
				to_chat(src, span_warning("Визуальные сенсоры: опасность повреждения ярким светом, искусственная расфокусировка линзы активна. Возможен минимальный вред."))
			else
			// BLUEMOON ADD END
				to_chat(src, "<span class='warning'>Глаза горят.</span>")
			eyes.applyOrganDamage(rand(2, 4))

		else if( damage >= 3)
			// BLUEMOON ADD START
			if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
				to_chat(src, span_warning("Визуальные сенсоры: опасность повреждения ярким светом, искусственная расфокусировка линзы активна. Оценка повреждений; средние."))
			else
			// BLUEMOON ADD END
				to_chat(src, "<span class='warning'>Ты ощущаешь сильный зуд и жжение в глазах!</span>")
			eyes.applyOrganDamage(rand(12, 16))

		if(eyes.damage > 10)
			blind_eyes(damage)
			blur_eyes(damage * rand(3, 6))

			if(eyes.damage > 20)
				if(prob(eyes.damage - 20))
					if(!HAS_TRAIT(src, TRAIT_NEARSIGHT))
						// BLUEMOON ADD START
						if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
							to_chat(src, span_warning("Визуальные сенсоры: тяжёлое повреждение линзы, необходима замена или ремонт."))
						else
						// BLUEMOON ADD END
							to_chat(src, "<span class='warning'>Глаза начинает сильно жечь!</span>")
					become_nearsighted(EYE_DAMAGE)

				else if(prob(eyes.damage - 25))
					if(!HAS_TRAIT(src, TRAIT_BLIND))
						// BLUEMOON ADD START
						if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
							to_chat(src, span_warning("Визуальные сенсоры: выгорание линзы, необходима замена или ремонт."))
						else
						// BLUEMOON ADD END
							to_chat(src, "<span class='warning'>Вы ничего не видите!</span>")
					eyes.applyOrganDamage(eyes.maxHealth)

			else
				// BLUEMOON ADD START
				if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
					to_chat(src, span_warning("Визуальные сенсоры: обнаружены умеренные повреждения, рекомендуется ремонт или замена."))
				else
				// BLUEMOON ADD END
					to_chat(src, "<span class='warning'>Ваши глаза начинают болеть. Это не хорошо!</span>")
		if(has_bane(BANE_LIGHT))
			mind.disrupt_spells(-500)
		return TRUE
	else if(damage == 0) // just enough protection
		if(prob(20))
			to_chat(src, "<span class='notice'>В углу зрения мелькнуло что-то яркое.</span>")
		if(has_bane(BANE_LIGHT))
			mind.disrupt_spells(0)


/mob/living/carbon/soundbang_act(intensity = 1, stun_pwr = 20, damage_pwr = 5, deafen_pwr = 15)
	var/list/reflist = list(intensity) // Need to wrap this in a list so we can pass a reference
	SEND_SIGNAL(src, COMSIG_CARBON_SOUNDBANG, reflist)
	intensity = reflist[1]
	var/ear_safety = get_ear_protection()
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	var/effect_amount = intensity - ear_safety
	if(effect_amount > 0)
		if(stun_pwr)
			DefaultCombatKnockdown(stun_pwr*effect_amount)

		if(istype(ears) && (deafen_pwr || damage_pwr))
			var/ear_damage = damage_pwr * effect_amount
			var/deaf = deafen_pwr * effect_amount
			adjustEarDamage(ear_damage,deaf)

			if(ears.damage >= 15)
				to_chat(src, "<span class='warning'>В ушах начинает сильно звенеть!</span>")
				if(prob(ears.damage - 5))
					to_chat(src, "<span class='userdanger'>Вы ничего не слышите!</span>")
					ears.damage = min(ears.damage, ears.maxHealth)
					// you need earmuffs, inacusiate, or replacement
			else if(ears.damage >= 5)
				to_chat(src, "<span class='warning'>В ушах начинает звенеть!</span>")
			SEND_SOUND(src, sound('sound/weapons/flash_ring.ogg',0,1,0,250))
		return effect_amount //how soundbanged we are


/mob/living/carbon/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	if(damage_type != BRUTE && damage_type != BURN)
		return
	damage_amount *= 0.5 //0.5 multiplier for balance reason, we don't want clothes to be too easily destroyed
	if(!def_zone || def_zone == BODY_ZONE_HEAD)
		var/obj/item/clothing/hit_clothes
		if(wear_mask)
			hit_clothes = wear_mask
		if(wear_neck)
			hit_clothes = wear_neck
		if(head)
			hit_clothes = head
		if(hit_clothes)
			hit_clothes.take_damage(damage_amount, damage_type, damage_flag, 0)

/mob/living/carbon/can_hear()
	. = FALSE
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	if(istype(ears) && !ears.deaf)
		. = TRUE

/mob/living/carbon/getBruteLoss_nonProsthetic()
	var/amount = 0
	for(var/obj/item/bodypart/BP in bodyparts)
		if (BP.is_organic_limb())
			amount += BP.brute_dam
	return amount

/mob/living/carbon/getFireLoss_nonProsthetic()
	var/amount = 0
	for(var/obj/item/bodypart/BP in bodyparts)
		if (BP.is_organic_limb())
			amount += BP.burn_dam
	return amount

/mob/living/carbon/proc/get_interaction_efficiency(zone)
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb)
		return

/mob/living/carbon/send_item_attack_message(obj/item/I, mob/living/user, hit_area, obj/item/bodypart/hit_bodypart, totitemdamage)
	var/message_verb = "attacked"
	if(length(I.attack_verb))
		message_verb = "[pick(I.attack_verb)]"
	else if(!I.force)
		return

	var/extra_wound_details = ""
	if(I.damtype == BRUTE && hit_bodypart.can_dismember())
		var/mangled_state = hit_bodypart.get_mangled_state()
		var/bio_state = get_biological_state()
		if(mangled_state == BODYPART_MANGLED_BOTH)
			extra_wound_details = ", threatening to sever it entirely"
		else if((mangled_state == BODYPART_MANGLED_FLESH && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_BONE && bio_state == BIO_JUST_BONE))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] through to the bone"
		else if((mangled_state == BODYPART_MANGLED_BONE && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_FLESH && bio_state == BIO_JUST_FLESH))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] at the remaining tissue"

	var/message_hit_area = ""
	if(hit_area)
		message_hit_area = " in the [hit_area]"
	var/attack_message = "<b>[src]</b> is [message_verb][message_hit_area] with [I][extra_wound_details]!"
	var/attack_message_local = "You're [message_verb][message_hit_area] with [I][extra_wound_details]!"
	if(user in viewers(src, null))
		attack_message = "[user] [message_verb] <b>[src]</b>[message_hit_area] with [I][extra_wound_details]!"
		attack_message_local = "[user] [message_verb] you[message_hit_area] with [I][extra_wound_details]!"
	if(user == src)
		attack_message_local = "You [message_verb] yourself[message_hit_area] with [I][extra_wound_details]"
	visible_message("<span class='danger'>[attack_message]</span>",\
		"<span class='userdanger'>[attack_message_local]</span>", null, COMBAT_MESSAGE_RANGE)
	return TRUE
