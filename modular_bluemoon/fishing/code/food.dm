// Общий корень для новых путей еды из модуля рыбалки.
/obj/item/food
	parent_type = /obj/item/reagent_containers/food/snacks
	icon = 'modular_bluemoon/fishing/icons/obj/food.dmi'
	icon_state = "fishfillet"

/obj/item/food/fishmeat
	name = "fish fillet"
	desc = "Филе рыбьего мяса."
	icon_state = "fishfillet"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	bitesize = 4
	tastes = list("fish" = 1)
	foodtype = SEAFOOD
	cooked_type = /obj/item/food/cooked_fish

/obj/item/food/fishmeat/quality
	name = "quality fish fillet"
	desc = "Филе драгоценного рыбьего мяса."
	icon_state = "fishfillet_quality"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	cooked_type = /obj/item/food/cooked_fish/quality

/obj/item/food/fishmeat/salmon
	name = "salmon fillet"
	desc = "Крупное жирное филе лосося."
	icon_state = "salmon"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/fat = 2,
	)
	cooked_type = /obj/item/food/cooked_fish/salmon

/obj/item/food/fishmeat/carp
	name = "carp fillet"
	desc = "Филе космического карпа."
	icon_state = "fishfillet_carp"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/toxin/carpotoxin = 2,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	cooked_type = /obj/item/food/cooked_fish/carp

/obj/item/food/fishmeat/carp/imitation
	name = "imitation carp fillet"
	desc = "Почти как настоящее, только вроде бы нет."
	icon_state = "fishfillet_imitation"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 3)
	cooked_type = /obj/item/food/cooked_fish/imitation

/obj/item/food/fishmeat/carp/no_tox
	icon_state = "fishfillet_carp"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	cooked_type = /obj/item/food/cooked_fish/carp

/obj/item/food/carpmeat/icantbeliveitsnotcarp
	parent_type = /obj/item/food/fishmeat/carp
	icon_state = "fishfillet_imitation"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 3)
	cooked_type = /obj/item/food/cooked_fish/imitation

/obj/item/food/fishmeat/moonfish
	name = "moonfish fillet"
	desc = "Филе лунорыбы."
	icon_state = "moonfish_fillet"
	cooked_type = /obj/item/food/grilled_moonfish

/obj/item/food/fishmeat/gunner_jellyfish
	name = "gunner jellyfish fillet"
	desc = "Медуза-артиллерист без жал."
	icon_state = "jellyfish_fillet"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 4)
	cooked_type = /obj/item/food/cooked_fish/jellyfish

/obj/item/food/fishmeat/armorfish
	name = "cleaned armorfish"
	desc = "Бронерыба без внутренностей и панциря, готовая к готовке."
	icon_state = "armorfish_fillet"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 3)
	cooked_type = /obj/item/food/cooked_fish/armorfish

/obj/item/food/fishmeat/donkfish
	name = "donkfillet"
	desc = "Жуткое филе донк-рыбы."
	icon_state = "donkfillet"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 2)
	cooked_type = /obj/item/food/cooked_fish/donkfish

/obj/item/food/fishmeat/octopus
	name = "octopus tentacle"
	desc = "Крупное щупальце осьминога."
	icon_state = "octopus_fillet"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 3)
	cooked_type = /obj/item/food/grilled_octopus

/obj/item/food/fishmeat/fish_tail
	name = "fish tail fillet"
	desc = "Драгоценное жирное филе, вырезанное прямо из хвоста огромной рыбы."
	icon_state = "fishfillet_tail"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
		/datum/reagent/consumable/nutriment/fat = 2,
	)
	cooked_type = /obj/item/food/cooked_fish/fish_tail

// Готовые блюда. У каждого свой спрайт, чтобы еда не выглядела одинаково.
/obj/item/food/cooked_fish
	name = "cooked fish"
	desc = "Приготовленная рыба. Пахнет приятно."
	icon_state = "fishfry"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	bitesize = 4
	tastes = list("cooked fish" = 1)
	foodtype = SEAFOOD

/obj/item/food/cooked_fish/quality
	name = "gourmet fried fish"
	desc = "Роскошное филе, обжаренное до золотистой корочки."
	icon_state = "fishfry_quality"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/fat = 1,
	)
	tastes = list("fine fish" = 1, "crispy crust" = 1)
	foodtype = SEAFOOD | FRIED

/obj/item/food/cooked_fish/salmon
	name = "grilled salmon"
	desc = "Сочный лосось, зажаренный целиком."
	icon_state = "grilled_moonfish"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/fat = 2,
	)
	tastes = list("grilled salmon" = 1)
	foodtype = SEAFOOD

/obj/item/food/cooked_fish/carp
	name = "fried carp"
	desc = "Кусок карпа, прожаренный до хруста."
	icon_state = "fishfry_carp"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/toxin/carpotoxin = 1,
	)
	tastes = list("cooked carp" = 1)
	foodtype = SEAFOOD | FRIED

