/* Tables and Racks
 * Contains:
 *		Tables
 *		Glass Tables
 *		Wooden Tables
 *		Reinforced Tables
 *		Racks
 *		Rack Parts
 */

/*
 * Tables
 */

/obj/structure/table
	name = "table"
	desc = "Квадрат металла на четырёхножной основе. Не может быть сдвинут с места."
	icon = 'icons/obj/smooth_structures/table.dmi'
	icon_state = "table"
	density = TRUE
	anchored = TRUE
	pass_flags_self = PASSTABLE | LETPASSTHROW
	layer = TABLE_LAYER
	climbable = TRUE
	obj_flags = CAN_BE_HIT|SHOVABLE_ONTO
	attack_hand_speed = CLICK_CD_MELEE
	attack_hand_is_action = TRUE
	var/frame = /obj/structure/table_frame
	var/framestack = /obj/item/stack/rods
	var/buildstack = /obj/item/stack/sheet/metal
	var/busy = FALSE
	var/buildstackamount = 1
	var/framestackamount = 2
	var/deconstruction_ready = 1
	max_integrity = 100
	integrity_failure = 0.33
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/table, /obj/structure/table/reinforced, /obj/structure/table/greyscale)

/obj/structure/table/Initialize(mapload)
	. = ..()

	var/static/list/barehanded_interactions = list(
		INTENT_ANY = "Slap",
		INTENT_HARM = "Slam"
	)

	AddElement(/datum/element/contextual_screentip_bare_hands, rmb_text_combat_mode = barehanded_interactions)

	var/static/list/hovering_item_typechecks = list(
		/obj/item/wallframe = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_GRAB = "Install frame on the table"),
		),
	)
	AddElement(/datum/element/contextual_screentip_item_typechecks, hovering_item_typechecks)

/obj/structure/table/examine(mob/user)
	. = ..()
	. += deconstruction_hints(user)

/obj/structure/table/proc/deconstruction_hints(mob/user)
	return "<span class='notice'>Верх стола <b>привинчен</b> к нему, но закреплённый <b>болтами</b> каркас также видим.</span>"

/obj/structure/table/update_icon()
	if(smooth)
		queue_smooth(src)
		queue_smooth_neighbors(src)

/obj/structure/table/narsie_act()
	var/atom/A = loc
	qdel(src)
	new /obj/structure/table/wood(A)

/obj/structure/table/ratvar_act()
	var/atom/A = loc
	qdel(src)
	new /obj/structure/table/reinforced/brass(A)

/obj/structure/table/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/table/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(Adjacent(user) && user.pulling)
		if(isliving(user.pulling))
			var/mob/living/pushed_mob = user.pulling
			if(pushed_mob.buckled)
				to_chat(user, "<span class='warning'>[pushed_mob] перемещён на [pushed_mob.buckled]!</span>")
				return
			// BLUEMOON ADDITION AHEAD - сверхтяжёлых персонажей нельзя положить на стол, только если ты сам не сверхтяжёлый, киборг или халк
			/* - не актуальный сегмент. Их может брать и перемещать большее количество персонажей с момента ввода. Остаётся на случай изменений в будущем
			if(pushed_mob.mob_weight > MOB_WEIGHT_HEAVY)
				if(!issilicon(user))
					if(iscarbon(user) && user.mob_weight < MOB_WEIGHT_HEAVY_SUPER)
						var/mob/living/carbon/C = user
						if(!C.dna.check_mutation(HULK))
							to_chat(user, span_warning("Слишком много весит!"))
							return
			*/
			// BLUEMOON ADDITION END
			if(user.a_intent == INTENT_GRAB)
				if(user.grab_state < GRAB_AGGRESSIVE)
					to_chat(user, "<span class='warning'>Bам нужна более крепкая хватка!</span>")
					return
				if(user.grab_state >= GRAB_NECK || HAS_TRAIT(user, TRAIT_MAULER))
					tablelimbsmash(user, pushed_mob)
				else
					tablepush(user, pushed_mob)
			if(user.a_intent == INTENT_HELP)
				pushed_mob.visible_message("<span class='notice'>[user] аккуратно кладёт [pushed_mob] на [src]...</span>", \
									"<span class='userdanger'>[user] аккуратно кладёт [pushed_mob] на [src]...</span>")
				if(do_after(user, 35, target = pushed_mob))
					tableplace(user, pushed_mob)
				else
					return
			user.stop_pulling()
		else if(user.pulling.pass_flags & PASSTABLE)
			user.Move_Pulled(src)
			if (user.pulling.loc == loc)
				user.visible_message("<span class='notice'>[user] укладывает [user.pulling] на [src].</span>",
					"<span class='notice'>Вы кладёте [user.pulling] на [src].</span>")
				user.stop_pulling()
	return ..()

/obj/structure/table/attack_robot(mob/user)
	on_attack_hand(user)

/obj/structure/table/attack_tk()
	return FALSE

/obj/structure/table/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(.)
		return
	if(mover.throwing)
		return TRUE
	if(locate(/obj/structure/table) in get_turf(mover))
		return TRUE

/obj/structure/table/CanAStarPass(obj/item/card/id/ID, to_dir, atom/movable/caller)
	. = !density
	if(istype(caller))
		. = . || (caller.pass_flags & PASSTABLE)

