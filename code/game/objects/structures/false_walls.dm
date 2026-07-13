/*
 * False Walls
 */
/obj/structure/falsewall
	name = "wall"
	desc = "A huge chunk of metal used to separate rooms."
	anchored = TRUE
	icon = 'modular_bluemoon/icons/turf/false_walls.dmi'
	icon_state = "wall-open"
	base_icon_state = "wall"
	plane = WALL_PLANE
	layer = LOW_OBJ_LAYER
	density = TRUE
	opacity = 1
	max_integrity = 100

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_WALLS
	can_be_unanchored = FALSE
	CanAtmosPass = ATMOS_PASS_DENSITY
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	rad_insulation = RAD_MEDIUM_INSULATION
	/// The icon this falsewall fakes when closed.
	var/fake_icon = 'modular_bluemoon/icons/turf/walls/wall.dmi'
	var/mineral = /obj/item/stack/sheet/metal
	var/mineral_amount = 2
	var/walltype = /turf/closed/wall
	var/girder_type = /obj/structure/girder/displaced
	var/opening = FALSE

/obj/structure/falsewall/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE)
	update_appearance()

/obj/structure/falsewall/ratvar_act()
	new /obj/structure/falsewall/brass(loc)
	qdel(src)

/obj/structure/falsewall/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(opening)
		return
	. = ..()
	if(.)
		return

	opening = TRUE
	update_appearance()
	if(!density)
		var/srcturf = get_turf(src)
		for(var/mob/living/obstacle in srcturf) //Stop people from using this as a shield
			opening = FALSE
			return
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/structure/falsewall, toggle_open)), 5)

/obj/structure/falsewall/proc/toggle_open()
	if(!QDELETED(src))
		density = !density
		set_opacity(density)
		opening = FALSE
		update_appearance()
		air_update_turf(TRUE)

/obj/structure/falsewall/update_icon(updates = ALL)
	. = ..()
	if(!density || !(updates & UPDATE_SMOOTHING))
		return

	if(opening)
		smoothing_flags &= ~USES_SMOOTHING
	else
		smoothing_flags |= SMOOTH_BITMASK | SMOOTH_OBJ
		QUEUE_SMOOTH(src)

/obj/structure/falsewall/update_icon_state()
	if(opening)
		icon = initial(icon)
		icon_state = "[base_icon_state]-[density ? "opening" : "closing"]"
		return ..()
	if(density)
		icon = fake_icon
		icon_state = "[base_icon_state]-[smoothing_junction]"
	else
		icon = initial(icon)
		icon_state = "[base_icon_state]-open"
	return ..()

/obj/structure/falsewall/proc/ChangeToWall(delete = 1)
	var/turf/T = get_turf(src)
	T.PlaceOnTop(walltype)
	if(delete)
		qdel(src)
	return T

/obj/structure/falsewall/attackby(obj/item/W, mob/user, params)
	if(opening)
		to_chat(user, "<span class='warning'>You must wait until the door has stopped moving!</span>")
		return

	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(density)
			var/turf/T = get_turf(src)
			if(T.density)
				to_chat(user, "<span class='warning'>[src] is blocked!</span>")
				return
			if(!isfloorturf(T))
				to_chat(user, "<span class='warning'>[src] bolts must be tightened on the floor!</span>")
				return
			user.visible_message("<span class='notice'>[user] tightens some bolts on the wall.</span>", "<span class='notice'>You tighten the bolts on the wall.</span>")
			ChangeToWall()
		else
			to_chat(user, "<span class='warning'>You can't reach, close it first!</span>")

	else if(W.tool_behaviour == TOOL_WELDER || istype(W, /obj/item/gun/energy/plasmacutter))
		if(W.use_tool(src, user, 0, volume=50))
			dismantle(user, TRUE)
	else if(istype(W, /obj/item/pickaxe/drill/jackhammer))
		W.play_tool_sound(src)
		dismantle(user, TRUE)
	else
		return ..()

