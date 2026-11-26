/proc/heretic_side_bearer(mob/user)
	return isliving(user) && (IS_HERETIC(user) || IS_HERETIC_MONSTER(user))

/datum/eldritch_knowledge/eldritch_coin
	name = "Монета изнанки"
	summary = "Голочип и лист железа дают монету: подброшенная у шлюза, она открывает, закрывает или болтирует его."
	details = list(
		"Подбросьте монету у шлюза, хоть по диагонали: на любом намерении, кроме «Вреда», он откроется или закроется.",
		"На «Вреде» монета опускает или поднимает болты; с перерезанным проводом болтов не выйдет.",
		"Нужно питание; заваренные шлюзы, хранилище и двери высокой защиты монета не трогает.",
		"Подбрасывать можно раз в 4 секунды; в наручниках и под щитом разума монета молчит.",
		"Неверному каждый подброс бьёт по мозгам: 10 урона мозгу.",
	)
	role = HERETIC_ROLE_RELIC
	ritual_hints = list(
		"Положите голочип с любой суммой и лист железа в клетку от центра руны; оба израсходуются.",
	)
	gain_text = "Каждая дверь берёт плату. Я наконец узнал, какой монетой."
	cost = 1
	required_atoms = list(/obj/item/holochip, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/coin/eldritch)

/obj/item/coin/eldritch
	name = "eldritch coin"
	desc = "Тяжёлая монета из тёмного металла: на одной стороне глаз, на другой клинок. Тёплая, будто её только что держали в кулаке."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	icon_state = "coin_heretic"
	sideslist = list("heretic", "blade")
	custom_materials = null
	material_flags = NONE
	COOLDOWN_DECLARE(door_cooldown)

/obj/item/coin/eldritch/examine(mob/user)
	. = ..()
	. -= "<span class='info'>It's worth [value] credit\s.</span>"
	if(heretic_side_bearer(user))
		. += span_notice("Подбросьте её у шлюза: на «Вреде» она болтирует дверь, на любом другом намерении открывает или закрывает.")
	else
		. += span_warning("Стоит задержать на ней взгляд, и начинает ломить виски.")

/obj/item/coin/eldritch/after_coin_flip_success(mob/living/user)
	if(!isliving(user))
		return
	if(heretic_side_bearer(user))
		heretic_flip(user)
	else
		heathen_flip(user)

/// Сколько шлюзов рядом откликнулось на подброс.
/obj/item/coin/eldritch/proc/heretic_flip(mob/living/user)
	var/reason = heretic_containment_reason(user)
	if(reason)
		to_chat(user, span_warning(reason))
		return 0
	if(!COOLDOWN_FINISHED(src, door_cooldown))
		balloon_alert(user, "монета ещё звенит")
		return 0
	var/bolts = user.a_intent == INTENT_HARM
	var/moved = 0
	for(var/obj/machinery/door/airlock/door in range(1, get_turf(src)))
		if(coin_door(door, bolts))
			moved++
	if(!moved)
		balloon_alert(user, "шлюзы не слушаются")
		return 0
	COOLDOWN_START(src, door_cooldown, HERETIC_COIN_COOLDOWN)
	playsound(src, 'sound/magic/Knock.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
	log_game("[key_name(user)] монетой изнанки [bolts ? "переключил болты" : "открыл или закрыл"] шлюзов: [moved] в [AREACOORD(user)].")
	return moved

/obj/item/coin/eldritch/proc/coin_door(obj/machinery/door/airlock/door, bolts)
	if(QDELETED(door) || door.operating || !door.hasPower() || (door.resistance_flags & INDESTRUCTIBLE))
		return FALSE
	if(istype(door, /obj/machinery/door/airlock/vault) || istype(door, /obj/machinery/door/airlock/highsecurity))
		return FALSE
	if(bolts)
		if(door.wires?.is_cut(WIRE_BOLTS))
			return FALSE
		if(door.locked)
			door.unbolt()
		else
			door.bolt()
		return TRUE
	if(door.locked || door.welded)
		return FALSE
	if(door.density)
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open))
	else
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, close))
	return TRUE

