/obj/item/restraints
	breakouttime = 600
	var/demoralize_criminals = TRUE // checked on carbon/carbon.dm to decide wheter to apply the handcuffed negative moodlet or not.
	/// allow movement at all during breakout
	var/allow_breakout_movement = FALSE

/obj/item/restraints/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] is strangling себя with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return(OXYLOSS)

/obj/item/restraints/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.handcuffed == src)
			M.handcuffed = null
			M.update_handcuffed()
			if(M.buckled && M.buckled.buckle_requires_restraints)
				M.buckled.unbuckle_mob(M)
		if(M.legcuffed == src)
			M.legcuffed = null
			M.update_inv_legcuffed()
	return ..()

//Handcuffs

/obj/item/restraints/handcuffs
	name = "handcuffs"
	desc = "Используйте их, чтобы держать заключенных в узде."
	gender = PLURAL
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "handcuff"
	item_state = "handcuff"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/iron=500)
	breakouttime = 600 //Deciseconds = 60s = 1 minute
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	var/cuffsound = 'sound/weapons/handcuffs.ogg'
	var/trashtype = null //for disposable cuffs

/obj/item/restraints/handcuffs/kinky
	name = "Kinky Handcuffs"
	desc = "Настоящие наручники, созданные для эротических игр... наверное... почему они настоящие?"
	icon_state = "handcuffgag"
	item_state = "kinkycuff"

/obj/item/restraints/handcuffs/attack(mob/living/carbon/C, mob/living/user)
	if(!istype(C))
		return

	if(iscarbon(user) && (HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50)))
		to_chat(user, "<span class='warning'>М-м-м... А как оно вообще работает?!</span>")
		apply_cuffs(user,user)
		return

	// chance of monkey retaliation
	if(ismonkey(C) && prob(MONKEY_CUFF_RETALIATION_PROB))
		var/mob/living/carbon/monkey/M
		M = C
		M.retaliate(user)

	if(!C.handcuffed)
		if(C.get_num_arms(FALSE) >= 2 || C.get_arm_ignore())
			C.visible_message("<span class='danger'>[user] пытается надеть [src.name] на [C]!</span>", \
								"<span class='userdanger'>[user] пытается надеть [src.name] на [C]!</span>")

			playsound(loc, cuffsound, 30, 1, -2)
			if(do_mob(user, C, 30) && (C.get_num_arms(FALSE) >= 2 || C.get_arm_ignore()))
				if(iscyborg(user))
					apply_cuffs(C, user, TRUE)
				else
					apply_cuffs(C, user)
				to_chat(user, "<span class='notice'>Вы стянули руки [C] наручниками.</span>")
				SSblackbox.record_feedback("tally", "handcuffs", 1, type)

				log_combat(user, C, "handcuffed")
			else
				to_chat(user, "<span class='warning'>Вы не смогли надеть наручники на [C]!</span>")
		else
			to_chat(user, "<span class='warning'>[C] не имеет руки...</span>")

/obj/item/restraints/handcuffs/proc/apply_cuffs(mob/living/carbon/target, mob/user, var/dispense = 0)
	if(target.handcuffed)
		return

	if(!user.temporarilyRemoveItemFromInventory(src) && !dispense)
		return

	var/obj/item/restraints/handcuffs/cuffs = src
	if(trashtype)
		cuffs = new trashtype()
	else if(dispense)
		cuffs = new type()

	cuffs.forceMove(target)
	target.handcuffed = cuffs

	target.update_handcuffed()
	if(trashtype && !dispense)
		qdel(src)
	if(iscyborg(user))
		playsound(user, "law", 50, 0)
	return

/obj/item/restraints/handcuffs/sinew
	name = "Sinew Restraints"
	desc = "Пара наручников, сделанных из длинных нитей плоти."
	icon = 'icons/obj/mining.dmi'
	icon_state = "sinewcuff"
	breakouttime = 300 //Deciseconds = 30s
	cuffsound = 'sound/weapons/cablecuff.ogg'

