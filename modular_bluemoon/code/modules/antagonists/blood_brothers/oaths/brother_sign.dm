/// Охраняемые зоны для последнего знака, кроме брига: мостик, хранилище, загрузка ИИ
GLOBAL_LIST_INIT(brother_guarded_areas, list(
	/area/command/bridge,
	/area/ai_monitored/command/nuke_storage,
	/area/ai_monitored/turret_protected/ai_upload,
))

/datum/blood_oath/brother_sign
	name = "Знак братства"
	key = "brother_sign"
	weight = 6
	capstone_type = /datum/action/cooldown/blood_bond/capstone/sign_eyes
	extra_actions = list(/datum/action/cooldown/blood_bond/brother_sign)
	story = "Пусть станция знает, что вы здесь были. Метьте её своей кровью: отдел за отделом, до самого мостика."

/datum/blood_oath/brother_sign/prepare(datum/team/brother_team/for_team)
	. = ..()
	add_step(new /datum/blood_oath_step/sign_department)
	add_step(new /datum/blood_oath_step/sign_spread)
	add_step(new /datum/blood_oath_step/sign_guarded)
	return TRUE

/// Отделы, где сейчас лежат целые знаки команды
/datum/blood_oath/brother_sign/proc/signed_departments()
	. = list()
	for(var/obj/effect/decal/cleanable/blood/brother_sign/sign as anything in team?.signs)
		if(sign.department && isturf(sign.loc))
			. |= sign.department

/datum/blood_oath_step/sign_department
	name = "Первый знак"
	desc = "Нарисуйте кнопкой «Знак братства» знак в любом отделе: в науке, медицине, инженерии, снабжении, СБ, командовании или в служебных помещениях сервиса. Лобби, холлы и коридоры не в счёт."

/datum/blood_oath_step/sign_department/can_seal(mob/living/sealer)
	var/datum/blood_oath/brother_sign/sign_oath = oath
	if(length(sign_oath.signed_departments()))
		return TRUE
	return "ни одного целого знака в отделах"

/datum/blood_oath_step/sign_department/condition_text(mob/living/viewer, sealable)
	return "знак в отделе: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/sign_spread
	name = "Знаки по станции"

/datum/blood_oath_step/sign_spread/describe()
	desc = "Целые знаки одновременно в [BROTHER_SIGN_DEPARTMENTS] разных отделах. Смытый знак не считается: нарисуйте новый."

/datum/blood_oath_step/sign_spread/can_seal(mob/living/sealer)
	if(signed_count() >= BROTHER_SIGN_DEPARTMENTS)
		return TRUE
	return condition_text(sealer)

/datum/blood_oath_step/sign_spread/condition_text(mob/living/viewer, sealable)
	return "отделов со знаками: [min(signed_count(), BROTHER_SIGN_DEPARTMENTS)] из [BROTHER_SIGN_DEPARTMENTS]"

/datum/blood_oath_step/sign_spread/proc/signed_count()
	var/datum/blood_oath/brother_sign/sign_oath = oath
	return length(sign_oath.signed_departments())

/datum/blood_oath_step/sign_guarded
	name = "Под носом у охраны"
	desc = "Целый знак на мостике, в бриге или перме, в хранилище или в загрузке ИИ."

/datum/blood_oath_step/sign_guarded/can_seal(mob/living/sealer)
	for(var/obj/effect/decal/cleanable/blood/brother_sign/sign as anything in oath.team?.signs)
		if(isturf(sign.loc) && (brother_area_is(sign, GLOB.brother_guarded_areas) || brother_area_is(sign, GLOB.brother_brig_areas)))
			return TRUE
	return "нет целого знака в охраняемой зоне"

/datum/blood_oath_step/sign_guarded/condition_text(mob/living/viewer, sealable)
	return "знак в охраняемой зоне: [sealable_now(viewer, sealable) ? "да" : "нет"]"
