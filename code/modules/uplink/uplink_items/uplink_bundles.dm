
//All bundles and telecrystals

/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

/datum/uplink_item/bundles_tc/chemical
	name = "Bioterror bundle"
	desc = "Для настоящего безумца: содержит ручной биотеррор-распылитель, биотеррор-пеногранату, \
			коробку смертельных химикатов, дротиковый пистолет, коробку шприцев, штурмовую винтовку Donksoft и дротики подавления. \
			Не забудьте: герметизируйте костюм и подключите баллон перед использованием."
	item = /obj/item/storage/backpack/duffelbag/syndie/med/bioterrorbundle
	cost = 30 // normally 42
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/bulldog
	name = "Bulldog bundle"
	desc = "Для любителей ближнего боя: содержит дробовик Bulldog, \
			барабан 12г с картечью, барабан 12г с тейзер-слагами и термоочки."
	item = /obj/item/storage/backpack/duffelbag/syndie/bulldogbundle
	cost = 13 // normally 16
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/c20r
	name = "C-20r bundle"
	desc = "Старая добрая классика: C-20r в комплекте с двумя магазинами и (списанным) глушителем по скидке."
	item = /obj/item/storage/backpack/duffelbag/syndie/c20rbundle
	cost = 14 // normally 16
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/contract_kit
	name = "Contract Kit"
	desc = "Враги Nanotrasen предлагают вам стать контрактником - брать контракты на похищение за TC и наличку. \
			В комплекте планшет с контрактным аплинком, спецскафандр, хамелеон-комбинезон и маска, \
			спецдубинка контрактора и три случайных недорогих предмета. Может включать экзотику."
	item = /obj/item/storage/box/syndie_kit/contract_kit
	cost = 30
	player_minimum = 50
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	restricted = TRUE

/datum/uplink_item/bundles_tc/northstar_bundle
	name = "Northstar Bundle"
	desc = "Предмет, обычно зарезервированный для Gorlex Marauders. \
			Эти наручи позволяют бить очень быстро со смертоносностью легендарного мастера единоборств. \
			Совместимы со всеми боевыми искусствами, но носитель не сможет пользоваться огнестрелом и снять наручи."
	item = /obj/item/storage/box/syndie_kit/northstar
	cost = 20
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/bundles_tc/scarp_bundle
	name = "Sleeping Carp Bundle"
	desc = "Станьте едины со своим внутренним карпом! Древние рыбные мастера завещают вам своё учение, священную форму и посох. \
	Учтите: вы не сможете использовать бесчестное дальнее оружие."
	item = /obj/item/storage/box/syndie_kit/scarp
	cost = 20
	player_minimum = 20
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/suits/infiltrator_bundle
	name = "Insidious Infiltration Gear Case"
	desc = "Разработан Roseus Galactic совместно с Gorlex Marauders для городских операций. \
			Дешевле стандартного скафандра, без ограничений подвижности (и без космозащиты). \
			Включает бронежилет, шлем, скрытный кровавый костюм, скрытные ботинки, спецперчатки и хайтек-балаклаву, скрывающую голос и лицо."
	item = /obj/item/storage/toolbox/infiltrator
	cost = 5
	limited_stock = 1 //you only get one so you don't end up with too many gun cases
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/bundles_tc/cybernetics_bundle
	name = "Cybernetic Implants Bundle"
	desc = "Случайная подборка кибернетических имплантов. Гарантировано 5 качественных имплантов. В комплекте автохирург."
	item = /obj/item/storage/box/cyber_implants
	cost = 40
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/medical
	name = "Medical bundle"
	desc = "Для специалиста поддержки: помогите своим союзникам. Содержит тактическую аптечку, \
			пулемёт Donksoft, коробку дротиков подавления и магботинки для спасения друзей в невесомости."
	item = /obj/item/storage/backpack/duffelbag/syndie/med/medicalbundle
	cost = 15 // normally 20
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/modular
	name = "Modular Pistol Kit"
	desc = "Тяжёлый кейс с модульным пистолетом (10мм), глушителем и запасными боеприпасами, \
		включая снотворные патроны. В комплекте пиджак с бронеподкладкой."
	item = /obj/item/storage/briefcase/modularbundle
	cost = 12

