#define MIXER_GATHER_TIME (10 MINUTES)
#define MIXER_QUORUM_SHARE 0.4
#define MIXER_MIN_QUORUM 3
#define MIXER_MAX_QUORUM 5
#define MIXER_BUDGET_BONUS 300
#define MIXER_DRINK_TIP 25
#define MIXER_DRINK_TIP_GUESTS 6
#define MIXER_HATS 6
#define MIXER_POPPERS 4

/datum/round_event_control/station_incident/service/corporate_mixer
	name = "Corporate Mixer"
	typepath = /datum/round_event/station_incident/service/corporate_mixer
	family = "corporate_mixer"
	min_players = 6
	area_groups = list(list(/area/service/bar))
	announcement_title = "Отдел корпоративной культуры NanoTrasen"

/datum/round_event_control/station_incident/service/corporate_mixer/New()
	. = ..()
	description = "ЦК объявляет корпоратив в баре и присылает капсулой колпаки, хлопушки и баннер. Через [DisplayTimeText(MIXER_GATHER_TIME)] отдел пересчитывает гостей: засчитываются сотрудники в баре в праздничном колпаке, с хлопушкой или с напитком в руке. Если таких наберётся [MIXER_MAX_QUORUM] (на малом онлайне от [MIXER_MIN_QUORUM]), звучит тост, гости получают хорошее настроение, бюджет сервиса - [MIXER_BUDGET_BONUS] кредитов, бармен - по [MIXER_DRINK_TIP] кредитов за каждого гостя с напитком (не больше чем за [MIXER_DRINK_TIP_GUESTS])."

/datum/round_event/station_incident/service/corporate_mixer
	var/quorum = MIXER_MAX_QUORUM
	var/attendance = 0
	var/drinkers = 0
	var/bartender_tip = 0
	var/bartender_name
	var/resolved = FALSE
	var/success = FALSE
	var/ends_at = 0
	var/gather_timer
	var/datum/weakref/banner_ref

/datum/round_event/station_incident/service/corporate_mixer/start()
	quorum = required_attendance(minor_service_effective_crew())
	ends_at = world.time + MIXER_GATHER_TIME
	. = ..()
	if(affected_count)
		gather_timer = addtimer(CALLBACK(src, PROC_REF(evaluate)), max(ends_at - world.time, 0), TIMER_STOPPABLE)

/datum/round_event/station_incident/service/corporate_mixer/announce(fake)
	if(!affected_count)
		return
	priority_announce("В честь квартального отчёта ЦК объявляет корпоратив. Капсула с колпаками, хлопушками и баннером уже летит в бар. Через [DisplayTimeText(MIXER_GATHER_TIME)] отдел пересчитает гостей: засчитываются сотрудники в баре в праздничном колпаке, с хлопушкой или с напитком в руке. Если таких наберётся не меньше [quorum], бюджет сервиса получит премию, а бармен - по [MIXER_DRINK_TIP] кредитов за каждого гостя с напитком. Отсек: [incident_area_name].", announcement_title())

/datum/round_event/station_incident/service/corporate_mixer/proc/required_attendance(effective_crew)
	return clamp(round(effective_crew * MIXER_QUORUM_SHARE), MIXER_MIN_QUORUM, MIXER_MAX_QUORUM)

/datum/round_event/station_incident/service/corporate_mixer/pack_shipment(obj/structure/closet/supplypod/pod)
	var/obj/structure/minor_mixer_banner/banner = new(pod)
	banner.party_ends_at = ends_at
	banner.party_quorum = quorum
	banner_ref = WEAKREF(banner)
	for(var/i in 1 to MIXER_POPPERS)
		new /obj/item/minor_party_popper(pod)
	for(var/i in 1 to MIXER_HATS)
		new /obj/item/clothing/head/festive(pod)

/datum/round_event/station_incident/service/corporate_mixer/proc/in_party_area(atom/movable/thing)
	return istype(get_area(thing), /area/service/bar)

/datum/round_event/station_incident/service/corporate_mixer/proc/held_drink(mob/living/guest)
	for(var/obj/item/reagent_containers/food/drinks/drink in guest.held_items)
		if(drink.reagents?.total_volume)
			return drink
	return null

/// Колпак на голове, хлопушка или напиток в руке: без них гость просто зашёл в бар.
/datum/round_event/station_incident/service/corporate_mixer/proc/is_festive(mob/living/guest)
	if(held_drink(guest) || (locate(/obj/item/minor_party_popper) in guest.held_items))
		return TRUE
	if(iscarbon(guest))
		var/mob/living/carbon/carbon_guest = guest
		return istype(carbon_guest.head, /obj/item/clothing/head/festive)
	return FALSE

/datum/round_event/station_incident/service/corporate_mixer/proc/is_guest(mob/living/guest)
	return is_effective_crew_mob(guest) && in_party_area(guest) && is_festive(guest)

