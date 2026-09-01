//If you're looking for spawners like ash walker eggs, check ghost_role_spawners.dm

/obj/structure/fans/tiny/invisible //For blocking air in ruin doorways
	invisibility = INVISIBILITY_ABSTRACT

///Wizard tower item
/obj/item/disk/design_disk/adv/knight_gear
	name = "Magic Disk of Smithing"

/obj/item/disk/design_disk/adv/knight_gear/Initialize(mapload)
	. = ..()
	var/datum/design/knight_armour/A = new
	var/datum/design/knight_helmet/H = new
	blueprints[1] = A
	blueprints[2] = H

//lavaland_surface_seed_vault.dmm
//Seed Vault

/obj/effect/spawner/lootdrop/seed_vault
	name = "seed vault seeds"
	lootcount = 1

	loot = list(/obj/item/seeds/gatfruit = 10,
				/obj/item/seeds/cherry/bomb = 10,
				/obj/item/seeds/berry/glow = 10,
				/obj/item/seeds/sunflower/moonflower = 8
				)

/obj/item/disk/design_disk/plant_disk
	name = "Plant Disk Blueprints"
	desc = "A disk to be uploaded into the autolathen for more plant disks."
	icon_state = "datadisk1"
	max_blueprints = 1

/obj/item/disk/design_disk/plant_disk/Initialize(mapload)
	. = ..()
	var/datum/design/diskplantgene/P = new
	blueprints[1] = P

//Free Golems

/obj/item/disk/design_disk/golem_shell
	name = "Golem Creation Disk"
	desc = "A gift from the Liberator."
	icon_state = "datadisk1"
	max_blueprints = 1

/obj/item/disk/design_disk/golem_shell/Initialize(mapload)
	. = ..()
	var/datum/design/golem_shell/G = new
	blueprints[1] = G

/datum/design/golem_shell
	name = "Golem Shell Construction"
	desc = "Allows for the construction of a Golem Shell."
	id = "golem"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 40000)
	build_path = /obj/item/golem_shell
	category = list("Imported")

/obj/item/golem_shell
	name = "incomplete free golem shell"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "construct"
	desc = "The incomplete body of a golem. Add ten sheets of any mineral to finish."
	var/shell_type = /obj/effect/mob_spawn/human/golem
	var/has_owner = FALSE //if the resulting golem obeys someone
	w_class = WEIGHT_CLASS_BULKY

/obj/item/golem_shell/attackby(obj/item/I, mob/user, params)
	..()
	var/static/list/golem_shell_species_types = list(
		/obj/item/stack/sheet/metal	                = /datum/species/golem,
		/obj/item/stack/sheet/glass 	            = /datum/species/golem/glass,
		/obj/item/stack/sheet/plasteel 	            = /datum/species/golem/plasteel,
		/obj/item/stack/sheet/mineral/sandstone	    = /datum/species/golem/sand,
		/obj/item/stack/sheet/mineral/plasma	    = /datum/species/golem/plasma,
		/obj/item/stack/sheet/mineral/diamond	    = /datum/species/golem/diamond,
		/obj/item/stack/sheet/mineral/gold	        = /datum/species/golem/gold,
		/obj/item/stack/sheet/mineral/silver	    = /datum/species/golem/silver,
		/obj/item/stack/sheet/mineral/uranium	    = /datum/species/golem/uranium,
		/obj/item/stack/sheet/mineral/bananium	    = /datum/species/golem/bananium,
		/obj/item/stack/sheet/mineral/titanium	    = /datum/species/golem/titanium,
		/obj/item/stack/sheet/mineral/plastitanium	= /datum/species/golem/plastitanium,
		/obj/item/stack/sheet/mineral/abductor	    = /datum/species/golem/alloy,
		/obj/item/stack/sheet/mineral/wood	        = /datum/species/golem/wood,
		/obj/item/stack/sheet/bluespace_crystal	    = /datum/species/golem/bluespace,
		/obj/item/stack/sheet/runed_metal	        = /datum/species/golem/runic,
		/obj/item/stack/medical/gauze	            = /datum/species/golem/cloth,
		/obj/item/stack/sheet/cloth	                = /datum/species/golem/cloth,
		/obj/item/stack/sheet/mineral/adamantine	= /datum/species/golem/adamantine,
		/obj/item/stack/sheet/plastic	            = /datum/species/golem/plastic,
		/obj/item/stack/tile/brass					= /datum/species/golem/clockwork,
		/obj/item/stack/sheet/bronze					= /datum/species/golem/bronze,
		/obj/item/stack/sheet/cardboard				= /datum/species/golem/cardboard,
		/obj/item/stack/sheet/leather				= /datum/species/golem/leather,
		/obj/item/stack/sheet/bone					= /datum/species/golem/bone,
		/obj/item/stack/sheet/cotton/durathread		= /datum/species/golem/durathread)

	if(istype(I, /obj/item/stack))
		var/obj/item/stack/O = I
		var/species = golem_shell_species_types[O.merge_type]
		if(species)
			if(O.use(10))
				to_chat(user, "You finish up the golem shell with ten sheets of [O].")
				new shell_type(get_turf(src), species, user)
				qdel(src)
			else
				to_chat(user, "You need at least ten sheets to finish a golem.")
		else
			to_chat(user, "You can't build a golem out of this kind of material.")

