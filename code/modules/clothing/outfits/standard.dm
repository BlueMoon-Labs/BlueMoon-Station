/datum/outfit/space
	name = "Standard Space Gear"

	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/sneakers/black
	suit = /obj/item/clothing/suit/space
	head = /obj/item/clothing/head/helmet/space
	back = /obj/item/tank/jetpack/oxygen
	mask = /obj/item/clothing/mask/breath

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/tournament
	name = "tournament standard red"

	uniform = /obj/item/clothing/under/color/red
	shoes = /obj/item/clothing/shoes/sneakers/black
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/thunderdome
	r_hand = /obj/item/gun/energy/pulse/destroyer
	l_hand = /obj/item/kitchen/knife
	r_pocket = /obj/item/grenade/smokebomb

/datum/outfit/tournament/green
	name = "tournament standard green"

	uniform = /obj/item/clothing/under/color/green

/datum/outfit/tournament/gangster
	name = "tournament gangster"

	uniform = /obj/item/clothing/under/rank/security/detective
	suit = /obj/item/clothing/suit/det_suit
	glasses = /obj/item/clothing/glasses/thermal/monocle
	head = /obj/item/clothing/head/fedora/det_hat
	r_hand = /obj/item/gun/ballistic
	l_hand = null
	r_pocket = /obj/item/ammo_box/c10mm

/datum/outfit/tournament/janitor
	name = "tournament janitor"

	uniform = /obj/item/clothing/under/rank/civilian/janitor
	back = /obj/item/storage/backpack
	suit = null
	head = null
	r_hand = /obj/item/mop
	l_hand = /obj/item/reagent_containers/glass/bucket
	r_pocket = /obj/item/grenade/chem_grenade/cleaner
	l_pocket = /obj/item/grenade/chem_grenade/cleaner
	backpack_contents = list(/obj/item/stack/tile/plasteel=6)

/datum/outfit/tournament/janitor/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/reagent_containers/glass/bucket/bucket = H.get_item_for_held_index(1)
	bucket.reagents.add_reagent(/datum/reagent/water,70)

/datum/outfit/laser_tag
	name = "Laser Tag Red"

	uniform = /obj/item/clothing/under/color/red
	shoes = /obj/item/clothing/shoes/sneakers/red
	head = /obj/item/clothing/head/helmet/redtaghelm
	gloves = /obj/item/clothing/gloves/color/red
	ears = /obj/item/radio/headset
	suit = /obj/item/clothing/suit/redtag
	back = /obj/item/storage/backpack
	suit_store = /obj/item/gun/energy/laser/redtag
	backpack_contents = list(/obj/item/storage/box=1)

/datum/outfit/laser_tag/blue
	name = "Laser Tag Blue"
	uniform = /obj/item/clothing/under/color/blue
	shoes = /obj/item/clothing/shoes/sneakers/blue
	head = /obj/item/clothing/head/helmet/bluetaghelm
	gloves = /obj/item/clothing/gloves/color/blue
	suit = /obj/item/clothing/suit/bluetag
	suit_store = /obj/item/gun/energy/laser/bluetag

/datum/outfit/pirate
	name = "Space Pirate"

	uniform = /obj/item/clothing/under/costume/pirate
	shoes = /obj/item/clothing/shoes/sneakers/brown
	suit = /obj/item/clothing/suit/pirate
	head = /obj/item/clothing/head/bandana
	glasses = /obj/item/clothing/glasses/eyepatch

/datum/outfit/pirate/space
	suit = /obj/item/clothing/suit/space/pirate
	head = /obj/item/clothing/head/helmet/space/pirate/bandana
	ears = /obj/item/radio/headset/pirate
	id = /obj/item/card/id/pirate

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/pirate/space/captain
	head = /obj/item/clothing/head/helmet/space/pirate

/datum/outfit/pirate/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.faction |= "pirate"

	var/obj/item/radio/R = H.ears
	if(R)
		R.set_frequency(FREQ_PIRATE)
		R.freqlock = TRUE

	var/obj/item/card/id/W = H.wear_id
	if(W)
		W.registered_name = H.real_name
		W.update_label(H.real_name)

	var/obj/item/implant/weapons_auth/B = new
	B.implant(H)

