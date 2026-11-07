/// Охраняемые зоны для последнего знака, кроме брига: мостик, хранилище, загрузка ИИ
GLOBAL_LIST_INIT(brother_guarded_areas, list(
	/area/command/bridge,
	/area/ai_monitored/command/nuke_storage,
	/area/ai_monitored/turret_protected/ai_upload,
))

/datum/blood_oath/brother_sign
	name = "Знак братства"
	key = "brother_sign"
	summary = "метить отделы знаками из своей крови, последний - под носом у охраны"
	weight = 6
	capstone_type = /datum/action/cooldown/blood_bond/capstone/sign_eyes
	kit_items = list(/obj/item/clothing/mask/balaclava, /obj/item/reagent_containers/glass/bottle/iron)
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

/// Отделы, где работают братья: знаки по станции в них не в счёт
/datum/blood_oath/brother_sign/proc/own_departments()
	. = list()
	if(!team)
		return
	for(var/datum/mind/member as anything in team.members - team.departed_minds - team.severed_minds)
		. |= brother_job_departments(member.assigned_role)

/datum/blood_oath/brother_sign/proc/foreign_signed_departments()
	return signed_departments() - own_departments()

/// Строка для рисующего: засчитается ли знак и куда
/datum/blood_oath/brother_sign/proc/sign_note(obj/effect/decal/cleanable/blood/brother_sign/sign)
	var/guarded = brother_area_is(sign, GLOB.brother_guarded_areas) || brother_area_is(sign, GLOB.brother_brig_areas)
	var/guarded_text = guarded ? " Он под носом у охраны." : ""
	if(!sign.department)
		return "Здесь не отдел: для шагов клятвы этот знак не в счёт.[guarded_text]"
	if(sign.department in own_departments())
		return "Отдел «[sign.department]» - ваш: первый знак здесь годится, а для знаков по станции нужны чужие отделы.[guarded_text]"
	return "Знак в отделе «[sign.department]».[guarded_text]"

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
	desc = "Целые знаки одновременно в [BROTHER_SIGN_DEPARTMENTS] разных отделах, где никто из вас не работает. Смытый знак не считается: нарисуйте новый."

/datum/blood_oath_step/sign_spread/can_seal(mob/living/sealer)
	if(signed_count() >= BROTHER_SIGN_DEPARTMENTS)
		return TRUE
	return condition_text(sealer)

/datum/blood_oath_step/sign_spread/condition_text(mob/living/viewer, sealable)
	var/datum/blood_oath/brother_sign/sign_oath = oath
	var/list/own = sign_oath.own_departments()
	return "чужих отделов со знаками: [min(signed_count(), BROTHER_SIGN_DEPARTMENTS)] из [BROTHER_SIGN_DEPARTMENTS][length(own) ? " (свои не в счёт: [own.Join(", ")])" : ""]"

/datum/blood_oath_step/sign_spread/proc/signed_count()
	var/datum/blood_oath/brother_sign/sign_oath = oath
	return length(sign_oath.foreign_signed_departments())

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
