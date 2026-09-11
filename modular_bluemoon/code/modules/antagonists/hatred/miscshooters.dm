#define JACKAL_ANTAG "jackal"
#define JACKAL_OMNIZINE_IMMUNITY "jackal_omnizine_immunity"
#define JACKAL_DEPENDENCY_BASE_DAMAGE 0.1
#define JACKAL_DEPENDENCY_BRUTE_MULTIPLIER 0.4
#define JACKAL_DEPENDENCY_FIRE_MULTIPLIER 0.2
#define JACKAL_DEPENDENCY_WARNING_CHANCE 10

/datum/antagonist/jackal
	parent_type = /datum/antagonist/hatred
	name = "Jackal"
	antagpanel_category = "Jackal"
	roundend_category = "Jackal"
	job_rank = ROLE_MASS_SHOOTER
	var/list/jackal_execution_quips = list(
		"...Мой компаньон будет рад",
		"Просто бизнес.",
		"...Сопутствующий ущерб",
		"Слышишь этот щелчок? Ты слышишь? Это звук твоей судьбы.",
		"Прости, мне платят за результат, а не за церемонии."
	)
	ui_name = "AntagInfoJackal"


/datum/antagonist/jackal/greet()
	var/greet_text = "Ты — [span_red(span_bold("Безымянный Ликвидатор"))]. Твое имя стерто из баз данных Солнечной Федерации, а твое прошлое давно сгорело в пепле грязных контрактов.<br>"
	greet_text += "Твоя кровь кипит от чудовищной дозы боевых стимуляторов, а реальность давно превратилась в психоделический кошмар. Окружающие люди для тебя — не более чем мишени, глупый и бесполезный шум в твоей раскалывающейся голове.<br>"
	greet_text += "У тебя осталась лишь одна цель: [span_red(span_bold("закрыть этот финальный контракт, выкосив станцию подчистую"))], и красиво сгореть в неоновой вспышке собственной смерти под аплодисменты воображаемого друга.<br><br>"
	greet_text += "Твои особые сигареты лечат тебя. Если в крови не останется алкоголя, Omnizine или стимуляторов, тело начнет постепенно разрушаться.<br>"
	greet_text += "В холстере лежат два stimpack medipen, три эпипена и один боевой нож. Эпипены почти не лечат, зато останавливают кровотечение.<br>"
	greet_text += "Казнь выполняется выстрелом из револьвера по критованной цели. После пяти казней револьвер станет ещё сильнее, уменьшая отдачу и увеличивая темп стрельбы.<br>"
	greet_text += span_red(span_bold("Докуривай сигарету — и погнали"))
	to_chat(owner.current, greet_text)
	antag_memory = greet_text
	owner.announce_objectives()

/datum/antagonist/jackal/on_gain()
	. = ..()
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		return
	H.remove_quirk(/datum/quirk/monochromatic)
	// Jackal needs natural healing for omnizine and stimpacks to work
	REMOVE_TRAIT(H, TRAIT_NONATURALHEAL, JACKAL_ANTAG)
	// Jackal is immune to omnizine overdose and healing restrictions
	ADD_TRAIT(H, JACKAL_OMNIZINE_IMMUNITY, JACKAL_ANTAG)
	H.update_body()
	// Jackal relies on stimpacks and cigarettes; hatred blocks all reagent speed boosts
	// Remove immunity not just for stimulants but for ALL reagent speed modifiers
	for(var/datum/movespeed_modifier/reagent/ms as anything in typesof(/datum/movespeed_modifier/reagent))
		if(initial(ms.multiplicative_slowdown) < 0)
			H.remove_movespeed_mod_immunities(JACKAL_ANTAG, ms)
	RegisterSignal(H, COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(jackal_biological_life), override = TRUE)

/datum/antagonist/jackal/proc/jackal_biological_life(mob/living/carbon/human/H, delta_time, times_fired)
	SIGNAL_HANDLER
	recover_from_softcrit(H, delta_time, times_fired)
	handle_dependency(H, delta_time, times_fired)

