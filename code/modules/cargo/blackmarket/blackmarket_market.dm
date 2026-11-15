/datum/blackmarket_market
	var/name = "huh?" // Name for the market.

	var/list/shipping // Available shipping methods and prices, just leave the shipping method out that you don't want to have.

	// Automatic vars, do not touch these.
	var/list/available_items = list() // Items available from this market, populated by SSblackmarket on initialization.
	var/list/categories	= list() // Item categories available from this market, only items which are in these categories can be gotten from this market.

/datum/blackmarket_market/proc/add_item(datum/blackmarket_item/item) // Adds item to the available items and add it's category if it is not in categories yet.
	if(!prob(initial(item.availability_prob)))
		return FALSE
	if(ispath(item))
		item = new item()
	if(!(item.category in categories))
		categories += item.category
		available_items[item.category] = list()
	available_items[item.category] += item
	return TRUE

/datum/blackmarket_market/proc/purchase(item, category, method, obj/item/blackmarket_uplink/uplink, user) // Handles buying the item, this is mainly for future use and moving the code away from the uplink.
	if(!istype(uplink) || !(method in shipping))
		return FALSE
	for(var/datum/blackmarket_item/I in available_items[category])
		if(I.type != item)
			continue
		var/price = item_price(I, user) + shipping[method]
		if(uplink.money < price) // I can't get the price of the item and shipping in a clean way to the UI, so I have to do this.
			to_chat(user, "<span class='warning'>You don't have enough credits in [uplink] for [I] with [method] shipping.</span>")
			return FALSE
		if(I.buy(uplink, user, method, price))
			uplink.money -= price
			return TRUE
		return FALSE

/// Цена лота без доставки: по рынку контрабанды сектора.
/datum/blackmarket_market/proc/item_price(datum/blackmarket_item/listing, mob/user)
	. = econ_blackmarket_price(listing.price)
	if(user?.mind?.has_antag_datum(/datum/antagonist/rev/head))
		. = round(. / 100, 1) // скидка хедревам
//
/datum/blackmarket_market/blackmarket
	name = "Black Market"
	shipping = list(SHIPPING_METHOD_LTSRBT	=50,
	SHIPPING_METHOD_LAUNCH	=10,
	SHIPPING_METHOD_TELEPORT=75)
