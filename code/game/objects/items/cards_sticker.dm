/obj/item/card_sticker
	name = "Card sticker"
	desc = "Наклейка для ID-карты."
	icon = 'icons/obj/card.dmi'
	icon_state = "occult_id"
	w_class = WEIGHT_CLASS_TINY
	var/const/wrap_delay = 1.3 SECONDS // time to wrap sticker on card
	var/special_assignment = "syndicate" // id card HUD icon
	/// Префикс для спец. карточек. null = без префикса
	var/prefix = null
	/// Суффикс для спец. карточек, внешне традиционно должны идти как минорные дополнения карты, добавляются как оверлей
	var/aftername_suffix = null
	/// В какой слот ID-карты встаёт наклейка. В префиксном слоте работает prefix, в суффиксном - aftername_suffix
	var/sticker_slot = STICKER_SLOT_PREFIX
	/**
	 * Режимы работы:
	 * - null: "скин" - карта целиком получает icon/icon_state наклейки
	 * - не null: "оверлей" - основа карты не трогается, поверх неё рисуется этот icon_state
	 */
	var/sticker_state = null
	/// Заменяет ли оверлей наклейки оверлей должности (id[job]) на карте
	var/replaces_job_overlay = FALSE

	var/auto_equip = FALSE // for loadout
	var/permit = null // only for auto_equip
	var/permit_only_extended = FALSE

	/// Блеклист префиксов/суффиксов для избежания рофлов типа Nanotrasen Syndicate Warden.
	/// Слова сравниваются отдельно, без учёта регистра.
	/// Проверка на слово префикса/суффикса есть всегда, даже если список пуст
	var/list/prefix_not_allowed_with = list()
	/// Что было на карте до наклейки (только для режима скинов)
	var/previous_icon
	var/previous_icon_state

/obj/item/card_sticker/examine(mob/user)
	. = ..()
	. += span_notice("Расширение, устанавливаемое поверх стандартной ID-карты. \
	Перехватывает и подменяет отображаемые данные: визуальный стиль карты, цветовую схему и название должности.\n\
	Не влияет на реальные уровни доступа и системы аутентификации, изменяя исключительно представление информации для интерфейсов и внешнего осмотра.")

// При выдаче через лодаут карта помещается в рюкзак и применяется на основную карту
/obj/item/card_sticker/on_enter_storage(datum/component/storage/concrete/S)

	if(auto_equip)
		auto_equip = FALSE
		var/mob/living/carbon/human/my_owner = null

		// Проверяем инветарь и сумку куклы
		var/atom/movable/cur = loc
		for(var/i = 1, i <= 2, i++)
			if(!cur)
				break

			if(ishuman(cur))
				my_owner = cur
				break

			// дальше поднимаемся только если следующий loc тоже movable
			if(!istype(cur.loc, /atom/movable))
				break

			cur = cur.loc

		if(my_owner)
			var/obj/item/card/id/id_card = my_owner.get_item_by_slot(ITEM_SLOT_ID)
			if(id_card)
				// Активируем наклейку
				if(wrap(id_card, my_owner, silent = TRUE, force = TRUE))
					// Попытка обновить манифест
					id_card.update_manifest()
					// Обновляем ПДА
					var/obj/item/modular_computer/pda/PDA = locate(/obj/item/modular_computer/pda) in my_owner.contents
					if(istype(PDA))
						PDA.ownjob = id_card.get_assignment_name()
						PDA.update_label()

			if(permit && (!permit_only_extended || GLOB.master_mode == ROUNDTYPE_EXTENDED))
				var/obj/item/clothing/accessory/permit/special/prmt = new permit(my_owner)
				//Привязываем пермит
				prmt.bind_to_user(my_owner, TRUE)

				var/obj/item/clothing/under/U = my_owner.get_item_by_slot(ITEM_SLOT_ICLOTHING)
				// Крепим к одежде, если не удалось, помещаем в сумку
				if(!(istype(U) && U.attach_accessory(prmt, my_owner, FALSE)))
					my_owner.equip_in_one_of_slots(prmt, list("backpack" = ITEM_SLOT_BACKPACK), critical = TRUE)

	return ..()

/// Вид оверлея для карты. Если null - наклейка работает как скин
/obj/item/card_sticker/proc/get_sticker_overlay()
	if(!sticker_state)
		return null
	return mutable_appearance(icon, sticker_state)

