/proc/count_throwbonus_windup_timers(datum/component/throwbonus_on_windup/comp)
	. = 0
	for(var/id in SStimer.timer_id_dict)
		var/datum/timedevent/timer = SStimer.timer_id_dict[id]
		if(timer && !QDELETED(timer) && timer.callBack?.object == comp)
			.++

/datum/unit_test/fishing_throwbonus_windup_stops_at_max

/datum/unit_test/fishing_throwbonus_windup_stops_at_max/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/screwdriver/item = allocate(/obj/item/screwdriver)
	item.AddComponent(/datum/component/throwbonus_on_windup, 2, 1)
	var/datum/component/throwbonus_on_windup/comp = item.GetComponent(/datum/component/throwbonus_on_windup)
	TEST_ASSERT(holder.put_in_active_hand(item), "Предмет должен лечь в руку")
	TEST_ASSERT(comp.windup_timer, "Раскрутка должна начаться в руке")
	sleep(1 SECONDS)
	TEST_ASSERT(comp.current_bonus == 2, "Бонус должен дойти до максимума, а он [comp.current_bonus]")
	TEST_ASSERT(item.throwforce == initial(item.throwforce) + 2, "Урон броска должен вырасти на бонус")
	TEST_ASSERT(count_throwbonus_windup_timers(comp) == 0, "После максимума таймер раскрутки должен быть снят")

/datum/unit_test/fishing_throwbonus_windup_explosion

/datum/unit_test/fishing_throwbonus_windup_explosion/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/fish/lavaloop/fish = allocate(/obj/item/fish/lavaloop)
	var/datum/component/throwbonus_on_windup/comp = fish.GetComponent(/datum/component/throwbonus_on_windup)
	TEST_ASSERT(comp, "У лавалупа должен быть компонент раскрутки")
	TEST_ASSERT(holder.put_in_active_hand(fish), "Рыба должна лечь в руку")
	comp.current_bonus = comp.maximum_bonus - 1
	sleep(1 SECONDS)
	TEST_ASSERT(QDELETED(fish), "Раскрученный лавалуп должен взорваться")
	TEST_ASSERT(count_throwbonus_windup_timers(comp) == 0, "После взрыва таймер раскрутки должен быть снят")
	comp.increment()
	TEST_ASSERT(comp.windup_timer == null, "Поздний тик не должен перевзводить таймер")
