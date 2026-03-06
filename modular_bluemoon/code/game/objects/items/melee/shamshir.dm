/obj/item/storage/belt/shamshir
	name = "authentic shamshir leather sheath"
	desc = "A good-looking sheath that is advertised as being made of real Venusian black leather. It feels rather plastic-like to the touch, and it looks like it's made to fit a British cavalry sabre."
	icon_state = "sheathsec"
	item_state = "sheathsec"
	w_class = WEIGHT_CLASS_BULKY
	content_overlays = TRUE
	onmob_overlays = TRUE
	var/list/fitting_swords = list(/obj/item/melee/sabre, /obj/item/melee/baton/stunsword, /obj/item/melee/shamshir)
	var/starting_sword = /obj/item/melee/shamshir
	custom_premium_price = 1000 // потому что ебать его в рот КЛИНОК
/obj/item/storage/belt/shamshir/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.rustle_sound = FALSE
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(fitting_swords)
	STR.quickdraw = TRUE

/obj/item/storage/belt/shamshir/examine(mob/user)
	. = ..()
	if(length(contents))
		. += "<span class='notice'>Alt-click it to quickly draw the blade.</span>"

/obj/item/storage/belt/shamshir/PopulateContents()
	if(starting_sword)
		new starting_sword(src)

/obj/item/melee/shamshir
	name = "authentic shamshir sabre"
	desc = "An expertly crafted historical human sword once used by the Persians which has recently gained traction due to Venusian historal recreation sports. One small flaw, the Taj-based company who produces these has mistaken them for British cavalry sabres akin to those used by high ranking Nanotrasen officials. Atleast it cuts the same way!."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "shamshir"
	item_state = "shamshir"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	flags_1 = CONDUCT_1
	obj_flags = UNIQUE_RENAME
	force = 15
	wound_bonus = 5
	bare_wound_bonus = 10
	throwforce = 25
	w_class = WEIGHT_CLASS_BULKY
	block_chance = 40
	armour_penetration = 50
	sharpness = WOUND_SLASH
	attack_verb = list("slashed", "cut")
	hitsound = 'sound/weapons/rapierhit.ogg'
	custom_materials = list(/datum/material/iron = 1000)
	total_mass = 3.4
	item_flags = NEEDS_PERMIT | ITEM_CAN_PARRY
	block_parry_data = /datum/block_parry_data/traitor_rapier

// слизываю проки кэпской сабли
/obj/item/melee/shamshir/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 30, 95, 5) //fast and effective, but as a sword, it might damage the results.
	AddElement(/datum/element/sword_point)

/obj/item/melee/shamshir/on_exit_storage(datum/component/storage/S)
	var/obj/item/storage/belt/shamshir/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, 1)
	..()

/obj/item/melee/shamshir/on_enter_storage(datum/component/storage/S)
	var/obj/item/storage/belt/shamshir/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, 1)
	..()

/obj/item/melee/shamshir/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "shamshir") // todo: make this and its rapier equivalent work for the inhands too

/obj/item/melee/shamshir/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-shamshir")

/obj/item/melee/shamshir/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] is trying to cut off all [user.ru_ego()] limbs with [src]! it looks like [user.p_theyre()] trying to commit suicide!</span>")
	var/i = 0
	ADD_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)
	if(iscarbon(user))
		var/mob/living/carbon/Cuser = user
		var/obj/item/bodypart/holding_bodypart = Cuser.get_holding_bodypart_of_item(src)
		var/list/limbs_to_dismember
		var/list/arms = list()
		var/list/legs = list()
		var/obj/item/bodypart/bodypart

		for(bodypart in Cuser.bodyparts)
			if(bodypart == holding_bodypart)
				continue
			if(bodypart.body_part & ARMS)
				arms += bodypart
			else if (bodypart.body_part & LEGS)
				legs += bodypart

		limbs_to_dismember = arms + legs
		if(holding_bodypart)
			limbs_to_dismember += holding_bodypart

		var/speedbase = abs((4 SECONDS) / limbs_to_dismember.len)
		for(bodypart in limbs_to_dismember)
			i++
			addtimer(CALLBACK(src, PROC_REF(suicide_dismember), user, bodypart), speedbase * i)
	addtimer(CALLBACK(src, PROC_REF(manual_suicide), user), (5 SECONDS) * i)
	return MANUAL_SUICIDE

