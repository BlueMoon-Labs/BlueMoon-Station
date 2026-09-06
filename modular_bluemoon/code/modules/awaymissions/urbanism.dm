/turf/closed/mineral/mesarock
	name = "rock"
	icon = 'icons/turf/mining.dmi'
	smooth_icon = 'icons/turf/walls/rock_wall.dmi'
	icon_state = "rockyash"
	smooth = SMOOTH_MORE|SMOOTH_BORDER
	canSmoothWith = list (/turf/closed)
	var/resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	explosion_block = INFINITY
	wave_explosion_block = INFINITY

/turf/closed/mineral/mesarock/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_INTERCEPT_TELEPORT, PROC_REF(block_teleport))

/turf/closed/mineral/mesarock/proc/block_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_TELEPORT


/turf/closed/mineral/mesarock/rust_heretic_act()
	return

/turf/closed/mineral/mesarock/TerraformTurf(path, new_baseturf, flags, defer_change = FALSE, ignore_air = FALSE)
	return

/turf/closed/mineral/mesarock/acid_act(acidpwr, acid_volume, acid_id)
	return FALSE

/turf/closed/mineral/mesarock/Melt()
	to_be_destroyed = FALSE
	return src

/turf/closed/mineral/mesarock/singularity_act()
	return

/turf/closed/mineral/mesarock/attackby(obj/item/pickaxe/I, mob/user, params)
	return

/turf/closed/mineral/mesarock/attack_hand(mob/user)
	return

/turf/closed/mineral/mesarock/attack_animal(mob/living/simple_animal/user, list/modifiers)
	return

/turf/closed/mineral/mesarock/attack_alien(mob/living/carbon/alien/user, list/modifiers)
	return

/turf/closed/mineral/mesarock/attack_hulk(mob/living/carbon/human/H)
	return

/turf/closed/mineral/mesarock/ex_act(severity, target, origin)
	return

/turf/closed/mineral/mesarock/gets_drilled(user, give_exp = FALSE)
	return

/obj/machinery/power/floodlight/urbanismlight
	name = "Floodlight"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "oldfloodlight"
	anchored = TRUE
	armor = list(MELEE = 30, BULLET =30, LASER = 20, ENERGY = 10, BOMB = 30, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)

/obj/machinery/power/floodlight/urbanismlight/mesaspec
	icon_state = "oldfloodlight_on"
	layer = 4
	light_range = 15
	light_color = "#ffffdd"
	light_flags = LIGHT_NO_RANGE_CAP
	max_integrity = 9999999


/obj/structure/closet/crate/urbanismcrate
	name = "military crate"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "milcrate"

/obj/structure/closet/crate/large/urbanismcratelarge
	name = "big box"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "box"

/obj/structure/closet/crate/large/urbanismcratelarge/mil
	name = "big military box"
	icon_state = "boxmil"

/obj/structure/urbanismdamagedbarrel
	name = "Old rusty barrel"
	desc = "An old barrel with some junk in"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "drumfire"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 30, BULLET =30, LASER = 20, ENERGY = 10, BOMB = 30, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)

/obj/structure/reagent_dispensers/urbanismbarrel
	name = "Barrel"
	desc = "Typical barrel. Contains... Something"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "barrel"
	anchored = TRUE
	armor = list(MELEE = 60, BULLET =50, LASER = 10, ENERGY = 10, BOMB = 30, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)

/obj/structure/reagent_dispensers/urbanismbarrel/red
	icon_state = "redbarrel"
	reagent_id = /datum/reagent/fuel
	tank_volume = 300

/obj/structure/reagent_dispensers/urbanismbarrel/radium/Initialize(mapload)
	. = ..()
	var/datum/component/radioactive/Comp
	AddComponent(/datum/component/radioactive, 0, src, 0, TRUE)
	Comp = GetComponent(/datum/component/radioactive)
	Comp.set_strength(rad_strength)

/obj/structure/barricade/urbanism
	name = "Barricade"
	desc = "Basic barricade meant to protect idiots like you from danger."
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "crowd_barrier"
	anchored = TRUE
	density = TRUE
	pass_flags_self = LETPASSTHROW
	max_integrity = 280
	proj_pass_rate = 20
	climbable = TRUE
	armor = list(MELEE = 30, BULLET =40, LASER = 10, ENERGY = 10, BOMB = 30, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)

/obj/structure/barricade/urbanism/roadblock
	resistance_flags = INDESTRUCTIBLE
	icon_state = "concrete"

/obj/structure/urbanismpile
	name = "Trash Crate"
	desc = "Crate full of trash... Found someone?"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "dumpsteropen_halffull"
	resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	density = TRUE

/obj/structure/urbanismtire
	name = "Tire"
	desc = "Tire for cars and fireplaces"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "shina"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 20, BULLET =40, LASER = 10, ENERGY = 10, BOMB = 30, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)

/obj/structure/urbanismpower
	name = "Power Line"
	desc = "Эта необычная старая вышка обеспечивает электричеством то место, где вы сейчас находитесь"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism_structure32x64.dmi'
	icon_state = "powerline"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	layer = SPACEVINE_LAYER