/datum/round_event/station_incident/service/corporate_mixer/proc/gather_guests()
	var/list/guests = list()
	for(var/mob/living/guest in GLOB.player_list)
		if(guest.client && is_guest(guest))
			guests += guest
	return guests

/// Бармен в баре, иначе любой живой бармен смены.
/datum/round_event/station_incident/service/corporate_mixer/proc/find_bartender()
	var/mob/living/fallback
	for(var/datum/mind/crew_mind as anything in SSticker.minds)
		var/mob/living/candidate = crew_mind.current
		if(crew_mind.assigned_role != "Bartender" || !isliving(candidate) || !is_effective_crew_mob(candidate))
			continue
		if(in_party_area(candidate))
			return candidate
		if(!fallback)
			fallback = candidate
	return fallback

/datum/round_event/station_incident/service/corporate_mixer/proc/pay_bartender(drink_guests)
	var/paid_guests = min(drink_guests, MIXER_DRINK_TIP_GUESTS)
	if(!paid_guests)
		return 0
	var/mob/living/bartender = find_bartender()
	var/datum/bank_account/account = minor_service_account_of(bartender)
	if(!account)
		return 0
	var/tip = paid_guests * MIXER_DRINK_TIP
	account.adjust_money(tip, "NanoTrasen: премия за напитки на корпоративе")
	account.bank_card_talk("Получено [tip] кр. за напитки на корпоративе.")
	bartender_name = bartender.real_name
	return tip

/// Подсчёт гостей и развязка; повторный вызов ничего не начисляет.
/datum/round_event/station_incident/service/corporate_mixer/proc/evaluate()
	gather_timer = null
	if(resolved)
		return FALSE
	resolved = TRUE
	var/list/guests = gather_guests()
	attendance = length(guests)
	var/event_name = control?.name || "Corporate Mixer"
	var/title = announcement_title()
	var/obj/structure/minor_mixer_banner/banner = banner_ref?.resolve()
	if(attendance < quorum)
		banner?.set_result("Корпоратив не состоялся: пришло [attendance] из [quorum] гостей.")
		minor_announce("На корпоратив пришло [attendance] из [quorum] запланированных гостей. Отдел корпоративной культуры переносит тимбилдинг на неопределённый срок и благодарит всех, кто заглянул. Колпаки можно оставить себе.", title)
		log_game("DIRECTOR: [event_name], отсек [incident_area_name], явка [attendance] из [quorum], тимбилдинг перенесён.")
		return FALSE
	success = TRUE
	var/list/drinking_guests = list()
	for(var/mob/living/guest as anything in guests)
		SEND_SIGNAL(guest, COMSIG_ADD_MOOD_EVENT, "minor_corporate_mixer", /datum/mood_event/minor_corporate_mixer)
		if(held_drink(guest))
			drinking_guests += guest
	drinkers = length(drinking_guests)
	minor_service_pay_budget(MIXER_BUDGET_BONUS, "NanoTrasen: премия за корпоратив")
	bartender_tip = pay_bartender(drinkers)
	celebrate(guests, drinking_guests)
	var/tip_text = bartender_tip ? " Бармен [bartender_name] получает [bartender_tip] кредитов за гостей с напитками." : ""
	banner?.set_result("Корпоратив состоялся: [attendance] гостей при плане [quorum], премия сервису [MIXER_BUDGET_BONUS] кр.[bartender_tip ? ", бармену [bartender_tip] кр." : "."]")
	minor_announce("Корпоратив состоялся: в баре [attendance] гостей при плане [quorum]. Бюджет сервиса получает премию [MIXER_BUDGET_BONUS] кредитов.[tip_text] Отдел корпоративной культуры напоминает, что завтра обычная смена.", title)
	log_game("DIRECTOR: [event_name], отсек [incident_area_name], явка [attendance] из [quorum], с напитками [drinkers], премия [MIXER_BUDGET_BONUS] кр. выдана, бармену [bartender_tip] кр.")
	return TRUE

/// Тост: гости с напитками поднимают бокалы, баннер празднует.
/datum/round_event/station_incident/service/corporate_mixer/proc/celebrate(list/guests, list/drinking_guests)
	for(var/mob/living/guest as anything in drinking_guests)
		var/obj/item/drink = held_drink(guest)
		to_chat(guest, span_notice("Вы поднимаете [drink.name] за удачный квартал."))
	var/obj/structure/minor_mixer_banner/banner = banner_ref?.resolve()
	if(!QDELETED(banner) && isturf(banner.loc) && in_party_area(banner))
		banner.celebrate(length(drinking_guests))
		return
	for(var/mob/living/guest as anything in guests)
		guest.playsound_local(get_turf(guest), 'sound/items/party_horn.ogg', 40, TRUE)

/datum/mood_event/minor_corporate_mixer
	description = "<span class='nicegreen'>Корпоратив удался!</span>\n"
	mood_change = 3
	timeout = 15 MINUTES

