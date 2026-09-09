/// Расход тонера на аварийный бланк.
#define INCIDENT_SPAM_TONER_USE 0.125

/// Небольшие происшествия в одном отсеке. База не регистрируется как отдельное событие.
/datum/round_event_control/station_incident
	weight = 10
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 5
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_JANITORIAL
	intensity_linger = 4 MINUTES
	/// Для спаунов и поломок инфраструктуры выбираем только коридоры и технические тоннели.
	var/public_locations_only = TRUE
	var/target_type = /turf/open/floor
	var/target_count = 1
	var/incident_message = ""
	var/requires_air = FALSE
	/// Узкие списки помещений для грузов: личные кабинеты и критические отсеки не подходят.
	var/list/allowed_area_types
	var/effect_radius = 3
	var/announcement_title = "Станционная служба оповещения"

/datum/round_event_control/station_incident/proc/valid_area(area/location)
	if(allowed_area_types)
		for(var/area_type in allowed_area_types)
			if(istype(location, area_type))
				return TRUE
		return FALSE
	return !public_locations_only || istype(location, /area/hallway) || istype(location, /area/maintenance)

/datum/round_event_control/station_incident/proc/valid_location(atom/target)
	var/turf/open/floor/floor = get_turf(target)
	if(!istype(floor) || !is_station_level(floor.z))
		return FALSE
	if(requires_air)
		var/datum/gas_mixture/air = floor.return_air()
		if(!air || air.return_pressure() < 80 || air.return_pressure() > 120 || air.temperature < 270 || air.temperature > 330)
			return FALSE
		if(air.get_moles(GAS_O2) < 10 || air.get_moles(GAS_PLASMA) > 0.1)
			return FALSE
	return valid_area(get_area(floor))

/datum/round_event_control/station_incident/proc/valid_target(atom/target)
	if(QDELETED(target) || !istype(target, target_type) || !valid_location(target))
		return FALSE
	if(isturf(target))
		var/turf/floor = target
		return !floor.is_blocked_turf()
	// Не трогаем технику и экипаж внутри контейнеров, мехов и мебели.
	if(!isturf(target.loc))
		return FALSE
	if(ismachinery(target))
		var/obj/machinery/machine = target
		return !(machine.machine_stat & (NOPOWER|BROKEN))
	return TRUE

/// Preflight останавливается на первой цели; полный выбор делается только при запуске.
/datum/round_event_control/station_incident/proc/get_candidates(first_only = FALSE)
	var/list/result = list()
	if(ispath(target_type, /turf))
		var/list/areas = first_only ? GLOB.sortedAreas : shuffle(GLOB.sortedAreas)
		for(var/area/location as anything in areas)
			if(!valid_area(location))
				continue
			for(var/turf/open/floor/floor in get_area_turfs(location))
				if(valid_target(floor))
					result += floor
					if(first_only)
						return result
				CHECK_TICK
			// Одного отсека достаточно: не собираем всю палубу ради двух мобов.
			if(length(result))
				return result
		return result
	var/list/source = ispath(target_type, /mob) ? GLOB.human_list : GLOB.machines
	for(var/atom/target as anything in source)
		if(valid_target(target))
			result += target
			if(first_only)
				return result
		CHECK_TICK
	return result

/datum/round_event_control/station_incident/director_preflight()
	var/ready = length(get_candidates(first_only = TRUE)) > 0
	director_preflight_detail = ready ? "Есть подходящая цель на станции." : "Нет подходящих целей на станции."
	return ready

/datum/round_event_control/station_incident/execute_action()
	if(!director_preflight())
		return FALSE
	return ..()

/datum/round_event/station_incident
	fakeable = FALSE
	var/affected_count = 0
	var/incident_area_name
	var/shipment_type

/datum/round_event/station_incident/start()
	var/datum/round_event_control/station_incident/incident = control
	if(!istype(incident))
		return
	var/list/candidates = incident.get_candidates()
	if(!length(candidates))
		return
	var/atom/first_target = pick(candidates)
	var/area/location = get_area(first_target)
	var/turf/epicentre = get_turf(first_target)
	incident_area_name = location.name
	// Все цели одного запуска находятся в одном отсеке.
	while(length(candidates) && affected_count < incident.target_count)
		var/atom/target = pick_n_take(candidates)
		if(get_area(target) != location || !incident.valid_target(target))
			continue
		var/turf/target_turf = get_turf(target)
		if(target_turf.z != epicentre.z || get_dist(epicentre, target) > incident.effect_radius)
			continue
		if(apply_effect(target))
			affected_count++
		CHECK_TICK
	if(affected_count)
		log_game("DIRECTOR: [control.name], отсек [incident_area_name], затронуто целей: [affected_count].")

