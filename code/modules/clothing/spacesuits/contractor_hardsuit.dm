//contractor hardsuit

/obj/item/clothing/head/helmet/space/hardsuit/contractor
	name = "Contractor Hardsuit Helmet"
	desc = "A top-tier syndicate helmet, a favorite of Syndicate field Contractors. Property of the Gorlex Marauders, with assistance from Cybersun Industries."
	icon_state = "hardsuit0-contractor"
	item_state = "contractor_helm"
	hardsuit_type = "contractor"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 30, BOMB = 35, BIO = 100, RAD = 75, FIRE = 75, ACID = 90, WOUND = 40)
	actions_types = list(/datum/action/item_action/toggle_helmet_light)

/obj/item/clothing/suit/space/hardsuit/contractor
	name = "Contractor Hardsuit"
	desc = "A top-tier syndicate hardsuit, a favorite of Syndicate field Contractors. Property of the Gorlex Marauders, with assistance from Cybersun Industries."
	icon_state = "hardsuit-contractor"
	item_state = "contractor_hardsuit"
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 30, BOMB = 35, BIO = 100, RAD = 75, FIRE = 75, ACID = 90, WOUND = 40)
	slowdown = 0
	w_class = WEIGHT_CLASS_NORMAL
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC //bluemoon add
	flags_inv = HIDEGLOVES | HIDEJUMPSUIT | HIDESHOES | HIDETAUR
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/contractor
	jetpack = /obj/item/tank/jetpack/suit
	allowed = list(/obj/item/gun, /obj/item/ammo_box,/obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	actions_types = list(/datum/action/item_action/toggle_helmet, /datum/action/item_action/advanced/chameleon_upgrade, /datum/action/item_action/advanced/hook_upgrade)
	//working as ninja hook, deleted when droped
	var/obj/item/gun/magic/contractor_hook/scorpion
	var/disguise = FALSE

/obj/item/clothing/suit/space/hardsuit/contractor/Destroy()
	. = ..()
	QDEL_NULL(scorpion)

/obj/item/clothing/suit/space/hardsuit/contractor/ui_action_click(user, action)
	if(istype(action, /datum/action/item_action/toggle_helmet))
		ToggleHelmet()
		return TRUE
	if(istype(action, /datum/action/item_action/advanced/chameleon_upgrade))
		toggle_chameleon()
		return TRUE
	if(istype(action, /datum/action/item_action/advanced/hook_upgrade))
		toggle_hook()
		return TRUE
	else
		return FALSE

/obj/item/clothing/suit/space/hardsuit/contractor/proc/update_suit()
	var/mob/living/carbon/human/H = src.loc
	H.update_inv_head()
	H.update_inv_wear_suit()

/*
		Hook
		Much worse version of lava and ninja hook for balance reasons.

*/
/datum/action/item_action/advanced/hook_upgrade
	name = "Hardsuit SCORPION hook module"
	desc = "A module installed in the wrist of your hardsuit, this highly illegal module uses a hardlight hook to forcefully pull a target towards you at high speed, knocking them down and partially exhausting them."
	charge_type = ADV_ACTION_TYPE_TOGGLE_RECHARGE
	charge_max = 6 SECONDS
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "hook"
	button_icon = 'icons/mob/actions/actions.dmi'

/obj/item/clothing/suit/space/hardsuit/contractor/proc/toggle_hook()
	if(scorpion)  //BLUEMOON EDIT START Обнуление переменной было перенесено в конец, поскольку в прошлом прочие переменные ссылались на пустую переменную, вызывая runtime ошибки
		playsound(src.loc, 'sound/mecha/mechmove03.ogg', 50, 1)
		to_chat(usr, "<span class='notice'>Вы возвращаете [scorpion] обратно под кисть бронекостюма.</span>")
		for (var/datum/action/item_action/advanced/hook_upgrade/hook in actions)
			scorpion.hook_action = hook
			hook.action_ready = FALSE
			hook.toggle_button_on_off()
		qdel(scorpion)
		scorpion = null //BLUEMOON EDIT END
	else
		scorpion = new
		scorpion.suit = src
		for(var/datum/action/item_action/advanced/hook_upgrade/hook in actions)
			scorpion.hook_action = hook
			hook.action_ready = TRUE
			hook.toggle_button_on_off()
			break
		usr.put_in_hands(scorpion)
		playsound(src.loc, 'sound/mecha/mechmove03.ogg', 50, 1)
		to_chat(usr, "<span class='notice'>Вы активировали [scorpion].</span>")

/datum/action/item_action/advanced/hook_upgrade/toggle_button_on_off()
	if(action_ready)
		background_icon_state = icon_state_active
		UpdateButton()
	else
		background_icon_state = icon_state_disabled
		UpdateButton()

/obj/item/gun/magic/contractor_hook
	name = "SCORPION hook"
	desc = "A hardlight hook used to non-lethally pull targets much closer to the user. You can pull even the heaviest prey when it is active." // BLUEMOON ADD - добавлено про возможность тащить тяжёлую добычу
	ammo_type = /obj/item/ammo_casing/magic/contractor_hook
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "hook_weapon"
	item_state = "gun"
	fire_sound = 'sound/weapons/batonextend.ogg'
	max_charges = 1
	recharge_rate = 0
	charge_tick = 1
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM
	slot_flags = 0
	item_flags = DROPDEL | ABSTRACT | NOBLUDGEON
	force = 0
	var/obj/item/clothing/suit/space/hardsuit/contractor/suit = null
	var/datum/action/item_action/advanced/hook_upgrade/hook_action = null

/obj/item/gun/magic/contractor_hook/process_chamber()
	. = ..()
	if(charges == 0)
		qdel(src)

/obj/item/gun/magic/contractor_hook/can_trigger_gun(mob/living/user)
	if(!hook_action.IsAvailable(show_message = TRUE, ignore_ready = TRUE))
		return FALSE
	else
		hook_action.use_action()
		return TRUE

/obj/item/gun/magic/contractor_hook/equip_to_best_slot(mob/M)
	qdel(src)

/obj/item/gun/magic/contractor_hook/Destroy() //BLUEMOON ADD START Правильно отвязывает крюк от костюма при сбросе или выпадении самого крюка
	if(suit)
		suit.scorpion = null
		suit = null
	if(hook_action)
		hook_action.action_ready = FALSE
		hook_action = null
	return ..() //BLUEMOON ADD END

/obj/item/ammo_casing/magic/contractor_hook
	name = "Hardlight hook"
	desc = "a hardlight hook."
	projectile_type = /obj/item/projectile/contractor_hook
	caliber = "hardlight_hook"
	icon_state = "hard_hook"
	firing_effect_type = null

/obj/item/projectile/contractor_hook
	name = "Hardlight hook"
	icon_state = "hard_hook"
	icon = 'icons/obj/projectiles.dmi'
	pass_flags = PASSTABLE
	damage = 0
	stamina = 50
	hitsound = 'sound/weapons/whip.ogg'
	knockdown_stamoverride = 36
	knockdown_stam_max = 50
	ricochet_chance = 0
	range = 7

/obj/item/projectile/contractor_hook/fire(setAngle)
	if(firer)
		chain = firer.Beam(src, icon_state = "hard_chain", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
	..()

/obj/item/projectile/contractor_hook/on_hit(atom/target, blocked = 0) //BLUEMOON EDIT START Исправление бага при котором агрессивный захват работал только при выстреле в упор
	. = ..()
	if(blocked >= 100)
		return 0
	if(isliving(target))
		var/mob/living/L = target
		if(!L.anchored && L.loc)
			L.visible_message("<span class='danger'>[L] is snagged by [firer]'s hook!</span>")

			var/old_density = L.density
			L.density = FALSE // Ensures the hook does not hit the target multiple times
			L.density = old_density
			firer.dropItemToGround(src)
			if (iscarbon(L))
				L.throw_at(get_step_towards(firer,L), 8, 2, firer, TRUE, TRUE, callback=CALLBACK(src, PROC_REF(contractor_hook_grab), firer, L))
			else
				L.throw_at(get_step_towards(firer,L), 8, 2)

/obj/item/projectile/contractor_hook/proc/contractor_hook_grab(mob/living/carbon/human/firer, mob/living/carbon/L)
	if(firer.Adjacent(L))
		if(firer.get_active_held_item() && !firer.get_inactive_held_item())
			firer.swap_hand()
		if(firer.get_active_held_item())
			return
		L.grabbedby(firer)
		L.grippedby(firer, instant = TRUE) //instant aggro grab //BLUEMOON EDIT END

/obj/item/projectile/contractor_hook/Destroy()
	QDEL_NULL(chain)
	return ..()
/*
	Chameleon
		Hardsuit chameleon module, very limited choice, shutting down when EMP'd.
*/

/datum/action/item_action/advanced/chameleon_upgrade
	name = "Advanced hardsuit chameleon module"
	desc = "An advanced version of chameleon tech, allowing you to disguise your hardsuit, giving you the opportunity to walk in full view of security and personnel without any difficulties."
	charge_type = ADV_ACTION_TYPE_TOGGLE
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "chameleon"
	button_icon = 'icons/mob/actions/actions.dmi'

/obj/item/clothing/suit/space/hardsuit/contractor/proc/toggle_chameleon()
	if(disguise)
		disguise = FALSE
		disable_chameleon()
		usr.visible_message("<span class='warning'>[usr] изменяет внешний вид своего бронекостюма!</span>", "<span class='notice'>Выключение маскировки..</span>")
		return
	var/list/choices = list(
		"EVA" = image(icon = 'icons/mob/clothing/contractor.dmi', icon_state = "EVA"),
		"Mining Hardsuit" = image(icon = 'icons/mob/clothing/contractor.dmi', icon_state = "mining"),
		"Medical Hardsuit" = image(icon = 'icons/mob/clothing/contractor.dmi', icon_state = "medical"),
		"Security Hardsuit" = image(icon = 'icons/mob/clothing/contractor.dmi', icon_state = "security"),
		"Engineering Hardsuit" = image(icon = 'icons/mob/clothing/contractor.dmi', icon_state = "engineering")
	)
	var/selected_chameleon = show_radial_menu(usr, loc, choices, require_near = TRUE)
	switch(selected_chameleon)
		if("EVA")
			src.name = "EVA Suit"
			src.icon_state = "space"
			src.desc = "A lightweight space suit with the basic ability to protect the wearer from the vacuum of space during emergencies."
			src.tail_state = "syndicate-winter"
			helmet.name = "EVA helmet"
			helmet.desc = "A lightweight space helmet with the basic ability to protect the wearer from the vacuum of space during emergencies."
			helmet.icon_state = "space"
		if("Mining Hardsuit")
			src.name = "Mining Hardsuit"
			src.icon_state = "hardsuit-mining"
			src.desc = "A special suit that protects against hazardous, low pressure environments. Has reinforced plating."
			src.tail_state = "engineer"
			helmet.name = "mining hardsuit helmet"
			helmet.desc = "A special helmet designed for work in a hazardous, low pressure environment. Has reinforced plating."
			helmet.icon_state = "hardsuit0-mining"
			helmet.hardsuit_type = "mining"
		if("Medical Hardsuit")
			src.name = "Medical Hardsuit"
			src.icon_state = "hardsuit-medical"
			src.desc = "A special suit designed for work in a hazardous, low pressure environment. Built with lightweight materials for extra comfort."
			src.tail_state = "syndicate-winter"
			helmet.name = "medical hardsuit helmet"
			helmet.desc = "A special helmet designed for work in a hazardous, low pressure environment. Built with lightweight materials for extra comfort, but does not protect the eyes from intense light."
			helmet.icon_state = "hardsuit0-medical"
			helmet.hardsuit_type = "medical"
		if("Security Hardsuit")
			src.name = "Security Hardsuit"
			src.icon_state = "hardsuit-sec"
			src.desc = "A special suit that protects against hazardous, low pressure environments. Has an additional layer of armor."
			src.tail_state = "sec"
			helmet.name = "security hardsuit helmet"
			helmet.desc = "A special helmet designed for work in a hazardous, low pressure environment. Has an additional layer of armor."
			helmet.icon_state = "hardsuit0-sec"
			helmet.hardsuit_type = "sec"
		if("Engineering Hardsuit")
			src.name = "Engineering Hardsuit"
			src.icon_state = "hardsuit-engineering"
			src.desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
			src.tail_state = "engineer"
			helmet.name = "engineering hardsuit helmet"
			helmet.desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
			helmet.icon_state = "hardsuit0-engineering"
			helmet.hardsuit_type = "engineering"
		else
			return
	balloon_alert(usr, "<span class='notice'>Бронекостюм начал гудеть..</span>")
	sleep(25)
	usr.visible_message("<span class='warning'>[usr] изменяет внешний вид своего бронекостюма!</span>", "<span class='notice'>[selected_chameleon] выбран.</span>")
	playsound(loc, 'sound/items/screwdriver2.ogg', 50, 1)
	update_suit()
	disguise = TRUE


/obj/item/clothing/suit/space/hardsuit/contractor/proc/disable_chameleon()
	src.name = initial(src.name)
	src.icon_state = initial(src.icon_state)
	src.desc = initial(src.desc)
	src.tail_state = initial(src.tail_state)
	helmet.name = initial(helmet.name)
	helmet.desc = initial(helmet.desc)
	helmet.icon_state = initial(helmet.icon_state)
	helmet.hardsuit_type = initial(helmet.hardsuit_type)
	update_suit()

/obj/item/clothing/suit/space/hardsuit/contractor/emp_act(severity)
	. = ..()
	if(disguise)
		usr.visible_message("<span class='warning'>Маскировка [usr] спадает!</span>", "<span class='notice'>Перегрузка модуля CHAMELEON! Отключение...</span>")
		disguise = FALSE
		disable_chameleon()

