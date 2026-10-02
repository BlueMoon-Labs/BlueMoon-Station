/// Грузы событий остаются настоящими контейнерами: их можно перевезти, осмотреть и вскрыть.
/obj/structure/closet/crate/incident_shipment
	name = "transit crate"
	icon = 'icons/obj/station_incident_crates.dmi'
	icon_state = "repair"
	desc = "Транспортный ящик с пломбами перевалочного склада. На крышке закреплена накладная."
	can_weld_shut = TRUE
	var/dispatch_manifest = ""
	var/seal_fault = FALSE
	var/release_timer
	var/warning_timer
	var/countdown_started = FALSE
	var/restless_cargo = FALSE
	var/rattle_until = 0

/// Шестнадцать кадров содержимого сопровождаются мягким покачиванием корпуса.
/obj/structure/closet/crate/incident_shipment/proc/rattle(strong = FALSE)
	if(opened || world.time < rattle_until)
		return
	rattle_until = world.time + 1.2 SECONDS
	flick("[initial(icon_state)]_rattle", src)
	var/rest_x = pixel_x
	var/amplitude = strong ? 2 : 1
	animate(src, pixel_x = rest_x + amplitude, time = 2, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(pixel_x = rest_x - amplitude, time = 4, easing = SINE_EASING)
	animate(pixel_x = rest_x, time = 6, easing = SINE_EASING)

/// Индикатор отражает состояние затвора и пропадает с открытой крышки.
/obj/structure/closet/crate/incident_shipment/closet_update_overlays(list/new_overlays)
	. = ..()
	if(initial(seal_fault) && !opened)
		. += seal_fault ? "securecrater" : "securecrateg"

/obj/structure/closet/crate/incident_shipment/Initialize(mapload)
	. = ..()
	var/obj/item/paper/fluff/jobs/cargo/manifest/shipping_note = new(src)
	shipping_note.name = "shipping manifest"
	shipping_note.add_raw_text(dispatch_manifest)
	shipping_note.update_appearance()
	set_manifest(shipping_note)
	if(seal_fault)
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_delivery))
		start_countdown()

/obj/structure/closet/crate/incident_shipment/Destroy()
	stop_countdown()
	return ..()

/obj/structure/closet/crate/incident_shipment/proc/on_delivery()
	SIGNAL_HANDLER
	start_countdown()