/obj/structure/table/proc/tableplace(mob/living/user, mob/living/pushed_mob)
	pushed_mob.forceMove(src.loc)
	pushed_mob.set_resting(TRUE, FALSE)
	pushed_mob.visible_message("<span class='notice'>[user] укладывает [pushed_mob] на [src].</span>", \
								"<span class='notice'>[user] укладывает [pushed_mob] на [src].</span>")
	log_combat(user, pushed_mob, "places", null, "onto [src]")
	// BLUEMOON ADDITION AHEAD - тяжёлые и сверхтяжёлые персонажи при толчке на стол ломают его
	var/break_table = FALSE
	if(pushed_mob.mob_weight > MOB_WEIGHT_HEAVY) // сверхтяжёлые персонажи всегда ломают стол (им не важно, есть он под ними или нет
		break_table = TRUE
	else if(pushed_mob.mob_weight > MOB_WEIGHT_NORMAL)
		if(!istype(src, /obj/structure/table/optable)) // тяжёлых персонажей всё ещё можно класть на хирургический стол, не ломая его в процессе
			break_table = TRUE
	if(break_table)
		pushed_mob.visible_message("<span class='danger'>[src] ломается под весом [pushed_mob]!</span>", \
								"<span class='userdanger'>Вы ломаете [src] собственным весом!</span>")
		deconstruct(TRUE)
	// BLUEMOON ADDITION END

/obj/structure/table/proc/tablepush(mob/living/user, mob/living/pushed_mob)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, "<span class='danger'>Это может навредить [pushed_mob]!</span>")
		return
	var/added_passtable = FALSE
	if(!(pushed_mob.pass_flags & PASSTABLE))
		added_passtable = TRUE
		pushed_mob.pass_flags |= PASSTABLE
	pushed_mob.Move(src.loc)
	if(added_passtable)
		pushed_mob.pass_flags &= ~PASSTABLE
	if(pushed_mob.loc != loc) //Something prevented the tabling
		return
	pushed_mob.DefaultCombatKnockdown(120)
	pushed_mob.apply_damage(15, BRUTE)
	pushed_mob.visible_message("<span class='danger'>[user] кидает [pushed_mob] на [src]!</span>", \
								"<span class='userdanger'>[user] кидает вас на [src]!</span>")
	playsound(pushed_mob, 'sound/weapons/thudswoosh.ogg', 90, TRUE)
	log_combat(user, pushed_mob, "tabled", null, "onto [src]")
	if(!ishuman(pushed_mob))
		return
	if(iscatperson(pushed_mob))
		pushed_mob.emote("nya")
	SEND_SIGNAL(pushed_mob, COMSIG_ADD_MOOD_EVENT, "table", /datum/mood_event/table)
	// BLUEMOON ADDITION AHEAD - тяжёлые и сверхтяжёлые персонажи при толчке на стол ломают его
	if(pushed_mob.mob_weight > MOB_WEIGHT_NORMAL)
		pushed_mob.visible_message("<span class='danger'>[src] ломается под весом [pushed_mob]!</span>", \
								"<span class='userdanger'>Вы ломаете [src] собственным весом!</span>")
		deconstruct(TRUE)
	// BLUEMOON ADDITION END

/obj/structure/table/proc/tablelimbsmash(mob/living/user, mob/living/pushed_mob)
	pushed_mob.Knockdown(30)
	var/obj/item/bodypart/banged_limb = pushed_mob.get_bodypart(user.zone_selected) || pushed_mob.get_bodypart(BODY_ZONE_HEAD)
	var/extra_wound = 10
	if(HAS_TRAIT(user, TRAIT_HULK) || HAS_TRAIT(user, TRAIT_MAULER))
		extra_wound = 20
	banged_limb.receive_damage(30, wound_bonus = extra_wound)
	pushed_mob.apply_damage(120, STAMINA)
	take_damage(50)

	playsound(pushed_mob, 'sound/effects/bang.ogg', 90, TRUE)
	pushed_mob.visible_message("<span class='danger'>[user] бьёт [banged_limb.ru_name_y] [pushed_mob] об [src]!</span>",
								"<span class='userdanger'>[user] бьёт вашу [banged_limb.ru_name_y] об [src]</span>")
	log_combat(user, pushed_mob, "head slammed", null, "against [src]")
	SEND_SIGNAL(pushed_mob, COMSIG_ADD_MOOD_EVENT, "table", /datum/mood_event/table_limbsmash, banged_limb)
	// BLUEMOON ADDITION AHEAD - тяжёлые и сверхтяжёлые персонажи при толчке на стол ломают его
	if(pushed_mob.mob_weight > MOB_WEIGHT_NORMAL)
		pushed_mob.visible_message("<span class='danger'>[src] ломается под весом [pushed_mob]!</span>", \
								"<span class='userdanger'>Вы ломаете [src] собственным весом!</span>")
		deconstruct(TRUE)
	// BLUEMOON ADDITION END

/obj/structure/table/shove_act(mob/living/target, mob/living/user)
	if(CHECK_MOBILITY(target, MOBILITY_STAND))
		target.DefaultCombatKnockdown(SHOVE_KNOCKDOWN_TABLE)
	user.visible_message("<span class='danger'>[user.name] толкает [target.name] на [src]!</span>",
		"<span class='danger'>Вы толкаете [target.name] на [src]!</span>", null, COMBAT_MESSAGE_RANGE)
	target.forceMove(loc)
	log_combat(user, target, "shoved", "onto [src] (table)")
	return TRUE

