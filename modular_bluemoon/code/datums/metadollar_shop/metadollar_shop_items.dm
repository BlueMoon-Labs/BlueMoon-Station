#define METADOLLAR_CATALOG_LEGIT "legit"
#define METADOLLAR_CATALOG_SMUGGLE "smuggle"

/datum/metadollar_shop_item
	var/name = "Товар"
	var/desc = ""
	var/cost = 0
	var/catalog = METADOLLAR_CATALOG_LEGIT
	var/minimum_players = 0

/datum/metadollar_shop_item/proc/is_visible(datum/metadollar_shop/shop)
	return TRUE

/datum/metadollar_shop_item/proc/try_purchase(client/C)
	if(!C?.ckey)
		return FALSE
	var/balance = SSmetadollars.get_metadollars(C.ckey)
	if(minimum_players && length(GLOB.player_list) < minimum_players)
		to_chat(C.mob, span_warning("На сервере слишком мало игроков для этой покупки (нужно минимум [minimum_players])."))
		return TRUE
	if(balance < cost)
		to_chat(C.mob, span_warning("Недостаточно метадолларов."))
		return TRUE
	if(!queue_delivery(C))
		return FALSE
	SSmetadollars.metadollar_adjust(-cost, C.ckey, C.key)
	to_chat(C.mob, span_notice("[delivery_message()]"))
	return TRUE

/datum/metadollar_shop_item/proc/queue_delivery(client/C)
	return FALSE

/datum/metadollar_shop_item/proc/delivery_message()
	return "Заказ будет в рюкзаке при следующем появлении на станции."

/datum/metadollar_shop_item/item
	var/obj/item/spawn_type

/datum/metadollar_shop_item/item/queue_delivery(client/C)
	if(!ispath(spawn_type, /obj/item))
		return FALSE
	LAZYADD(C.prefs.metadollar_pending_items, "[spawn_type]")
	return TRUE

/datum/metadollar_shop_item/item/antag_token
	catalog = null
	var/token_spawn_type
	var/round_limit = 0
	var/round_limit_key = null
	var/list/disallowed_modes = null
	var/disallowed_mode_message = "Этот жетон недоступен в текущем режиме игры."

/datum/metadollar_shop_item/item/antag_token/try_purchase(client/C)
	if(!C?.ckey)
		return FALSE
	if(disallowed_modes && SSticker?.mode)
		for(var/mode_type in disallowed_modes)
			if(ispath(mode_type) && istype(SSticker.mode, mode_type))
				to_chat(C.mob, span_warning(disallowed_mode_message))
				return TRUE
	if(round_limit > 0 && round_limit_key && !SSmetadollars.can_purchase_round_limited_item(round_limit_key, round_limit))
		to_chat(C.mob, span_warning("В этом раунде все такие жетоны уже раскуплены (лимит [round_limit] на станцию)."))
		return TRUE
	return ..()

/datum/metadollar_shop_item/item/antag_token/queue_delivery(client/C)
	if(!ispath(token_spawn_type, /obj/item))
		return FALSE
	LAZYADD(C.prefs.metadollar_pending_items, "[token_spawn_type]")
	if(round_limit > 0 && round_limit_key)
		SSmetadollars.register_round_limited_purchase(round_limit_key)
	return TRUE

/datum/metadollar_shop_item/item/antag_token/is_visible(datum/metadollar_shop/shop)
	if(disallowed_modes && SSticker?.mode)
		for(var/mode_type in disallowed_modes)
			if(ispath(mode_type) && istype(SSticker.mode, mode_type))
				return FALSE
	return TRUE

/datum/metadollar_shop_item/item/metadollar_voucher
	name = "Стопка метадолларов"
	desc = "После доставки в рюкзак: зачисление 50 М$ на лобби-счёт проведением стопки по КПК или по ID-карте; Alt+ЛКМ — отделить любую сумму (можно передать другому игроку)."
	cost = 50
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/stack/metadollar/fifty

/datum/metadollar_shop_item/item/insulated_gloves
	name = "Изолированные перчатки"
	desc = "Стандартные жёлтые перчатки для работы с электрикой."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/gloves/color/yellow

/datum/metadollar_shop_item/item/sunglasses
	name = "Солнцезащитные очки"
	desc = "Классические тёмные стёкла защищают от вспышек."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/glasses/sunglasses

/datum/metadollar_shop_item/item/gift_anything_lootbox
	name = "Коробка-сюрприз"
	desc = "Внутри вас ждёт случайный предмет."
	cost = 25
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/a_gift/anything

