/datum/ert/vdv_ert
	roles = list(/datum/antagonist/ert/vdv)
	leader_role = /datum/antagonist/ert/vdv/leader
	rename_team = "NRI Vozdushno Desantnie Voyska Squad"
	teamsize = 7
	opendoors = FALSE
	rename_team = "ВДВ"
	code = "Red"
	mission = "От одной из близлежащих космических станций получен сигнал о помощи. Мы связались с НТ и получили добро на вмешательство. Окажите поддержку."
	polldesc = "Vozdushno Desantnie Voyska Squad"
	ertphrase = "modular_bluemoon/sound/ert/nri_send.ogg"

/datum/antagonist/ert/vdv
	name = "NRI VDV Soldier"
	outfit = /datum/outfit/ert/vdv
	random_names = TRUE
	greentext_reward = 15

/datum/antagonist/ert/vdv/leader
	name = "NRI VDV Leader"
	outfit = /datum/outfit/ert/vdv/leader
	leader = TRUE
	greentext_reward = 20

/datum/antagonist/ert/vdv/update_name()
	owner.current.fully_replace_character_name(owner.current.real_name,"[pick("Рядовой", "Ефрейтор", "Сержант")] [pick(name_source)]")

/datum/antagonist/ert/vdv/leader/update_name()
	owner.current.fully_replace_character_name(owner.current.real_name,"Лейтенант [pick(name_source)]")

/obj/item/card/id/ert/vdv/lieutenant

/obj/item/card/id/ert/vdv/lieutenant/Initialize(mapload)
	. = ..()

	access = list(ACCESS_CENT_GENERAL, ACCESS_CENT_LIVING, ACCESS_MAINT_TUNNELS, ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_MINERAL_STOREROOM)

/obj/item/card/id/ert/vdv

/obj/item/card/id/ert/vdv/Initialize(mapload)
	. = ..()

	access = list(ACCESS_CENT_GENERAL, ACCESS_CENT_LIVING, ACCESS_MAINT_TUNNELS, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_MINERAL_STOREROOM)

/datum/outfit/ert/vdv
	name = "NRI VDV Soldier"

	shirt = /obj/item/clothing/underwear/shirt/striped
	uniform = /obj/item/clothing/under/pants/camo
	suit = /obj/item/clothing/suit/armor/nri_vest
	suit_store = /obj/item/melee/classic_baton
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	gloves = /obj/item/clothing/gloves/fingerless
	ears = /obj/item/radio/headset/headset_cent/alt
	head = /obj/item/clothing/head/HoS/beret/nri
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	belt = /obj/item/storage/belt/security/vdv
	id = /obj/item/card/id/nri
	back = /obj/item/storage/backpack/rucksack
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
							/obj/item/ammo_box/magazine/m10mm=3)

	l_hand = /obj/item/gun/ballistic/automatic/pistol

	implants = list(/obj/item/implant/mindshield)

/datum/outfit/ert/vdv/pre_equip(mob/living/carbon/human/H)
	if (prob(50))
		back = /obj/item/shield/riot/flash
	else
		back = /obj/item/storage/backpack
		backpack_contents = list(
			/obj/item/storage/box/survival/engineer=1,
			/obj/item/storage/pill_bottle/zvezdochka=1,
			/obj/item/ammo_box/magazine/m10mm,
			)
	if (prob(25))
		r_hand = /obj/item/gun/ballistic/rocketlauncher/unrestricted // Да. ВДВшник с РПГ. И что?
		l_hand = /obj/item/ammo_casing/caseless/rocket

/datum/outfit/ert/vdv/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/headset_sec
	R.recalculateChannels()

	var/obj/item/card/id/W = H.wear_id
	W.assignment = name
	W.registered_name = H.real_name
	W.update_label()

/datum/outfit/ert/vdv/leader
	name = "NRI VDV Leader"

	suit_store = /obj/item/gun/ballistic/automatic/pistol/APS
	gloves = /obj/item/clothing/gloves/color/black
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	belt = /obj/item/storage/belt/military/army/vdv
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(
		/obj/item/storage/pill_bottle/zvezdochka = 1,
		/obj/item/ammo_box/magazine/ak12 = 4,
		)

	r_hand = /obj/item/gun/ballistic/automatic/ak12

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/vdv/leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/vdv/leader/post_equip(mob/living/carbon/human/H, visualsOnly)
	. = ..()

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()
	var/obj/item/card/id/W = H.wear_id
	W.assignment = name
	W.registered_name = H.real_name
	W.update_label()

/obj/item/storage/belt/military/army/vdv

/obj/item/storage/belt/military/army/vdv/PopulateContents()
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)
	new /obj/item/grenade/flashbang(src)
	new /obj/item/grenade/chem_grenade/teargas(src)
	new /obj/item/grenade/frag/mega(src)
	new /obj/item/grenade/syndieminibomb/concussion(src)

/obj/item/storage/belt/security/vdv

/obj/item/storage/belt/security/vdv/PopulateContents()
	new /obj/item/grenade/flashbang(src)
	new	/obj/item/grenade/stingbang(src)
	new /obj/item/grenade/chem_grenade/teargas(src)
	new /obj/item/restraints/handcuffs/cable/zipties(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)