/obj/structure/urbanismpower/transformer
	name = "Power transformer"
	desc = "электротехническое устройство в сетях электроснабжения с двумя или более обмотками, который посредством электромагнитной индукции преобразует одну величину переменного напряжения и тока в другую величину переменного напряжения и тока, той же частоты без изменения её передаваемой мощности"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism_structure32x64.dmi'
	icon_state = "powertransformer"

/obj/structure/urbanismbigcrate
	name = "Big boxes"
	desc = "One big box with one smaller on it. Honestly, they are empty"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism_structure32x64.dmi'
	icon_state = "crate"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	layer = SPACEVINE_LAYER

/obj/structure/urbanismbigcrate/alt
	name = "heavy boxes"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "boxalt"


/obj/structure/urbanismcars
	name = "Damaged car"
	desc = "Just lost in time broken (and bit rusty) vehicle"
	icon = 'modular_bluemoon/icons/obj/urbanism/vehicles140x140.dmi'
	icon_state = "car_wreck"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 70, BULLET =60, LASER = 50, ENERGY = 80, BOMB = 50, BIO = 10, RAD = 10, FIRE = 50, ACID = 50)
	layer = SPACEVINE_LAYER

/obj/structure/urbanismradio
	name = "Radio"
	desc = "Big rusty radio tower"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism_structure32x64.dmi'
	icon_state = "radio"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	layer = SPACEVINE_LAYER


/obj/structure/urbanismdisplay
	name = "Black mesa based display"
	desc = "Looks like black mesa BIOS is sucks."
	icon = 'modular_bluemoon/icons/obj/urbanism/mesa_display.dmi'
	icon_state = "display_broken"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	light_range = 5
	light_color = "#2652e2"
	max_integrity = 9999999
	layer = SPACEVINE_LAYER

/obj/structure/urbanismdisplay/urbanismchalk
	name = "Big chalkboard"
	desc = "Here is many of symbols and text... You barely can understand this smart words and scientific formulas"
	icon = 'modular_bluemoon/icons/obj/urbanism/mesa_display.dmi'
	icon_state = "chalkboard"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	light_range = FALSE
	light_color = FALSE
	max_integrity = 9999999

/obj/structure/urbanismmachines

	name = "old machine"
	desc = "some kind of old (and sometimes broken) machine"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "server_desrtoyed"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 30, BULLET =50, LASER = 30, ENERGY = 20, BOMB = 70, BIO = 15, RAD = 10, FIRE = 40, ACID = 30)

/obj/structure/urbanismmachines/hecucamp

	name = "abandoned camp"
	desc = "abandoned camp of hecu"
	icon = 'modular_bluemoon/icons/obj/urbanism/camps.dmi'
	icon_state = "camp"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 30, BULLET =50, LASER = 30, ENERGY = 20, BOMB = 70, BIO = 15, RAD = 10, FIRE = 40, ACID = 30)

/obj/structure/urbanismmachines/osprey

	name = "crushed osprey"
	desc = "something terryfying happened here..."
	icon = 'modular_bluemoon/icons/obj/urbanism/crushedosprey.dmi'
	icon_state = "crushedosprey"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 30, BULLET =50, LASER = 30, ENERGY = 20, BOMB = 70, BIO = 15, RAD = 10, FIRE = 40, ACID = 30)


/obj/structure/urbanismmachines/server

	name = "old server"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism_structure32x64.dmi'
	icon_state = "server"

/obj/structure/urbanismmounted

	name = "Mounted kind of machine"
	desc = "here's many terminals and generators... Be careful"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "terminal_broken"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 30, BULLET =50, LASER = 30, ENERGY = 20, BOMB = 70, BIO = 15, RAD = 10, FIRE = 40, ACID = 30)


/obj/structure/urbanismbillboard
	name = "Big billboard"
	desc = "YOUR AD COULD BE HERE!"
	icon = 'modular_bluemoon/icons/obj/urbanism/bilboards.dmi'
	icon_state = "bilboard1"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 80, BULLET =80, LASER = 70, ENERGY = 60, BOMB = 80, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	light_range = FALSE
	light_color = FALSE
	max_integrity = 9999999
	layer = SPACEVINE_LAYER


/obj/structure/rockpilemesa
	name = "large rocks"
	icon_state = "rocks"
	icon = 'modular_bluemoon/icons/obj/urbanism/stone.dmi'
	icon_state = "stone1"
	color = "#f79668"

/obj/effect/turf_decal/misc/brokenwalls
	name = "crushed wall"
	icon = 'modular_bluemoon/icons/obj/urbanism/decals.dmi'
	icon_state = "brokenwall2"

/obj/effect/turf_decal/misc/brokenwalls/alt
	icon_state = "brokenwall1"


/obj/effect/turf_decal/weather/rock
	name = "rocks"
	icon = 'modular_bluemoon/icons/obj/urbanism/decals.dmi'
	icon_state = "rock"

/obj/structure/mesaflora
	name = "bush"
	desc = "A wild plant that is found in jungles."
	icon = 'modular_bluemoon/icons/obj/urbanism/flora.dmi'
	icon_state = "flora1"
	anchored = TRUE
	density = FALSE

