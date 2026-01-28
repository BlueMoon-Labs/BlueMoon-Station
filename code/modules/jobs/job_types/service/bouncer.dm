/datum/job/bouncer
	title = "Bouncer"
	flag = BOUNCER
	department_head = list("Head of Personnel")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the head of personnel"
	selection_color = "#bbe291"
	exp_type_department = EXP_TYPE_SERVICE // This is so the jobs menu can work properly

	outfit = /datum/outfit/job/bouncer
	plasma_outfit = /datum/outfit/plasmaman/bar

	access = list(ACCESS_HYDROPONICS, ACCESS_BAR, ACCESS_KITCHEN, ACCESS_MORGUE, ACCESS_WEAPONS, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_BAR, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_SRV
	bounty_types = CIV_JOB_DRINK
	display_order = JOB_DISPLAY_ORDER_BOUNCER
	threat = 1
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/nonviolent, /datum/quirk/blindness, /datum/quirk/monophobia)
	custom_spawn_text = "ваша задача — помогать сервисным сотрудникам обеспечивать порядок и спокойствие в их кабинетах и отделах, а также выполнять небольшие поручения. Не выполняйте работу офицеров за них самих."

	family_heirlooms = list(
		/obj/item/toy/plush/beeplushie,
	)

	alt_titles = list(
		"Bodyguard",
		"Hired Muscle",
		"Service Guard",
		"Barmaid Sentinel",
		"Slapper",
		"Cocksucker"
		)

/////////////////////////////

/obj/item/pda/bouncer
	name = "bouncer PDA"
	icon_state = "pda-bartender"
	default_cartridge = /obj/item/cartridge/bartender //BLUEMOON EDIT Uncomment
	inserted_item = /obj/item/pen/fountain

/datum/outfit/job/bouncer
	name = "Bouncer"
	jobtype = /datum/job/bouncer

	glasses = /obj/item/clothing/glasses/sunglasses
	belt = /obj/item/pda/bouncer
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/syndicate/tacticool
	//suit =
	backpack_contents = list(/obj/item/reagent_containers/spray/pepper=1, /obj/item/gun/energy/civilian=1, /obj/item/restraints/legcuffs/bola/energy=1, /obj/item/restraints/handcuffs/cable/zipties=2, /obj/item/choice_beacon/bouncer=1)
	shoes = /obj/item/clothing/shoes/jackboots
	accessory = list(/obj/item/clothing/accessory/permit/special/bouncer)

/datum/outfit/job/bouncer/syndicate
	name = "Syndicate Bouncer"
	jobtype = /datum/job/bouncer

	belt = /obj/item/pda/bouncer

	glasses = /obj/item/clothing/glasses/sunglasses
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/syndicate
	//suit =
	shoes = /obj/item/clothing/shoes/jackboots

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	accessory = list(/obj/item/clothing/accessory/permit/special/bouncer)

	backpack_contents = list(/obj/item/reagent_containers/spray/pepper=1, /obj/item/restraints/handcuffs/cable/zipties=2, /obj/item/choice_beacon/copgun=1, /obj/item/syndicate_uplink=1)

//BLUEMOON ADD
/datum/martial_art/krav_maga/restricted/bouncer
	name = "Krav Maga (bouncer edition)"
	valid_areas = list(/area/service/bar/atrium, /area/service/bar)
	resist_grab_chance = 40

/obj/item/choice_beacon/bouncer
	name = "personal weapon beacon"
	desc = "Use this to summon your personal issued sidearm!"

/obj/item/choice_beacon/bouncer/generate_display_names()
	var/static/list/gun_list
	if(!gun_list)
		gun_list = list()
		var/list/templist = subtypesof(/obj/item/storage/secure/briefcase/bouncer/)
		for(var/V in templist)
			var/atom/A = V
			gun_list[initial(A.name)] = A
	return gun_list

/obj/item/storage/secure/briefcase/bouncer/advtaser_box
	name = "\improper Hybrid taser gun box"
	desc = "A storage case for a high-tech energy firearm."