//made with xenobiology, the golem obeys its creator
/obj/item/golem_shell/servant
	name = "incomplete servant golem shell"
	shell_type = /obj/effect/mob_spawn/human/golem/servant

///Syndicate Listening Post

/obj/effect/mob_spawn/human/lavaland_syndicate
	name = "DS-1 Lavaland Specialist"
	mob_name = "a Syndicate 'Dune' Researcher"
	roundstart = FALSE
	death = FALSE
	job_description = "Off-station Syndicate Specialist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Научный Специалист Синдиката, работающий на Аванпосту Лаваленда и изучающий аномальное поле Системы Синих Лун."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	category = "syndicate"
	make_bank_account = TRUE // BLUEMOON ADD
	starting_money = 1000 // BLUEMOON ADD

/obj/effect/mob_spawn/human/lavaland_syndicate/special(mob/living/new_spawn)
	. = ..()
	new_spawn.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)

/datum/outfit/lavaland_syndicate
	name = "Off-station Syndicate Agent"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/toggle/labcoat
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/ds1
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/lavaland/researcher
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)

	accessory = list(/obj/item/clothing/accessory/permit/special/deep_space_syndicate)

/datum/outfit/lavaland_syndicate/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.faction |= ROLE_SYNDICATE

/obj/effect/mob_spawn/human/lavaland_syndicate/shaft
	name = "DS-1 Security Agent"
	mob_name = "a Syndicate 'Dune' Combatant"
	roundstart = FALSE
	death = FALSE
	job_description = "Syndicate Security Specialist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Специалист по обеспечению безопасности Синдиката, работающий на Аванпосту Лаваленда и изучающий аномальное поле Системы Синих Лун. Вы второй по главенству оперативник после Специалиста Прослушки на Дюне."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate/shaft
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE

/datum/outfit/lavaland_syndicate/shaft
	name = "Off-station Syndicate Security Specialist"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	//neck = /obj/item/clothing/neck/baron
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/ds1
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/lavaland/security
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)

/obj/effect/mob_spawn/human/lavaland_syndicate/comms
	name = "Syndicate Comms Agent"
	job_description = "Off-station Syndicate Comms Agent"
	short_desc = "Вы Специалист Разведки Синдиката, работающий на Аванпосту Лаваленда и изучающий аномальное поле Системы Синих Лун. Вы первый по главенству оперативник после Специалиста Прослушки на Дюне и исполняете Главенствующую Роль на своём объекте."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Мега-Корпорации Nanotrasen, начали добычу полезных ископаемых в этом секторе. Следите за вражеской активностью как можно лучше и старайтесь не высовываться. Используйте коммуникационное оборудование для оказания поддержки любым полевым агентам и сотрудникам Космической Станции."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate/comms
	can_load_appearance = TRUE

/*
/obj/effect/mob_spawn/human/lavaland_syndicate/comms/space/Initialize(mapload)
	. = ..()
	if(prob(1)) //only has a 99% chance of existing, otherwise it'll just be a NPC syndie.
		new /mob/living/simple_animal/hostile/syndicate/ranged(get_turf(src))
		return INITIALIZE_HINT_QDEL
*/

/datum/outfit/lavaland_syndicate/comms
	name = "Syndicate Comms Agent"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	mask = /obj/item/clothing/mask/chameleon/gps
	neck = /obj/item/clothing/neck/cloak/syndiecap
	suit = /obj/item/clothing/suit/armor/vest
	ears = /obj/item/radio/headset/ds1/comms
	id = /obj/item/card/id/syndicate/anyone/comms
	back = /obj/item/storage/backpack/duffelbag/syndie

/obj/item/clothing/mask/chameleon/gps/Initialize(mapload)
	. = ..()
	new /obj/item/gps/internal/lavaland_syndicate_base(src)

/obj/item/gps/internal/lavaland_syndicate_base
	gpstag = "Encrypted Signal"

/obj/item/radio/headset/ds1
	name = "DS-1 Headset"
	desc = "A bowman headset with a large red cross on the earpiece, has a small 'IP' written on the top strap. Protects the ears from flashbangs."
	icon_state = "syndie_headset"
	radiosound = 'modular_sand/sound/radio/syndie.ogg'
	freqlock = TRUE
	keyslot = new /obj/item/encryptionkey/headset_syndicate/ds1

/obj/item/radio/headset/ds2
	name = "DS-2 Headset"
	desc = "A bowman headset with a large red cross on the earpiece, has a small 'IP' written on the top strap. Protects the ears from flashbangs."
	icon_state = "syndie_headset"
	radiosound = 'modular_sand/sound/radio/syndie.ogg'
	freqlock = TRUE
	keyslot = new /obj/item/encryptionkey/headset_syndicate/ds2

