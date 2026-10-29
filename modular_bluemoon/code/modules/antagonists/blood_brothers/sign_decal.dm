/datum/team/brother_team
	/// Целые знаки братства команды
	var/list/obj/effect/decal/cleanable/blood/brother_sign/signs = list()

/// Знак братства: серый рисунок, цвет и смешение даёт кровь рисовавшего
/obj/effect/decal/cleanable/blood/brother_sign
	name = "blood sign"
	desc = "Две ладони, прижатые друг к другу, нарисованные кровью. Вывели старательно, это не случайный мазок."
	icon = 'modular_bluemoon/icons/effects/blood_brothers.dmi'
	icon_state = "brother_sign_1"
	random_icon_states = null
	persistent = FALSE
	mergeable_decal = FALSE
	cap_exempt = TRUE
	var/datum/team/brother_team/team
	/// Отдел зоны, где нарисован знак, или null
	var/department

/obj/effect/decal/cleanable/blood/brother_sign/Destroy()
	unbind_team()
	return ..()

/// Чужой знак на той же клетке не заменяет этот
/obj/effect/decal/cleanable/blood/brother_sign/replace_decal(obj/effect/decal/cleanable/other)
	return FALSE

/obj/effect/decal/cleanable/blood/brother_sign/proc/bind_team(datum/team/brother_team/new_team)
	unbind_team()
	if(QDELETED(new_team))
		return
	team = new_team
	team.signs += src
	department = brother_area_department(get_area(src))
	RegisterSignal(team, COMSIG_PARENT_QDELETING, PROC_REF(on_team_deleted))

/obj/effect/decal/cleanable/blood/brother_sign/proc/unbind_team()
	if(!team)
		return
	UnregisterSignal(team, COMSIG_PARENT_QDELETING)
	team.signs -= src
	team = null

/obj/effect/decal/cleanable/blood/brother_sign/proc/on_team_deleted(datum/source)
	SIGNAL_HANDLER
	unbind_team()

/// Набросок знака на время рисования; кончается ровно на кадре готового знака
/obj/effect/temp_visual/brother_sign_draw
	icon = 'modular_bluemoon/icons/effects/blood_brothers.dmi'
	icon_state = "brother_sign_draw"
	plane = FLOOR_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	blend_mode = BLEND_MULTIPLY
	color = BLOOD_COLOR_HUMAN
	randomdir = FALSE
	duration = BROTHER_SIGN_DRAW_TIME * 2

/obj/effect/temp_visual/brother_sign_draw/Initialize(mapload, mob/living/drawer, angle = 0)
	. = ..()
	var/list/blood_dna = drawer?.get_blood_dna_list()
	if(blood_dna && blood_dna["color"])
		color = blood_dna["color"]
		blend_mode = isnull(blood_dna["blendmode"]) ? BLEND_MULTIPLY : blood_dna["blendmode"]
	transform = brother_sign_rotation(angle)

/proc/brother_sign_rotation(angle)
	var/matrix/rotation = matrix()
	rotation.Turn(angle)
	return rotation
