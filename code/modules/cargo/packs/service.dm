
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Service //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/service
	group = "Service"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Cargo ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/service/wrapping_paper
	name = "Cargo Packaging Crate"
	desc = "Хотите отправить своим близким шоколад в подарочной упаковке, мягкие игрушки или отрубленную голову клоуна? Вы можете сделать все это с помощью этого ящика, полного праздничной (и обычной) оберточной бумаги. Также содержит ручную этикетировочную машину и устройство для маркировки места назначения для удобства доставки!"
	cost = 1000
	contains = list(/obj/item/stack/wrapping_paper,
					/obj/item/stack/wrapping_paper,
					/obj/item/stack/wrapping_paper,
					/obj/item/stack/packageWrap,
					/obj/item/stack/packageWrap,
					/obj/item/stack/packageWrap,
					/obj/item/dest_tagger,
					/obj/item/hand_labeler)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "wrapping paper crate"

/datum/supply_pack/service/cargo_supples
	name = "Cargo Supplies Crate"
	desc = "Продал все, что не было прикручено? Вы можете сразу вернуться к работе с этим ящиком, содержащим марки, экспортный сканер, устройство для маркировки места назначения, ручную этикетировочную машину и некоторые виды упаковки. Теперь с дополнительными картриджами с тонером!"
	cost = 1000
	contains = list(/obj/item/stamp,
					/obj/item/stamp/denied,
					/obj/item/export_scanner,
					/obj/item/dest_tagger,
					/obj/item/hand_labeler,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/stack/packageWrap,
					/obj/item/stack/packageWrap)
	crate_name = "cargo supplies crate"

/datum/supply_pack/service/mule
	name = "MULEbot Crate"
	desc = "Розововолосая Квартирмейстерша не выполняет свою работу? Замените ее этим неутомимым работником сегодня!"
	cost = 2000
	contains = list(/mob/living/simple_animal/bot/mulebot)
	crate_name = "\improper MULEbot Crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/service/minerkit
	name = "Shaft Miner Starter Kit"
	desc = "Все шахтеры умерли слишком быстро? Айко хочет почувствовать вкус жизни за пределами станции? В любом случае, этот набор - лучший способ превратить обычного члена экипажа в машину для добычи руды и уничтожения монстров. Содержит мезонные очки, кирку, продвинутый сканер для добычи полезных ископаемых, карго гарнитуру, мешок для руды, противогаз и костюм исследователя. Требуется доступ КМ для открытия."
	cost = 2500
	contains = list(/obj/item/pickaxe/mini,
			/obj/item/clothing/glasses/meson,
			/obj/item/t_scanner/adv_mining_scanner/lesser,
			/obj/item/radio/headset/headset_cargo/mining,
			/obj/item/storage/bag/ore,
			/obj/item/clothing/suit/hooded/explorer/standard,
			/obj/item/clothing/mask/gas/explorer)
	crate_name = "shaft miner starter kit"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/snowmobile
	name = "Snowmobile kit"
	desc = "Пойман в ловушку на холодной пустоши? Нужно быстро передвигаться? Приобретите отремонтированный снегоход с бесплатной гарантией 10 микросекунд!"
	cost = 1500 // 1000 points cheaper than ATV
	contains = list(/obj/vehicle/ridden/atv/snowmobile = 1,
			/obj/item/key = 1,
			/obj/item/clothing/mask/gas/explorer = 1)
	crate_name = "Snowmobile kit"
	crate_type = /obj/structure/closet/crate/large

//////////////////////////////////////////////////////////////////////////////
/////////////////////// Chef, Botanist, Bartender ////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/service/buildabar
	name = "Build a Bar Crate"
	desc = "Хотите создать свое собственное маленькое убежище? Может быть, вы просто хотите открыть магазин прямо перед барменом. Каковы бы ни были ваши причины, начните с этого с помощью этого удобного набора. Содержит печатные платы для барного оборудования, некоторые детали и некоторые основные принадлежности для бармена. (Батарейки в комплект не входят)"
	cost = 3750
	contains = list(/obj/item/storage/box/drinkingglasses,
					/obj/item/storage/box/drinkingglasses,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/matter_bin,
					/obj/item/stock_parts/manipulator,
					/obj/item/stock_parts/manipulator,
					/obj/item/stock_parts/manipulator,
					/obj/item/stock_parts/capacitor,
					/obj/item/stock_parts/capacitor,
					/obj/item/stack/sheet/metal/ten,
					/obj/item/stack/sheet/metal/five,
					/obj/item/stack/sheet/glass/five,
					/obj/item/stack/cable_coil/random,
					/obj/item/reagent_containers/rag,
					/obj/item/book/manual/wiki/barman_recipes,
					/obj/item/book/granter/action/drink_fling,
					/obj/item/reagent_containers/food/drinks/shaker,
					/obj/item/circuitboard/machine/chem_dispenser/drinks/beer,
					/obj/item/circuitboard/machine/chem_dispenser/drinks,
					/obj/item/circuitboard/machine/dish_drive)
	crate_name = "build a bar crate"

