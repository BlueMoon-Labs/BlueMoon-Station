
// Dangerous Items

/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

/datum/uplink_item/dangerous/pistol
	name = "Makarov Pistol"
	desc = "Элегантная коробка с маленьким, легко скрываемым пистолетом на патронах 10мм авто в магазинах на 8 патронов. Совместим с глушителями."
	item = /obj/item/storage/box/syndie_kit/pistol
	cost = 3
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/aps_pistol
	name = "Stechkin Pistol"
	desc = "Оригинальная русская версия широко распространённого пистолета Syndicate. Калибр 9мм. Нарезной ствол под глушитель."
	item = /obj/item/storage/box/syndie_kit/aps_pistol
	cost = 5
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/revolver
	name = "Revolver Kit"
	desc = "Элегантная коробка с брутально простым револьвером Syndicate под .357 Magnum, 7 камор и скорозарядник в комплекте."
	item = /obj/item/storage/box/syndie_kit/revolver
	cost = 10
	player_minimum = 15
	surplus = 50
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/revolver_inteq
	name = "InteQ Revolver Kit"
	desc = "Простой и брутальный револьвер под патрон .357 Magnum. 7 выстрелов для 7 трупов, скорозарядник с дополнительным боезопасом в комплекте."
	item = /obj/item/storage/box/inteq_kit/revolver
	cost = 10
	player_minimum = 15
	surplus = 50
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/dangerous/rawketlawnchair
	name = "84mm Rocket Propelled Grenade Launcher"
	desc = "Многоразовый гранатомёт, заряженный 84мм фугасной ракетой малой мощности. \
		Гарантируем, что ваша цель уйдёт с грохотом, или вернём деньги!"
	item = /obj/item/gun/ballistic/rocketlauncher
	cost = 8
	surplus = 30
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/antitank
	name = "Anti Tank Pistol"
	desc = "По сути снайперская винтовка без приклада и ствола (и нарезки, если на то пошло). \
			Этот крайне сомнительный пистолет гарантированно вывихнет вам запястья и попадёт в стену амбара! \
	 		Использует снайперные боеприпасы. \
	 		Пули имеют тенденцию лететь мимо. Мы не несём ответственности за непреднамеренный ущерб из-за неточности."
	item = /obj/item/gun/ballistic/automatic/pistol/antitank/syndicate
	cost = 14
	surplus = 25
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/pie_cannon
	name = "Banana Cream Pie Cannon"
	desc = "A special pie cannon for a special clown, this gadget can hold up to 20 pies and automatically fabricates one every two seconds!"
	cost = 10
	item = /obj/item/pneumatic_cannon/pie/selfcharge
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/bananashield
	name = "Bananium Energy Shield"
	desc = "A clown's most powerful defensive weapon, this personal shield provides near immunity to ranged energy attacks \
		by bouncing them back at the ones who fired them. It can also be thrown to bounce off of people, slipping them, \
		and returning to you even if you miss. WARNING: DO NOT ATTEMPT TO STAND ON SHIELD WHILE DEPLOYED, EVEN IF WEARING ANTI-SLIP SHOES."
	item = /obj/item/shield/energy/bananium
	cost = 16
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/clownsword
	name = "Bananium Energy Sword"
	desc = "An energy sword that deals no damage, but will slip anyone it contacts, be it by melee attack, thrown \
	impact, or just stepping on it. Beware friendly fire, as even anti-slip shoes will not protect against it."
	item = /obj/item/melee/transforming/energy/sword/bananium
	cost = 3
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/dangerous/bioterror
	name = "Biohazardous Chemical Sprayer"
	desc = "Ручной химический распылитель широкого спектра действия. Смесь от Tiger Cooperative \
			дезориентирует, калечит и обездвиживает врагов... \
			Используйте с крайней осторожностью, чтобы не отравить себя и своих оперативников."
	item = /obj/item/reagent_containers/spray/chemsprayer/bioterror
	cost = 20
	surplus = 0
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE | UPLINK_CLOWN_OPS)

