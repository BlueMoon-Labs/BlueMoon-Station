// Чипсы MacNachos
/obj/item/reagent_containers/food/snacks/chips/macnachos
	name = "MacNachos Diablo"
	desc = "Лис на упаковке словно говорит вам “Это, черт возьми, остро!”"
	icon_state = "macnachos"
	trash = /obj/item/trash/chips/macnachos
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/capsaicin = 3)
	filling_color = "#ff5100"
	tastes = list("hot" = 1, "crisps" = 1)
	custom_price = PRICE_CHEAP

/obj/item/reagent_containers/food/snacks/lollipop/capsaicin
	name = "Chupa-Chups"
	desc = "Леденец на палочке с ”освежающим” вкусом перца. На этикетке мелким шрифтом: ”Соси и плачь, тупая дура”."
	icon = 'icons/obj/lollipop.dmi'
	icon_state = "lollipop_stick"
	item_state = "lollipop_stick"
	list_reagents = list(
		/datum/reagent/consumable/nutriment = 1,
		/datum/reagent/consumable/sugar = 3,
		/datum/reagent/consumable/capsaicin = 2,
		/datum/reagent/consumable/condensedcapsaicin = 5,
		/datum/reagent/consumable/tearjuice = 4,
	)
	tastes = list("candy" = 1, "hot" = 2, "bitterness" = 1)
	bitesize = 1
	foodtype = JUNKFOOD | SUGAR
	slot_flags = ITEM_SLOT_MASK
	custom_price = PRICE_CHEAP

/obj/item/reagent_containers/food/snacks/lollipop/capsaicin/Initialize(mapload)
	. = ..()
	change_head_color(rgb(220, 45, 15))
	AddElement(/datum/element/chewable, metabolization_amount = REAGENTS_METABOLISM / 2)

// Вульпиксы (чебупели)
/obj/item/reagent_containers/food/snacks/donkpocket/vulpix
	name = "\improper MacVulpix Original Taste"
	desc = "Пластиковый контейнер доверху наполненный вкуснейшими и ароматными мясными шариками с кетчупом."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_classic_open"
	list_reagents = list(/datum/reagent/consumable/nutriment = 10)
	cooked_type = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/warm
	filling_color = "#CD853F"
	tastes = list("meat" = 2, "dough" = 2, "laziness" = 1)
	foodtype = GRAIN | JUNKFOOD | MEAT

/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/warm
	icon_state = "vulpix_classic_warm"
	cooked_type = null
	bonus_reagents = list(/datum/reagent/medicine/omnizine = 3)
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/medicine/omnizine = 3)

//Сырные вульпиксы
/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese
	name = "\improper MacVulpix Triple-Cheese"
	desc = "Пластиковый контейнер доверху наполненный вкуснейшими и ароматными мясными шариками с сырным соусом."
	icon_state = "vulpix_cheese_open"
	cooked_type = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese/warm
	foodtype = GRAIN | JUNKFOOD | MEAT | DAIRY

/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese/warm
	icon_state = "vulpix_cheese_warm"
	cooked_type = null
	bonus_reagents = list(/datum/reagent/medicine/omnizine = 3)
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/medicine/omnizine = 3)

//Упаковка с вульпиксами
/obj/item/small_delivery/donk_vulpix
	name = "MacVulpix Original Taste"
	desc = "Классический вкус вульпиксов, проверенный временем, в удобной порционной упаковке."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_classic"
	custom_price = PRICE_BELOW_NORMAL
	var/init_packed_item = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix

/obj/item/small_delivery/donk_vulpix/cheese
	name = "MacVulpix Triple-Cheese"
	desc = "Классические вульпиксы - теперь с тройной сырной добавкой!"
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_cheese"
	init_packed_item = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese

/obj/item/small_delivery/donk_vulpix/Initialize(mapload)
	. = ..()
	var/obj/item/I = new init_packed_item(get_turf(loc))
	I.forceMove(src)

//Вендорный бургер (ретекстур большого бургера)
/obj/item/reagent_containers/food/snacks/burger/macvulpburger
	name = "MacVulpBurger gourmet"
	desc = "огромный, аппетитный и сочащийся соками бургер с двойной говяжей котлетой, трюфельным и ягодным соусом. "
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "macvulpburger"

/obj/item/storage/fancy/macvulpburger
	name = "MacVulpBurger gourmet box"
	desc = "Особый бургер из линейки “Большой Укус” с трюфельным и ягодным соусом, только для истинных гурманов!"
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "macvulpburger_box_closed"
	icon_type = "macvulpburger_" // честно - даже думать не хочу об этом
	spawn_type = /obj/item/reagent_containers/food/snacks/burger/macvulpburger
	fancy_open = TRUE
	custom_price = PRICE_ALMOST_CHEAP

/obj/item/storage/fancy/macvulpburger/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/food/snacks/burger))

// Коробка из под пиццы
/obj/item/pizzabox/macvulpizza
	name = "MacVulPizza extra pepperoni"
	desc = "Легендарная тройная пепперони-пицца от МакВульпикс с особым томатным соусом, в основе которого лежит тайная смесь сорока двух специй!"
	icon = 'modular_bluemoon/icons/obj/food/macvulpizzabox.dmi'
	custom_price = 500

/obj/item/pizzabox/macvulpizza/Initialize(mapload)
	. = ..()
	pizza = new /obj/item/reagent_containers/food/snacks/pizza/sassysage/macvulp(src)
	boxtag = "MacVulpix"

// Пицца
/obj/item/reagent_containers/food/snacks/pizza/sassysage/macvulp
	name = "MacVulPizza extra pepperoni"
	desc = "Хорошо выглядящая пицца с тройной порцией пепперони, большим количеством моцареллы и ярким томатным соусом."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "macvulpizza"
	slice_path = /obj/item/reagent_containers/food/snacks/pizzaslice/sassysage/macvulp

/obj/item/reagent_containers/food/snacks/pizzaslice/sassysage/macvulp
	name = "MacVulPizza extra pepperoni pizza slice"
	desc = "Хорошо выглядящий кусок пиццы с тройной порцией пепперони, большим количеством моцареллы и ярким томатным соусом."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "macvulpizza_slice"