/datum/round_event/station_incident/announce(fake)
	if(!affected_count)
		return
	var/datum/round_event_control/station_incident/incident = control
	priority_announce("[incident.incident_message] Отсек: [incident_area_name].", incident.announcement_title)

/datum/round_event/station_incident/proc/apply_effect(atom/target)
	if(shipment_type)
		return deliver_shipment(get_turf(target))
	return FALSE

/// Груз проходит обычную анимацию доставки и остаётся упакованным после открытия капсулы.
/datum/round_event/station_incident/proc/deliver_shipment(turf/target)
	var/obj/structure/closet/supplypod/centcompod/pod = make_shipment()
	new /obj/effect/pod_landingzone(target, pod)
	return TRUE

/datum/round_event/station_incident/proc/make_shipment()
	var/obj/structure/closet/supplypod/centcompod/pod = new()
	pod.effectQuiet = TRUE
	pod.delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 2 SECONDS)
	new shipment_type(pod)
	return pod

/datum/round_event_control/station_incident/vending_samples
	name = "Vending Samples"
	description = "Торговая сеть тестирует промоакцию: до трёх пищевых автоматов поблизости выдают по два пробника из обычного запаса и приглашают экипаж на дегустацию."
	typepath = /datum/round_event/station_incident/vending_samples
	category = EVENT_CATEGORY_FRIENDLY
	family = "vending"
	public_locations_only = FALSE
	target_type = /obj/machinery/vending
	target_count = 3
	announcement_title = "Отдел потребительских исследований NanoTrasen"
	incident_message = "Сегодня дегустация за счёт поставщика. Автоматы в выбранной зоне выдадут пробники из текущей партии. Просьба не путать бесплатную порцию с разрешением опустошить автомат."

/datum/round_event_control/station_incident/vending_samples/valid_target(obj/machinery/vending/target)
	if(!..() || target.shoot_inventory || target.tilted)
		return FALSE
	if(!istype(target, /obj/machinery/vending/snack) && !istype(target, /obj/machinery/vending/cola) && !istype(target, /obj/machinery/vending/coffee))
		return FALSE
	for(var/datum/data/vending_product/product as anything in target.product_records)
		if(product.amount > 0 && product.product_path)
			return TRUE
	return FALSE

/datum/round_event/station_incident/vending_samples/apply_effect(obj/machinery/vending/target)
	target.speak("Промоакция! Две бесплатные порции для участников дегустации. Если вам не понравилось, вспомните, сколько вы заплатили.")
	target.freebie(null, 2)
	new /obj/effect/temp_visual/incident_particles/confetti(get_turf(target))
	SStgui.update_uis(target)
	return TRUE

/datum/round_event_control/station_incident/copier_spam
	name = "Recursive Paperwork"
	description = "Старая заявка попадает в цикл согласования: до двух копиров рядом печатают бланки, которые требуют приложить собственную копию. Внизу остаётся сообщение об остановке очереди."
	typepath = /datum/round_event/station_incident/copier_spam
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "paperwork"
	public_locations_only = FALSE
	target_type = /obj/machinery/photocopier
	target_count = 2
	announcement_title = "Служба документооборота NanoTrasen"
	incident_message = "Очередь согласований остановлена: форма 38-Б повторно запрашивает форму 38-Б в качестве приложения. Уже напечатанные экземпляры недействительны. Не подавайте их заново — это и запустило цикл."

/datum/round_event_control/station_incident/copier_spam/valid_target(obj/machinery/photocopier/target)
	return ..() && !target.busy && target.get_paper_count() > 0 && target.toner_cartridge?.charges >= INCIDENT_SPAM_TONER_USE