/datum/antagonist/jackal/on_removal()
	var/mob/living/carbon/human/H = owner?.current
	if(istype(H))
		UnregisterSignal(H, COMSIG_LIVING_BIOLOGICAL_LIFE)
		REMOVE_TRAIT(H, JACKAL_OMNIZINE_IMMUNITY, JACKAL_ANTAG)
	. = ..()

// Jackal omnizine override - handles healing and overdose immunity
/datum/reagent/medicine/omnizine/on_mob_life(mob/living/carbon/M)
	var/healing = 0.5
	var/jackal_immune = HAS_TRAIT(M, JACKAL_OMNIZINE_IMMUNITY)
	var/should_heal = (jackal_immune ? TRUE : FALSE)
	M.adjustToxLoss(-healing*REM, 0, should_heal)
	M.adjustOxyLoss(-healing*REM, 0, should_heal)
	M.adjustBruteLoss(-healing*REM, 0, should_heal)
	M.adjustFireLoss(-healing*REM, 0, should_heal)
	..()
	. = 1

/datum/reagent/medicine/omnizine/overdose_process(mob/living/M)
	if(HAS_TRAIT(M, JACKAL_OMNIZINE_IMMUNITY))
		return
	M.adjustToxLoss(1.5*REM, 0)
	M.adjustOxyLoss(1.5*REM, 0)
	M.adjustBruteLoss(1.5*REM, 0)
	M.adjustFireLoss(1.5*REM, 0)
	..()
	. = 1

/datum/antagonist/jackal/proc/handle_dependency(mob/living/carbon/human/H, delta_time, times_fired)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE) // Required: parent Hatred has recover_from_softcrit() on the same COMSIG_LIVING_BIOLOGICAL_LIFE signal
	if(!istype(H) || H.stat == DEAD || dependency_satisfied(H))
		return
	H.adjustBruteLoss(max(JACKAL_DEPENDENCY_BASE_DAMAGE, delta_time * JACKAL_DEPENDENCY_BRUTE_MULTIPLIER), TRUE)
	H.adjustFireLoss(max(JACKAL_DEPENDENCY_BASE_DAMAGE, delta_time * JACKAL_DEPENDENCY_FIRE_MULTIPLIER), TRUE)
	if(prob(JACKAL_DEPENDENCY_WARNING_CHANCE))
		to_chat(H, span_userdanger("Тело ломается без сигарет, алкоголя или стимуляторов. Найди дозу."))

/datum/antagonist/jackal/proc/dependency_satisfied(mob/living/carbon/human/H)
	if(!H.reagents)
		return FALSE
	for(var/datum/reagent/R as anything in H.reagents.reagent_list)
		if(istype(R, /datum/reagent/consumable/ethanol) || istype(R, /datum/reagent/medicine/omnizine) || istype(R, /datum/reagent/medicine/stimulants))
			return TRUE
	return FALSE

/datum/admins/proc/makeJackal(mob/dead/observer/applicant)
	var/mutable_appearance/alert_overlay = mutable_appearance('modular_bluemoon/code/modules/antagonists/hatred/hatred_icon.dmi', "jackal")
	if(!istype(applicant))
		var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for the position of a Jackal?", "pacifist", null, ROLE_MASS_SHOOTER, 30 SECONDS, poll_alert_pic = alert_overlay)
		applicant = pick_n_take(candidates)
	if(!istype(applicant) || !applicant.client)
		return FALSE
	var/mob/living/carbon/human/body = new(get_turf(GET_ERROR_ROOM))
	body.dna.remove_all_mutations()
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE
	player_mind.transfer_to(body)
	notify_ghosts("Jackal готовится к охоте...", 'sound/weapons/autoguninsert.ogg', source = body, alert_overlay = alert_overlay, action = NOTIFY_ORBIT, header = "Jackal")
	body.mind.make_Jackal()
	return TRUE

/datum/mind/proc/make_Jackal()
	if(!has_antag_datum(/datum/antagonist/jackal))
		special_role = "Jackal"
		assigned_role = "Jackal"
		add_antag_datum(/datum/antagonist/jackal)

