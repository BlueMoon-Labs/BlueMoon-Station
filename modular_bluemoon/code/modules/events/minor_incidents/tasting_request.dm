#define TASTING_DEADLINE (25 MINUTES)
#define TASTING_PICKUP_DELAY (5 SECONDS)
#define TASTING_BUDGET_REWARD 400
#define TASTING_PERSONAL_REWARD 150
#define TASTING_COCKTAIL_VOLUME 30
#define TASTING_MODE_DISH "dish"
#define TASTING_MODE_COCKTAIL "cocktail"
#define COURIER_DROP_HEIGHT 320

/datum/round_event_control/station_incident/service/tasting_request
	name = "Tasting Request"
	typepath = /datum/round_event/station_incident/service/tasting_request
	family = "tasting_request"
	min_players = 5
	announcement_title = "Служба корпоративного питания NanoTrasen"
	var/list/kitchen_area_types = list(/area/service/kitchen)
	var/list/bar_area_types = list(/area/service/bar)

/datum/round_event_control/station_incident/service/tasting_request/New()
	. = ..()
	area_groups = list(kitchen_area_types, bar_area_types)
	description = "ЦК или проходящий лайнер заказывает блюдо средней сложности, а если на смене есть бармен и нет повара - коктейль. Капсула привозит термокейс с карточкой заказа; надкусанное блюдо не принимается, запечатанный кейс с заказом за [DisplayTimeText(TASTING_DEADLINE)] забирает курьер, бюджет сервиса получает [TASTING_BUDGET_REWARD] кредитов, запечатавший - [TASTING_PERSONAL_REWARD]."

/datum/round_event_control/station_incident/service/tasting_request/director_preflight()
	if(!director_has_living_role(list("Cook", "Bartender")))
		director_preflight_detail = "На смене нет ни повара, ни бармена."
		director_preflight_failure = director_preflight_detail
		return FALSE
	return ..()

/datum/round_event/station_incident/service/tasting_request
	var/mode
	var/order_path
	var/order_name
	var/client_name
	var/client_from
	var/static/list/dish_orders = list(
		/obj/item/reagent_containers/food/snacks/khachapuri = "хачапури",
		/obj/item/reagent_containers/food/snacks/benedict = "яйца Бенедикт",
		/obj/item/reagent_containers/food/snacks/meatballspaghetti = "спагетти с фрикадельками",
		/obj/item/reagent_containers/food/snacks/pie/meatpie = "мясной пирог",
		/obj/item/reagent_containers/food/snacks/pizza/margherita = "пицца «Маргарита»",
		/obj/item/reagent_containers/food/snacks/soup/meatball = "суп с фрикадельками",
		/obj/item/reagent_containers/food/snacks/enchiladas = "энчиладас",
		/obj/item/reagent_containers/food/snacks/hotdog = "хот-дог",
	)
	var/static/list/cocktail_orders = list(
		/datum/reagent/consumable/ethanol/manhattan = "коктейль «Манхэттен»",
		/datum/reagent/consumable/ethanol/margarita = "коктейль «Маргарита»",
		/datum/reagent/consumable/ethanol/tequila_sunrise = "коктейль «Текила санрайз»",
		/datum/reagent/consumable/ethanol/b52 = "коктейль «Би-52»",
		/datum/reagent/consumable/ethanol/bloody_mary = "коктейль «Кровавая Мэри»",
		/datum/reagent/consumable/ethanol/whiskey_sour = "коктейль «Виски сауэр»",
		/datum/reagent/consumable/ethanol/longislandicedtea = "коктейль «Лонг-Айленд»",
		/datum/reagent/consumable/ethanol/between_the_sheets = "коктейль «Между простынями»",
	)
	var/static/list/clients = list(
		"Центральное командование" = "от Центрального командования",
		"Лайнер «Северное сияние»" = "с лайнера «Северное сияние»",
		"Лайнер «Каллисто-экспресс»" = "с лайнера «Каллисто-экспресс»",
		"Кают-компания флагмана «Гарантия»" = "из кают-компании флагмана «Гарантия»",
	)

