/* BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\clothesmate.dm'
/obj/machinery/vending/clothing/Initialize()
	var/list/extra_products = list(
		/obj/item/clothing/suit/assu_suit = 16,
		/obj/item/clothing/head/assu_helmet = 16,
		/obj/item/clothing/head/hoodcowl = 4,
		///obj/item/clothing/glasses/aviators = 10, удаляем защиту от флешек (опять)
		/obj/item/clothing/suit/toggle/rp_jacket = 3,
		/obj/item/clothing/suit/toggle/rp_jacket/orange = 3,
		/obj/item/clothing/suit/toggle/rp_jacket/purple = 3,
		/obj/item/clothing/suit/toggle/rp_jacket/red = 3,
		/obj/item/clothing/suit/toggle/rp_jacket/white = 3,
		/obj/item/clothing/suit/jacket/runner/engi = 3,
		/obj/item/clothing/suit/jacket/runner/syndicate = 3,
		/obj/item/clothing/suit/toggle/rp_jacket/white = 3,
		/obj/item/clothing/under/goner/fake/poly = 10,
		/obj/item/clothing/suit/goner/fake/poly = 10,
		/obj/item/clothing/head/helmet/goner/fake/poly = 10,
		/obj/item/clothing/under/raccveralls = 3,
		/obj/item/clothing/under/raccveralls/flush_shirt = 3,
		/obj/item/clothing/under/officesexy = 3,
		/obj/item/clothing/suit/toggle/tunnelfox = 3,
		/obj/item/clothing/under/performer = 2,
		/obj/item/clothing/under/bluedress = 3,
		/obj/item/clothing/accessory/shortcrop = 3,
		/obj/item/clothing/accessory/longcrop = 3,
		/obj/item/clothing/accessory/formalcrop = 3,
		/obj/item/clothing/under/misc/leia_outfit = 2,
		/obj/item/clothing/under/performer/polychromic = 2,
		/obj/item/clothing/under/suit/black_really_collared = 3,
		/obj/item/clothing/under/suit/black_really_collared/skirt = 3,
		/obj/item/clothing/under/suit/inferno = 3,
		/obj/item/clothing/under/suit/inferno/skirt = 3,
		/obj/item/clothing/under/suit/helltaker = 3,
		/obj/item/clothing/under/suit/helltaker/skirt = 3,
		/obj/item/clothing/suit/invisijacket = 3,
		/obj/item/clothing/head/invisihat = 3,
		/obj/item/clothing/under/pentatop = 3,
		/obj/item/clothing/under/misc/pentagram = 3,
		/obj/item/clothing/under/misc/revealingdress = 3,
		/obj/item/clothing/under/misc/vneck = 3,
		/obj/item/clothing/under/misc/tian_dress = 3,
		/obj/item/clothing/under/misc/wench = 3,
		/obj/item/clothing/under/misc/gothic = 3,
		/obj/item/clothing/under/misc/rippedpunk = 3,
		/obj/item/clothing/under/misc/corsetdress = 3,
		/obj/item/clothing/under/misc/sheer = 3,
		/obj/item/clothing/under/misc/asym = 3,
		/obj/item/clothing/under/misc/swoop = 3,
		/obj/item/clothing/under/misc/miniskirt_sheer = 3,
		/obj/item/clothing/under/misc/miniskirt = 3,
		/obj/item/clothing/wrists/armwarmer = 3,
		/obj/item/clothing/wrists/armwarmer/long = 3,
		/obj/item/clothing/wrists/armwarmer_striped = 3,
		/obj/item/clothing/wrists/armwarmer_striped/long = 3,
		/obj/item/clothing/under/pants/yoga = 3,
		/obj/item/clothing/under/blutigen_undergarment = 3,
		/obj/item/clothing/glasses/contact = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_heart = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_sheer = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_mini = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_sheer_mini = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_vag_sheer = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_vag_mini = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_vag = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_anal = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_vag_x = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_vag_bandaid = 3,
		/obj/item/clothing/underwear/briefs/panties/maebari/maebari_anal_bandaid = 3,
		/obj/item/clothing/accessory/pride/other = 30
	)
	var/list/extra_contraband = list(
		/obj/item/clothing/under/rank/civilian/lawyer/galaxy_red = 3,
		/obj/item/clothing/mask/gas/goner/basic = 10
	)
	var/list/extra_premium = list(
		/obj/item/clothing/under/rank/civilian/lawyer/galaxy_blue = 3,
		/obj/item/clothing/head/helmet/goner/officer/fake/poly = 10
	)

	// if(SSholidays.holidays && SSholidays.holidays[CHRISTMAS])
	// 	extra_products += list(
	// 		/obj/item/clothing/accessory/sweater/uglyxmas = 3,
	// 		/obj/item/clothing/head/beanie/christmas = 3,
	// 		/obj/item/clothing/neck/scarf/christmas = 3,
	// 		/obj/item/clothing/under/costume/christmas = 3,
	// 		/obj/item/clothing/under/costume/christmas/green = 3,
	// 		/obj/item/clothing/under/costume/christmas/croptop = 3,
	// 		/obj/item/clothing/under/costume/christmas/croptop/green = 3,
	// 		/obj/item/clothing/suit/hooded/wintercoat/christmascoatr = 3,
	// 		/obj/item/clothing/suit/hooded/wintercoat/christmascoatg = 3,
	// 		/obj/item/clothing/suit/hooded/wintercoat/christmascoatrg = 3,
	// 		/obj/item/clothing/head/christmashat = 3,
	// 		/obj/item/clothing/head/christmashatg = 3,
	// 		/obj/item/clothing/shoes/winterboots/christmasbootsr = 3,
	// 		/obj/item/clothing/shoes/winterboots/christmasbootsg = 3,
	// 		/obj/item/clothing/shoes/winterboots/santaboots = 3,
	// 		/obj/item/clothing/underwear/socks/thigh/christmas = 3,
	// 		/obj/item/clothing/underwear/socks/christmas = 3,
	// 		/obj/item/clothing/underwear/socks/knee/christmas = 3,
	// 	)

	LAZYADD(products, extra_products)
	LAZYADD(contraband, extra_contraband)
	LAZYADD(premium, extra_premium)
	. = ..()
*/
