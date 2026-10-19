//Main code edits
/obj/item/clothing/suit/space/hardsuit/Initialize()
	. = ..()
	if(type == /obj/item/clothing/suit/space/hardsuit)
		icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
		mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
		anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'

/obj/item/clothing/head/helmet/space/hardsuit/Initialize()
	. = ..()
	if(type == /obj/item/clothing/head/helmet/space/hardsuit)
		mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'

//Own stuff
/obj/item/clothing/head/helmet/space/hardsuit/rd/hev
	name = "HEV Suit helmet"
	desc = "A Hazardous Environment Helmet. It fits snug over the suit and has a heads-up display for researchers. The flashlight seems broken, fitting considering this was made before the start of the millennium."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "hev"
	item_state = "hev"
	resistance_flags = ACID_PROOF | FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	armor_type = /datum/armor/hev_suit
	actions_types = list(/datum/action/item_action/toggle_research_scanner)

/obj/item/clothing/head/helmet/space/hardsuit/rd/hev/no_scanner
	actions_types = list()

/obj/item/clothing/suit/space/hardsuit/rd/hev
	name = "HEV Suit"
	desc = "The hazard suit. It was designed to protect scientists from the blunt trauma, radiation, energy discharge that hazardous materials might produce or entail. Fits you like a glove. The automatic medical system seems broken... They're waiting for you, Gordon. In the test chamber."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'
	icon_state = "hev"
	item_state = "hev"
	tail_state = "hev"
	resistance_flags = ACID_PROOF | FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT //Same as an emergency firesuit. Not ideal for extended exposure.
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAUR|HIDETAIL
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/gun/energy/wormhole_projector,
	/obj/item/hand_tele, /obj/item/aicard)
	armor_type = /datum/armor/hev_suit
	brc_mitigation_bonus = 10  // BLUEMOON ADD
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC //bluemoon add
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/rd/hev
	var/firstpickup = TRUE
	var/pickupsound = TRUE

/obj/item/clothing/suit/space/hardsuit/rd/hev/no_sound
	pickupsound = FALSE

/obj/item/clothing/suit/space/hardsuit/rd/hev/Initialize(mapload)
	. = ..()
	allowed = GLOB.security_hardsuit_allowed

/obj/item/clothing/suit/space/hardsuit/rd/hev/equipped(mob/user, slot)
	. = ..()
	if(!pickupsound)
		return
	if(!ishuman(user))
		return
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!firstpickup)
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/hevsuit_pickup.ogg', volume = 50))
		else
			firstpickup = FALSE
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/hevsuit_firstpickup.ogg', volume = 50))
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/anomalous_materials.ogg', volume = 50))
	return

/obj/item/clothing/head/helmet/space/hardsuit/rd/hev/cosmetic
	resistance_flags = null
	max_heat_protection_temperature = null
	armor_type = /datum/armor/bio100
	actions_types = list()

/obj/item/clothing/suit/space/hardsuit/rd/hev/cosmetic
	resistance_flags = null
	max_heat_protection_temperature = null
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/gun/energy/wormhole_projector, /obj/item/hand_tele, /obj/item/aicard)
	armor_type = /datum/armor/bio100
	brc_mitigation_bonus = 0  // BLUEMOON ADD
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/rd/hev/cosmetic
	actions_types = list(/datum/action/item_action/toggle_helmet, /datum/action/item_action/toggle_cool_music)
	firstpickup = list('modular_splurt/sound/halflife/hevsuit_pickup.ogg')

/obj/item/clothing/suit/space/hardsuit/rd/hev/cosmetic/Initialize()
	. = ..()

/obj/item/clothing/suit/space/hardsuit/rd/hev/cosmetic/equipped(slot)
	. = ..()

/obj/item/clothing/suit/space/hardsuit/shielded/goldenpa
	name = "Nanotrasen Power Armor"
	desc = "An advanced armor with built in energy shielding, developed by Nanotrasen via unknown means. It belongs by only few exclusive members of the corporation."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'
	icon_state = "golden_pa"
	item_state = "golden_pa"
	max_charges = 4
	current_charges = 4
	recharge_delay = 15
	armor_type = /datum/armor/deathsquad_and_shielded
	brc_mitigation_bonus = 25  // BLUEMOON ADD
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/goldenpa
	mutantrace_variation = STYLE_MUZZLE | STYLE_ALL_TAURIC
	slowdown = 0

/obj/item/clothing/suit/space/hardsuit/shielded/goldenpa/Initialize()
	jetpack = new /obj/item/tank/jetpack/suit(src)
	. = ..()