/obj/item/coin/eldritch/proc/heathen_flip(mob/living/user)
	if(iscarbon(user))
		user.adjustOrganLoss(ORGAN_SLOT_BRAIN, HERETIC_COIN_BRAIN_DAMAGE, HERETIC_COIN_BRAIN_DAMAGE_MAX)
	to_chat(user, span_warning("Монета звенит прямо у вас в черепе, и мысли на миг рассыпаются."))

/datum/eldritch_knowledge/prophet_greaves
	name = "Поножи пророка"
	summary = "Обувь и лист железа дают поножи: в них еретик не поскальзывается и не падает от толчков."
	details = list(
		"На ногах еретика или его слуги поножи держат на мыле, смазке, льду и крови.",
		"Толчок не валит вас с ног и не выбивает вещь из рук.",
		"Броню поножи не дают: от ударов и пуль защищают не лучше обычных ботинок.",
		"Неверного поножи тянут к полу: он ходит медленнее, а держать равновесие они ему не помогают.",
	)
	role = HERETIC_ROLE_DEFENSE
	ritual_hints = list(
		"Положите любую пару обуви и лист железа в клетку от центра руны; оба израсходуются.",
	)
	gain_text = "Пророк шёл по воде и не оступился. Под его ногами тоже было скользко."
	cost = 1
	required_atoms = list(/obj/item/clothing/shoes, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/clothing/shoes/heretic_greaves)

/obj/item/clothing/shoes/heretic_greaves
	name = "prophet's greaves"
	desc = "Тяжёлые поножи из тёмного металла, по голенищу выгравированы закрытые глаза. Шагают уверенно, будто сами знают, куда ставить ногу."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/heretic_side_lore_worn.dmi'
	icon_state = "greaves"
	item_state = "jackboots"
	lefthand_file = 'icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing_righthand.dmi'
	mutantrace_variation = NONE
	strip_delay = 50
	equip_delay_other = 50
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/shoes/heretic_greaves/equipped(mob/user, slot)
	var/worn = slot == ITEM_SLOT_FEET
	var/bearer = worn && heretic_side_bearer(user)
	slowdown = (worn && !bearer) ? HERETIC_GREAVES_HEATHEN_SLOWDOWN : 0
	. = ..()
	if(bearer)
		ADD_TRAIT(user, TRAIT_NOSLIPALL, REF(src))
		ADD_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))
	else if(worn)
		to_chat(user, span_warning("Поножи наливаются свинцом: ноги еле отрываются от пола."))

/obj/item/clothing/shoes/heretic_greaves/dropped(mob/user)
	slowdown = 0
	. = ..()
	REMOVE_TRAIT(user, TRAIT_NOSLIPALL, REF(src))
	REMOVE_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))

/datum/eldritch_knowledge/amber_focus
	name = "Янтарный фокус"
	summary = "Лист стекла и глаза дают янтарную подвеску: на шее еретика она гасит ослепляющие вспышки."
	details = list(
		"Вспышки флешеров и светошумовых гранат не слепят вас и не валят с ног.",
		"Грохот светошумовой гранаты подвеска не глушит: оглушение от звука остаётся.",
		"Работает только на шее еретика или его слуги; в руке или в кармане подвеска не помогает.",
		"Неверному янтарь мутит взгляд, едва он наденет подвеску, а от вспышек не бережёт.",
	)
	role = HERETIC_ROLE_DEFENSE
	ritual_hints = list(
		"Положите лист стекла и пару глаз в клетку от центра руны; оба израсходуются.",
	)
	gain_text = "В янтаре застыл чужой взгляд. Теперь он смотрит на свет вместо меня."
	cost = 1
	required_atoms = list(/obj/item/stack/sheet/glass, /obj/item/organ/eyes)
	result_atoms = list(/obj/item/clothing/neck/heretic_focus)

