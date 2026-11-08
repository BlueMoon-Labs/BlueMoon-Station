/obj/item/organ/cyberimp/chest
	name = "cybernetic torso implant"
	desc = "Implants for the organs in your torso."
	icon_state = "chest_implant"
	implant_overlay = "chest_implant_overlay"
	zone = BODY_ZONE_CHEST

/obj/item/organ/cyberimp/chest/nutriment
	name = "Nutriment pump implant"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are starving."
	icon_state = "chest_implant"
	implant_color = "#00AA00"
	aug_overlay = "nutripump"
	var/hunger_threshold = NUTRITION_LEVEL_STARVING
	var/synthesizing = 0
	var/poison_amount = 5
	slot = ORGAN_SLOT_STOMACH_AID

/obj/item/organ/cyberimp/chest/nutriment/on_life()
	. = ..()
	if(!. || synthesizing)
		return

	// Check if this user can process nutriment
	if(HAS_TRAIT(owner, TRAIT_NO_PROCESS_FOOD))
		return

	if(owner.nutrition <= hunger_threshold)
		synthesizing = TRUE
		to_chat(owner, "<span class='notice'>You feel less hungry...</span>")
		owner.adjust_nutrition(50)
		addtimer(CALLBACK(src, PROC_REF(synth_cool)), 50)

/obj/item/organ/cyberimp/chest/nutriment/proc/synth_cool()
	synthesizing = FALSE

/obj/item/organ/cyberimp/chest/nutriment/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	owner.reagents.add_reagent(/datum/reagent/toxin/bad_food, poison_amount * severity/100)
	to_chat(owner, "<span class='warning'>You feel like your insides are burning.</span>")

/obj/item/organ/cyberimp/chest/nutriment/plus
	name = "Nutriment pump implant PLUS"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry."
	icon_state = "chest_implant"
	implant_color = "#006607"
	aug_overlay = "nutripump_adv"
	hunger_threshold = NUTRITION_LEVEL_HUNGRY
	poison_amount = 10

#define MAX_HEAL_COOLDOWN 15 MINUTES
#define DEF_CONVALESCENCE_TIME 15 SECONDS

/obj/item/organ/cyberimp/chest/reviver
	name = "Reviver implant"
	desc = "This implant will attempt to revive and heal you if you lose consciousness. For the faint of heart!"
	icon_state = "chest_implant"
	implant_color = "#AD0000"
	aug_overlay = "reviver"
	emissive_overlay = TRUE
	slot = ORGAN_SLOT_HEART_AID
	var/revive_cost = 0
	var/reviving = FALSE
	var/cooldown = 0
	var/convalescence_time = 0

/obj/item/organ/cyberimp/chest/reviver/on_life()
	. = ..()
	if(reviving)
		var/do_heal = . && world.time < convalescence_time
		if(revive_cost >= MAX_HEAL_COOLDOWN)
			do_heal = FALSE
		else if(owner?.stat && owner.stat != DEAD)
			do_heal = TRUE
		else if(!do_heal)
			convalescence_time = world.time + DEF_CONVALESCENCE_TIME
		if(. && (do_heal || world.time < convalescence_time))
			addtimer(CALLBACK(src, PROC_REF(heal)), 3 SECONDS)
		else
			cooldown = revive_cost + world.time
			reviving = FALSE
			if(owner)
				to_chat(owner, "<span class='notice'>Your reviver implant shuts down and starts recharging. It will be ready again in [DisplayTimeText(revive_cost)].</span>")
		return

	if(!. || cooldown > world.time || owner.stat == CONSCIOUS || owner.stat == DEAD || owner.suiciding)
		return

	revive_cost = 0
	convalescence_time = 0
	reviving = TRUE
	to_chat(owner, "<span class='notice'>You feel a faint buzzing as your reviver implant starts patching your wounds...</span>")

