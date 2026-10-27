#define TOUR_GROUP_MIN_SIZE 2
#define TOUR_GROUP_MAX_SIZE 4
#define TOUR_MIN_ATTRACTIONS 4
#define TOUR_MAX_ATTRACTIONS 5
#define TOUR_GHOST_ROLE "Ghost Role"
#define TOUR_GUIDE_RANGE 2
#define TOUR_GUIDE_REWARD 150
#define TOUR_SERVICE_REWARD 300
#define TOUR_LENGTH_MINUTES 40
#define TOUR_LENGTH (TOUR_LENGTH_MINUTES MINUTES)
#define TOUR_SHAKE_COOLDOWN (2 SECONDS)
#define TOUR_STOP_BAR "бар"
#define TOUR_STOP_CHAPEL "часовня"
#define TOUR_STOP_LIBRARY "библиотека"
#define TOUR_STOP_ARCADE "зал аркадных автоматов"

/datum/round_event_control/tour_group
	name = "Tour Group"
	typepath = /datum/round_event/ghost_role/tour_group
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	min_players = 12
	severity = DIRECTOR_SEVERITY_MINOR
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	category = EVENT_CATEGORY_FRIENDLY
	family = "tour_group"
	intensity_linger = 4 MINUTES
	director_ghost_jobban = ROLE_GHOSTROLE

/datum/round_event_control/tour_group/New()
	description = "На станцию прилетает группа туристов агентства «Звёздный маршрут» (гост-роли, не антагонисты) с маршрутом по публичным отсекам. Штампы в путеводитель ставит экипаж: сотрудник касается туриста ID-картой в отсеке маршрута, в баре штамп даёт хороший коктейль, в часовне - благословение священника, в библиотеке - книга от библиотекаря. Сопровождающий сотрудник получает [TOUR_GUIDE_REWARD] кредитов за каждую новую остановку группы, за каждого туриста с полным маршрутом бюджет сервиса получает [TOUR_SERVICE_REWARD] кредитов. Турист перестаёт быть нагрузкой директора после полного маршрута или через [TOUR_LENGTH_MINUTES] минут."
	return ..()

/datum/round_event_control/tour_group/proc/find_attractions()
	return tour_station_attractions()

/datum/round_event_control/tour_group/director_preflight()
	if(length(find_attractions()) < TOUR_MIN_ATTRACTIONS)
		director_preflight_detail = "На станции меньше [TOUR_MIN_ATTRACTIONS] отсеков для экскурсии."
		director_preflight_failure = director_preflight_detail
		return FALSE
	return ..()

/// Публичные отсеки маршрута: подпись -> корневые типы отсека.
/proc/tour_attraction_catalog()
	var/static/list/catalog = list(
		TOUR_STOP_BAR = list(/area/service/bar),
		TOUR_STOP_CHAPEL = list(/area/service/chapel),
		TOUR_STOP_LIBRARY = list(/area/service/library),
		"сад" = list(/area/service/hydroponics/garden),
		"холл медбея" = list(/area/medical/medbay/lobby),
		"спортзал" = list(/area/commons/fitness),
		"голодек" = list(/area/holodeck/rec_center),
		"кафетерий" = list(/area/service/cafeteria, /area/service/kitchen/diner),
		TOUR_STOP_ARCADE = list(/area/commons/arcade),
	)
	return catalog

/// Отсек подходит под остановку, если он не служебный и не заброшенный подотсек.
/proc/tour_area_matches(area/location, list/root_types)
	var/static/list/staff_only = typecacheof(list(
		/area/service/bar/backroom,
		/area/service/chapel/asteroid,
		/area/service/chapel/dock,
		/area/service/chapel/main/monastery,
		/area/service/chapel/office,
		/area/service/chapel/storage,
		/area/service/hydroponics/garden/abandoned,
		/area/service/hydroponics/garden/monastery,
		/area/service/library/abandoned,
		/area/service/library/private,
	))
	if(!location || staff_only[location.type])
		return FALSE
	return is_type_in_list(location, root_types)

/// Остановки, которые есть на текущей станции: подпись -> корневые типы отсека.
/proc/tour_station_attractions()
	var/list/catalog = tour_attraction_catalog()
	var/list/available = list()
	for(var/area/candidate as anything in GLOB.sortedAreas)
		if(!candidate.z || !is_station_level(candidate.z))
			continue
		for(var/label in catalog)
			if(!available[label] && tour_area_matches(candidate, catalog[label]))
				available[label] = catalog[label]
	var/list/route = list()
	for(var/label in shuffle(available))
		route[label] = available[label]
		if(length(route) >= TOUR_MAX_ATTRACTIONS)
			break
	return route

