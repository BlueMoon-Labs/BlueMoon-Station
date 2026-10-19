/obj/machinery/computer/unit_test_lit_console
	use_power = NO_POWER_USE

/obj/item/unit_test_lamp
	light_range = 2
	light_power = 1

/// Копия погашенного шаблона держит ровно свой источник света и не оставляет сирот после qdel.
/datum/unit_test/duplicate_object_light_source

/datum/unit_test/duplicate_object_light_source/Run()
	var/obj/machinery/computer/console_template = allocate(/obj/machinery/computer/unit_test_lit_console)
	console_template.set_light(0)
	TEST_ASSERT_NULL(console_template.light, "Шаблон консоли не погас - предпосылка теста сломана")

	var/obj/machinery/computer/console_copy = DuplicateObject(console_template, newloc = run_loc_floor_top_right)
	TEST_ASSERT_NOTNULL(console_copy, "DuplicateObject не создал копию консоли")
	TEST_ASSERT_NOTNULL(console_copy.light, "Запитанная копия консоли не светится")
	TEST_ASSERT_EQUAL(count_light_sources_of(console_copy), 1, "У копии консоли не один источник света")
	qdel(console_copy)
	TEST_ASSERT_EQUAL(count_light_sources_of(console_copy), 0, "После qdel копии консоли на неё ссылается источник света")

	var/obj/item/lamp_template = allocate(/obj/item/unit_test_lamp)
	lamp_template.set_light(0)
	var/obj/item/lamp_copy = DuplicateObject(lamp_template, newloc = run_loc_floor_top_right)
	TEST_ASSERT_NULL(lamp_copy.light, "Копия погашенной лампы светится")
	TEST_ASSERT_EQUAL(count_light_sources_of(lamp_copy), 0, "Копия погашенной лампы держит источник света")
	qdel(lamp_copy)

	var/obj/item/flashlight/lamp/overlay_lamp_template = allocate(/obj/item/flashlight/lamp/green)
	var/obj/item/flashlight/lamp/overlay_lamp_copy = DuplicateObject(overlay_lamp_template, newloc = run_loc_floor_top_right)
	TEST_ASSERT(length(overlay_lamp_copy.affected_dynamic_lights), "Копия настольной лампы не светит - предпосылка теста сломана")
	for(var/datum/component/overlay_lighting/light_component as anything in overlay_lamp_copy.affected_dynamic_lights)
		TEST_ASSERT_EQUAL(light_component.parent, overlay_lamp_copy, "Копия настольной лампы учитывает источник света шаблона")
	qdel(overlay_lamp_copy)

/datum/unit_test/duplicate_object_light_source/proc/count_light_sources_of(atom/owner)
	. = 0
	for(var/datum/light_source/source as anything in GLOB.all_light_sources)
		if(source.source_atom == owner || source.top_atom == owner)
			.++

/// Поглаживание кладёт мудлет под строковую категорию: погладивший не держит питомца ключом.
/datum/unit_test/petting_mood_category

/datum/unit_test/petting_mood_category/Run()
	var/mob/living/carbon/human/petter = allocate(/mob/living/carbon/human)
	var/datum/component/mood/mood = petter.GetComponent(/datum/component/mood) || petter.AddComponent(/datum/component/mood)
	petter.zone_selected = BODY_ZONE_HEAD

	var/mob/living/carbon/human/headpat_lover = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	headpat_lover.AddElement(/datum/element/wuv/headpat, null, null, /datum/mood_event/pet_animal)
	var/datum/element/wuv/headpat/headpat = SSdcs.GetElement(list(/datum/element/wuv/headpat, null, null, /datum/mood_event/pet_animal))
	headpat.pet_the_dog(headpat_lover, petter)
	TEST_ASSERT(has_pet_moodlet(mood), "Погладивший по голове не получил мудлет")
	check_categories(mood, "после поглаживания по голове")

	var/mob/living/simple_animal/pet = allocate(/mob/living/simple_animal, run_loc_floor_top_right)
	pet.AddElement(/datum/element/wuv, "урчит.", EMOTE_VISIBLE, /datum/mood_event/pet_animal)
	var/datum/element/wuv/wuv = SSdcs.GetElement(list(/datum/element/wuv, "урчит.", EMOTE_VISIBLE, /datum/mood_event/pet_animal))
	wuv.pet_the_dog(pet, petter)
	check_categories(mood, "после поглаживания питомца")

	var/mob/living/simple_animal/pet/dog/corgi/corgi = allocate(/mob/living/simple_animal/pet/dog/corgi, run_loc_floor_top_right)
	corgi.place_on_head(null, petter)
	check_categories(mood, "после поглаживания корги")

	qdel(headpat_lover)
	qdel(pet)
	qdel(corgi)
	for(var/mob/gone as anything in list(headpat_lover, pet, corgi))
		TEST_ASSERT(!(gone in mood.mood_events), "mood_events держит удалённого [gone.type]")
		TEST_ASSERT(!(gone in mood.mood_event_timers), "mood_event_timers держит удалённого [gone.type]")