/obj/structure/deadmesa
	name = "Damaged body"
	desc = "Horrific consequences of Resonance Cascade."
	icon = 'modular_bluemoon/icons/obj/urbanism/deadhuman.dmi'
	icon_state = "deadhecu"
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 50, BULLET =40, LASER = 50, ENERGY = 60, BOMB = 50, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	var/loot_amount = 2
	var/scavenge_time = 5 SECONDS
	var/can_use_hands = TRUE
	var/looted = FALSE
	var/list/loot = list(
		/obj/item/ammo_box/magazine/p90 = 10,
		/obj/item/ammo_box/magazine/mp5 = 10,
		/obj/item/grenade/frag = 5,
		/obj/item/ammo_box/magazine/scar = 8,
		/obj/item/ammo_box/magazine/fal/r10 = 8,
		/obj/item/clothing/shoes/jackboots = 15,
		/obj/item/storage/firstaid/regular = 5,
		/obj/item/ammo_box/magazine/m50 = 7,
		/obj/item/ammo_box/magazine/pistolm9mm = 12,
		/obj/item/clothing/gloves/combat = 10,
		/obj/item/gun/ballistic/automatic/pistol/hl9mm = 3
	)

/obj/structure/deadmesa/ComponentInitialize()
	. = ..()
	if(loot)
		AddElement(/datum/element/scavenging, loot_amount, loot, null, scavenge_time, can_use_hands, null, null, FALSE, NO_LOOT_RESTRICTION, 1)

/obj/structure/deadmesa/hecughost
	name = "Призрак лидера отряда HECU"
	desc = "Он точно потерялся... И он точно перепутал гейт Blackmesa с ihategordon. Появится ли blackmesa и тут? Что значит призрак этого парня? Зачем вы читаете его описание?"
	icon_state = "Hecughost"


/obj/structure/urbanismeffect
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanismmisc.dmi'
	icon_state = "red_big"
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT // Prevent mouse interaction
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	move_resist = INFINITY
	obj_flags = 0

	vis_flags = VIS_INHERIT_PLANE

/obj/structure/urbanismeffect/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	return

/obj/structure/urbanismeffect/fire_act(exposed_temperature, exposed_volume)
	return

/obj/structure/urbanismeffect/acid_act()
	return

/obj/structure/urbanismeffect/blob_act(obj/structure/blob/B)
	return

/obj/structure/urbanismeffect/attack_hulk(mob/living/carbon/human/user, does_attack_animation = 0)
	return FALSE

/obj/structure/urbanismeffect/experience_pressure_difference()
	return

/obj/structure/urbanismeffect/singularity_act()
	return FALSE

/obj/structure/urbanismeffect/ex_act(severity, target, origin)
	return

/obj/structure/urbanismeffect/ConveyorMove()
	return

/obj/structure/urbanismeffect/abstract

//заебала эта хуета с сломанными стейтами блять.
/obj/structure/flora/grass/snowgrass
	name = "snowy grass"
	desc = "A patch of overgrown grass."
	icon = 'icons/obj/flora/snowflora.dmi'
	icon_state = "snowgrass"

/obj/structure/urbanismhuge
	name = "huge construction"
	desc = "Oh my god, what a huge construction is this?"
	icon = 'modular_bluemoon/icons/obj/urbanism/hugeshit.dmi'
	icon_state = "huge1"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 100, BULLET =100, LASER = 100, ENERGY = 100, BOMB = 20, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	light_range = FALSE
	light_color = FALSE
	max_integrity = 5000
	layer = SPACEVINE_LAYER


/obj/structure/urbanismmachinery
	name = "heavy machinery"
	desc = "Huge piece of machinery, probably used in construction works."
	icon = 'modular_bluemoon/icons/obj/urbanism/communication.dmi'
	icon_state = "communication"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 100, BULLET =100, LASER = 100, ENERGY = 100, BOMB = 20, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	light_range = FALSE
	light_color = FALSE
	max_integrity = 5000
	layer = SPACEVINE_LAYER

/obj/structure/urbanismfabricator
	name = "heavy machinery"
	desc = "Huge piece of machinery, probably used in construction works."
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanismmachinery.dmi'
	icon_state = "hugem1"
	anchored = TRUE
	density = TRUE
	armor = list(MELEE = 100, BULLET =100, LASER = 100, ENERGY = 100, BOMB = 20, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	light_range = FALSE
	light_color = FALSE
	max_integrity = 5000
	layer = SPACEVINE_LAYER

/obj/structure/microwaveexplosive
	name = "suspicious microwave"
	desc = "This microwave looks... off. Better not touch it."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "mw"
	density = TRUE
	anchored = TRUE
	var/exploded = FALSE

/obj/structure/microwaveexplosive/attack_hand(mob/user)
	if(exploded)
		return
	exploded = TRUE
	. = ..()

	playsound(src, 'modular_bluemoon/sound/creatures/mesa/madsci/microwaveboom.ogg', 100, FALSE)

	for(var/obj/structure/mad_scientist/scientist in range(5, src))
		playsound(scientist, 'modular_bluemoon/sound/creatures/mesa/madsci/microwavefuck.ogg', 150, FALSE)

	explosion(src, 0, 0, 1, 1, flame_range = 1)

	new /obj/effect/hotspot(get_turf(src))

	icon_state = "mwbloodyo"
	new /obj/structure/urbanismeffect(get_turf(src))

// =============================================================================
// REINFORCED BARRICADES
// Barricades that can only be destroyed by bombardment
// =============================================================================

/obj/structure/barricade/wooden/reinforced
	name = "reinforced wooden barricade"
	desc = "A heavily reinforced wooden barricade. It seems impervious to conventional damage."
	icon = 'modular_bluemoon/icons/obj/barricade.dmi'
	icon_state = "wooden"
	max_integrity = 500
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE

/obj/structure/barricade/wooden/reinforced/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/mineral/wood))
		to_chat(user, span_warning("This barricade cannot be repaired."))
		return
	..()