/proc/_jackal_alarm_station(datum/antagonist/jackal/J)
	if(istype(J) && J?.owner?.current && J.owner.current.stat != DEAD)
		priority_announce("Дипломатический Корпус Солнечной Федерации предупреждает: в вашем секторе зафиксирован взлом частоты особо опасной личностью. Он находится в состоянии глубокого психоза из-за боевой химии, тяжёлых наркотиков и алкоголя. Цель вооружена крупнокалиберным револьвером и ликвидирует всех на своем пути. Всем сотрудникам: разрешено открытие огня на поражение без предупреждения\n\n...Просто диллер мудак. Вот и всё...", "DIPLOMATIC CORPS ALERT", 'modular_bluemoon/code/modules/antagonists/hatred/jackal_spawned.ogg', has_important_message = TRUE)
/datum/antagonist/jackal/make_authentic_body()
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		return
	H.real_name = "Jackal"
	H.name = H.real_name
	H.dna.real_name = H.real_name
	H.mind?.name = H.real_name
	H.set_species(/datum/species/human)
	H.set_gender(MALE, TRUE, forced = TRUE)
	H.dna.remove_all_mutations()
	H.skin_tone = "caucasian1"
	H.hair_style = "Business Hair 2"
	H.hair_color = sanitize_hexcolor("#552a00")
	H.facial_hair_style = "Beard (7 o'Clock)"
	H.facial_hair_color = sanitize_hexcolor("#552a00")
	H.set_bark("mutedc2")
	H.dna.update_ui_block(DNA_GENDER_BLOCK)
	H.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
	H.dna.features["legs"] = "Plantigrade"
	H.dna.species.mutant_bodyparts["legs"] = "Plantigrade"
	H.Digitigrade_Leg_Swap(TRUE)
	H.update_body()
	H.update_hair()

/datum/outfit/jackal
	parent_type = /datum/outfit/hatred
	name = "Jackal"
	head = null
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses/jackal
	uniform = /obj/item/clothing/under/jackal
	suit = null
	belt = /obj/item/storage/belt/holster/jackal
	suit_store = null
	back = null
	backpack_contents = null

/datum/outfit/jackal/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	return // Prevent parent hatred pre_equip from running (weapon selection dialog)

/datum/outfit/jackal/post_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	if(!istype(H) || QDELETED(H))
		return
	var/obj/item/clothing/under/U = H.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(U)
		U.has_sensor = NO_SENSORS
		U.resistance_flags = FIRE_PROOF | ACID_PROOF
		U.unique_reskin = null
		U.max_restricted_accessories = 1
		ADD_TRAIT(U, TRAIT_NODROP, JACKAL_ANTAG)
	for(var/slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_EYES, ITEM_SLOT_BELT, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET))
		var/obj/item/I = H.get_item_by_slot(slot)
		if(I)
			I.resistance_flags |= FIRE_PROOF
			if(slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_BELT))
				ADD_TRAIT(I, TRAIT_NODROP, JACKAL_ANTAG)

/obj/item/clothing/under/jackal
	name = "Jackal combat uniform"
	desc = "A fitted combat uniform reinforced against gunfire, blasts, and heat. It is tailored for a single ruthless operator."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	item_state = "jackalsuit"
	icon_state = "jackalsuit"
	body_parts_covered = CHEST|GROIN|ARMS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 35, BULLET = 45, LASER = 35, ENERGY = 35, BOMB = 45, BIO = 20, RAD = 20, FIRE = 80, ACID = 35, WOUND = 35)

/obj/item/clothing/glasses/hud/health/sunglasses/jackal
	name = "Jackal optical shield"
	desc = "Orange combat lenses with a medical HUD and hardened flash protection. Bright flashes cannot blind the wearer."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	icon_state = "jackalglasses"
	item_state = "jackalglasses"
	flash_protect = 2
	tint = 0

/obj/item/gun/ballistic/revolver/jackal357
	name = "Jackal .357 revolver"
	desc = "A custom .357 revolver built for a single purpose: ending a fight before the target can react."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/miscweapons.dmi'
	icon_state = "jackal357"
	item_state = "jackal357"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/jackal
	fire_sound = 'modular_bluemoon/sound/weapons/jackal357.ogg'
	recoil = 0.5
	spread = 4
	fire_delay = 1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS | ITEM_SLOT_SUITSTORE
	var/glory_kills = 0

