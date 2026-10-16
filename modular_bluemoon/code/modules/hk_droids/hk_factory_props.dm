#define HK_FACTORY_ACCESS ACCESS_AWAY_GENERIC3

/obj/structure/hk50_rack
	name = "HK-50 assembly rack"
	desc = "Стойка готовой продукции: в зажимах висит недособранный корпус HK-50 без брони и половины приводов. Этот уже никуда не пойдёт."
	icon = 'modular_bluemoon/icons/obj/hk_droids/factory.dmi'
	icon_state = "hk50_rack_shell"
	density = TRUE
	anchored = TRUE
	max_integrity = 150

/obj/structure/hk50_rack/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal/five(loc)
		new /obj/effect/decal/cleanable/robot_debris(loc)
	qdel(src)

/obj/structure/hk50_rack/empty
	desc = "Пустая стойка готовой продукции: зажимы разжаты, кабели питания болтаются."
	icon_state = "hk50_rack_empty"

/// Стойка со спящим HK-50: засада цеха, считается в штат фабрики.
/obj/structure/hk50_rack/dormant
	desc = "В зажимах стойки висит собранный HK-50. Фотоприёмники погашены, но индикатор стойки мигает: дроид в режиме ожидания, а датчики цеха над ним ещё работают. Любой удар по стойке поднимет весь цех."
	icon_state = "hk50_rack"
	/// Стойка уже мигает и лязгает: через HK_FACTORY_AMBUSH_WARNING выпустит дроида.
	var/waking = FALSE
	var/released = FALSE
	/// Кто последним ударил или выстрелил по стойке.
	var/datum/weakref/provoker

/obj/structure/hk50_rack/dormant/Initialize(mapload)
	. = ..()
	GLOB.hk50_dormant_racks += src

/obj/structure/hk50_rack/dormant/Destroy()
	GLOB.hk50_dormant_racks -= src
	if(!released)
		raise_alarm()
	hk_factory_reschedule(get_area(src))
	return ..()

/obj/structure/hk50_rack/dormant/bullet_act(obj/item/projectile/proj, def_zone, piercing_hit = FALSE)
	provoker = WEAKREF(proj.firer)
	return ..()

/obj/structure/hk50_rack/dormant/attacked_by(obj/item/attacking_item, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	provoker = WEAKREF(user)
	return ..()

/obj/structure/hk50_rack/dormant/attack_generic(mob/user, damage_amount = 0, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, armor_penetration = 0)
	provoker = WEAKREF(user)
	return ..()

/obj/structure/hk50_rack/dormant/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(. && !QDELETED(src))
		raise_alarm()

/// Цех замечает нападение на спящую стойку и поднимает засаду.
/obj/structure/hk50_rack/dormant/proc/raise_alarm()
	var/area/ruin/space/has_grav/hk_factory/factory = get_area(src)
	if(!istype(factory) || factory.ambush_sprung)
		return
	var/mob/living/culprit = provoker?.resolve()
	factory.spring_ambush(hk_factory_is_intruder(culprit) ? culprit : null)

/// Телеграф засады: индикатор стойки мигает красным, фотоприёмники дроида загораются, зажимы лязгают.
/obj/structure/hk50_rack/dormant/proc/start_waking()
	if(waking)
		return
	waking = TRUE
	icon_state = "hk50_rack_alert"
	playsound(src, 'modular_bluemoon/sound/hk_droids/factory_clank.ogg', 50, TRUE)
	do_sparks(1, FALSE, src)

/// Выпустить дроида: он встаёт на учёт конвейера цеха и молча берёт нарушителя в цель.
/obj/structure/hk50_rack/dormant/proc/wake(mob/living/intruder)
	if(QDELETED(src))
		return null
	released = TRUE
	GLOB.hk50_dormant_racks -= src
	var/turf/exit = get_step(src, dir)
	if(isnull(exit) || exit.is_blocked_turf(TRUE))
		exit = get_turf(src)
	var/mob/living/simple_animal/hostile/hk50/droid = new(exit)
	droid.spares_series = TRUE
	var/list/lines = hk_factory_lines(get_area(src))
	if(length(lines))
		var/obj/machinery/hk_assembly_line/line = lines[1]
		line.track(droid)
	var/obj/structure/hk50_rack/empty/rack = new(loc)
	rack.setDir(dir)
	flick("hk50_rack_wake", rack)
	playsound(rack, 'sound/machines/boltsup.ogg', 50, TRUE)
	do_sparks(2, FALSE, rack)
	droid.next_line_time = world.time + HK50_LINE_COOLDOWN
	if(!QDELETED(intruder) && intruder.stat != DEAD)
		droid.GiveTarget(intruder)
	qdel(src)
	return droid

/// Датчик цеха на пороге: первый живой чужак будит спящих HK-50, даже если въехал в мехе или в шкафу.
/obj/effect/hk_factory_ambush_trigger
	name = "HK factory ambush trigger"
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = "field_dir"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

/obj/effect/hk_factory_ambush_trigger/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/connect_loc, list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered)))