/datum/uplink_item/dangerous/throwingweapons
	name = "Box of Throwing Weapons"
	desc = "Коробка сюрикенов и усиленных бола из древних земных боевых искусств. Крайне эффективное \
			 метательное оружие. Бола сбивают цель с ног, а сюрикены застревают в конечностях."
	item = /obj/item/storage/box/syndie_kit/throwing_weapons
	cost = 3

/datum/uplink_item/dangerous/shotgun
	name = "Bulldog Shotgun"
	desc = "Полностью заряженный полуавтоматический дробовик с барабанным магазином. Совместим со всеми снарядами 12-го калибра. \
			Конструирован для ближнего боя."
	item = /obj/item/gun/ballistic/automatic/shotgun/bulldog
	cost = 8
	surplus = 40
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/smg
	name = "C-20r Submachine Gun"
	desc = "Полностью заряженный пистолет-пулемёт булл-пап от Scarborough Arms. C-20r стреляет патронами .45 \
			из магазина на 24 патрона и совместим с глушителями."
	item = /obj/item/gun/ballistic/automatic/c20r
	cost = 10
	surplus = 40
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/doublesword
	name = "Double-Bladed Energy Sword"
	desc = "Двухлезвийный энергетический меч наносит чуть больше урона, чем обычный, и отражает все \
			энергетические снаряды, но требует двух рук."
	item = /obj/item/dualsaber
	player_minimum = 25
	cost = 16
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/doublesword/get_discount()
	return pick(4;0.8,2;0.65,1;0.5)

/datum/uplink_item/dangerous/plasmascythe
	name = "Plasma axe"	 // Прошло голосование за смену спрайта с аниме косы на топор
	desc = "Надеюсь, ты достаточно ловкий, что бы не перерезать себя пополам. Огромное лезвие этого топора, при должном мастерстве, позволит сжигать что угодно на своём пути, даже пули."
	item = /obj/item/plasmascythe
	player_minimum = 25
	cost = 16
	purchasable_from = ~(UPLINK_SYNDICATE | UPLINK_CLOWN_OPS)

/datum/uplink_item/dangerous/plasmascythe/get_discount()
	return pick(4;0.8,2;0.65,1;0.4)

/datum/uplink_item/dangerous/hyperblade
	name = "Hypereutactic Blade"
	desc = "Результат слияния двух мечей Зуб Дракона — не хотели бы вы увидеть это несущимся на вас! \
			Требует двух рук и замедляет вас. Можно перекрасить!"
	item = /obj/item/dualsaber/hypereutactic
	player_minimum = 25
	cost = 16
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/hyperblade/get_discount()
	return pick(4;0.8,2;0.65,1;0.5)

/datum/uplink_item/dangerous/sword
	name = "Energy Sword"
	desc = "Энергетический меч с лезвием из чистой энергии. В выключенном состоянии достаточно мал, чтобы \
			спрятать в карман. Активация издаёт громкий, узнаваемый звук."
	item = /obj/item/melee/transforming/energy/sword/saber
	cost = 8
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/sword ///Bluemoon add
	name = "Plasma Sword"
	desc = "Смертоностное оружие как для врага, так и для владельца. Лезвие из раскалённой плазмы с лёгкостью\
			прорезает броню и плоть, а достаточно ловкие оперативники могут сжечь им пулю на лету."
	item = /obj/item/melee/transforming/plasmasword
	cost = 8
	purchasable_from = ~(UPLINK_SYNDICATE | UPLINK_CLOWN_OPS)

