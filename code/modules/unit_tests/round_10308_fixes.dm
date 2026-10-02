/// Предмет, покинувший шкаф скафандров любым путём, обязан освободить свой слот.
/datum/unit_test/ssu_slot_cleared_on_exit/Run()
	var/obj/machinery/suit_storage_unit/unit = allocate(/obj/machinery/suit_storage_unit)
	var/obj/item/mod/control/suit = allocate(/obj/item/mod/control)
	suit.forceMove(unit)
	unit.mod = suit
	suit.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(unit.mod, "Шкаф держит МОД, которого в нём уже нет")

/// Выбивание двери изнутри роняет содержимое - слоты обязаны опустеть вместе с ним.
/datum/unit_test/ssu_resist_open_clears_slots/Run()
	var/obj/machinery/suit_storage_unit/unit = allocate(/obj/machinery/suit_storage_unit)
	var/mob/living/carbon/human/prisoner = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/stored_suit = allocate(/obj/item/clothing/suit/space)
	stored_suit.forceMove(unit)
	unit.suit = stored_suit
	unit.state_open = FALSE
	prisoner.forceMove(unit)
	unit.occupant = prisoner
	unit.resist_open(prisoner)
	TEST_ASSERT(unit.state_open, "resist_open() не открыл шкаф")
	TEST_ASSERT_NULL(unit.suit, "Шкаф держит скафандр, выпавший при выбивании двери")
	TEST_ASSERT_NULL(unit.occupant, "Шкаф держит выбравшегося пленника")

/// Кнопка способности модуля обязана удалиться вместе с модулем.
/datum/unit_test/mod_ability_button_dies_with_module/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/suit = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/module = allocate(/obj/item/mod/module)
	suit.wearer = wearer
	suit.generate_ability_button(module)
	suit.wearer = null
	var/datum/action/cooldown/module_action/button = locate() in wearer.actions
	TEST_ASSERT_NOTNULL(button, "Кнопка способности не выдана носителю")
	qdel(module)
	TEST_ASSERT(QDELETED(button), "Кнопка способности пережила свой модуль")
	TEST_ASSERT(!(button in wearer.actions), "Удалённая кнопка осталась в actions носителя")

/// Удаляемый мозг не должен заводить себе новый brainmob.
/datum/unit_test/brain_destroy_makes_no_brainmob/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	var/obj/item/organ/brain/brain = body.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_NOTNULL(brain, "У тестового человека нет мозга")
	qdel(body)
	TEST_ASSERT_NULL(brain.brainmob, "Мозг завёл brainmob во время собственного удаления")

/// Удаление хозяина обязано снять enslaved_to с разума слуги.
/datum/unit_test/mind_enslaved_to_released/Run()
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/servant = allocate(/mob/living/carbon/human)
	servant.mind_initialize()
	servant.mind.set_enslaved_to(master)
	TEST_ASSERT_EQUAL(servant.mind.enslaved_to, master, "set_enslaved_to() не записал хозяина")
	qdel(master)
	TEST_ASSERT_NULL(servant.mind.enslaved_to, "Разум слуги держит удалённого хозяина")

/// Привязанный к охлаждающему экстракту моб обязан выпасть из allies при удалении.
/datum/unit_test/chilling_extract_releases_ally/Run()
	var/obj/item/slimecross/chilling/bluespace/extract = allocate(/obj/item/slimecross/chilling/bluespace)
	var/mob/living/carbon/monkey/ally = allocate(/mob/living/carbon/monkey)
	TEST_ASSERT(extract.toggle_ally(ally), "toggle_ally() не привязал моба")
	qdel(ally)
	TEST_ASSERT_EQUAL(length(extract.allies), 0, "Экстракт держит удалённого моба в allies")

/// Разрыв дружбы обязан убрать бывшего друга и из speech_buffer слайма.
/datum/unit_test/slime_speech_buffer_follows_friendship/Run()
	var/mob/living/simple_animal/slime/slime = allocate(/mob/living/simple_animal/slime)
	var/mob/living/carbon/human/friend = allocate(/mob/living/carbon/human)
	slime.add_friend(friend)
	slime.speech_buffer = list(friend, "slime follow")
	slime.clear_friend(friend)
	TEST_ASSERT_EQUAL(length(slime.speech_buffer), 0, "speech_buffer держит моба, за которым слайм больше не следит")

/// getpois(sorted = FALSE) обязан вернуть тех же мобов, что и сортированный вариант.
/datum/unit_test/getpois_unsorted_same_set/Run()
	allocate(/mob/living/carbon/human)
	allocate(/mob/living/carbon/monkey)
	var/list/sorted_pois = getpois(mobs_only = TRUE)
	var/list/unsorted_pois = getpois(mobs_only = TRUE, sorted = FALSE)
	var/list/sorted_mobs = list()
	for(var/poi_name in sorted_pois)
		sorted_mobs |= sorted_pois[poi_name]
	var/list/unsorted_mobs = list()
	for(var/poi_name in unsorted_pois)
		unsorted_mobs |= unsorted_pois[poi_name]
	TEST_ASSERT_EQUAL(length(unsorted_mobs), length(sorted_mobs), "Несортированный getpois() потерял или добавил мобов")
	for(var/mob/listed as anything in sorted_mobs)
		TEST_ASSERT(listed in unsorted_mobs, "[listed] пропал из несортированного getpois()")