/obj/item/organ/cyberimp/chest/reviver/proc/heal()
	if(!owner)
		return
	if(owner.getOxyLoss())
		owner.adjustOxyLoss(-5)
		revive_cost += 0.5 SECONDS
	if(owner.getBruteLoss())
		owner.adjustBruteLoss(-2)
		revive_cost += 4 SECONDS
	if(owner.getFireLoss())
		owner.adjustFireLoss(-2)
		revive_cost += 4 SECONDS
	if(owner.getToxLoss())
		owner.adjustToxLoss(-1)
		revive_cost += 4 SECONDS


/obj/item/organ/cyberimp/chest/reviver/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return

	if(reviving)
		revive_cost += 20 SECONDS
	else
		cooldown += 20 SECONDS

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.stat != DEAD && prob(severity/2) && H.can_heartattack())
			H.set_heartattack(TRUE)
			to_chat(H, "<span class='userdanger'>You feel a horrible agony in your chest!</span>")
			addtimer(CALLBACK(src, PROC_REF(undo_heart_attack)), (60 * severity/100) SECONDS)

/obj/item/organ/cyberimp/chest/reviver/proc/undo_heart_attack()
	var/mob/living/carbon/human/H = owner
	if(!H || !istype(H))
		return
	H.set_heartattack(FALSE)
	if(H.stat == CONSCIOUS || H.stat == SOFT_CRIT)
		to_chat(H, "<span class='notice'>Ваше сердце снова забилось!</span>")

#undef MAX_HEAL_COOLDOWN
#undef DEF_CONVALESCENCE_TIME

/obj/item/organ/cyberimp/chest/reviver/sec_level
	name = "Corporate Reviver implant"
	implant_color = "#751010"
	active_security_level = REVIVER_SEC_LEVEL

/obj/item/organ/cyberimp/chest/thrusters
	name = "implantable thrusters set"
	desc = "An implantable set of thruster ports. They use the gas from environment or subject's internals for propulsion in zero-gravity areas. \
	Unlike regular jetpacks, this device has no stabilization system."
	slot = ORGAN_SLOT_THRUSTERS
	icon_state = "imp_jetpack"
	implant_overlay = null
	implant_color = null
	aug_overlay = "imp_jetpack"
	emissive_overlay = TRUE
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	w_class = WEIGHT_CLASS_NORMAL
	var/on = FALSE
	var/datum/effect_system/trail_follow/ion/ion_trail
	/// Не больше одного списания за тик, см. одноимённое поле у баллонного джетпака.
	var/last_thrust_time = -1
	/// Скорость полёта берётся из конфига: TRUE → RUN_DELAY, FALSE → WALK_DELAY.
	var/full_speed = TRUE

/obj/item/organ/cyberimp/chest/thrusters/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!ion_trail)
		ion_trail = new
	ion_trail.set_up(M)

/// The bodypart overlay shows a different sprite while the thrusters are active.
/obj/item/organ/cyberimp/chest/thrusters/get_overlay_state(image_layer, obj/item/bodypart/limb)
	return "[aug_overlay][on ? "_on" : ""]"

/obj/item/organ/cyberimp/chest/thrusters/get_overlay(image_layer, obj/item/bodypart/limb)
	. = ..()
	for (var/image/overlay as anything in .)
		overlay.layer = -BODY_ADJ_UPPER_LAYER // renders on top of jumpsuits; looks cool

/obj/item/organ/cyberimp/chest/thrusters/deactivate(removing)
	. = ..()
	if(on)
		toggle(TRUE)

/obj/item/organ/cyberimp/chest/thrusters/ui_action_click()
	toggle()

