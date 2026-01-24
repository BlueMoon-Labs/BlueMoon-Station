/datum/supply_pack/engineering/gasminer
	name = "Gas miner"
	desc = "Here's a gas miner circuitboard, that can generate any of four next gases - oxygen, nitrogen, plasma and carbon dioxide. Requires activated pyroclastic anomaly core."
	cost = 10000
	contains = list(/obj/item/circuitboard/machine/gas_miner)
	crate_name = "gas miner circuitboard"
	crate_type = /obj/structure/closet/crate/secure/engineering

//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engineering/bfl
	name = "BFL assembly crate"
	cost = 10000
	special = TRUE
	contains = list(
					/obj/item/circuitboard/machine/bfl_emitter,
					/obj/item/circuitboard/machine/bfl_receiver,
					/obj/item/paper/bfl
					)
	crate_name = "BFL assembly crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/bfl
	// required_tech = list("engineering" = 5, "powerstorage" = 4, "bluespace" = 6, "plasmatech" = 6)

/datum/supply_pack/engineering/bfl_lens
	name = "BFL High-precision lens"
	cost = 5000
	special = TRUE
	contains = list(
					/obj/machinery/bfl_lens
					)
	crate_name = "BFL High-precision lens"
	crate_type = /obj/structure/closet/crate/secure/engineering/bfl
	// required_tech = list("materials" = 7, "bluespace" = 4)

/datum/supply_pack/engineering/bfl_goal
	name = "BFL Mission goal"
	cost = 50000
	special = TRUE
	contains = list(
					/obj/structure/toilet/golden_toilet/bfl_goal,
					/obj/item/case_with_bipki
					)
	crate_name = "Goal crate"
	crate_type = /obj/structure/closet/crate/secure/engineering/bfl

/datum/supply_pack/engineering/bfl_goal/fill(obj/structure/closet/crate/C)
	var/list/L = contains.Copy()
	var/item = pick_n_take(L)
	new item(C)
	var/datum/station_goal/bfl/B = locate() in SSticker.mode.station_goals
	B?.completed = TRUE

//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engineering/cyborg_advexting
	name = "Cyborg Upgrade Module (Advanced Fire Extinguisher)"
	desc = "Atmospheric Technician-grade extinguisher for cyborg use. Can surpass most dangerous flames. Requires specialized foam tank to refill."
	cost = 12000
	contains = list(/obj/item/borg/upgrade/extinguisher_adv)
	crate_name = "Cyborg Upgrade Module"
	crate_type = /obj/structure/closet/crate/secure/engineering