/datum/unit_test/petting_mood_category/proc/has_pet_moodlet(datum/component/mood/mood)
	for(var/category in mood.mood_events)
		if(istype(mood.mood_events[category], /datum/mood_event/pet_animal))
			return TRUE
	return FALSE

/datum/unit_test/petting_mood_category/proc/check_categories(datum/component/mood/mood, stage)
	for(var/category in mood.mood_events)
		TEST_ASSERT(!isdatum(category), "Категория мудлета [stage] - датум [category]")
	for(var/category in mood.mood_event_timers)
		TEST_ASSERT(!isdatum(category), "Категория таймера мудлета [stage] - датум [category]")

/// update_appearance() на собранной еде не трогает её имя и не падает.
/datum/unit_test/customizable_food_update_appearance

/datum/unit_test/customizable_food_update_appearance/Run()
	var/mob/living/carbon/human/cook = allocate(/mob/living/carbon/human)
	var/obj/item/reagent_containers/food/snacks/customizable/pizza/pizza = allocate(/obj/item/reagent_containers/food/snacks/customizable/pizza)
	var/obj/item/reagent_containers/food/snacks/cheesewedge/cheese = allocate(/obj/item/reagent_containers/food/snacks/cheesewedge)
	var/cheese_name = cheese.name
	cook.put_in_hands(cheese)
	pizza.attackby(cheese, cook)
	TEST_ASSERT(cheese in pizza.ingredients, "Сыр не лёг в пиццу - предпосылка теста сломана")
	var/assembled_name = pizza.name
	TEST_ASSERT(findtext(assembled_name, cheese_name), "Имя собранной пиццы без ингредиента: [assembled_name]")

	try
		pizza.update_appearance()
	catch(var/exception/update_error)
		TEST_FAIL("update_appearance() на собранной пицце упал: [update_error]")
	TEST_ASSERT_EQUAL(pizza.name, assembled_name, "update_appearance() переименовал собранную пиццу")

/// Вспышка рисует срабатывание только по явному запросу, а не от update_appearance().
/datum/unit_test/flash_update_appearance

/datum/unit_test/flash_update_appearance/Run()
	var/obj/item/assembly/flash/handheld/flash = allocate(/obj/item/assembly/flash/handheld)
	flash.update_appearance()
	TEST_ASSERT(!(flash.flashing_overlay in flash.attached_overlays), "update_appearance() нарисовал срабатывание вспышки")
	flash.update_icon(ALL, TRUE)
	TEST_ASSERT(flash.flashing_overlay in flash.attached_overlays, "Явный вызов со вспышкой не нарисовал срабатывание")

/// Выездные врата без станционной пары отвечают отказом, а не падают.
/datum/unit_test/away_gateway_without_home

/datum/unit_test/away_gateway_without_home/Run()
	var/obj/machinery/gateway/station_gateway = GLOB.the_gateway
	GLOB.the_gateway = null
	var/obj/machinery/gateway/away/gateway = allocate(/obj/machinery/gateway/away)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/crash_text
	try
		gateway.interact(user)
	catch(var/exception/interact_error)
		crash_text = "[interact_error]"
	GLOB.the_gateway = station_gateway
	TEST_ASSERT_NULL(crash_text, "interact() выездных врат без станционных упал: [crash_text]")
	TEST_ASSERT_NULL(gateway.target, "Выездные врата без станционных куда-то подключились")