/obj/item/clothing/head/helmet/space/hardsuit/shielded/goldenpa
	name = "Nanotrasen Power Helmet"
	desc = "An advanced armor helmet with built in energy shielding, developed by Nanotrasen via unknown means. It belongs by only few exclusive members of the corporation."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "hardsuit0-goldenpa"
	item_state = "hardsuit0-goldenpa"
	hardsuit_type = "goldenpa"
	armor_type = /datum/armor/deathsquad_and_shielded
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/obj/item/clothing/suit/space/hardsuit/teslapa
	name = "Tesla Power Armor"
	desc = "An advanced power armor, with built-in tesla technology. You're sure this will fry whoever dares attack in close quarters."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'
	icon_state = "tesla_pa"
	item_state = "tesla_pa"
	armor_type = /datum/armor/teslapa_suit
	brc_mitigation_bonus = 25  // BLUEMOON ADD
	strip_delay = 300
	equip_delay_self = 300
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/teslapahelmet
	slowdown = 1
	siemens_coefficient = -1
	blood_overlay_type = "armor"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/hit_reaction_chance = 50
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	var/teslapa_cooldown = 20
	var/teslapa_cooldown_duration = 10
	var/tesla_power = 20000
	var/tesla_range = 4
	var/tesla_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE
	var/legacy = FALSE
	var/legacy_dmg = 35

/obj/item/clothing/suit/space/hardsuit/teslapa/Initialize()
	jetpack = new /obj/item/tank/jetpack/suit(src)
	. = ..()

/obj/item/clothing/suit/space/hardsuit/teslapa/dropped(mob/user)
	..()
	if(istype(user))
		REMOVE_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "reactive_teslapa_armor")

/obj/item/clothing/suit/space/hardsuit/teslapa/equipped(mob/user, slot)
	..()
	if(slot_flags & slot) //Was equipped to a valid slot for this item?
		ADD_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "reactive_teslapa_armor")

/obj/item/clothing/suit/space/hardsuit/teslapa/run_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = ATTACK_TYPE_MELEE)
	if(prob(hit_reaction_chance))
		if(world.time < teslapa_cooldown_duration)
			var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
			sparks.set_up(1, 1, src)
			sparks.start()
			owner.visible_message("<span class='danger'>The tesla capacitors on [owner]'s Tesla Power Armor are still recharging! The armor merely emits some sparks.</span>")
			return
		owner.visible_message("<span class='danger'>[src] blocks [attack_text], sending out arcs of lightning!</span>")
		if(!legacy)
			tesla_zap(owner, tesla_range, tesla_power, tesla_flags)
		else
			for(var/mob/living/M in view(2, owner))
				if(M == owner)
					continue
				owner.Beam(M,icon_state="purple_lightning",icon='icons/effects/effects.dmi',time=5)
				M.adjustFireLoss(legacy_dmg)
				playsound(M, 'sound/machines/defib_zap.ogg', 50, 1, -1)
		teslapa_cooldown = world.time + teslapa_cooldown_duration
		return TRUE

/obj/item/clothing/head/helmet/space/hardsuit/teslapahelmet
	name = "Tesla Power Armor Helmet"
	desc = "An advanced power armor, with built-in tesla technology. You're sure this will fry whoever dares attack in close quarters."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "teslaup"
	item_state = "teslaup"
	armor_type = /datum/armor/teslapa_suit
	strip_delay = 130
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/obj/item/clothing/head/helmet/space/hardsuit/teslapahelmet/update_icon_state()
	return

/obj/item/clothing/suit/space/hardsuit/advancedpa
	name = "Advanced Power Armor"
	desc = "An advanced power armor. You're sure this is near to impossible to penetrate in close quarters."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'
	icon_state = "advanced_pa"
	item_state = "advanced_pa"
	armor_type = /datum/armor/advancedpa_suit
	brc_mitigation_bonus = 30  // BLUEMOON ADD
	strip_delay = 300 //chonky armor means chonky strip
	equip_delay_self = 300
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/advancedpahelmet
	slowdown = 0
	blood_overlay_type = "armor"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/clothing/suit/space/hardsuit/advancedpa/Initialize()
	jetpack = new /obj/item/tank/jetpack/suit(src)
	. = ..()

/obj/item/clothing/head/helmet/space/hardsuit/advancedpahelmet
	name = "Advanced Power Armor Helmet"
	desc = "An advanced power armor. You're sure this is almost impenetrable in close quarters."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "adv_pa"
	item_state = "adv_pa"
	armor_type = /datum/armor/advancedpa_suit
	strip_delay = 300
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

/obj/item/clothing/head/helmet/space/hardsuit/advancedpahelmet/update_icon_state()
	return

/obj/item/clothing/head/helmet/space/hardsuit/corpus
	name = "Corpus Ranger Helmet"
	desc = "The helmet component of a Corpus Ranger hardsuit, has a flashlight!."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	icon_state = "hardsuit0-corpus"
	item_state = "hardsuit0-corpus"
	armor_type = /datum/armor/corpus_helmet
	strip_delay = 300
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	hardsuit_type = "corpus"
	actions_types = list(/datum/action/item_action/toggle_helmet_light)

/obj/item/clothing/suit/space/hardsuit/corpus
	name = "Corpus Ranger Hardsuit"
	desc = "A specially designed Corpus hardsuit that protects against space. Has energy shielding, though the device has faltered slightly with age."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	icon_state = "hardsuit-corpus"
	item_state = "hardsuit-corpus"
	max_integrity = 300
	armor_type = /datum/armor/corpus_suit
	brc_mitigation_bonus = 5  // BLUEMOON ADD
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/t_scanner, /obj/item/construction/rcd, /obj/item/pipe_dispenser)
	siemens_coefficient = 0
	actions_types = list(/datum/action/item_action/toggle_helmet)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/corpus