/obj/item/organ/cyberimp/chest/thrusters/proc/toggle(silent = FALSE)
	if(!on)
		if(crit_fail || (organ_flags & ORGAN_FAILING))
			if(!silent)
				to_chat(owner, "<span class='warning'>Your thrusters set seems to be broken!</span>")
			return FALSE
		on = TRUE
		// Вопрос "потянем ли" задаётся уже поднятому флагу - иначе allow_thrust() отвечает "нет"
		// просто потому, что двигатели выключены. Не потянули - откатываем флаг здесь; раньше это
		// делал рекурсивный вызов toggle() из самой allow_thrust(), и по дороге он снимал подписки
		// и модификаторы, которых ещё не успели навесить.
		if(!allow_thrust(0.01, consume = FALSE))
			on = FALSE
		else
			ion_trail.start()
			RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death), override = TRUE)
			owner.update_movespeed()
			if(!silent)
				to_chat(owner, "<span class='notice'>You turn your thrusters set on.</span>")
	else
		ion_trail.stop()
		if(!QDELETED(owner))
			UnregisterSignal(owner, COMSIG_LIVING_DEATH)
			owner.update_movespeed()
			if(!silent)
				to_chat(owner, "<span class='notice'>You turn your thrusters set off.</span>")
		on = FALSE
	update_icon()
	refresh_bodypart_overlays()

/obj/item/organ/cyberimp/chest/thrusters/update_icon_state()
	if(on)
		icon_state = "imp_jetpack-on"
	else
		icon_state = "imp_jetpack"

/// Мёртвый не тянет рычаги. Дрейф остаётся - тело летит по инерции.
/obj/item/organ/cyberimp/chest/thrusters/proc/on_owner_death(mob/living/source)
	SIGNAL_HANDLER
	if(on)
		toggle(silent = TRUE)

/**
 * Спрашивает у трастеров, есть ли рабочее тело, и по желанию списывает за него.
 *
 * `consume = FALSE` отвечает на вопрос "потянем ли", ничего не тратя: накат по курсу на
 * крейсерской скорости двигателю ничего не стоит, но шагать он всё равно разрешает.
 */
/obj/item/organ/cyberimp/chest/thrusters/proc/allow_thrust(num, consume = TRUE)
	if(!on || !owner)
		return FALSE
	if(owner.stat != CONSCIOUS)
		return FALSE

	var/turf/T = get_turf(owner)
	if(!T) // No more runtimes from being stuck in nullspace.
		return FALSE

	// Priority 1: use air from environment.
	var/datum/gas_mixture/environment = T.return_air()
	if(environment && environment.return_pressure() > 30)
		return TRUE

	var/spend = consume && last_thrust_time != world.time

	// Priority 2: use plasma from internal plasma storage.
	// (just in case someone would ever use this implant system to make cyber-alien ops with jetpacks and taser arms)
	if(owner.getPlasma() >= num*100)
		if(spend)
			owner.adjustPlasma(-num*100)
			last_thrust_time = world.time
		return TRUE

	// Priority 3: use internals tank.
	var/obj/item/tank/I = owner.internal
	if(I && I.air_contents && I.air_contents.total_moles() >= num)
		if(spend)
			T.assume_air_moles(I.air_contents, num)
			last_thrust_time = world.time
		return TRUE

	// Гасим двигатели только тогда, когда за шаг реально надо было платить. Проверка без списания
	// приходит и с наката по курсу, и с самого включения - выключаться по ней значило бы душить
	// двигатели за то, что их спросили.
	if(consume)
		toggle(silent = TRUE)

	return FALSE

/obj/item/organ/cyberimp/chest/chem_implant
	name = "Chemical sequencer implant"
	desc = "This implant can inject limited list of basic reagents into your blood."
	slot = INTERNAL_ORGAN_CHEM_IMPLANT
	w_class = WEIGHT_CLASS_TINY
	icon = 'modular_bluemoon/icons/obj/surgery.dmi' //BLUEMOON ADD респрайт импланта
	icon_state = "chem_implant"
	var/charge_capacity = 4
	var/charge = 4
	var/charge_tick = 0
	var/charge_delay = 16
	var/implant_level = 0
	actions_types = list(/datum/action/item_action/chem_implant) ///datum/action/item_action/organ_action/use
	var/available_c = list()

/obj/item/organ/cyberimp/chest/chem_implant/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(60/severity) && owner)
		to_chat(owner, span_warning("Your chemical implant lost its charge!"))
		charge = 0