/obj/structure/minor_mixer_banner
	name = "corporate mixer banner"
	desc = "Растяжка «Корпоратив» на двух стойках, по краю бежит гирлянда, сбоку закреплён динамик для тоста. Отдел корпоративной культуры выдаёт её под роспись и обратно не ждёт."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/corporate_mixer.dmi'
	icon_state = "banner"
	density = FALSE
	max_integrity = 60
	resistance_flags = FLAMMABLE
	var/party_ends_at = 0
	var/party_quorum = 0
	var/result_text

/obj/structure/minor_mixer_banner/examine(mob/user)
	. = ..()
	if(result_text)
		. += span_notice(result_text)
		return
	if(world.time < party_ends_at)
		. += span_notice("До подсчёта гостей: [DisplayTimeText(party_ends_at - world.time, 60)]. Засчитываются сотрудники в баре в праздничном колпаке, с хлопушкой или с напитком в руке; премию дадут, если таких наберётся не меньше [party_quorum].")

/obj/structure/minor_mixer_banner/proc/set_result(text)
	result_text = text

/obj/structure/minor_mixer_banner/proc/celebrate(raised_glasses = 0)
	playsound(src, 'sound/items/party_horn.ogg', 50, TRUE)
	playsound(src, pick('sound/misc/clap1.ogg', 'sound/misc/clap2.ogg', 'sound/misc/clap3.ogg', 'sound/misc/clap4.ogg'), 40, TRUE)
	new /obj/effect/temp_visual/minor_confetti_burst(get_turf(src))
	var/glasses_text = raised_glasses ? " Гости с напитками поднимают бокалы: [raised_glasses]." : ""
	visible_message(span_notice("Динамик на [src] зачитывает тост за удачный квартал.[glasses_text] Гирлянда вспыхивает разом, сверху сыплется конфетти."))

/obj/item/minor_party_popper
	name = "party popper"
	desc = "Картонная хлопушка с конфетти. Дёрните за шнурок, держа её в руке. Гость с хлопушкой в руке засчитывается на корпоративе, даже если она уже пустая."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/corporate_mixer.dmi'
	icon_state = "popper"
	item_state = "flare"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/spent = FALSE

/obj/item/minor_party_popper/examine(mob/user)
	. = ..()
	if(!spent)
		. += span_notice("Используйте в руке, чтобы хлопнуть.")

/obj/item/minor_party_popper/attack_self(mob/user)
	if(spent)
		to_chat(user, span_notice("Хлопушка уже пустая."))
		return
	pop(user)

/obj/item/minor_party_popper/proc/pop(mob/user)
	if(spent)
		return FALSE
	spent = TRUE
	name = "spent party popper"
	desc = "Пустая картонная хлопушка. Шнурок оторван, изнутри торчат обрывки фольги. На корпоративе засчитывается и такая."
	icon_state = "popper_spent"
	var/turf/spot = get_turf(src)
	playsound(spot, 'sound/effects/chipbagpop.ogg', 50, TRUE)
	new /obj/effect/temp_visual/minor_confetti_burst(spot)
	new /obj/effect/decal/cleanable/confetti(spot)
	user?.visible_message(span_notice("[user] дёргает шнурок, и [src] с хлопком выстреливает облаком конфетти!"), span_notice("Вы дёргаете шнурок, и хлопушка выстреливает конфетти."))
	return TRUE

/particles/minor_confetti_burst
	width = 128
	height = 128
	count = 48
	spawning = 24
	lifespan = 16
	fade = 6
	gradient = list(0, "#f4cd69", 1, "#e85d75", 2, "#6ccff6", 3, "#9be37a", 4, "#c58cf2")
	color = generator("num", 0, 4)
	color_change = 0
	scale = list(2, 1)
	spin = generator("num", -15, 15)
	position = generator("box", list(-3, 2, 0), list(3, 6, 0))
	velocity = generator("vector", list(-3, 3, 0), list(3, 6.5, 0))
	gravity = list(0, -0.45, 0)
	friction = 0.12
	drift = generator("vector", list(-0.2, 0, 0), list(0.2, 0, 0))

/// Один залп: частицы сыплются после выстрела, новые не появляются.
/obj/effect/temp_visual/minor_confetti_burst
	icon = null
	randomdir = FALSE
	duration = 2.4 SECONDS

/obj/effect/temp_visual/minor_confetti_burst/Initialize(mapload)
	. = ..()
	particles = new /particles/minor_confetti_burst
	addtimer(CALLBACK(src, PROC_REF(stop_spawning)), 0.3 SECONDS)

/obj/effect/temp_visual/minor_confetti_burst/proc/stop_spawning()
	particles?.spawning = 0

/obj/effect/temp_visual/minor_confetti_burst/Destroy()
	particles = null
	return ..()

#undef MIXER_GATHER_TIME
#undef MIXER_QUORUM_SHARE
#undef MIXER_MIN_QUORUM
#undef MIXER_MAX_QUORUM
#undef MIXER_BUDGET_BONUS
#undef MIXER_DRINK_TIP
#undef MIXER_DRINK_TIP_GUESTS
#undef MIXER_HATS
#undef MIXER_POPPERS