/obj/item/melee/shamshir/proc/suicide_dismember(mob/living/user, obj/item/bodypart/affecting)
	if(!QDELETED(affecting) && affecting.dismemberable && affecting.owner == user && !QDELETED(user))
		playsound(user, hitsound, 25, 1)
		affecting.dismember(BRUTE)
		user.adjustBruteLoss(20)

/obj/item/melee/shamshir/proc/manual_suicide(mob/living/user, originally_nodropped)
	if(!QDELETED(user))
		user.adjustBruteLoss(200)
		user.death(FALSE)
	REMOVE_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)


// Сюда же пихну крио-катану

/obj/item/melee/sabre/security
	name = "Cryo-blade"
	desc = "A cryotechnological device that freezes criminals alive. Facinating!"
	icon_state = "security_katana"
	item_state = "security_katana"
	force = 15
	block_chance = 30
	armour_penetration = 10

	icon = 'modular_bluemoon/icons/obj/white/items_and_weapons.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/swords_righthand.dmi'

	var/obj/item/stock_parts/cell/cell
	var/preload_cell_type //if not empty the baton starts with this type of cell
	var/cell_hit_cost = 1000
	var/can_remove_cell = TRUE

	///are we using our cryo mode?
	var/turned_on = FALSE

/obj/item/melee/sabre/security/on_exit_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sheath/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/melee/sabre/security/on_enter_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sheath/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, TRUE)

/obj/item/melee/sabre/security/loaded //this one starts with a cell pre-installed.
	preload_cell_type = /obj/item/stock_parts/cell/high/plus

/obj/item/melee/sabre/security/get_cell()
	return cell

/obj/item/melee/sabre/security/Initialize()
	. = ..()
	if(preload_cell_type)
		if(!ispath(preload_cell_type,/obj/item/stock_parts/cell))
			log_mapping("[src] at [AREACOORD(src)] had an invalid preload_cell_type: [preload_cell_type].")
		else
			cell = new preload_cell_type(src)
	update_icon()

/obj/item/melee/sabre/security/Destroy()
	if(cell)
		QDEL_NULL(cell)
	return ..()

/obj/item/melee/sabre/security/handle_atom_del(atom/A)
	if(A == cell)
		cell = null
		turned_on = FALSE
		update_icon()
	return ..()

/obj/item/melee/sabre/security/proc/deductcharge(chrgdeductamt)
	if(cell)
		//Note this value returned is significant, as it will determine
		//if a stun is applied or not
		. = cell.use(chrgdeductamt)
		if(turned_on && cell.charge < cell_hit_cost)
			//we're below minimum, turn off
			turned_on = FALSE
			update_icon()
			playsound(src, "sparks", 75, TRUE, -1)

/obj/item/melee/sabre/security/update_icon_state()
	if(turned_on)
		icon_state = "[initial(icon_state)]_active"
		item_state = "[initial(item_state)]_active"
	else if(!cell)
		icon_state = "[initial(icon_state)]_nocell"
	else
		icon_state = "[initial(icon_state)]"
		item_state = "[initial(item_state)]"

/obj/item/melee/sabre/security/examine(mob/user)
	. = ..()
	if(cell)
		. += "<hr><span class='notice'>Заряд <b>[src.name]</b>: [round(cell.percent())]%.</span>"
	else
		. += "<hr><span class='warning'>Заряд <b>[src.name]</b>: НЕТ БАТАРЕИ.</span>"

/obj/item/melee/sabre/security/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/C = W
		if(cell)
			to_chat(user, span_warning("<b>[capitalize(src.name)]</b> уже имеет батарейку!"))
		else
			if(C.maxcharge < cell_hit_cost)
				to_chat(user, span_notice("<b>[capitalize(src.name)]</b> требует более мощный источник питания."))
				return
			if(!user.transferItemToLoc(W, src))
				return
			cell = W
			to_chat(user, span_notice("Вставляю батарейку в <b>[capitalize(src.name)]</b>."))
			update_icon()

	else if(W.tool_behaviour == TOOL_SCREWDRIVER)
		tryremovecell(user)
	else
		return ..()