/obj/item/organ/cyberimp/chest/chem_implant/plus
	name = "Chemical Sequencer implant PLUS"
	desc = "This implant can inject limited list of advanced reagents into your blood."
	icon_state = "chem_implant_plus"
	implant_level = 1

/obj/item/organ/cyberimp/chest/chem_implant/sec_level
	name = "Corporate Chemical Sequencer implant"
	icon_state = "chem_implant_corpo"
	active_security_level = CHEM_SEQ_SEC_LEVEL

/obj/item/organ/cyberimp/chest/blood_pump
	name = "Blood pump implant"
	desc = "An emergency blood pump that injects regenerative compounds into the bloodstream when critically injured."
	slot = INTERNAL_ORGAN_CHEM_IMPLANT
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/surgery.dmi'
	icon_state = "blood_pump_sec"
	actions_types = list()
	var/charge_capacity = 2
	var/charge = 2
	var/charge_recharge_time = 1500
	var/last_use_time = 0
	var/last_charge_time = 0
	var/health_threshold = 60
	var/list/chem_list = list(/datum/reagent/medicine/synthflesh = 100, /datum/reagent/medicine/charcoal = 5)
	var/between_use_cooldown = 150
	var/ready = TRUE

/obj/item/organ/cyberimp/chest/blood_pump/Initialize()
	. = ..()
	last_charge_time = world.time
	last_use_time = 0

/obj/item/organ/cyberimp/chest/blood_pump/on_life(seconds, times_fired)
	. = ..()
	if(!.)
		return
	if(!owner || owner.stat == DEAD)
		return
	// recharge
	if(charge < charge_capacity && world.time - last_charge_time >= charge_recharge_time)
		charge++
		last_charge_time = world.time
	// check
	if(charge <= 0)
		return
	if(world.time - last_use_time < between_use_cooldown)
		return
	if(owner.health <= health_threshold)
		trigger_pump()

/obj/item/organ/cyberimp/chest/blood_pump/proc/trigger_pump()
	if(!owner || charge <= 0)
		return
	if(world.time - last_use_time < between_use_cooldown)
		return
	for(var/reagent_type in chem_list)
		var/amount = chem_list[reagent_type]
		var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
		if(istype(reagent, /datum/reagent/medicine/synthflesh))
			// Синтплоть лечит только при контакте с кожей: применяем её эффект напрямую,
			// в кровь она не попадает (там она бездействует и вредна в ранах).
			reagent.reaction_mob(owner, TOUCH, amount)
		else
			owner.reagents.add_reagent(reagent_type, amount)
	charge--
	last_use_time = world.time
	last_charge_time = world.time
	to_chat(owner, span_notice("The blood pump injects emergency compounds into your bloodstream."))

/obj/item/organ/cyberimp/chest/blood_pump/sec_level
	name = "Corporate Blood pump implant"
	icon_state = "blood_pump_sec"
	active_security_level = CHEM_SEQ_SEC_LEVEL

/obj/item/organ/cyberimp/chest/blood_pump/antag
	name = "Millitech Blood pump implant"
	desc = "An emergency blood pump that injects advanced regenerative compounds into the bloodstream when critically injured."
	icon_state = "blood_pump"
	charge_capacity = 3
	charge = 3
	charge_recharge_time = 3000
	health_threshold = 40
	chem_list = list(/datum/reagent/medicine/synthflesh/neo = 100, /datum/reagent/medicine/stimulants = 2)
	between_use_cooldown = 300

/////////////////////////
//Subdermal Armor      //
/////////////////////////

/obj/item/organ/cyberimp/chest/subdermal_armor
	name = "Subdermal armor implant"
	desc = "A lattice of composite plates woven beneath the skin. Absorbs part of incoming melee, bullet and laser damage."
	slot = ORGAN_SLOT_SUBDERMAL_ARMOR
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/surgery.dmi'
	icon_state = "subcutaneous_armor"
	/// Flat armor percentages granted to the owner's physiology while installed.
	var/melee_armor_bonus = 20
	var/bullet_armor_bonus = 10
	var/laser_armor_bonus = 10
	/// Flat BRC mitigation granted while installed.
	var/brc_mitigation_bonus = BRC_MITIGATION_25