/// Общая запись группы: оплаченные остановки гиду и снятие туристов с учёта директора.
/datum/star_route_tour
	var/action_name
	var/list/datum/weakref/tourist_minds = list()
	var/list/paid_stops = list()

/datum/star_route_tour/New(source_action_name)
	action_name = source_action_name

/datum/star_route_tour/proc/begin()
	addtimer(CALLBACK(src, PROC_REF(end_tour)), TOUR_LENGTH)

/datum/star_route_tour/proc/end_tour()
	var/released = 0
	for(var/datum/weakref/mind_ref as anything in tourist_minds.Copy())
		if(release(mind_ref.resolve()))
			released++
	tourist_minds.Cut()
	log_game("DIRECTOR: Tour Group, экскурсия окончена по времени, с учёта директора снято туристов: [released].")

/// Турист, закончивший экскурсию, остаётся гостем станции, но больше не держит intensity директора.
/datum/star_route_tour/proc/release(datum/mind/tourist_mind)
	if(!tourist_mind)
		return FALSE
	tourist_minds -= WEAKREF(tourist_mind)
	return minor_crew_release_ghost_role(action_name, tourist_mind)

/datum/star_route_tour/proc/pay_guide(label, mob/living/guide)
	if(!guide || paid_stops[label])
		return FALSE
	if(!minor_crew_pay_person(guide, TOUR_GUIDE_REWARD, "«Звёздный маршрут»: сопровождение экскурсии, остановка «[label]»"))
		return FALSE
	paid_stops[label] = TRUE
	log_game("DIRECTOR: Tour Group, [key_name(guide)] получает [TOUR_GUIDE_REWARD] кр. как гид за остановку «[label]».")
	return TRUE

/datum/round_event/ghost_role/tour_group
	minimum_required = 1
	role_name = "турист агентства «Звёздный маршрут»"
	var/list/attractions = list()
	var/datum/star_route_tour/tour

/datum/round_event/ghost_role/tour_group/spawn_role()
	var/datum/round_event_control/tour_group/tour_control = control
	attractions = istype(tour_control) ? tour_control.find_attractions() : tour_station_attractions()
	if(length(attractions) < TOUR_MIN_ATTRACTIONS)
		return MAP_ERROR
	var/list/candidates = get_candidates(ROLE_GHOSTROLE, null, null)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS
	tour = new(control?.action_name())
	var/wanted = rand(TOUR_GROUP_MIN_SIZE, TOUR_GROUP_MAX_SIZE)
	while(length(candidates) && length(spawned_mobs) < wanted)
		var/mob/dead/selected = pick_n_take(candidates)
		if(QDELETED(selected) || !selected.key)
			continue
		spawned_mobs += make_tourist(selected)
	if(!length(spawned_mobs))
		return NOT_ENOUGH_PLAYERS
	tour.begin()
	log_game("DIRECTOR: Tour Group, прибыло туристов: [length(spawned_mobs)], маршрут: [jointext(attractions, ", ")].")
	return SUCCESSFUL_SPAWN

/datum/round_event/ghost_role/tour_group/announce(fake)
	if(!length(spawned_mobs))
		return
	priority_announce("На станцию прибывает экскурсионная группа агентства «Звёздный маршрут», туристов в группе: [length(spawned_mobs)]. Маршрут: [jointext(attractions, ", ")]. Штампы в путеводители ставит экипаж: коснитесь туриста своей ID-картой в отсеке маршрута или у его входа. В баре штамп даёт хороший коктейль, в часовне - благословение священника, в библиотеке - книга от библиотекаря. Сотрудник, который сопровождает группу, получает [TOUR_GUIDE_REWARD] кредитов за каждую новую остановку, а за каждого туриста, прошедшего весь маршрут, агентство переводит [TOUR_SERVICE_REWARD] кредитов в бюджет сервиса. Доступа в служебные помещения у гостей нет, домой они улетят на эвакуационном шаттле.", "Отдел корпоративного туризма NanoTrasen")