/obj/structure/table/attackby(obj/item/I, mob/user, params)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(I.tool_behaviour == TOOL_SCREWDRIVER && deconstruction_ready && !(user.a_intent == INTENT_HELP))
			to_chat(user, "<span class='notice'>Вы начали частично разбирать [src]...</span>")
			if(I.use_tool(src, user, 20, volume=50))
				deconstruct(TRUE)
			return

		if(I.tool_behaviour == TOOL_WRENCH && deconstruction_ready && !(user.a_intent == INTENT_HELP))
			to_chat(user, "<span class='notice'>Вы начали разбирать на части [src]...</span>")
			if(I.use_tool(src, user, 40, volume=50))
				playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
				deconstruct(TRUE, 1)
			return

	if(istype(I, /obj/item/storage/bag/tray))
		var/obj/item/storage/bag/tray/T = I
		if(T.contents.len > 0) // If the tray isn't empty
			for(var/x in T.contents)
				var/obj/item/item = x
				AfterPutItemOnTable(item, user)
			SEND_SIGNAL(I, COMSIG_TRY_STORAGE_QUICK_EMPTY, drop_location())
			user.visible_message("[user] высыпает [I] на [src].")
			return
		// If the tray IS empty, continue on (tray will be placed on the table like other items)

	if(istype(I, /obj/item/riding_offhand))
		var/obj/item/riding_offhand/riding_item = I
		var/mob/living/carried_mob = riding_item.rider
		if(carried_mob == user) //Piggyback user.
			return
		if(user.a_intent == INTENT_HARM)
			user.unbuckle_mob(carried_mob)
			tablelimbsmash(user, carried_mob)
		else
			var/tableplace_delay = 3.5 SECONDS
			var/skills_space = ""
			if(HAS_TRAIT(user, TRAIT_QUICKER_CARRY))
				tableplace_delay = 2 SECONDS
				skills_space = " экспертно"
			else if(HAS_TRAIT(user, TRAIT_QUICK_CARRY))
				tableplace_delay = 2.75 SECONDS
				skills_space = " быстро"
			carried_mob.visible_message(span_notice("[user] начинает [skills_space] укладывать [carried_mob] на [src]..."),
				span_userdanger("[user] начинает [skills_space] укладывать [carried_mob] на [src]..."))
			if(do_after(user, tableplace_delay, target = carried_mob))
				user.unbuckle_mob(carried_mob)
				tableplace(user, carried_mob)
		return TRUE
	if(istype(I, /obj/item/wallframe) && user.a_intent == INTENT_GRAB)
		var/obj/item/wallframe/W = I
		if(W.try_build(src, user))
			W.attach(src, user, params)
		return TRUE
	if(user.a_intent != INTENT_HARM && !(I.item_flags & ABSTRACT))
		return PutItemOnTable(I, user, params)
	else
		return ..()

/obj/structure/table/proc/PutItemOnTable(obj/item/I, mob/living/user, params)
	if(user.transferItemToLoc(I, drop_location()))
		var/list/click_params = params2list(params)
		//Center the icon where the user clicked.
		if(!click_params || !click_params["icon-x"] || !click_params["icon-y"])
			return
		//Clamp it so that the icon never moves more than 16 pixels in either direction (thus leaving the table turf)
		I.pixel_x = clamp(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)
		I.pixel_y = clamp(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)
		AfterPutItemOnTable(I, user)
		return TRUE

/obj/structure/table/proc/AfterPutItemOnTable(obj/item/I, mob/living/user)
	return

/obj/structure/table/alt_attack_hand(mob/user)
	if(!user.CheckActionCooldown(CLICK_CD_MELEE))
		return
	user.DelayNextAction()
	if(user && Adjacent(user) && !user.incapacitated())
		if(istype(user) && user.a_intent == INTENT_HARM)
			user.visible_message("<span class='warning'>[user] с силой грымнул[user.ru_a()] ладонью по [src].</span>", "<span class='warning'>Вы с силой ударяете ладонью по [src].</span>")
			playsound(src, 'sound/weapons/sonic_jackhammer.ogg', 50, 1)
		else
			user.visible_message("<span class='notice'>[user] стукнул[user.ru_a()] рукой по [src].</span>", "<span class='notice'>Вы стукнули рукой по [src].</span>")
			playsound(src, 'sound/weapons/tap.ogg', 50, 1)
		user.do_attack_animation(src)
		return TRUE

/obj/structure/table/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/T = get_turf(src)
		if(buildstack)
			new buildstack(T, buildstackamount)
		else
			for(var/i in custom_materials)
				var/datum/material/M = i
				new M.sheet_type(T, FLOOR(custom_materials[M] / MINERAL_MATERIAL_AMOUNT, 1))
		if(!wrench_disassembly)
			new frame(T)
		else
			new framestack(T, framestackamount)
	qdel(src)


/**
 * Gets all connected tables
 * Cardinals only
 */
/obj/structure/table/proc/connected_floodfill(max = 25)
	. = list()
	connected_floodfill_internal(., list())

/obj/structure/table/proc/connected_floodfill_internal(list/out = list(), list/processed = list())
	if(processed[src])
		return
	processed[src] = TRUE
	out += src
	var/obj/structure/table/other
#define RUN_TABLE(dir) \
	other = locate(/obj/structure/table) in get_step(src, dir); \
	if(other) { \
		other.connected_floodfill_internal(out, processed); \
	}
	RUN_TABLE(NORTH)
	RUN_TABLE(SOUTH)
	RUN_TABLE(EAST)
	RUN_TABLE(WEST)
#undef RUN_TABLE

/obj/structure/table/greyscale
	icon = 'icons/obj/smooth_structures/table_greyscale.dmi'
	icon_state = "table"
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	buildstack = null //No buildstack, so generate from mat datums

