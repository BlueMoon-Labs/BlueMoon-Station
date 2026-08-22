/obj/machinery/vending/liberationstation
	name = "\improper Liberation Station"
	desc = "An overwhelming amount of <b>ancient patriotism</b> washes over you just by looking at the machine."
	icon_state = "liberationstation"
	product_slogans = "Станция Освобождения: Ваш универсальный магазин для всех вещей, связанных со второй поправкой!;Будь патриотом сегодня, возьми оружие!;Качественное оружие по низким ценам!;Лучше мертвый, чем красный!;Плавать как космонавт, жалить как пуля!;Вырази свою вторую поправку сегодня!;Оружие не убивает людей, но ты можешь!;Кому нужна ответственность, когда у тебя есть оружие?"
	vend_reply = "Remember the name: Liberation Station!"
	//panel_type = "panel17"
	products = list(
		/obj/item/reagent_containers/food/snacks/burger/plain = 5, //O say can you see, by the dawn's early light
		/obj/item/reagent_containers/food/snacks/burger/baseball = 3, //What so proudly we hailed at the twilight's last gleaming
		/obj/item/reagent_containers/food/snacks/fries = 5, //Whose broad stripes and bright stars through the perilous fight
		/obj/item/reagent_containers/food/drinks/beer/light = 10, //O'er the ramparts we watched, were so gallantly streaming?
		/obj/item/gun/ballistic/automatic/pistol/deagle/gold = 2,
		/obj/item/gun/ballistic/automatic/pistol/deagle/camo = 2,
		/obj/item/gun/ballistic/automatic/pistol/m1911 = 2,
		/obj/item/gun/ballistic/automatic/proto = 2,
		/obj/item/gun/ballistic/shotgun/automatic/combat = 2,
		/obj/item/gun/ballistic/automatic/gyropistol = 1,
		/obj/item/gun/ballistic/shotgun = 2,
		/obj/item/gun/ballistic/automatic/ar = 2,
		// Mesa guns
		/obj/item/gun/ballistic/automatic/pistol/hl9mm = 3,
		/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1 = 2,
		/obj/item/gun/ballistic/automatic/mp5 = 3,
		/obj/item/gun/ballistic/automatic/mp5/underbarrel = 2,
		/obj/item/gun/ballistic/shotgun/m870 = 3,
		/obj/item/gun/ballistic/shotgun/spas = 2,
		/obj/item/gun/ballistic/automatic/m16a4/mesa = 3,
		/obj/item/gun/ballistic/automatic/mp7 = 3,
		/obj/item/gun/ballistic/automatic/scar = 2,
		/obj/item/gun/ballistic/automatic/p90 = 2,
	)
	premium = list(
		/obj/item/ammo_box/magazine/smgm9mm = 2,
		/obj/item/ammo_box/magazine/m50 = 4,
		/obj/item/ammo_box/magazine/m45 = 2,
		/obj/item/ammo_box/magazine/m75 = 2,
		/obj/item/reagent_containers/food/snacks/cheesyfries = 5,
		/obj/item/reagent_containers/food/snacks/burger/baconburger = 5,//Premium burgers for the premium section
		// Mesa gun ammo
		/obj/item/ammo_box/magazine/pistolm9mm = 5,
		/obj/item/ammo_box/magazine/sniper_rounds/m4oa1 = 4,
		/obj/item/ammo_box/magazine/mp5 = 5,
		/obj/item/ammo_box/shotgun/loaded/buckshot = 6,
		/obj/item/ammo_box/magazine/m16 = 5,
		/obj/item/ammo_box/magazine/mp7 = 5,
		/obj/item/ammo_box/magazine/scar = 4,
		/obj/item/ammo_box/magazine/p90 = 4,
	)
	contraband = list(
		/obj/item/clothing/under/misc/patriotsuit = 3,
		/obj/item/bedsheet/patriot = 5,
		/obj/item/reagent_containers/food/snacks/burger/superbite = 3,
	) //U S A
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50)

	resistance_flags = FIRE_PROOF
	default_price = PRICE_ABOVE_NORMAL
	extra_price = PRICE_ABOVE_EXPENSIVE
	payment_department = ACCOUNT_SEC
	light_mask = "liberation-light-mask"

