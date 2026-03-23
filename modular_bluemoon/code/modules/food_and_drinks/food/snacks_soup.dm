/obj/item/reagent_containers/food/snacks/soup/satsuma_black
	name = "Satsuma Black Soup"
	desc = "A rich, heavy seafood and noodle soup from Mars, employing squid ink to give a strong taste of the sea."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "satsuma_black"
	// bonus_reagents = list(/datum/reagent/consumable/nutriment/vitamin = 11) - незнаю что сюда добавлять
	list_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/soup/satsuma_black = 30)
	tastes = list("seafood" = 1, "tofu" = 1, "noodles" = 1)
	trash = /obj/item/reagent_containers/glass/bowl
	filling_color = "#161513"
	foodtype = SEAFOOD | GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/soup/shoyu_ramen
	name = "shōyu ramen"
	desc = "A soy-sauce based ramen, with noodles, fishcake, barbecued meat and a boiled egg."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "shoyu_ramen"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/soup/shoyu_ramen = 30)
	tastes = list("egg" = 1, "fish" = 1, "noodles" = 1, "meat" = 1, "broth" = 1)
	filling_color = "#7a5816"
	foodtype = MEAT | GRAIN | VEGETABLES | SEAFOOD

/obj/item/reagent_containers/food/snacks/soup/secret_noodle_soup
	name = "secret Noodle Soup"
	desc = "Made to a secret family recipe (that's in several cookbooks). What is the secret ingredient, you ask? Well, let's just say it could be anything..."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "secret_noodle_soup"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/secret_noodle_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 6)
	tastes = list("noodles" = 1, "chicken" = 1, "aromatic broth" = 1)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#D9BB79"
	foodtype = MEAT | VEGETABLES | GRAIN

/obj/item/reagent_containers/food/snacks/soup/new_osaka_sunrise
	name = "new Osaka Sunrise Soup"
	desc = "A bright, flavourful miso soup with tofu that commonly forms part of a traditional Martian breakfast, at least in the capital."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "new_osaka_sunrise"
	tastes = list("miso" = 1, "tofu" = 1, "onion" = 1, "eggplant" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/new_osaka_sunrise = 30,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 2)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#EAB26E"
	foodtype = VEGETABLES | BREAKFAST

/obj/item/reagent_containers/food/snacks/soup/miso
	name = "Miso Soup"
	desc = "The universes best soup! Yum!!!"
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "misosoup"
	tastes = list("miso" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/miso = 30,
		/datum/reagent/water = 10)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#EAB26E"
	foodtype = VEGETABLES | BREAKFAST

/obj/item/reagent_containers/food/snacks/soup/gyuramen
	name = "gyuramen miy käzu"
	desc = "A rich beef and onion ramen with cheese- blending several cultural influences seemlessly into one tasty dish."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "gyuramen"
	tastes = list("beef broth" = 1, "onion" = 1, "cheese" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/gyuramen = 20,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/nutriment/protein = 10)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#442621"
	foodtype = MEAT | GRAIN | DAIRY | VEGETABLES

/obj/item/reagent_containers/food/snacks/soup/dragon_ramen
	name = "\improper Dragon Style ramen"
	desc = "For the ramen fan who hates their tastebuds and digestive tract. Traditionally made with seven different chilis, although after two or so the point sorta gets lost."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "gyuramen"
	tastes = list("meat" = 1, "liquid hot magma" = 1, "noodles" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dragon_ramen = 30,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 6,)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#980F00"
	foodtype = SEAFOOD | GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/soup/foxs_prize_soup
	name = "fox's prize soup"
	desc = "Originally based on the Chinese classic of egg-drop soup, fox's prize soup iterated on the concept via the addition of aburaage and dashi, making a dish that would truly appeal to any hungry fox."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "foxs_prize_soup"
	tastes = list("egg" = 1, "chicken" = 1, "fried tofu" = 1, "umami broth" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/foxs_prize_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
		)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#E9B200"
	foodtype = MEAT | VEGETABLES

/obj/item/reagent_containers/food/snacks/soup/secret_noodle_soup
	name = "secret noodle soup"
	desc = "Made to a secret family recipe (that's in several cookbooks). What is the secret ingredient, you ask? Well, let's just say it could be anything..."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "foxs_prize_soup"
	tastes = list("noodles" = 1, "chicken" = 1, "aromatic broth" = 1)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/soup/secret_noodle_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
		)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#D9BB79"
	foodtype = MEAT | VEGETABLES | GRAIN

/obj/item/reagent_containers/food/snacks/soup/dashi
	name = "Dashi soup"
	desc = "Made with kombu and katsuobushi, this mother stock forms the basis for a large number of Japanese dishes."
	icon = 'icons/obj/food/soupsalad.dmi'
	icon_state = "wishsoup"
	tastes = list("umami" = 1)
	list_reagents = list(/datum/reagent/consumable/nutriment/soup/dashi = 30)
	trash = /obj/item/reagent_containers/glass/bowl
	color = "#D49D26"
	foodtype = MEAT | VEGETABLES