/datum/metadollar_shop_item/item/ration_pack
	name = "Случайный сухпаёк NT"
	desc = "Запечатанный рацион: при доставке выпадает одно из меню 1–4 (как безопасные MRE)."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/storage/box/mre/random_safe

/datum/metadollar_shop_item/item/collectable_random_hat
	name = "Случайная коллекционная шляпа"
	desc = "Сувенир из серии collectable: при доставке в рюкзак выпадает абсолютно случайный вариант из всех подтипов."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/head/collectable/random_metashop

/datum/metadollar_shop_item/item/freak_command_case
	name = "Командный кейс с сюрпризами"
	desc = "Большой офицерский кейс: случайная еда, алкогольные напитки и шприцы с контрабандой."
	cost = 50
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/storage/backpack/case/command/freak

/datum/metadollar_shop_item/item/captain_spare_id
	name = "Запасная ID-карта капитана"
	desc = "Золотая карта с полным доступом."
	cost = 500
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/card/id/captains_spare

/datum/metadollar_shop_item/item/traitor_token
	parent_type = /datum/metadollar_shop_item/item/antag_token
	name = "Жетон «Предатель»"
	desc = "Пластиковая монета. Alt+ЛКМ — роль предателя; Ctrl+ЛКМ — вернуть 250 М$. На всю станцию — не более 3 штук за раунд."
	cost = 250
	catalog = METADOLLAR_CATALOG_SMUGGLE
	minimum_players = 50
	token_spawn_type = /obj/item/coin/antagtoken/metashop/traitor
	round_limit = METASHOP_TRAITOR_TOKEN_ROUND_LIMIT
	round_limit_key = METASHOP_ANTAG_TOKEN_TRAITOR_LIMIT_KEY
	disallowed_modes = list(/datum/game_mode/extended)
	disallowed_mode_message = "Жетон «Предатель» недоступен в Extended: он зарезервирован под Dynamic."

/datum/metadollar_shop_item/item/changeling_token
	parent_type = /datum/metadollar_shop_item/item/antag_token
	name = "Жетон «Генокрад»"
	desc = "Органический жетон. Alt+ЛКМ — стать генокрадом; Ctrl+ЛКМ — вернуть 250 М$."
	cost = 250
	catalog = METADOLLAR_CATALOG_SMUGGLE
	minimum_players = 50
	token_spawn_type = /obj/item/coin/antagtoken/metashop/changeling

/datum/metadollar_shop_item/item/metadollar_total_burn
	name = "Протокол «Пепелище»"
	desc = "100000 М$: обнулить метадоллары у всех игроков. На вашем счёте должно быть не меньше 100000 М$."
	cost = 100000
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = null
	minimum_players = 100

/datum/metadollar_shop_item/item/metadollar_total_burn/try_purchase(client/C)
	if(!C?.ckey)
		return FALSE
	var/balance = SSmetadollars.get_metadollars(C.ckey)
	if(balance < cost)
		to_chat(C.mob, span_warning("Недостаточно метадолларов (нужно [cost] М$)."))
		return TRUE
	bm_metadollar_global_burn(C.mob)
	message_admins("[key_name_admin(C.mob)] активировал протокол «Пепелище»: обнулены все балансы метадолларов.")
	log_game("Metadollar total burn: [key_name(C.mob)] wiped all metadollar balances.")
	for(var/mob/M in GLOB.player_list)
		to_chat(M, span_danger("Межгалактическое казначейство: все балансы метадолларов обнулены. Сгорело всё."))
	return TRUE

/datum/metadollar_shop_item/item/golden_horn
	name = "Золотой клаксон"
	desc = "Роскошный велосипедный гудок для истинных ценителей комедии."
	cost = 25
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/bikehorn/golden

/datum/metadollar_shop_item/item/scream_mask
	name = "Маска крика"
	desc = "Маска с особым эффектом на эмоции."
	cost = 25
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/mask/screammask

/datum/metadollar_shop_item/item/desk_beacon
	name = "Маяк «Мебель»"
	desc = "Вызывает доставку мебели на выбор."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/choice_beacon/box/desk

/datum/metadollar_shop_item/item/pet_beacon
	name = "Маяк питомца"
	desc = "Позволяет призвать компаньона-питомца."
	cost = 25
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/choice_beacon/pet

/datum/metadollar_shop_item/item/carpet_beacon
	name = "Маяк ковров"
	desc = "Доставка наборов коврового покрытия."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/choice_beacon/box/carpet