/obj/item/food/cooked_fish/imitation
	name = "imitation fish fingers"
	desc = "Рыбные палочки из чего-то, что притворяется рыбой."
	icon_state = "fishfingers"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("fish" = 1, "breadcrumbs" = 1)
	foodtype = SEAFOOD | FRIED

/obj/item/food/cooked_fish/donkfish
	name = "fried donkfillet"
	desc = "Донк-рыба, которую всё-таки решили приготовить. Пахнет подозрительно."
	icon_state = "fishfry_donk"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	tastes = list("regret" = 1)
	foodtype = SEAFOOD | FRIED

/obj/item/food/cooked_fish/fish_tail
	name = "fish tail and chips"
	desc = "Хвостовое филе с картофелем. Роскошно и сытно."
	icon_state = "fishandchips"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/nutriment/fat = 2,
	)
	tastes = list("fish" = 1, "chips" = 1)
	foodtype = SEAFOOD | VEGETABLES | FRIED

/obj/item/food/cooked_fish/jellyfish
	name = "jellyfish stew"
	desc = "Густой суп из медузы-артиллериста."
	icon_state = "jellyfish_stew"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("jelly" = 1, "broth" = 1)
	foodtype = SEAFOOD

/obj/item/food/cooked_fish/armorfish
	name = "armorfish skewer"
	desc = "Бронерыба на шпажке с луком и перцем."
	icon_state = "picoss_skewer"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 7,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("fish" = 1, "onion" = 1)
	foodtype = SEAFOOD | VEGETABLES

/obj/item/food/cooked_fish/crab
	name = "crab meat"
	desc = "Приготовленное мясо краба."
	icon_state = "crabmeat"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 5,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("crab" = 1)
	foodtype = SEAFOOD

/obj/item/food/meat/slab/rawcrab
	name = "raw crab meat"
	desc = "Кучка сырого мяса краба."
	icon_state = "crabmeatraw"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/consumable/nutriment/fat = 3,
	)
	bitesize = 3
	tastes = list("raw crab" = 1)
	foodtype = SEAFOOD
	cooked_type = /obj/item/food/cooked_fish/crab

/obj/item/food/grilled_moonfish
	name = "grilled moonfish"
	desc = "Жареное филе лунорыбы."
	icon_state = "grilled_moonfish"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment/vitamin = 4,
	)
	foodtype = SEAFOOD

/obj/item/food/grilled_octopus
	name = "grilled octopus"
	desc = "Жареные щупальца осьминога."
	icon_state = "grilled_octopus"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 7,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	foodtype = SEAFOOD

/obj/item/food/moonfish_eggs
	name = "moonfish eggs"
	desc = "Кластер крупной икры лунорыбы."
	icon_state = "moonfish_eggs"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/consumable/nutriment/vitamin = 1,
	)
	foodtype = SEAFOOD
	cooked_type = /obj/item/food/moonfish_caviar

/obj/item/food/moonfish_caviar
	name = "moonfish caviar paste"
	desc = "Густая паста из икры лунорыбы."
	icon_state = "moonfish_caviar"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("caviar" = 1)
	foodtype = SEAFOOD

/obj/item/food/seaweed
	name = "seaweed"
	desc = "Пучок морских водорослей."
	icon_state = "sea_weed"
	list_reagents = list(/datum/reagent/consumable/nutriment = 1)
	foodtype = VEGETABLES

// Неприглядные, но всё же съедобные остатки рыбалки.
/obj/item/food/badrecipe
	name = "burnt mess"
	desc = "Что-то, что когда-то было едой. Теперь это лучше не трогать."
	icon_state = "badrecipe"
	list_reagents = list(/datum/reagent/toxin = 1)
	bitesize = 1
	tastes = list("burnt" = 1)
	foodtype = GROSS

/obj/item/food/badrecipe/moldy/bacteria
	name = "moldy bacteria"
	desc = "Слизистый комок из рыбьих внутренностей. Пахнет особенно скверно."
	icon_state = "badrecipe_moldy"

/obj/item/food/meat/slab/human/mutant/slime
	name = "slime meat"
	desc = "Слизистое мясо, которое лучше не рассматривать слишком долго."
	icon_state = "slimemeat"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/toxin/slimejelly = 3,
	)
	tastes = list("slime" = 1, "jelly" = 1)
	foodtype = SEAFOOD

/obj/item/food/meat/slab/human/mutant/zombie
	name = "rotten meat"
	desc = "Мясо, которое явно пролежало слишком долго."
	icon_state = "rottenmeat"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 3,
		/datum/reagent/toxin = 2,
	)
	tastes = list("rot" = 1)
	foodtype = SEAFOOD

/obj/item/food/meat/cutlet/plain/human
	name = "strange cutlet"
	desc = "Кусок мяса, происхождение которого лучше не выяснять."
	icon_state = "cutlet"
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 2)
	tastes = list("meat" = 1)
	foodtype = SEAFOOD

/obj/item/food/nugget/fish
	name = "fish nugget"
	desc = "Рыбный наггетс странной формы."
	icon_state = "nugget_lump"
	list_reagents = list(
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 2,
	)
	tastes = list("fried fish" = 1)
	foodtype = SEAFOOD | FRIED