/obj/item/gun/ballistic/revolver/jackal357/equipped(mob/user, slot, initial)
	. = ..()

/obj/item/gun/ballistic/revolver/jackal357/update_overlays()
	. = ..()
	if(glory_kills >= 5)
		. += mutable_appearance(icon, "bloodmask")

/obj/item/gun/ballistic/revolver/jackal357/check_glory_kill(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!QDELETED(user) && user.mind?.has_antag_datum(/datum/antagonist/jackal) && (QDELETED(target) || target?.stat == DEAD))
		glory_kills++
		if(glory_kills == 5)
			recoil = 0.2
			spread = 0
			fire_delay = 0
			upgrade_ammo()
			to_chat(user, span_userdanger("Кровавая маска проступает на [src]. Револьвер становится легче и быстрее в руке."))
		update_icon()

/obj/item/gun/ballistic/revolver/jackal357/proc/upgrade_ammo()
	if(!magazine)
		return
	// Use the cylinder's upgrade proc
	var/obj/item/ammo_box/magazine/internal/cylinder/jackal/jackal_cylinder = magazine
	if(istype(jackal_cylinder))
		jackal_cylinder.upgrade()
		chamber_round()

/obj/item/gun/ballistic/revolver/jackal357/handle_suicide(mob/living/carbon/human/user, mob/living/carbon/human/target, params, bypass_timer, time_to_kill = 5 SECONDS)
	var/datum/antagonist/jackal/J = user.mind?.has_antag_datum(/datum/antagonist/jackal)
	if(!J || !ishuman(target) || !target.get_bodypart(BODY_ZONE_HEAD))
		// Not a Jackal or invalid target: delegate to global hatred/handle_suicide override (hatred.dm:480)
		var/obj/item/gun/G = src
		return G../handle_suicide(user, target, params, bypass_timer, time_to_kill)
	var/is_glory = TRUE
	if(!target.client || target?.stat == DEAD)
		is_glory = FALSE
	else if(COOLDOWN_FINISHED(J, killing_speech_cd))
		var/quip = pick(J.jackal_execution_quips)
		// visible_message with 3 params: public, private (viewer), ambient
		// Use same format as other hatred executions
		visible_message("<span class='bolddanger'>[user] произносит \"[quip]\"</span>", \
						"<span class='userdanger'>[user] смотрит вам в глаза и произносит: [quip]</span>", \
						"<span class='italics'>Вы слышите, как кто-то произносит угрожающие слова.</span>")
		COOLDOWN_START(J, killing_speech_cd, 10 SECONDS)
	// Go straight to BASE GUN handle_suicide (gun.dm:828) so the global hatred.dm override doesn't
	// interfere or check the same things twice. We handle cooldowns/quips above.
	var/obj/item/gun/base_gun = src
	. = base_gun../handle_suicide(user, target, params, bypass_timer, time_to_kill)
	if(!. || user == target || !is_glory)
		return
	addtimer(CALLBACK(src, PROC_REF(check_glory_kill), user, target), 1 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/gun/ballistic/revolver/jackal357/attackby(obj/item/A, mob/user, params)
	// INTERCEPT: if it's a jackal speedloader, handle it OURSELVES before parent messes things up
	// Parent's default revolver attackby would load only 1 round and deplete the speedloader
	if(!magazine)
		return ..()
	if(istype(A, /obj/item/ammo_box/a357/jackal) && istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder/jackal))
		var/obj/item/ammo_box/a357/jackal/speedloader = A
		var/obj/item/ammo_box/magazine/internal/cylinder/jackal/JC = magazine
		if(!JC.can_load(user))
			return
		var/num_loaded = JC.ammo_box_reload(speedloader, user, params, 0, 1)
		if(num_loaded)
			to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src].</span>")
			playsound(user, 'sound/weapons/bulletinsert.ogg', 60, 1)
			speedloader.update_icon()
			update_icon()
			chamber_round(0)
			return TRUE
		else
			to_chat(user, span_warning("The speedloader has no ammo left!"))
			return
	// Not a jackal speedloader? Fallback to normal parent logic
	. = ..()
	if(.)
		return
	if(!magazine)
		return
	var/num_loaded = 0
	if(istype(A, /obj/item/ammo_box))
		var/obj/item/ammo_box/AM = A
		if(istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder/jackal))
			var/obj/item/ammo_box/magazine/internal/cylinder/jackal/JC = magazine
			num_loaded = JC.ammo_box_reload(AM, user, params, 0, 1)
		else
			if(!AM.speedloader)
				if(!istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder))
					return to_chat(user, span_userdanger("У вас не получается зарядить револьвер при помощи [A]!"))
				var/obj/item/ammo_box/magazine/internal/cylinder/C = magazine
				num_loaded = C.ammo_box_reload(AM, user, params, 1)
			else
				num_loaded = magazine.attackby(A, user, params, 1)
	if(num_loaded)
		to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src].</span>")
		playsound(user, 'sound/weapons/bulletinsert.ogg', 60, 1)
		A.update_icon()
		update_icon()
		chamber_round(0)

