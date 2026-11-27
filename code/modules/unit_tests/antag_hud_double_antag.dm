/// Культист, обращённый революцией, держит оба значка: культ видит у него свой, революция - свой.
/// Раньше у моба был один антаг-худ на разум и один значок на тело, и новая роль выкидывала его из худа старой.
/datum/unit_test/antag_hud_double_antag
	var/list/datum/mind/antag_minds = list()
	var/list/datum/team/antag_teams = list()

/datum/unit_test/antag_hud_double_antag/proc/make_crew()
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	crew.mind_initialize()
	allocated += crew.mind
	antag_minds += crew.mind
	return crew

/datum/unit_test/antag_hud_double_antag/proc/make_cultist(mob/living/carbon/human/crew)
	var/datum/antagonist/cult/cultist = new
	cultist.ignore_eligibility_checks = TRUE
	crew.mind.add_antag_datum(cultist)
	antag_teams |= cultist.cult_team

/datum/unit_test/antag_hud_double_antag/proc/hud_icon(datum/atom_hud/hud, mob/target)
	return target.hud_list[hud.hud_icons[1]]

/// Значки, которые худ раздал бы зрителю при подключении
/datum/unit_test/antag_hud_double_antag/proc/shown_icons(datum/atom_hud/hud, mob/viewer)
	var/list/shown = list()
	hud.collect_hud_images_for(viewer, shown)
	return shown

/datum/unit_test/antag_hud_double_antag/Run()
	var/datum/atom_hud/antag/culthud = GLOB.huds[ANTAG_HUD_CULT]
	var/datum/atom_hud/antag/revhud = GLOB.huds[ANTAG_HUD_REV]
	var/mob/living/carbon/human/double = make_crew()
	var/mob/living/carbon/human/cult_ally = make_crew()
	var/mob/living/carbon/human/rev_leader = make_crew()
	make_cultist(double)
	make_cultist(cult_ally)
	var/datum/antagonist/rev/head/head = rev_leader.mind.add_antag_datum(/datum/antagonist/rev/head)
	TEST_ASSERT_NOTNULL(head, "Глава революции не выдан - предпосылка теста сломана")
	antag_teams |= head.rev_team
	TEST_ASSERT(head.add_revolutionary(double.mind, FALSE), "Глава не обратил культиста - предпосылка теста сломана")

	var/image/cult_icon = hud_icon(culthud, double)
	var/image/rev_icon = hud_icon(revhud, double)
	TEST_ASSERT(double in culthud.hudatoms, "Обращение в революцию сняло с культиста значок культа")
	TEST_ASSERT(culthud.hudusers[double] && revhud.hudusers[double], "Культист-революционер должен видеть и культ, и революцию")
	TEST_ASSERT(cult_icon && rev_icon && cult_icon != rev_icon, "Культ и революция делят один значок на теле")
	TEST_ASSERT_EQUAL(cult_icon.icon_state, "cult", "Значок культа перезаписан")
	TEST_ASSERT_EQUAL(rev_icon.icon_state, "rev", "Значок революции не выставлен")
	var/list/cult_view = shown_icons(culthud, cult_ally)
	TEST_ASSERT(cult_icon in cult_view, "Другой культист не видит значок культа у культиста-революционера")
	TEST_ASSERT(!(rev_icon in cult_view), "Культ видит значок революции")
	var/list/rev_view = shown_icons(revhud, rev_leader)
	TEST_ASSERT(rev_icon in rev_view, "Глава революции не видит значок революции у обращённого")
	TEST_ASSERT(!(cult_icon in rev_view), "Революция видит значок культа")
	var/image/leader_icon = hud_icon(revhud, rev_leader)
	TEST_ASSERT_EQUAL(leader_icon?.icon_state, "rev_head", "Значок главы революции")

	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	double.mind.transfer_to(new_body)
	TEST_ASSERT((new_body in culthud.hudatoms) && (new_body in revhud.hudatoms), "Перенос разума унёс не все антаг-худы")
	var/image/moved_cult_icon = hud_icon(culthud, new_body)
	var/image/moved_rev_icon = hud_icon(revhud, new_body)
	TEST_ASSERT_EQUAL(moved_cult_icon?.icon_state, "cult", "Значок культа после переноса разума")
	TEST_ASSERT_EQUAL(moved_rev_icon?.icon_state, "rev", "Значок революции после переноса разума")
	TEST_ASSERT(!(double in culthud.hudatoms) && !(double in revhud.hudatoms), "Антаг-значки остались на прежнем теле")

	new_body.mind.remove_antag_datum(/datum/antagonist/rev)
	TEST_ASSERT(!(new_body in revhud.hudatoms), "Деконверсия не сняла значок революции")
	TEST_ASSERT(new_body in culthud.hudatoms, "Деконверсия революции сняла значок культа")
	var/image/kept_cult_icon = hud_icon(culthud, new_body)
	TEST_ASSERT_EQUAL(kept_cult_icon?.icon_state, "cult", "Деконверсия революции стёрла значок культа")
	TEST_ASSERT(kept_cult_icon in shown_icons(culthud, cult_ally), "После деконверсии культ не видит своего")

/datum/unit_test/antag_hud_double_antag/Destroy()
	for(var/datum/mind/mind as anything in antag_minds)
		mind.remove_antag_datum(/datum/antagonist/rev)
		mind.remove_antag_datum(/datum/antagonist/cult)
	for(var/datum/objective/objective as anything in GLOB.objectives.Copy())
		if(objective.team && (objective.team in antag_teams))
			qdel(objective)
	for(var/datum/team/team as anything in antag_teams)
		qdel(team)
	antag_minds = null
	antag_teams = null
	return ..()