///Table on wheels
/obj/structure/table/rolling
	name = "Rolling table"
	desc = "NT-брендированный \"Rolly poly\" стол на колёсиках. Может и будет свободно перемещаться."
	anchored = FALSE
	smooth = SMOOTH_FALSE
	canSmoothWith = list()
	icon = 'icons/obj/smooth_structures/rollingtable.dmi'
	icon_state = "rollingtable"
	var/list/attached_items = list()

/obj/structure/table/rolling/AfterPutItemOnTable(obj/item/I, mob/living/user)
	. = ..()
	attached_items += I
	RegisterSignal(I, COMSIG_MOVABLE_MOVED, PROC_REF(RemoveItemFromTable)) //Listen for the pickup event, unregister on pick-up so we aren't moved

/obj/structure/table/rolling/proc/RemoveItemFromTable(datum/source, newloc, dir)
	if(newloc != loc) //Did we not move with the table? because that shit's ok
		return FALSE
	attached_items -= source
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)

/obj/structure/table/rolling/Moved(atom/OldLoc, Dir)
	. = ..()
	for(var/mob/M in OldLoc.contents)//Kidnap everyone on top
		M.forceMove(loc)
	for(var/x in attached_items)
		var/atom/movable/AM = x
		if(!AM.Move(loc))
			RemoveItemFromTable(AM, AM.loc)

/*
 * Glass tables
 */
/obj/structure/table/glass
	name = "glass table"
	desc = "Что я говорил о том, чтобы не упираться о стеклянные столы? Теперь пора в трампункт."
	icon = 'icons/obj/smooth_structures/glass_table.dmi'
	icon_state = "glass_table"
	buildstack = /obj/item/stack/sheet/glass
	canSmoothWith = null
	max_integrity = 70
	resistance_flags = ACID_PROOF
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 100)
	var/list/debris = list()

/obj/structure/table/glass/New()
	. = ..()
	debris += new frame
	debris += new /obj/item/shard

/obj/structure/table/glass/Destroy()
	QDEL_LIST(debris)
	. = ..()


//BLUEMOON ADD стол из стекла можно осмотреть на предмет выдерживания на нём персонажа
/obj/structure/table/glass/examine(mob/user)
	. = ..()
	if(in_range(user, src) && isliving(user))
		var/mob/living/M = user
		if(M.has_gravity() && !(M.movement_type & FLYING) && ((M.mob_size > MOB_SIZE_SMALL && M.mob_weight > MOB_WEIGHT_LIGHT) || M.mob_size > MOB_SIZE_HUMAN))
			. += span_danger("Выглядит словно сломается при попытке залезть на него.")
		else
			. += span_notice("Выгялдит, будто можно безопасно пересечь.")
//BLUEMOON ADD END

/obj/structure/table/glass/Crossed(atom/movable/AM)
	. = ..()
	if(flags_1 & NODECONSTRUCT_1)
		return
	if(!isliving(AM))
		return
	// Don't break if they're just flying past
	if(AM.throwing)
		addtimer(CALLBACK(src, PROC_REF(throw_check), AM), 5)
	else
		check_break(AM)

/obj/structure/table/glass/proc/throw_check(mob/living/M)
	if(M.loc == get_turf(src))
		check_break(M)

/obj/structure/table/glass/proc/check_break(mob/living/M)
	if(M.has_gravity() && !(M.movement_type & FLYING) && ((M.mob_size > MOB_SIZE_SMALL && M.mob_weight > MOB_WEIGHT_LIGHT) || M.mob_size > MOB_SIZE_HUMAN)) //BLUEMOON ADD столы ломаются при размере 0.81 или если лёгкий, то 1.21
		table_shatter(M)

/obj/structure/table/glass/proc/table_shatter(mob/living/L)
	visible_message("<span class='warning'>[src] ломается!</span>",
		"<span class='danger'>Вы слышите ломающееся стекло.</span>")
	var/turf/T = get_turf(src)
	playsound(T, "shatter", 50, 1)
	for(var/I in debris)
		var/atom/movable/AM = I
		AM.forceMove(T)
		debris -= AM
		if(istype(AM, /obj/item/shard))
			AM.throw_impact(L)
	L.DefaultCombatKnockdown(100)
	qdel(src)

/obj/structure/table/glass/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			..()
			return
		else
			var/turf/T = get_turf(src)
			playsound(T, "shatter", 50, 1)
			for(var/X in debris)
				var/atom/movable/AM = X
				AM.forceMove(T)
				debris -= AM
	qdel(src)

/obj/structure/table/glass/narsie_act()
	color = NARSIE_WINDOW_COLOUR
	for(var/obj/item/shard/S in debris)
		S.color = NARSIE_WINDOW_COLOUR

/*
 * Plasmaglass tables
 */
/obj/structure/table/plasmaglass
	name = "plasmaglass table"
	desc = "Стеклянный стол, но розовый и куда более прочный. Что ещё Nanotrasen спроектирует на плазме?"
	icon = 'icons/obj/smooth_structures/plasmaglass_table.dmi'
	icon_state = "plasmaglass_table"
	climbable = TRUE
	buildstack = /obj/item/stack/sheet/plasmaglass
	canSmoothWith = null
	max_integrity = 270
	resistance_flags = ACID_PROOF
	armor = list(MELEE = 10, BULLET = 5, LASER = 0, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 80, ACID = 100)
	var/list/debris = list()

/obj/structure/table/plasmaglass/New()
	. = ..()
	debris += new frame
	debris += new /obj/item/shard/plasma

/obj/structure/table/plasmaglass/Destroy()
	QDEL_LIST(debris)
	. = ..()

/obj/structure/table/plasmaglass/proc/check_break(mob/living/M)
	return

