/datum/reagent/medicine/mesa_healing_solution
	name = "Healing Solution"
	description = "A unique healing solution developed by Black Mesa scientists. It is designed to accelerate the healing process of burns, wounds, and toxins."
	color = "#44944a"
	taste_description = "strange metallic"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 30
	can_synth = FALSE
	value = REAGENT_VALUE_RARE

/datum/reagent/medicine/mesa_healing_solution/on_mob_life(mob/living/carbon/M)
	if(!M)
		return

	if(M.getFireLoss_nonProsthetic() > 0)
		M.heal_bodypart_damage(0, 3)

	if(M.getBruteLoss_nonProsthetic() > 0)
		M.heal_bodypart_damage(3, 0)
	M.adjustToxLoss(-3, 0, TRUE)

	..()

/datum/reagent/medicine/mesa_healing_solution/overdose_process(mob/living/carbon/M, severity)
	if(!M)
		return

	if(prob(30))
		M.vomit(10, FALSE, distance = 1)
		to_chat(M, "<span class='warning'>Вы чувствуете сильную тошноту от передозировки лечебного раствора!</span>")

/obj/item/stack/medical/mesa_tactical
	name = "black mesa tactical medical pack"
	singular_name = "black mesa tactical medical pack"
	desc = "A tactical medical pack designed for use in the field. It contains a unique healing solution developed by Black Mesa scientists, which accelerates the healing process of burns, wounds, and toxins."
	icon = 'modular_bluemoon/icons/obj/mesameds.dmi'
	icon_state = "basicmed"
	item_state = "basicmed"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount = 1
	max_amount = 1
	self_delay = 50
	other_delay = 50
	merge_type = null // Prevent stacking
	repeating = FALSE
	heal_brute = 0
	heal_burn = 0
	stop_bleeding = 1
	flesh_regeneration = 0
	sanitization = 0
	bypass_armor = TRUE

	var/healing_solution_amount = 20
	var/used = FALSE

/obj/item/stack/medical/mesa_tactical/Initialize(mapload, new_amount, merge = TRUE)
	. = ..()
	update_icon()

/obj/item/stack/medical/mesa_tactical/update_icon_state()
	if(used)
		icon_state = "basicmed-empty"
		item_state = "basicmed-empty"
	else
		icon_state = "basicmed"
		item_state = "basicmed"

/obj/item/stack/medical/mesa_tactical/has_healable_damage(mob/living/carbon/patient)
	if(patient.getBruteLoss() > 0 || patient.getFireLoss() > 0 || patient.getToxLoss() > 0)
		return TRUE
	for(var/datum/wound/W as anything in patient.all_wounds)
		if(istype(W, /datum/wound/blunt) || istype(W, /datum/wound/slash) || istype(W, /datum/wound/pierce))
			return TRUE
	return FALSE

/obj/item/stack/medical/mesa_tactical/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!patient)
		return FALSE
	if(!user)
		return FALSE

	if(!can_heal(patient, user, healed_zone, silent))
		return FALSE

	if(!heal_dead && patient.stat == DEAD && !HAS_TRAIT(patient, TRAIT_UNDEAD))
		if(!silent)
			to_chat(user, "<span class='warning'>[patient] мертв[patient.ru_a()]! Вы не можете [patient.ru_emu()] помочь.</span>")
		return FALSE

	if(!iscarbon(patient))
		return FALSE

	var/mob/living/carbon/carbon_patient = patient
	var/obj/item/bodypart/affecting = carbon_patient.get_bodypart(healed_zone)
	if(!affecting)
		if(!silent)
			to_chat(user, "<span class='warning'>У [patient] отсутствует \a [ru_parse_zone(healed_zone)]!</span>")
		return FALSE

	var/has_treatable_wounds = FALSE
	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/blunt) || istype(W, /datum/wound/slash) || istype(W, /datum/wound/pierce))
			has_treatable_wounds = TRUE
			break

	var/has_any_damage = (carbon_patient.getBruteLoss() > 0) || (carbon_patient.getFireLoss() > 0) || (carbon_patient.getToxLoss() > 0)

	if(!has_treatable_wounds && !has_any_damage && affecting.brute_dam == 0 && affecting.burn_dam == 0)
		if(!silent)
			to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [patient] не требует лечения!</span>")
		return FALSE

	return TRUE