/obj/item/storage/secure/briefcase/bouncer/advtaser_box/PopulateContents()
	new /obj/item/gun/energy/e_gun/advtaser(src)

/obj/item/storage/secure/briefcase/bouncer/e45_box
	name = "\improper Enforcer handgun box"
	desc = "A storage case for a Mk. 58 Enforcer. Peace through power!"

/obj/item/storage/secure/briefcase/bouncer/e45_box/PopulateContents()
	var/obj/item/gun/ballistic/automatic/pistol/enforcer/pistol = new /obj/item/gun/ballistic/automatic/pistol/enforcer/nomag(src)
	var/pin_type = initial(/obj/item/gun/ballistic/automatic/pistol/enforcer::pin)
	if(pin_type)
		QDEL_NULL(pistol.pin)
		pistol.pin = new pin_type(pistol) // Нет никого смысла ограничивать пистолет баунсеру на синий код, это не СБ
	new /obj/item/ammo_box/magazine/e45/taser(src)
	new /obj/item/ammo_box/magazine/e45/taser(src)
	new /obj/item/ammo_box/magazine/e45/taser(src)
//BLUEMOON ADD END
/*
/datum/martial_art/bouncer
	name = "Bouncer martial art"
	id = MARTIALART_BOUNCER
	//pugilist = TRUE
	var/datum/action/bounce/bounce = new/datum/action/bounce()

/datum/martial_art/bouncer/proc/check_streak(var/mob/living/carbon/human/A, var/mob/living/carbon/human/D)
	if(!can_use(A, D))
		return FALSE
	switch(streak)
		if("do_bounce")
			streak = ""
			do_bounce(A,D)
			return TRUE
	return FALSE

/datum/martial_art/bouncer/teach(mob/living/carbon/human/H,make_temporary=0)
	if(..())
		bounce.Grant(H)

/datum/martial_art/bouncer/on_remove(mob/living/carbon/human/H)
	bounce.Remove(H)

/datum/action/bounce
	name = "Bounce"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "legsweep"

/datum/action/bounce/Trigger()
	if(owner.incapacitated())
		to_chat(owner, "<span class='warning'>You can't bounce while you're incapacitated.</span>")
		return
	var/mob/living/carbon/human/H = owner
	if (H.mind.martial_art.streak == "do_bounce")
		owner.visible_message("<span class='danger'>[owner] assumes a neutral stance.</span>", "<b><i>Your next attack is cleared.</i></b>")
		H.mind.martial_art.streak = ""
	else
		if(HAS_TRAIT(H, TRAIT_PACIFISM))
			to_chat(H, "<span class='warning'>You don't want to harm other people!</span>")
			return
		owner.visible_message("<span class='danger'>[owner] assumes the Bouncer stance!</span>", "<b><i>Your next attack will be a Bounce.</i></b>")
		H.mind.martial_art.streak = "do_bounce"

/datum/martial_art/bouncer/proc/do_bounce(mob/living/carbon/human/A, mob/living/carbon/human/D)
	var/damage = (damage_roll(A,D) + 3)
	A.do_attack_animation(D, ATTACK_EFFECT_KICK)
	D.visible_message("<span class='warning'>[A] kicks [D] square in the chest, sending them flying!</span>", \
					"<span class='userdanger'>You are kicked square in the chest by [A], sending you flying!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, A)
	playsound(get_turf(A), 'sound/effects/hit_kick.ogg', 50, TRUE, -1)
	var/atom/throw_target = get_edge_target_turf(D, A.dir)
	D.throw_at(throw_target, 5, 9, A)
	D.apply_damage(damage, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND, wound_bonus = CANT_WOUND)
	log_combat(A, D, "bounced")
	return TRUE

/datum/martial_art/bouncer/harm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(check_streak(A,D))
		return TRUE
	..()
*/
/datum/outfit/job/bouncer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(visualsOnly)
		return
	var/datum/martial_art/krav_maga/restricted/bouncer/B = new //BLUEMOON CHANGE
	B.teach(H)