/datum/uplink_item/bundles_tc/shredderbundle
	name = "Shredder bundle"
	desc = "По-настоящему ужасное оружие для калечения жертв - CX Shredder запрещён несколькими межгалактическими договорами. \
			В наборе два шредера, запасные патроны, элитный скафандр и разгрузка."
	item = /obj/item/storage/backpack/duffelbag/syndie/shredderbundle
	cost = 30 // normally 41
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/sniper
	name = "Sniper bundle"
	desc = "Элегантно и утончённо: складная снайперка в дорогом кейсе, \
			два снотворных магазина, списанный глушитель и стильный тактический водолазковый костюм. \
			Закажите СЕЙЧАС - и красный галстук в подарок."
	item = /obj/item/storage/briefcase/sniperbundle
	cost = 20 // normally 26
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/firestarter
	name = "Spetsnaz Pyro bundle"
	desc = "Для систематического подавления углеродных форм жизни в ближнем бою: содержит ранцевый распылитель Ново-российского производства, \
			элитный скафандр, пистолет Стечкин, два магазина, минибомбу и стимулятор. \
			Закажите СЕЙЧАС - и товарищ Борис подкинет дополнительный спортивный костюм."
	item = /obj/item/storage/backpack/duffelbag/syndie/firestarter
	cost = 30
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/bundle
	name = "Operative Bundle"
	desc = "Специализированные наборы предметов в обычной коробке. \
			Суммарно стоят больше 20 кредитов, но специализация неизвестна заранее. \
			Могут содержать снятые с производства и/или экзотические предметы."
	item = /obj/item/storage/box/syndicate
	cost = 15
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	cant_discount = TRUE

/datum/uplink_item/bundles_tc/bundle //blumoon add
	name = "Old hero Bundle"
	desc = "Набор оперативника - подборка предметов в обычной коробке. \
			Суммарная ценность содержимого свыше 20 кредитов, но какую специализацию получите - неизвестно. \
			Может содержать снятые с производства и/или экзотические предметы."
	item = /obj/item/storage/box/inteq_kit/new_heroes
	cost = 17
	purchasable_from = UPLINK_TRAITORS
	cant_discount = TRUE

/datum/uplink_item/bundles_tc/surplus
	name = "Surplus Crate"
	desc = "Пыльный ящик с задворок нелегального склада. Говорят, содержит ценный набор предметов, \
			но кто знает. Содержимое всегда на 50 кредитов."
	item = /obj/structure/closet/crate
	cost = 20
	player_minimum = 25
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	var/starting_crate_value = 50
	var/uplink_flags = UPLINK_TRAITORS

/datum/uplink_item/bundles_tc/surplus/super
	name = "Super Surplus Crate"
	desc = "Пыльный СУПЕР-РАЗМЕРНЫЙ ящик с задворок нелегального склада. Говорят, содержит ценный набор предметов, \
			но кто знает. Содержимое всегда на 125 кредитов."
	cost = 40
	player_minimum = 40
	starting_crate_value = 125

/datum/uplink_item/bundles_tc/surplus/purchase(mob/user, datum/component/uplink/U)
	var/list/uplink_items = get_uplink_items(uplink_flags, FALSE)

	var/crate_value = starting_crate_value
	var/obj/structure/closet/crate/C = spawn_item(/obj/structure/closet/crate, user, U)
	if(U.purchase_log)
		U.purchase_log.LogPurchase(C, src, cost)
	while(crate_value)
		var/category = pick(uplink_items)
		var/item = pick(uplink_items[category])
		var/datum/uplink_item/I = uplink_items[category][item]

		if(!I.surplus || prob(100 - I.surplus))
			continue
		if(crate_value < I.cost)
			continue
		crate_value -= I.cost
		var/obj/goods = new I.item(C)
		if(U.purchase_log)
			U.purchase_log.LogPurchase(goods, I, 0)
	return C

