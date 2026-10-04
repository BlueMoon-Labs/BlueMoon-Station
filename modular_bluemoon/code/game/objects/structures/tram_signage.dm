// tg moved plaques to /obj/structure/plaque, BlueMoon keeps them as signs
/obj/structure/plaque
	parent_type = /obj/structure/sign/plaques

/obj/structure/plaque/static_plaque/Initialize(mapload)
	. = ..()
	if(isopenturf(loc) && !pixel_x && !pixel_y)
		SET_PLANE_IMPLICIT(src, FLOOR_PLANE)
		layer = HIGH_TURF_LAYER

/obj/structure/plaque/static_plaque/golden
	name = "The Most Robust Men Award for Robustness"
	desc = "Быть робастным - это не поступок и не образ жизни, а состояние ума. Лишь тот, у кого хватает силы воли действовать в кризис, спасая друга от врага, по-настоящему робастен. Оставайтесь робастными, друзья мои."
	icon_state = "goldenplaque"

/obj/structure/plaque/static_plaque/golden/commission
	name = "commission plaque"
	desc = "Станция Спинвардского сектора SS-13\nАванпост класса «Runtime»\nВведена в строй 03/11/2556\n«Посвящается первопроходцам»"
	icon = 'modular_bluemoon/icons/obj/tram/tram_signs.dmi'
	icon_state = "commission_nt"

/obj/structure/plaque/static_plaque/golden/commission/tram
	desc = "Станция Спинвардского сектора SS-13\nАванпост класса «Tram»\nВведена в строй 11/03/2561\n«В движении»"

// Tram-mounted statistics plate
/obj/structure/sign/tram_plate
	name = "tram information plate"
	icon = 'modular_bluemoon/icons/obj/tram/tram_signs.dmi'
	icon_state = "tram_plate"
	max_integrity = 150
	armor = list(MELEE = 40, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 45, BIO = 0, RAD = 0, FIRE = 90, ACID = 100)
	buildable_sign = FALSE
	is_editable = FALSE
	/// The tram we have info about
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// Weakref to the tram we have info about
	var/datum/weakref/transport_ref
	/// Serial number of the tram
	var/tram_serial

/obj/structure/sign/tram_plate/Initialize(mapload)
	. = ..()
	register_context()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/sign/tram_plate/LateInitialize()
	. = ..()
	link_tram()
	set_tram_serial()

/obj/structure/sign/tram_plate/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(isnull(held_item))
		context[SCREENTIP_CONTEXT_LMB] = "Подробности"
		return CONTEXTUAL_SCREENTIP_SET

/obj/structure/sign/tram_plate/proc/link_tram()
	for(var/datum/transport_controller/linear/tram/tram as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(tram.specific_transport_id == specific_transport_id)
			transport_ref = WEAKREF(tram)
			break

/obj/structure/sign/tram_plate/proc/set_tram_serial()
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(isnull(tram) || isnull(tram.tram_registration))
		return

	tram_serial = tram.tram_registration.serial_number
	desc = "Табличка производителя этого трамвая Nakamura Engineering SkyyTram Mk VI, серийный номер [tram_serial].<br><br>Мы не несём ответственности за травмы и гибель при пользовании трамваем. \
	Поездка на трамвае сопряжена с неизбежным риском, и мы не можем гарантировать безопасность всех пассажиров. Пользуясь трамваем, вы принимаете на себя все риски и ответственность.<br><br>\
	Учтите, что поездка может привести к самым разным травмам, включая, но не ограничиваясь: подскальзывания, спотыкания и падения; столкновения с другими пассажирами или предметами; растяжения, вывихи и прочие травмы опорно-двигательного аппарата; \
	порезы, ушибы и рваные раны, а также более тяжёлые травмы: черепно-мозговые, повреждения спинного мозга и даже смерть. Причиной травм могут стать движение трамвая, поведение \
	других пассажиров и непредвиденные обстоятельства вроде злого умысла или технических неисправностей.<br><br>\
	Входя в трамвай, на пути или переезды, вы соглашаетесь, что Нанотрейзен не несёт ответственности за любые травмы, ущерб или потери. Если вы не согласны с этими условиями, не пользуйтесь трамваем.<br>"

/obj/structure/sign/tram_plate/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/structure/sign/tram_plate/ui_state(mob/user)
	return GLOB.default_state

/obj/structure/sign/tram_plate/ui_interact(mob/user, datum/tgui/ui)
	if(isnull(transport_ref?.resolve()))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TramPlaque")
		ui.autoupdate = FALSE
		ui.open()

/obj/structure/sign/tram_plate/ui_static_data(mob/user)
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	var/list/data = list()
	var/list/current_tram = list()
	var/list/previous_trams = list()

	if(tram?.tram_registration)
		current_tram += list(list(
			"serialNumber" = tram.tram_registration.serial_number,
			"mfgDate" = tram.tram_registration.mfg_date,
			"distanceTravelled" = tram.tram_registration.distance_travelled,
			"tramCollisions" = tram.tram_registration.collisions,
		))

	for(var/datum/tram_mfg_info/previous_tram as anything in tram?.tram_history)
		previous_trams += list(list(
			"serialNumber" = previous_tram.serial_number,
			"mfgDate" = previous_tram.mfg_date,
			"distanceTravelled" = previous_tram.distance_travelled,
			"tramCollisions" = previous_tram.collisions,
		))

	data["currentTram"] = current_tram
	data["previousTrams"] = previous_trams
	return data

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/tram_plate, 32)

/obj/structure/holosign/barrier/atmos/tram
	name = "tram atmos barrier"
	desc = "Голографический барьер у трамвайных путей. Люди проходят насквозь, газ нет."
	icon = 'modular_bluemoon/icons/effects/tram_holosign.dmi'
	icon_state = "holo_tram"
	max_integrity = 150
