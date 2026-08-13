GLOBAL_LIST_INIT(possible_squad_leader_first_names, list(\
"Кощей","Башня","Патриарх", "Чернобог","Душегуб","Басурман","Мародёр","Апостол","Дипломат","Голиаф","Миллениум",\
"Гадюка","Носорог","Кабан","Орёл","Слон","Крокодил","Бегемот","Журавль","Тигр","Лев","Анаконда","Волк","Гиена","Шакал","Цербер"))

// Трекер на командира

/obj/item/pinpointer/squad
	name = "squad tracker"
	desc = "A handheld tracking device that locates the leader. <b>SQUAD, ON ME!</b>"
	icon_state = "pinpointer_syndicate"
	item_state = "pinpointer_black"
	var/leader = null

/obj/item/pinpointer/squad/Destroy()
	leader = null
	. = ..()

/obj/item/pinpointer/squad/examine(mob/user)
	. = ..()
	if(leader)
		var/obj/item/squad_leader_tracker/leader_beacon = leader
		if(leader_beacon.tracking_name)
			. += "<hr>"
			. += span_info("Вы - часть отряда <b>\"[leader_beacon.tracking_name]\"</b>.")
	. += span_info("Трекер можно поднести к маячку лидера, чтобы присоединиться к его отряду.")

/obj/item/pinpointer/squad/scan_for_target()
	set_target(leader)

// Командирский маячок

/obj/item/squad_leader_tracker
	name = "squad beacon"
	desc = "Устройство с функционалом маячка. Излучает сигнал, улавливаемый определёнными пинпоинтерами. \
	Такая модель часто используется в военных и полу-военных подразделениях для поиска командира отряда - её они и носят. \
	Как правило, к ней прикреплены только те маячки, что идут в комплекте. Позволяет усилить организацию над приматами и детьми до 8 лет."
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-white"
	item_state = "radio"
	var/tracking_name = ""

/obj/item/squad_leader_tracker/Initialize(mapload)
	. = ..()
	if(length(GLOB.possible_squad_leader_first_names))
		tracking_name = pick(GLOB.possible_squad_leader_first_names)
		GLOB.possible_squad_leader_first_names -= tracking_name
	else
		tracking_name = "[rand(1,999)]"

/obj/item/squad_leader_tracker/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(istype(I, /obj/item/pinpointer/squad)) // По клику на маячок трекером, можно привязаться к отряду
		var/obj/item/pinpointer/squad/tracker = I
		if(tracker.leader == src)
			to_chat(user, span_danger("Этот пинпоинтер уже привязан к данному отряду."))
			return
		tracker.leader = src
		playsound(src, 'sound/items/timer.ogg', 50, 1, -5)
		to_chat(user, span_notice("Вы переназначаете отряд на \"[tracking_name]\". Теперь, это ваш отряд."))
		return
	. = ..()

/obj/item/squad_leader_tracker/examine(mob/user)
	. = ..()
	if(tracking_name)
		. += "<hr>"
		. += span_info("Этот маяк относится к отряду <b>\"[tracking_name]\"</b>.")

// Коробочка с полным набором

/obj/item/storage/box/pinpointer_squad/PopulateContents()
	var/obj/item/pinpointer/squad/A = new(src)
	var/obj/item/pinpointer/squad/B = new(src)
	var/obj/item/pinpointer/squad/C = new(src)
	var/obj/item/pinpointer/squad/D = new(src)
	var/obj/item/pinpointer/squad/E = new(src)
	var/obj/item/pinpointer/squad/F = new(src)
	var/obj/item/squad_leader_tracker/master = new(src)

	A.leader = master
	B.leader = master
	C.leader = master
	D.leader = master
	E.leader = master
	F.leader = master

// Добавление обоих предметов в техфабы с начала смены

/datum/design/squad_beacon
	name = "Squad Beacon"
	id = "squad_beacon"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1500, /datum/material/gold = 200)
	build_path = /obj/item/squad_leader_tracker
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/squad_tracker
	name = "Squad Tracker"
	desc = "A handheld tracking device that locates the leader. <b>SQUAD, ON ME!</b>"
	id = "squad_tracker"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1500, /datum/material/gold = 200)
	build_path = /obj/item/pinpointer/squad
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/techweb_node/base/New()
	var/list/extra_designs = list(
		"squad_beacon",
		"squad_tracker"
	)
	LAZYADD(design_ids, extra_designs)
	. = ..()
