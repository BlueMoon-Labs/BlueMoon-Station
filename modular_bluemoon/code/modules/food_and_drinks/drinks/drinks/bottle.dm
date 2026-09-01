/obj/item/reagent_containers/food/drinks/bottle/blank/vampire_bottle
	name = "Vampire Delight"
	desc = "To sate the fanged gentlemen and gentlewomen."
	list_reagents = list(/datum/reagent/blood/fancy = 90)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle
	name = "Syrup Bottle"
	desc = "In cooking, syrup is a condiment that is a thick, viscous liquid consisting primarily of a solution of sugar in water, containing a large amount of dissolved sugars but showing little tendency to deposit crystals."
	icon = 'modular_bluemoon/icons/obj/drinks.dmi'
	icon_state = "common_syrop_b"
	volume = 40
	list_reagents = list(/datum/reagent/consumable/sugar/syrup = 40)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/update_overlays()
	. = ..()
	if(!cached_icon)
		cached_icon = icon_state

	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('modular_bluemoon/icons/obj/drinks.dmi', "4", color = mix_color_from_reagents(reagents.reagent_list))

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)
				filling.icon_state = "syrup_0"
			if(10 to 19)
				filling.icon_state = "syrup_1"
			if(20 to 29)
				filling.icon_state = "syrup_2"
			if(30 to 39)
				filling.icon_state = "syrup_3"
			if(40 to INFINITY)
				filling.icon_state = "syrup_4"
		. += filling

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/banana
	name = "Banana Syrup Bottle"
	desc = "Banana syrup is a simple syrup with a delicious banana flavor. Like all simple syrup, it's mainly made of sugar and water, then flavored with ripe bananas."
	icon_state = "banana_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/banana = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/caramel
	name = "Caramel Syrup Bottle"
	desc = "It is surprisingly easy to make caramel syrup from scratch, calling for just sugar, water, vanilla extract, and a pinch of salt. It adds a rich sweetness to drinks, including your morning coffee or evening cocktails."
	icon_state = "caramel_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/caramel = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/chili
	name = "Chili Syrup Bottle"
	desc = "Sweet and spicy chili simple syrup is made by soaking chili peppers in a simple syrup.  The simple syrup becomes infused with the chili peppers creating a slightly spicy, sultry, amber colored simple syrup that is truly addicting."
	icon_state = "chili_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/chili = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/crocin
	name = "Crocin Syrup Bottle"
	desc = "Naturally found in the crocus and gardenia flowers, this drug acts as a natural and safe aphrodisiac. Now turned into a syrup!"
	icon_state = "crocin_syrop_b"
	list_reagents = list(/datum/reagent/drug/aphrodisiac/syrup = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/semen
	name = "Semen Syrup Bottle"
	desc = "Sperm turned into syrup. Succubi love those!"
	icon_state = "cum_syrop_b"
	list_reagents = list(/datum/reagent/consumable/semen/syrup = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/grape
	name = "Grape Syrup Bottle"
	desc = "Grape syrup is a condiment made with concentrated grape juice. It is thick and sweet because of its high ratio of sugar to water. Grape syrup is made by boiling grapes, removing their skins, squeezing them through a sieve to extract the juice."
	icon_state = "grape_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/grape = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/cactus
	name = "Cactus Syrup Bottle"
	desc = "Cactus Syrup expertly recreates the exciting taste of this world-famous plant. With a floral nose and flavour, this syrup makes a fantastic addition to cocktails, mocktails, sodas and more. Be adventurous and give this one a try!"
	icon_state = "cactus_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/cactus = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/mint
	name = "Mint Syrup Bottle"
	desc = "This mint simple syrup is made with fresh mint leaves, sugar, and water to create a minty fresh sweet syrup to add a refreshing lift to cocktails, mocktails, pastry glazes, and frozen desserts."
	icon_state = "mint_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/mint = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/orange
	name = "Orange Syrup Bottle"
	desc = "This Orange Syrup tastes exactly like it sounds – sweet, silky  orange syrup – the perfect amount of citrus, the perfect amount of sugar and the perfect kiss of butter."
	icon_state = "orange_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/orange = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/saltcaramel
	name = "Saltcaramel Syrup Bottle"
	desc = "The decadence of caramel combined with the complement of salt makes for a surprising flavor pairing. Salted Caramel adds delicious salty sweetness to specialty cocktails, hot and cold lattes, cappuccinos and coffee beverages."
	icon_state = "saltcaramel_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/saltcaramel = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/vanilla
	name = "Vanilla Syrup Bottle"
	desc = "Nothing beats the original. Inspired by premium vanilla flavor, it’s clean, pure and creamy. And that spells delicious every time you add it."
	icon_state = "vanila_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/vanilla = 40)

/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/watermelon
	name = "Watermelon Syrup Bottle"
	desc = "Succulent and sweet, watermelon is a summertime picnic favorite that is now available year round. Use our Watermelon Syrup to freshen up your sodas, slushes, teas and exotic cocktails."
	icon_state = "watermelon_syrop_b"
	list_reagents = list(/datum/reagent/consumable/sugar/syrup/watermelon = 40)

/obj/item/reagent_containers/food/drinks/bottle/macvulp
	name = "Red Fox's strawberry milk"
	desc = "Упаковка молочного коктейля с милой мордочкой лиса."
	custom_price = PRICE_ALMOST_CHEAP
	icon = 'modular_bluemoon/icons/obj/drinks.dmi'
	icon_state = "macvulp_milk_strawberry"
	list_reagents = list(/datum/reagent/consumable/milkshake_strawberry/lactose_free = 100)
	foodtype = FRUIT | BREAKFAST

/obj/item/reagent_containers/food/drinks/bottle/macvulp/choco
	name = "Red Fox's choco milk"
	icon_state = "macvulp_milk_choco"
	list_reagents = list(/datum/reagent/consumable/choccyshake/lactose_free = 100)
	foodtype = BREAKFAST

/obj/item/reagent_containers/food/drinks/bottle/macvulp/banana
	name = "Red Fox's banana milk"
	icon_state = "macvulp_milk_banana"
	list_reagents = list(/datum/reagent/consumable/milkshake_banana/lactose_free = 100)
	foodtype = FRUIT | BREAKFAST

/obj/item/reagent_containers/food/drinks/beer/macvulp
	name = "Macvulp non-alcoholic beer"
	desc = "Beer. In space."
	icon = 'modular_bluemoon/icons/obj/drinks.dmi'
	icon_state = "macvulp_beer"
	list_reagents = list(/datum/reagent/consumable/non_alcoholic_beer = 30)
	foodtype = GRAIN
	custom_price = PRICE_BELOW_NORMAL
