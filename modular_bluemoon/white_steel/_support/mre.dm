//WHITE-STEEL PORT - Индивидуальный рацион питания

/obj/item/storage/mre
	name = "ИРП-4"
	desc = "Запечатанный под вакуумом пакет с дневным запасом питательных веществ для взрослого, находящегося в тяжелых условиях. На упаковке нет видимой даты истечения срока годности."
	icon = 'modular_bluemoon/white/valtos/icons/mre.dmi'
	icon_state = "mre"
	var/open_sound = 'modular_bluemoon/white/valtos/sounds/rip1.ogg'
	var/list/meal_contents = list(
		/obj/item/storage/mrebag,
		/obj/item/storage/mrebag,
		/obj/item/storage/mrebag/dessert,
		/obj/item/reagent_containers/food/snacks/breadslice/meat,
		/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind,
		/obj/item/reagent_containers/food/condiment/pack/hotsauce)

/obj/item/storage/mre/PopulateContents()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 6
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.allow_quick_empty = FALSE
	STR.rustle_sound = FALSE
	STR.locked = TRUE
	for(var/i in meal_contents)
		new i(src)

/obj/item/storage/mre/update_icon()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR.locked)
		icon_state = "[initial(icon_state)]1"
	. = ..()

/obj/item/storage/mre/attack_self(mob/user)
	open(user)
	. = ..()

/obj/item/storage/mre/proc/open(mob/user)
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR.locked)
		playsound(get_turf(src), open_sound, 50, TRUE)
		STR.locked = FALSE
		to_chat(user, span_notice("Вскрываю упаковку. Приятный запах начинает исходить из неё."))
		update_icon()

/obj/item/storage/mre/vegan
	name = "ИРП-6"
	icon_state = "vegmre"
	meal_contents = list(
		/obj/item/storage/mrebag/vegan,
		/obj/item/storage/mrebag/vegan,
		/obj/item/storage/mrebag/dessert,
		/obj/item/reagent_containers/food/snacks/breadslice/tofu,
		/obj/item/reagent_containers/glass/beaker/waterbottle,
		/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind)

/obj/item/storage/mre/protein
	name = "ИРП-47"
	icon_state = "meatmre"
	meal_contents = list(
		/obj/item/storage/mrebag/protein,
		/obj/item/storage/mrebag/protein,
		/obj/item/storage/mrebag/dessert,
		/obj/item/reagent_containers/food/snacks/grilledcheese,
		/obj/item/reagent_containers/food/condiment/pack/bbqsauce,
		/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind)

/obj/item/storage/mrebag
	name = "основное блюдо (пицца)"
	desc = "Запечатанный под вакуумом пакет, содержащий основное блюдо ИРП. Саморазогревается при открытии."
	icon = 'modular_bluemoon/white/valtos/icons/mre.dmi'
	icon_state = "pouch_medium"
	w_class = WEIGHT_CLASS_SMALL
	var/open_sound = 'sound/effects/bubbles.ogg'

/obj/item/storage/mrebag/proc/generate_main_meal()
	var/obj/item/main_meal = pick(subtypesof(/obj/item/reagent_containers/food/snacks/pizzaslice))
	new main_meal(src)

/obj/item/storage/mrebag/vegan
	name = "основное блюдо (салат)"

/obj/item/storage/mrebag/vegan/generate_main_meal()
	var/obj/item/main_meal = pick(subtypesof(/obj/item/reagent_containers/food/snacks/salad))
	new main_meal(src)

/obj/item/storage/mrebag/protein
	name = "основное блюдо (бургер)"

/obj/item/storage/mrebag/protein/generate_main_meal()
	var/obj/item/main_meal = pick(subtypesof(/obj/item/reagent_containers/food/snacks/burger))
	new main_meal(src)

/obj/item/storage/mrebag/PopulateContents()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.locked = TRUE
	generate_main_meal()

/obj/item/storage/mrebag/update_icon()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR.locked)
		icon_state = "[initial(icon_state)]1"
	. = ..()

/obj/item/storage/mrebag/attack_self(mob/user)
	open(user)
	. = ..()

/obj/item/storage/mrebag/proc/open(mob/user)
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR.locked)
		playsound(get_turf(src), open_sound, 50, TRUE)
		STR.locked = FALSE
		to_chat(user, span_notice("Вскрываю упаковку. Приятный запах начинает исходить из неё."))
		update_icon()

/obj/item/storage/mrebag/dessert
	name = "десерт"
	desc = "Вакуумный пакет с десертом ИРП."
	icon_state = "pouch_small"
	open_sound = 'modular_bluemoon/white/valtos/sounds/rip1.ogg'

/obj/item/storage/mrebag/dessert/PopulateContents()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.allow_quick_empty = FALSE
	STR.rustle_sound = FALSE
	STR.locked = TRUE
	var/obj/item/picked_content = pick(subtypesof(/obj/item/reagent_containers/food/snacks/donut))
	new picked_content(src)