/obj/item/restraints/handcuffs/cable
	name = "Cable Restraints"
	desc = "Похоже на несколько кабелей, связанных вместе. Может использоваться для связывания чего-либо."
	icon_state = "cuff"
	item_state = "coil"
	color =  "#ff0000"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=150, /datum/material/glass=75)
	breakouttime = 300 //Deciseconds = 30s
	cuffsound = 'sound/weapons/cablecuff.ogg'

/obj/item/restraints/handcuffs/cable/Initialize(mapload)
	. = ..()

	var/static/list/hovering_item_typechecks = list(
		/obj/item/stack/rods = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Craft wired rod"),
		),

		/obj/item/stack/sheet/metal = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Craft bola"),
		),
	)

	AddElement(/datum/element/contextual_screentip_item_typechecks, hovering_item_typechecks)

/obj/item/restraints/handcuffs/cable/attack_self(mob/user)
	to_chat(user, "<span class='notice'>Вы начинаете разматывать стяжки в форму кабеля.</span>")
	if(!do_after(user, 25, user))
		return
	qdel(src)
	var/obj/item/stack/cable_coil/coil = new(get_turf(user))
	coil.amount = 15
	user.put_in_hands(coil)
	coil.color = color
	to_chat(user, "<span class='notice'>Вы размотали стяжки обратно в форму кабеля.</span>")

/obj/item/restraints/handcuffs/cable/red
	color = "#ff0000"

/obj/item/restraints/handcuffs/cable/yellow
	color = "#ffff00"

/obj/item/restraints/handcuffs/cable/blue
	color = "#1919c8"

/obj/item/restraints/handcuffs/cable/green
	color = "#00aa00"

/obj/item/restraints/handcuffs/cable/pink
	color = "#ff3ccd"

/obj/item/restraints/handcuffs/cable/orange
	color = "#ff8000"

/obj/item/restraints/handcuffs/cable/cyan
	color = "#00ffff"

/obj/item/restraints/handcuffs/cable/white
	color = null

/obj/item/restraints/handcuffs/cable/random

/obj/item/restraints/handcuffs/cable/random/Initialize(mapload)
	. = ..()
	var/list/cable_colors = GLOB.cable_colors
	color = pick(cable_colors)

/obj/item/restraints/handcuffs/cable/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = I
		if (R.use(1))
			var/obj/item/wirerod/W = new /obj/item/wirerod
			remove_item_from_storage(user)
			user.put_in_hands(W)
			to_chat(user, "<span class='notice'>Вы обернули стяжки вокруг верхушки прута.</span>")
			qdel(src)
		else
			to_chat(user, "<span class='warning'>Вам нужна один прут, чтобы обернуть вокруг него кабель!</span>")
			return
	else if(istype(I, /obj/item/stack/sheet/metal))
		var/obj/item/stack/sheet/metal/M = I
		if(M.get_amount() < 6)
			to_chat(user, "<span class='warning'>Вам нужно как минимум шесть листов железа для придания нужной массы!</span>")
			return
		to_chat(user, "<span class='notice'>Вы начинаете применять [I] к [src]...</span>")
		if(do_after(user, 35, target = src))
			if(M.get_amount() < 6 || !M)
				return
			var/obj/item/restraints/legcuffs/bola/S = new /obj/item/restraints/legcuffs/bola
			M.use(6)
			user.put_in_hands(S)
			to_chat(user, "<span class='notice'>Вы сделали несколько грузиков из [I] и привязали их к [src].</span>")
			remove_item_from_storage(user)
			qdel(src)
	else
		return ..()

/obj/item/restraints/handcuffs/cable/zipties
	name = "Zipties"
	desc = "Пластиковые одноразовые стяжки-молнии, которые могут использоваться для задержания, но после использования сами по себе рвутся."
	item_state = "zipties"
	color = "white"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	custom_materials = null
	breakouttime = 450 //Deciseconds = 45s
	trashtype = /obj/item/restraints/handcuffs/cable/zipties/used

/obj/item/restraints/handcuffs/cable/zipties/attack_self() //Zipties arent cable
	return

