
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Miscellaneous ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc
	group = "Miscellaneous Supplies"

//////////////////////////////////////////////////////////////////////////////
//////////////////// Paperwork and Writing Supplies //////////////////////////
//////////////////////////////////////////////////////////////////////////////


/datum/supply_pack/misc/anvil
	name = "Anvil Crate"
	desc = "Наковальня в ящике, мы откапали это на старом складе. На ней есть колесики, так что вы можете ее передвигать."
	cost = 7500
	contains = list(/obj/structure/anvil/obtainable/basic)

/datum/supply_pack/misc/artsupply
	name = "Art Supplies"
	desc = "Устройте несколько маленьких счастливых случайностей с шестью холстами, двумя мольбертами, двумя коробками цветных карандашей и радужным мелком!"
	cost = 800
	contains = list(/obj/structure/easel,
					/obj/structure/easel,
					/obj/item/canvas/nineteenXnineteen,
					/obj/item/canvas/nineteenXnineteen,
					/obj/item/canvas/twentythreeXnineteen,
					/obj/item/canvas/twentythreeXnineteen,
					/obj/item/canvas/twentythreeXtwentythree,
					/obj/item/canvas/twentythreeXtwentythree,
					/obj/item/storage/crayons,
					/obj/item/storage/crayons,
					/obj/item/toy/crayon/rainbow,
					/obj/item/toy/crayon/white,
					/obj/item/toy/crayon/white)
	crate_name = "art supply crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/book_crate
	name = "Book Crate"
	desc = "Извлеченные из архивов Nanotrasen, эти семь книг, несомненно, будут полезны для чтения."
	// cost = CARGO_CRATE_VALUE * 3
	cost = 1500
	contains = list(/obj/item/book/codex_gigas,
					/obj/item/book/manual/random,
					/obj/item/book/manual/random,
					/obj/item/book/manual/random,
					/obj/item/book/random,
					/obj/item/book/random,
					/obj/item/book/random)
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/paper
	name = "Bureaucracy Crate"
	desc = "Высокие стопки бумаг на вашем столе - большая проблема - сделайте их размером с горошину с помощью этих бюрократических принадлежностей! Содержит шесть ручек, немного фотопленки, принадлежности для этикетирования, контейнер для бумаги, копировальную бумагу, три папки, лазерную указку, две картонные коробки и две марки."//that was too forced
	cost = 1500
	contains = list(/obj/structure/filingcabinet/chestdrawer/wheeled,
					/obj/item/camera_film,
					/obj/item/hand_labeler,
					/obj/item/hand_labeler_refill,
					/obj/item/hand_labeler_refill,
					/obj/item/paper_bin,
					/obj/item/paper_bin/carbon,
					/obj/item/pen/fourcolor,
					/obj/item/pen/fourcolor,
					/obj/item/pen,
					/obj/item/pen/fountain,
					/obj/item/pen/blue,
					/obj/item/pen/red,
					/obj/item/folder/blue,
					/obj/item/folder/red,
					/obj/item/folder/yellow,
					/obj/item/clipboard,
					/obj/item/clipboard,
					/obj/item/stamp,
					/obj/item/stamp/denied,
					/obj/item/laser_pointer/purple)
	crate_name = "bureaucracy crate"

/datum/supply_pack/misc/captain_pen
	name = "Captain Pen"
	desc = "Запасная авторучка капитана."
	access = ACCESS_CAPTAIN
	cost = 5000
	contains = list(/obj/item/pen/fountain/captain)
	crate_name = "captain pen"
	crate_type = /obj/structure/closet/crate/secure/weapon //It is a combat pen

/datum/supply_pack/misc/fountainpens
	name = "Calligraphy Crate"
	desc = "Стильно подписывайте смертные приговоры с помощью этих семи перьевых ручек."
	cost = 730
	contains = list(/obj/item/storage/box/fountainpens,
					/obj/item/paper_bin)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "calligraphy crate"

