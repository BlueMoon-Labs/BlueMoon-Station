/// Тиковые кэши угроз и союзников AI-контроллера не держат удалённого моба
/datum/unit_test/ai_tactical_caches_release_deleted_mobs
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/proc/cache_and_delete(datum/ai_controller/controller, victim_type)
	var/mob/living/victim = new victim_type(get_step(run_loc_floor_bottom_left, EAST))
	if(ispath(victim_type, /mob/living/simple_animal/hostile))
		TEST_ASSERT(victim in controller.get_nearby_allies(), "Sanity: [victim_type] не попал в кэш союзников")
	else
		TEST_ASSERT(victim in controller.get_nearby_threats(), "Sanity: [victim_type] не попал в кэш угроз")
	qdel(victim)

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/proc/deleted_in_cache(datum/ai_controller/controller, key)
	. = 0
	for(var/atom/cached as anything in controller.blackboard[key])
		if(QDELETED(cached))
			.++

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/Run()
	var/mob/living/simple_animal/hostile/headcrab/watcher = allocate(/mob/living/simple_animal/hostile/headcrab, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = watcher.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: у хедкраба нет AI-контроллера")

	cache_and_delete(controller, /mob/living/simple_animal/hostile/headcrab)
	cache_and_delete(controller, /mob/living/carbon/monkey)
	settle()
	TEST_ASSERT_EQUAL(deleted_in_cache(controller, BB_AI_ALLY_CACHE), 0, "Кэш союзников держит удалённого моба после смены тика")
	TEST_ASSERT_EQUAL(deleted_in_cache(controller, BB_AI_THREAT_CACHE), 0, "Кэш угроз держит удалённого моба после смены тика")

/// Атом, удалённый посреди анимации превращения, не остаётся в глобальном реестре анимаций
/datum/unit_test/transformation_animation_releases_deleted_atom

/datum/unit_test/transformation_animation_releases_deleted_atom/proc/animate_and_delete()
	var/obj/item/morphing = new(run_loc_floor_bottom_left)
	morphing.transformation_animation(mutable_appearance('icons/obj/stack_objects.dmi', "sheet-metal"), time = 10 SECONDS, transform_overlay = mutable_appearance('icons/obj/stack_objects.dmi', "sheet-glass"), reset_after = FALSE, replace_icon = FALSE)
	TEST_ASSERT(GLOB.transformation_animation_objects[morphing], "Sanity: анимация не записалась в реестр")
	qdel(morphing)

/datum/unit_test/transformation_animation_releases_deleted_atom/Run()
	var/registered_before = length(GLOB.transformation_animation_objects)
	animate_and_delete()
	TEST_ASSERT_EQUAL(length(GLOB.transformation_animation_objects), registered_before, "Удалённый атом остался в GLOB.transformation_animation_objects")

/mob/living/simple_animal/bot/cleanbot/hud_build_counter
	var/hud_builds = 0

/mob/living/simple_animal/bot/cleanbot/hud_build_counter/prepare_huds()
	hud_builds++
	return ..()

/// Значки худа бота строятся один раз: пересборка после добавления в диагностический худ оставляет зрителям образы с loc на бота
/datum/unit_test/bot_hud_images_built_once/Run()
	var/mob/living/simple_animal/bot/cleanbot/hud_build_counter/bot = allocate(/mob/living/simple_animal/bot/cleanbot/hud_build_counter, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(bot.hud_builds, 1, "Значки худа бота пересобраны после регистрации в диагностическом худе")