/obj/structure/barricade/wooden/reinforced/crowbar_act(mob/living/user, obj/item/I)
	to_chat(user, span_warning("This barricade is too reinforced to be disassembled with a crowbar."))
	return TRUE

/obj/structure/barricade/wooden/reinforced/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armor_penetration)
	if(damage_flag == BOMB || damage_amount >= 100)
		..()
	else
		return 0

/obj/structure/barricade/wooden/crude/reinforced
	name = "reinforced crude wooden barricade"
	desc = "A heavily reinforced crude wooden barricade. It seems impervious to conventional damage."
	max_integrity = 400
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE

/obj/structure/barricade/wooden/crude/reinforced/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/mineral/wood))
		to_chat(user, span_warning("This barricade cannot be repaired."))
		return
	..()

/obj/structure/barricade/wooden/crude/reinforced/crowbar_act(mob/living/user, obj/item/I)
	to_chat(user, span_warning("This barricade is too reinforced to be disassembled with a crowbar."))
	return TRUE

/obj/structure/barricade/wooden/crude/reinforced/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armor_penetration)
	if(damage_flag == BOMB || damage_amount >= 100)
		..()
	else
		return 0

/obj/structure/mad_scientist
	name = "mad scientist"
	desc = "A deranged scientist who seems to be working on something dangerous."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "madscientist"
	density = TRUE
	anchored = TRUE

/obj/structure/mad_scientist/attack_hand(mob/user)
	. = ..()

	playsound(src, 'modular_bluemoon/sound/creatures/mesa/madsci/scimad.ogg', 100, FALSE)

/obj/structure/fence/nocut
	name = "reinforced fence"
	desc = "A chain link fence reinforced to prevent cutting."
	cuttable = FALSE
	pass_flags_self = PASSFENCE // Allow mobs with PASSFENCE to pass through

/obj/structure/fence/nocut/CanAStarPass(ID, dir, atom/movable/pathing_movable)
	// Allow zombies to path through this fence
	if(istype(pathing_movable, /mob/living/simple_animal/hostile/infected))
		return TRUE
	return ..()


/obj/structure/reagent_dispensers/urbanismbarrel/radium
	name = "Radium barrel"
	desc = "Barrel filled with radium. Very dangerous."
	icon_state = "radiumbarrel"
	reagent_id = /datum/reagent/radium
	tank_volume = 300
	var/rad_strength = 1000

/obj/structure/reagent_dispensers/urbanismbarrel/radium/Initialize(mapload)
	. = ..()
	var/datum/component/radioactive/Comp
	AddComponent(/datum/component/radioactive, 0, src, 0, TRUE)
	Comp = GetComponent(/datum/component/radioactive)
	Comp.set_strength(rad_strength)


/obj/structure/urbanism_generator
	name = "generator"
	desc = "A strange generator. Activate it with an empty hand."
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "generatorold"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	max_integrity = 9999999

	var/activation_time = 60 SECONDS
	var/active_duration = 60 SECONDS
	var/damage_threshold = 300

	var/activating = FALSE
	var/active = FALSE
	var/activation_start_time = 0
	var/next_mob_spawn_time = 0
	var/next_director_horde_time = 0
	var/damage_taken = 0

	var/spawn_mobs = FALSE
	var/list/mob_types = list()
	var/mob_spawn_interval = 10 SECONDS
	var/max_mobs_per_wave = 5
	var/spawn_radius = 5

	var/reward_type = null
	var/blastdoor_id = null

/turf/open/floor/plating/smooth/grass/urbanism
	name = "urbanism grass"
	desc = "A patch of grass found in urban areas."
	icon = 'modular_bluemoon/icons/turf/_smooth.dmi'
	icon_state = "grass"
	base_icon_state = "grass"
	footstep = FOOTSTEP_GRASS
	barefootstep = FOOTSTEP_GRASS
	clawfootstep = FOOTSTEP_GRASS
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	layer = 2.1
	smooth_icon = 'modular_bluemoon/icons/turf/_smooth.dmi'
	canSmoothWith = list(/turf/open/floor/plating/smooth/grass/urbanism, /turf/closed/indestructible)
	smooth_offset = 8

/obj/structure/urbanism_generator/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/urbanism_generator/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/urbanism_generator/process()
	if(activating && damage_taken >= damage_threshold)
		interrupt_activation()
		return

	if(spawn_mobs && mob_types && mob_types.len && activating)
		if(world.time >= next_mob_spawn_time)
			spawn_mob_wave()

	if(activating && GLOB.zombie_director)
		if(world.time >= next_director_horde_time)
			var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
			if(D)
				D.trigger_horde()
			next_director_horde_time = world.time + 60 SECONDS

	if(!active)
		return

	if(world.time >= activation_start_time + active_duration)
		finish_activation()
		return

