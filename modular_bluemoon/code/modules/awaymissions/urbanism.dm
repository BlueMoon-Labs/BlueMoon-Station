/turf/closed/mineral/mesarock
	name = "rock"
	icon = 'icons/turf/mining.dmi'
	smooth_icon = 'icons/turf/walls/rock_wall.dmi'
	icon_state = "rockyash"
	smooth = SMOOTH_MORE|SMOOTH_BORDER
	canSmoothWith = list (/turf/closed)

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

/obj/structure/deadmesa/hecughost
	name = "Призрак лидера отряда HECU"
	desc = "Он точно потерялся... И он точно перепутал гейт Blackmesa с ihategordon. Появится ли blackmesa и тут? Что значит призрак этого парня? Зачем вы читаете его описание?"
	icon_state = "Hecughost"
