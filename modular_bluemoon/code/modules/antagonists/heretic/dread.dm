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

/obj/effect/broken_illusion/proc/neutralize(mob/living/user, obj/item/anomaly_neutralizer/neutralizer)
	if(!isliving(user) || neutralizing)
		return FALSE
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		to_chat(user, span_warning("Завеса не станет запирать саму себя."))
		return FALSE
	neutralizing = TRUE
	user.visible_message(span_warning("[user] подносит [neutralizer] к разрыву в воздухе."), span_notice("Вы начинаете стягивать края разрыва..."))
	var/completed = do_after(user, 5 SECONDS, src)
	neutralizing = FALSE
	if(!completed || QDELETED(src) || QDELETED(neutralizer) || !user.is_holding(neutralizer))
		return FALSE
	return finish_neutralize(user, neutralizer)

/obj/effect/broken_illusion/proc/finish_neutralize(mob/living/user, obj/item/anomaly_neutralizer/neutralizer)
	touch_mansus(user)
	qdel(neutralizer)
	if(fake)
		user.visible_message(span_notice("Разрыв гаснет, не оставив ничего."), span_notice("Устройство сгорает впустую: за этим разрывом ничего не было."))
		log_game("[key_name(user)] нейтрализует ложный след разлома в [AREACOORD(src)].")
	else
		new /obj/item/heretic_veil_crystal(get_turf(src))
		user.visible_message(span_notice("Разрыв схлопывается в кристалл."), span_notice("Устройство сгорает, и разрыв схлопывается в кристалл."))
		log_game("[key_name(user)] нейтрализует след разлома в [AREACOORD(src)], выпадает кристалл завесы.")
	playsound(src, 'sound/effects/phasein.ogg', 40, TRUE)
	qdel(src)
	return TRUE

/obj/item/heretic_veil_crystal
	name = "veil crystal"
	desc = "Друза тёмных кристаллов в бронзовом когте, в которую схлопнулся разрыв реальности. Изнутри время от времени открывается золотой зрачок. Учёным она интересна как образец."
	icon = 'modular_bluemoon/icons/obj/heretic_veil_crystal.dmi'
	icon_state = "veil_crystal"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/heretic_veil_crystal/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user))
		. += span_notice("Раздавите его в руке, и сила завесы на время затянет раны и вернёт дыхание.")

/obj/item/heretic_veil_crystal/attack_self(mob/living/user)
	if(!IS_HERETIC(user))
		to_chat(user, span_notice("Кристалл холодный и молчит."))
		return
	if(user.has_status_effect(/datum/status_effect/heretic_veil_crystal))
		to_chat(user, span_warning("Сила прошлого кристалла ещё не ушла."))
		return
	user.apply_status_effect(/datum/status_effect/heretic_veil_crystal)
	user.visible_message(span_warning("[user] сжимает кристалл, и тот рассыпается чёрной пылью."), span_notice("Кристалл рассыпается, и завеса течёт в ваши раны."))
	playsound(user, 'sound/effects/glassbr1.ogg', 40, TRUE)
	log_game("[key_name(user)] использует кристалл завесы в [AREACOORD(user)].")
	qdel(src)

/datum/status_effect/heretic_veil_crystal
	id = "heretic_veil_crystal"
	duration = 20 SECONDS
	tick_interval = 2 SECONDS
	alert_type = null

/datum/status_effect/heretic_veil_crystal/tick()
	heretic_heal_pool(owner, 4)
	owner.adjustStaminaLoss(-10)

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
	icon_state = "void_domain"

/datum/client_colour/heretic_domain
	priority = 4
	colour = list(0.55, 0, 0, 0, 0, 0.6, 0, 0, 0, 0, 0.65, 0, 0, 0, 0, 1, 0.15, 0.18, 0.2, 0)
