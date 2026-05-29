/* BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\liberation.dm'
/obj/machinery/vending/liberationstation
	name = "\improper Liberation Station"
	desc = "An overwhelming amount of <b>ancient patriotism</b> washes over you just by looking at the machine."
	icon_state = "liberationstation"
	product_slogans = "Станция Освобождения: Ваш универсальный магазин для всех вещей, связанных со второй поправкой!;Будь патриотом сегодня, возьми оружие!;Качественное оружие по низким ценам!;Лучше мертвый, чем красный!;Плавать как космонавт, жалить как пуля!;Вырази свою вторую поправку сегодня!;Оружие не убивает людей, но ты можешь!;Кому нужна ответственность, когда у тебя есть оружие?"
	vend_reply = "Remember the name: Liberation Station!"
	products = list(/obj/item/reagent_containers/food/snacks/burger/plain = 5, //O say can you see, by the dawn's early light
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
					/obj/item/gun/ballistic/automatic/ar = 2)
	premium = list(/obj/item/ammo_box/magazine/smgm9mm = 2,
					/obj/item/ammo_box/magazine/m50 = 4,
					/obj/item/ammo_box/magazine/m45 = 2,
					/obj/item/ammo_box/magazine/m75 = 2,
					/obj/item/reagent_containers/food/snacks/cheesyfries = 5,
					/obj/item/reagent_containers/food/snacks/burger/baconburger = 5) //Premium burgers for the premium section
	contraband = list(/obj/item/clothing/under/misc/patriotsuit = 3,
					/obj/item/bedsheet/patriot = 5,
					/obj/item/reagent_containers/food/snacks/burger/superbite = 3) //U S A
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
		/obj/item/restraints/handcuffs = 3,
		/obj/item/assembly/flash/handheld = 2,
		/obj/item/flashlight/seclite = 2,
		/obj/item/ammo_box/magazine/m10mm = 3,
		/obj/item/ammo_box/magazine/smgm45 = 3,
		/obj/item/ammo_box/magazine/sniper_rounds = 3,
		/obj/item/ammo_box/magazine/m556 = 2,
		/obj/item/ammo_box/magazine/m12g = 3,
		/obj/item/grenade/plastic/c4 = 2,
		/obj/item/grenade/frag = 4,
		/obj/item/melee/transforming/energy/sword/saber/red = 2,
		)
	var/voucher_items = list(
		"M-90gl Carbine" = /obj/item/gun/ballistic/automatic/m90,
		"Sniper Rifle" = /obj/item/gun/ballistic/automatic/sniper_rifle,
		"C-20r SMG" = /obj/item/gun/ballistic/automatic/c20r,
		"Bulldog Shotgun" = /obj/item/gun/ballistic/automatic/shotgun/bulldog)

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
*/