/obj/structure/falsewall/proc/dismantle(mob/user, disassembled=TRUE, obj/item/tool = null)
	user.visible_message("[user] dismantles the false wall.", "<span class='notice'>You dismantle the false wall.</span>")
	if(tool)
		tool.play_tool_sound(src, 100)
	else
		playsound(src, 'sound/items/welder.ogg', 100, 1)
	deconstruct(disassembled)

/obj/structure/falsewall/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			new girder_type(loc)
		if(mineral_amount)
			for(var/i in 1 to mineral_amount)
				new mineral(loc)
	qdel(src)

/obj/structure/falsewall/get_dumping_location(obj/item/storage/source,mob/user)
	return null

/obj/structure/falsewall/examine_status(mob/user) //So you can't detect falsewalls by examine.
	to_chat(user, "<span class='notice'>The outer plating is <b>welded</b> firmly in place.</span>")
	return null

/*
 * False R-Walls
 */

/obj/structure/falsewall/reinforced
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms."
	icon_state = "reinforced_wall-open"
	base_icon_state = "reinforced_wall"
	fake_icon = 'modular_bluemoon/icons/turf/walls/reinforced_wall.dmi'
	walltype = /turf/closed/wall/r_wall
	mineral = /obj/item/stack/sheet/plasteel

/obj/structure/falsewall/reinforced/examine_status(mob/user)
	to_chat(user, "<span class='notice'>The outer <b>grille</b> is fully intact.</span>")
	return null

/obj/structure/falsewall/reinforced/attackby(obj/item/tool, mob/user)
	..()
	if(tool.tool_behaviour == TOOL_WIRECUTTER)
		dismantle(user, TRUE, tool)

/*
 * Uranium Falsewalls
 */

/obj/structure/falsewall/uranium
	name = "uranium wall"
	desc = "A wall with uranium plating. This is probably a bad idea."
	icon_state = "uranium_wall-open"
	base_icon_state = "uranium_wall"
	mineral = /obj/item/stack/sheet/mineral/uranium
	walltype = /turf/closed/wall/mineral/uranium
	smoothing_groups = SMOOTH_GROUP_URANIUM_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_URANIUM_WALLS + SMOOTH_GROUP_WALLS
	var/active = null
	var/last_event = 0

/obj/structure/falsewall/uranium/attackby(obj/item/W, mob/user, params)
	radiate()
	return ..()

/obj/structure/falsewall/uranium/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	radiate()
	. = ..()

/obj/structure/falsewall/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			radiation_pulse(src, 150)
			for(var/turf/closed/wall/mineral/uranium/T in orange(1,src))
				T.radiate()
			last_event = world.time
			active = null
			return
	return
/*
 * Other misc falsewall types
 */

/obj/structure/falsewall/gold
	name = "gold wall"
	desc = "A wall with gold plating. Swag!"
	icon_state = "gold_wall-open"
	base_icon_state = "gold_wall"
	mineral = /obj/item/stack/sheet/mineral/gold
	walltype = /turf/closed/wall/mineral/gold
	smoothing_groups = SMOOTH_GROUP_GOLD_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_GOLD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/silver
	name = "silver wall"
	desc = "A wall with silver plating. Shiny."
	icon_state = "silver_wall-open"
	base_icon_state = "silver_wall"
	mineral = /obj/item/stack/sheet/mineral/silver
	walltype = /turf/closed/wall/mineral/silver
	smoothing_groups = SMOOTH_GROUP_SILVER_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_SILVER_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/diamond
	name = "diamond wall"
	desc = "A wall with diamond plating. You monster."
	icon_state = "diamond_wall-open"
	base_icon_state = "diamond_wall"
	mineral = /obj/item/stack/sheet/mineral/diamond
	walltype = /turf/closed/wall/mineral/diamond
	smoothing_groups = SMOOTH_GROUP_DIAMOND_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_DIAMOND_WALLS + SMOOTH_GROUP_WALLS
	max_integrity = 800