/datum/round_event/ghost_role/tour_group/proc/make_tourist(mob/dead/selected)
	var/mob/living/carbon/human/tourist = new
	if(selected.client?.prefs)
		selected.client.prefs.copy_to(tourist)
		tourist.dna.update_dna_identity()
	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = TRUE
	player_mind.transfer_to(tourist)
	equip_tourist(tourist)
	SSjob.SendToLateJoin(tourist)
	to_chat(tourist, examine_block("<span class='big bold'>Вы - турист агентства «Звёздный маршрут».</span><br>\
		Вы прилетели на экскурсию по станции NanoTrasen. Маршрут: [jointext(attractions, ", ")].<br>\
		Штамп в путеводитель ставит экипаж: попросите сотрудника коснуться вас ID-картой, когда стоите в отсеке маршрута или у его входа. В баре штамп даёт хороший коктейль, в часовне - благословение священника, в библиотеке - книга от библиотекаря. Путеводитель держите при себе. За полный набор штампов агентство вручает сувенир.<br>\
		[span_warning("Вы не антагонист. Соблюдайте законы станции и указания охраны, не заходите в служебные помещения без приглашения. Домой вы улетаете вместе с экипажем на эвакуационном шаттле.")]"))
	log_game("DIRECTOR: Tour Group, [key_name(tourist)] прибывает на станцию туристом.")
	return tourist

/// Гостевая роль из EXP_TYPE_SPECIAL: мидраунд-рулсеты не выбирают туристов в антагонисты.
/datum/round_event/ghost_role/tour_group/proc/equip_tourist(mob/living/carbon/human/tourist)
	if(tourist.mind)
		tourist.mind.assigned_role = TOUR_GHOST_ROLE
		if(tour)
			tour.tourist_minds += WEAKREF(tourist.mind)
	tourist.dna.species.before_equip_job(null, tourist)
	tourist.equipOutfit(/datum/outfit/star_route_tourist)
	stow_held_tanks(tourist)
	var/obj/item/card/id/visitor_card = tourist.wear_id
	if(istype(visitor_card))
		visitor_card.registered_name = tourist.real_name
		visitor_card.update_label()
	var/obj/item/tour_guidebook/guide = new(tourist, attractions, tour)
	guide.set_owner(tourist)
	if(!tourist.put_in_hands(guide) && !tourist.equip_to_slot_if_possible(guide, ITEM_SLOT_BACKPACK, disable_warning = TRUE))
		guide.forceMove(tourist.drop_location())
	return guide

/// Баллоны вида из рук уходят в слоты, чтобы путеводитель и фотоаппарат было чем держать.
/datum/round_event/ghost_role/tour_group/proc/stow_held_tanks(mob/living/carbon/human/tourist)
	var/obj/item/tank/breathing = tourist.internal
	for(var/obj/item/tank/tank in tourist.held_items)
		var/list/slots = tank == breathing ? list(ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE) : list(ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE, ITEM_SLOT_BACKPACK)
		for(var/slot in slots)
			if(tourist.equip_to_slot_if_possible(tank, slot, disable_warning = TRUE))
				break
	if(breathing?.loc == tourist)
		tourist.internal = breathing
		tourist.update_action_buttons_icon()

/datum/outfit/star_route_tourist
	name = "Star Route Tourist"
	uniform = /obj/item/clothing/under/shorts/blue
	suit = /obj/item/clothing/suit/toggle/jacket/hawaiian/orange
	shoes = /obj/item/clothing/shoes/sandal
	glasses = /obj/item/clothing/glasses/sunglasses/fake
	neck = /obj/item/camera
	ears = /obj/item/radio/headset
	back = /obj/item/storage/backpack/satchel
	backpack_contents = list(/obj/item/storage/box/survival = 1, /obj/item/camera_film = 1)
	l_pocket = /obj/item/stack/spacecash/c200
	id = /obj/item/card/id/star_route_visitor

/datum/outfit/star_route_tourist/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	. = ..()
	uniform = pick(/obj/item/clothing/under/shorts/blue, /obj/item/clothing/under/shorts/red, /obj/item/clothing/under/shorts/green, /obj/item/clothing/under/pants/jeanshort)
	suit = pick(/obj/item/clothing/suit/toggle/jacket/hawaiian/orange, /obj/item/clothing/suit/toggle/jacket/hawaiian/vine, /obj/item/clothing/suit/toggle/jacket/hawaiian/motu, /obj/item/clothing/suit/toggle/jacket/hawaiian/fuch)