/obj/structure/table/plasmaglass/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			..()
			return
		else
			var/turf/T = get_turf(src)
			playsound(T, "shatter", 50, 1)
			for(var/X in debris)
				var/atom/movable/AM = X
				AM.forceMove(T)
				debris -= AM
	qdel(src)

/obj/structure/table/plasmaglass/narsie_act()
	color = NARSIE_WINDOW_COLOUR
	for(var/obj/item/shard/S in debris)
		S.color = NARSIE_WINDOW_COLOUR

/*
 * Wooden tables
 */

/obj/structure/table/wood
	name = "wooden table"
	desc = "Держать подальше от огня. Слухи говорят, он легко горит."
	icon = 'icons/obj/smooth_structures/wood_table.dmi'
	icon_state = "wood_table"
	frame = /obj/structure/table_frame/wood
	framestack = /obj/item/stack/sheet/mineral/wood
	buildstack = /obj/item/stack/sheet/mineral/wood
	resistance_flags = FLAMMABLE
	max_integrity = 70
	canSmoothWith = list(/obj/structure/table/wood,
		/obj/structure/table/wood/poker,
		/obj/structure/table/wood/bar)

/obj/structure/table/wood/narsie_act(total_override = TRUE)
	if(!total_override)
		..()

/obj/structure/table/wood/poker //No specialties, Just a mapping object.
	name = "gambling table"
	desc = "Сомнительный стол для сомнительных сделок в сомнительных местах."
	icon = 'icons/obj/smooth_structures/poker_table.dmi'
	icon_state = "poker_table"
	buildstack = /obj/item/stack/tile/carpet

/obj/structure/table/wood/poker/narsie_act()
	..(FALSE)

/obj/structure/table/wood/fancy
	name = "fancy table"
	desc = "Стандартный каркас из металла, покрытый удивительно стильной узорчатой тканью."
	icon = 'icons/obj/structures.dmi'
	icon_state = "fancy_table"
	frame = /obj/structure/table_frame
	framestack = /obj/item/stack/rods
	buildstack = /obj/item/stack/tile/carpet
	canSmoothWith = list(/obj/structure/table/wood/fancy,
		/obj/structure/table/wood/fancy/black,
		/obj/structure/table/wood/fancy/blackred,
		/obj/structure/table/wood/fancy/monochrome,
		/obj/structure/table/wood/fancy/blue,
		/obj/structure/table/wood/fancy/cyan,
		/obj/structure/table/wood/fancy/green,
		/obj/structure/table/wood/fancy/orange,
		/obj/structure/table/wood/fancy/purple,
		/obj/structure/table/wood/fancy/red,
		/obj/structure/table/wood/fancy/royalblack,
		/obj/structure/table/wood/fancy/royalblue)
	var/smooth_icon = 'icons/obj/smooth_structures/fancy_table.dmi' // see Initialize()

/obj/structure/table/wood/fancy/Initialize(mapload)
	. = ..()
	// Needs to be set dynamically because table smooth sprites are 32x34,
	// which the editor treats as a two-tile-tall object. The sprites are that
	// size so that the north/south corners look nice - examine the detail on
	// the sprites in the editor to see why.
	icon = smooth_icon

	if (!(flags_1 & NODECONSTRUCT_1))
		var/static/list/tool_behaviors = list(
			TOOL_SCREWDRIVER = list(
				SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Disassemble"),
			),

			TOOL_WRENCH = list(
				SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Deconstruct"),
			),
		)

		AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)

/obj/structure/table/wood/fancy/black
	icon_state = "fancy_table_black"
	buildstack = /obj/item/stack/tile/carpet/black
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_black.dmi'

/obj/structure/table/wood/fancy/blackred
	icon_state = "fancy_table_blackred"
	buildstack = /obj/item/stack/tile/carpet/blackred
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_blackred.dmi'

/obj/structure/table/wood/fancy/monochrome
	icon_state = "fancy_table_monochrome"
	buildstack = /obj/item/stack/tile/carpet/monochrome
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_monochrome.dmi'

/obj/structure/table/wood/fancy/blue
	icon_state = "fancy_table_blue"
	buildstack = /obj/item/stack/tile/carpet/blue
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_blue.dmi'

/obj/structure/table/wood/fancy/cyan
	icon_state = "fancy_table_cyan"
	buildstack = /obj/item/stack/tile/carpet/cyan
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_cyan.dmi'

/obj/structure/table/wood/fancy/green
	icon_state = "fancy_table_green"
	buildstack = /obj/item/stack/tile/carpet/green
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_green.dmi'

/obj/structure/table/wood/fancy/orange
	icon_state = "fancy_table_orange"
	buildstack = /obj/item/stack/tile/carpet/orange
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_orange.dmi'

/obj/structure/table/wood/fancy/purple
	icon_state = "fancy_table_purple"
	buildstack = /obj/item/stack/tile/carpet/purple
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_purple.dmi'

/obj/structure/table/wood/fancy/red
	icon_state = "fancy_table_red"
	buildstack = /obj/item/stack/tile/carpet/red
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_red.dmi'

/obj/structure/table/wood/fancy/royalblack
	icon_state = "fancy_table_royalblack"
	buildstack = /obj/item/stack/tile/carpet/royalblack
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_royalblack.dmi'

/obj/structure/table/wood/fancy/royalblue
	icon_state = "fancy_table_royalblue"
	buildstack = /obj/item/stack/tile/carpet/royalblue
	smooth_icon = 'icons/obj/smooth_structures/fancy_table_royalblue.dmi'

/*
 * Reinforced tables
 */