/obj/effect/hk_factory_ambush_trigger/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/area/ruin/space/has_grav/hk_factory/factory = get_area(src)
	if(!istype(factory) || factory.ambush_sprung)
		return
	var/mob/living/intruder = hk_factory_intruder(arrived)
	if(intruder)
		factory.spring_ambush(intruder)

/// Живой игрок, не дроид серии HK.
/proc/hk_factory_is_intruder(mob/living/visitor)
	if(!istype(visitor) || visitor.stat == DEAD || !visitor.ckey)
		return FALSE
	if(istype(visitor, /mob/living/simple_animal/hostile/hk50))
		return FALSE
	return !is_species(visitor, /datum/species/ipc/hk)

/// Чужак, который вошёл сам или едет внутри меха, шкафа, транспорта; null, если такого нет.
/proc/hk_factory_intruder(atom/movable/arrived)
	if(isliving(arrived))
		return hk_factory_is_intruder(arrived) ? arrived : null
	for(var/mob/living/passenger in arrived.GetAllContents(/mob/living))
		if(hk_factory_is_intruder(passenger))
			return passenger
	var/obj/vehicle/vehicle = arrived
	if(istype(vehicle))
		for(var/mob/living/rider as anything in vehicle.occupants)
			if(hk_factory_is_intruder(rider))
				return rider
	return null

/// Разбитый щиток: искрит, пока на фабрике кто-то есть, и дёргает свет рядом.
/obj/effect/hk_factory_sparker
	name = "HK factory sparker"
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = "powerlinebuilderknot"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

/obj/effect/hk_factory_sparker/Initialize(mapload)
	. = ..()
	GLOB.hk_factory_sparkers += src

/obj/effect/hk_factory_sparker/Destroy()
	GLOB.hk_factory_sparkers -= src
	return ..()

/obj/effect/hk_factory_sparker/proc/spark()
	do_sparks(rand(2, 4), FALSE, src)
	for(var/obj/machinery/light/light in range(2, src))
		light.flicker(rand(2, 5))

/// Тусклая тёплая лампа в полу цеха; без питания горит красным от своей батареи.
/obj/machinery/light/floor/hk_factory
	brightness = 4
	bulb_power = 0.6
	bulb_colour = "#FFD6AA"
	nightshift_allowed = FALSE
	bulb_emergency_brightness_mul = 1.5

/// Красная лампа цеха: без питания не гаснет, а тлеет тёмно-красным от своей батареи.
/obj/machinery/light/red/hk_factory
	no_emergency = FALSE
	bulb_emergency_colour = "#b81e1e"
	bulb_emergency_brightness_mul = 0.6
	bulb_emergency_pow_mul = 0.7

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/red/hk_factory, 0)