/obj/item/restraints/handcuffs/cable/zipties/used
	desc = "A pair of broken zipties."
	icon_state = "cuff_used"

/obj/item/restraints/handcuffs/cable/zipties/used/attack()
	return

/obj/item/restraints/handcuffs/alien
	icon_state = "handcuffAlien"

/obj/item/restraints/handcuffs/fake
	name = "Fake Handcuffs"
	desc = "Поддельные наручники, предназначенные для всяческих игр."
	breakouttime = 10 //Deciseconds = 1s
	demoralize_criminals = FALSE

/obj/item/restraints/handcuffs/fake/kinky
	name = "Kinky Handcuffs"
	desc = "Фальшивые наручники, предназначенные для эротических ролевых игр."
	icon_state = "handcuffgag"
	item_state = "kinkycuff"

//Legcuffs

/obj/item/restraints/legcuffs
	name = "leg cuffs"
	desc = "Используйте это, чтобы держать заключённых в узде."
	gender = PLURAL
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "handcuff"
	item_state = "legcuff"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	flags_1 = CONDUCT_1
	throwforce = 0
	obj_flags = IMMUTABLE_SLOW
	w_class = WEIGHT_CLASS_NORMAL
	slowdown = 7
	allow_breakout_movement = TRUE
	breakouttime = 300	//Deciseconds = 30s = 0.5 minute

/obj/item/restraints/legcuffs/proc/on_removed()
	return

/obj/item/restraints/legcuffs/beartrap
	name = "bear trap"
	throw_speed = 1
	throw_range = 1
	icon_state = "beartrap"
	desc = "Ловушка для поимки медведей и других существ с ногами."
	var/armed = FALSE
	var/trap_damage = 20
	var/ignore_weight = FALSE //BLUEMOON ADD капканы реагируют на вес карбонов

/obj/item/restraints/legcuffs/beartrap/prearmed
	armed = TRUE

/obj/item/restraints/legcuffs/beartrap/Initialize(mapload)
	. = ..()
	icon_state = "[initial(icon_state)][armed]"

/obj/item/restraints/legcuffs/beartrap/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] засовывает свою голову в [src.name]! Похоже что [user.ru_who()] пытается покончить с собой!</span>")
	playsound(loc, 'sound/weapons/bladeslice.ogg', 75, 1, -1)
	return (BRUTELOSS)

/obj/item/restraints/legcuffs/beartrap/attack_self(mob/user)
	..()
	if(ishuman(user) && !user.stat && !user.restrained())
		armed = !armed
		icon_state = "[initial(icon_state)][armed]"
		to_chat(user, "<span class='notice'>[src] теперь [armed ? "взведён" : "спущен"]</span>")

/obj/item/restraints/legcuffs/beartrap/Crossed(AM as mob|obj)
	if(armed && isturf(src.loc))
		if(isliving(AM))
			var/mob/living/L = AM
//BLUEMOON CHANGE переписывание прока для взаимодействия карбонов с полётом и учитыванием их веса
			var/snap = TRUE
			var/def_zone = BODY_ZONE_CHEST
			if(L.movement_type & (FLYING | FLOATING))
				snap = FALSE
			else if(!ignore_weight && (L.mob_size <= MOB_SIZE_TINY || (L.mob_size <= MOB_SIZE_SMALL && L.mob_weight < MOB_WEIGHT_NORMAL)))
				snap = FALSE
			if(iscarbon(L))
				var/mob/living/carbon/C = L
				def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				if(C.lying)
					snap = FALSE
				else if(!C.legcuffed && C.get_num_legs(FALSE) >= 2 && snap) //beartrap can't cuff your leg if there's already a beartrap or legcuffs, or you don't have two legs.
					C.legcuffed = src
					forceMove(C)
					C.update_equipment_speed_mods()
					C.update_inv_legcuffed()
					SSblackbox.record_feedback("tally", "handcuffs", 1, type)