/obj/machinery/vending/security/syndicate
	name = "\improper Syndicate Station"
	desc = "Специальный терминал для выдачи вооружения. Вставьте свою Карточку на Вооружение в приёмник и выбирайте свою пушку!"
	product_slogans = "Станция Синдиката: Ваш универсальный магазин для всех вещей, связанных со второй поправкой!;Будь Оперативником сегодня, возьми оружие!;Качественное оружие по низким ценам!;Лучше мертвый, чем жёлтый!;Плавать как космонавт, жалить как пуля!;Вырази свою вторую поправку сегодня!;Оружие не убивает людей, но ты можешь!;Кому нужна ответственность, когда у тебя есть оружие?"
	icon_state = "syndicate-marine"
	icon_deny = "syndicate-marine-deny"
	light_mask = "syndicate-marine-mask"
	icon_vend = "syndicate-marine-vend"
	req_access = list(ACCESS_SYNDICATE)
	products = list(
		/obj/item/restraints/handcuffs = 9,
		/obj/item/assembly/flash/handheld = 6,
		/obj/item/flashlight/seclite = 6,
		/obj/item/ammo_box/magazine/m10mm = 9,
		/obj/item/ammo_box/magazine/smgm45 = 9,
		// /obj/item/ammo_box/magazine/sniper_rounds = 9,
		/obj/item/ammo_box/magazine/m556 = 6,
		/obj/item/ammo_casing/a40mm = 6,
		/obj/item/ammo_box/magazine/m12g = 9,
		/obj/item/grenade/plastic/c4 = 4,
		/obj/item/grenade/frag = 4,
		/obj/item/melee/transforming/energy/sword/saber/red = 6,
	)
	var/voucher_items = list(
		"M-90gl Carbine" = /obj/item/gun/ballistic/automatic/m90/unrestricted,
		// "Sniper Rifle" = /obj/item/gun/ballistic/automatic/sniper_rifle/unrestricted,
		"C-20r SMG" = /obj/item/gun/ballistic/automatic/c20r/unrestricted,
		"Bulldog Shotgun" = /obj/item/gun/ballistic/automatic/shotgun/bulldog/unrestricted
	)

/obj/machinery/vending/security/syndicate/attackby(obj/item/I, mob/user, params) //WS edit: THERE IS NO GOD. THERE IS ONLY GUNS. REPENT. //shiptest: i should remove this comment, but its funny
	if(istype(I, /obj/item/gun_voucher))
		RedeemVoucher(I, user)
		return
	return..()