/obj/structure/table/reinforced
	name = "reinforced table"
	desc = "Усиленная версия четырёхножного стола."
	icon = 'icons/obj/smooth_structures/reinforced_table.dmi'
	icon_state = "r_table"
	deconstruction_ready = 0
	buildstack = /obj/item/stack/sheet/plasteel
	max_integrity = 200
	integrity_failure = 0.25
	armor = list(MELEE = 10, BULLET = 30, LASER = 30, ENERGY = 100, BOMB = 20, BIO = 0, RAD = 0, FIRE = 80, ACID = 70)

/obj/structure/table/reinforced/deconstruction_hints(mob/user)
	if(deconstruction_ready)
		return "<span class='notice'>Верх стола <i>отварен</i> и видно оголённые <b>болты</b> каркаса.</span>"
	return "<span class='notice'>Верх стола крепко <b>приварен</b> к месту.</span>"

/obj/structure/table/reinforced/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WELDER && !(user.a_intent == INTENT_HELP))
		if(!W.tool_start_check(user, amount=0))
			return

		if(deconstruction_ready)
			to_chat(user, "<span class='notice'>Вы стали усиливать стол...</span>")
			if (W.use_tool(src, user, 50, volume=50))
				to_chat(user, "<span class='notice'>Вы усилили стол.</span>")
				deconstruction_ready = 0
		else
			to_chat(user, "<span class='notice'>Вы стали ослаблять стол...</span>")
			if (W.use_tool(src, user, 50, volume=50))
				to_chat(user, "<span class='notice'>Вы ослабили стол.</span>")
				deconstruction_ready = 1
	else
		. = ..()

/obj/structure/table/reinforced/plastitaniumglass
	name = "Plastitanium Glass Table"
	icon = 'icons/obj/smooth_structures/plastitaniumglass_table.dmi'
	icon_state = "plastitaniumglass_table"
	canSmoothWith = list(/obj/structure/table/reinforced/plastitaniumglass)
	desc = "Стол из силикат-плазменного композита с титановым усилением. Прочно так же, как и звучит."
	buildstack = /obj/item/stack/sheet/plastitaniumglass
	max_integrity = 300

/obj/structure/table/reinforced/brass
	name = "brass table"
	desc = "A solid, slightly beveled brass table."
	icon = 'icons/obj/smooth_structures/brass_table.dmi'
	icon_state = "brass_table"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	frame = /obj/structure/table_frame/brass
	framestack = /obj/item/stack/tile/brass
	buildstack = /obj/item/stack/tile/brass
	framestackamount = 1
	buildstackamount = 1
	canSmoothWith = list(/obj/structure/table/reinforced/brass, /obj/structure/table/bronze)

/obj/structure/table/reinforced/brass/New()
	change_construction_value(2)
	..()

/obj/structure/table/reinforced/brass/Destroy()
	change_construction_value(-2)
	return ..()

/obj/structure/table/reinforced/brass/tablelimbsmash(mob/living/user, mob/living/pushed_mob)
	.= ..()
	playsound(src, 'sound/magic/clockwork/fellowship_armory.ogg', 50, TRUE)

/obj/structure/table/reinforced/brass/narsie_act()
	take_damage(rand(15, 45), BRUTE)
	if(src) //do we still exist?
		var/previouscolor = color
		color = "#960000"
		animate(src, color = previouscolor, time = 8)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 8)

/obj/structure/table/reinforced/brass/ratvar_act()
	obj_integrity = max_integrity

/obj/structure/table/bronze
	name = "bronze table"
	desc = "Крепкий стол из бронзы."
	icon = 'icons/obj/smooth_structures/brass_table.dmi'
	icon_state = "brass_table"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	buildstack = /obj/item/stack/sheet/bronze
	canSmoothWith = list(/obj/structure/table/reinforced/brass, /obj/structure/table/bronze)

/obj/structure/table/bronze/tablelimbsmash(mob/living/user, mob/living/pushed_mob)
	..()
	playsound(src, 'sound/magic/clockwork/fellowship_armory.ogg', 50, TRUE)

/*
 * Surgery Tables
 */

/obj/structure/table/optable
	name = "operating table"
	desc = "Кушетка для продвинутых хирургических операций."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "optable"
	buildstack = /obj/item/stack/sheet/mineral/silver
	smooth = SMOOTH_FALSE
	can_buckle = 1
	buckle_lying = 90
	var/mob/living/carbon/human/patient = null
	var/obj/machinery/computer/operating/computer = null
// BLUEMOON ADD START
	var/obj/item/tank/internals/tank = null // баллон внутри
	var/obj/item/clothing/mask/mask = null // маска внутри

/obj/structure/table/optable/Initialize(mapload)
	. = ..()
	register_context()


/obj/structure/table/optable/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Unbuckle patient")
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Set internals")
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Remove tank and mask")
	return CONTEXTUAL_SCREENTIP_SET

/obj/structure/table/optable/examine(mob/user)
	. = ..()
	. += "<hr>"

	if(tank)
		. += span_info("Сбоку на нём закреплён [tank].")
	else
		. += span_warning("Сбоку есть пустое место под ёмкость с газом (баллон или канистру).")

	if(mask)
		. += span_info("На стойке висит [mask].")
	else
		. += span_warning("Сбоку находится пустая стойка для маски.")

	if(computer)
		. += span_info("Операционный стол подключен к компьютеру рядом через кабель на полу.")

	if(tank && mask)
		. += span_notice("Alt-Click для подачи анестетика пациенту на столе.")

	if(tank || mask)
		. += span_notice("Ctrl-Click: отсоединить от стола баллон и маску.")

/obj/structure/table/optable/AltClick(mob/living/user)
	. = ..()
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	if(tank && mask)
		if(!check_patient())
			return
		if(!patient.internal) // у пациента не включена подача воздуха
			to_chat(user, span_notice("Вы начинаете включать подачу анестетика."))
			if(patient.stat != UNCONSCIOUS) // пациент без сознания не видит сообщение ниже
				to_chat(patient, span_danger("[user] пытается включить подачу анестетика!"))
			if(!do_after(user, 3 SECONDS, patient))
				return
			if(patient.wear_mask)
				if(isclothing(patient.wear_mask)) // это одежда
					var/obj/item/clothing/patient_item_in_mask_slot = patient.wear_mask
					if(!(patient_item_in_mask_slot.clothing_flags & ALLOWINTERNALS)) // можно использовать для дыхания
						if(!patient.dropItemToGround(patient.wear_mask)) // если нельзя, то можно ли снять
							to_chat(user, span_danger("У вас не получилось снять маску с [patient], чтобы надеть кислородную маску!"))
							return
				else // это предмет
					if(!patient.dropItemToGround(patient.wear_mask))
						to_chat(user, span_danger("У вас не получилось убрать предмет с лица [patient], чтобы надеть кислородную маску!"))
						return
			patient.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK)
			if(!patient.wear_mask) // если головы нет, например
				to_chat(user, span_danger("У вас не получилось надеть кислородную маску на [patient]!"))
				return
			patient.internal = tank
			user.visible_message("[user] подключает оборудование для анестезии к [patient] и проворачиваете клапан.", span_notice("Вы открываете клапан с анестезией. Убедитесь, что пациент спит и можно начинать."))
			START_PROCESSING(SSobj, src)
		else
			if(patient.internal != tank) // У пациента включен собственный баллон
				to_chat(user, span_danger("Сначала нужно отключить собственный баллон у [patient]!"))
				return
			if(!do_after(user, 1 SECONDS, patient))
				return
			user.visible_message("[user] отключает подачу анестетика к [patient].", span_notice("Вы проворачиваете клапан и отключаете подачу анестезии."))
			stop_process()
	else
		to_chat(user, span_warning("[src] не имеет прикрепленного к нему баллона или маски!"))
		return

/obj/structure/table/optable/CtrlClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(!isliving(user))
		to_chat(user, span_warning("Это слишком сложно для вас!"))
		return
	if(check_patient())
		to_chat(user, span_warning("Сначала нужно убрать пациента!"))
		return
	if(tank && !patient?.internal)
		to_chat(user, span_notice("Вы убираете [tank] с бока операционного стола."))
		user.put_in_hands(tank)
		tank = null
	else if(mask && !patient?.internal)
		to_chat(user, span_notice("Вы убираете [mask] со стойки операционного стола."))
		user.put_in_hands(mask)
		mask = null

/obj/structure/table/optable/attack_robot(mob/user)
	if(Adjacent(user))
		return attack_hand(user)

/obj/structure/table/optable/post_buckle_mob(mob/living/M)
	. = ..()
	check_patient()

/obj/structure/table/optable/process()
	if(mask?.loc != patient || tank?.loc != src || patient?.loc != loc)
		stop_process()

/obj/structure/table/optable/proc/stop_process()
	STOP_PROCESSING(SSobj, src)
	if(!patient)
		if(mask)
			mask.forceMove(src)
		return
	if(mask && mask.loc != src)
		visible_message(span_notice("[mask] срывается и возвращается на место по втягивающемуся шлангу."))
		patient.transferItemToLoc(mask, src, TRUE)
	patient.internal = null
	patient = null

/obj/structure/table/optable/Destroy()
	if(tank)
		tank.forceMove(loc)
		tank = null
	if(mask)
		mask.forceMove(loc)
		mask = null
	if(patient)
		if(patient.internal == tank)
			patient.internal = null
		patient = null
	if(computer)
		computer.table = null
		computer = null
	STOP_PROCESSING(SSobj, src)
	. = ..()

// We dont wont put item
/obj/structure/table/optable/PutItemOnTable(obj/item/I, mob/living/user, params)
	return

/obj/structure/table/optable/attackby(obj/item/I, mob/living/user, attackchain_flags, damage_multiplier)
	if(user.a_intent == INTENT_HELP)
		if(!tank)
			if(istype(I, /obj/item/tank/internals))
				if(user.transferItemToLoc(I, src))
					user.visible_message("[user] закрепляет [I] сбоку операционного стола.", span_notice("Вы закрепляете [I] сбоку операционного стола."))
					tank = I
					return
		if(!mask)
			if(istype(I, /obj/item/clothing/mask))
				var/obj/item/clothing/mask/potential_mask = I
				if(potential_mask.clothing_flags & ALLOWINTERNALS) // можно использовать для дыхания
					if(user.transferItemToLoc(I, src))
						user.visible_message("[user] закрепляет [I] на стойку для маски.", span_notice("Вы закрепляете [I] на стойку для маски."))
						mask = I
						return
	. = ..()
// BLUEMOON ADD END

/obj/structure/table/optable/New()
	..()
	for(var/direction in GLOB.cardinals)
		computer = locate(/obj/machinery/computer/operating, get_step(src, direction))
		if(computer)
			computer.table = src
			break

/obj/structure/table/optable/tablelimbsmash(mob/living/user, mob/living/pushed_mob)
	pushed_mob.forceMove(loc)
	pushed_mob.set_resting(TRUE, TRUE)
	visible_message("<span class='notice'>[user] укладывает [pushed_mob] на [src].</span>")
	check_patient()