/obj/item/card/id/star_route_visitor
	assignment = "Visitor"
	desc = "Гостевая карта агентства «Звёздный маршрут». Доступа в помещения станции не даёт."

/datum/mood_event/star_route_tour
	description = "<span class='nicegreen'>Маршрут пройден, сувенир у меня. Отличная поездка!</span>\n"
	mood_change = 4
	timeout = 10 MINUTES

/obj/item/tour_guidebook
	name = "Star Route guidebook"
	desc = "Путеводитель агентства «Звёздный маршрут» по станции NanoTrasen: схема палуб, советы гостям и страницы под штампы. Штампы ставит экипаж станции: сотрудник касается туриста ID-картой в отсеке маршрута."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/tour_group.dmi'
	icon_state = "guidebook"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	item_state = "book"
	w_class = WEIGHT_CLASS_SMALL
	drop_sound = 'sound/items/handling/book_drop.ogg'
	pickup_sound = 'sound/items/handling/book_pickup.ogg'
	/// Подпись остановки -> корневые типы её отсека.
	var/list/attractions = list()
	var/list/stamped = list()
	var/list/stampers = list()
	var/opened = FALSE
	var/souvenir_given = FALSE
	var/mob/living/carbon/human/owner
	var/datum/star_route_tour/tour
	var/static/list/reviews = list(
		"Экипаж приветливый, станция ни разу не загорелась при нас. Пять звёзд.",
		"Гид знал каждый закоулок и ни разу не завёл нас в техи.",
		"Жаль, что в служебные помещения не пускают, но и так было интересно.",
		"Обязательно вернусь, если страховая разрешит.",
		"Лучшая станция маршрута. Ну, единственная, но всё равно лучшая.",
	)

/obj/item/tour_guidebook/Initialize(mapload, list/route, datum/star_route_tour/group_tour)
	. = ..()
	if(length(route))
		attractions = route.Copy()
	tour = group_tour

/obj/item/tour_guidebook/Destroy()
	set_owner(null)
	tour = null
	return ..()

/// Штампы ставят туристу, а не путеводителю: подписываемся на касания и настроение владельца.
/obj/item/tour_guidebook/proc/set_owner(mob/living/carbon/human/new_owner)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_ATOM_ITEM_INTERACTION, COMSIG_ADD_MOOD_EVENT, COMSIG_PARENT_QDELETING))
	owner = new_owner
	if(!owner)
		return
	RegisterSignal(owner, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_owner_touched))
	RegisterSignal(owner, COMSIG_ADD_MOOD_EVENT, PROC_REF(on_owner_mood))
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))

/obj/item/tour_guidebook/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	set_owner(null)

/obj/item/tour_guidebook/proc/carried()
	return owner && get(src, /mob/living) == owner

/// Первая непроштампованная остановка, в отсеке которой или у входа в который стоит владелец.
/obj/item/tour_guidebook/proc/attraction_here(only_label)
	var/turf/spot = get_turf(owner)
	if(!spot)
		return null
	for(var/turf/nearby as anything in RANGE_TURFS(1, spot))
		var/area/nearby_area = nearby.loc
		for(var/label in attractions)
			if(stamped[label] || (only_label && label != only_label))
				continue
			if(tour_area_matches(nearby_area, attractions[label]))
				return label
	return null