/obj/structure/urbanism_generator/attack_hand(mob/user)
	if(!user)
		return

	if(active)
		to_chat(user, span_warning("Генератор уже активирован!"))
		return

	if(activating)
		to_chat(user, span_warning("Генератор уже запускается!"))
		return

	if(user.get_active_held_item())
		to_chat(user, span_warning("Вам нужны пустые руки для активации генератора."))
		return

	start_activation(user)

/obj/structure/urbanism_generator/proc/start_activation(mob/user)
	if(!src || !user)
		return

	activating = TRUE
	damage_taken = 0
	next_mob_spawn_time = world.time + mob_spawn_interval
	next_director_horde_time = world.time + mob_spawn_interval
	to_chat(user, span_notice("Вы начинаете активировать генератор..."))

	playsound(src, 'modular_bluemoon/sound/creatures/mesa/generator/generator_start.ogg', 50, TRUE)

	if(do_after(user, activation_time, target = src, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM | IGNORE_INCAPACITATED))
		if(!activating || QDELETED(src) || QDELETED(user))
			activating = FALSE
			return

		begin_active_phase()
	else
		activating = FALSE
		to_chat(user, span_warning("Активация прервана!"))

/obj/structure/urbanism_generator/proc/begin_active_phase()
	if(!src)
		return

	activating = FALSE
	active = TRUE
	activation_start_time = world.time
	damage_taken = 0
	next_mob_spawn_time = world.time + mob_spawn_interval

	visible_message(span_boldnotice("Генератор активирован!"))

	if(blastdoor_id)
		open_blastdoor()

	playsound(src, 'modular_bluemoon/sound/creatures/mesa/generator/generator_sputter.ogg', 50, TRUE)

/obj/structure/urbanism_generator/proc/finish_activation()
	if(!src)
		return

	active = FALSE
	icon_state = "generatorold"
	visible_message(span_boldnotice("Генератор завершил работу!"))

	if(reward_type)
		spawn_reward()

/obj/structure/urbanism_generator/proc/spawn_reward()
	if(!src || !reward_type)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	new reward_type(T)
	visible_message(span_notice("Из генератора выпал предмет!"))

/obj/structure/urbanism_generator/proc/open_blastdoor()
	if(!src || !blastdoor_id)
		return

	var/doors_opened = 0

	for(var/obj/machinery/door/poddoor/D in GLOB.machines)
		if(D && D.id == blastdoor_id)
			D.open()
			doors_opened++

	for(var/obj/machinery/door/window/brigdoor/W in GLOB.machines)
		if(W && W.id == blastdoor_id)
			W.open()
			doors_opened++

	for(var/obj/machinery/door/airlock/A in GLOB.airlocks)
		if(A && A.id_tag == blastdoor_id)
			A.open()
			doors_opened++

	log_world("open_blastdoor: blastdoor_id=[blastdoor_id], doors_opened=[doors_opened]")

	if(doors_opened > 0)
		visible_message(span_notice("Открыто [doors_opened] дверей с ID [blastdoor_id]!"))
	else
		visible_message(span_warning("Не удалось найти двери с ID [blastdoor_id]!"))

/obj/structure/urbanism_generator/proc/get_spawn_count_for_difficulty()
	if(!src)
		return 1

	var/max_count = max(1, max_mobs_per_wave)
	var/difficulty = 0
	var/datum/ai_director/zombie_mission/director = GLOB.zombie_director
	if(director)
		difficulty = director.difficulty_level

	switch(difficulty)
		if(0)
			return rand(1, min(2, max_count))
		if(1)
			return rand(1, min(3, max_count))
		if(2)
			return rand(2, min(4, max_count))
		if(3)
			return rand(2, min(5, max_count))
		if(4)
			return rand(3, min(6, max_count))
		if(5)
			return rand(3, min(7, max_count))
		else
			return rand(4, max_count)

/obj/structure/urbanism_generator/proc/spawn_mob_wave()
	if(!src)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	if(!mob_types || !mob_types.len)
		return

	var/mobs_to_spawn = get_spawn_count_for_difficulty()
	if(mobs_to_spawn < 1)
		mobs_to_spawn = 1

	for(var/i = 1; i <= mobs_to_spawn; i++)
		var/mob_type = pick(mob_types)
		if(!mob_type)
			continue

		var/turf/spawn_turf = null
		for(var/attempt = 1 to 10)
			var/turf/candidate = get_step(T, pick(GLOB.cardinals))
			if(!candidate)
				continue
			var/dist = get_dist(candidate, T)
			if(dist < spawn_radius)
				var/dir_to_move = get_dir(T, candidate)
				for(var/j = 1 to (spawn_radius - dist))
					candidate = get_step(candidate, dir_to_move)
					if(!candidate)
						break
			if(!candidate)
				continue
			if(candidate.density || candidate.is_blocked_turf())
				continue
			spawn_turf = candidate
			break
		if(!spawn_turf)
			continue

		var/mob/living/M = new mob_type(spawn_turf)
		if(!M)
			continue

		if(istype(M, /mob/living/simple_animal/hostile/infected) && GLOB.zombie_director)
			var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
			if(D && D.zombie_hp_multiplier > 1.0)
				M.maxHealth = round(M.maxHealth * D.zombie_hp_multiplier)
				M.health = M.maxHealth

		new /obj/effect/temp_visual/dir_setting/ninja/phase(spawn_turf)
		playsound(spawn_turf, 'sound/magic/Teleport_app.ogg', 50, TRUE)

	next_mob_spawn_time = world.time + mob_spawn_interval

