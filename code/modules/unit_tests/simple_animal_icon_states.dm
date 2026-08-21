// Ссылка на несуществующий icon_state не стоит ничего при компиляции: BYOND
// молча рисует пустоту, а моб остаётся кликабельным и осязаемым. В раунде это
// читается как "невидимый моб бегает и бьёт" - ровно так всплыл битый icon_dead
// у культистов vharmob, когда таймстоп начал поднимать трупы.
//
// Проверяем на живом инстансе, а не через initial(): половина мобов (куры,
// кролики, гремлины) собирает имена спрайтов в Initialize() из цвета тушки.

///У каждого simple animal живой спрайт и спрайт трупа обязаны существовать в его иконке
/datum/unit_test/simple_animal_icon_states
	priority = TEST_LONGER

/datum/unit_test/simple_animal_icon_states/Run()
	var/list/broken = list()
	var/checked = 0
	//гондолопод существует только внутри своего пода и без него ругается стектрейсом
	var/list/needs_arguments = typesof(/mob/living/simple_animal/pet/gondola/gondolapod)
	for(var/mob/living/simple_animal/animal_type as anything in subtypesof(/mob/living/simple_animal))
		if(animal_type in needs_arguments)
			continue
		var/mob/living/simple_animal/victim = new animal_type(run_loc_floor_bottom_left)
		if(QDELETED(victim))
			continue
		//тип, не заявивший ни одного спрайта - абстрактная база, её не спавнят
		if(!victim.icon || (!victim.icon_state && !victim.icon_living))
			qdel(victim)
			continue
		//моб, подменивший иконку на лету (зомби собирают себя get_flat_human_icon),
		//сам отвечает за свой вид, а имена стейтов из типа к ней уже не относятся
		if(victim.icon != initial(victim.icon))
			qdel(victim)
			continue
		var/list/available = icon_states(victim.icon)
		//иконка с безымянным стейтом невидимой не бывает: BYOND рисует его всегда,
		//когда запрошенного стейта в иконке нет
		if("" in available)
			qdel(victim)
			continue
		checked++
		var/list/bad = list()
		if(victim.icon_state && !(victim.icon_state in available))
			bad += "icon_state='[victim.icon_state]'"
		if(victim.icon_living && !(victim.icon_living in available))
			bad += "icon_living='[victim.icon_living]'"
		//у del_on_death-моба icon_dead - мёртвая буква: тело исчезает, а труп на
		//полу оставляет loot (обычно /obj/effect/mob_spawn/human/corpse/...)
		if(!victim.del_on_death && victim.icon_dead && !(victim.icon_dead in available))
			bad += "icon_dead='[victim.icon_dead]'"
		//сидящий спрайт живёт только у попугаев и рисуется тем же присваиванием
		//icon_state, так что опечатка в нём даёт ровно того же невидимого моба
		var/mob/living/simple_animal/parrot/bird = victim
		if(istype(bird) && bird.icon_sit && !(bird.icon_sit in available))
			bad += "icon_sit='[bird.icon_sit]'"
		if(length(bad))
			broken += "[animal_type] ([victim.icon]): [bad.Join(", ")]"
		qdel(victim)
		CHECK_TICK
	TEST_ASSERT(checked > 300, "Проверено всего [checked] simple animals - похоже, спавн отвалился")
	TEST_ASSERT(!length(broken), "Спрайты, которых нет в иконке моба:\n[broken.Join("\n")]")

///Труп обязан быть видимым: даже если icon_dead пустой или врёт, corpse_icon_state()
///подставляет живой спрайт, а не пустую строку
/datum/unit_test/simple_animal_corpse_stays_visible/Run()
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp)
	//моб без спрайта смерти и моб с враньём в icon_dead - оба должны остаться видимыми
	fish.icon_dead = ""
	TEST_ASSERT_EQUAL(fish.corpse_icon_state(), fish.icon_living, "Пустой icon_dead обязан откатываться на живой спрайт")
	fish.icon_dead = "no_such_state_anywhere"
	TEST_ASSERT_EQUAL(fish.corpse_icon_state(), fish.icon_living, "icon_dead с несуществующим стейтом обязан откатываться на живой спрайт")

	fish.icon_dead = initial(fish.icon_dead)
	fish.death()
	TEST_ASSERT_EQUAL(fish.stat, DEAD, "Sanity: карп должен умереть")
	TEST_ASSERT(fish.icon_state in icon_states(fish.icon), "После смерти icon_state обязан существовать в иконке, иначе труп невидимый")