/datum/uplink_item/dangerous/shield
	name = "Energy Shield"
	desc = "Невероятно полезный персональный щитовой проектор, способный отражать энергетические снаряды и защищать \
			от прочих атак. В связке с энергетическим мечом — убойная комбинация."
	item = /obj/item/shield/energy
	cost = 16
	surplus = 20
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/shield
	name = "Energy Shield"
	desc = "Устаревшая на несколько поколений модель энергетического щита; компенсируется своей надёжностью и универсальностью. \
	Использует механические ограничители силового поля и эргономика немного страдает, но всё ещё является желанным элементом экипировки. \
	В сочетании с плазменным мечом - убийственная комбинация."
	item = /obj/item/shield/inteq_energy
	cost = 16
	surplus = 20
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/dangerous/rapier
	name = "Rapier"
	desc = "Элегантная пластитаниумовая рапира с алмазным наконечником, покрытая специальным усыпляющим ядом. \
			Поставляется с ножнами, пробивает почти любую защиту. \
			Однако размер лезвия и приметные ножны явно намекают на недобрые намерения."
	item = /obj/item/storage/belt/sabre/rapier
	cost = 8
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/dangerous/karakurt //bluemoon add
	name = "Karakurt"
	desc = "Некогда элегантная рапира из пластитаниума. После даработки воронёное лезвие было пропитано сильнейшим нейротоксином, парализующим дыхательную и нервную систему, \
			а в ножнах встроено хранилище яда, не дающее лезвию высохнуть. Если цель не умрёт от потери крови, то неожиданно забудет как дышать, разве не идеальное оружие для дуэли?"
	item = /obj/item/storage/belt/sabre/karakurt
	cost = 8
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/dangerous/flamethrower
	name = "Flamethrower"
	desc = "Огнемёт, заправленный высокогорючими биотоксинами, крадеными со станций Nanotrasen. \
			Поджарьте мерзавцев в их же жадности. Используйте осторожно."
	item = /obj/item/flamethrower/full/tank
	cost = 4
	surplus = 40
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/flechettegun
	name = "Flechette Launcher"
	desc = "Компактный булл-пап, стреляющий микро-флешеттами. \
			По одной они слабы, но в количестве — смертельны. \
			Заряжен бронебойными флешеттами, пробивающими большинство видов брони."
	item = /obj/item/gun/ballistic/automatic/flechette
	cost = 12
	surplus = 30
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/rapid
	name = "Bands of the North Star"
	desc = "Эти наручи позволяют бить очень быстро со смертоносностью легендарного мастера боевых искусств. \
			Не улучшают скорость атаки оружием и кулаки халка, но в рукопашной вам не будет равных. \
			Совместимы со всеми боевыми искусствами, но носитель не сможет пользоваться огнестрельным, и наручи не снимаются."
	item = /obj/item/clothing/gloves/fingerless/pugilist/rapid
	cost = 30
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/guardian
	name = "Holoparasites"
	desc = "Способны на почти волшебные трюки через голограммы и наномашины, но требуют органического \
			носителя как базу и источник энергии. Бывают разных типов и делят урон с хозяином."
	item = /obj/item/storage/box/syndie_kit/guardian
	cost = 12
	limited_stock = 1 // you can only have one holopara apparently?
	refundable = TRUE
	cant_discount = TRUE
	surplus = 0
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	player_minimum = 25
	restricted = TRUE
	refund_path = /obj/item/guardiancreator/tech/choose/traitor