/obj/machinery/vending/security/syndicate/proc/RedeemVoucher(obj/item/gun_voucher/voucher, mob/redeemer)
	var/selection = show_radial_menu(redeemer, src, voucher_items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	if(voucher_items[selection])
		var/drop_location = drop_location()
		var/obj/selected_item = voucher_items[selection]
		new selected_item(drop_location)

	SSblackbox.record_feedback("tally", "gun_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/item/gun_voucher
	name = "Security Weapon Voucher"
	desc = "A token used to redeem guns from the SecTech vendor."
	icon = 'icons/obj/vending.dmi'
	icon_state = "sec-voucher"
	w_class = WEIGHT_CLASS_TINY //WS end

/obj/item/gun_voucher/syndicate
	name = "Syndicate Weapon Voucher"
	desc = "A token used to redeem equipment from your nearest marine vendor."
	icon_state = "syndie-voucher"

/obj/item/gun_voucher/nanotrasen
	name = "Nanotrasen Weapon Voucher"
	desc = "A token used to redeem equipment from your nearest marine vendor."
	icon_state = "nanotrasen-voucher"

/obj/machinery/vending/ultimateliberation
	name = "\improper ULTIMATE LIBERATION STATION"
	desc = "Таинственный автомат для продажи оборудования ядерных оперативников. Здесь можно найти всё, что нужно для диверсий и боя."
	icon_state = "liberationstation"
	product_slogans = "Ghost Cafe: Оружие для настоящих призраков!;Будь невидимым, будь смертоносным!;Качественное снаряжение для самых тёмных дел!;Лучше быть мёртвым, чем красным!;Плавать как призрак, жалить как пуля!;Вырази свою тёмную сторону сегодня!;Оружие не убивает людей, но ты можешь!;Кому нужна мораль, когда у тебя есть оружие?"
	vend_reply = "Welcome to the Ghost Cafe!"
	product_categories = list(
		list(
			"name" = "Дробовики",
			"icon" = "crosshairs",
			"products" = list(
				/obj/item/gun/ballistic/automatic/shotgun/bulldog/unrestricted = 3,
				/obj/item/gun/ballistic/shotgun/automatic/combat = 2,
				/obj/item/gun/ballistic/shotgun/m870 = 2,
				/obj/item/gun/ballistic/shotgun/spas = 2,
				/obj/item/gun/ballistic/shotgun/riot = 2,
				/obj/item/gun/ballistic/shotgun/riot/syndicate = 2,
				/obj/item/gun/ballistic/shotgun/shorty = 3,
				/obj/item/gun/ballistic/shotgun/hunting = 2,
				/obj/item/gun/ballistic/shotgun/leveraction = 2,
				/obj/item/gun/ballistic/shotgun/brush2 = 2,
				/obj/item/ammo_box/magazine/m12g = 5,
				/obj/item/ammo_box/shotgun/loaded/buckshot = 6,
			)
		),
		list(
			"name" = "SMG",
			"icon" = "gun",
			"products" = list(
				/obj/item/gun/ballistic/automatic/c20r/unrestricted = 3,
				/obj/item/gun/ballistic/automatic/mp5 = 2,
				/obj/item/gun/ballistic/automatic/mp5/underbarrel = 2,
				/obj/item/gun/ballistic/automatic/mp7 = 2,
				/obj/item/gun/ballistic/automatic/p90 = 2,
				/obj/item/ammo_box/magazine/smgm45 = 5,
				/obj/item/ammo_box/magazine/mp5 = 5,
				/obj/item/ammo_box/magazine/mp7 = 5,
				/obj/item/ammo_box/magazine/p90 = 5,
			)
		),
		list(
			"name" = "Тяжёлое оружие",
			"icon" = "explosion",
			"products" = list(
				/obj/item/gun/ballistic/automatic/l6_saw/unrestricted = 2,
				/obj/item/gun/ballistic/automatic/m90/unrestricted = 2,
				/obj/item/gun/ballistic/automatic/scar = 2,
				/obj/item/gun/ballistic/automatic/sniper_rifle = 2,
				/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1 = 2,
				/obj/item/gun/ballistic/rocketlauncher/unrestricted = 1,
				/obj/item/gun/ballistic/automatic/ak12 = 3,
				/obj/item/gun/ballistic/automatic/ak12/r = 2,
				/obj/item/gun/ballistic/automatic/ak47 = 3,
				/obj/item/gun/ballistic/automatic/ak47/akm = 2,
				/obj/item/gun/ballistic/automatic/ak47/homemade = 2,
				/obj/item/gun/ballistic/automatic/m16a4 = 3,
				/obj/item/gun/ballistic/automatic/m16a4/tactical = 2,
				/obj/item/gun/ballistic/automatic/m16a4/stock = 2,
				/obj/item/gun/ballistic/automatic/m16a4/mesa = 2,
				/obj/item/ammo_box/magazine/m556 = 4,
				/obj/item/ammo_box/magazine/sniper_rounds = 4,
				/obj/item/ammo_box/magazine/sniper_rounds/m4oa1 = 4,
				/obj/item/ammo_box/magazine/scar = 4,
				/obj/item/ammo_box/magazine/mm712x82 = 3,
				/obj/item/ammo_casing/caseless/rocket = 3,
				/obj/item/ammo_box/magazine/ak12 = 5,
				/obj/item/ammo_box/magazine/ak12/r = 3,
				/obj/item/ammo_box/magazine/ak47 = 5,
				/obj/item/ammo_box/magazine/m16 = 5,
			)
		),
		list(
			"name" = "Пистолеты",
			"icon" = "dot-circle",
			"products" = list(
				/obj/item/storage/box/syndie_kit/pistol = 3,
				/obj/item/storage/box/syndie_kit/aps_pistol = 3,
				/obj/item/storage/box/syndie_kit/revolver = 2,
				/obj/item/storage/box/inteq_kit/revolver = 2,
				/obj/item/gun/ballistic/automatic/pistol/hl9mm = 3,
				/obj/item/gun/ballistic/automatic/pistol/deagle/gold = 2,
				/obj/item/gun/ballistic/automatic/pistol/deagle/camo = 2,
				/obj/item/ammo_box/magazine/m10mm = 5,
				/obj/item/ammo_box/magazine/pistolm9mm = 5,
			)
		),
		list(
			"name" = "Ближнее оружие",
			"icon" = "knife",
			"products" = list(
				/obj/item/melee/transforming/energy/sword/saber = 3,
				/obj/item/melee/transforming/plasmasword = 2,
				/obj/item/shield/energy = 2,
				/obj/item/shield/inteq_energy = 2,
				/obj/item/storage/belt/sabre/rapier = 2,
				/obj/item/storage/belt/sabre/karakurt = 2,
				/obj/item/melee/powerfist = 2,
				/obj/item/clothing/gloves/fingerless/pugilist/mauler = 2,
			)
		),
		list(
			"name" = "Боевые искусства",
			"icon" = "fist",
			"products" = list(
				/obj/item/book/granter/martial/cqc = 2,
				/obj/item/book/granter/martial/carp = 2,
				/obj/item/book/granter/martial/krav_maga = 2,
			)
		),
		list(
			"name" = "Медикаменты",
			"icon" = "plus",
			"products" = list(
				/obj/item/storage/firstaid/tactical/nukeop = 5,
				/obj/item/storage/firstaid/regular = 5,
				/obj/item/storage/firstaid/brute = 5,
				/obj/item/storage/firstaid/fire = 5,
				/obj/item/storage/firstaid/toxin = 5,
				/obj/item/storage/firstaid/o2 = 5,
				/obj/item/gun/magic/wand/resurrection/debug/ghostcafe = 1,
			)
		),
	)
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50)
	resistance_flags = 115 // INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | LAVA_PROOF
	default_price = PRICE_ABOVE_NORMAL
	extra_price = PRICE_ABOVE_EXPENSIVE
	payment_department = ACCOUNT_SEC
	light_mask = "liberation-light-mask"
	refill_canister = /obj/item/vending_refill/ultimateliberation

/obj/item/vending_refill/ultimateliberation
	machine_name = "ULTIMATE LIBERATION STATION"
	icon_state = "refill_custom"