/datum/round_event/station_incident/service/tasting_request/start()
	var/datum/round_event_control/station_incident/service/tasting_request/incident = control
	if(!istype(incident))
		return
	var/list/kitchen_floors = incident.find_floors(incident.kitchen_area_types)
	var/list/bar_floors = incident.find_floors(incident.bar_area_types)
	mode = choose_mode(director_has_living_role(list("Cook")), director_has_living_role(list("Bartender")), length(kitchen_floors), length(bar_floors))
	if(!mode)
		return
	var/turf/target = pick(mode == TASTING_MODE_DISH ? kitchen_floors : bar_floors)
	choose_order()
	incident_area_name = get_area_name(target, TRUE)
	if(apply_effect(target))
		affected_count = 1
		log_game("DIRECTOR: [control.name], отсек [incident_area_name], заказ [order_name] для [client_name].")

/datum/round_event/station_incident/service/tasting_request/announce(fake)
	if(!affected_count)
		return
	if(mode == TASTING_MODE_COCKTAIL)
		priority_announce("Поступил дегустационный заказ [client_from]: [order_name]. Термокейс с карточкой заказа уже летит в бар: налейте в стакан не меньше [TASTING_COCKTAIL_VOLUME] единиц, поставьте его в кейс и запечатайте в течение [DisplayTimeText(TASTING_DEADLINE)]. Курьер заберёт кейс сам, оплата поступит сервису и тому, кто запечатал. Отсек: [incident_area_name].", announcement_title())
		return
	priority_announce("Поступил дегустационный заказ [client_from]: [order_name]. Термокейс с карточкой заказа уже летит на кухню: положите целое готовое блюдо внутрь и запечатайте кейс в течение [DisplayTimeText(TASTING_DEADLINE)]. Курьер заберёт его сам, оплата поступит сервису и тому, кто запечатал. Отсек: [incident_area_name].", announcement_title())

/// Коктейль - только когда бар работает, а кухня пустует; иначе блюдо, если есть кухня.
/datum/round_event/station_incident/service/tasting_request/proc/choose_mode(has_cook, has_bartender, has_kitchen, has_bar)
	if(has_bar && has_bartender && !has_cook)
		return TASTING_MODE_COCKTAIL
	if(has_kitchen)
		return TASTING_MODE_DISH
	if(has_bar)
		return TASTING_MODE_COCKTAIL
	return null

/// Русское название и игровое имя рецепта, по которому его ищут в книге.
/datum/round_event/station_incident/service/tasting_request/proc/choose_order()
	var/list/menu = mode == TASTING_MODE_COCKTAIL ? cocktail_orders : dish_orders
	order_path = pick(menu)
	var/game_name
	if(mode == TASTING_MODE_COCKTAIL)
		var/datum/reagent/drink = order_path
		game_name = initial(drink.name)
	else
		var/obj/item/dish = order_path
		game_name = initial(dish.name)
	order_name = "[menu[order_path]] ([game_name])"
	client_name = pick(clients)
	client_from = clients[client_name]

/datum/round_event/station_incident/service/tasting_request/pack_shipment(obj/structure/closet/supplypod/pod)
	var/obj/item/minor_tasting_case/case = new(pod)
	case.set_order(mode, order_path, order_name, client_name)
	var/obj/item/paper/card = new(pod)
	card.name = "paper - 'Tasting order'"
	card.add_raw_text(case.order_card_text())
	card.update_appearance()

/obj/item/minor_tasting_case
	name = "insulated tasting case"
	desc = "Термокейс курьерской службы с охлаждающим вкладышем и пломбой на защёлке."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/tasting_request.dmi'
	icon_state = "case_open"
	lefthand_file = 'icons/mob/inhands/equipment/briefcase_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/briefcase_righthand.dmi'
	item_state = "sec-case"
	w_class = WEIGHT_CLASS_BULKY
	var/order_mode
	var/order_path
	var/order_name
	var/order_client
	var/cooling = FALSE
	var/sealed = FALSE
	var/delivered = FALSE
	var/deadline_at = 0
	var/deadline_timer
	var/pickup_timer
	var/datum/weakref/sealer_ref

/obj/item/minor_tasting_case/Destroy()
	deltimer(deadline_timer)
	deltimer(pickup_timer)
	deadline_timer = null
	pickup_timer = null
	return ..()