/obj/item/storage/belt/holster/jackal
	name = "Jackal assault holster"
	desc = "A reinforced shoulder holster with deep internal storage. It carries the Jackal's revolver, knives, ammunition, cigarettes, and lighter without slowing its wearer."
	icon_state = "holster"
	item_state = "jackalholster"
	mob_overlay_icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/holster/jackal/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 20
	STR.max_combined_w_class = INFINITY
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(list(/obj/item/gun/ballistic/revolver/jackal357, /obj/item/ammo_box/a357/jackal, /obj/item/kitchen/knife/combat, /obj/item/storage/fancy/cigarettes/jackal, /obj/item/lighter, /obj/item/reagent_containers/hypospray/medipen/stimulants, /obj/item/reagent_containers/hypospray/medipen))
	STR.quickdraw = TRUE

/obj/item/storage/belt/holster/jackal/PopulateContents()
	new /obj/item/gun/ballistic/revolver/jackal357(src)
	new /obj/item/ammo_box/a357/jackal(src)
	new /obj/item/ammo_box/a357/jackal(src)
	new /obj/item/ammo_box/a357/jackal(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/storage/fancy/cigarettes/jackal(src)
	new /obj/item/lighter(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimulants(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimulants(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)

// Helper proc: create a FRESH jackal speedloader with correct ammo type
/obj/item/storage/belt/holster/jackal/proc/create_refilled_speedloader(target_loc)
	// Check if the revolver has been upgraded to use enhanced ammo
	var/obj/item/gun/ballistic/revolver/jackal357/revolver
	for(var/obj/item/I in src)
		if(istype(I, /obj/item/gun/ballistic/revolver/jackal357))
			revolver = I
			break
	var/enhanced_ammo = FALSE
	if(revolver && revolver.glory_kills >= 5)
		enhanced_ammo = TRUE

	// Create the fresh speedloader instance
	var/obj/item/ammo_box/a357/jackal/fresh = new /obj/item/ammo_box/a357/jackal(target_loc)
	// Override ammo in it with the correct type
	for(var/obj/item/ammo_casing/old as anything in fresh.stored_ammo)
		if(old && !QDELETED(old))
			qdel(old)
	fresh.stored_ammo.Cut()
	while(fresh.stored_ammo.len < fresh.max_ammo)
		var/obj/item/ammo_casing/new_casing
		if(enhanced_ammo)
			new_casing = new /obj/item/ammo_casing/a357/jackal/enhanced(fresh)
		else
			new_casing = new /obj/item/ammo_casing/a357/jackal(fresh)
		fresh.stored_ammo += new_casing
	fresh.update_icon()
	return fresh

// AUTO-REFILL on Enter (like Hatred ammo pouch):
// Put the EMPTY/USED jackal speedloader back into the holster — it turns into a NEW FULL one instantly
// You don't need to take it out and put it back — just place it inside
/obj/item/storage/belt/holster/jackal/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(istype(AM, /obj/item/ammo_box/a357/jackal) && !QDELETED(src))
		// Same logic as Hatred pouch: destroy the used one, spawn a new full one in its place
		qdel(AM)
		create_refilled_speedloader(src)

// BACKWARDS COMPATIBILITY: when you REMOVE the speedloader it gets refilled (old behavior preserved)
/obj/item/storage/belt/holster/jackal/Exited(atom/movable/gone, atom/newLoc)
	. = ..()
	if(istype(gone, /obj/item/ammo_box/a357/jackal) && !QDELETED(src))
		var/obj/item/ammo_box/a357/jackal/speedloader = gone
		// Check if the revolver has been upgraded to use enhanced ammo
		var/obj/item/gun/ballistic/revolver/jackal357/revolver
		for(var/obj/item/I in src)
			if(istype(I, /obj/item/gun/ballistic/revolver/jackal357))
				revolver = I
				break
		var/enhanced_ammo = FALSE
		if(revolver && revolver.glory_kills >= 5)
			enhanced_ammo = TRUE

		// Clear existing ammo and refill
		for(var/obj/item/ammo_casing/old_casing as anything in speedloader.stored_ammo)
			if(old_casing && !QDELETED(old_casing))
				qdel(old_casing)
		speedloader.stored_ammo.Cut()
		while(speedloader.stored_ammo.len < speedloader.max_ammo)
			var/obj/item/ammo_casing/new_casing
			if(enhanced_ammo)
				new_casing = new /obj/item/ammo_casing/a357/jackal/enhanced(speedloader)
			else
				new_casing = new /obj/item/ammo_casing/a357/jackal(speedloader)
			speedloader.stored_ammo += new_casing
		speedloader.update_icon()

/obj/item/clothing/mask/cigarette/jackal
	name = "Jackal cigarette"
	desc = "A harsh cigarette laced with a small dose of Omnizine instead of the usual cheap filler."
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/medicine/omnizine = 10)

/obj/item/storage/fancy/cigarettes/jackal
	name = "Jackal cigarette packet"
	desc = "A battered packet of field cigarettes prepared for a violent, prolonged hunt."
	icon_state = "syndie"
	spawn_type = /obj/item/clothing/mask/cigarette/jackal

// Jackal specific ammo casings - moved here from revolver.dm
/obj/item/ammo_casing/a357/jackal
	name = ".357 Jackal bullet casing"
	desc = "A .357 bullet casing specifically designed for the Jackal's revolver."
	caliber = "357"
	projectile_type = /obj/item/projectile/bullet/a357/jackal
	can_be_printed = FALSE

/obj/item/ammo_casing/a357/jackal/enhanced
	name = ".357 Jackal enhanced bullet casing"
	desc = "A .357 bullet casing enhanced by the Jackal's blood mask."
	caliber = "357"
	projectile_type = /obj/item/projectile/bullet/a357/jackal/enhanced
	can_be_printed = FALSE
	// This is just a copy of jackal casing with enhanced projectile - used for internal cylinder after 5 kills

// Jackal specific speedloader
/obj/item/ammo_box/a357/jackal
	name = "speed loader (.357 Jackal)"
	desc = "A speed loader with .357 rounds specifically designed for the Jackal's revolver."
	icon_state = "357"
	ammo_type = /obj/item/ammo_casing/a357/jackal
	caliber = "357"
	max_ammo = 7
	multiload = TRUE
	w_class = WEIGHT_CLASS_TINY
	custom_materials = list(/datum/material/iron = 40000)
	speedloader = TRUE

// Jackal specific projectiles - moved here from projectile/revolver.dm
/obj/item/projectile/bullet/a357/jackal
	name = ".357 Jackal bullet"
	damage = 30  // Weaker than standard a357 (65) - 4 shots = 120 damage (~4 shots to kill with armor)
	armour_penetration = BULLET_BR3  // Same penetration as standard a357
	wound_bonus = 12
	ricochets_max = 2
	ricochet_chance = 100

/obj/item/projectile/bullet/a357/jackal/enhanced
	name = ".357 Jackal enhanced bullet"
	damage = 60  // Powerful enough for 2 shots = 120 damage (~2 shots to kill with armor)
	armour_penetration = BULLET_BR4  // Slightly better penetration when enhanced
	wound_bonus = 25
	ricochets_max = 2
	ricochet_chance = 100