/obj/item/organ/cyberimp/chest/subdermal_armor/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	M.brc_mitigation += brc_mitigation_bonus
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		// При уничтожении моба физиология могла быть уже разобрана.
		if(H.physiology?.armor)
			H.physiology.armor.melee += melee_armor_bonus
			H.physiology.armor.bullet += bullet_armor_bonus
			H.physiology.armor.laser += laser_armor_bonus

/obj/item/organ/cyberimp/chest/subdermal_armor/Remove(special = FALSE)
	if(owner)
		owner.brc_mitigation = max(0, owner.brc_mitigation - brc_mitigation_bonus)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			// При уничтожении моба физиология могла быть уже разобрана.
			if(H.physiology?.armor)
				H.physiology.armor.melee -= melee_armor_bonus
				H.physiology.armor.bullet -= bullet_armor_bonus
				H.physiology.armor.laser -= laser_armor_bonus
	return ..()

/////////////////////////
//Reinforced Skeleton  //
/////////////////////////

/obj/item/organ/cyberimp/chest/reinforced_skeleton
	name = "Reinforced skeleton implant"
	desc = "A carbon-composite endoskeleton grafted over the user's own bones, raising the amount of trauma the body can take before collapsing."
	slot = ORGAN_SLOT_REINFORCED_SKELETON
	w_class = WEIGHT_CLASS_NORMAL
	icon = 'icons/obj/surgery.dmi'
	icon_state = "combat_coating"
	/// Extra max health granted while installed.
	var/health_bonus = 25

/obj/item/organ/cyberimp/chest/reinforced_skeleton/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	M.maxHealth += health_bonus
	M.updatehealth()

/obj/item/organ/cyberimp/chest/reinforced_skeleton/Remove(special = FALSE)
	if(owner)
		owner.maxHealth = max(1, owner.maxHealth - health_bonus)
		owner.updatehealth()
	return ..()

///////////////////
//Shawarma Spit  //
///////////////////

/obj/item/organ/cyberimp/chest/shawarma_spit
	name = "Shawarma spit implant"
	desc = "A built-in shawarma spit. Activate it, then stack meat on it (help intent, aimed at the chest); each piece roasts in five seconds. Slices are carved off with a knife."
	slot = INTERNAL_ORGAN_CHEM_IMPLANT
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/surgery.dmi'
	icon_state = "kebab_grill"
	aug_overlay = "shawarma_skewer_0"
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	var/active = FALSE
	var/meat_count = 0
	var/max_meat = 3
	var/ready_count = 0
	var/cook_time = 5 SECONDS
	/// Meat sprite currently drawn on top of the grill sprite.
	var/image/meat_overlay

/obj/item/organ/cyberimp/chest/shawarma_spit/Initialize(mapload)
	. = ..()
	update_icon_state()

/obj/item/organ/cyberimp/chest/shawarma_spit/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(.)
		RegisterSignal(M, COMSIG_PARENT_ATTACKBY, PROC_REF(on_owner_attackby))

/obj/item/organ/cyberimp/chest/shawarma_spit/Remove(special = FALSE)
	if(owner)
		UnregisterSignal(owner, COMSIG_PARENT_ATTACKBY)
	return ..()

/obj/item/organ/cyberimp/chest/shawarma_spit/ui_action_click(mob/user, actiontype)
	active = !active
	to_chat(owner, span_notice("You [active ? "extend" : "retract"] your shawarma spit."))
	playsound(get_turf(owner), 'sound/machines/click.ogg', 30, TRUE)