/obj/item/stack/medical/mesa_tactical/heal_carbon_new(mob/living/carbon/C, mob/user, healed_zone)
	var/obj/item/bodypart/affecting = C.get_bodypart(healed_zone)
	if(!affecting)
		return FALSE

	var/healed_something = FALSE
	for(var/datum/wound/W as anything in affecting.wounds)
		if(istype(W, /datum/wound/blunt))
			qdel(W)
			healed_something = TRUE
	for(var/datum/wound/W as anything in affecting.wounds)
		if(istype(W, /datum/wound/slash) || istype(W, /datum/wound/pierce))
			W.blood_flow = 0
			healed_something = TRUE
	if(C.reagents)
		C.reagents.add_reagent(/datum/reagent/medicine/mesa_healing_solution, healing_solution_amount)
		healed_something = TRUE

	if(healed_something)
		user.visible_message("<span class='green'>[user] наносит \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>", "<span class='green'>Вы наносите \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>")
		// Don't set used = TRUE - tactical medkit stays usable
		used = TRUE
		update_icon()

	return healed_something

/obj/item/reagent_containers/hypospray/medipen/mesa_healing
	name = "Black Mesa healing syringe"
	desc = "A specialized healing syringe containing Black Mesa's unique healing solution. Treats fractures, dislocations, and injects healing reagent."
	icon = 'modular_bluemoon/icons/obj/mesameds.dmi'
	icon_state = "basicsyringe"
	item_state = "syringe_0"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/mesa_healing_solution = 10)
	ignore_flags = 1
	reagent_flags = DRAWABLE
	flags_1 = null

	var/healing_use_time = 20

/obj/item/reagent_containers/hypospray/medipen/mesa_healing/attack(mob/M, mob/user)
	if(!M)
		return
	if(!user)
		return

	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	if(!iscarbon(M))
		to_chat(user, "<span class='warning'>[src] можно использовать только на гуманоидных существах!</span>")
		return

	var/mob/living/carbon/C = M

	if(user == C)
		to_chat(C, "<span class='notice'>Вы начинаете использовать [src] на себе...</span>")
	else
		user.visible_message("<span class='notice'>[user] начинает использовать [src] на [C]...</span>", "<span class='notice'>Вы начинаете использовать [src] на [C]...</span>")
		to_chat(C, "<span class='warning'>[user] начинает использовать [src] на вас!</span>")

	if(!do_after(user, healing_use_time, target = C))
		return

	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	for(var/obj/item/bodypart/BP as anything in C.bodyparts)
		if(!BP)
			continue
		for(var/datum/wound/W as anything in BP.wounds)
			if(istype(W, /datum/wound/blunt/moderate))
				qdel(W)
	..()

	if(user == C)
		to_chat(C, "<span class='green'>Вы успешно использовали [src] на себе!</span>")
	else
		user.visible_message("<span class='green'>[user] успешно использовал [src] на [C]!</span>", "<span class='green'>Вы успешно использовали [src] на [C]!</span>")
		to_chat(C, "<span class='green'>[user] использовал [src] на вас!</span>")
	// Don't disable the syringe after use - it stays usable
	if(!iscyborg(user))
		reagents.maximum_volume = 0
		reagent_flags = NONE
	update_icon()

/obj/item/reagent_containers/hypospray/medipen/mesa_healing/update_icon_state()
	if(reagents.total_volume > 0)
		icon_state = initial(icon_state)
		item_state = "syringe_0"
	else
		icon_state = "[initial(icon_state)]-"
		item_state = "syringe_empty"

/obj/item/stock_parts/cell/mesa_battery
	name = "HEV battery"
	desc = "A high-capacity battery designed for HEV suits and synthetic entities. Can charge suits below 20% and restore shield charges."
	icon = 'modular_bluemoon/icons/obj/mesameds.dmi'
	icon_state = "hevbattery"
	item_state = "bone-gel"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	maxcharge = 5000
	chargerate = 1000