/datum/supply_pack/misc/toner
	name = "Toner Crate"
	desc = "Потратил слишком много чернил на печать фотографий задниц? Не волнуйтесь, с этими шестью заправками тонера вы будете печатать документы еще долго"
	cost = 200 * 4
	contains = list(/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner)
	crate_name = "toner crate"

/datum/supply_pack/misc/toner_large
	name = "Toner Crate (Large)"
	desc = "Устали менять картриджи с тонером? Эти шесть сверхпрочных картриджей содержат примерно в пять раз больше тонера, чем базовая модель!"
	cost = 200 * 6
	contains = list(/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large)
	crate_name = "large toner crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Entertainment ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc/coloredsheets
	name = "Bedsheet Crate"
	desc = "Придайте вашей ночной жизни всплеск красок с помощью этого ящика, наполненного простынями! Содержит в общей сложности девять разноцветных листов."
	cost = 1250
	contains = list(/obj/item/bedsheet/blue,
					/obj/item/bedsheet/green,
					/obj/item/bedsheet/orange,
					/obj/item/bedsheet/purple,
					/obj/item/bedsheet/red,
					/obj/item/bedsheet/yellow,
					/obj/item/bedsheet/brown,
					/obj/item/bedsheet/black,
					/obj/item/bedsheet/rainbow)
	crate_name = "colored bedsheet crate"

/datum/supply_pack/misc/bicycle
	name = "Bicycle"
	desc = "Nanotrasen напоминает всем сотрудникам, чтобы они никогда не играли с силами, находящимися вне их контроля."
	cost = 5000000
	contains = list(/obj/vehicle/ridden/bicycle)
	crate_name = "Bicycle Crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/misc/bigband
	name = "Big Band Instrument Collection"
	desc = "Заставьте свою унылую станцию двигаться с этой прекрасной коллекцией! Содержит девять различных инструментов!"
	cost = 5000
	crate_name = "Big band musical instruments collection"
	contains = list(/obj/item/instrument/violin,
					/obj/item/instrument/guitar,
					/obj/item/instrument/glockenspiel,
					/obj/item/instrument/accordion,
					/obj/item/instrument/saxophone,
					/obj/item/instrument/trombone,
					/obj/item/instrument/recorder,
					/obj/item/instrument/harmonica,
					/obj/structure/musician/piano/unanchored)
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/casinocrate
	name = "Casino Crate"
	desc = "Откройте свое собственное грандиозное казино с блэкджеком и шлюхами !"
	cost = 3000
	contains = list(/obj/item/circuitboard/computer/arcade/battle,
					/obj/item/circuitboard/computer/arcade/battle,
					/obj/item/circuitboard/computer/arcade/orion_trail,
					/obj/item/circuitboard/computer/arcade/orion_trail,
					/obj/item/circuitboard/computer/arcade/tetris,
					/obj/item/circuitboard/computer/arcade/tetris,
					/obj/item/circuitboard/computer/slot_machine,
					/obj/item/circuitboard/computer/slot_machine,
					/obj/item/circuitboard/computer/slot_machine,
					/obj/item/circuitboard/computer/slot_machine,
					/obj/item/circuitboard/computer/slot_machine,
					/obj/item/circuitboard/computer/slot_machine)
	crate_name = "casino crate"

/datum/supply_pack/misc/coincrate
	name = "Coin Crate"
	desc = "Псссс, привет, ты. Да, ты. Я слышал, что монеты могут делать какие-то особенные вещи на вашей станции, давать вам доступ к некоторым довольно крутым вещам. Вот в чем дело, вы даете мне несколько кредитов, а я даю вам несколько монет. Звучит как сделка? Я дам тебе 10 за 10000 кредитов."
	contraband = TRUE
	cost = 3000
	contains = list(/obj/item/coin/silver) // 400 x 10 = 2 sheets of silver for 2300cr
	crate_name = "coin crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/misc/coincrate/generate()
	. = ..()
	for(var/i in 1 to 9)
		new /obj/item/coin/silver(.)