/obj/item/melee/sabre/security/proc/tryremovecell(mob/user)
	if(cell && can_remove_cell)
		cell.update_icon()
		cell.forceMove(get_turf(src))
		cell = null
		to_chat(user, span_notice("Вытаскиваю батарейку из <b>[src.name]</b>."))
		turned_on = FALSE
		update_icon()

/obj/item/melee/sabre/security/attack_self(mob/user)
	toggle_on(user)

/obj/item/melee/sabre/security/proc/toggle_on(mob/user)
	if(cell && cell.charge > cell_hit_cost)
		turned_on = !turned_on
		to_chat(user, span_notice("<b>[capitalize(src.name)]</b> теперь [turned_on ? "включена" : "отключена"]."))
		playsound(src, "sparks", 75, TRUE, -1)
	else
		turned_on = FALSE
		if(!cell)
			to_chat(user, span_warning("<b>[capitalize(src.name)]</b> не имеет источника энергии!"))
		else
			to_chat(user, span_warning("<b>[capitalize(src.name)]</b> разрядилась."))
	update_icon()
	add_fingerprint(user)

/obj/item/melee/sabre/security/attack(mob/M, mob/living/user)
	if(iscyborg(M))
		..()
		return

	if(user.a_intent != INTENT_HARM)
		if(turned_on)
			if(cryo(M, user))
				user.do_attack_animation(M)
				return
	else
		if(turned_on)
			cryo(M, user)
		..()

/obj/item/melee/sabre/security/proc/cryo(mob/living/L, mob/user)
	deductcharge(cell_hit_cost)
	L.adjust_bodytemperature(-60)
	L.apply_damage(20, STAMINA, BODY_ZONE_CHEST)
	playsound(src, 'sound/weapons/egloves.ogg', 50, TRUE, -1)
	if(user)
//		L.lastattacker = user.real_name
//		L.lastattackerckey = user.ckey
		L.visible_message(span_danger("<b>[user]</b> бьёт <b>[L]</b> при помощи <b>[src.name]</b>, высвобождая холодный поток энергии из <b>[src]</b>!") , \
								span_userdanger("<b>[user]</b> бьёт меня при помощи <b>[src.name]</b>!"))
		log_combat(user, L, "cryosliced")

	return 1

/obj/item/melee/sabre/security/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "seckatana") // todo: make this and its rapier equivalent work for the inhands too

/obj/item/melee/sabre/security/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-seckatana")


/obj/item/melee/sabre/security/hos
	name = "Master's cryo-blade "
	desc = "Show me your motivation."
	icon_state = "hos_katana"
	item_state = "hos_katana"
	force = 18
	block_chance = 50
	armour_penetration = 40
	preload_cell_type = /obj/item/stock_parts/cell/high/plus

/obj/item/katana/on_exit_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sheath/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/katana/on_enter_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/sheath/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, TRUE)


/obj/item/storage/belt/sheath
	name = "Katana sheath"
	desc = "Holding the power."
	icon_state = "security_katana_sheath"
	item_state = "security_katana_sheath"
	w_class = WEIGHT_CLASS_BULKY
	content_overlays = TRUE
	onmob_overlays = TRUE
	var/list/fitting_swords = list(/obj/item/melee/sabre/security, /obj/item/katana)
/obj/item/storage/belt/sheath/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.rustle_sound = FALSE
	STR.quickdraw = TRUE
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(fitting_swords)


/obj/item/storage/belt/sheath/security
	name = "Officer katana sheath"

/obj/item/storage/belt/sheath/security/PopulateContents()
	new /obj/item/melee/sabre/security/loaded(src)
	update_icon()

/obj/item/storage/belt/sheath/security/hos/PopulateContents()
	new /obj/item/melee/sabre/security/hos(src)
	update_icon()