/obj/item/stock_parts/cell/mesa_battery/afterattack(atom/target, mob/user, params)
	if(!target)
		return
	if(!user)
		return

	if(charge <= 0)
		to_chat(user, "<span class='warning'>[src] разряжена!</span>")
		return

	if(istype(target, /obj/item/clothing/suit/space/hev_suit))
		var/obj/item/clothing/suit/space/hev_suit/suit = target
		if(!suit.cell)
			to_chat(user, "<span class='warning'>[suit] не имеет установленной батареи!</span>")
			return

		var/charge_needed = suit.cell.maxcharge - suit.cell.charge
		if(charge_needed <= 0)
			to_chat(user, "<span class='warning'>[suit] уже полностью заряжен!</span>")
			return

		var/current_percent = suit.cell.charge / suit.cell.maxcharge * 100
		if(current_percent >= 20)
			to_chat(user, "<span class='warning'>[suit] имеет достаточно заряда ([round(current_percent, 1)]%). Зарядка возможна только при менее 20%!</span>")
			return

		var/charge_to_add = min(charge_needed, charge)
		suit.cell.charge = min(suit.cell.charge + charge_to_add, suit.cell.maxcharge)
		use(charge_to_add)
		if(charge <= 0)
			icon_state = "hevbattery-empty"
		if(istype(suit.loc, /mob/living/carbon))
			var/datum/component/shielded/shield = suit.GetComponent(/datum/component/shielded)
			if(!shield)
				suit.AddComponent(/datum/component/shielded, current = 5, max = 5, delay = 20 SECONDS, rate = 0, slots = ITEM_SLOT_OCLOTHING, state = "shield-red")
				to_chat(user, "<span class='green'>Вы зарядили [suit] и активировали защитный щит!</span>")
			else
				shield.adjust_charges(5)
				to_chat(user, "<span class='green'>Вы зарядили [suit] и восстановили заряды щита!</span>")

		playsound(loc, 'sound/magic/charge.ogg', 50, TRUE)
		return

	if(issilicon(target))
		var/mob/living/silicon/robot/R = target
		if(!R.cell)
			to_chat(user, "<span class='warning'>[R] не имеет батареи!</span>")
			return

		var/charge_needed = R.cell.maxcharge - R.cell.charge
		if(charge_needed <= 0)
			to_chat(user, "<span class='warning'>[R] уже полностью заряжен!</span>")
			return

		var/charge_to_add = min(charge_needed, charge)
		R.cell.charge = min(R.cell.charge + charge_to_add, R.cell.maxcharge)
		use(charge_to_add)
		if(charge <= 0)
			icon_state = "hevbattery-empty"

		to_chat(user, "<span class='green'>Вы зарядили [R]!</span>")
		to_chat(R, "<span class='green'>[user] зарядил вас!</span>")
		playsound(loc, 'sound/machines/chime.ogg', 50, TRUE)
		return

	return ..()

/obj/item/mesa_robot_kit
	name = "Black Mesa robot repair kit"
	desc = "A specialized repair kit for synthetic entities. Repairs damage and charges the target's battery."
	icon = 'modular_bluemoon/icons/obj/mesameds.dmi'
	icon_state = "synthmed"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	item_state = "firstaid-o2"
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 2
	throw_range = 6

	var/charges = 1
	var/max_charges = 1
	var/repair_amount = 50
	var/charge_amount = 2000
	var/use_time = 100

/obj/item/mesa_robot_kit/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Зарядов осталось: [charges]/[max_charges].</span>"

/obj/item/mesa_robot_kit/update_icon_state()
	if(charges > 0)
		icon_state = "synthmed"
	else
		icon_state = "synthmed-empty"