/datum/supply_pack/service/food_cart
	name = "Food Cart Crate"
	desc = "Хотите продавать еду на ходу? Повар потерял свою тележку? Что ж, так уж получилось, что у нас есть несколько свободных тележек!"
	cost = 1000
	contains = list(/obj/machinery/food_cart)
	crate_name = "food cart crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/icecream_cart
	name = "Ice Cream Cart Crate"
	desc = "Плазменный огонь слишком горяч для тебя? Хотите приятного угощения после тяжелого исследований на секс столе? Что ж, теперь у нас есть тележка для вас! В этом чане для мороженого есть все необходимое, чтобы приготовить вам и вашим друзьям настоящее угощение из мороженого! В этой тележке есть несколько ингредиентов для каждого вида мороженого, которое можно использовать в виде шариков."
	cost = 2750 //Comes prestocked with basic ingredients
	contains = list(/obj/machinery/icecream_vat)
	crate_name = "ice cream vat crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/grill
	name = "Grilling Starter Kit"
	desc = "Эй, пап, я голоден. Привет, Голодный, Я НОВЫЙ СТАРТОВЫЙ НАБОР ДЛЯ ГРИЛЯ, ПОЛУЧИ СЕЙЧАС ВСЕГО 3000 БАКСОВ! Содержит гриль для приготовления пищи и пять листов угля."
	cost = 3000
	contains = list(/obj/item/stack/sheet/mineral/coal/five,
					/obj/machinery/grill/unwrenched)
	crate_name = "grilling starter kit crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/grillfuel
	name = "Grilling Fuel Kit"
	desc = "Содержит уголь и угольные принадлежности. (Примечание: всего десять листов угля.)"
	cost = 1000
	contains = list(/obj/item/stack/sheet/mineral/coal/ten)
	crate_name = "grilling fuel kit crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/cutlery
	name = "Kitchen Cutlery Deluxe Set"
	desc = "Нужно нарезать кубиками помидоры? Что ж, у нас есть то, что вам нужно! В комплекте хороший набор ножей, вилок, тарелок, стаканов и точильнй камень."
	cost = 10000
	contains = list(/obj/item/sharpener, //Deluxe for a reason
					/obj/item/kitchen/fork,
					/obj/item/kitchen/fork,
					/obj/item/kitchen/knife,
					/obj/item/kitchen/knife,
					/obj/item/kitchen/knife,
					/obj/item/kitchen/knife,
					/obj/item/kitchen/knife/butcher,
					/obj/item/kitchen/knife/butcher,
					/obj/item/kitchen/rollingpin,
					/obj/item/trash/plate,
					/obj/item/trash/plate,
					/obj/item/trash/plate,
					/obj/item/trash/plate,
					/obj/item/reagent_containers/food/drinks/drinkingglass,
					/obj/item/reagent_containers/food/drinks/drinkingglass,
					/obj/item/reagent_containers/food/drinks/drinkingglass,
					/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass,
					/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass)
	crate_name = "kitchen cutlery deluxe set"

/datum/supply_pack/service/replacementdb
	name = "Replacement Defensive Bar Shotgun"
	desc = "Кто-то украл двустволку у бармена пока он отвлекся на вульпу? Дайте ему еще две с значительной наценкой! Поставляется с двумя неиспользованными двуствольными дробовиками для каждого бармена, дополнительные патроны в комплект не входят. Для открытия требуется доступ бармена."
	cost = 2200
	access = ACCESS_BAR
	contraband = TRUE
	contains = list(/obj/item/gun/ballistic/revolver/doublebarrel)
	crate_name = "replacement double-barrel crate"
	crate_type = /obj/structure/closet/crate/secure

