// HellGate / PactDivest — OBJ-структуры (спрайты из sprites_HellGate)
// Иконки: icons/obj/hellgate/
// Имена состояний взяты из .dmi

/obj/structure/hellgate_vehicle
	name = "внедорожник 4x4"
	desc = "Колёсная техника. Пока просто декоративный объект."
	icon = 'icons/obj/hellgate/4x4.dmi'
	icon_state = "land_rover"
	anchored = TRUE
	density = TRUE

// dropship.dmi: nos, sad
/obj/structure/hellgate_dropship
	name = "дропшип"
	desc = "Транспортный летательный аппарат."
	icon = 'icons/obj/hellgate/dropship.dmi'
	icon_state = "nos"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_dropship/sad
	icon_state = "sad"

// campaign_big.dmi: mlrs, mlrs_broken, tank, tank_broken
/obj/structure/hellgate_campaign
	name = "кампанийский объект"
	desc = "Крупный объект для кампании/миссии."
	icon = 'icons/obj/hellgate/campaign_big.dmi'
	icon_state = "mlrs"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_campaign/tank
	name = "танк"
	desc = "Боевая машина."
	icon_state = "tank"

/obj/structure/hellgate_campaign/tank_broken
	name = "подбитый танк"
	icon_state = "tank_broken"

/obj/structure/hellgate_campaign/mlrs_broken
	name = "подбитая РСЗО"
	icon_state = "mlrs_broken"

// npc_beacon.dmi: beacon_undeployed, beacon_deployed_off, beacon_deployed_on, beacon_activating, beacon_emissive, beacon_deploying, fc_beacon_*
/obj/structure/hellgate_beacon
	name = "маяк НПС"
	desc = "Маяк. Будет активироваться и спавнить мобов."
	icon = 'icons/obj/hellgate/npc_beacon.dmi'
	icon_state = "beacon_undeployed"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_beacon/deployed
	icon_state = "beacon_deployed_off"

/obj/structure/hellgate_beacon/deployed_on
	icon_state = "beacon_deployed_on"

/obj/structure/hellgate_beacon/deployed_on/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/spawner, \
		list(/mob/living/simple_animal/hostile/syndicate/ranged), \
		300, \
		list(ROLE_SYNDICATE), \
		"warps in from", \
		5)

// train.dmi: nt, sat, hyperdyne, construction, crates, weapons, mech, empty, maglev
/obj/structure/hellgate_train
	name = "поезд"
	desc = "Состав. Пока просто декоративный объект."
	icon = 'icons/obj/hellgate/train.dmi'
	icon_state = "nt"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_train/sat
	icon_state = "sat"

/obj/structure/hellgate_train/hyperdyne
	icon_state = "hyperdyne"

/obj/structure/hellgate_train/construction
	icon_state = "construction"

/obj/structure/hellgate_train/crates
	icon_state = "crates"

/obj/structure/hellgate_train/weapons
	icon_state = "weapons"

/obj/structure/hellgate_train/mech
	icon_state = "mech"

/obj/structure/hellgate_train/empty
	icon_state = "empty"

/obj/structure/hellgate_train/maglev
	icon_state = "maglev"

// tram_rails.dmi: railend, rail_floor, anchor, anchor_bot, rail
/obj/structure/hellgate_tram_rails
	name = "трамвайные рельсы"
	desc = "Рельсы для трамвая."
	icon = 'icons/obj/hellgate/tram_rails.dmi'
	icon_state = "rail"
	anchored = TRUE
	density = FALSE

/obj/structure/hellgate_tram_rails/railend
	icon_state = "railend"

/obj/structure/hellgate_tram_rails/rail_floor
	icon_state = "rail_floor"

/obj/structure/hellgate_tram_rails/anchor
	icon_state = "anchor"

/obj/structure/hellgate_tram_rails/anchor_bot
	icon_state = "anchor_bot"

// 64x128.dmi: filtration_0, filtration_1
/obj/structure/hellgate_large
	name = "фильтрация"
	desc = "Оборудование фильтрации."
	icon = 'icons/obj/hellgate/64x128.dmi'
	icon_state = "filtration_0"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_large/filtration_1
	icon_state = "filtration_1"

// 64x96.dmi: filtration_machine_A_0, filtration_machine_A_1, filtration_machine_B_0, filtration_machine_B_1, sedementation_0, sedementation_1
/obj/structure/hellgate_large/wide
	name = "оборудование HellGate"
	desc = "Крупногабаритное оборудование."
	icon = 'icons/obj/hellgate/64x96.dmi'
	icon_state = "filtration_machine_A_0"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_large/wide/filtration_machine_A_1
	icon_state = "filtration_machine_A_1"

/obj/structure/hellgate_large/wide/filtration_machine_B_0
	icon_state = "filtration_machine_B_0"

/obj/structure/hellgate_large/wide/filtration_machine_B_1
	icon_state = "filtration_machine_B_1"

/obj/structure/hellgate_large/wide/sedementation_0
	icon_state = "sedementation_0"

/obj/structure/hellgate_large/wide/sedementation_1
	icon_state = "sedementation_1"

// fabs_64.dmi: orange, orange_trim, pink, pink_trim, blu, blu_trim, white, white_trim, red, red_trim
/obj/structure/hellgate_fabs
	name = "фабрикат"
	desc = "Производственный объект."
	icon = 'icons/obj/hellgate/fabs_64.dmi'
	icon_state = "orange"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_fabs/orange_trim
	icon_state = "orange_trim"

/obj/structure/hellgate_fabs/pink
	icon_state = "pink"

/obj/structure/hellgate_fabs/pink_trim
	icon_state = "pink_trim"

/obj/structure/hellgate_fabs/blu
	icon_state = "blu"

/obj/structure/hellgate_fabs/blu_trim
	icon_state = "blu_trim"

/obj/structure/hellgate_fabs/white
	icon_state = "white"

/obj/structure/hellgate_fabs/white_trim
	icon_state = "white_trim"

/obj/structure/hellgate_fabs/red
	icon_state = "red"

/obj/structure/hellgate_fabs/red_trim
	icon_state = "red_trim"

// factory.dmi: factory_conveyer, factory_roboticarm, factory_
/obj/structure/hellgate_factory
	name = "завод"
	desc = "Промышленное здание."
	icon = 'icons/obj/hellgate/factory.dmi'
	icon_state = "factory_conveyer"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_factory/roboticarm
	icon_state = "factory_roboticarm"

/obj/structure/hellgate_factory/base
	icon_state = "factory_"

// power_transformer.dmi: transformer
/obj/structure/hellgate_power_transformer
	name = "силовой трансформатор"
	desc = "Электрооборудование."
	icon = 'icons/obj/hellgate/power_transformer.dmi'
	icon_state = "transformer"
	anchored = TRUE
	density = TRUE