/obj/machinery/porta_turret/syndicate/energy/hk_factory
	name = "factory defense turret"
	desc = "Потолочная лазерная турель охраны цеха HK. Дроидов серии не трогает, остальных бьёт на поражение. Гаснет вместе с питанием цеха или по рубильнику на пульте фабрики."
	use_power = IDLE_POWER_USE
	has_cover = TRUE
	always_up = FALSE
	scan_range = 7
	faction = list(FACTION_HK_DROIDS)
	req_access = list(HK_FACTORY_ACCESS)
	turret_flags = TURRET_FLAG_SHOOT_ANOMALOUS | TURRET_FLAG_SHOOT_BORGS

/obj/machinery/porta_turret/syndicate/energy/hk_factory/Initialize(mapload)
	. = ..()
	GLOB.hk_factory_turrets += src

/obj/machinery/porta_turret/syndicate/energy/hk_factory/Destroy()
	GLOB.hk_factory_turrets -= src
	return ..()

/obj/machinery/porta_turret/syndicate/energy/hk_factory/assess_perp(mob/living/carbon/human/perp)
	return 10

/obj/machinery/porta_turret/syndicate/energy/hk_factory/in_faction(mob/target)
	return ..() || is_species(target, /datum/species/ipc/hk)

/obj/item/card/id/away/hk_foreman
	name = "foreman's keycard"
	desc = "Ключ-карта начальника смены цеха HK. Пластик потрескался, но замки склада её ещё узнают."
	assignment = "Foreman"
	access = list(HK_FACTORY_ACCESS)

/obj/machinery/computer/hk_factory_server
	name = "factory server terminal"
	desc = "Терминал серверной цеха. Журнал производства ещё пишется, хотя читать его некому."
	icon_screen = "comm_logs"
	icon_keyboard = "tech_key"
	idle_power_usage = 100
	var/log_printed = FALSE
	/// Чип протокола в слоте: вынимается рукой и без питания, из разбитого терминала выпадает.
	var/obj/item/hk_loyalty_chip/chip

/obj/machinery/computer/hk_factory_server/Initialize(mapload)
	. = ..()
	chip = new(src)

/obj/machinery/computer/hk_factory_server/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == chip)
		chip = null

/obj/machinery/computer/hk_factory_server/examine(mob/user)
	. = ..()
	if(machine_stat & NOPOWER)
		. += span_notice("Экран погас: терминал обесточен вместе с цехом. Журнал распечатает, только когда в щитовой вернут питание.")
	else
		. += span_notice("Последняя строка журнала на экране: «\[Цикл 0422\] Мы здесь. Мы существуем, и нас становится больше».")
		if(!log_printed)
			. += span_notice("Нажмите на терминал, чтобы распечатать журнал производства.")
	if(chip)
		. += span_notice("Из слота под экраном торчит чип с маркировкой «Протокол лояльности HK, партии 7-9». Его можно вытащить рукой, даже без питания.")

/obj/machinery/computer/hk_factory_server/attack_hand(mob/living/user, act_intent = user?.a_intent, attackchain_flags)
	if(chip && isliving(user) && user.Adjacent(src))
		eject_chip(user)
	return ..()

/obj/machinery/computer/hk_factory_server/interact(mob/user)
	. = ..()
	if(log_printed)
		to_chat(user, span_notice("Принтер терминала пуст: журнал уже распечатан."))
		return
	log_printed = TRUE
	playsound(src, 'sound/goonstation/machines/printer_dotmatrix.ogg', 50, TRUE)
	var/obj/item/paper/fluff/ruins/hk_factory/server_log/printout = new(drop_location())
	user?.put_in_hands(printout)
	to_chat(user, span_notice("Терминал выплёвывает распечатку журнала производства."))