/obj/item/clothing/neck/heretic_focus
	name = "amber focus"
	desc = "Капля тёплого янтаря на тёмной цепочке. Внутри застыл глаз, и он моргает, когда в комнате вспыхивает свет."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/heretic_side_lore_worn.dmi'
	icon_state = "amber_focus"
	item_state = "amber_focus"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_side_lore_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_side_lore_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/clothing/neck/heretic_focus/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_NECK)
		return
	if(heretic_side_bearer(user))
		ADD_TRAIT(user, TRAIT_NOFLASH, REF(src))
		return
	user.blur_eyes(HERETIC_FOCUS_HEATHEN_BLUR)
	to_chat(user, span_warning("Янтарь на груди теплеет, и всё вокруг плывёт, как сквозь смолу."))

/obj/item/clothing/neck/heretic_focus/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_NOFLASH, REF(src))

/datum/eldritch_knowledge/newborn_ether
	name = "Эфир новорождённого"
	summary = "Осколок стекла и рвота дают флакон: выпив его, еретик исцеляется полностью и засыпает."
	details = list(
		"Пить 3 секунды: флакон должен остаться в руке.",
		"Эфир снимает весь урон, раны, переломы, болезни, травмы мозга и вымывает из крови все вещества.",
		"Потерянные руки и ноги эфир не вернёт, мёртвого не поднимет.",
		"Затем 15 секунд вы спите беззащитным: пейте там, где вас не найдут.",
		"Неверному эфир - яд: 30 урона токсинами и рвота, без всякого лечения.",
	)
	role = HERETIC_ROLE_SUPPORT
	ritual_hints = list(
		"Нужна лужа рвоты на полу у руны и осколок стекла рядом; оба израсходуются.",
	)
	gain_text = "Всё, что из меня вышло, вернулось чистым. Так рождаются заново."
	cost = 2
	required_atoms = list(/obj/item/shard, /obj/effect/decal/cleanable/vomit)
	result_atoms = list(/obj/item/heretic_ether)

/obj/item/heretic_ether
	name = "ether of the newborn"
	desc = "Пузатый флакон с мутно-зелёной жидкостью, пробка вырезана в виде черепа. Пахнет детской присыпкой и чем-то сырым."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	icon_state = "ether"
	item_state = "beaker"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/heretic_ether/examine(mob/user)
	. = ..()
	if(heretic_side_bearer(user))
		. += span_notice("Выпейте, держа в руке: эфир исцелит всё, но потом вы [HERETIC_ETHER_SLEEP / (1 SECONDS)] секунд проспите.")

/obj/item/heretic_ether/attack_self(mob/living/user)
	if(!isliving(user))
		return
	user.visible_message(span_warning("[user] откупоривает [src] и подносит к губам."), span_notice("Вы откупориваете [src]."))
	if(!do_after(user, HERETIC_ETHER_DRINK_TIME, target = user) || QDELETED(src) || loc != user)
		return
	drink(user)

/obj/item/heretic_ether/proc/drink(mob/living/user)
	playsound(user, 'sound/items/drink.ogg', 50, TRUE)
	if(heretic_side_bearer(user))
		user.fully_heal(FALSE)
		user.Sleeping(HERETIC_ETHER_SLEEP)
		user.visible_message(span_warning("[user] осушает [src], раны на глазах затягиваются, и [user] валится в сон."), span_notice("Эфир смывает всю боль, и вас накрывает сон младенца."))
		log_game("[key_name(user)] выпил эфир новорождённого в [AREACOORD(user)].")
	else
		user.adjustToxLoss(HERETIC_ETHER_HEATHEN_TOX)
		to_chat(user, span_userdanger("Жидкость обжигает горло, и желудок выворачивает наизнанку."))
	qdel(src)