/obj/structure/table/optable/proc/check_patient()
	var/mob/living/carbon/human/H = locate() in loc
	if(H)
		if(!CHECK_MOBILITY(H, MOBILITY_STAND))
			patient = H
			return TRUE
	else
		patient = null
		return FALSE

/*
 * Racks
 */
/obj/structure/rack
	name = "rack"
	desc = "Совсем не как во времена Средневековья..."
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"
	layer = TABLE_LAYER
	density = TRUE
	anchored = TRUE
	pass_flags_self = LETPASSTHROW //You can throw objects over this, despite it's density.
	max_integrity = 20
	attack_hand_speed = CLICK_CD_MELEE
	attack_hand_is_action = TRUE

/obj/structure/rack/shelf
	name = "shelf"
	desc = "Шкаф для хранения вещей. Удобно!"
	icon_state = "shelf"

/obj/structure/rack/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Держится на парочке <b>болтов</b>.</span>"

/obj/structure/rack/CanPass(atom/movable/mover, turf/target)
	if(src.density == 0) //Because broken racks -Agouri |TODO: SPRITE!|
		return TRUE
	if(istype(mover) && (mover.pass_flags & PASSTABLE))
		return TRUE
	else
		return FALSE

/obj/structure/rack/CanAStarPass(obj/item/card/id/ID, to_dir, atom/movable/caller)
	. = !density
	if(istype(caller))
		. = . || (caller.pass_flags & PASSTABLE)

/obj/structure/rack/MouseDrop_T(obj/O, mob/user)
	. = ..()
	if ((!( istype(O, /obj/item) ) || user.get_active_held_item() != O))
		return
	if(!user.dropItemToGround(O))
		return
	if(O.loc != src.loc)
		step(O, get_dir(O, src))

/obj/structure/rack/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH && !(flags_1 & NODECONSTRUCT_1))
		W.play_tool_sound(src)
		deconstruct(TRUE)
		return
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(user.transferItemToLoc(W, drop_location()))
		return TRUE

/obj/structure/rack/attack_paw(mob/living/user)
	attack_hand(user)

/obj/structure/rack/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(CHECK_MULTIPLE_BITFIELDS(user.mobility_flags, MOBILITY_STAND|MOBILITY_MOVE) || user.get_num_legs() < 2)
		return
	user.do_attack_animation(src, ATTACK_EFFECT_KICK)
	user.visible_message("<span class='danger'>[user] kicks [src].</span>", null, null, COMBAT_MESSAGE_RANGE)
	take_damage(rand(4,8), BRUTE, MELEE, 1)

/obj/structure/rack/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(loc, 'sound/items/dodgeball.ogg', 80, 1)
			else
				playsound(loc, 'sound/weapons/tap.ogg', 50, 1)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 40, 1)

/*
 * Rack destruction
 */

/obj/structure/rack/deconstruct(disassembled = TRUE)
	if(!(flags_1&NODECONSTRUCT_1))
		density = FALSE
		var/obj/item/rack_parts/newparts = new(loc)
		transfer_fingerprints_to(newparts)
	qdel(src)


/*
 * Rack Parts
 */

/obj/item/rack_parts
	name = "rack parts"
	desc = "Части стойки."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "rack_parts"
	flags_1 = CONDUCT_1
	custom_materials = list(/datum/material/iron=2000)
	var/building = FALSE
	// MODULAR_JUICY-ADD - Делаем дефолтный путь к объекту в виде переменной, чтобы можно было передать что за тип конструкции
	var/obj/construction_type = /obj/structure/rack
	// MODULAR_JUICY-ADD

/obj/item/shelf_parts
	name = "shelf parts"
	desc = "Части шкафа."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "rack_parts"
	flags_1 = CONDUCT_1
	custom_materials = list(/datum/material/iron=2000)
	var/building = FALSE

/obj/item/rack_parts/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		new /obj/item/stack/sheet/metal(user.loc)
		qdel(src)
	else
		. = ..()

/obj/item/rack_parts/attack_self(mob/user)
	// BLUEMOON ADD
	if(locate(construction_type) in get_turf(user))
		balloon_alert(user, "не хватает места!")
		return
	// BLUEMOON ADD END
	if(building)
		return
	building = TRUE
	to_chat(user, "<span class='notice'>Вы стали собирать воедино [src]...</span>") // BLUEMOON EDIT
	if(do_after(user, 50, target = user, progress=TRUE))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return
		var/obj/structure/R = new construction_type(user.loc) // BLUEMOON EDIT
		user.visible_message("<span class='notice'>[user] собирает \a [R].\
			</span>", "<span class='notice'>Вы собрали \a [R].</span>")
		R.add_fingerprint(user)
		qdel(src)
	building = FALSE

/obj/item/shelf_parts/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		new /obj/item/stack/sheet/metal(user.loc)
		qdel(src)
	else
		. = ..()

/obj/item/shelf_parts/attack_self(mob/user)
	if(building)
		return
	building = TRUE
	to_chat(user, "<span class='notice'>Вы стали возводить шкаф..</span>")
	if(do_after(user, 50, target = user, progress=TRUE))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return
		var/obj/structure/rack/shelf/R = new /obj/structure/rack/shelf(user.loc)
		user.visible_message("<span class='notice'>[user] собрал[user.ru_a()] \a [R].\
			</span>", "<span class='notice'>Вы собрали \a [R].</span>")
		R.add_fingerprint(user)
		qdel(src)
	building = FALSE
