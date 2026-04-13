
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

//Grenades and Explosives

/datum/uplink_item/explosives/bioterrorfoam
	name = "Bioterror Foam Grenade"
	desc = "Мощная химическая пенная граната, создающая смертоносный поток пены, которая заглушает, ослепляет, дезориентирует, \
			мутирует и раздражает углеродных существ. Сварена специалистами по химическому оружию Tiger Cooperative \
			с добавлением спорового токсина. Перед использованием убедитесь, что костюм герметичен."
	item = /obj/item/grenade/chem_grenade/bioterrorfoam
	cost = 5
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/explosives/bombanana
	name = "Bombanana"
	desc = "Банан со взрывным вкусом! Выкидывай кожуру как можно скорее — через пару секунд после поедания банана \
		она рванёт с силой мини-бомбы Syndicate."
	item = /obj/item/reagent_containers/food/snacks/grown/banana/bombanana
	cost = 4 //it is a bit cheaper than a minibomb because you have to take off your helmet to eat it, which is how you arm it
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/explosives/buzzkill
	name = "Buzzkill Grenade Box"
	desc = "Коробка с тремя гранатами, выпускающими рой злющих пчёл при активации. Пчёлы без разбора жалят \
			друзей и врагов случайными токсинами. Любезно предоставлено BLF и Tiger Cooperative."
	item = /obj/item/storage/box/syndie_kit/bee_grenades
	cost = 15
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/explosives/c4
	name = "Composition C-4"
	desc = "C-4 — пластичная взрывчатка стандартного состава Composition C. Подойдёт для пролома стен, \
			диверсий с оборудованием, или можно подключить сборку для изменения способа детонации. \
			Крепится почти к любому объекту, таймер настраивается с минимумом в 10 секунд."
	item = /obj/item/grenade/plastic/c4
	cost = 1

/datum/uplink_item/explosives/doorboom
	name = "Door Charge"
	desc = "Небольшое взрывное устройство, которое можно поместить посреди электроники шлюза. Любой, кто рискнёт открыть такой шлюз ощутит на себе прелести взрывной химической реакции. Поставляется комплектом из пяти штук."
	item = /obj/item/storage/box/inteq_kit/doorgoboom
	cost = 3

/datum/uplink_item/explosives/c4bag
	name = "Bag of C-4 explosives"
	desc = "Потому что иногда количество — это качество. Содержит 10 пластичных взрывчаток C-4."
	item = /obj/item/storage/backpack/duffelbag/syndie/c4
	cost = 9 //10% discount!
	cant_discount = TRUE
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/explosives/c4bag/inteq
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/c4
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/explosives/x4bag
	name = "Bag of X-4 explosives"
	desc = "Содержит 3 направленных пластичных взрывчатки X-4. Похоже на C4, но мощнее и бьёт направленно, а не по кругу. \
			X-4 крепится к твёрдой поверхности вроде стены или окна — пробивает насквозь, калеча всё с обратной стороны, \
			при этом безопаснее для пользователя. Когда нужна контролируемая дыра побольше и поглубже."
	item = /obj/item/storage/backpack/duffelbag/syndie/x4
	cost = 4
	cant_discount = TRUE
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/explosives/x4bag/inteq
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/x4
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/explosives/clown_bomb_clownops
	name = "Clown Bomb"
	desc = "Клоунская бомба — уморительное устройство для эпических пранков. Таймер настраивается, минимум 60 секунд, \
			можно прикрутить к полу гаечным ключом. Бомба громоздкая и не перемещается; при заказе вам доставят \
			маленький маячок, который при активации телепортирует настоящую бомбу к себе. Учтите, что бомбу можно \
			обезвредить, и кто-то из экипажа наверняка попробует."
	item = /obj/item/sbeacondrop/clownbomb
	cost = 15
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/explosives/detomatix
	name = "Detomatix PDA Cartridge"
	desc = "При установке в КПК этот картридж даёт четыре попытки подорвать КПК тех членов экипажа, \
			у кого включена функция сообщений. Взрывная волна вырубит получателя ненадолго, а оглушит на подольше."
	item = /obj/item/cartridge/virus/syndicate
	cost = 5
	restricted = TRUE
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS) //bluemoon change никаких подрывов через ВР
	limited_stock = 1

/datum/uplink_item/explosives/emp
	name = "EMP Grenades and Implanter Kit"
	desc = "Набор из пяти EMP-гранат и EMP-импланта на три использования. Пригодится, чтобы вырубить связь, \
			энергетическое оружие охраны и силиконов, когда припрёт."
	item = /obj/item/storage/box/syndie_kit/emp
	cost = 2