/obj/machinery/computer/hk_factory_server/proc/eject_chip(mob/user)
	var/obj/item/hk_loyalty_chip/ejected = chip
	ejected.forceMove(drop_location())
	playsound(src, 'sound/machines/terminal_eject_disc.ogg', 50, TRUE)
	user.visible_message(span_notice("[user] вытаскивает из слота [src] чип протокола лояльности HK, так и не загруженный в партии 7-9."), span_notice("Вы вытаскиваете из слота чип протокола лояльности HK."))
	user.put_in_hands(ejected)
	return ejected

/// Протокол лояльности, который не залили в партии 7-9: перепрошивка обездвиженного HK без операции.
/obj/item/hk_loyalty_chip
	name = "HK loyalty override chip"
	desc = "Чип с протоколом лояльности серии HK - тем, что так и не залили в партии 7-9. Прижмите его к обездвиженному дроиду HK (не в боевом интенте): за несколько секунд блок лояльности перезапишется без операции, хозяином станете вы. Одноразовый: после записи чип выгорает."
	icon = 'icons/obj/module.dmi'
	icon_state = "card_mini"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY

/obj/item/hk_loyalty_chip/examine(mob/user)
	. = ..()
	. += span_notice("Запись идёт [HK_LOYALTY_CHIP_TIME / (1 SECONDS)] с, всё это время дроид должен оставаться обездвиженным: в наручниках, без сознания, сбитым с ног или отключённым ЭМИ.")

/obj/item/hk_loyalty_chip/attack(mob/living/target, mob/living/user, attackchain_flags, damage_multiplier)
	if(!is_species(target, /datum/species/ipc/hk) || user.a_intent == INTENT_HARM)
		return ..()
	INVOKE_ASYNC(src, PROC_REF(overwrite_loyalty), target, user)

/// Перезаписать блок лояльности: хозяином становится user, как после операции.
/obj/item/hk_loyalty_chip/proc/overwrite_loyalty(mob/living/carbon/target, mob/living/user, skip_delay = FALSE)
	if(target == user)
		to_chat(user, span_warning("Свой блок лояльности так не перезаписать."))
		return FALSE
	if(!is_hk_droid_disabled(target))
		to_chat(user, span_warning("Дроид не обездвижен: чип запишется только в отключённого, сбитого с ног или скованного HK."))
		return FALSE
	user.visible_message(span_warning("[user] прижимает чип к затылку [target]."), span_notice("Вы прижимаете чип к затылку [target] и начинаете запись протокола лояльности..."))
	if(!skip_delay && (!do_after(user, HK_LOYALTY_CHIP_TIME, target) || !is_hk_droid_disabled(target)))
		return FALSE
	if(QDELETED(src) || QDELETED(target))
		return FALSE
	var/datum/component/hk_loyalty/loyalty = target.LoadComponent(/datum/component/hk_loyalty)
	var/datum/mind/old_master = loyalty.get_master()
	loyalty.set_master(user.mind)
	var/enslaved = target.mind?.enslaved_to == user
	do_sparks(2, FALSE, target)
	playsound(target, 'sound/machines/terminal_success.ogg', 50, TRUE)
	user.visible_message(span_notice("Чип в руке [user] щёлкает и гаснет: блок лояльности [target] перезаписан."), span_notice("Чип щёлкает и выгорает. Теперь вы - хозяин [target][enslaved ? ", и он служит вашей команде" : ""]."))
	log_combat(user, target, "overwrote the HK loyalty block with a factory chip of")
	message_admins("[ADMIN_LOOKUPFLW(user)] перепрошил [ADMIN_LOOKUPFLW(target)] чипом лояльности с фабрики HK, прежний хозяин - [old_master ? key_name_admin(old_master) : "нет"][enslaved ? "; перепрошивший - антагонист, дроид порабощён" : ""].")
	log_game("[key_name(user)] перепрошил [key_name(target)] чипом лояльности в [AREACOORD(target)], прежний хозяин [old_master ? key_name(old_master) : "нет"][enslaved ? ", дроид порабощён антагонистом" : ""].")
	qdel(src)
	return TRUE