//BLUEMOON CHANGE END
			if(snap)
				armed = FALSE
				icon_state = "[initial(icon_state)][armed]"
				playsound(src.loc, 'sound/effects/snap.ogg', 50, 1)
				L.visible_message("<span class='danger'>[L] активирует \the [src].</span>", \
						"<span class='userdanger'>Вы активируете \the [src]!</span>")
				L.apply_damage(trap_damage, BRUTE, def_zone)
	..()

/obj/item/restraints/legcuffs/beartrap/energy
	name = "energy snare"
	armed = TRUE
	icon_state = "e_snare"
	trap_damage = 0
	item_flags = DROPDEL
	flags_1 = NONE
	breakouttime = 50
	ignore_weight = TRUE //BLUEMOON ADD энерголовушкам плевать на вес персонажа

/obj/item/restraints/legcuffs/beartrap/energy/New()
	..()
	addtimer(CALLBACK(src, PROC_REF(dissipate)), 100)

/obj/item/restraints/legcuffs/beartrap/energy/proc/dissipate()
	if(!ismob(loc))
		do_sparks(1, TRUE, src)
		qdel(src)

/obj/item/restraints/legcuffs/beartrap/energy/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	//Crossed(user) //honk
	//. = ..()
	qdel(src)

/obj/item/restraints/legcuffs/beartrap/energy/cyborg
	breakouttime = 40 // Cyborgs shouldn't have a strong restraint

/obj/item/restraints/legcuffs/bola
	name = "bola"
	desc = "Сдерживающий метательный инструмент. По достижению цели, оборачивает ноги, мешая балансу движений, вплоть до падений."
	icon_state = "bola"
	breakouttime = 35//easy to apply, easy to break out of
	gender = NEUTER
	var/knockdown = 0

/obj/item/restraints/legcuffs/bola/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, quickstart = TRUE)
	if(!..())
		return
	playsound(src.loc,'sound/weapons/bolathrow.ogg', 75, 1)

/obj/item/restraints/legcuffs/bola/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..() || !iscarbon(hit_atom))//if it gets caught or the target can't be cuffed,
		return//abort
	ensnare(hit_atom)

/**
  * Attempts to legcuff someone with the bola
  *
  * Arguments:
  * * C - the carbon that we will try to ensnare
  */
/obj/item/restraints/legcuffs/bola/proc/ensnare(mob/living/carbon/C)
	if(!C.legcuffed && C.get_num_legs(FALSE) >= 2)
		visible_message("<span class='danger'>\The [src] опутывает [C]!</span>")
		C.legcuffed = src
		forceMove(C)
		C.update_equipment_speed_mods()
		C.update_inv_legcuffed()
		SSblackbox.record_feedback("tally", "handcuffs", 1, type)
		to_chat(C, "<span class='userdanger'>\The [src] опутывает вас!</span>")
		C.Knockdown(knockdown)
		playsound(src, 'sound/effects/snap.ogg', 50, TRUE)
		C.apply_status_effect(/datum/status_effect/bola_snared)

/obj/item/restraints/legcuffs/bola/tactical//traitor variant
	name = "reinforced bola"
	desc = "Крепкая бола со стальной цепью. Выглядит тяжёлой, достаточно, чтобы опрокинуть кого-то при попадании."
	icon_state = "bola_r"
	breakouttime = 70
	knockdown = 20

/obj/item/restraints/legcuffs/bola/energy //For Security
	name = "energy bola"
	desc = "Специализированая бола из твёрдого света для опутывания ног убегающих преступников и помощи в арестах."
	icon_state = "ebola"
	hitsound = 'sound/weapons/taserhit.ogg'
	w_class = WEIGHT_CLASS_SMALL
	breakouttime = 50

/obj/item/restraints/legcuffs/bola/energy/on_removed()
	do_sparks(1, TRUE, src)
	qdel(src)

/obj/item/restraints/legcuffs/bola/bone //Lavaland variant
	name = "tribal bola"
	desc = "A tibal bone weapon designed to be thrown at the target. Upon connecting with said target, it will wrap around their legs, making it difficult for them to move quickly."
	icon_state = "bone_bola"