/datum/supply_pack/misc/dueling_stam
	name = "Dueling Pistols"
	desc = "Разрешите все свои ссоры каким-нибудь несмертельным развлечением."
	cost = 2000
	contains = list(/obj/item/storage/lockbox/dueling/hugbox/stamina)
	crate_name = "dueling pistols"

/datum/supply_pack/misc/dueling_stam/generate()
	. = ..()
	for(var/i in 1 to 3)
		new /obj/item/storage/lockbox/dueling/hugbox/stamina(.)

/datum/supply_pack/misc/dueling_lethal
	name = "Lethal Dueling Pistols"
	desc = "Уладьте свои разногласия истинным способом космонавта."
	cost = 3000
	contraband = TRUE
	contains = list(/obj/item/storage/lockbox/dueling/hugbox,
	/obj/item/storage/lockbox/dueling/hugbox,
	/obj/item/storage/lockbox/dueling/hugbox)
	crate_name = "dueling pistols (lethal)"

/datum/supply_pack/misc/dueling_death
	name = "Elimination Dueling Pistols"
	desc = "Уже полдень."
	cost = 5000
	hidden = TRUE
	contains = list(/obj/item/storage/lockbox/dueling)
	crate_name = "dueling pistols (elimination)"

/datum/supply_pack/misc/dirtymags
	name = "Dirty Magazines"
	desc = "Выбрось свои мысли из головы, оперативник, тебе нужно поработать. Три товара на заказ. Возможные результаты: Скорозарядные устройства калибра 357, патентованные магазины Kitchen Gun или магазины Stetchkin."
	hidden = TRUE
	cost = 4000
	var/num_contained = 3
	contains = list(/obj/item/ammo_box/a357,
					/obj/item/ammo_box/magazine/pistolm9mm,
					/obj/item/ammo_box/magazine/m45/kitchengun)
	crate_name = "crate"

/datum/supply_pack/misc/dirtymags/fill(obj/structure/closet/crate/C)
	var/list/L = contains.Copy()
	for(var/i in 1 to num_contained)
		var/item = pick_n_take(L)
		new item(C)

//////////////////////////////////////////////////////////////////////////////
///////////////////////////////// Misc Supplies //////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc/candles
	name = "Candle Crate"
	desc = "Устройте романтический ужин или устройте танцы с помощью этих дополнительных свечей и цветных карандашей."
	cost = 850
	contains = list(/obj/item/storage/fancy/candle_box,
					/obj/item/storage/fancy/candle_box,
					/obj/item/storage/box/matches)
	crate_name = "candle crate"

/datum/supply_pack/misc/diamondring
	name = "Diamond Ring"
	desc = "Покажи им, что твоя любовь подобна бриллианту: нерушима и вечна. Доставлено прямиком из детских рабовладельческих картелей на шахтах космической Африки."
	cost = 10000
	contains = list(/obj/item/storage/fancy/ringbox/diamond)
	crate_name = "diamond ring crate"

/datum/supply_pack/misc/exoticfootwear
	name = "Exotic Footwear Crate"
	desc = "Обувь, популярная среди ящериц и экзотических танцоров, входящая в комплект поставки, несомненно, даст вашим ногам передышку, которой они заслуживают. Sweet Kicks Inc. не несет ответственности за любой ущерб или бедствие"
	cost = 4337
	contains = list(/obj/item/clothing/shoes/wraps,
					/obj/item/clothing/shoes/wraps,
					/obj/item/clothing/shoes/wraps/silver,
					/obj/item/clothing/shoes/wraps/silver,
					/obj/item/clothing/shoes/wraps/red,
					/obj/item/clothing/shoes/wraps/red,
					/obj/item/clothing/shoes/wraps/blue,
					/obj/item/clothing/shoes/wraps/blue,
					/obj/item/clothing/shoes/clown_shoes,
					/obj/item/clothing/shoes/kindleKicks)
	crate_name = "footie crate"

/datum/supply_pack/misc/funeral
	name = "Funeral Supplies"
	desc = "Оплакивайте своих умерших должным образом, отправляя им записки, наполненные любовью, чистую одежду и соответствующую церемонию. Содержит две упаковки свечей, похоронную одежду, цветы, корзину для бумаги и цветные карандаши, которые помогут в религиозных ритуалах. Гроб в комплекте."
	cost = 1200
	contains = list(/obj/item/clothing/under/misc/burial,
					/obj/item/storage/fancy/candle_box,
					/obj/item/storage/fancy/candle_box,
					/obj/item/reagent_containers/food/snacks/grown/harebell,
					/obj/item/reagent_containers/food/snacks/grown/harebell,
					/obj/item/reagent_containers/food/snacks/grown/poppy/geranium,
					/obj/item/reagent_containers/food/snacks/grown/poppy/geranium,
					/obj/item/reagent_containers/food/snacks/grown/poppy/lily,
					/obj/item/reagent_containers/food/snacks/grown/poppy/lily,
					/obj/item/storage/crayons,
					/obj/item/paper_bin
					)
	crate_name = "coffin"
	crate_type = /obj/structure/closet/crate/coffin

/datum/supply_pack/misc/jewelry
	name = "Jewelry Crate"
	desc = "Выделяйся с этим ящиком драгоценностей. В комплект входит золотое ожерелье и набор из двух колец."
	cost = 5000
	contains = list(/obj/item/clothing/neck/necklace/dope,
					/obj/item/storage/fancy/ringbox,
					/obj/item/storage/fancy/ringbox/silver
					)
	crate_name = "jewelry crate"

/datum/supply_pack/misc/jukebox
	name = "Jukebox"
	desc = "Это не достойно пояснения"
	cost = 10000
	contains = list(/obj/machinery/jukebox)
	crate_name = "Jukebox"

/datum/supply_pack/misc/moniq // BLUEMOON FINK ADD
	name = "Jukebox (Muz-TV)"
	desc = "Туц туц туц туц"
	cost = 15000
	contains = list(/obj/item/sign/moniq)
	crate_name = "Jukebox (Muz-TV)"


/datum/supply_pack/misc/abandonedcrate
	name = "Loot Box"
	desc = "Испытайте свою удачу с этими высокозащищенными ящиками с добычей! Разгадайте замок, выиграйте отличные призы! ПРЕДУПРЕЖДЕНИЕ: ВЗРЫВООПАСНЫЙ ПРОВАЛ."
	contraband = TRUE
	cost = 10000 // 15к за ящик которые даже не интересно депать? Zaaaaamn
	contains = list(/obj/structure/closet/crate/secure/loot)
	crate_name = "abandoned crate"
	crate_type = /obj/structure/closet/crate/large
	dangerous = TRUE

/datum/supply_pack/misc/potted_plants
	name = "Potted Plants Crate"
	desc = "Украсьте станцию этими прекрасными растениями! Содержит случайный ассортимент из пяти горшечных растений из отдела исследований горшечных растений Nanotrasen."
	cost = 730
	contains = list(/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random)
	crate_name = "potted plants crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/service/religious_supplies
	name = "Religious Supplies Crate"
	desc = "Следите за тем, чтобы ваш местный капеллан был доволен и хорошо снабжался, чтобы они не навлекли осуждение на ваш грузовой отсек. Содержит две бутылки со святой водой, библии, одеяния капеллана и погребальную одежду."
	cost = 4000	// it costs so much because the Space Church needs funding to build a cathedral
	contains = list(/obj/item/reagent_containers/food/drinks/bottle/holywater,
					/obj/item/reagent_containers/food/drinks/bottle/holywater,
					/obj/item/storage/book/bible/booze,
					/obj/item/storage/book/bible/booze,
					/obj/item/clothing/suit/hooded/chaplain_hoodie,
					/obj/item/clothing/suit/hooded/chaplain_hoodie)
	crate_name = "religious supplies crate"

/datum/supply_pack/misc/holy_knight
	name = "Knights of the Round Table Crate"
	desc = "Содержит один священный клеймор для особо убеждённых паладинов, три обычных меча для статистов, четыре комплекта рыцарских доспехов для тех, кто хочет тяжело топать по коридорам, и бочку святой воды на случай, если кто-то снова решил дружить с демонами."
	cost = 24999
	contains = list(/obj/item/nullrod/claymore,
					/obj/item/claymore,
					/obj/item/claymore,
					/obj/item/claymore,
					/obj/item/clothing/suit/armor/riot/knight,
					/obj/item/clothing/suit/armor/riot/knight/blue,
					/obj/item/clothing/suit/armor/riot/knight/red,
					/obj/item/clothing/suit/armor/riot/knight/yellow,
					/obj/item/clothing/head/helmet/knight,
					/obj/item/clothing/head/helmet/knight/blue,
					/obj/item/clothing/head/helmet/knight/red,
					/obj/item/clothing/head/helmet/knight/yellow,
					/obj/structure/reagent_dispensers/watertank/holy)
	crate_name = "holy knight crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/shower
	name = "Shower Supplies"
	desc = "Каждому нужно немного R&R. Убедитесь, что вы можете получить свое, заказав этот ящик, наполненный полотенцами, резиновыми уточками и небольшим количеством мыла!"
	cost = 1000
	contains = list(/obj/item/reagent_containers/rag/towel,
					/obj/item/reagent_containers/rag/towel,
					/obj/item/reagent_containers/rag/towel,
					/obj/item/reagent_containers/rag/towel,
					/obj/item/reagent_containers/rag/towel,
					/obj/item/reagent_containers/rag/towel,
					/obj/item/bikehorn/rubberducky,
					/obj/item/bikehorn/rubberducky,
					/obj/item/soap/nanotrasen)
	crate_name = "shower crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Misc + Decor ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc/carpet
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "Classic Carpet Single-Pack"
	desc = "Напольная плитка действует вам на нервы? Эта стопка из 50 единиц очень мягкого ковра свяжет воедино любую комнату."
	cost = 200
	contains = list(/obj/item/stack/tile/carpet/fifty)

/datum/supply_pack/misc/carpet/black
	name = "Black Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/black/fifty)

/datum/supply_pack/misc/carpet/arcade
	name = "Arcade Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/arcade/fifty)

/datum/supply_pack/misc/carpet/premium
	name = "Monochrome Carpet Single-Pack"
	desc = "Экзотические ковры для всех ваших потребностей в декорировании. Эта стопка из 30 единиц очень мягкого ковра свяжет воедино любую комнату."
	cost = 250
	contains = list(/obj/item/stack/tile/carpet/monochrome/thirty)

/datum/supply_pack/misc/carpet/premium/blackred
	name = "Black-Red Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/blackred/thirty)

/datum/supply_pack/misc/carpet/premium/royalblack
	name = "Royal Black Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/royalblack/thirty)

/datum/supply_pack/misc/carpet/premium/royalblue
	name = "Royal Blue Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/royalblue/thirty)

/datum/supply_pack/misc/carpet/premium/red
	name = "Red Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/red/thirty)

/datum/supply_pack/misc/carpet/premium/purple
	name = "Purple Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/purple/thirty)

/datum/supply_pack/misc/carpet/premium/orange
	name = "Orange Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/orange/thirty)

/datum/supply_pack/misc/carpet/premium/green
	name = "Green Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/green/thirty)

/datum/supply_pack/misc/carpet/premium/cyan
	name = "Cyan Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/cyan/thirty)

/datum/supply_pack/misc/carpet/premium/blue
	name = "Blue Carpet Single-Pack"
	contains = list(/obj/item/stack/tile/carpet/blue/thirty)

/datum/supply_pack/misc/noslipfloor
	name = "High-traction Floor Tiles"
	desc = "Сделайте скольжение делом прошлого с помощью шестидесяти промышленных противоскользящих напольных плиток!"
	cost = 2000
	contains = list(/obj/item/stack/tile/noslip/thirty,
					/obj/item/stack/tile/noslip/thirty)
	crate_name = "high-traction floor tiles crate"

/datum/supply_pack/misc/blackmarket_telepad
	name = "Black Market LTSRBT"
	desc = "Нужен более быстрый и качественный способ транспортировки ваших нелегальных товаров со станции и обратно? Не бойтесь, приемопередатчик Bluespace с большой и малой дальностью действия здесь, чтобы помочь. Содержит схему LTSRBT, два кристалла bluespace и один ansible."
	cost = 8000
	contraband = TRUE
	contains = list(/obj/item/circuitboard/machine/ltsrbt,
		/obj/item/stack/ore/bluespace_crystal/artificial,
		/obj/item/stack/ore/bluespace_crystal/artificial,
		/obj/item/stock_parts/subspace/ansible)
	crate_name = "crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Lewd Supplies ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc/lewd
	name = "Lewd Crate" // OwO
	desc = "Пссст, хочешь хорошо провести время со своими шлюхами? Что ж, у меня есть то, что ты хочешь! Одежда для горничной, фаллоимитаторы, ошейники и многое другое!"
	cost = 5250
	contraband = TRUE
	contains = list(/obj/item/dildo/custom,
					/obj/item/dildo/custom,
					/obj/item/vending_refill/kink,
					/obj/item/vending_refill/kink,
					/obj/item/clothing/under/costume/maid,
					/obj/item/clothing/under/costume/maid,
					/obj/item/electropack/shockcollar,
					/obj/item/electropack/shockcollar,
					/obj/item/restraints/handcuffs/fake/kinky,
					/obj/item/restraints/handcuffs/fake/kinky,
					/obj/item/clothing/head/kitty/genuine, // Why its illegal
					/obj/item/clothing/head/kitty/genuine,
					/obj/item/storage/pill_bottle/penis_enlargement,
					/obj/structure/reagent_dispensers/keg/aphro)
	crate_name = "lewd kit"
	crate_type = /obj/structure/closet/crate

///Special supply crate that generates random syndicate gear up to a determined TC value

/datum/supply_pack/misc/syndicate

	name = "Assorted Syndicate Gear"

	desc = "Contains a random assortment of syndicate gear."

	special = TRUE ///Cannot be ordered via cargo

	contains = list()

	crate_name = "syndicate gear crate"

	crate_type = /obj/structure/closet/crate

	var/crate_value = 30 ///Total TC worth of contained uplink items

	uplink_flags = UPLINK_TRAITORS

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Syndicate Packs /////////////////////////////
//////////////////////////////////////////////////////////////////////////////

//Generate assorted uplink items, taking into account the same surplus modifiers used for surplus crates
//(this is exclusively used for the rare variant of the stray cargo event!)
/datum/supply_pack/misc/syndicate/fill(obj/structure/closet/crate/C)
	var/list/uplink_items = get_uplink_items(uplink_flags, FALSE)
	while(crate_value)
		var/category = pick(uplink_items)
		var/item = pick(uplink_items[category])
		var/datum/uplink_item/I = uplink_items[category][item]
		if(!I.surplus || prob(100 - I.surplus))
			continue
		if(crate_value < I.cost)
			continue
		crate_value -= I.cost
		new I.item(C)

/datum/supply_pack/misc/commandkeys
	name = "Command Encryption Key Crate"
	desc = "Набор ключей шифрования, которые дают доступ к командной радиосети. Набор ключей шифрования, которые дают доступ к командной радиосети.по крайней мере, свести к минимуму перебранки со стороны командного состава."
	access = ACCESS_BRIDGE_OFFICER
	cost = 6000
	contains = list(/obj/item/encryptionkey/headset_com = 3)
	crate_type = /obj/structure/closet/crate/secure/gear
	crate_name = "command encryption key crate"