/datum/uplink_item/dangerous/nukieguardian // just like the normal holoparasites but without the support or deffensive stands because nukies shouldnt turtle
	name = "Holoparasites"
	desc = "Способны на почти волшебные трюки через голограммы и наномашины, но требуют органического \
			носителя как базу и источник энергии. Бывают разных типов и делят урон с хозяином."
	item = /obj/item/storage/box/syndie_kit/nukieguardian
	cost = 8
	refundable = TRUE
	surplus = 50
	refund_path = /obj/item/guardiancreator/tech/choose/nukie
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/machinegun
	name = "L6 Squad Automatic Weapon"
	desc = "Полностью заряженный ленточный пулемёт от Aussec Armoury. \
			Этот смертоносный агрегат оснащён магазином на 50 патронов разрушительного калибра 7.12x82мм."
	item = /obj/item/gun/ballistic/automatic/l6_saw
	cost = 18
	surplus = 0
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/carbine
	name = "M-90gl Carbine"
	desc = "Полностью заряженный карабин с режимом очереди по 3 выстрела, калибр 5.56мм, магазин на 30 патронов \
			с переключаемым подствольным гранатомётом 40мм."
	item = /obj/item/gun/ballistic/automatic/m90
	cost = 18
	surplus = 50
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/maulergauntlets
	name = "Mauler Gauntlets"
	desc = "Высокотехнологичные пластитаниумовые перчатки с нелегальными нанитными инъекторами, \
	дающие шестикратную силу среднего человека. Вы бьёте сильнее, наносите больше травм кулаками \
	и можете вбивать людей в столы с нечеловеческой силой. \
	К сожалению, из-за размера перчаток вы не сможете пользоваться огнестрельным оружием."
	item = /obj/item/clothing/gloves/fingerless/pugilist/mauler
	cost = 8

/datum/uplink_item/dangerous/powerfist
	name = "Power Fist"
	desc = "Металлическая перчатка со встроенным поршневым молотом на газовом приводе. \
		При ударе поршень выдвигается для контакта — мало не покажется. \
		Гаечным ключом можно регулировать расход газа для дополнительного урона и отбрасывания целей. \
		Отвёрткой можно извлечь присоединённый баллон."
	item = /obj/item/melee/powerfist
	cost = 5

/datum/uplink_item/dangerous/death_lipstick
	name = "Kiss of Death"
	desc = "Невероятно ядовитый тюбик помады, сделанный из яда ужасной Жёлтой Пятнистой Космической Ящерицы — смертельно и стильно. Постарайтесь не размазать!"
	item = /obj/item/lipstick/black/death
	cost = 12

/datum/uplink_item/dangerous/sniper
	name = "Sniper Rifle"
	desc = "Дальнобойная ярость в стиле Syndicate. Гарантированный шок и трепет, или вернём TC!"
	item = /obj/item/gun/ballistic/automatic/sniper_rifle/syndicate
	cost = 16
	surplus = 25
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/bolt_action
	name = "Surplus Rifle"
	desc = "Ужасно устаревшая винтовка с продольно-скользящим затвором. Нужно быть в отчаянии, чтобы взяться за это."
	item = /obj/item/gun/ballistic/shotgun/boltaction
	cost = 2
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/dangerous/foamsmg
	name = "Toy Submachine Gun"
	desc = "Полностью заряженный пистолет-пулемёт Donksoft типа буллпап. Стреляет дротиками подавления, магазин на 20 патронов."
	item = /obj/item/gun/ballistic/automatic/c20r/toy
	cost = 5
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS| UPLINK_SYNDICATE

/datum/uplink_item/dangerous/foammachinegun
	name = "Toy Machine Gun"
	desc = "Полностью заряженный ленточный пулемёт Donksoft. Имеет огромный магазин на 50 разрушительных \
			дротиков подавления — одной очередью можно ненадолго вырубить кого угодно."
	item = /obj/item/gun/ballistic/automatic/l6_saw/toy
	cost = 10
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/dangerous/foampistol
	name = "Toy Pistol with Riot Darts"
	desc = "Невинно выглядящий игрушечный пистолет для поролоновых дротиков. Заряжен дротиками подавления, \
			эффективными для обездвиживания цели."
	item = /obj/item/gun/ballistic/automatic/toy/pistol/riot
	cost = 3
	surplus = 10

/datum/uplink_item/dangerous/motivation
	name = "Motivation"
	desc = "Древний клинок, говорят, связанный с глубочайшими демонами Лаваленда. \
			Позволяет рубить на расстоянии!"
	item = /obj/item/gun/magic/staff/motivation
	cost = 10
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/dangerous/kudzu_seeds
	name = "Pack of Kudzu Seeds"
	desc = "Семена сорняка, который растёт с невероятной скоростью."
	item = /obj/item/seeds/kudzu
	cost = 4
	surplus = 10