/datum/round_event/station_incident/copier_spam/apply_effect(obj/machinery/photocopier/target)
	var/copies = min(4, target.get_paper_count(), FLOOR(target.toner_cartridge.charges / INCIDENT_SPAM_TONER_USE, 1))
	for(var/i in 1 to copies)
		var/obj/item/paper/form = target.get_empty_paper()
		form.name = "paper - 'Form 38-B'"
		form.add_raw_text("ОТДЕЛ ДОКУМЕНТООБОРОТА NANOTRASEN<br>Форма 38-Б. Восстановление утраченного приложения.<br>Заявитель: автоматический архив станции.<br>Утраченное приложение: форма 38-Б.<br>Для согласования приложите заверенную копию формы 38-Б.<br><br>ДИАГНОСТИКА ОЧЕРЕДИ: обнаружена ссылка документа на самого себя. Печать остановлена, повторная подача заблокирована. Экземпляр предназначен для служебного разбора и не требует подписи.")
		form.update_appearance()
		form.forceMove(get_turf(target))
		target.give_pixel_offset(form)
		new /obj/effect/temp_visual/incident_paper(get_turf(target))
		target.toner_cartridge.charges -= INCIDENT_SPAM_TONER_USE
	SStgui.update_uis(target)
	return copies > 0

/datum/round_event_control/station_incident/weed_bloom
	name = "Hydroponics Weed Bloom"
	description = "Влажный субстрат из загрязнённой партии даёт всходы сорняков в трёх соседних лотках. Культуры сохраняются; ботаники могут убрать молодые побеги культиватором."
	typepath = /datum/round_event/station_incident/weed_bloom
	family = "plants"
	public_locations_only = FALSE
	target_type = /obj/machinery/hydroponics
	target_count = 3
	announcement_title = "Уведомление поставщика агроматериалов"
	incident_message = "В партии питательного субстрата найдены жизнеспособные семена сорняков. Они прорастают во влажных лотках без автономного ухода. Поставщик рекомендует прополоть всходы, пока они не вытеснили культурные растения."

/datum/round_event_control/station_incident/weed_bloom/valid_target(obj/machinery/hydroponics/target)
	return ..() && target.myseed && !target.dead && !target.self_sustaining && target.waterlevel >= 30 && target.weedlevel < 5

/datum/round_event/station_incident/weed_bloom/apply_effect(obj/machinery/hydroponics/target)
	target.visible_message(span_notice("Между посадками в [target] пробиваются частые светлые побеги сорняков."))
	target.adjustWeeds(5 - target.weedlevel)
	target.update_icon()
	new /obj/effect/temp_visual/incident_particles/sprouts(get_turf(target))
	return TRUE

/datum/round_event_control/station_incident/poultry
	name = "Escaped Poultry"
	description = "В грузовую зону доставляют трёх кур для станционной фермы. У транспортного ящика разболтался затвор: через минуту он откроется, если не подтянуть его гаечным ключом."
	typepath = /datum/round_event/station_incident/poultry
	category = EVENT_CATEGORY_SPAWNERS
	family = "cargo_pod"
	allowed_area_types = list(/area/cargo/warehouse, /area/cargo/storage, /area/cargo/sorting)
	requires_air = TRUE
	announcement_title = "Служба доставки живых грузов"
	incident_message = "Прибывает пополнение для станционной фермы: три несушки. Перевозчик сообщает о повреждённом затворе. Подтяните его гаечным ключом в течение минуты после выгрузки и передайте птиц ботаникам."

/datum/round_event/station_incident/poultry
	shipment_type = /obj/structure/closet/crate/incident_shipment/poultry

/datum/round_event_control/station_incident/floor_damage
	name = "Deck Tile Fatigue"
	description = "На небольшом участке палубы от температурного расширения лопается до шести соседних плиток. Несущая обшивка цела; повреждённое покрытие можно заменить обычным способом."
	typepath = /datum/round_event/station_incident/floor_damage
	category = EVENT_CATEGORY_ENGINEERING
	family = "deck_repairs"
	target_count = 6
	incident_message = "Датчики зарегистрировали деформацию покрытия после температурного перепада. Несущая палуба герметична. Инженерной службе следует осмотреть участок и заменить растрескавшиеся плитки."

/datum/round_event_control/station_incident/floor_damage/valid_target(turf/open/floor/target)
	return ..() && target.floor_tile && !target.broken && !target.burnt && length(target.broken_states)

