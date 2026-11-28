/datum/unit_test/proc/heretic_tails_last_round(datum/eldritch_knowledge/base_lead/lead, mob/living/target)
	var/mob/living/carbon/human/user = lead.lead_body
	var/obj/item/projectile/bullet/heretic_lead/last_round/bullet = new(get_turf(user))
	bullet.firer = user
	bullet.lead_ref = WEAKREF(lead)
	bullet.preparePixelProjectile(target, user)
	bullet.fire()
	heretic_lead_test_fly(bullet, 2)

/// Последний патрон за попадание Свинец не возвращает, а убитый им человек отдаёт те же три, что и обычная пуля.
/datum/unit_test/heretic_lead_last_round_kill_refund/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/survivor = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	lead.combat_resource = 0
	heretic_tails_last_round(lead, survivor)
	TEST_ASSERT(survivor.stat != DEAD && survivor.getBruteLoss() > 0, "Последний патрон попал и не убил: [survivor.getBruteLoss()].")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Попадание Последнего патрона без убийства Свинец не возвращает.")
	survivor.forceMove(heretic_lead_test_spot(2, 0))
	var/mob/living/carbon/human/doomed = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	doomed.setOxyLoss(170)
	TEST_ASSERT(doomed.stat != DEAD, "Цель ещё жива.")
	heretic_tails_last_round(lead, doomed)
	TEST_ASSERT(doomed.stat == DEAD, "Последний патрон добил цель: здоровье [doomed.health].")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_KILL_LEAD, "Убийство Последним патроном возвращает [HERETIC_LEAD_KILL_LEAD] Свинца.")
	heretic_tails_last_round(lead, doomed)
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_KILL_LEAD, "Выстрел в труп Свинец не возвращает.")

/// Серия Пера растёт и по живой цели, у которой все части тела изрублены до предела и урон больше не растёт.
/datum/unit_test/heretic_dusk_combo_maxed_body/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	ADD_TRAIT(victim, TRAIT_NODEATH, TRAIT_GENERIC)
	for(var/obj/item/bodypart/part as anything in victim.bodyparts)
		part.receive_damage(part.max_damage)
	victim.updatehealth()
	TEST_ASSERT(victim.stat != DEAD, "Изрубленная цель жива.")
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	dusk_light_all(1)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_FACE, "Серия идёт в Лике.")
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(dusk.combo_hits, 1, "Удар по изрубленной цели засчитан в серию.")
	blade.attack(victim, user)
	blade.attack(victim, user)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dusk_lit), "Третий удар по изрубленной цели - световой разрез.")
	REMOVE_TRAIT(victim, TRAIT_NODEATH, TRAIT_GENERIC)
	victim.death()
	var/hits = dusk.combo_hits
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(dusk.combo_hits, hits, "Удар по трупу серию не растит.")

/// Кнопка «Смена облика» показывает нынешний облик.
/datum/unit_test/heretic_dusk_form_button_icon/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(2, 2)
	var/obj/effect/proc_holder/spell/self/heretic_dusk/form/power = dusk.combat_power
	TEST_ASSERT(istype(power) && power.action, "У Сумрака есть кнопка смены облика.")
	TEST_ASSERT_EQUAL(dusk.form, HERETIC_DUSK_FORM_FACE, "Сумрак начинает в Лике.")
	TEST_ASSERT_EQUAL(power.action.button_icon_state, "dusk_cov_seraph", "В Лике на кнопке нимб.")
	dusk.set_form(HERETIC_DUSK_FORM_WING)
	TEST_ASSERT_EQUAL(power.action.button_icon_state, "dusk_cov_fallen", "В Крыле на кнопке крылья.")
	dusk.set_form(HERETIC_DUSK_FORM_FACE)
	TEST_ASSERT_EQUAL(power.action.button_icon_state, "dusk_cov_seraph", "Обратно в Лик - снова нимб.")
	for(var/state in list("dusk_cov_seraph", "dusk_cov_fallen"))
		TEST_ASSERT(state in icon_states(power.action.icon_icon), "Значок [state] есть в листе кнопки.")