/// Что эта наклейка добавляет к названию должности, вместе с пробелом со стороны должности.
/// Вся логика названия лежит здесь, карта только склеивает части из своих слотов
/obj/item/card_sticker/proc/get_name_part(assignment)
	var/word = (sticker_slot == STICKER_SLOT_SUFFIX) ? aftername_suffix : prefix
	if(!word || is_decoration_blocked(assignment, word))
		return ""
	return (sticker_slot == STICKER_SLOT_SUFFIX) ? " [word]" : "[word] "

/// Хелпер: нельзя ли добавить слово к должности
/obj/item/card_sticker/proc/is_decoration_blocked(assignment, decoration)
	if(assignment_has_word(assignment, decoration))
		return TRUE
	for(var/word in prefix_not_allowed_with)
		if(assignment_has_word(assignment, word))
			return TRUE
	return FALSE

/obj/item/card_sticker/proc/assignment_has_word(assignment, word)
	var/regex/word_regex = regex("(^|\[^A-Za-zА-Яа-я0-9\])[word](\[^A-Za-zА-Яа-я0-9\]|$)", "i")
	return word_regex.Find(assignment) ? TRUE : FALSE

/// Обновляет карту и худ того, кто её носит
/obj/item/card_sticker/proc/refresh_card(obj/item/card/id/card)
	card.update_label()
	if(ishuman(card.loc))
		var/mob/living/carbon/human/holder = card.loc
		holder.sec_hud_set_ID()

/obj/item/card_sticker/proc/get_wrap_block_reason(obj/item/card/id/card)
	if(card.get_sticker(sticker_slot))
		return "Карта уже обёрнута"
	// Скин подменит иконку карты целиком, и два скина сразу корректно снять нельзя
	if(!sticker_state)
		for(var/obj/item/card_sticker/other in card.get_stickers())
			if(!other.sticker_state)
				return "Конфликт внешнего вида"
	return null

/// Прок оборачивания айди карты в стикер
/obj/item/card_sticker/proc/wrap(obj/item/card/id/card, mob/user, silent = FALSE, force = FALSE)
	. = FALSE
	if(!istype(card, /obj/item/card/id))
		return
	if(user && INTERACTING_WITH(user, card))
		return
	var/block_reason = get_wrap_block_reason(card)
	if(block_reason)
		if(!silent && user)
			balloon_alert(user, block_reason)
		return
	if(!silent && user)
		balloon_alert(user, "Присоединяю...")
	if(!force && (!user || !do_after(user, wrap_delay, card)))
		return
	if(get_wrap_block_reason(card))
		return

	if(!forceMove(card))
		return
	card.set_sticker(sticker_slot, src)

	if(!sticker_state)
		previous_icon = card.icon
		previous_icon_state = card.icon_state
		card.icon = icon
		card.icon_state = icon_state

	refresh_card(card)
	return TRUE

/obj/item/card_sticker/proc/unwrap(obj/item/card/id/card, mob/user, silent = FALSE, force = FALSE)
	. = FALSE
	if(!istype(card) || card.get_sticker(sticker_slot) != src || (user && INTERACTING_WITH(user, card)))
		return
	if(!silent && user)
		balloon_alert(user, "Снимаю...")
	if(!force && (!user || !do_after(user, wrap_delay, card)))
		return
	if(card.get_sticker(sticker_slot) != src)
		return

	if(user)
		if(!user.put_in_hands(src))
			return
	else
		moveToNullspace()

	card.set_sticker(sticker_slot, null)

	if(!sticker_state)
		card.icon = previous_icon
		card.icon_state = previous_icon_state
		previous_icon = null
		previous_icon_state = null

	refresh_card(card)
	return TRUE

/obj/item/card_sticker/heresy
	name = "Occult sticker"
	desc = "Стикер для исследований, связанных с оккультной деятельностью, неизученная натура феноменов которой слабо поддерживается научной практикой."
	icon_state = "occult_id"
	prefix = "Heretic"
	special_assignment = "heresy"
	permit = /obj/item/clothing/accessory/permit/special/deviant/heresey

/obj/item/card_sticker/heresy/loadout
	auto_equip = TRUE

/obj/item/card_sticker/lust
	name = "Sex Worker sticker"
	desc = "Стикер для сотрудников компании Silver Love Co."
	icon_state = "lust_id"
	prefix = "Sex Worker"
	special_assignment = "lust"
	prefix_not_allowed_with = list("Sex")
	permit = /obj/item/clothing/accessory/permit/special/deviant/lust

/obj/item/card_sticker/lust/loadout
	auto_equip = TRUE

/obj/item/card_sticker/agony
	name = "Ravenheart Resident sticker"
	desc = "Стикер для исследований, связанных с экстремальными активностями, агонистическая натура которых строго возбранена научной практикой."
	icon_state = "agony_id"
	prefix = "Ravenheart"
	special_assignment = "agony"
	permit = /obj/item/clothing/accessory/permit/special/deviant/agony
	permit_only_extended = TRUE