/obj/item/radio/headset/ds2/command
	name = "DS-2 Command Headset"
	desc = "A commanding headset to gather your underlings. Protects the ears from flashbangs."
	keyslot = new /obj/item/encryptionkey/headset_syndicate/ds2
	keyslot2 = new /obj/item/encryptionkey/headset_syndicate/ds1
	command = TRUE

/obj/item/radio/headset/ds1/comms
	name = "Universal DS Command Headset"
	desc = "A commanding headset to gather your underlings. Protects the ears from flashbangs."
	keyslot = new /obj/item/encryptionkey/headset_syndicate/ds2
	keyslot2 = new /obj/item/encryptionkey/headset_syndicate/ds1
	command = TRUE

/obj/effect/mob_spawn/human/lavaland_syndicate/medic
	name = "DS-1 Bioweapon Researcher"
	mob_name = "a Syndicate 'Dune' Virologist"
	roundstart = FALSE
	death = FALSE
	job_description = "Off-station Syndicate Medical Specialist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Медицинский Специалист и Вирусолог Синдиката, работающий на Аванпосту Лаваленда и изучающий вирусное воздействие на организмы живых существ."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate/medic
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE

/datum/outfit/lavaland_syndicate/medic
	name = "Off-station Medical Agent"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	uniform = /obj/item/clothing/under/syndicate/scrubs
	suit = /obj/item/clothing/suit/toggle/labcoat/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	ears = /obj/item/radio/headset/ds1
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/storage/firstaid/tactical = 1,
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/lavaland/virologist
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)

/obj/effect/mob_spawn/human/lavaland_syndicate/engineer
	name = "DS-1 Nuсlear Reactor Specialist"
	mob_name = "a Syndicate 'Dune' Nuclear Technician"
	roundstart = FALSE
	death = FALSE
	job_description = "Off-station Syndicate Nuсlear Reactor Specialist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Специалист по запуску и обслуживанию ядерного реактора Синдиката, работающий на Аванпосту Лаваленда и исполняющий обязаности инженера."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate/engineer
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE

/datum/outfit/lavaland_syndicate/engineer
	name = "Off-station Nuclear Reactor Agent"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	uniform = /obj/item/clothing/under/syndicate/overalls
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/ds1
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/lavaland/nucleartech
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)

/obj/effect/mob_spawn/human/lavaland_syndicate/Mime
	name = "DS-1 Mime Operative"
	mob_name = "a Syndicate 'Dune' Mime"
	roundstart = FALSE
	death = FALSE
	job_description = "Off-station Syndicate Mime operative"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Мим Синдиката, работающий на Аванпосту Лаваленда и исполняющий обязанности разнорабочего. Удоволетворите потребности персонала. И помните - ни слова."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/lavaland_syndicate/mime
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE

/datum/outfit/lavaland_syndicate/mime
	name = "Off-station Syndicate Mime operative"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	l_hand = /obj/item/reagent_containers/food/drinks/bottle/bottleofnothing
	uniform = /obj/item/clothing/under/rank/civilian/mime
	suit = null
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/ds1
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/lavaland/mime
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)

/obj/effect/mob_spawn/human/lavaland_syndicate/offcomm
	name = "DS-1 Communications Officer"
	mob_name = "a Syndicate 'Dune' Leader"
	roundstart = FALSE
	death = FALSE
	job_description = "Off-station Syndicate Communications Officer"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Офицер Коммуникаций, работающий на Аванпосту Лаваленда и руководящий объектом. Обеспечьте функционирование ввереного вам аванпоста, поддерживайте связь с адмиралом и представителем Триглава, дислоцированных на объекте DS-2. Проводите отчётную деятельность."
	flavour_text = "К сожалению это или к счастью, но сотрудники вашего партнёра, Nanotrasen, начали добычу полезных ископаемых в этом секторе. Продолжайте свои исследования как можно лучше и старайтесь особо не высовываться, и не провоцировать этих же самых сотрудников."
	important_info = "Вы не антагонист. Вы стоите ниже представителя Триглава и Адмирала DS-2 в иерархии."
	outfit = /datum/outfit/lavaland_syndicate/offcomm
	assignedrole = "Lavaland Syndicate"
	can_load_appearance = TRUE
	loadout_enabled = TRUE

/datum/outfit/lavaland_syndicate/offcomm
	name = "Off-station Syndicate Communications Officer"
	r_hand = /obj/item/melee/transforming/energy/sword/saber
	uniform = /obj/item/clothing/under/syndicate/enclave_alt
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/ds1/comms
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/lighter/gonzofist = 1
		)
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	id = /obj/item/card/id/syndicate/advanced/ds/gold/offcomm
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/anchor, /obj/item/implant/deathrattle/deepspacecrew)