//////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Janitor //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/service/advlighting
	name = "Advanced Lighting crate"
	desc = "Благодаря передовым технологиям освещения мы здесь, на фабрике ламп, смогли производить больше ламп и светильных изделий! В этом ящике есть три лампы, коробка с лампочками и ультрасовременное устройство быстрого освещения!"
	cost = 2750
	contains = list(/obj/item/construction/rld,
					/obj/item/flashlight/lamp,
					/obj/item/flashlight/lamp,
					/obj/item/flashlight/lamp/green,
					/obj/item/storage/box/lights/mixed)
	crate_name = "advanced lighting crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/lightbulbs
	name = "Replacement Lights" //Subgrouping this with Advanced Lighting Crate, they're both lighting related.
	desc = "Да воссияет свет Эфира над этой станцией! Или, по крайней мере, свет сорока двух лампочек и двадцати одной лампочки накаливания, а также заменитель ламп."
	cost = 1200
	contains = list(/obj/item/storage/box/lights/mixed,
					/obj/item/storage/box/lights/mixed,
					/obj/item/storage/box/lights/mixed,
					/obj/item/lightreplacer)
	crate_name = "replacement lights"

/datum/supply_pack/service/janitor/advanced
	name = "Advanced Sanitation Crate"
	desc = "Содержит все необходимое для продвинутой команды по очистке космического пространства. Этот набор включает в себя мешок для мусора, усовершенствованную швабру, флакон средства для уборки помещений, буфер для пола и проектор голосигнала. Требуется доступ уборщика, чтобы открыть"
	cost = 5700
	access = ACCESS_JANITOR
	contains = list(/obj/item/storage/bag/trash/bluespace,
					/obj/item/reagent_containers/spray/cleaner,
					/obj/item/mop/advanced,
					/obj/item/lightreplacer,
					/obj/item/janicart_upgrade/buffer,
					/obj/item/holosign_creator)
	crate_name = "advanced santation crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/janitor/janpimp
	name = "Custodial Cruiser"
	desc = "Клоун украл твою машину? Помощник запер его в дормах? Закажите новый и возвращайтесь к стильной уборке!"
	cost = 3000
	access = ACCESS_JANITOR
	contains = list(/obj/vehicle/ridden/janicart,
					/obj/item/key/janitor)
	crate_name = "janitor ride crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/service/janitor/janitank
	name = "Janitor Backpack Crate"
	desc = "Призовите божественный суд на грязь и копоти с помощью этого вместительного рюкзака для уборщиков. Содержит 500 единиц очистителя для очистки станции. Для открытия требуется доступ уборщика."
	cost = 1000
	access = ACCESS_JANITOR
	contains = list(/obj/item/watertank/janitor)
	crate_name = "janitor backpack crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/janitor/janpremium
	name = "Janitor Supplies (Premium)"
	desc = "В союзе опекунов неспокойно, поэтому мы собрали для вас кое-что получше. В этом ящике вы можете получить совершенно новый химический сушильный агент. Эта штука - дело рук слизи или магии! В этом ящике также находится тряпка для проверки магии сушильного агента, несколько чистящих гранат, несколько запасных бутылок с нашатырным спиртом и MCE."
	cost = 2700
	contains = list(/obj/item/grenade/clusterbuster/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/reagent_containers/rag,
					/obj/item/reagent_containers/glass/bottle/ammonia,
					/obj/item/reagent_containers/glass/bottle/ammonia,
					/obj/item/reagent_containers/glass/bottle/ammonia,
					/obj/item/reagent_containers/spray/drying_agent)
	crate_name = "premium janitorial crate"

/datum/supply_pack/service/janitor/starter
	name = "Janitorial Supplies (Standard)"
	desc = "Боритесь с грязью и копотью с помощью средств для уборки Nanotrasen Essentials(tm)! Содержит три ведра, знаки предостережения и гранаты для чистки. Также есть одна швабра, распылитель для чистки, тряпка, жидкое мыло и мешок для мусора."
	cost = 1300
	contains = list(/obj/item/reagent_containers/glass/bucket,
					/obj/item/reagent_containers/glass/bucket,
					/obj/item/reagent_containers/glass/bucket,
					/obj/item/mop,
					/obj/item/clothing/suit/caution,
					/obj/item/clothing/suit/caution,
					/obj/item/clothing/suit/caution,
					/obj/item/storage/bag/trash,
					/obj/item/reagent_containers/spray/cleaner,
					/obj/item/reagent_containers/rag,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/soap/nanotrasen)
	crate_name = "standard janitorial crate"

/datum/supply_pack/service/janitor/janicart
	name = "Janicart and Galoshes Crate"
	desc = "Краеугольный камень любого успешного уборщика. Пока у вас есть ноги, эта пара галош будет надежно удерживать их на земле. Также содержит тележку для уборки."
	cost = 2000
	contains = list(/obj/structure/janitorialcart,
					/obj/item/clothing/shoes/galoshes)
	crate_name = "janitorial cart crate"
	crate_type = /obj/structure/closet/crate/large
