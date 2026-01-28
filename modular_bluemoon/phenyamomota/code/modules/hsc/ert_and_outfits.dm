//This file contains everything to spawn ERT for cleaning up a nuclear reactor meltdown, if those things could actually explode

//ERT
/datum/ert/hsc
	rename_team = "Trauma Team Squad"
	code = "Blue"	//CC probably wouldn't know if it was sabotage or not, but nuclear waste is a hazard to personnel
	mission = "Спаси и вылечи как можно больше сотрудников."
	enforce_human = FALSE
	opendoors = FALSE
	polldesc = "Trauma Team Squad"
	teamsize = 3	//2 is not enough for such a big area, 4 is too much
	leader_role = /datum/antagonist/ert/hsc/medic
	roles = list(/datum/antagonist/ert/hsc/sec, /datum/antagonist/ert/hsc/assistant)

/datum/ert/hsc/New()
	mission = "Спасти как можно больше сотрудников и жизней на [station_name()]."

//Antag mind & team (for objectives on what to do)
/datum/antagonist/ert/hsc/medic
	name = "Trauma Team Squad"
	role = "Медик-Специалист"
	ert_team = /datum/team/ert/hsc
	outfit = /datum/outfit/hsc/medic

/datum/antagonist/ert/hsc/sec
	name = "Trauma Team Squad"
	role = "Защитник"
	ert_team = /datum/team/ert/hsc
	outfit = /datum/outfit/hsc

/datum/antagonist/ert/hsc/assistant
	name = "Trauma Team Squad"
	role = "Специалист"
	ert_team = /datum/team/ert/hsc
	outfit = /datum/outfit/hsc/assistant

/datum/antagonist/ert/hsc/greet()
	//\an [name] because modularization is nice
	to_chat(owner, "Ты \an [name].\n\
		Ты должен спасти как можно больше жизней с [station_name()], \
		ведь по мнению Nanotrasen сотрудники этой Космической Станции очень важны.")

/datum/team/ert/hsc
	mission = "Спаси как можно больше сотрудников."
	objectives = list("Спаси как можно больше сотрудников.")

/datum/outfit/hsc
	name = "HSC Security"
	uniform = /obj/item/clothing/under/syndicate/combat/ert
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	back =  /obj/item/storage/backpack/ert_commander/ert_medical
	ears = /obj/item/radio/headset/headset_cent/alt
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	belt = /obj/item/storage/belt/military/ert_min
	id = /obj/item/card/id/hsc
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/hsc
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	mask = /obj/item/clothing/mask/gas/sechailer/hsc
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/handcuffs=1,
		/obj/item/storage/firstaid/regular=1,
		/obj/item/gun/energy/e_gun/dragnet=1,
		/obj/item/gun/ballistic/automatic/proto/unrestricted,
		/obj/item/storage/box/ammo/smgap=1,
		)
	l_pocket = /obj/item/gun/energy/e_gun/nuclear/ert
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	suit_store = /obj/item/tank/internals/doubleoxygen

	implants = list(
		/obj/item/implant/mindshield,
	 	/obj/item/implant/deathrattle/centcom,
	  	/obj/item/implant/weapons_auth,
	)
	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/shield,
	)
	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/hsc/medic
	name = "HSC Medic"
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	belt = /obj/item/defibrillator/compact/loaded_ert
	id = /obj/item/card/id/hsc/medic
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/medical
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/reagent_containers/hypospray/combat=1,\
		/obj/item/gun/medbeam=1,
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/surgery/advanced,
	)

/datum/outfit/hsc/assistant
	name = "HSC Assistant"
	ears = /obj/item/radio/headset/headset_cent/alt
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	belt = /obj/item/defibrillator/compact/loaded_ert
	id = /obj/item/card/id/hsc/assistant
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/assistant
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/gun/medbeam=1,
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,
		/obj/item/bodybag/bluespace=1
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/surgery,
	)
/datum/outfit/hsc/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	ADD_TRAIT(H, TRAIT_SURGEON, TRAIT_GENERIC)
	if(visualsOnly)
		return

	var/obj/item/implant/mindshield/L = new
	L.implant(H, null, 1)

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/card/id/W = H.wear_id
	if(W)
		W.registered_name = H.real_name
		W.update_label()

/obj/item/card/id/hsc
	name = "\improper HSC Security ID"
	desc = "Health Safety Control ID card."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/card.dmi'
	icon_state = "hsc"
	registered_name = "Health Safety Control Security"
	assignment = "Health Safety Control Security"
	special_assignment = "centcom"
	var/overlay_state = "idsec"

/obj/item/card/id/hsc/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("commander")-ACCESS_CHANGE_IDS
	. = ..()
	update_icon()

/obj/item/card/id/hsc/update_overlays()
	. = ..()
	. += mutable_appearance(icon, overlay_state)

/obj/item/card/id/hsc/medic
	name = "\improper HSC Medical ID"
	desc = "Health Safety Control ID card."
	icon_state = "hsc"
	registered_name = "Health Safety Control Medic"
	assignment = "Health Safety Control Medic"
	overlay_state = "idmed"

/obj/item/card/id/hsc/assistant
	name = "\improper HSC Assistant ID"
	desc = "Health Safety Control ID card."
	icon_state = "hsc"
	registered_name = "Health Safety Control Assistant"
	assignment = "Health Safety Control Assistant"
	overlay_state = "idas"