/obj/item/minor_tasting_case/proc/set_order(mode, path, name_text, client)
	order_mode = mode
	order_path = path
	order_name = name_text
	order_client = client
	cooling = TRUE
	deadline_at = world.time + TASTING_DEADLINE
	deltimer(deadline_timer)
	deadline_timer = addtimer(CALLBACK(src, PROC_REF(expire)), TASTING_DEADLINE, TIMER_STOPPABLE)
	update_appearance()

/obj/item/minor_tasting_case/proc/order_text()
	return order_mode == TASTING_MODE_COCKTAIL ? "[order_name], не меньше [TASTING_COCKTAIL_VOLUME] единиц в стакане" : order_name

/obj/item/minor_tasting_case/proc/order_card_text()
	return "СЛУЖБА КОРПОРАТИВНОГО ПИТАНИЯ NANOTRASEN<br>Карточка дегустационного заказа<br><br>Заказчик: [order_client].<br>Заказ: [order_text()].<br>Срок: [DisplayTimeText(TASTING_DEADLINE)] с момента доставки, пока горит индикатор охлаждения.<br><br>Положите заказ в термокейс и запечатайте его, нажав на кейс в руке[order_mode == TASTING_MODE_DISH ? "; надкусанное блюдо курьер не примет" : ""]. Курьер заберёт кейс через несколько секунд. Оплата: [TASTING_BUDGET_REWARD] кредитов бюджету сервиса и [TASTING_PERSONAL_REWARD] кредитов тому, кто запечатал кейс."

/obj/item/minor_tasting_case/proc/get_stored()
	return locate(/obj/item) in contents

/obj/item/minor_tasting_case/examine(mob/user)
	. = ..()
	if(order_path)
		. += span_notice("Заказ: [order_text()]. Заказчик: [order_client].")
	var/obj/item/stored = get_stored()
	if(stored)
		. += span_notice("Внутри лежит [stored.name].")
	if(delivered)
		return
	if(sealed)
		. += span_notice("Кейс запечатан и ждёт курьера.")
		return
	if(!cooling)
		. += span_warning("Индикатор охлаждения погас: заказ отменён.")
		return
	. += span_notice("Индикатор охлаждения горит, до отмены заказа: [DisplayTimeText(max(deadline_at - world.time, 0), 60)].")
	. += span_notice("Положите заказ внутрь и нажмите на кейс в руке, чтобы запечатать. Alt+клик достаёт содержимое.")

/obj/item/minor_tasting_case/update_icon_state()
	icon_state = sealed ? "case_closed" : "case_open"
	return ..()

/obj/item/minor_tasting_case/update_overlays()
	. = ..()
	var/obj/item/stored = get_stored()
	if(stored && !sealed)
		var/mutable_appearance/dish = new(stored)
		dish.plane = FLOAT_PLANE
		dish.layer = FLOAT_LAYER
		dish.pixel_x = 0
		dish.pixel_y = 1
		dish.transform = matrix().Scale(0.55)
		. += dish
		. += "case_lip"
	if(sealed || delivered)
		. += "led_sealed"
	else if(cooling)
		. += "led_cold"
	else
		. += "led_off"

/obj/item/minor_tasting_case/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/reagent_containers/food))
		return ..()
	insert_item(item, user)
	return TRUE

/obj/item/minor_tasting_case/AltClick(mob/user)
	. = ..()
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	eject_item(user)
	return TRUE

/obj/item/minor_tasting_case/attack_self(mob/user)
	try_seal(user)

/obj/item/minor_tasting_case/proc/insert_item(obj/item/item, mob/living/user)
	if(!istype(item, /obj/item/reagent_containers/food))
		to_chat(user, span_warning("В термокейс кладут только блюда и напитки."))
		return FALSE
	if(sealed || delivered)
		to_chat(user, span_warning("Кейс уже запечатан."))
		return FALSE
	if(!cooling)
		to_chat(user, span_warning("Индикатор охлаждения погас: заказ отменён, кейс больше ничего не принимает."))
		return FALSE
	if(get_stored())
		to_chat(user, span_warning("В кейсе уже что-то лежит. Alt+клик достаёт содержимое."))
		return FALSE
	if(user && !user.transferItemToLoc(item, src))
		return FALSE
	if(!user)
		item.forceMove(src)
	to_chat(user, span_notice("Вы ставите [item] в термокейс."))
	update_appearance()
	return TRUE