/obj/structure/urbanism_generator/proc/spawn_zombie_horde()
	if(!src)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	var/list/horde_mob_types = mob_types
	if(!horde_mob_types || !horde_mob_types.len)
		horde_mob_types = list(
			/mob/living/simple_animal/hostile/infected,
			/mob/living/simple_animal/hostile/infected/bruiser
		)

	var/horde_size = get_spawn_count_for_difficulty() * 2
	if(horde_size < 3)
		horde_size = 3

	var/list/spawn_offsets = list()
	for(var/x = -7 to 7)
		for(var/y = -7 to 7)
			if(abs(x) <= 1 && abs(y) <= 1)
				continue
			var/dist = sqrt(x*x + y*y)
			if(dist >= 4 && dist <= 8)
				spawn_offsets += list(list(x, y))

	var/spawned_count = 0
	for(var/i = 1; i <= horde_size && i <= spawn_offsets.len; i++)
		var/list/offset = spawn_offsets[i]
		if(!offset || offset.len < 2)
			continue

		var/turf/spawn_turf = get_step(T, offset[1])
		if(!spawn_turf)
			continue
		spawn_turf = get_step(spawn_turf, offset[2])
		if(!spawn_turf)
			continue

		if(spawn_turf.density || spawn_turf.is_blocked_turf())
			continue

		var/mob_type = pick(horde_mob_types)
		if(!mob_type)
			continue

		var/mob/living/M = new mob_type(spawn_turf)
		if(!M)
			continue

		if(istype(M, /mob/living/simple_animal/hostile/infected) && GLOB.zombie_director)
			var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
			if(D && D.zombie_hp_multiplier > 1.0)
				M.maxHealth = round(M.maxHealth * D.zombie_hp_multiplier)
				M.health = M.maxHealth

		new /obj/effect/temp_visual/dir_setting/ninja/phase(spawn_turf)
		playsound(spawn_turf, 'sound/magic/Teleport_app.ogg', 50, TRUE)
		spawned_count++

	if(spawned_count > 0)
		visible_message(span_danger("Орда зомби появляется вокруг генератора!"))

/obj/structure/urbanism_generator/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	if(!src)
		return

	if(!active && !activating)
		return ..()

	damage_taken += damage_amount

	if(damage_taken >= damage_threshold)
		interrupt_activation()

	return ..()

/obj/structure/urbanism_generator/proc/interrupt_activation()
	if(!src)
		return

	active = FALSE
	activating = FALSE
	icon_state = "generatorold"
	damage_taken = 0

	visible_message(span_danger("Генератор был повреждён и остановлен!"))
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/generator/generator_sputter.ogg', 50, TRUE)


/obj/structure/urbanism_generator/reward
	name = "supply generator"
	desc = "A generator that dispenses supplies when activated."
	reward_type = /obj/item/storage/firstaid/regular
	spawn_mobs = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/infected,
		/mob/living/simple_animal/hostile/infected/bruiser
	)

/obj/structure/urbanism_generator/reward/weapon
	name = "weapon generator"
	reward_type = /obj/item/gun/ballistic/automatic/pistol/hl9mm

/obj/structure/urbanism_generator/reward/medical
	name = "medical generator"
	reward_type = /obj/item/storage/firstaid/regular


/obj/structure/urbanism_generator/button
	name = "door generator"
	desc = "A generator that opens a blastdoor when activated."
	blastdoor_id = "urbanism_door_1"
	reward_type = null
	spawn_mobs = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/infected,
		/mob/living/simple_animal/hostile/infected/bruiser
	)
	mob_spawn_interval = 10 SECONDS
	max_mobs_per_wave = 3

/obj/structure/urbanism_generator/button/alt
	name = "secondary door generator"
	blastdoor_id = "urbanism_door_2"
	spawn_mobs = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/infected,
		/mob/living/simple_animal/hostile/infected/bruiser
	)
	mob_spawn_interval = 10 SECONDS
	max_mobs_per_wave = 3

/obj/structure/urbanism_generator/button/safe
	name = "safe door generator"
	desc = "A generator that opens a blastdoor when activated, without spawning any mobs."
	blastdoor_id = "urbanism_door_1"
	reward_type = null
	spawn_mobs = FALSE
	mob_types = list()
	active_duration = 30 SECONDS

/obj/structure/urbanism_generator/continuous
	name = "hive generator"
	desc = "A generator that continuously spawns infected while active."
	reward_type = null
	spawn_mobs = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/infected,
		/mob/living/simple_animal/hostile/infected/bruiser
	)
	mob_spawn_interval = 10 SECONDS
	max_mobs_per_wave = 2
	active_duration = 120 SECONDS