/datum/outfit/tunnel_clown
	name = "Tunnel Clown"

	uniform = /obj/item/clothing/under/rank/civilian/clown
	shoes = /obj/item/clothing/shoes/clown_shoes
	gloves = /obj/item/clothing/gloves/color/black
	mask = /obj/item/clothing/mask/gas/clown_hat
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/thermal/monocle
	suit = /obj/item/clothing/suit/hooded/chaplain_hoodie
	l_pocket = /obj/item/reagent_containers/food/snacks/grown/banana
	r_pocket = /obj/item/bikehorn
	id = /obj/item/card/id
	r_hand = /obj/item/fireaxe

/datum/outfit/tunnel_clown/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.access = get_all_accesses()
	W.assignment = "Tunnel Clown!"
	W.registered_name = H.real_name
	W.update_label()

/datum/outfit/psycho
	name = "Masked Killer"

	uniform = /obj/item/clothing/under/misc/overalls
	shoes = /obj/item/clothing/shoes/sneakers/white
	gloves = /obj/item/clothing/gloves/color/latex
	mask = /obj/item/clothing/mask/surgical
	head = /obj/item/clothing/head/welding
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/thermal/monocle
	suit = /obj/item/clothing/suit/apron
	l_pocket = /obj/item/kitchen/knife
	r_pocket = /obj/item/scalpel
	r_hand = /obj/item/fireaxe

/datum/outfit/psycho/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	for(var/obj/item/carried_item in H.get_equipped_items(TRUE))
		carried_item.add_mob_blood(H)//Oh yes, there will be blood...
	for(var/obj/item/I in H.held_items)
		I.add_mob_blood(H)
	H.regenerate_icons()

/datum/outfit/assassin
	name = "Assassin"

	uniform = /obj/item/clothing/under/suit/black
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/black
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/sunglasses
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	l_hand = /obj/item/storage/secure/briefcase
	id = /obj/item/card/id/syndicate
	belt = /obj/item/pda/heads
	accessory = list(/obj/item/clothing/accessory/waistcoat)

/datum/outfit/assassin/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	//Could use a type
	var/obj/item/storage/secure/briefcase/sec_briefcase = H.get_item_for_held_index(1)
	for(var/obj/item/briefcase_item in sec_briefcase)
		qdel(briefcase_item)
	for(var/i = 3 to 0 step -1)
		SEND_SIGNAL(sec_briefcase, COMSIG_TRY_STORAGE_INSERT, new /obj/item/stack/spacecash/c1000, null, TRUE, TRUE)
	SEND_SIGNAL(sec_briefcase, COMSIG_TRY_STORAGE_INSERT, new /obj/item/gun/energy/kinetic_accelerator/crossbow, null, TRUE, TRUE)
	SEND_SIGNAL(sec_briefcase, COMSIG_TRY_STORAGE_INSERT, new /obj/item/gun/ballistic/revolver/mateba, null, TRUE, TRUE)
	SEND_SIGNAL(sec_briefcase, COMSIG_TRY_STORAGE_INSERT, new /obj/item/ammo_box/a357, null, TRUE, TRUE)
	SEND_SIGNAL(sec_briefcase, COMSIG_TRY_STORAGE_INSERT, new /obj/item/grenade/plastic/x4, null, TRUE, TRUE)

	var/obj/item/pda/heads/pda = H.belt
	pda.owner = H.real_name
	pda.ownjob = "Reaper"
	pda.update_label()

	var/obj/item/card/id/syndicate/W = H.wear_id
	W.access = get_all_accesses()
	W.assignment = "Reaper"
	W.registered_name = H.real_name
	W.update_label()