/datum/uplink_item/bundles_tc/reroll
	name = "Renegotiate Contract"
	desc = "Сообщите работодателям, что хотите новые задания. Можно сделать только дважды."
	item = /obj/effect/gibspawner/generic
	cost = 0
	cant_discount = TRUE
	restricted = TRUE
	limited_stock = 2

/datum/uplink_item/bundles_tc/reroll/purchase(mob/user, datum/component/uplink/U)
	var/datum/antagonist/traitor/T = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	if(istype(T))
		T.set_traitor_kind(get_random_traitor_kind(blacklist = list(/datum/traitor_class/human/freeform, /datum/traitor_class/human/hijack, /datum/traitor_class/human/martyr)))
	else
		to_chat(user,"Invalid user for contract renegotiation.")

/datum/uplink_item/bundles_tc/random
	name = "Random Item"
	desc = "Купит случайный предмет. Полезно, если есть лишние TC или не определились со стратегией."
	item = /obj/effect/gibspawner/generic
	cost = 0
	cant_discount = TRUE

/datum/uplink_item/bundles_tc/random/purchase(mob/user, datum/component/uplink/U)
	var/list/uplink_items = U.uplink_items
	var/list/possible_items = list()
	for(var/category in uplink_items)
		for(var/item in uplink_items[category])
			var/datum/uplink_item/I = uplink_items[category][item]
			if(src == I || !I.item)
				continue
			if(istype(I, /datum/uplink_item/bundles_tc/reroll)) //oops!
				continue
			if(U.telecrystals < I.cost)
				continue
			if(I.limited_stock == 0)
				continue
			possible_items += I

	if(possible_items.len)
		var/datum/uplink_item/I = pick(possible_items)
		SSblackbox.record_feedback("tally", "traitor_random_uplink_items_gotten", 1, initial(I.name))
		U.MakePurchase(user, I)

/datum/uplink_item/bundles_tc/telecrystal
	name = "1 Telecrystal"
	desc = "A telecrystal in its rawest and purest form; can be utilized on active uplinks to increase their telecrystal count."
	item = /obj/item/stack/telecrystal
	cost = 1
	surplus = 0
	cant_discount = TRUE
	// Don't add telecrystals to the purchase_log since
	// it's just used to buy more items (including itself!)
	purchase_log_vis = FALSE
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/bundles_tc/telecrystal/five
	name = "5 Telecrystals"
	desc = "Five telecrystals in their rawest and purest form; can be utilized on active uplinks to increase their telecrystal count."
	item = /obj/item/stack/telecrystal/five
	cost = 5
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/bundles_tc/telecrystal/twenty
	name = "20 Telecrystals"
	desc = "Twenty telecrystals in their rawest and purest form; can be utilized on active uplinks to increase their telecrystal count."
	item = /obj/item/stack/telecrystal/twenty
	cost = 20
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/bundles_tc/telecrystal/inteq
	name = "1 Tele Credit"
	desc = "Золотой кредит. Можно вставить в аплинк."
	item = /obj/item/stack/telecrystal/inteq
	cost = 1
	surplus = 0
	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/telecrystal/five/inteq
	name = "5 Tele Credits"
	desc = "Пять золотых кредитов. Можно вставить в аплинк."
	item = /obj/item/stack/telecrystal/inteq/five
	cost = 5
	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/telecrystal/twenty/inteq
	name = "20 Tele Credits"
	desc = "Двадцать золотых кредитов. Можно вставить в аплинк."
	item = /obj/item/stack/telecrystal/inteq/twenty
	cost = 20
	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/bundles_tc/conversion_kit
	name = "InteQ Conversion Kit"
	desc = "Коробка с набором конвертации наушника в bowman headset и ключом-шифратором InteQ. Набор конвертации, после использования на наушнике обеспечивает пользователю защиту от звука светошумовой гранаты. Вставьте в наушник чтобы получить доступ к каналу InteQ (говорить и слышать) и остальным каналам на станции (только слышать)."
	item = /obj/item/storage/box/inteq_kit/conversion_kit
	cost = 1
	purchasable_from = UPLINK_TRAITORS