/turf/closed/wall/r_wall/blackmesa
	name = "indestructible reinforced wall"
	desc = "An extremely reinforced wall that cannot be dismantled by any means."
	icon = 'icons/turf/walls/reinforced_wall.dmi'
	icon_state = "r_wall"
	smooth = SMOOTH_TRUE
	canSmoothWith = list(
		/turf/closed/wall,
		/turf/closed/wall/r_wall,
		/turf/closed/wall/r_wall/blackmesa,
		/turf/closed/wall/r_wall/rust,
		/turf/closed/wall/rust
	)
	var/resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF

/turf/closed/wall/r_wall/blackmesa/try_decon(obj/item/W, mob/user, turf/T)
	return FALSE

/turf/closed/wall/r_wall/blackmesa/try_destroy(obj/item/I, mob/user, turf/T)
	return FALSE

/turf/closed/wall/r_wall/blackmesa/dismantle_wall(devastated = 0, explode = 0)
	return

/turf/closed/wall/r_wall/blackmesa/attack_animal(mob/living/simple_animal/M)
	return


/datum/looping_sound/urbanism_flicker
	mid_sounds = list('modular_bluemoon/sound/ambience/mesa/lights_flicker.ogg' = 1)
	mid_length = 2 SECONDS
	volume = 25
	extra_range = -10
	falloff_exponent = 3
	falloff_distance = 1
	skip_starting_sounds = TRUE

/obj/machinery/light/urbanism_flicker
	name = "flickering light fixture"
	desc = "A malfunctioning light fixture that flickers chaotically."
	flickering = TRUE
	var/datum/looping_sound/urbanism_flicker/sound_loop
	var/flickering_active = FALSE

/obj/machinery/light/urbanism_flicker/Initialize(mapload)
	. = ..()
	sound_loop = new(src, TRUE)
	START_PROCESSING(SSmachines, src)

/obj/machinery/light/urbanism_flicker/Destroy()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(sound_loop)
	return ..()

/obj/machinery/light/urbanism_flicker/process()
	if(!src)
		return PROCESS_KILL
	if(status != LIGHT_OK)
		if(flickering_active)
			flickering_active = FALSE
		return
	if(!on)
		if(flickering_active)
			flickering_active = FALSE
		return
	if(!flickering_active)
		flickering_active = TRUE
		START_Flickering()

/obj/machinery/light/urbanism_flicker/proc/START_Flickering()
	set waitfor = 0
	if(!src)
		return
	while(src && status == LIGHT_OK && on)
		on = !on
		update(FALSE, TRUE)
		sleep(rand(1, 3))
		on = (status == LIGHT_OK)
		update(FALSE, TRUE)
		sleep(rand(1, 3))
	flickering_active = FALSE

/obj/machinery/light/urbanism_flicker/break_light_tube(skip_sound_and_sparks = 0)
	if(!src)
		return
	QDEL_NULL(sound_loop)
	return ..()

/obj/machinery/light/urbanism_flicker/burn_out()
	if(!src)
		return
	QDEL_NULL(sound_loop)
	return ..()

/obj/machinery/light/urbanism_flicker/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(status != LIGHT_OK)
		QDEL_NULL(sound_loop)

/obj/machinery/light/urbanism_flicker/tube
	name = "flickering tube light"
	base_state = "tube"
	fitting = "tube"
	brightness = 9
	icon_state = "tube"
	light_type = /obj/item/light/tube
	cone_angle = LIGHTING_WALL_TUBE_CONE_ANGLE

/obj/machinery/light/urbanism_flicker/small
	name = "flickering bulb light"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 5
	icon_state = "bulb"
	light_type = /obj/item/light/bulb
	cone_angle = LIGHTING_WALL_BULB_CONE_ANGLE


/obj/machinery/light/urbanism_flicker/silent
	name = "silent flickering light fixture"
	desc = "A malfunctioning light fixture that flickers chaotically without sound."

/obj/machinery/light/urbanism_flicker/silent/Initialize(mapload)
	. = ..()
	QDEL_NULL(sound_loop)

/obj/machinery/light/urbanism_flicker/silent/tube
	name = "silent flickering tube light"
	base_state = "tube"
	fitting = "tube"
	brightness = 9
	icon_state = "tube"
	light_type = /obj/item/light/tube
	cone_angle = LIGHTING_WALL_TUBE_CONE_ANGLE

/obj/machinery/light/urbanism_flicker/silent/small
	name = "silent flickering bulb light"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 5
	icon_state = "bulb"
	light_type = /obj/item/light/bulb
	cone_angle = LIGHTING_WALL_BULB_CONE_ANGLE

/turf/closed/wall/r_wall/blackmesa/attack_hulk(mob/living/carbon/human/H)
	return FALSE


/obj/structure/urbanismmachines/sign
	name = "road sign"
	desc = "Average road sign... Anyway! You have no car"
	icon = 'modular_bluemoon/icons/obj/urbanism/roadsign.dmi'
	icon_state = "roadsign1"