/datum/round_event/station_incident/floor_damage/apply_effect(turf/open/floor/target)
	target.visible_message(span_notice("С сухим треском по плитке расходится трещина."))
	target.break_tile()
	if(target.broken)
		new /obj/effect/temp_visual/incident_particles(target)
	return target.broken

/datum/round_event_control/station_incident/repair_cache
	name = "Delayed Maintenance Shipment"
	description = "Транзитный склад находит потерянный заказ предыдущей смены и досылает оплаченный ремонтный комплект. В ящике есть инструменты, материалы и накладная с объяснением задержки."
	typepath = /datum/round_event/station_incident/repair_cache
	category = EVENT_CATEGORY_FRIENDLY
	family = "cargo_pod"
	allowed_area_types = list(/area/engineering/storage, /area/cargo/warehouse, /area/cargo/storage)
	announcement_title = "Транзитный склад NanoTrasen"
	incident_message = "Заказ ремонтных материалов предыдущей смены найден в очереди недоставленных грузов и направлен на станцию. Повторная оплата не требуется. Просим передать комплект инженерной службе."

/datum/round_event/station_incident/repair_cache
	shipment_type = /obj/structure/closet/crate/incident_shipment/repair_cache

/datum/round_event_control/station_incident/ore_stowaway
	name = "Ore Stowaway"
	description = "С рудными пробами прибывает золотожор, пропущенный карантинным сканером. Он остаётся внутри до вскрытия ящика; предупреждение в накладной позволяет подготовить место для осмотра."
	typepath = /datum/round_event/station_incident/ore_stowaway
	category = EVENT_CATEGORY_SPAWNERS
	family = "cargo_pod"
	allowed_area_types = list(/area/cargo/miningstorage, /area/cargo/warehouse, /area/cargo/storage)
	announcement_title = "Карантинная служба рудного терминала"
	incident_message = "Отправленная партия рудных проб не прошла повторную проверку: внутри замечено движение. Вскрывайте ящик в закрытом помещении, предварительно убрав свободную руду. Накладная прилагается."

/datum/round_event/station_incident/ore_stowaway
	shipment_type = /obj/structure/closet/crate/incident_shipment/ore_stowaway

/datum/round_event_control/station_incident/capacitor_discharge
	name = "APC Battery Failure"
	description = "В резервной батарее одного APC пробивает часть ячеек. Она дымит, теряет заряд и половину ёмкости; повреждения видны при осмотре вынутой батареи. Замена восстанавливает резерв."
	typepath = /datum/round_event/station_incident/capacitor_discharge
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MODERATE
	earliest_start = 25 MINUTES
	min_players = 12
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	family = "petty_power"
	intensity_linger = 6 MINUTES
	target_type = /obj/machinery/power/apc
	announcement_title = "Диагностика электроснабжения"
	incident_message = "Самопроверка APC обнаружила внутреннее замыкание части аккумуляторных ячеек. Резервная ёмкость снижена; обычная зарядка её не восстановит. Требуется замена повреждённой батареи."

/datum/round_event_control/station_incident/capacitor_discharge/valid_target(obj/machinery/power/apc/target)
	if(!..() || !target.operating || target.shorted || !target.cell || target.cell.rigged)
		return FALSE
	if(istype(target.cell, /obj/item/stock_parts/cell/infinite) || istype(target.cell, /obj/item/stock_parts/cell/emproof))
		return FALSE
	return target.cell.charge > target.cell.maxcharge * 0.5 && target.cell.maxcharge > target.cell.chargerate

/datum/round_event/station_incident/capacitor_discharge/apply_effect(obj/machinery/power/apc/target)
	if(!target.cell.use(target.cell.charge * 0.6, FALSE))
		return FALSE
	target.cell.maxcharge = max(target.cell.maxcharge * 0.5, target.cell.chargerate)
	target.cell.desc += " На корпусе виден тёмный след перегрева. Часть ячеек повреждена; зарядка не восстановит прежнюю ёмкость."
	new /obj/effect/temp_visual/incident_short_circuit(get_turf(target))
	target.visible_message(span_warning("Из [target] вырывается тонкая струйка дыма; индикатор батареи начинает мигать."))
	new /obj/effect/temp_visual/small_smoke(get_turf(target))
	target.update_icon()
	SStgui.update_uis(target)
	return TRUE