/datum/outfit/centcom_commander
	name = "CentCom Commander"

	uniform = /obj/item/clothing/under/rank/centcom/commander
	suit = /obj/item/clothing/suit/hooded/wintercoat/centcom
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/headset_cent/commander/alt/generic
	glasses = /obj/item/clothing/glasses/hud/security/night/combat
	mask = /obj/item/clothing/mask/cigarette/cigar/cohiba
	head = /obj/item/clothing/head/centhat/cap
	belt = /obj/item/storage/belt/military/ert_max
	r_pocket = /obj/item/lighter
	l_pocket = /obj/item/tank/internals/emergency_oxygen/double
	suit_store = /obj/item/gun/energy/pulse/pistol/loyalpin
	back = /obj/item/storage/backpack/satchel/leather
	id = /obj/item/card/id/ert

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		/obj/item/melee/classic_baton/telescopic/centcom/plus = 1,
		)

	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom,
	 	/obj/item/implant/weapons_auth,
		/obj/item/implant/radio/centcom,
	 	/obj/item/implant/cqc,
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/medical,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/combat,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/mouth/breathing_tube,
		/obj/item/organ/cyberimp/chest/thrusters,
	)
/datum/outfit/centcom_commander/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()
	W.access += get_centcom_access("CentCom Commander")
	W.assignment = "CentCom Commander"
	W.registered_name = H.real_name
	W.update_label()

	var/obj/item/radio/headset/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

/datum/outfit/spec_ops
	name = "Special Ops Officer"

	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/space/officer
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	glasses = /obj/item/clothing/glasses/hud/security/night/combat
	ears = /obj/item/radio/headset/headset_cent/commander/alt/generic
	mask = /obj/item/clothing/mask/cigarette/cigar/havana
	head = /obj/item/clothing/head/helmet/space/beret
	belt = /obj/item/gun/energy/pulse/pistol/loyalpin
	r_pocket = /obj/item/lighter
	l_pocket = /obj/item/tank/internals/emergency_oxygen/double
	back = /obj/item/storage/backpack/satchel/leather
	id = /obj/item/card/id/ert

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		/obj/item/melee/classic_baton/telescopic/centcom/plus = 1,
		)

	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom,
		/obj/item/implant/weapons_auth,
		/obj/item/implant/radio/centcom,
		/obj/item/implant/cqc,
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/medical,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/combat,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/mouth/breathing_tube,
		/obj/item/organ/cyberimp/chest/thrusters,
	)
/datum/outfit/spec_ops/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()
	W.access += get_centcom_access("Special Ops Officer")
	W.assignment = "Special Ops Officer"
	W.registered_name = H.real_name
	W.update_label()

	var/obj/item/radio/headset/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

/datum/outfit/ghost_cultist
	name = "Cultist Ghost"

	uniform = /obj/item/clothing/under/color/black/ghost
	suit = /obj/item/clothing/suit/cultrobes/alt/ghost
	shoes = /obj/item/clothing/shoes/cult/alt/ghost
	head = /obj/item/clothing/head/culthood/alt/ghost
	r_hand = /obj/item/melee/cultblade/ghost

/datum/outfit/wizard
	name = "Blue Wizard"

	uniform = /obj/item/clothing/under/color/lightpurple/trackless
	suit = /obj/item/clothing/suit/wizrobe
	shoes = /obj/item/clothing/shoes/sandal/magic
	ears = /obj/item/radio/headset
	head = /obj/item/clothing/head/wizard
	r_pocket = /obj/item/teleportation_scroll
	r_hand = /obj/item/spellbook
	l_hand = /obj/item/staff
	back = /obj/item/storage/backpack
	backpack_contents = list(/obj/item/storage/box=1)

/datum/outfit/wizard/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/spellbook/S = locate() in H.held_items
	if(S)
		S.owner = H

/datum/outfit/wizard/apprentice
	name = "Wizard Apprentice"
	r_hand = null
	l_hand = null
	r_pocket = /obj/item/teleportation_scroll/apprentice

/datum/outfit/wizard/red
	name = "Red Wizard"

	suit = /obj/item/clothing/suit/wizrobe/red
	head = /obj/item/clothing/head/wizard/red

/datum/outfit/wizard/weeb
	name = "Marisa Wizard"

	suit = /obj/item/clothing/suit/wizrobe/marisa
	shoes = /obj/item/clothing/shoes/sandal/marisa
	head = /obj/item/clothing/head/wizard/marisa

