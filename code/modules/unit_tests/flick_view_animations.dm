/// Анимация подбора показывается через vis_contents турфа, а не картинкой каждому клиенту.
/datum/unit_test/pickup_animation_uses_turf_visual

/datum/unit_test/pickup_animation_uses_turf_visual/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/obj/item/toy/crayon/red/crayon = allocate(/obj/item/toy/crayon/red, source)
	var/mob/living/carbon/human/picker = allocate(/mob/living/carbon/human, get_step(source, NORTH))

	crayon.do_pickup_animation(picker)

	var/atom/movable/flick_visual/visual = locate() in source.vis_contents
	TEST_ASSERT_NOTNULL(visual, "анимация подбора не попала в vis_contents турфа")
	source.vis_contents -= visual
	qdel(visual)

/// Всплеск из мензурки показывается через vis_contents турфа.
/datum/unit_test/beaker_splash_uses_turf_visual

/datum/unit_test/beaker_splash_uses_turf_visual/Run()
	var/turf/open/floor/target = run_loc_floor_bottom_left
	var/mob/living/carbon/human/pourer = allocate(/mob/living/carbon/human, get_step(target, NORTH))
	pourer.a_intent_change(INTENT_HARM)
	var/obj/item/reagent_containers/glass/beaker/beaker = allocate(/obj/item/reagent_containers/glass/beaker, get_turf(pourer))
	beaker.reagents.add_reagent(/datum/reagent/water, 10)

	beaker.afterattack(target, pourer, TRUE)

	var/atom/movable/flick_visual/visual = locate() in target.vis_contents
	TEST_ASSERT_NOTNULL(visual, "всплеск не попал в vis_contents турфа")
	target.vis_contents -= visual
	qdel(visual)