/datum/round_event_control/station_incident/terminal_burnout
	name = "Public Terminal Burnout"
	description = "Короткий скачок напряжения выводит из строя экраны до двух соседних публичных терминалов. Обугленная лицевая панель указывает на причину; платы пригодны для повторной сборки."
	typepath = /datum/round_event/station_incident/terminal_burnout
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MODERATE
	earliest_start = 25 MINUTES
	min_players = 12
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	family = "terminal_fault"
	intensity_linger = 8 MINUTES
	target_type = /obj/machinery/computer
	target_count = 2
	announcement_title = "Диагностика станционных терминалов"
	incident_message = "После скачка напряжения пропал отклик экранных модулей публичных терминалов. Платы продолжают отвечать на диагностику. Консоли можно восстановить разборкой и заменой стекла."

/datum/round_event_control/station_incident/terminal_burnout/valid_target(obj/machinery/computer/target)
	if(!..() || !target.circuit || (target.flags_1 & NODECONSTRUCT_1))
		return FALSE
	return istype(target, /obj/machinery/computer/arcade) || istype(target, /obj/machinery/computer/crew) || istype(target, /obj/machinery/computer/security)

/datum/round_event/station_incident/terminal_burnout/apply_effect(obj/machinery/computer/target)
	target.obj_break(ENERGY)
	new /obj/effect/temp_visual/incident_terminal_static(get_turf(target))
	target.visible_message(span_warning("Экран [target] вспыхивает белым и гаснет. От лицевой панели поднимается дым."))
	new /obj/effect/temp_visual/small_smoke(get_turf(target))
	return (target.machine_stat & BROKEN) != 0

/datum/round_event_control/station_incident/mimic
	name = "Counterfeit Cargo Crate"
	description = "Утилизаторы присылают опечатанный транспортный футляр с ящиком, найденным на заброшенном судне. Внутренний ящик оказывается мимиком; вскрытие можно подготовить в изолированном помещении."
	typepath = /datum/round_event/station_incident/mimic
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MODERATE
	earliest_start = 25 MINUTES
	min_players = 15
	min_staffing = list(DIRECTOR_DEPT_SECURITY = 1)
	family = "cargo_pod"
	allowed_area_types = list(/area/cargo/warehouse, /area/cargo/storage, /area/cargo/sorting)
	intensity_linger = 8 MINUTES
	announcement_title = "Служба утилизации заброшенных судов"
	incident_message = "Прибывает находка для оценки: грузовой ящик без маркировки, упакованный в отдельный транспортный футляр. Контрольное взвешивание дало нестабильный результат. До осмотра научным отделом или охраной держите футляр закрытым."

/datum/round_event/station_incident/mimic
	shipment_type = /obj/structure/closet/crate/incident_shipment/mimic

/datum/round_event_control/station_incident/slimes
	name = "Leaking Slime Shipment"
	description = "Лаборатория-поставщик досылает два серых образца для ксенобиологии. После выгрузки повреждённый затвор контейнера продержится минуту. Гаечный ключ предотвратит побег; внутри приложен штатный водяной распылитель."
	typepath = /datum/round_event/station_incident/slimes
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MODERATE
	earliest_start = 30 MINUTES
	min_players = 15
	min_staffing = list(DIRECTOR_DEPT_SCIENCE = 1)
	family = "cargo_pod"
	intensity_linger = 8 MINUTES
	allowed_area_types = list(/area/cargo/warehouse, /area/cargo/storage, /area/cargo/sorting)
	requires_air = TRUE
	announcement_title = "Лаборатория снабжения ксенобиологии"
	incident_message = "На станцию направлены два серых образца взамен партии, задержанной карантином. Телеметрия сообщает о расшатанном затворе контейнера: после выгрузки он может раскрыться в течение минуты. Подтяните крепление гаечным ключом и передайте контейнер ксенобиологам."

/datum/round_event/station_incident/slimes
	shipment_type = /obj/structure/closet/crate/incident_shipment/slimes