/obj/item/card_sticker/agony/loadout
	auto_equip = TRUE

/obj/item/card_sticker/vampire
	name = "Bloodfledge sticker"
	desc = "Стикер для лёгкого опознания отпрысков кровопийц без дополнительных медицинских анализов."
	icon_state = "vampire2"
	prefix = "Bloodsucker"
	special_assignment = "bloodsuckerfledgling"

/obj/item/card_sticker/vampire/loadout
	auto_equip = TRUE

/obj/item/card_sticker/blumenland
	name = "Blumenland Citizen sticker"
	desc = "Стикер для различия граждан Конфедерации Блюменланд и туристов из неё."
	icon_state = "blumland"
	prefix = "Blumenland"
	special_assignment = "bmland"

/obj/item/card_sticker/blumenland/loadout
	auto_equip = TRUE

/obj/item/card_sticker/syndicate
	name = "Syndicate Employee sticker"
	desc = "Стикер для различия агентов и поддерживающих Триглав Синдиката."
	icon_state = "card_black"
	prefix = "Syndicate"
	special_assignment = "syndicate"
	prefix_not_allowed_with = SYNDI_NT_PREFIX_LIST

/obj/item/card_sticker/syndicate/loadout
	auto_equip = TRUE

/obj/item/card_sticker/nanotrasen
	name = "Nanotrasen Employee sticker"
	desc = "Стикер для различия сотрудников Nanotrasen и поддерживающих корпорацию."
	icon_state = "centcom"
	prefix = "Nanotrasen"
	special_assignment = "centcom"
	prefix_not_allowed_with = SYNDI_NT_PREFIX_LIST

/obj/item/card_sticker/nanotrasen/loadout
	auto_equip = TRUE

/obj/item/card_sticker/sol
	name = "SolFed Citizen sticker"
	desc = "Стикер для различия граждан Солнечной Федерации и туристов из неё."
	icon_state = "sol"
	prefix = "SolFed"
	special_assignment = "sol"
	prefix_not_allowed_with = list("Sol", "Solar Federation")

/obj/item/card_sticker/sol/loadout
	auto_equip = TRUE

/obj/item/card_sticker/nri
	name = "NRI Citizen sticker"
	desc = "Стикер для различия граждан Новороссийской Империи и туристов из неё."
	icon_state = "nri"
	prefix = "NRI"
	special_assignment = "nri"
	prefix_not_allowed_with = list("New Russian Empire")

/obj/item/card_sticker/nri/loadout
	auto_equip = TRUE

/// Стикеры авангарда: оверлей поверх обычной карты, без префикса, но с суффиксом
/obj/item/card_sticker/vanguard
	sticker_slot = STICKER_SLOT_SUFFIX
	replaces_job_overlay = TRUE

/obj/item/card_sticker/vanguard/grenadier
	name = "vanguard grenadier sticker"
	desc = "Стикер авангарда для ID-карты. Гренадёры эскадронов известны своим дурным нравом предложить взорвать каждую встреченную стенку на пути."
	icon_state = "vanguardgrenadiersticker"
	sticker_state = "idvanguardgrenadier"
	aftername_suffix = "Grenadier"
	special_assignment = "hudvanguardgrenadier"
	prefix_not_allowed_with = list("Feldscherer", "Shocktrooper")

/obj/item/card_sticker/vanguard/feldscherer
	name = "vanguard feldscherer sticker"
	desc = "Стикер авангарда для ID-карты. Многие недооценивают важность хорошего фельдшера в эскадроне, по крайней мере, до первой клинической смерти."
	icon_state = "vanguardfeldscherersticker"
	sticker_state = "idvanguardfeldscherer"
	aftername_suffix = "Feldscherer"
	special_assignment = "hudvanguardfeldscherer"
	prefix_not_allowed_with = list("Grenadier", "Shocktrooper")

/obj/item/card_sticker/vanguard/shocktrooper
	name = "vanguard shocktrooper sticker"
	desc = "Стикер авангарда для ID-карты. На самом деле, именно штурмовики обязаны принимать на себя первый удар, почему это делают фельдшера с щитами?..."
	icon_state = "vanguardshocktroopersticker"
	sticker_state = "idvanguardshocktrooper"
	aftername_suffix = "Shocktrooper"
	special_assignment = "hudvanguardshocktrooper"
	prefix_not_allowed_with = list("Grenadier", "Feldscherer")