/obj/structure/falsewall/plasma
	name = "plasma wall"
	desc = "A wall with plasma plating. This is definitely a bad idea."
	icon_state = "plasma_wall-open"
	base_icon_state = "plasma_wall"
	mineral = /obj/item/stack/sheet/mineral/plasma
	walltype = /turf/closed/wall/mineral/plasma
	smoothing_groups = SMOOTH_GROUP_PLASMA_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_PLASMA_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/plasma/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300)
		var/turf/T = get_turf(src)
		message_admins("Plasma falsewall ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_admin("Plasma falsewall ignited by [key_name(user)] in [AREACOORD(T)]")
		burnbabyburn()
	else
		return ..()

/obj/structure/falsewall/plasma/proc/burnbabyburn(user)
	playsound(src, 'sound/items/welder.ogg', 100, 1)
	atmos_spawn_air("plasma=400;TEMP=1000")
	new /obj/structure/girder/displaced(loc)
	qdel(src)

/obj/structure/falsewall/plasma/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		burnbabyburn()

/obj/structure/falsewall/bananium
	name = "bananium wall"
	desc = "A wall with bananium plating. Honk!"
	icon_state = "bananium_wall-open"
	base_icon_state = "bananium_wall"
	mineral = /obj/item/stack/sheet/mineral/bananium
	walltype = /turf/closed/wall/mineral/bananium
	smoothing_groups = SMOOTH_GROUP_BANANIUM_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_BANANIUM_WALLS + SMOOTH_GROUP_WALLS


/obj/structure/falsewall/sandstone
	name = "sandstone wall"
	desc = "A wall with sandstone plating. Rough."
	icon_state = "sandstone_wall-open"
	base_icon_state = "sandstone_wall"
	mineral = /obj/item/stack/sheet/mineral/sandstone
	walltype = /turf/closed/wall/mineral/sandstone
	smoothing_groups = SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/wood
	name = "wooden wall"
	desc = "A wall with wooden plating. Stiff."
	icon_state = "wood_wall-open"
	base_icon_state = "wood_wall"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/mineral/wood
	smoothing_groups = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/iron
	name = "rough metal wall"
	desc = "A wall with rough metal plating."
	icon_state = "iron_wall-open"
	base_icon_state = "iron_wall"
	mineral = /obj/item/stack/rods
	mineral_amount = 5
	walltype = /turf/closed/wall/mineral/iron
	smoothing_groups = SMOOTH_GROUP_IRON_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_IRON_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/abductor
	name = "alien wall"
	desc = "A wall with alien alloy plating."
	icon_state = "abductor_wall-open"
	base_icon_state = "abductor_wall"
	mineral = /obj/item/stack/sheet/mineral/abductor
	walltype = /turf/closed/wall/mineral/abductor
	smoothing_groups = SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/titanium
	name = "wall"
	desc = "A light-weight titanium wall used in shuttles."
	icon_state = "shuttle_wall-open"
	base_icon_state = "shuttle_wall"
	mineral = /obj/item/stack/sheet/mineral/titanium
	walltype = /turf/closed/wall/mineral/titanium
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_DIAGONAL_CORNERS | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/plastitanium
	name = "wall"
	desc = "An evil wall of plasma and titanium."
	icon_state = "plastitanium_wall-open"
	base_icon_state = "plastitanium_wall"
	mineral = /obj/item/stack/sheet/mineral/plastitanium
	walltype = /turf/closed/wall/mineral/plastitanium
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_DIAGONAL_CORNERS | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/brass
	name = "clockwork wall"
	desc = "A huge chunk of warm metal. The clanging of machinery emanates from within."
	icon_state = "clockwork_wall-open"
	base_icon_state = "clockwork_wall"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mineral_amount = 1
	smoothing_groups = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS
	girder_type = /obj/structure/destructible/clockwork/wall_gear/displaced
	walltype = /turf/closed/wall/clockwork
	mineral = /obj/item/stack/tile/brass

/obj/structure/falsewall/brass/New(loc)
	..()
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/ratvar/wall/false(T)
	new /obj/effect/temp_visual/ratvar/beam/falsewall(T)
	change_construction_value(4)

/obj/structure/falsewall/brass/Destroy()
	change_construction_value(-4)
	return ..()

/obj/structure/falsewall/brass/ratvar_act()
	if(GLOB.ratvar_awakens)
		obj_integrity = max_integrity