/datum/outfit/soviet
	name = "Soviet Admiral"

	uniform = /obj/item/clothing/under/costume/soviet
	head = /obj/item/clothing/head/pirate/captain
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/headset_cent
	glasses = /obj/item/clothing/glasses/thermal/eyepatch
	suit = /obj/item/clothing/suit/pirate/captain
	back = /obj/item/storage/backpack/satchel/leather
	belt = /obj/item/gun/ballistic/revolver/mateba

	id = /obj/item/card/id

/datum/outfit/soviet/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()
	W.access += get_centcom_access("Admiral")
	W.assignment = "Admiral"
	W.registered_name = H.real_name
	W.update_label()

/datum/outfit/mobster
	name = "Mobster"

	uniform = /obj/item/clothing/under/suit/black_really
	head = /obj/item/clothing/head/fedora
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/black
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/sunglasses
	r_hand = /obj/item/gun/ballistic/automatic/tommygun
	id = /obj/item/card/id

/datum/outfit/mobster/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.assignment = "Assistant"
	W.registered_name = H.real_name
	W.update_label()

/datum/outfit/plasmaman
	name = "Plasmaman"

	head = /obj/item/clothing/head/helmet/space/plasmaman
	uniform = /obj/item/clothing/under/plasmaman
	r_hand = /obj/item/tank/internals/plasmaman/belt/full
	mask = /obj/item/clothing/mask/breath

/datum/outfit/death_commando
	name = "Death Commando"

	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/space/hardsuit/deathsquad
	shoes = /obj/item/clothing/shoes/magboots/syndie/advance
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_security
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	r_pocket = /obj/item/shield/energy
	suit_store = /obj/item/tank/internals/emergency_oxygen/double
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/gun/energy/pulse/destroyer
	id = /obj/item/card/id/death
	ears = /obj/item/radio/headset/headset_cent/alt

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/syndie_kit/revolver=1,\
		/obj/item/storage/firstaid/tactical/slaver=1,\
		/obj/item/storage/box/flashbangs/super=1,\
		/obj/item/pinpointer/nuke=1,\
		/obj/item/grenade/plastic/x4=1)

	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom, /obj/item/implant/weapons_auth, /obj/item/implant/radio/centcom)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/death_commando/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/card/id/death/W = H.wear_id
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("Death Commando")//Let's add their alloted CentCom access.
	W.registered_name = H.real_name
	W.update_label(W.registered_name)

/datum/outfit/death_commando/officer
	name = "Death Commando Officer"
	head = /obj/item/clothing/head/helmet/space/beret

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/box/syndie_kit/revolver=1,\
		/obj/item/storage/firstaid/tactical/slaver=1,\
		/obj/item/storage/box/flashbangs/super=1,\
		/obj/item/pinpointer/nuke=1,\
		/obj/item/grenade/plastic/x4=1)
// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/death_commando/officer/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/debug //Debug objs plus hardsuit
	name = "Debug outfit"
	uniform = /obj/item/clothing/under/misc/patriotsuit
	suit = /obj/item/clothing/suit/space/hardsuit/syndi/elite/debug
	glasses = /obj/item/clothing/glasses/debug
	ears = /obj/item/radio/headset/headset_cent/commander
	mask = /obj/item/clothing/mask/gas/welding/up
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	belt = /obj/item/storage/belt/utility/chief/full
	l_pocket = /obj/item/gun/magic/wand/resurrection/debug
	r_pocket = /obj/item/gun/magic/wand/death/debug
	shoes = /obj/item/clothing/shoes/magboots/advance/debug
	id = /obj/item/card/id/debug
	suit_store = /obj/item/tank/internals/oxygen
	back = /obj/item/storage/backpack/holding
	box = /obj/item/storage/box/debugtools
	internals_slot = ITEM_SLOT_SUITSTORE
	backpack_contents = list(
		/obj/item/melee/transforming/energy/axe=1,\
		/obj/item/storage/part_replacer/bluespace/tier5=1,\
		/obj/item/debug/human_spawner=1,\
		)

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/debug/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	var/obj/item/card/id/death/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label()