/obj/item/minor_tasting_case/proc/eject_item(mob/living/user)
	if(sealed || delivered)
		to_chat(user, span_warning("Пломба уже стоит, кейс не открыть."))
		return FALSE
	var/obj/item/stored = get_stored()
	if(!stored)
		to_chat(user, span_notice("Кейс пуст."))
		return FALSE
	stored.forceMove(drop_location())
	user?.put_in_hands(stored)
	update_appearance()
	return TRUE

/// Причина отказа или null, если содержимое подходит к заказу.
/obj/item/minor_tasting_case/proc/check_contents()
	var/obj/item/stored = get_stored()
	if(!stored)
		return "Кейс пуст: сначала положите внутрь заказ."
	if(order_mode == TASTING_MODE_COCKTAIL)
		if(!istype(stored, /obj/item/reagent_containers/food/drinks/drinkingglass))
			return "Коктейль подают в стакане, а не в [stored.name]."
		var/amount = stored.reagents.get_reagent_amount(order_path)
		if(!amount)
			return "В стакане не тот напиток. Заказ: [order_name]."
		if(amount < TASTING_COCKTAIL_VOLUME)
			return "Заказанного коктейля в стакане [round(amount, 0.1)] ед., а нужно не меньше [TASTING_COCKTAIL_VOLUME]."
		return null
	if(stored.type != order_path)
		return "Курьер примет только заказанное блюдо: [order_name]."
	var/obj/item/reagent_containers/food/snacks/dish = stored
	if(istype(dish) && dish.bitecount)
		return "Блюдо надкусано, а курьер примет только нетронутое."
	return null

/obj/item/minor_tasting_case/proc/try_seal(mob/living/user)
	if(sealed || delivered)
		to_chat(user, span_notice("Кейс уже запечатан и ждёт курьера."))
		return FALSE
	if(!cooling)
		to_chat(user, span_warning("Индикатор охлаждения погас: заказ отменён."))
		return FALSE
	var/problem = check_contents()
	if(problem)
		to_chat(user, span_warning("Защёлка не встаёт в пломбу. [problem]"))
		balloon_alert(user, "не то содержимое")
		return FALSE
	seal(user)
	return TRUE

/obj/item/minor_tasting_case/proc/seal(mob/living/user)
	sealed = TRUE
	sealer_ref = WEAKREF(user)
	deltimer(deadline_timer)
	deadline_timer = null
	update_appearance()
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	user?.visible_message(span_notice("[user] защёлкивает пломбу на [src]."), span_notice("Вы защёлкиваете пломбу. Индикатор загорается зелёным: курьер уже в пути."))
	pickup_timer = addtimer(CALLBACK(src, PROC_REF(call_courier)), TASTING_PICKUP_DELAY, TIMER_STOPPABLE)
	log_game("DIRECTOR: Tasting Request, кейс запечатан [key_name(user)] в [get_area_name(src, TRUE)], заказ [order_name].")

/obj/item/minor_tasting_case/proc/call_courier()
	deltimer(pickup_timer)
	pickup_timer = null
	if(delivered)
		return FALSE
	var/turf/spot = get_turf(src)
	if(!spot)
		complete_delivery()
		qdel(src)
		return TRUE
	new /obj/effect/minor_courier_pod(spot, src)
	return TRUE