/// Отсчёт начинается после выгрузки из капсулы, а не во время перевозки внутри неё.
/obj/structure/closet/crate/incident_shipment/proc/start_countdown()
	if(!seal_fault || countdown_started || opened || !isturf(loc))
		return
	countdown_started = TRUE
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	visible_message(span_warning("На [src] горит красный индикатор затвора. Крышка дребезжит на ослабших креплениях."))
	playsound(src, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	rattle()
	release_timer = addtimer(CALLBACK(src, PROC_REF(release_cargo)), 1 MINUTES, TIMER_STOPPABLE)
	warning_timer = addtimer(CALLBACK(src, PROC_REF(warn_seal_failure)), 45 SECONDS, TIMER_STOPPABLE)

/obj/structure/closet/crate/incident_shipment/proc/warn_seal_failure()
	warning_timer = null
	if(!seal_fault || opened || welded || locked)
		return
	rattle(strong = TRUE)
	playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
	visible_message(span_warning("Крышка [src] ходит ходуном: затвор вот-вот сорвётся!"))

/obj/structure/closet/crate/incident_shipment/proc/stop_countdown()
	if(warning_timer)
		deltimer(warning_timer)
		warning_timer = null
	if(release_timer)
		deltimer(release_timer)
		release_timer = null

/obj/structure/closet/crate/incident_shipment/proc/release_cargo()
	stop_countdown()
	if(!seal_fault || opened || welded || locked)
		return
	visible_message(span_warning("Затвор [src] срывается, и крышка откидывается!"))
	open()

/obj/structure/closet/crate/incident_shipment/examine(mob/user)
	. = ..()
	if(manifest)
		. += span_notice("Накладную можно снять рукой, не открывая ящик. В ней указаны отправитель, содержимое и условия перевозки.")
	if(opened)
		return
	if(seal_fault)
		. += span_warning("Крепление затвора разболталось. Его можно подтянуть гаечным ключом, не открывая контейнер. Содержимое указано в накладной на крышке.")
	else if(initial(seal_fault))
		. += span_notice("Затвор закреплён. Контейнер можно безопасно перевезти, пока крышка закрыта.")

/// Сначала даём прочитать предупреждение. Следующее взаимодействие открывает ящик штатно.
/obj/structure/closet/crate/incident_shipment/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(manifest && !opened)
		if(restless_cargo)
			rattle()
		tear_manifest(user)
		return TRUE
	return ..()

/obj/structure/closet/crate/incident_shipment/tool_interact(obj/item/tool, mob/living/user)
	if(tool.tool_behaviour != TOOL_WRENCH || !seal_fault || opened)
		return ..()
	to_chat(user, span_notice("Вы начинаете подтягивать крепление затвора [src]."))
	if(tool.use_tool(src, user, 5 SECONDS, volume = 50) && !QDELETED(src) && repair_seal())
		user.visible_message(span_notice("[user] закрепляет затвор [src]. Индикатор меняется с красного на зелёный."))
	return TRUE

/obj/structure/closet/crate/incident_shipment/proc/repair_seal()
	if(!seal_fault || opened)
		return FALSE
	seal_fault = FALSE
	stop_countdown()
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	update_icon()
	return TRUE

/obj/structure/closet/crate/incident_shipment/after_open(mob/living/user, force)
	. = ..()
	seal_fault = FALSE
	stop_countdown()
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	update_icon()

/obj/structure/closet/crate/incident_shipment/poultry
	name = "poultry transport crate"
	icon_state = "poultry"
	restless_cargo = TRUE
	desc = "Зелёная транспортная клетка с латунными петлями и эмблемой пера. За прутьями видна соломенная подстилка; при переноске наружу выбиваются отдельные пушинки."
	seal_fault = TRUE
	dispatch_manifest = "СЕЛЬСКОХОЗЯЙСТВЕННЫЙ ПИТОМНИК NANOTRASEN<br>Получатель: станционная ферма, через грузовой отдел.<br>Содержимое: три несушки для пополнения поголовья.<br>Отметка перевозчика: затвор повреждён при перегрузке. Подтянуть крепление гаечным ключом до вскрытия.<br>Передать птиц ботаникам. Корм и размещение обеспечивает принимающая сторона."

/obj/structure/closet/crate/incident_shipment/poultry/PopulateContents()
	for(var/i in 1 to 3)
		new /mob/living/simple_animal/chicken(src)

/obj/structure/closet/crate/incident_shipment/slimes
	name = "xenobiology specimen carrier"
	icon_state = "slimes"
	restless_cargo = TRUE
	desc = "Белый лабораторный контейнер с фиолетовыми амортизаторами и двумя запотевшими смотровыми окнами. Сбоку закреплён водяной баллон системы перевозки. На накладной крупно написано: «ВСКРЫВАТЬ В КАМЕРЕ СОДЕРЖАНИЯ»."
	seal_fault = TRUE
	dispatch_manifest = "ЛАБОРАТОРИЯ СНАБЖЕНИЯ КСЕНОБИОЛОГИИ<br>Получатель: научный отдел, через грузовой склад.<br>Содержимое: два молодых серых слизня; водяной распылитель из комплекта перевозки.<br>Основание: замена партии, задержанной карантинной службой.<br>ВНИМАНИЕ: телеметрия указывает на ослабление затвора. После выгрузки подтянуть его гаечным ключом. Не открывать до помещения контейнера в камеру содержания.<br>При побеге избегать контакта, использовать воду. Образцы остаются пригодными для исследований."

/obj/structure/closet/crate/incident_shipment/slimes/PopulateContents()
	for(var/i in 1 to 2)
		new /mob/living/simple_animal/slime(src)
	var/obj/item/extinguisher/sprayer = new(src)
	sprayer.name = "specimen handling sprayer"
	sprayer.desc = "Водяной распылитель из транспортного комплекта ксенобиологии. Обычный огнетушитель с дополнительной маркировкой для усмирения слизней."

/obj/structure/closet/crate/incident_shipment/repair_cache
	name = "delayed maintenance crate"
	icon_state = "repair"
	desc = "Оранжевый ремонтный кейс с синими стяжками и мигающим маячком складского учёта. Поверх старых наклеек прилеплена новая: «НАЙДЕНО. ДОСЛАТЬ ПОЛУЧАТЕЛЮ»."
	dispatch_manifest = "ТРАНЗИТНЫЙ СКЛАД NANOTRASEN<br>Получатель: инженерная служба станции.<br>Заказ предыдущей смены: набор инструментов, 10 листов металла, 5 листов стекла, 15 отрезков кабеля.<br>Причина задержки: сканер прочитал складскую отметку как адрес получателя. Груз совершил три внутренних пересылки.<br>Заказ оплачен ранее. С повторным счётом просьба обращаться в отдел претензий, а не оплачивать его."

/obj/structure/closet/crate/incident_shipment/repair_cache/PopulateContents()
	new /obj/item/storage/toolbox/mechanical(src)
	new /obj/item/stack/sheet/metal(src, 10)
	new /obj/item/stack/sheet/glass(src, 5)
	new /obj/item/stack/cable_coil(src, 15)

/obj/structure/closet/crate/incident_shipment/ore_stowaway
	name = "quarantined ore samples"
	icon_state = "ore"
	restless_cargo = TRUE
	desc = "Тяжёлый ящик с латунными уголками, жёлтыми полосами карантина и эмблемой кристалла. Через узкую решётку поблёскивает золотистая пыль."
	dispatch_manifest = "РУДНЫЙ ТЕРМИНАЛ. ПРОБЫ ДЛЯ ПЕРЕПЛАВКИ<br>Получатель: шахтёрский отдел.<br>Заявлено: три образца золотоносной руды.<br>Дополнение карантинной службы: повторный снимок выявил золотожора среди проб. Уведомление отправлено после ухода груза.<br>Осматривать в закрытом помещении, свободную руду предварительно убрать. Особь не нападает, но поедает минералы и старается убежать. После разделки можно вернуть проглоченное."

/obj/structure/closet/crate/incident_shipment/ore_stowaway/PopulateContents()
	var/mob/living/simple_animal/hostile/asteroid/goldgrub/stowaway = new(src)
	// На металлической палубе нет грунта: золотожор остаётся доступен для поимки.
	stowaway.will_burrow = FALSE
	new /obj/item/stack/ore/gold(src, 3)

/obj/structure/closet/crate/incident_shipment/mimic
	name = "sealed salvage transit case"
	icon_state = "salvage"
	restless_cargo = TRUE
	desc = "Потёртый бирюзовый футляр службы утилизации, стянутый медными ремнями. На заплатанных панелях сохранились выцветшие предупредительные полосы. Оранжевая пломба цела, но крышка сидит неровно."
	dispatch_manifest = "СЛУЖБА УТИЛИЗАЦИИ ЗАБРОШЕННЫХ СУДОВ<br>Получатель: грузовой отдел, для оценки и передачи специалистам.<br>Находка: немаркированный ящик из грузового трюма покинутого судна.<br>Упаковка: отдельный транспортный футляр, пломба склада цела.<br>Примечания бригады: масса менялась между замерами. Один грузчик сообщил о звуке дыхания; второй отказался подписывать акт.<br>Вскрывать в изолированном помещении в присутствии охраны."

/obj/structure/closet/crate/incident_shipment/mimic/PopulateContents()
	var/mob/living/simple_animal/hostile/mimic/crate/mimic = new(src)
	new /obj/item/stack/sheet/metal(mimic, 10)
	new /obj/item/stack/sheet/glass(mimic, 5)