/datum/round_event_control/station_incident/hay_fever
	name = "Pollen Exposure"
	description = "Готовое к сбору растение начинает усиленно пылить. Через полминуты пыльца раздражает дыхательные пути стоящих рядом сотрудников. Сбор урожая или удаление растения прекращает выброс; маски защищают."
	typepath = /datum/round_event/station_incident/hay_fever
	category = EVENT_CATEGORY_HEALTH
	severity = DIRECTOR_SEVERITY_MODERATE
	earliest_start = 25 MINUTES
	min_players = 15
	min_staffing = list(DIRECTOR_DEPT_MEDICAL = 1)
	family = "allergens"
	intensity_linger = 4 MINUTES
	public_locations_only = FALSE
	target_type = /obj/machinery/hydroponics
	announcement_title = "Мониторинг воздуха гидропоники"
	incident_message = "У одного из созревших растений обнаружено избыточное выделение пыльцы. Соберите урожай или удалите растение, чтобы остановить выброс. До обработки лотка используйте маски; при зуде и чихании обратитесь к медикам."

/datum/round_event_control/station_incident/hay_fever/valid_target(obj/machinery/hydroponics/target)
	return ..() && target.myseed && target.harvest && !target.dead && !target.self_sustaining

/datum/round_event/station_incident/hay_fever
	// Раннер событий шагает раз в две секунды: 60 шагов дают две минуты выброса.
	end_when = 60
	var/datum/weakref/pollen_tray
	var/datum/weakref/pollen_seed
	var/datum/weakref/pollen_area
	var/pollen_z
	var/obj/effect/incident_pollen_cloud/pollen_cloud
	var/list/exposed = list()

/datum/round_event/station_incident/hay_fever/apply_effect(obj/machinery/hydroponics/target)
	pollen_tray = WEAKREF(target)
	pollen_seed = WEAKREF(target.myseed)
	pollen_area = WEAKREF(get_area(target))
	pollen_z = target.z
	QDEL_NULL(pollen_cloud)
	pollen_cloud = new(null, target)
	target.visible_message(span_warning("Над созревшими посадками в [target] поднимается облачко жёлтой пыльцы. Похоже, пора собирать урожай."))
	return TRUE

/datum/round_event/station_incident/hay_fever/proc/get_pollen_source()
	var/obj/machinery/hydroponics/tray = pollen_tray?.resolve()
	if(QDELETED(tray) || tray.dead || !tray.harvest || tray.self_sustaining || !isturf(tray.loc))
		return null
	if(QDELETED(tray.myseed) || tray.myseed != pollen_seed?.resolve())
		return null
	if(tray.z != pollen_z || get_area(tray) != pollen_area?.resolve())
		return null
	return tray

/datum/round_event/station_incident/hay_fever/proc/can_expose(mob/living/carbon/human/target)
	if(QDELETED(target) || !isturf(target.loc) || target.stat != CONSCIOUS || target.health < 80 || !is_effective_crew_mob(target))
		return FALSE
	if(isrobotic(target) || target.wear_mask || HAS_TRAIT(target, TRAIT_NOBREATH) || HAS_TRAIT(target, TRAIT_TOXIMMUNE))
		return FALSE
	return target.reagents && !target.reagents.has_reagent(/datum/reagent/toxin/histamine)

/datum/round_event/station_incident/hay_fever/proc/expose(mob/living/carbon/human/target)
	if(length(exposed) >= 4 || (REF(target) in exposed) || !can_expose(target))
		return FALSE
	if(!target.reagents.add_reagent(/datum/reagent/toxin/histamine, 4))
		return FALSE
	exposed += REF(target)
	to_chat(target, span_warning("В воздухе щекочет мелкая пыльца. Глаза начинают зудеть."))
	return TRUE

/datum/round_event/station_incident/hay_fever/tick()
	var/obj/machinery/hydroponics/tray = get_pollen_source()
	if(!tray)
		return kill()
	if(activeFor < 15 || !ISMULTIPLE(activeFor, 5))
		return
	for(var/mob/living/carbon/human/target in view(3, tray))
		if(!target.client || get_area(target) != get_area(tray))
			continue
		expose(target)
		if(length(exposed) >= 4)
			break

/datum/round_event/station_incident/hay_fever/kill()
	QDEL_NULL(pollen_cloud)
	return ..()

/datum/round_event/station_incident/hay_fever/end()
	QDEL_NULL(pollen_cloud)
	return ..()

/datum/round_event/station_incident/hay_fever/Destroy()
	QDEL_NULL(pollen_cloud)
	return ..()

#undef INCIDENT_SPAM_TONER_USE