/obj/item/mesa_robot_kit/attack(mob/living/M, mob/user)
	if(!M)
		return
	if(!user)
		return

	if(charges <= 0)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	if(!issilicon(M))
		to_chat(user, "<span class='warning'>[src] можно использовать только на синтетах!</span>")
		return

	var/mob/living/silicon/robot/R = M

	if(user == R)
		to_chat(R, "<span class='notice'>Вы начинаете использовать [src] на себе...</span>")
	else
		user.visible_message("<span class='notice'>[user] начинает использовать [src] на [R]...</span>", "<span class='notice'>Вы начинаете использовать [src] на [R]...</span>")
		to_chat(R, "<span class='warning'>[user] начинает использовать [src] на вас!</span>")

	if(!do_after(user, use_time, target = R))
		return

	if(charges <= 0)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	if(R.getBruteLoss() > 0)
		R.adjustBruteLoss(-repair_amount, only_robotic = TRUE, only_organic = FALSE)
	if(R.getFireLoss() > 0)
		R.adjustFireLoss(-repair_amount, only_robotic = TRUE, only_organic = FALSE)
	if(R.getToxLoss() > 0)
		R.adjustToxLoss(-repair_amount, 0, TRUE)
	if(R.cell)
		var/charge_needed = R.cell.maxcharge - R.cell.charge
		var/charge_to_add = min(charge_needed, charge_amount)
		R.cell.charge = min(R.cell.charge + charge_to_add, R.cell.maxcharge)

	charges--
	update_icon()

	if(user == R)
		to_chat(R, "<span class='green'>Вы успешно использовали [src] на себе!</span>")
	else
		user.visible_message("<span class='green'>[user] успешно использовал [src] на [R]!</span>", "<span class='green'>Вы успешно использовали [src] на [R]!</span>")
		to_chat(R, "<span class='green'>[user] использовал [src] на вас!</span>")

	playsound(loc, 'modular_bluemoon/sound/creatures/mesa/meds/medkit.ogg', 50, TRUE)

/obj/item/reagent_containers/hypospray/medipen/mesa_robot
	name = "Black Mesa robot repair syringe"
	desc = "A specialized repair syringe for synthetic entities. Repairs damage and charges the target's battery."
	icon = 'modular_bluemoon/icons/obj/mesameds.dmi'
	icon_state = "synthsyringe"
	item_state = "syringe_0"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/mesa_healing_solution = 10)
	ignore_flags = 1
	reagent_flags = DRAWABLE
	flags_1 = null

	var/robot_repair_amount = 25
	var/robot_charge_amount = 1000
	var/robot_use_time = 50

/obj/item/reagent_containers/hypospray/medipen/mesa_robot/attack(mob/M, mob/user)
	if(!M)
		return
	if(!user)
		return

	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	if(!issilicon(M))
		to_chat(user, "<span class='warning'>[src] можно использовать только на синтетах!</span>")
		return

	var/mob/living/silicon/robot/R = M

	if(user == R)
		to_chat(R, "<span class='notice'>Вы начинаете использовать [src] на себе...</span>")
	else
		user.visible_message("<span class='notice'>[user] начинает использовать [src] на [R]...</span>", "<span class='notice'>Вы начинаете использовать [src] на [R]...</span>")
		to_chat(R, "<span class='warning'>[user] начинает использовать [src] на вас!</span>")

	if(!do_after(user, robot_use_time, target = R))
		return

	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return

	if(R.getBruteLoss() > 0)
		R.adjustBruteLoss(-robot_repair_amount, only_robotic = TRUE, only_organic = FALSE)
	if(R.getFireLoss() > 0)
		R.adjustFireLoss(-robot_repair_amount, only_robotic = TRUE, only_organic = FALSE)
	if(R.getToxLoss() > 0)
		R.adjustToxLoss(-robot_repair_amount, 0, TRUE)
	if(R.cell)
		var/charge_needed = R.cell.maxcharge - R.cell.charge
		var/charge_to_add = min(charge_needed, robot_charge_amount)
		R.cell.charge = min(R.cell.charge + charge_to_add, R.cell.maxcharge)

	if(user == R)
		to_chat(R, "<span class='green'>Вы успешно использовали [src] на себе!</span>")
	else
		user.visible_message("<span class='green'>[user] успешно использовал [src] на [R]!</span>", "<span class='green'>Вы успешно использовал [src] на [R]!</span>")
		to_chat(R, "<span class='green'>[user] использовал [src] на вас!</span>")
	// Don't disable the syringe after use - it stays usable
	// if(!iscyborg(user))
	// 	reagents.maximum_volume = 0
	// 	reagent_flags = NONE
	update_icon()

/obj/item/reagent_containers/hypospray/medipen/mesa_robot/update_icon_state()
	if(reagents.total_volume > 0)
		icon_state = initial(icon_state)
		item_state = "syringe_0"
	else
		icon_state = "[initial(icon_state)]-"
		item_state = "syringe_empty"