/datum/eldritch_knowledge/backdoor_keys
	name = "Ключи от чёрного хода"
	summary = "ID-карта и лом дают карту лабиринта: она связывает два шлюза тайным ходом для вас и ваших слуг."
	details = list(
		"Коснитесь картой одного шлюза, потом другого на той же палубе или станции: между ними откроется ход.",
		"Коснитесь картой связанного шлюза или пройдите в его проём шагом - и выйдете у другой двери.",
		"Выход там, где вы стояли, связывая дверь; бегом через проём вы просто проходите дверь.",
		"Карта держит 2 хода; новый стирает самый старый.",
		"Знак скважины на дверях виден всем: удар Библией или нулевым жезлом на «Вреде» стирает ход.",
		"Неверного карта обжигает: 10 ожога за попытку. В наручниках и под щитом не работает.",
	)
	role = HERETIC_ROLE_ESCAPE
	ritual_hints = list(
		"Положите любую ID-карту и лом в клетку от центра руны; оба израсходуются.",
	)
	gain_text = "У каждого дома есть дверь, которой не пользуются хозяева. Её открывают гости."
	cost = 2
	required_atoms = list(/obj/item/card/id, /obj/item/crowbar)
	result_atoms = list(/obj/item/heretic_backdoor_card)

/obj/item/heretic_backdoor_card
	name = "labyrinth card"
	desc = "Карта из тёмного пластика, похожая на пропуск. Вместо фотографии - лабиринт, и его ходы медленно меняются."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	icon_state = "backdoor_card"
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/pending_door
	var/pending_side
	/// Знаки ходов парами: первая и вторая дверь, старые первыми.
	var/list/portals = list()

/obj/item/heretic_backdoor_card/Destroy()
	for(var/obj/effect/heretic_backdoor/portal as anything in portals.Copy())
		qdel(portal)
	portals.Cut()
	pending_door = null
	return ..()

/obj/item/heretic_backdoor_card/examine(mob/user)
	. = ..()
	if(!heretic_side_bearer(user))
		return
	. += span_notice("Ходов: [length(portals) / 2] из [HERETIC_BACKDOOR_PAIRS]. Коснитесь картой двух шлюзов по очереди, чтобы связать их.")

/obj/item/heretic_backdoor_card/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(!istype(target, /obj/machinery/door/airlock))
		return ..()
	use_on_door(target, user)
	return STOP_ATTACK_PROC_CHAIN

/obj/item/heretic_backdoor_card/proc/use_on_door(obj/machinery/door/airlock/door, mob/living/user)
	if(!heretic_side_bearer(user))
		user.adjustFireLoss(HERETIC_BACKDOOR_CARD_BURN)
		to_chat(user, span_userdanger("Карта раскаляется в пальцах, и по ладони расползается ожог в форме лабиринта."))
		return FALSE
	var/reason = heretic_containment_reason(user)
	if(reason)
		to_chat(user, span_warning(reason))
		return FALSE
	var/obj/effect/heretic_backdoor/linked = locate() in get_turf(door)
	if(linked)
		return linked.travel(user)
	var/obj/machinery/door/airlock/first = pending_door?.resolve()
	if(QDELETED(first) || first == door || (locate(/obj/effect/heretic_backdoor) in get_turf(first)))
		pending_door = WEAKREF(door)
		pending_side = get_dir(door, user)
		door.balloon_alert(user, "первая дверь отмечена")
		return TRUE
	if(first.z != door.z && !(is_station_level(first.z) && is_station_level(door.z)))
		pending_door = null
		to_chat(user, span_warning("Ход не тянется так далеко: обе двери должны быть на станции или на одной палубе."))
		return FALSE
	link_doors(first, pending_side, door, get_dir(door, user), user)
	return TRUE