/obj/item/organ/cyberimp/chest/shawarma_spit/proc/on_owner_attackby(datum/source, obj/item/I, mob/living/user, params)
	SIGNAL_HANDLER
	if(user.a_intent != INTENT_HELP || user.zone_selected != BODY_ZONE_CHEST)
		return
	if(istype(I, /obj/item/reagent_containers/food/snacks/meat))
		if(!active)
			to_chat(user, span_warning("The shawarma spit is retracted!"))
			return COMPONENT_NO_AFTERATTACK
		if(meat_count >= max_meat)
			to_chat(user, span_warning("[src] is already stacked with meat!"))
			return COMPONENT_NO_AFTERATTACK
		meat_count++
		update_icon_state()
		user.visible_message(span_notice("[user] slides [I] onto [owner]'s shawarma spit."), span_notice("You slide [I] onto [owner]'s shawarma spit."))
		qdel(I)
		addtimer(CALLBACK(src, PROC_REF(finish_cooking)), cook_time)
		return COMPONENT_NO_AFTERATTACK
	if(istype(I, /obj/item/kitchen/knife))
		INVOKE_ASYNC(src, PROC_REF(slice_off), user)
		return COMPONENT_NO_AFTERATTACK

/obj/item/organ/cyberimp/chest/shawarma_spit/proc/finish_cooking()
	if(!owner || ready_count >= meat_count)
		return
	ready_count++
	playsound(get_turf(owner), 'sound/machines/microwave/microwave-end.ogg', 40, FALSE)
	to_chat(owner, span_notice("A piece of meat on your shawarma spit is now roasted."))

/obj/item/organ/cyberimp/chest/shawarma_spit/proc/slice_off(mob/living/user)
	if(meat_count <= 0)
		to_chat(user, span_warning("The shawarma spit is empty!"))
		return
	var/ready = (ready_count > 0)
	if(ready)
		ready_count--
	meat_count--
	ready_count = min(ready_count, meat_count)
	update_icon_state()
	var/obj/item/slice
	if(ready)
		slice = new /obj/item/reagent_containers/food/snacks/meat/ready_kebab(get_turf(user))
	else
		slice = new /obj/item/reagent_containers/food/snacks/meat/cutlet(get_turf(user))
	if(!user.put_in_hands(slice))
		slice.forceMove(get_turf(user))
	user.visible_message(span_notice("[user] carves a slice of meat off [owner]'s shawarma spit."), span_notice("You carve a slice of meat off [owner]'s shawarma spit."))
	playsound(get_turf(user), 'sound/weapons/bladeslice.ogg', 30, TRUE)

/obj/item/organ/cyberimp/chest/shawarma_spit/create_bodypart_aug()
	. = ..()
	// Вертел рисуется поверх одежды (FRONT-слой), а не только на голом теле.
	if(bodypart_aug)
		bodypart_aug.set_layers(list(EXTERNAL_FRONT = BODY_FRONT_LAYER))

/obj/item/organ/cyberimp/chest/shawarma_spit/update_icon_state()
	icon_state = "kebab_grill"
	var/meat_state = "shawarma_skewer_[clamp(meat_count, 0, max_meat)]"
	// Ключ кэша конечности включает aug_overlay, поэтому после смены мяса достаточно
	// пересобрать части тела. Базовый гриль при этом остаётся нетронутым.
	aug_overlay = meat_state
	if(meat_overlay)
		cut_overlay(meat_overlay)
		meat_overlay = null
	meat_overlay = image(icon = icon, icon_state = meat_state)
	add_overlay(meat_overlay)
	. = ..()
	refresh_bodypart_overlays()

/obj/item/organ/cyberimp/chest/shawarma_spit/get_overlay(image_layer, obj/item/bodypart/limb)
	. = list()
	// Гриль и вертел с мясом — отдельные слои: вертел накладывается поверх гриля,
	// состояние _0 — пустой вертел, _1.._3 — количество слоёв мяса.
	. += image(icon = aug_icon, icon_state = "kebab_grill", layer = image_layer)
	. += image(icon = aug_icon, icon_state = "shawarma_skewer_[clamp(meat_count, 0, max_meat)]", layer = image_layer)

/datum/chem_implant
	var/chemname
	var/key
	var/chemdesc = "This is a chemical"
	var/chemuse = 1
	var/quantity = 8
	var/level = 0