/obj/structure/urbanismmachines/xenplant
	name = "strange plant"
	layer = 5.4
	desc = "A mysterious plant growing in the urban landscape."
	icon = 'modular_bluemoon/icons/obj/urbanism/xensheet.dmi'
	icon_state = "xentree"

// =============================================================================
// TRUCK LANDMARKS
// Invisible landmarks for truck start and end positions
// =============================================================================

/obj/effect/landmark/truck_start
	name = "truck start position"
	icon_state = "x"
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/landmark/truck_end
	name = "truck end position"
	icon_state = "x"
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

// =============================================================================
// TRUCK GENERATOR
// Generator that activates truck movement
// =============================================================================

/obj/structure/urbanism_generator/truck
	name = "truck generator"
	desc = "A generator that powers the truck fueling system."
	var/obj/structure/urbanismcars/truck/linked_truck = null
	var/obj/effect/landmark/truck_start/start_landmark = null
	var/obj/effect/landmark/truck_end/end_landmark = null

/obj/structure/urbanism_generator/truck/Initialize(mapload)
	. = ..()
	find_landmarks()
	spawn_truck()

/obj/structure/urbanism_generator/truck/proc/find_landmarks()
	if(!src)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	for(var/obj/effect/landmark/truck_start/L in GLOB.landmarks_list)
		if(L && L.z == T.z)
			start_landmark = L
			break

	for(var/obj/effect/landmark/truck_end/L in GLOB.landmarks_list)
		if(L && L.z == T.z)
			end_landmark = L
			break

	if(!start_landmark)
		log_world("truck_generator: start_landmark not found")
	if(!end_landmark)
		log_world("truck_generator: end_landmark not found")

/obj/structure/urbanism_generator/truck/proc/spawn_truck()
	if(!src || !start_landmark)
		return

	var/turf/start_turf = get_turf(start_landmark)
	if(!start_turf)
		return

	linked_truck = new /obj/structure/urbanismcars/truck(start_turf)
	if(!linked_truck)
		log_world("truck_generator: failed to spawn truck")
		return

	linked_truck.anchored = TRUE
	linked_truck.density = TRUE

/obj/structure/urbanism_generator/truck/begin_active_phase()
	if(!src)
		return

	. = ..()

	if(linked_truck && end_landmark)
		var/turf/end_turf = get_turf(end_landmark)
		if(end_turf)
			linked_truck.charge_to_destination(end_turf)

// =============================================================================
// MOVABLE TRUCK
// Truck with charge movement system based on bubblegum
// =============================================================================

/obj/structure/urbanismcars/truck
	name = "truck"
	desc = "A heavy military truck."
	icon = 'modular_bluemoon/icons/obj/urbanism/vehicles140x140.dmi'
	icon_state = "car_wreck"
	anchored = TRUE
	density = TRUE
	var/charging = FALSE
	var/turf/target_turf = null

/obj/structure/urbanismcars/truck/proc/charge_to_destination(turf/destination)
	if(!src || !destination)
		return

	if(charging)
		return

	target_turf = destination
	var/turf/T = get_turf(src)
	if(!T || T == target_turf)
		return

	new /obj/effect/temp_visual/dragon_swoop(target_turf)
	charging = TRUE
	DestroySurroundings()
	setDir(get_dir(src, target_turf))
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc, src)
	if(D)
		animate(D, alpha = 0, color = "#FF0000", transform = matrix() * 2, time = 5)

	addtimer(CALLBACK(src, PROC_REF(start_charge), target_turf), 5)

/obj/structure/urbanismcars/truck/proc/start_charge(turf/destination)
	if(!src || !destination)
		charging = FALSE
		return

	throw_at(destination, get_dist(src, destination), 1, src, 0)

/obj/structure/urbanismcars/truck/Move()
	if(charging)
		playsound(src.loc, 'sound/effects/meteorimpact.ogg', 200, 1, 2, 1)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		DestroySurroundings()
	. = ..()
	if(charging)
		DestroySurroundings()

/obj/structure/urbanismcars/truck/Bump(atom/A)
	if(!src || !A)
		return ..()

	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			// Принудительно разрушаем объект
			A.ex_act(EXPLODE_HEAVY)
			// Если объект всё ещё существует, удаляем принудительно
			if(!QDELETED(A))
				qdel(A)
		DestroySurroundings()
	..()

/obj/structure/urbanismcars/truck/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!src)
		return

	if(!charging)
		return ..()

	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(!L)
			return

		L.visible_message("<span class='danger'>[src] slams into [L]!</span>", "<span class='userdanger'>[src] slams into you!</span>")
		L.apply_damage(55, BRUTE)
		playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 3)

	charging = FALSE
	anchored = TRUE
	density = TRUE
	visible_message(span_notice("The truck comes to a halt."))

/obj/structure/urbanismcars/truck/proc/DestroySurroundings()
	if(!src)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	for(var/dir in GLOB.cardinals)
		for(var/atom/movable/AM in get_step(T, dir))
			if(!AM || AM == src)
				continue
			if(isturf(AM))
				continue
			if(AM.density)
				// Принудительно разрушаем объект
				AM.ex_act(EXPLODE_HEAVY)
				// Если объект всё ещё существует, удаляем принудительно
				if(!QDELETED(AM))
					qdel(AM)
