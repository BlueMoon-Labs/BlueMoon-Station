/// Ржавчина истачивает оболочку, не задевая содержимое и не запуская разрушение компонентов.
/obj/item/proc/heretic_corrode_surface()
	if((item_flags & ABSTRACT) || (resistance_flags & (INDESTRUCTIBLE | ACID_PROOF)))
		return 0
	var/safe_integrity = max(1, max_integrity * max(0.25, integrity_failure) + DAMAGE_PRECISION)
	var/wear = clamp(obj_integrity - safe_integrity, 0, 15)
	obj_integrity -= wear
	return wear

/// Завеса сначала предупреждает; повторное прикосновение в течение полуминуты ранит.
/obj/effect/broken_illusion/proc/touch_mansus(mob/living/user, telekinetic = FALSE)
	if(QDELETED(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user) || user.check_magic_resistance())
		return FALSE
	if(user.has_status_effect(/datum/status_effect/heretic_rift_exposure))
		user.adjustBruteLoss(20)
		user.adjustStaminaLoss(30)
		user.Knockdown(1 SECONDS)
		user.visible_message(span_danger("[user] отшатывается от разрыва. По коже проступают тонкие порезы!"), span_userdanger("Завеса узнала вас. Чужие пальцы тянут изнутри — кожа лопается!"))
		playsound(src, 'sound/effects/wounds/crackandbleed.ogg', 45, TRUE)
		return TRUE
	user.apply_status_effect(/datum/status_effect/heretic_rift_exposure)
	user.adjustStaminaLoss(15)
	var/warning = telekinetic ? "По мысленной нити к вам тянется чужая рука. Оборвите связь! Ещё одно прикосновение ранит вас." : "За разрывом кто-то обхватил ваши пальцы. Отдёрните руку! Ещё одно прикосновение ранит вас."
	to_chat(user, span_userdanger(warning))
	return TRUE

/datum/status_effect/heretic_rift_exposure
	id = "heretic_rift_exposure"
	duration = 30 SECONDS
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/heretic_rift_exposure

/datum/status_effect/heretic_rift_exposure/on_apply()
	. = ..()
	owner.playsound_local(get_turf(owner), 'sound/hallucinations/behind_you1.ogg', 45, FALSE, pressure_affected = FALSE)
	return TRUE

/atom/movable/screen/alert/status_effect/heretic_rift_exposure
	name = "Завеса помнит"
	desc = "Вы потревожили разрыв. В течение 30 секунд новое прикосновение рукой или телекинезом нанесёт раны."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "rift_exposure"

/// Один эффект экрана переживает пересечение нескольких доменов и исчезает с последним.
/datum/status_effect/heretic_domain
	id = "heretic_domain"
	duration = -1
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/heretic_domain
	var/list/domains = list()

/datum/status_effect/heretic_domain/on_apply()
	. = ..()
	owner.add_client_colour(/datum/client_colour/heretic_domain)
	owner.playsound_local(get_turf(owner), 'sound/hallucinations/veryfar_noise.ogg', 35, FALSE, pressure_affected = FALSE)
	to_chat(owner, span_userdanger("Мир побледнел. Холод держит ваши ноги, а голос остаётся в горле. Выйдите за границу печати!"))
	return TRUE

/datum/status_effect/heretic_domain/proc/remove_domain(obj/effect/domain_expansion/domain)
	domains -= domain
	if(!length(domains))
		qdel(src)

/datum/status_effect/heretic_domain/on_remove()
	owner.remove_client_colour(/datum/client_colour/heretic_domain)
	domains.Cut()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_domain
	name = "Домен Пустоты"
	desc = "Холод замедляет вас и отнимает голос. Покиньте белую границу печати."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_void"

/datum/client_colour/heretic_domain
	priority = 4
	colour = list(0.55, 0, 0, 0, 0, 0.6, 0, 0, 0, 0, 0.65, 0, 0, 0, 0, 1, 0.15, 0.18, 0.2, 0)
