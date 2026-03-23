/datum/design/board/spacepod_main
	name = "Спейспод - Основной контролер"
	desc = "Содержит основные компоненты управления Спейсподом."
	id = "spacepod_main"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/circuitboard/mecha/pod
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pod_core
	name = "Ядро Спейспода"
	desc = "Содержит ионный двигатель и системы поддержания жизнедеятельности."
	id = "podcore"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=5000, /datum/material/uranium=1000, /datum/material/plasma=5000)
	build_path = /obj/item/pod_parts/core
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pod_armor_civ
	name = "Броня Спейспода - Гражданская"
	desc = "Внешняя герметичная, защитная обшивка. Гражданский образец."
	id = "podarmor_civ"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=15000,/datum/material/glass=5000,/datum/material/plasma=10000)
	build_path = /obj/item/pod_parts/armor
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pod_armor_black
	name = "Броня Спейспода - Темная"
	desc = "Внешняя герметичная, защитная обшивка. Гражданский образец."
	id = "podarmor_dark"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/pod_parts/armor/black
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=15000,/datum/material/glass=5000,/datum/material/plasma=10000)
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pod_armor_industrial
	name = "Броня Спейспода - Промышленная"
	desc = "Внешняя герметичная, защитная обшивка. Промышленный образец."
	id = "podarmor_industiral"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/pod_parts/armor/industrial
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=15000,/datum/material/glass=5000,/datum/material/plasma=10000,/datum/material/diamond=5000,/datum/material/silver=7500)
	departmental_flags = DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/pod_armor_sec
	name = "Броня Спейспода - СБ"
	desc = "Внешняя герметичная, защитная обшивка. Служебный образец."
	id = "podarmor_sec"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/pod_parts/armor/security
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=15000,/datum/material/glass=5000,/datum/material/plasma=10000,/datum/material/diamond=5000,/datum/material/silver=7500)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/pod_armor_gold
	name = "Броня Спейспода - Золото"
	desc = "Внешняя герметичная, защитная обшивка. Престижный образец."
	id = "podarmor_gold"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/pod_parts/armor/gold
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=5000,/datum/material/glass=2500,/datum/material/plasma=7500,/datum/material/gold=10000)
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

//////////////////////////////////////////
//////SPACEPOD GUNS///////////////////////
//////////////////////////////////////////

/datum/design/pod_gun_disabler
	name = "Усмиритель Спейспода"
	desc = "Стреляет маломощными лазерами которые изматывают цель, не нанося ей вреда."
	id = "podgun_disabler"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/spacepod_equipment/weaponry/disabler
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron = 15000)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/pod_gun_bdisabler
	name = "Модернезированный усмиритель Спейспода"
	desc = "Стреляет очередью маломощных лазеров которые изматывают цель, не нанося ей вреда."
	id = "podgun_bdisabler"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/spacepod_equipment/weaponry/burst_disabler
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron = 15000,/datum/material/plasma=2000)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/pod_gun_laser
	name = "Лазер Спейспода"
	desc = "Ведет огонь лазером средней мощности."
	id = "podgun_laser"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/spacepod_equipment/weaponry/laser
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=10000,/datum/material/glass=5000,/datum/material/gold=1000,/datum/material/silver=2000)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/pod_gun_laser_heavylaser
	name = "Модернезированный лазер Спейспода"
	desc = "Ведет огонь лазером высокой мощности."
	id = "podgun_laser_heavylaser"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/spacepod_equipment/weaponry/laser_heavylaser
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron=10000,/datum/material/glass=5000,/datum/material/gold=4000,/datum/material/silver=4000, /datum/material/diamond = 4000)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
/datum/design/pod_ka_basic
	name = "Кинетический акселератор Спейспода"
	desc = "Ведет огонь слабыми импульсами кинетической энергии."
	id = "pod_ka_basic"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000, /datum/material/silver = 2000, /datum/material/uranium = 2000)
	build_path = /obj/item/spacepod_equipment/weaponry/basic_pod_ka
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/pod_ka
	name = "Модернезированный кинетический акселератор Спейспода"
	desc = "Ведет огонь мощными импульсами кинетической энергии. Продвинутая версия обладает повышенной скорострельностью и более экономичным энергопотреблением."
	id = "pod_ka"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000, /datum/material/silver = 2000, /datum/material/gold = 2000, /datum/material/diamond = 2000)
	build_path = /obj/item/spacepod_equipment/weaponry/pod_ka
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO


/datum/design/pod_plasma_cutter
	name = "Плазменный резак Спейспода"
	desc = "Ведет огонь концентрированными сгустками плазмы, используется при добыче полезных ископаемых на астероидах."
	id = "pod_plasma_cutter"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000, /datum/material/silver = 2000, /datum/material/gold = 2000, /datum/material/diamond = 2000)
	build_path = /obj/item/spacepod_equipment/weaponry/plasma_cutter
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/pod_adv_plasma_cutter
	name = "Продвинутый плазменный резак Спейспода"
	desc = "Ведет огонь концентрированными сгустками плазмы, используется при добыче полезных ископаемых на астероидах. Продвинутая версия обладает повышенной скорострельностью и более экономичным энергопотреблением."
	id = "pod_adv_plasma_cutter"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000, /datum/material/silver = 4000, /datum/material/gold = 4000, /datum/material/diamond = 4000)
	build_path = /obj/item/spacepod_equipment/weaponry/plasma_cutter/adv
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

//////////////////////////////////////////
//////SPACEPOD MISC. ITEMS////////////////
//////////////////////////////////////////

/datum/design/pod_misc_tracker
	name = "Маяк Спейспода"
	desc = "Следящее устройство для поиска корабля в бескрайнем космосе."
	id = "podmisc_tracker"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=5000)
	build_path = /obj/item/spacepod_equipment/tracker
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

//////////////////////////////////////////
//////SPACEPOD CARGO ITEMS////////////////
//////////////////////////////////////////

/datum/design/pod_cargo_ore
	name = "Рудный танк Спейспода"
	desc = "Система хранения руды для Спейсподов. Автоматически собирает ближайшую руду, рядом с кораблем. Для работы необходимо загрузить ящик для руды."
	id = "podcargo_ore"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=20000, /datum/material/glass=2000)
	build_path = /obj/item/spacepod_equipment/cargo/large/ore
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/pod_cargo_crate
	name = "Трюм Спейспода"
	desc = "Небольшой отсек вмещающий один стандартный грузовой ящик. Ящик в комплект не входит."
	id = "podcargo_crate"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=25000)
	build_path = /obj/item/spacepod_equipment/cargo/large
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

//////////////////////////////////////////
//////SPACEPOD SEC CARGO ITEMS////////////
//////////////////////////////////////////

/datum/design/passenger_seat
	name = "Пассажирское кресло Спейспода"
	desc = "Второе посадочное место для перевозки пасажиров."
	id = "podcargo_seat"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=7500, /datum/material/glass=2500)
	build_path = /obj/item/spacepod_equipment/cargo/chair
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

//////////////////////////////////////////
//////SPACEPOD LOCK ITEMS////////////////
//////////////////////////////////////////
/datum/design/pod_lock_keyed
	name = "Центральный замок Спейспода"
	desc = "Блокирует двери, полезно для защиты имущества. После изготовления необходимо синхронизировать с ключом."
	id = "podlock_keyed"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=4500)
	build_path = /obj/item/spacepod_equipment/lock/keyed
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pod_key
	name = "Ключ от Спейспода"
	desc = "Ключ от центрального замка Спейспода. После изготовления необходимо синхронизировать с замком."
	id = "podkey"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron=500)
	build_path = /obj/item/spacepod_key
	category = list("Shuttle Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/lockbuster
	name = "Взломщик центрального замка Спейспода"
	desc = "Уничтожает замок и разблокирует Спейспод. Внимание: после использования гарантия обнуляется."
	id = "pod_lockbuster"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	build_path = /obj/item/device/lock_buster
	category = list("Shuttle Machinery")
	materials = list(/datum/material/iron = 15000, /datum/material/diamond=2500) //it IS a drill!
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