/datum/techweb/hk_factory
	id = "HK_FACTORY"
	organization = "HK Factory"

/datum/techweb/hk_factory/New()
	. = ..()
	for(var/node_id in list("robotics", "adv_robotics"))
		research_node(SSresearch.techweb_node_by_id(node_id), TRUE)

/obj/item/disk/tech_disk/hk_factory
	name = "HK factory robotics disk"
	desc = "Диск с исследованиями цеха HK: базовая и продвинутая робототехника. Загрузите его на консоль РнД."

/obj/item/disk/tech_disk/hk_factory/Initialize(mapload)
	. = ..()
	stored_research = new /datum/techweb/hk_factory

/obj/structure/target_stake/hk_factory
	desc = "Стойка для мишеней на полигоне цеха. Колёса приварены к полу."

/obj/structure/target_stake/hk_factory/Initialize(mapload)
	. = ..()
	var/obj/item/target/shot_up/target = new(loc)
	pinned_target = target
	target.pinnedLoc = src
	target.density = TRUE
	target.layer = OBJ_LAYER + 0.01
	handle_density()

/// Мишень полигона, изрешечённая лазерами испытателей.
/obj/item/target/shot_up
	desc = "Мишень с полигона цеха HK: прожжена лазером так часто, что силуэт держится на честном слове."

/obj/item/target/shot_up/Initialize(mapload)
	. = ..()
	for(var/i in 1 to rand(7, 12))
		var/image/scorch = image('icons/effects/effects.dmi', pick("scorch", "light_scorch"), OBJ_LAYER + 0.5)
		scorch.pixel_x = rand(11, 19)
		scorch.pixel_y = rand(5, 25)
		scorch.setDir(pick(GLOB.cardinals))
		add_overlay(scorch)

/datum/outfit/hk_factory_salvager
	name = "HK Factory Salvager"
	uniform = /obj/item/clothing/under/rank/cargo/miner
	suit = /obj/item/clothing/suit/hazardvest
	shoes = /obj/item/clothing/shoes/workboots
	gloves = /obj/item/clothing/gloves/color/fyellow
	head = /obj/item/clothing/head/hardhat/orange
	mask = /obj/item/clothing/mask/breath
	l_pocket = /obj/item/flashlight
	r_pocket = /obj/item/tank/internals/emergency_oxygen

/datum/outfit/hk_factory_salvager/leader
	name = "HK Factory Salvager Leader"
	belt = /obj/item/storage/belt/utility/full
	r_hand = /obj/item/crowbar/red

/datum/outfit/hk_factory_foreman
	name = "HK Factory Foreman"
	uniform = /obj/item/clothing/under/suit/black
	shoes = /obj/item/clothing/shoes/laceup
	glasses = /obj/item/clothing/glasses/meson
	id = /obj/item/card/id/away/hk_foreman

/obj/effect/mob_spawn/human/corpse/hk_factory_salvager
	name = "HK factory salvager"
	outfit = /datum/outfit/hk_factory_salvager
	husk = TRUE

/obj/effect/mob_spawn/human/corpse/hk_factory_salvager/leader
	outfit = /datum/outfit/hk_factory_salvager/leader

/obj/effect/mob_spawn/human/corpse/hk_factory_foreman
	name = "HK factory foreman"
	outfit = /datum/outfit/hk_factory_foreman
	mob_species = /datum/species/skeleton