/datum/chem_implant/epinephrine
	chemname = "Epinephrine"
	key = /datum/reagent/medicine/epinephrine
	chemdesc = "Stabilizes critical condition and slowly heals suffocation damage."
	quantity = 8

/datum/chem_implant/salglucose
	chemname = "Saline-Glucose Solution"
	key = /datum/reagent/medicine/salglu_solution
	chemdesc = "Heals all damage, but it requires more costs."
	quantity = 24

/datum/chem_implant/salbutamol
	chemname = "Salbutamol"
	key = /datum/reagent/medicine/salbutamol
	chemdesc = "Heals suffocation damage."
	quantity = 12

/datum/chem_implant/charcoal
	chemname = "Charcoal"
	key = /datum/reagent/medicine/charcoal
	chemdesc = "Slowly heals intoxication."
	quantity = 12

/datum/chem_implant/bicaridine
	chemname = "Bicaridine"
	key = /datum/reagent/medicine/bicaridine
	chemdesc = "Heals brute damage."
	quantity = 8


/datum/chem_implant/kelotane
	chemname = "Kelotane"
	key = /datum/reagent/medicine/kelotane
	chemdesc = "Heals burn damage."
	quantity = 8

/datum/chem_implant/stimulative_agent
	chemname = "Stimulants"
	key = /datum/reagent/medicine/stimulants
	chemdesc = "Stand up and deal with it."
	quantity = 4
	level = 1

/datum/chem_implant/mannitol
	chemname = "Mannitol"
	key = /datum/reagent/medicine/mannitol
	chemdesc = "Slowly heals your brain."
	quantity = 12
	level = 1

/datum/chem_implant/earthsblood
	chemname = "Earthsblood"
	key = /datum/reagent/medicine/earthsblood
	chemdesc = "Heals all damage, great for restoring wounds, but it's a little heavy on the brain."
	quantity = 8
	level = 1

/obj/item/organ/cyberimp/chest/chem_implant/Insert(var/mob/living/carbon/M, var/special = 0, drop_if_replaced = FALSE)
	. = ..()
	for(var/data in subtypesof(/datum/chem_implant))
		var/datum/chem_implant/C = new data
		if(C.chemname && implant_level >= C.level)
			available_c += list(list("name" = C.chemname, "key" = C.key, "desc" = C.chemdesc, "amount" = C.quantity))

/obj/item/organ/cyberimp/chest/chem_implant/on_life(seconds, times_fired)
	. = ..()
	if(!.)
		return
	charge_tick++
	if(charge_tick >= charge_delay)
		charge_tick = 0
		if (charge < charge_capacity)
			charge++

/obj/item/organ/cyberimp/chest/chem_implant/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemImplantSec", "Chemical Implant Interface")
		ui.open()

/obj/item/organ/cyberimp/chest/chem_implant/ui_data(mob/user)
	var/list/data = list()
	if(!owner)
		return data
	data["dead"] = (owner.stat > UNCONSCIOUS)
	data["health"] = owner.health
	data["current_chemicals"] = charge
	data["available_chemicals"] = available_c
	return data

/obj/item/organ/cyberimp/chest/chem_implant/ui_action_click(mob/user)
	ui_interact(user)

/obj/item/organ/cyberimp/chest/chem_implant/ui_status(mob/user, datum/ui_state/state)
	. = UI_CLOSE
	if(user.stat != DEAD && activate_allowed(user = user, silent = TRUE))
		. = max(., UI_INTERACTIVE)

/obj/item/organ/cyberimp/chest/chem_implant/ui_act(action, list/params)
	if(..() && owner.stat != DEAD)
		return
	switch(action)
		if("secreteChemicals")
			for(var/data in subtypesof(/datum/chem_implant))
				var/datum/chem_implant/C = new data
				if(C.chemname == params["key"] && charge > 0)
					to_chat(owner, "<span class='notice'>You inject [C.chemname] from your chemical sequncer implant into your bloodstream.</span>")
					owner.reagents.add_reagent(C.key, C.quantity)
					charge -= C.chemuse
					break
