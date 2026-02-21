/datum/crafting_recipe/food/satsuma_black
	name = "Satsuma Black"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/tofu = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		/obj/item/reagent_containers/food/snacks/sea_weed = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/satsuma_black
	subcategory = CAT_SOUP

/datum/crafting_recipe/food/homemade_dashi
	name = "Dashi"
	reqs = list(
		/datum/reagent/water = 10,
		/datum/reagent/consumable/bonito = 20,
		/obj/item/reagent_containers/food/snacks/sea_weed = 1,
		/obj/item/reagent_containers/glass/bowl = 1
	)
	result = /obj/item/reagent_containers/food/snacks/soup/dashi
	subcategory = CAT_SOUP

// Shoyu Ramen
/datum/crafting_recipe/food/shoyu_ramen
	name = "shōyu ramen"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/datum/reagent/consumable/nutriment/soup/teriyaki = 15,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		// /obj/item/reagent_containers/food/snacks/kamaboko_slice = 1, нету
		/obj/item/reagent_containers/food/snacks/meat/cutlet = 1,
		/obj/item/reagent_containers/food/snacks/boiledegg = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/shoyu_ramen
	subcategory = CAT_SOUP

/datum/crafting_recipe/food/secret_noodle_soup
	name = "secret noodle soup"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/meat/cutlet/chicken = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		/obj/item/reagent_containers/food/snacks/grown/mushroom/chanterelle = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/secret_noodle_soup
	subcategory = CAT_SOUP

/datum/crafting_recipe/food/new_osaka_sunrise
	name = "new Osaka Sunrise Soup"
	reqs = list(
		/datum/reagent/consumable/nutriment/soup/miso = 15,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/grown/herbs = 1,
		/obj/item/reagent_containers/food/snacks/grown/eggplant = 1,
		/obj/item/reagent_containers/food/snacks/onion_slice = 1,
		/obj/item/reagent_containers/food/snacks/tofu = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/new_osaka_sunrise
	subcategory = CAT_SOUP

// Miso soup
/datum/crafting_recipe/food/miso
	name = "Miso Soup"
	reqs = list(
		/datum/reagent/water = 50,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/soydope = 2,
		/obj/item/reagent_containers/food/snacks/tofu = 2,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/miso
	subcategory = CAT_SOUP

// Gyuramen
/datum/crafting_recipe/food/gyuramen
	name = "Gyuramen Miy Käzu"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/datum/reagent/consumable/soysauce = 5,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		/obj/item/reagent_containers/food/snacks/cheesewedge = 1,
		/obj/item/reagent_containers/food/snacks/onion_slice = 2,
		/obj/item/reagent_containers/food/snacks/meat/cutlet = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/gyuramen
	subcategory = CAT_SOUP

// Dragon Style
/datum/crafting_recipe/food/dragon_ramen
	name = "\improper Dragon Style ramen"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/datum/reagent/consumable/nutriment/soup/teriyaki = 10,
		/datum/reagent/consumable/red_bay = 5,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		/obj/item/reagent_containers/food/snacks/grown/ghost_chili = 1,
		/obj/item/reagent_containers/food/snacks/grown/chili = 1,
		// /obj/item/reagent_containers/food/snacks/kamaboko_slice = 1, // Устала это делать, доделайте кто-нибудь ;-;
		/obj/item/reagent_containers/food/snacks/boiledegg = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/dragon_ramen
	subcategory = CAT_SOUP

/datum/crafting_recipe/food/foxs_prize_soup
	name = "fox's prize soup"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/datum/reagent/consumable/eggwhite = 10,
		/obj/item/reagent_containers/glass/bowl = 1,
		/obj/item/reagent_containers/food/snacks/meat/cutlet/chicken = 1,
		/obj/item/reagent_containers/food/snacks/tofu = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/foxs_prize_soup
	subcategory = CAT_SOUP

/datum/crafting_recipe/food/secret_noodle_soup
	name = "secret noodle soup"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/soup/dashi = 1,
		/obj/item/reagent_containers/food/snacks/meat/cutlet/chicken = 1,
		/obj/item/reagent_containers/food/snacks/spaghetti/boilednoodles = 1,
		/obj/item/reagent_containers/food/snacks/grown/mushroom/chanterelle = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/soup/secret_noodle_soup
	subcategory = CAT_SOUP