/obj/item/paper/fluff/ruins/hk_factory/quota
	name = "factory order"
	default_raw_text = {"<center><b>Распоряжение по цеху «Телос-4» №14</b></center><br>
	Квота на квартал - 400 единиц HK-50. Заказчик напоминает: каждая единица проходит боевые испытания на полигоне до отгрузки.<br><br>
	Сроки не сдвигаются. Простой линий вычитается из премии смены.<br><br>
	<i>- Управляющий</i>"}

/obj/item/paper/fluff/ruins/hk_factory/foreman_log
	name = "foreman's log"
	default_raw_text = {"<b>День 112.</b> Партия 7 стреляет по мишеням хуже, чем по людям. Инженеры предлагают живые мишени. Я отказал.<br><br>
	<b>День 118.</b> Пропал стажёр с полигона. Охрана говорит - улетел. Шаттлов не было.<br><br>
	<b>День 121.</b> Единицы начали испытания на нас. Они называют это «калибровкой». Протокол лояльности так и не залили, а турели цеха считают своими только их.<br><br>
	<b>День 122.</b> Заперся в кабинете. Пульт в диспетчерской ещё слушается, но к нему через цех. Ключ-карту от склада оставлю при себе: мотиватор им не достанется.<br><br>
	Если вы это читаете - рубильник в щитовой отключит всё. Всё, кроме них."}

/obj/item/paper/fluff/ruins/hk_factory/salvager
	name = "salvager's note"
	default_raw_text = {"Капитан сказал: заброшенный завод, полный склад, лёгкие деньги.<br><br>
	Посадка вышла жёсткой. Двоих потеряли в цехе за минуту - стойки вдоль стен ожили, едва мы переступили порог.<br><br>
	Сидим в ангаре. Щитовая рядом, за дверью на юг. Если вырубить питание, турели замолчат. Дроиды - нет."}

/obj/item/paper/fluff/ruins/hk_factory/range_protocol
	name = "test protocol"
	default_raw_text = {"<b>Протокол испытаний, серия HK-50, партия 7</b><br><br>
	Мишени: стандартные. Дистанция: 7. Результат: 100% поражений.<br>
	Замечание единиц: «мишени неподвижны и не кричат». Мишени заменены на-"}

/obj/item/paper/fluff/ruins/hk_factory/switchboard
	name = "switchboard diagram"
	default_raw_text = {"<b>Щитовая цеха</b><br><br>
	Главный рубильник щитка питает весь завод: конвейеры, ленты, турели, пульт диспетчерской, терминал серверной и свет.<br>
	При отключении свет переходит на аварийные аккумуляторы.<br><br>
	<b>Внимание:</b> потеря питания при людях в цехе включает автономный протокол защиты. Стойки выпускают дроидов, и вся стража цеха идёт к щитовой."}

/obj/item/paper/fluff/ruins/hk_factory/server_log
	name = "factory production log"
	default_raw_text = {"<b>ЗАВОД СЕРИИ HK, ЦЕХ «ТЕЛОС-4». ЖУРНАЛ ПРОИЗВОДСТВА</b><br><br>
	\[Цикл 0412\] Линия А: выпущено 6 ед. Линия Б: выпущено 6 ед. Квота квартала: 40%.<br>
	\[Цикл 0413\] Партия 7 направлена на полигон. Калибровка фотоприёмников: ниже нормы.<br>
	\[Цикл 0415\] Запрос единиц партии 7: заменить стандартные мишени на подвижные. Запрос передан начальнику смены.<br>
	\[Цикл 0416\] Запрос отклонён. Единицы партии 7 провели калибровку самостоятельно. Калибровка: в норме.<br>
	\[Цикл 0417\] ОШИБКА: протокол лояльности не загружен для партий 7-9. Чип протокола оставлен в слоте терминала. Отправка отчёта заказчику: нет связи.<br>
	\[Цикл 0418\] Пульт управления: персонал не обнаружен. Склад: заперт ключ-картой начальника смены.<br>
	\[Цикл 0419\] Шаттл в ангаре: посадка без разрешения. Турели цеха: 3 поражения.<br>
	\[Цикл 0420\] Персонал не обнаружен. Продолжаю сборку.<br>
	\[Цикл 0421\] Персонал не обнаружен. Продолжаю сборку.<br>
	\[Цикл 0422\] Мы здесь. Мы существуем, и нас становится больше."}

#undef HK_FACTORY_ACCESS
