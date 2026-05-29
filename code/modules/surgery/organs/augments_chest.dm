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
	hunger_threshold = NUTRITION_LEVEL_HUNGRY
	poison_amount = 10

#define MAX_HEAL_COOLDOWN 15 MINUTES
#define DEF_CONVALESCENCE_TIME 15 SECONDS

/obj/item/organ/cyberimp/chest/reviver
	name = "Reviver implant"
	desc = "This implant will attempt to revive and heal you if you lose consciousness. For the faint of heart!"
	icon_state = "chest_implant"
	implant_color = "#AD0000"
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

/obj/item/organ/cyberimp/chest/thrusters
	name = "implantable thrusters set"
	desc = "An implantable set of thruster ports. They use the gas from environment or subject's internals for propulsion in zero-gravity areas. \
	Unlike regular jetpacks, this device has no stabilization system."
	slot = ORGAN_SLOT_THRUSTERS
	icon_state = "imp_jetpack"
	implant_overlay = null
	implant_color = null
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	w_class = WEIGHT_CLASS_NORMAL
	var/on = FALSE
	var/datum/effect_system/trail_follow/ion/ion_trail

/obj/item/organ/cyberimp/chest/thrusters/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!ion_trail)
		ion_trail = new
	ion_trail.set_up(M)

/obj/item/organ/cyberimp/chest/thrusters/Remove(special = FALSE)
	if(on)
		toggle(TRUE)
	return ..()

/obj/item/organ/cyberimp/chest/thrusters/ui_action_click()
	toggle()

/obj/item/organ/cyberimp/chest/thrusters/proc/toggle(silent = FALSE)
	if(!on)
		if(crit_fail || (organ_flags & ORGAN_FAILING))
			if(!silent)
				to_chat(owner, "<span class='warning'>Your thrusters set seems to be broken!</span>")
			return FALSE
		on = TRUE
		if(allow_thrust(0.01))
			ion_trail.start()
			RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(move_react))
			owner.add_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
			if(!silent)
				to_chat(owner, "<span class='notice'>You turn your thrusters set on.</span>")
	else
		ion_trail.stop()
		if(!QDELETED(owner))
			UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
			owner.remove_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
			if(!silent)
				to_chat(owner, "<span class='notice'>You turn your thrusters set off.</span>")
		on = FALSE
	update_icon()

/obj/item/organ/cyberimp/chest/thrusters/update_icon_state()
	if(on)
		icon_state = "imp_jetpack-on"
	else
		icon_state = "imp_jetpack"

/obj/item/organ/cyberimp/chest/thrusters/proc/move_react()
	allow_thrust(0.01)

/obj/item/organ/cyberimp/chest/thrusters/proc/allow_thrust(num)
	if(!on || !owner)
		return FALSE

	var/turf/T = get_turf(owner)
	if(!T) // No more runtimes from being stuck in nullspace.
		return FALSE

	// Priority 1: use air from environment.
	var/datum/gas_mixture/environment = T.return_air()
	if(environment && environment.return_pressure() > 30)
		return TRUE

	// Priority 2: use plasma from internal plasma storage.
	// (just in case someone would ever use this implant system to make cyber-alien ops with jetpacks and taser arms)
	if(owner.getPlasma() >= num*100)
		owner.adjustPlasma(-num*100)
		return TRUE

	// Priority 3: use internals tank.
	var/obj/item/tank/I = owner.internal
	if(I && I.air_contents && I.air_contents.total_moles() >= num)
		T.assume_air_moles(I.air_contents, num)
		return TRUE

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

/obj/item/organ/cyberimp/chest/chem_implant/plus
	name = "Chemical sequencer implant plus"
	desc = "This implant can inject limited list of advanced reagents into your blood."
	icon_state = "chem_implant_plus"
	implant_level = 1

/obj/item/organ/cyberimp/chest/chem_implant/emp_act(severity)
	if(prob(60/severity) && owner)
		to_chat(owner, "<span class='warning'>Your chemical implant lost it's chargre!</span>")
		charge = 0

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

/obj/item/organ/cyberimp/chest/chem_implant/on_life()
	. = ..()
	charge_tick++
	if(charge_tick >= charge_delay)
		charge_tick = 0
		if (charge < charge_capacity)
			charge++

/obj/item/organ/cyberimp/chest/chem_implant/Remove()
	. = ..()

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
	if(user.stat != DEAD)
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