/obj/item/heretic_backdoor_card/proc/link_doors(obj/machinery/door/airlock/first, first_side, obj/machinery/door/airlock/second, second_side, mob/living/user)
	pending_door = null
	var/obj/effect/heretic_backdoor/entry = new(get_turf(first), first, first_side, src)
	var/obj/effect/heretic_backdoor/exit = new(get_turf(second), second, second_side, src)
	entry.partner = exit
	exit.partner = entry
	portals += entry
	portals += exit
	while(length(portals) > HERETIC_BACKDOOR_PAIRS * 2)
		qdel(portals[1])
	playsound(second, 'sound/magic/Knock.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
	second.balloon_alert(user, "ход открыт")
	log_game("[key_name(user)] связал ходом лабиринта [first] в [AREACOORD(first)] и [second] в [AREACOORD(second)].")

/obj/effect/heretic_backdoor
	name = "keyhole sigil"
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	icon_state = "backdoor_glyph"
	anchored = TRUE
	layer = ABOVE_OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/obj/machinery/door/airlock/door
	var/obj/effect/heretic_backdoor/partner
	var/obj/item/heretic_backdoor_card/card
	/// С какой стороны двери выходит пришедший с другого конца.
	var/exit_side

/obj/effect/heretic_backdoor/Initialize(mapload, obj/machinery/door/airlock/new_door, side, obj/item/heretic_backdoor_card/new_card)
	. = ..()
	if(QDELETED(new_door))
		return INITIALIZE_HINT_QDEL
	door = new_door
	exit_side = side
	card = new_card
	RegisterSignal(door, COMSIG_PARENT_QDELETING, PROC_REF(on_door_deleted))
	RegisterSignal(door, COMSIG_PARENT_ATTACKBY, PROC_REF(on_door_attackby))
	RegisterSignal(door, COMSIG_PARENT_EXAMINE, PROC_REF(on_door_examine))
	var/static/list/loc_connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/heretic_backdoor/Destroy()
	card?.portals -= src
	card = null
	if(door)
		UnregisterSignal(door, list(COMSIG_PARENT_QDELETING, COMSIG_PARENT_ATTACKBY, COMSIG_PARENT_EXAMINE))
		door = null
	var/obj/effect/heretic_backdoor/other = partner
	partner = null
	if(other && !QDELETED(other))
		other.partner = null
		qdel(other)
	return ..()

/obj/effect/heretic_backdoor/proc/on_door_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/heretic_backdoor/proc/on_door_attackby(datum/source, obj/item/weapon, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(weapon, /obj/item/nullrod) && !istype(weapon, /obj/item/storage/book/bible))
		return
	dispel(user, weapon)
	return COMPONENT_NO_AFTERATTACK

/obj/effect/heretic_backdoor/proc/on_door_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(heretic_side_bearer(user))
		examine_list += span_notice("На двери ваш знак скважины: шагом в проём или касанием карты выйдете у второй двери хода.")
	else
		examine_list += span_warning("На двери светится знак замочной скважины. Удар Библией или нулевым жезлом на «Вреде» сотрёт его.")

/obj/effect/heretic_backdoor/proc/dispel(mob/living/user, obj/item/weapon)
	var/atom/first_door = door
	var/atom/second_door = partner?.door
	for(var/atom/sealed as anything in list(first_door, second_door))
		if(!QDELETED(sealed))
			heretic_craft_dispel_fx(sealed, null)
	user?.visible_message(span_notice("[user] проводит [weapon] по двери, и знак скважины выгорает."), span_notice("Знак скважины выгорает: тайный ход закрыт."))
	log_game("[key_name(user)] стёр ход лабиринта у [first_door] в [AREACOORD(first_door)].")
	qdel(src)

/obj/effect/heretic_backdoor/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(!isliving(arrived) || !partner)
		return
	var/mob/living/walker = arrived
	if(walker.m_intent != MOVE_INTENT_WALK || !heretic_side_bearer(walker))
		return
	INVOKE_ASYNC(src, PROC_REF(travel), walker)

/mob/living
	var/heretic_backdoor_ready = 0

/obj/effect/heretic_backdoor/proc/travel(mob/living/walker)
	if(QDELETED(partner) || QDELETED(walker) || walker.heretic_backdoor_ready > world.time)
		return FALSE
	var/reason = heretic_containment_reason(walker)
	if(reason)
		to_chat(walker, span_warning(reason))
		return FALSE
	var/turf/exit = partner.exit_turf()
	if(!exit)
		walker.balloon_alert(walker, "выход завален")
		return FALSE
	var/turf/origin = get_turf(walker)
	if(!do_teleport(walker, exit, no_effects = TRUE, channel = TELEPORT_CHANNEL_MAGIC))
		walker.balloon_alert(walker, "ход не пускает")
		return FALSE
	walker.heretic_backdoor_ready = world.time + HERETIC_BACKDOOR_TRAVEL_COOLDOWN
	playsound(origin, 'sound/magic/Knock.ogg', 20, TRUE, SILENCED_SOUND_EXTRARANGE)
	playsound(exit, 'sound/magic/Knock.ogg', 20, TRUE, SILENCED_SOUND_EXTRARANGE)
	return TRUE

/obj/effect/heretic_backdoor/proc/exit_turf()
	if(QDELETED(door))
		return null
	var/turf/preferred = exit_side ? get_step(door, exit_side) : null
	if(preferred && heretic_tile_passable(preferred))
		return preferred
	for(var/direction in GLOB.cardinals)
		var/turf/side = get_step(door, direction)
		if(side && heretic_tile_passable(side))
			return side
	return null

/datum/eldritch_knowledge/rust_sower
	name = "Ржавый сеятель"
	summary = "Граната и стержень дают ржавую гранату: взрыв ржавит всё вокруг и мутит неверных."
	details = list(
		"Взводится как обычная граната; взрыв ржавит полы и стены в 3 клетках на виду.",
		"Ржавеют полы и простые стены; укреплённые - через раз, а неразрушимое ржавчина не берёт.",
		"Неверных рядом тошнит, и взгляд у них мутнеет; синтетики получают 30 урона ржой.",
		"Вас и ваших слуг взрыв не трогает; защита от магии бережёт от тошноты.",
		"Неверный гранату не взведёт: ржавчина пачкает руки, и его мутит.",
	)
	role = HERETIC_ROLE_CONTROL
	ritual_hints = list(
		"Подойдёт любая граната: светошумовая, дымовая, корпус химической. Рядом положите металлический стержень.",
		"Граната и стержень израсходуются; взведённую гранату не кладите.",
	)
	gain_text = "Я бросил в землю горсть ржавчины, и сад взошёл быстрее, чем я успел отойти."
	cost = 2
	required_atoms = list(/obj/item/grenade, /obj/item/stack/rods)
	result_atoms = list(/obj/item/grenade/heretic_rust_sower)

/obj/item/grenade/heretic_rust_sower
	name = "rust sower"
	desc = "Граната, сплошь покрытая рыжей коростой. Сквозь трещины сочится бурая пыль, а чека скрипит, как старая петля."
	icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	icon_state = "rust_sower"

/obj/item/grenade/heretic_rust_sower/attack_self(mob/user)
	if(!active && !heretic_side_bearer(user))
		heathen_touch(user)
		return
	return ..()

/obj/item/grenade/heretic_rust_sower/proc/heathen_touch(mob/user)
	if(isliving(user))
		var/mob/living/fumbler = user
		fumbler.adjust_disgust(HERETIC_RUST_SOWER_DISGUST / 2)
	to_chat(user, span_warning("Чека рассыпается рыжей пылью у вас в пальцах, и к горлу подкатывает тошнота."))

/obj/item/grenade/heretic_rust_sower/prime(mob/living/lanced_by)
	. = ..()
	var/turf/center = get_turf(src)
	update_mob()
	if(center)
		sow(center)
	qdel(src)

/obj/item/grenade/heretic_rust_sower/proc/sow(turf/center)
	playsound(center, 'modular_bluemoon/sound/heretic/rust_seed_burst.ogg', 70, TRUE)
	var/list/seen = heretic_field_view(HERETIC_RUST_SOWER_RANGE, center)
	for(var/mob/living/victim in seen)
		if(!heretic_can_affect(primed_by, victim))
			continue
		if(issilicon(victim))
			victim.adjustBruteLoss(HERETIC_RUST_SOWER_SILICON_DAMAGE)
		else
			victim.adjust_disgust(HERETIC_RUST_SOWER_DISGUST)
			victim.blur_eyes(HERETIC_RUST_SOWER_BLUR)
		to_chat(victim, span_warning("В лицо бьёт облако рыжей пыли, во рту привкус железа."))
		log_combat(primed_by, victim, "rusted", src)
	for(var/turf/place in seen)
		place.rust_heretic_act()