/datum/metadollar_shop_item/item/tennis_rainbow
	name = "Радужная теннисная сфера"
	desc = "Пищащий мячик-трёхшарик — игрушка и антистресс."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow

/datum/metadollar_shop_item/item/bedsheet_cosmos
	name = "Космическая простыня"
	desc = "Простыня с космическим принтом."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/bedsheet/cosmos

/datum/metadollar_shop_item/item/spacecash_1000
	name = "Пачка кредитов (1000 кр.)"
	desc = "Красивые станционные кредиты."
	cost = 10
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/stack/spacecash/c1000

/datum/metadollar_shop_item/item/chameleon_kit
	name = "Коробка хамелеона"
	desc = "Синдикатовский набор маскировки."
	cost = 50
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/storage/box/syndie_kit/chameleon

/datum/metadollar_shop_item/item/syndie_mask
	name = "Маска Синдиката"
	desc = "Тактическая маска в стиле Синдиката."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/mask/gas/syndicate

/datum/metadollar_shop_item/item/syndie_turtleneck
	name = "Тактическая водолазка Синдиката"
	desc = "Классические тёмные штаны и водолазка."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/under/syndicate

/datum/metadollar_shop_item/item/syndie_skirtleneck
	name = "Тактическая юбка Синдиката"
	desc = "Классические тёмные штаны и юбка."
	cost = 10
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/clothing/under/syndicate/skirt

/datum/metadollar_shop_item/item/summon_pie
	name = "Книга заклинания «Пирог»"
	desc = "Учит простому заклинанию призыва пирога."
	cost = 100
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/book/granter/spell/summon_pie

/datum/metadollar_shop_item/item/foam_lmg
	name = "Игрушечный пенный пулемёт"
	desc = "Foam LMG — безопасный для станции."
	cost = 50
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted/riot

/datum/metadollar_shop_item/item/foam_lmg_mag
	name = "Магазин пенного LMG"
	desc = "Боезапас к игрушечному пулемёту."
	cost = 10
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/ammo_box/magazine/toy/m762/riot

/datum/metadollar_shop_item/item/syndie_dufflebag
	name = "Подозрительная сумка"
	desc = "Большая вещевая сумка для хранения дополнительных тактических принадлежностей."
	cost = 35
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/storage/backpack/duffelbag/syndie

/datum/metadollar_shop_item/item/potion_intelligence
	name = "Зелье интеллекта"
	desc = "Чудесная химическая смесь, наделяющая живые существа человеческим интеллектом."
	cost = 20
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/slimepotion/slime/sentience

/datum/metadollar_shop_item/item/jukebox
	name = "Jukebox"
	desc = "Переносная колонка для крутых."
	cost = 25
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/jukebox

/datum/metadollar_shop_item/item/jukebox_sponsor
	name = "Personal music box"
	desc = "A portable music box. You can load your own .ogg tracks from your computer and play them nearby."
	cost = 50
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/personal_music_box

/datum/metadollar_shop_item/item/smokespell_lesser
	name = "Книга с заклинанием призыва дыма"
	desc = "Книжка, что при изучении даёт вам возможность использовать заклинание маленького дыма."
	cost = 80
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/book/granter/spell/smoke/lesser

/datum/metadollar_shop_item/item/smokespell_crocin
	name = "Книга с заклинанием призыва кроцинового дыма"
	desc = "Книжка, что при изучении даёт вам возможность использовать заклинание кроцинового дыма."
	cost = 100
	catalog = METADOLLAR_CATALOG_LEGIT
	spawn_type = /obj/item/book/granter/spell/smoke/crocin

/datum/metadollar_shop_item/item/chameleon_stamp
	name = "Хамелеон-штамп"
	desc = "Маскируется под любой штамп должности - удобен для подделки бумаг."
	cost = 25
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/stamp/chameleon

/datum/metadollar_shop_item/item/holoparasite_injector
	name = "Инжектор голопаразита"
	desc = "Коробка с одноразовым инжектором голопаразита и разрешением на ношение."
	cost = 100
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/storage/box/metashop/holoparasite_kit

/datum/metadollar_shop_item/item/traitor_announcer
	name = "odd device"
	desc = "Странный пульт. Одноразовая подделка приоритетного объявления по вашему сценарию."
	cost = 100
	catalog = METADOLLAR_CATALOG_SMUGGLE
	spawn_type = /obj/item/device/traitor_announcer

#undef METADOLLAR_CATALOG_LEGIT
#undef METADOLLAR_CATALOG_SMUGGLE