/// Оплата заказа; повторный вызов ничего не начисляет.
/obj/item/minor_tasting_case/proc/complete_delivery()
	if(delivered)
		return FALSE
	delivered = TRUE
	minor_service_pay_budget(TASTING_BUDGET_REWARD, "[order_client]: оплата дегустационного заказа")
	var/mob/living/sealer = sealer_ref?.resolve()
	var/datum/bank_account/account = minor_service_account_of(sealer)
	if(account)
		account.adjust_money(TASTING_PERSONAL_REWARD, "[order_client]: чаевые за дегустационный заказ")
		account.bank_card_talk("Получено [TASTING_PERSONAL_REWARD] кр. чаевых за дегустационный заказ.")
	minor_announce("Заказ доставлен. Отзыв заказчика ([order_client]): «[pick("Подача безупречная, курьер просил добавки.", "Дегустаторы спорят, кому достался последний кусок.", "Передайте мастеру наше почтение и попросите рецепт.", "Ровно то, что нужно после долгого перелёта.")]» Бюджет сервиса получает [TASTING_BUDGET_REWARD] кредитов.", "Служба корпоративного питания NanoTrasen")
	log_game("DIRECTOR: Tasting Request, заказ [order_name] доставлен, бюджету сервиса [TASTING_BUDGET_REWARD] кр., [key_name(sealer)] [account ? "получил [TASTING_PERSONAL_REWARD] кр." : "без счёта"].")
	return TRUE

/obj/item/minor_tasting_case/proc/expire()
	deadline_timer = null
	if(sealed || delivered || !cooling)
		return FALSE
	cooling = FALSE
	update_appearance()
	visible_message(span_warning("Индикатор охлаждения на [src] мигает и гаснет. Заказ отменён."))
	log_game("DIRECTOR: Tasting Request, заказ [order_name] не выполнен за срок, отменён.")
	return TRUE

/// Курьер падает на клетку кейса, забирает его и улетает; оплата приходит в момент загрузки.
/obj/effect/minor_courier_pod
	name = "courier pod"
	desc = "Курьерская капсула ЦК. Задерживаться не собирается."
	icon = 'icons/obj/supplypods.dmi'
	icon_state = "centcompod_falling"
	pixel_x = -16
	layer = FLY_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/obj/item/minor_tasting_case/cargo
	var/step_timer

/obj/effect/minor_courier_pod/Initialize(mapload, obj/item/minor_tasting_case/case)
	. = ..()
	if(!istype(case))
		return INITIALIZE_HINT_QDEL
	cargo = case
	pixel_z = COURIER_DROP_HEIGHT
	animate(src, pixel_z = 0, time = 0.6 SECONDS, easing = QUAD_EASING|EASE_IN)
	playsound(src, 'sound/weapons/mortar_whistle.ogg', 40, TRUE)
	step_timer = addtimer(CALLBACK(src, PROC_REF(touch_down)), 0.6 SECONDS, TIMER_STOPPABLE)

/obj/effect/minor_courier_pod/Destroy()
	deltimer(step_timer)
	step_timer = null
	QDEL_NULL(cargo)
	return ..()

/obj/effect/minor_courier_pod/proc/touch_down()
	icon_state = "centcompod"
	playsound(src, 'sound/effects/bang.ogg', 25, TRUE)
	step_timer = addtimer(CALLBACK(src, PROC_REF(load_cargo)), 1 SECONDS, TIMER_STOPPABLE)

/obj/effect/minor_courier_pod/proc/load_cargo()
	if(!QDELETED(cargo))
		if(ismob(cargo.loc))
			var/mob/holder = cargo.loc
			holder.temporarilyRemoveItemFromInventory(cargo, TRUE)
		cargo.forceMove(src)
		cargo.complete_delivery()
	add_overlay("centcompod_door")
	playsound(src, 'sound/machines/blastdoor.ogg', 30, TRUE)
	step_timer = addtimer(CALLBACK(src, PROC_REF(depart)), 0.6 SECONDS, TIMER_STOPPABLE)

/obj/effect/minor_courier_pod/proc/depart()
	cut_overlays()
	icon_state = "centcompod_falling"
	animate(src, pixel_z = COURIER_DROP_HEIGHT, alpha = 0, time = 1 SECONDS, easing = QUAD_EASING|EASE_IN)
	step_timer = addtimer(CALLBACK(src, PROC_REF(leave)), 1 SECONDS, TIMER_STOPPABLE)

/obj/effect/minor_courier_pod/proc/leave()
	step_timer = null
	qdel(src)

#undef TASTING_DEADLINE
#undef TASTING_PICKUP_DELAY
#undef TASTING_BUDGET_REWARD
#undef TASTING_PERSONAL_REWARD
#undef TASTING_COCKTAIL_VOLUME
#undef TASTING_MODE_DISH
#undef TASTING_MODE_COCKTAIL
#undef COURIER_DROP_HEIGHT