/obj/item/tour_guidebook/proc/on_owner_touched(datum/source, mob/living/user, obj/item/tool, params)
	SIGNAL_HANDLER
	if(user == owner || !carried())
		return NONE
	if(istype(tool, /obj/item/storage/book/bible))
		if(!user.mind?.isholy)
			return NONE
		var/chapel = attraction_here(TOUR_STOP_CHAPEL)
		if(!chapel)
			return NONE
		stamp_attraction(chapel, user, "благословляет [owner] и ставит в путеводитель штамп «[chapel]».")
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	if(istype(tool, /obj/item/book))
		var/obj/item/card/id/card = user.get_idcard(TRUE)
		if(!card || !(ACCESS_LIBRARY in card.GetAccess()))
			return NONE
		var/library = attraction_here(TOUR_STOP_LIBRARY)
		if(!library)
			return NONE
		if(user.temporarilyRemoveItemFromInventory(tool))
			INVOKE_ASYNC(src, PROC_REF(hand_over), tool)
		stamp_attraction(library, user, "выдаёт [owner] книгу [tool] и ставит в путеводитель штамп «[library]».")
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	if(!tool.GetID())
		return NONE
	var/bare_card = istype(tool, /obj/item/card/id)
	if(!is_effective_crew_mob(user))
		if(bare_card)
			to_chat(user, span_warning("Штампы в путеводитель ставит только экипаж станции."))
		return bare_card ? TOOL_ACT_MELEE_CHAIN_BLOCKING : NONE
	var/label = attraction_here()
	if(!label)
		if(bare_card)
			to_chat(user, span_notice("[owner] сейчас не в отсеке из маршрута: штамп ставится в отсеке или у его входа."))
		return bare_card ? TOOL_ACT_MELEE_CHAIN_BLOCKING : NONE
	stamp_attraction(label, user, "прикладывает ID-карту к путеводителю [owner] и ставит штамп «[label]».")
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/obj/item/tour_guidebook/proc/hand_over(obj/item/gift)
	if(!owner?.put_in_hands(gift))
		gift.forceMove(owner ? owner.drop_location() : drop_location())

/obj/item/tour_guidebook/proc/on_owner_mood(datum/source, category, type, param)
	SIGNAL_HANDLER
	if(!carried())
		return
	switch(category)
		if("quality_drink")
			var/bar = attraction_here(TOUR_STOP_BAR)
			if(bar)
				stamp_attraction(bar, null, "В путеводитель [owner] ложится штамп «[bar]»: коктейль оценён по достоинству.")
		if("arcade")
			var/arcade = attraction_here(TOUR_STOP_ARCADE)
			if(arcade)
				stamp_attraction(arcade, null, "Автомат выдаёт [owner] призовой штамп «[arcade]».")