/datum/uplink_item/explosives/virus_grenade
	name = "Fungal Tuberculosis Grenade"
	desc = "Заряженная био-граната в компактной коробке. В комплекте пять автоинжекторов BVAK (антидот) \
			на двоих каждый, шприц и бутылёк с раствором BVAK."
	item = /obj/item/storage/box/syndie_kit/tuberculosisgrenade
	cost = 8
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE
	restricted = TRUE

/datum/uplink_item/explosives/grenadier
	name = "Grenadier's belt"
	desc = "Пояс с 26-ю смертельно опасными гранатами. В комплекте мультитул и отвёртка."
	item = /obj/item/storage/belt/grenade/full
	purchasable_from = UPLINK_NUKE_OPS
	cost = 22
	surplus = 0

/datum/uplink_item/explosives/pizza_bomb
	name = "Pizza Bomb"
	desc = "Коробка с пиццей, к крышке которой хитро прикреплена бомба. Таймер активируется при первом открытии; \
			после этого повторное открытие запустит детонацию по истечении времени. Бесплатная пицца прилагается — для тебя или твоей цели!"
	item = /obj/item/pizzabox/bomb
	cost = 6
	surplus = 8

/datum/uplink_item/explosives/syndicate_bomb
	name = "Syndicate Bomb"
	desc = "Бомба Syndicate — грозное устройство, способное устроить масштабные разрушения. Таймер настраивается, минимум 60 секунд, \
			можно прикрутить к полу гаечным ключом. Бомба громоздкая и не перемещается; при заказе вам доставят \
			маленький маячок, который при активации телепортирует настоящую бомбу к себе. Учтите, что бомбу можно \
			обезвредить, и кто-то из экипажа наверняка попробует."
	item = /obj/item/sbeacondrop/bomb
	cost = 11
	hijack_only = TRUE
	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/explosives/syndicate_detonator
	name = "Syndicate Detonator"
	desc = "Детонатор Syndicate — устройство-компаньон к бомбе Syndicate. Просто нажми кнопку — зашифрованная радиочастота \
			прикажет всем активным бомбам Syndicate рвануть. Полезно, когда важна скорость или нужно синхронизировать \
			несколько взрывов. Убедись, что стоишь подальше от зоны поражения, прежде чем жать."
	item = /obj/item/syndicatedetonator
	cost = 3
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_TRAITORS

/datum/uplink_item/explosives/syndicate_minibomb
	name = "Syndicate Minibomb"
	desc = "Мини-бомба — граната с пятисекундным запалом. При детонации пробивает корпус и наносит \
			серьёзный урон всем, кто оказался рядом."
	item = /obj/item/grenade/syndieminibomb
	cost = 6
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/explosives/syndicate_minibombs
	name = "Syndicate Minibomb Clusterbang"
	desc = "Кластерная мини-бомба — граната с пятисекундным запалом. При детонации пробивает корпус \
			и наносит серьёзный урон всем, кто оказался рядом."
	item = /obj/item/grenade/clusterbuster/syndieminibomb
	cost = 21
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS

/datum/uplink_item/explosives/tearstache
	name = "Teachstache Grenade"
	desc = "Слезоточивая граната, которая лепит липкие усы на лицо каждому, кто не носит маску клоуна или мима. \
		Усы держатся на морде целых две минуты, не давая пользоваться дыхательными масками и прочими штуками."
	item = /obj/item/grenade/chem_grenade/teargas/moustache
	cost = 3
	surplus = 1
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/explosives/viscerators
	name = "Viscerator Delivery Grenade"
	desc = "Уникальная граната, выпускающая рой висцераторов при активации. Они выследят и нашинкуют \
			всех, кто не является оперативником, в округе."
	item = /obj/item/grenade/spawnergrenade/manhacks
	cost = 5
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/explosives/spesscarp
	name = "Space Carps Delivery Grenade"
	desc = "Классическая граната, начинённая исключительно карпами. Пригодится в любой ситуации!"
	item = /obj/item/grenade/spawnergrenade/spesscarp
	cost = 5
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/explosives/spesscarps
	name = "Space Carps Clusterbang"
	desc = "Классическая кластерная граната, начинённая исключительно карпами. Пригодится в любой ситуации!"
	item = /obj/item/grenade/clusterbuster/spawner_spesscarp
	cost = 16
	surplus = 35
	purchasable_from = UPLINK_NUKE_OPS

/datum/uplink_item/explosives/clf3
	name = "Clusterbang CLF3"
	desc = "ДОБРО ПОЖАЛОВАТЬ В АД, УБЛЮДКИ."
	item = /obj/item/grenade/clusterbuster/clf3
	cost = 28
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS
