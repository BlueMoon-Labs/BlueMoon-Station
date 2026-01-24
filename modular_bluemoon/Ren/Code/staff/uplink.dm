// -----------------------------------------[bundle]-----------------------------[bundle]----------------------------------[bundle]-------------------------------------
///Одежда
/datum/uplink_item/inteq/indiv_number
	name = "Personal number"
	desc = "Армейский жетон с твоим личным цифровым номером и классом."
	item = /obj/item/clothing/accessory/indiv_number
	cost = 0
	limited_stock = 1
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/suits/inteq_infiltrator_bundle
	name = "SpecOps Infiltration Gear Case"
	desc = "Тактический костюм разработки Мародёров Горлекса, слегка изменённый внутренними предприятиями inteQ для собственных нужд. Лёгкий, прочный и тихий костюм совершенно не сковывает движений владельца. Покрывает всё тело носителя и использует внутренний блок шифровки голоса, гарантируя, что никто не узнает вашу личность. Набор содержит в себе костюм, бронежилет, ботинки, перчатки, шлем и балаклаву. Не предназначен для использования в условиях пониженного давления."
	item = /obj/item/storage/toolbox/infiltrator/inteq
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/bundles_tc/angel
	name = "Angel of death"
	desc = "Набор очень древней брони, использовавшейся в первых космических войнах Солнечной федерацией. Для полного раскрытия потенциала этого полутонного куска керамита необходимо вживить специальный орган, значительно увеличивающий выживаемость и силу владельца. Пришло время доказать, что ты достоин зваться 'Ангелом смерти'."
	item = /obj/item/storage/box/syndie_kit/spacehero
	cost = 30
	purchasable_from =  UPLINK_NUKE_OPS

/datum/uplink_item/bundles_tc/grey
	name = "The Greatest of the Greys"
	desc = "Вещи величайшего грейтайдера. Его копьё впитало в себя столько крови, страха и превозмогания, что стало великим артефактом равным которому нет в бою. С этим даже один человек сможет стать целым тайфуном."
	item = /obj/item/storage/box/syndie_kit/grayhero
	cost = 14
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/explosives/bombcollar
	name = "Bomb collar"
	desc = "Ошейник с бомбой. Больше нечего добавить. Сигналлер в комплект не входит."
	item = /obj/item/electropack/shockcollar/bomb
	cost = 1
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/suits/hank
	name = "AAHW trophey"
	desc = "Старое и потрёпаное пальто, бандана и красные очки. От всего этого невероятно розит кровью, но если свыкнуться с этим, \
			костюм подарит рефлексы своего прошлого владельца. Увернуться от пули ещё никогда не было так стильно."
	item = /obj/item/storage/box/inteq_kit/hank
	cost = 13
	purchasable_from = ~(UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/suits/iron_tombstone
	name = "Iron tombstone"
	desc = "Древний, но от этого не менее грозный бронекостюм. Представляет невероятную защиту от пуль и осколков, но сковывает движения. Или так было до того, как технический отдел не приделал под основу пассивный экзоскелет.\
			Теперь эта пятнадцати килограммовая пластина сбережёт твоё личико от недружественного огня."
	item = /obj/item/clothing/suit/space/hardsuit/iron_tombstone
	cost = 10
	purchasable_from = ~(UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/suits/quet
	name = "Quiet kid kit"
	desc = "Тебя выгоняют из дома на самоубийственную миссию, а менять толстовку с кепкой на каску с бронежилетом не хочется? Наборы из гибких пластин помогут с этим и будут отлично сидеть под любой одеждой."
	item = /obj/item/storage/box/inteq_kit/quetkid
	cost = 3
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)

///Оружие
/datum/uplink_item/inteq/angle_grinder
	name = "USHM"
	desc = "Индустриальный инструмент, предназначенный для резки армированного бетона и металлических стен. Так же отлично прорезает и “живые преграды”."
	item = /obj/item/pickaxe/drill/jackhammer/angle_grinder
	cost = 8
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/inteq/pulse_pistol
	name = "Melter"
	desc = "Генератор высокотемпературной плазмы, предназначенный для производственных нужд, но после внедрения технологий NT получил возможность отправлять сгусток плазмы в полёт. Имеет два режима стрельбы"
	item = /obj/item/gun/energy/pulse/pistol/inteq
	cost = 15
	limited_stock = 1
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/inteq/canceller
	name = "Canceller"
	desc = "Старый пистолет для не летальных задержаний использовавшийся спецслужбами Солнечной федерации. Вместо батареи был поставлен РИТЭГ, благодаря чему заряд постепенно восполняется, а рукам становится тепло в этом холодном космосе."
	item = /obj/item/gun/energy/laser/canceller
	cost = 6
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/inteq/sand_parasite
	name = "Sand parasite"
	desc = "Искусственно выращенный паразит, пожирающий тело носителя и перестраивающий его в более пластичную форму. Необратимо лишает носителя человечности в обмен даруя способности к мимикрии, при этом не мешая взаимодействовать с окружением."
	item = /obj/item/reagent_containers/syringe/sand
	cost = 15
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/dangerous/garand
	name = "Old, but gold rifle"
	desc = "Классическая полуавтоматическая винтовка с деревянной фурнитурой под калибр .308 winchester. Мы знаем как трудно достать в наше время сменные клипсы, по этому в комплекте идёт диск с чертежами патронов для автолата."
	item = /obj/item/storage/backpack/guitarbag/sniper
	cost = 9 //у патронов .308 оказывается понизили урон до 45 с 60.
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)


/obj/item/storage/box/inteq_kit/new_heroes/PopulateContents()
	switch (pickweight(list("bloodyspai" = 3, "hacker" = 3,"sabotage" = 3, "death_quin" = 3, "stealth" = 2, "bond" = 2, "screwed" = 2,  "guns" = 2, "murder" = 2, "launchman" = 2, "baseball" = 1, "implant" = 1, "darklord" = 1, "sniper" = 1, "metaops" = 1, "ninja" = 1, "ancient" = 1, "spacemarine" = 1)))
		if("bloodyspai") // 30 tc now this is more right
			new /obj/item/storage/box/syndie_kit/chameleon(src) // 2 tc since it's not the full set /теперь полный
			new /obj/item/card/id/inteq(src) // 2 tc
			new /obj/item/clothing/shoes/chameleon/noslip(src) // 2 tc
			new /obj/item/camera_bug(src) // 1 tc
			new /obj/item/multitool/ai_detect(src) // 1 tc
			new /obj/item/encryptionkey/inteq(src) // 2 tc
			new /obj/item/reagent_containers/syringe/mulligan(src) // 4 tc
			new /obj/item/kitchen/knife/backstabber(src) //заменяем обычную бабочку на крутую 12тк
			new	/obj/item/paper/guides/backstabber(src)
			new /obj/item/storage/fancy/cigarettes/cigpack_inteq (src) // 2 tc this shit heals
			new /obj/item/flashlight/emp(src) // 2 tc
			new /obj/item/chameleon(src) // 7 tc

		if("stealth") // 31 tc
			new /obj/item/gun/energy/kinetic_accelerator/crossbow(src)
			new /obj/item/pen/sleepy(src)
			new /obj/item/healthanalyzer/rad_laser(src)
			new /obj/item/chameleon(src)
			new /obj/item/soap/inteq(src)
			new /obj/item/clothing/glasses/thermal/syndi(src)

		if("bond") // 29 tc
			new /obj/item/gun/ballistic/automatic/pistol/APS(src)
			new	/obj/item/suppressor(src)
			new /obj/item/ammo_box/magazine/pistolm9mm(src)
			new /obj/item/ammo_box/magazine/pistolm9mm(src)
			new /obj/item/ammo_box/magazine/pistolm9mm(src)
			new /obj/item/clothing/under/chameleon(src)
			new /obj/item/encryptionkey/inteq(src)
			new	/obj/item/clothing/accessory/kevlar(src)
			new	/obj/item/clothing/accessory/kevlar(src)
			new	/obj/item/clothing/accessory/kevlar(src)
			new /obj/item/reagent_containers/syringe/stimulants(src)
			new /obj/item/clothing/neck/tie/red(src)

		if("screwed") // 29 tc
			new /obj/item/sbeacondrop/bomb(src)
			new /obj/item/sbeacondrop/bomb (src)
			new /obj/item/grenade/syndieminibomb(src)
			new /obj/item/sbeacondrop/powersink(src)
			new /obj/item/clothing/suit/space/syndicate/black/orange(src)
			new /obj/item/clothing/head/helmet/space/syndicate/orange(src)
			new /obj/item/encryptionkey/inteq(src)

		if("guns") // 30 tc now
			new /obj/item/gun/ballistic/revolver/inteq(src)
			new /obj/item/ammo_box/a357(src)
			new /obj/item/ammo_box/a357(src)
			new /obj/item/card/emag(src)
			new /obj/item/grenade/plastic/c4(src)
			new /obj/item/clothing/gloves/color/latex/nitrile(src)
			new /obj/item/clothing/mask/gas/clown_hat(src)
			new /obj/item/clothing/under/suit/black_really(src)
			new /obj/item/screwdriver/power/inteq(src) //2 tc item
			new /obj/item/pickaxe/drill/jackhammer/angle_grinder(src)

		if("murder") // 35 tc
			new /obj/item/inteq_sledgehammer(src)
			new /obj/item/compressionkit(src)
			new /obj/item/clothing/glasses/thermal/syndi(src)
			new /obj/item/card/emag(src)
			new /obj/item/clothing/shoes/chameleon/noslip(src)
			new /obj/item/encryptionkey/inteq(src)
			new /obj/item/grenade/syndieminibomb(src)
			new /obj/item/clothing/glasses/phantomthief/syndicate(src)
			new /obj/item/reagent_containers/syringe/stimulants(src)

		if("baseball") // 44~ tc
			new /obj/item/melee/baseball_bat/ablative/inteq(src) //Lets say 12 tc, lesser sleeping carp
			new /obj/item/clothing/glasses/sunglasses(src) //Lets say 2 tc
			new /obj/item/card/emag(src) //6 tc
			new /obj/item/clothing/shoes/sneakers/noslip(src) //2tc
			new /obj/item/encryptionkey/inteq(src) //1tc
			new /obj/item/autosurgeon/syndicate/anti_drop(src) //Lets just say 7~
			new /obj/item/clothing/under/inteq/baseball(src) //3tc
			new /obj/item/clothing/head/soft/inteq/baseball(src) //Lets say 4 tc
			new /obj/item/reagent_containers/hypospray/medipen/stimulants(src) //lets say 5tc


		if("implant") // 67+ tc holy shit what the fuck this is a lottery disguised as fun boxes isn't it?
			new /obj/item/implanter/freedom(src)
			new /obj/item/implanter/uplink/precharged(src)
			new /obj/item/implanter/emp(src)
			new /obj/item/implanter/adrenalin(src)
			new /obj/item/implanter/explosive(src)
			new /obj/item/implanter/storage(src)
			new /obj/item/implanter/radio/syndicate(src)
			new /obj/item/implanter/stealth(src)

		if("hacker") // 30 tc
			new /obj/item/ai_module/syndicate(src)
			new /obj/item/card/emag(src)
			new /obj/item/encryptionkey/binary(src)
			new /obj/item/ai_module/toyAI(src)
			new /obj/item/multitool/ai_detect(src)
			new /obj/item/flashlight/emp(src)
			new /obj/item/emagrecharge(src)
			new	/obj/item/implanter/hijack(src)
			new /obj/item/storage/toolbox/inteq/cooler(src)

		if("lordsingulo") // "36" tc aka 23 tc
			new /obj/item/sbeacondrop(src) // 14 kinda useless
			new /obj/item/clothing/suit/space/syndicate/black/orange(src)
			new /obj/item/clothing/head/helmet/space/syndicate/orange(src)
			new /obj/item/card/emag(src) //6
			new /obj/item/emagrecharge(src) //2
			new /obj/item/storage/toolbox/syndicate(src) //1
			new /obj/item/encryptionkey/inteq(src) //2
			new /obj/item/flashlight/emp(src) //2
			new /obj/item/jammer(src) //5

		if("sabotage") // ~28 tc now
			new /obj/item/grenade/plastic/c4 (src)
			new /obj/item/grenade/plastic/c4 (src)
			new /obj/item/grenade/plastic/x4 (src)
			new /obj/item/grenade/plastic/x4 (src)
			new /obj/item/storage/box/inteq_kit/doorgoboom(src)
			new /obj/item/suspiciousphone(src)
			new /obj/item/camera_bug(src)
			new /obj/item/sbeacondrop/powersink(src)
			new /obj/item/cartridge/virus/syndicate(src)
			new /obj/item/storage/toolbox/syndicate(src) //To actually get to those places
			new /obj/item/pizzabox/bomb

		if("darklord") //20 tc + tk + summon item close enough for now
			new /obj/item/dualsaber(src)
			new /obj/item/dnainjector/telemut/darkbundle(src)
			new /obj/item/clothing/suit/hooded/chaplain_hoodie(src)
			new /obj/item/encryptionkey/inteq(src)
			new /obj/item/clothing/shoes/chameleon/noslip(src) //because slipping while being a dark lord sucks
			new /obj/item/book/granter/spell/summonitem(src)

		if("sniper") //This shit is unique so can't really balance it around tc, also no silencer because getting killed without ANY indicator on what killed you sucks
			new /obj/item/gun/ballistic/automatic/sniper_rifle(src) // 12 tc
			new /obj/item/ammo_box/magazine/sniper_rounds/penetrator(src) // прицел сломан, колличество людей на станции увеличелось с пары десятков до  сотни. Пора поднимать боезапас
			new /obj/item/ammo_box/magazine/sniper_rounds/penetrator(src)
			new /obj/item/ammo_box/magazine/sniper_rounds/penetrator(src)
			new /obj/item/clothing/glasses/thermal/syndi(src)
			new /obj/item/clothing/gloves/color/latex/nitrile(src)
			new /obj/item/clothing/mask/gas/clown_hat(src)
			new /obj/item/clothing/under/suit/black_really(src)

		if("metaops") // 30 tc
			new /obj/item/clothing/suit/space/hardsuit/syndi/inteq(src) // 8 tc
			new /obj/item/gun/ballistic/automatic/shotgun/aa12(src) // 8 tc
			new /obj/item/implanter/explosive(src) // 2 tc
			new /obj/item/ammo_box/magazine/aa12/small(src) // 2 tc
			new /obj/item/ammo_box/magazine/aa12/small(src) // 2 tc
			new /obj/item/grenade/plastic/c4 (src) // 1 tc
			new /obj/item/grenade/plastic/c4 (src) // 1 tc
			new /obj/item/card/emag(src) // 6 tc

		if("ninja") // 40~ tc worth
			new /obj/item/katana(src) // Unique , basicly a better esword. 10 tc?
			new /obj/item/implanter/adrenalin(src) // 8 tc
			new /obj/item/throwing_star(src) // ~5 tc for all 6
			new /obj/item/throwing_star(src)
			new /obj/item/throwing_star(src)
			new /obj/item/implanter/emp(src)
			new /obj/item/grenade/smokebomb(src)
			new /obj/item/grenade/smokebomb(src)
			new /obj/item/storage/belt/chameleon(src) // Unique but worth at least 2 tc
			new /obj/item/encryptionkey/inteq(src) // 2 tc
			new /obj/item/chameleon(src) // 7 tc

		if("ancient") //A kit so old, it's probably older than you. //This bundle is filled with the entire unlink contents traitors had access to in 2006, from OpenSS13. Notably the esword was not a choice but existed in code.
			new /obj/item/storage/toolbox/emergency/old/ancientbundle(src) //Items fit neatly into a classic toolbox just to remind you what the theme is.

		if("death_quin") // 29 tc worth
			new /obj/item/storage/box/syndie_kit/chameleon(src) // 2
			new /obj/item/lipstick/black/death(src) // 12 tc
			new /obj/item/storage/box/syndie_kit/chemical (src) //  6
			new /obj/item/gun/syringe/syndicate(src) //  3
			new /obj/item/storage/fancy/cigarettes/derringer(src) //  6

		if("launchman") // 29 tc worth
			new /obj/item/storage/briefcase/launchpad(src) // 6
			new /obj/item/clothing/glasses/inteq_xray(src) // 8 tc
			new /obj/item/binoculars(src) //  1
			new /obj/item/gun/energy/laser/canceller(src) //  6
			new /obj/item/storage/box/holy_grenades(src) //  6
			new /obj/item/grenade/confetti(src)
			new /obj/item/grenade/confetti(src)
			new /obj/item/grenade/confetti(src)

		if("spacemarine")
			new /obj/item/autosurgeon/syndicate/inteq/astartes(src)
			new /obj/item/clothing/shoes/jackboots/powerbots(src)
			new /obj/item/clothing/mask/gas/sechailer/angrymarin(src)
			new /obj/item/clothing/suit/space/syndicate/darktemplar(src)
			new /obj/item/clothing/head/helmet/space/syndicate/darktemplar(src)
			new /obj/item/clothing/under/syndicate/combat(src)
			new /obj/item/clothing/gloves/tackler/combat/insulated(src)
			new	/obj/item/nullrod/claymore/chainsaw_sword/real(src)