/obj/item/tour_guidebook/proc/stamp_attraction(label, mob/living/stamper, action_text)
	if(!label || stamped[label] || !(label in attractions))
		return FALSE
	stamped[label] = TRUE
	if(stamper)
		stampers |= stamper.name
		owner.visible_message(span_notice("[stamper] [action_text]"))
	else
		owner.visible_message(span_notice(action_text))
	playsound(src, 'sound/items/handling/standard_stamp.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
	to_chat(owner, span_notice("Штамп «[label]»: собрано [length(stamped)] из [length(attractions)]."))
	var/mob/living/carbon/human/guide = find_guide(stamper)
	tour?.pay_guide(label, guide)
	update_appearance()
	log_game("DIRECTOR: Tour Group, [key_name(owner)] получает штамп «[label]»[stamper ? " от [key_name(stamper)]" : ""].")
	if(length(stamped) >= length(attractions))
		INVOKE_ASYNC(src, PROC_REF(complete_route))
	return TRUE

/// Гид - ближайший к туристу сотрудник станции со счётом, кроме того, кто ставит штамп.
/obj/item/tour_guidebook/proc/find_guide(mob/living/stamper)
	var/mob/living/carbon/human/guide
	var/guide_distance = INFINITY
	for(var/mob/living/carbon/human/candidate in range(TOUR_GUIDE_RANGE, owner))
		if(candidate == owner || candidate == stamper || candidate.stat != CONSCIOUS || !is_effective_crew_mob(candidate) || !candidate.get_bank_account())
			continue
		var/distance = get_dist(candidate, owner)
		if(distance < guide_distance)
			guide = candidate
			guide_distance = distance
	return guide

/obj/item/tour_guidebook/proc/complete_route()
	if(!give_souvenir(owner))
		return FALSE
	var/paid = minor_service_pay_budget(TOUR_SERVICE_REWARD, "«Звёздный маршрут»: турист прошёл весь маршрут")
	var/thanks = length(stampers) ? " Спасибо за штампы: [jointext(stampers, ", ")]." : ""
	paperwork_radio("Отзыв «Звёздного маршрута»: [owner.real_name] прошёл весь маршрут - [jointext(attractions, ", ")]. «[pick(reviews)]»[thanks][paid ? " В бюджет сервиса переведено [TOUR_SERVICE_REWARD] кредитов." : ""]", RADIO_CHANNEL_SERVICE)
	tour?.release(owner.mind)
	log_game("DIRECTOR: Tour Group, [key_name(owner)] прошёл маршрут[paid ? ", в бюджет сервиса переведено [TOUR_SERVICE_REWARD] кр." : ""].")
	return TRUE

/obj/item/tour_guidebook/update_icon_state()
	icon_state = opened ? "guidebook_open" : "guidebook"
	return ..()

/obj/item/tour_guidebook/update_overlays()
	. = ..()
	if(!opened)
		return
	for(var/stamp_index in 1 to min(length(stamped), TOUR_MAX_ATTRACTIONS))
		. += "guidebook_stamp_[stamp_index]"

/obj/item/tour_guidebook/examine(mob/user)
	. = ..()
	. += route_text()

/obj/item/tour_guidebook/attack_self(mob/user)
	. = ..()
	playsound(src, pick('sound/effects/pageturn1.ogg', 'sound/effects/pageturn2.ogg', 'sound/effects/pageturn3.ogg'), 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	opened = !opened
	update_appearance()
	if(opened)
		to_chat(user, examine_block(route_text()))

/obj/item/tour_guidebook/proc/route_text()
	if(!length(attractions))
		return span_notice("Страницы маршрута пусты: в агентстве забыли вписать экскурсию.")
	var/list/lines = list("<b>Экскурсия «Звёздного маршрута»</b>, штампов [length(stamped)] из [length(attractions)]:")
	for(var/label in attractions)
		lines += "[stamped[label] ? "\[штамп\]" : "\[    \]"] [label]"
	if(souvenir_given)
		lines += "Маршрут пройден, сувенир получен."
	else
		lines += "Штамп ставит сотрудник станции: в отсеке маршрута или у его входа он касается туриста ID-картой. В баре штамп даёт хороший коктейль, в часовне - благословение священника, в библиотеке - книга от библиотекаря."
		lines += "Сотрудник, который сопровождает группу, получает от агентства [TOUR_GUIDE_REWARD] кредитов за каждую новую остановку."
	return jointext(lines, "<br>")

/obj/item/tour_guidebook/proc/give_souvenir(mob/user)
	if(souvenir_given || !user)
		return FALSE
	souvenir_given = TRUE
	var/obj/item/tour_snowglobe/globe = new(drop_location())
	user.put_in_hands(globe)
	SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "star_route_tour", /datum/mood_event/star_route_tour)
	to_chat(user, span_nicegreen("Маршрут пройден! Из кармашка на обложке выпадает сувенир агентства - снежный шар со станцией."))
	return TRUE

/obj/item/tour_snowglobe
	name = "station snow globe"
	desc = "Сувенир агентства «Звёздный маршрут»: в стеклянном шаре крошечная станция NanoTrasen и искусственный снег. Встряхните его (используйте в руке), чтобы поднять метель."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/tour_group.dmi'
	icon_state = "snowglobe"
	item_state = "beaker"
	w_class = WEIGHT_CLASS_SMALL
	drop_sound = 'sound/items/handling/drinkglass_drop.ogg'
	pickup_sound = 'sound/items/handling/drinkglass_pickup.ogg'
	COOLDOWN_DECLARE(shake_cooldown)

/obj/item/tour_snowglobe/attack_self(mob/user)
	. = ..()
	if(!COOLDOWN_FINISHED(src, shake_cooldown))
		return
	COOLDOWN_START(src, shake_cooldown, TOUR_SHAKE_COOLDOWN)
	flick("snowglobe_shake", src)
	playsound(src, 'sound/items/handling/drinkglass_pickup.ogg', 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	user.visible_message(span_notice("[user] встряхивает [src], и над крошечной станцией поднимается метель."), span_notice("Вы встряхиваете [src]. Над крошечной станцией кружит снег."))

#undef TOUR_GROUP_MIN_SIZE
#undef TOUR_GROUP_MAX_SIZE
#undef TOUR_MIN_ATTRACTIONS
#undef TOUR_MAX_ATTRACTIONS
#undef TOUR_GHOST_ROLE
#undef TOUR_GUIDE_RANGE
#undef TOUR_GUIDE_REWARD
#undef TOUR_SERVICE_REWARD
#undef TOUR_LENGTH_MINUTES
#undef TOUR_LENGTH
#undef TOUR_SHAKE_COOLDOWN
#undef TOUR_STOP_BAR
#undef TOUR_STOP_CHAPEL
#undef TOUR_STOP_LIBRARY
#undef TOUR_STOP_ARCADE
