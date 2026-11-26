#define LEAD_DRUM_ICON 'modular_bluemoon/icons/obj/heretic_lead_drum.dmi'
#define LEAD_DRUM_RING 5
#define LEAD_RING_TRACE (0.5 SECONDS)
#define LEAD_FOCUS_TRACE (0.1 SECONDS)
#define LEAD_BELT_TEXT_HEIGHT 10

/// Барабан Шестизарядника: Свинец заряжает каморы подряд от курка, род пули задаёт сама камора.
/datum/eldritch_knowledge/base_lead
	/// Камора кольца под курком, 1-5; Шестая камора - сам полный барабан.
	var/drum_hammer = 1
	/// Шестую камору взвёл сам игрок: держится до Последнего патрона или выбора другой каморы.
	var/sixth_armed = FALSE
	/// Пуля под курком выпала на прокрутке.
	var/drum_lucky = FALSE
	var/drum_style = HERETIC_LEAD_STYLE_PLAIN
	var/list/drum_overlays

/datum/eldritch_knowledge/base_lead/proc/lead_ascended()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = lead_finale()
	return finale?.finished

/// Род пули каморы; камора, ещё не открытая прокачкой, бьёт простой Свинцовой пулей.
/datum/eldritch_knowledge/base_lead/proc/chamber_round(position)
	var/static/list/unlocks = list(
		null,
		/datum/eldritch_knowledge/lead_relic,
		/datum/eldritch_knowledge/lead_mark,
		/datum/eldritch_knowledge/spell/lead_catch,
		/datum/eldritch_knowledge/spell/lead_ricochet,
		/datum/eldritch_knowledge/lead_ear,
	)
	var/static/list/rounds = list(
		/obj/item/projectile/bullet/heretic_lead,
		/obj/item/projectile/bullet/heretic_lead/heavy,
		/obj/item/projectile/bullet/heretic_lead/marked,
		/obj/item/projectile/bullet/heretic_lead/powder,
		/obj/item/projectile/bullet/heretic_lead/ringing,
		/obj/item/projectile/bullet/heretic_lead/last_round,
	)
	if(position == 1)
		return lead_ascended() ? /obj/item/projectile/bullet/heretic_lead/piercing : /obj/item/projectile/bullet/heretic_lead
	if(position < 1 || position > HERETIC_LEAD_CAPACITY || !knows(unlocks[position]))
		return /obj/item/projectile/bullet/heretic_lead
	return rounds[position]

/datum/eldritch_knowledge/base_lead/proc/open_chambers()
	. = list(1)
	for(var/position in 2 to LEAD_DRUM_RING)
		if(chamber_round(position) != /obj/item/projectile/bullet/heretic_lead)
			. += position

/// Шестая камора под курком: следующий выстрел в человека уйдёт Последним патроном.
/datum/eldritch_knowledge/base_lead/proc/sixth_cocked()
	return sixth_armed && last_round_ready()

/datum/eldritch_knowledge/base_lead/proc/chamber_charged(position)
	if(position > LEAD_DRUM_RING)
		return free_last_round || combat_resource >= combat_resource_max
	return (position - drum_hammer + LEAD_DRUM_RING) % LEAD_DRUM_RING < min(combat_resource, LEAD_DRUM_RING)

/datum/eldritch_knowledge/base_lead/proc/sacrifice_penetration()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	return min((heretic?.total_sacrifices || 0) * HERETIC_LEAD_SACRIFICE_PENETRATION, HERETIC_LEAD_SACRIFICE_PENETRATION_CAP)

/datum/eldritch_knowledge/base_lead/proc/advance_drum()
	drum_hammer = drum_hammer % LEAD_DRUM_RING + 1
	drum_lucky = FALSE
	update_drum_hud()

/// Выбор каморы: открытая камора кольца или Шестая, если барабан полон.
/datum/eldritch_knowledge/base_lead/proc/turn_drum(position)
	if(position == HERETIC_LEAD_CAPACITY)
		if(!last_round_ready())
			return FALSE
		sixth_armed = TRUE
	else if(position in open_chambers())
		drum_hammer = position
		sixth_armed = FALSE
	else
		return FALSE
	drum_lucky = FALSE
	update_drum_hud()
	return TRUE

/// Прокрутка: под курок встаёт случайная открытая камора, и её пуля бьёт сильнее.
/datum/eldritch_knowledge/base_lead/proc/spin_drum()
	var/list/choices = open_chambers()
	if(length(choices) > 1)
		choices -= drum_hammer
	drum_hammer = pick(choices)
	drum_lucky = TRUE
	sixth_armed = FALSE
	update_drum_hud()
	return drum_hammer

/datum/eldritch_knowledge/base_lead/proc/round_name(position)
	var/obj/item/projectile/bullet/heretic_lead/round_type = chamber_round(position)
	return initial(round_type.round_name)

/datum/eldritch_knowledge/base_lead/proc/style_name(style = drum_style)
	switch(style)
		if(HERETIC_LEAD_STYLE_AIMED)
			return "прицельный выстрел"
		if(HERETIC_LEAD_STYLE_FAN)
			return "веер"
	return "обычный выстрел"

/datum/eldritch_knowledge/base_lead/proc/drum_state()
	if(!knows(/datum/eldritch_knowledge/lead_relic))
		return ""
	var/list/charged = list()
	for(var/step in 0 to min(combat_resource, LEAD_DRUM_RING) - 1)
		charged += round_name((drum_hammer - 1 + step) % LEAD_DRUM_RING + 1)
	var/next = sixth_cocked() ? "Последний патрон" : round_name(drum_hammer)
	. = " Под курком: [next][drum_lucky ? ", на удачу" : ""]. Заряжены: [length(charged) ? jointext(charged, ", ") : "ничего"]. Стиль: [style_name()]."
	if(sixth_armed && !sixth_cocked())
		. += " Шестая камора взведена и ждёт полного барабана."
	else if(!sixth_armed && free_last_round && knows(/datum/eldritch_knowledge/lead_ear))
		. += " Шестая камора - подарок барабана: Alt-клик по Шестизаряднику взводит её, Свинец не тратится."
	else if(!sixth_armed && last_round_ready())
		. += " Барабан полон: Alt-клик по Шестизаряднику взводит Шестую камору."

/// Барабан поверх значка запаса: заряженные каморы своим цветом, метка у каморы под курком.
/datum/eldritch_knowledge/base_lead/proc/update_drum_hud()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	if(!heretic || QDELETED(lead_body))
		return null
	var/atom/movable/screen/alert/heretic_resource/indicator = heretic.update_combat_resource_alert(FALSE)
	if(!indicator)
		return null
	if(length(drum_overlays))
		indicator.cut_overlay(drum_overlays)
	drum_overlays = drum_appearances()
	indicator.add_overlay(drum_overlays)
	return indicator

/datum/eldritch_knowledge/base_lead/proc/drum_appearances()
	. = list(mutable_appearance(LEAD_DRUM_ICON, "drum"))
	for(var/position in 1 to HERETIC_LEAD_CAPACITY)
		if(!chamber_charged(position))
			continue
		var/obj/item/projectile/bullet/heretic_lead/round_type = chamber_round(position)
		if(round_type == /obj/item/projectile/bullet/heretic_lead/last_round)
			. += mutable_appearance(LEAD_DRUM_ICON, "round6_last")
			continue
		var/mutable_appearance/chamber = mutable_appearance(LEAD_DRUM_ICON, "round[position]")
		chamber.color = initial(round_type.color)
		. += chamber
	. += mutable_appearance(LEAD_DRUM_ICON, "next[sixth_cocked() ? HERETIC_LEAD_CAPACITY : drum_hammer]")
	if(drum_lucky)
		. += mutable_appearance(LEAD_DRUM_ICON, "luck")
	if(drum_style == HERETIC_LEAD_STYLE_AIMED)
		. += mutable_appearance(LEAD_DRUM_ICON, "aim")
	else if(drum_style == HERETIC_LEAD_STYLE_FAN)
		. += mutable_appearance(LEAD_DRUM_ICON, "fan")
	if(bandolier || reload_timer)
		var/mutable_appearance/belt = new
		belt.maptext_width = world.icon_size
		belt.maptext_height = LEAD_BELT_TEXT_HEIGHT
		belt.maptext_y = world.icon_size - LEAD_BELT_TEXT_HEIGHT
		belt.maptext = MAPTEXT("<div style='text-align:right;color:[reload_timer ? "#ffb35c" : "#e8c66a"];font-size:7px'>+[bandolier]</div>")
		. += belt

/// Новое знание открывает камору: барабан на значке перекрашивается сразу.
/proc/heretic_lead_refresh_drum(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	return lead?.update_drum_hud()

/datum/eldritch_knowledge/lead_mark/on_gain(mob/user)
	. = ..()
	heretic_lead_refresh_drum(user)
	if(user && !QDELETED(choice_power))
		to_chat(user, span_eldritch("Кнопка «Школа стрельбы» ждёт выбора: Стрелок, Охотник или Канонир. Выбор необратим до сброса пути."))

/datum/eldritch_knowledge/lead_relic/on_gain(mob/user)
	. = ..()
	heretic_lead_refresh_drum(user)

/datum/eldritch_knowledge/spell/lead_catch/on_gain(mob/user)
	. = ..()
	heretic_lead_refresh_drum(user)

/datum/eldritch_knowledge/spell/lead_ricochet/on_gain(mob/user)
	. = ..()
	heretic_lead_refresh_drum(user)

/datum/eldritch_knowledge/lead_ear/on_gain(mob/user)
	. = ..()
	heretic_lead_refresh_drum(user)

/obj/item/heretic_path_relic/lead_revolver
	var/focus_timer
	var/datum/weakref/focus_ref
	var/turf/focus_from
	var/datum/beam/focus_beam
	var/fan_timer
	var/fan_left = 0
	/// Пули веера сверх заряженных камор: не тратят Свинец.
	var/fan_free = 0
	COOLDOWN_DECLARE(drum_turn)
	COOLDOWN_DECLARE(drum_spin)
	COOLDOWN_DECLARE(fan_lockout)

/obj/item/heretic_path_relic/lead_revolver/proc/owner_lead(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)

/obj/item/heretic_path_relic/lead_revolver/proc/drum_busy()
	return aim_timer || focus_timer || fan_timer

/obj/item/heretic_path_relic/lead_revolver/proc/drum_block_reason(mob/living/user)
	. = use_block_reason(user)
	if(!. && drum_busy())
		return "курок уже взведён"

/obj/item/heretic_path_relic/lead_revolver/proc/drum_hand_ready(mob/living/user)
	return !drum_block_reason(user)

/// Отказ вслух: облачко над револьвером и строка в чате с причиной.
/obj/item/heretic_path_relic/lead_revolver/proc/refuse(mob/living/user, reason)
	balloon_alert(user, reason)
	to_chat(user, span_warning("Шестизарядник: [reason]."))
	return FALSE

/obj/item/heretic_path_relic/lead_revolver/AltClick(mob/user)
	if(!isliving(user) || !user.is_holding(src) || !IS_HERETIC(user))
		return ..()
	var/reason = drum_block_reason(user)
	if(reason)
		refuse(user, reason)
		return TRUE
	INVOKE_ASYNC(src, PROC_REF(choose_chamber), user)
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/CtrlClick(mob/user)
	if(!isliving(user) || !user.is_holding(src) || !IS_HERETIC(user))
		return ..()
	spin(user)
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/attack_self(mob/living/user)
	. = ..()
	if(!IS_HERETIC(user))
		return
	var/reason = drum_block_reason(user)
	if(reason)
		refuse(user, reason)
		return
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	lead.drum_style = (lead.drum_style + 1) % (HERETIC_LEAD_STYLE_FAN + 1)
	lead.update_drum_hud()
	balloon_alert(user, lead.style_name())
	switch(lead.drum_style)
		if(HERETIC_LEAD_STYLE_AIMED)
			to_chat(user, span_notice("Прицельный выстрел: щелчок по живой цели в [lead.aim_range()] клетках - [replacetext("[lead.aim_time() / (1 SECONDS)]", ".", ",")] с стойте неподвижно, цель видит красную линию; затем пуля бьёт на [HERETIC_LEAD_AIM_BONUS]% сильнее и пробивает броню глубже."))
		if(HERETIC_LEAD_STYLE_FAN)
			to_chat(user, span_notice("Веер: щелчок по цели - щелчок курка, затем за секунду уходят все заряженные каморы[lead.fan_extra() ? " и ещё [lead.fan_extra()] пули Канонира" : ""] с разбросом, по [HERETIC_LEAD_FAN_DAMAGE]% урона каждая; после - [HERETIC_LEAD_FAN_LOCKOUT / (1 SECONDS)] секунды без выстрелов."))
		else
			to_chat(user, span_notice("Обычный выстрел из каморы под курком."))
	heretic_lead_sound(src, "drum_select", 25, TRUE, SILENCED_SOUND_EXTRARANGE)

/obj/item/heretic_path_relic/lead_revolver/proc/chamber_choices(datum/eldritch_knowledge/base_lead/lead)
	. = list()
	for(var/position in lead.open_chambers())
		.[lead.round_name(position)] = round_image(lead.chamber_round(position))
	if(lead.last_round_ready())
		.["Последний патрон"] = round_image(/obj/item/projectile/bullet/heretic_lead/last_round)

/obj/item/heretic_path_relic/lead_revolver/proc/round_image(obj/item/projectile/bullet/heretic_lead/round_type)
	var/image/case = image(LEAD_DRUM_ICON, "round_case")
	var/image/tip = image(LEAD_DRUM_ICON, "round_tip")
	tip.color = initial(round_type.color)
	case.overlays += tip
	return case

/obj/item/heretic_path_relic/lead_revolver/proc/choose_chamber(mob/living/user)
	var/reason = drum_block_reason(user)
	if(reason)
		return refuse(user, reason)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	var/list/choices = chamber_choices(lead)
	var/picked = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(drum_hand_ready), user), require_near = TRUE, tooltips = TRUE)
	if(!picked)
		return FALSE
	reason = drum_block_reason(user)
	if(reason)
		return refuse(user, reason)
	var/position = picked == "Последний патрон" ? HERETIC_LEAD_CAPACITY : null
	for(var/open in lead.open_chambers())
		if(!position && lead.round_name(open) == picked)
			position = open
	return select_chamber(user, position)

/// Камора встаёт под курок за полсекунды; выстрела в это время нет.
/obj/item/heretic_path_relic/lead_revolver/proc/select_chamber(mob/living/user, position)
	var/reason = drum_block_reason(user)
	if(reason)
		return refuse(user, reason)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(!lead.turn_drum(position))
		return refuse(user, position == HERETIC_LEAD_CAPACITY ? "Шестая камора - только при полном барабане" : "эта камора ещё закрыта")
	COOLDOWN_START(src, drum_turn, HERETIC_LEAD_DRUM_TURN)
	heretic_lead_sound(src, "drum_select", 35, TRUE, SILENCED_SOUND_EXTRARANGE)
	if(position == HERETIC_LEAD_CAPACITY)
		balloon_alert(user, "последний патрон")
		if(lead.free_last_round)
			to_chat(user, span_notice("Шестая камора взведена - подарок барабана: следующий выстрел в человека уйдёт Последним патроном, а Свинец в барабане останется. Отменить - Alt-клик и любая другая камора."))
		else
			to_chat(user, span_notice("Шестая камора взведена: следующий выстрел в человека при полном барабане уйдёт Последним патроном за весь Свинец. Отменить - Alt-клик и любая другая камора."))
		return TRUE
	balloon_alert(user, lowertext(lead.round_name(position)))
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/proc/spin(mob/living/user)
	var/reason = drum_block_reason(user)
	if(reason)
		return refuse(user, reason)
	if(!COOLDOWN_FINISHED(src, drum_spin))
		balloon_alert(user, "барабан ещё не остыл")
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	COOLDOWN_START(src, drum_spin, HERETIC_LEAD_SPIN_COOLDOWN)
	COOLDOWN_START(src, drum_turn, HERETIC_LEAD_DRUM_TURN)
	var/position = lead.spin_drum()
	heretic_lead_sound(src, "drum_spin", 45, TRUE)
	user.visible_message(span_warning("[user] с треском раскручивает барабан [src]."), span_notice("Барабан встаёт на камору «[lead.round_name(position)]»: эта пуля ударит на [HERETIC_LEAD_LUCK_BONUS]% сильнее."))
	balloon_alert(user, lowertext(lead.round_name(position)))
	return position

/proc/heretic_lead_aim_target(atom/target, mob/living/user, range = HERETIC_LEAD_AIM_RANGE)
	var/mob/living/victim = target
	return istype(victim) && victim != user && victim.stat != DEAD && isturf(victim.loc) && victim.z == user.z && get_dist(user, victim) <= range

/// Прицельный выстрел: секунда неподвижности, красная линия видна цели.
/obj/item/heretic_path_relic/lead_revolver/proc/start_focus(mob/living/victim, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	var/aim_time = lead ? lead.aim_time() : HERETIC_LEAD_AIM_TIME
	focus_ref = WEAKREF(victim)
	focus_from = get_turf(user)
	focus_beam = user.Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = aim_time + LEAD_FOCUS_TRACE, maxdistance = (lead ? lead.aim_range() : HERETIC_LEAD_AIM_RANGE) + 1)
	focus_timer = addtimer(CALLBACK(src, PROC_REF(fire_focus), WEAKREF(user)), aim_time, TIMER_STOPPABLE)
	heretic_lead_sound(src, "cock", 45, TRUE)
	user.visible_message(span_danger("[user] вскидывает [src] и замирает, целясь в [victim]!"), span_notice("Вы целитесь в [victim]: не двигайтесь [replacetext("[aim_time / (1 SECONDS)]", ".", ",")] с."))
	to_chat(victim, span_userdanger("От ствола к вам тянется красная линия прицела! Уйдите с линии за укрытие."))
	log_combat(user, victim, "берёт на прицел Шестизарядником")
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/proc/clear_focus()
	deltimer(focus_timer)
	focus_timer = null
	focus_ref = null
	focus_from = null
	QDEL_NULL(focus_beam)

/obj/item/heretic_path_relic/lead_revolver/proc/fire_focus(datum/weakref/user_ref)
	focus_timer = null
	var/mob/living/victim = focus_ref?.resolve()
	var/turf/from = focus_from
	clear_focus()
	var/mob/living/user = user_ref?.resolve()
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(!lead?.can_use(user) || !user.is_holding(src) || get_turf(user) != from || !heretic_lead_aim_target(victim, user, lead.aim_range()) || !can_see(user, victim, lead.aim_range()))
		if(user)
			to_chat(user, span_warning("Прицел сорвался: вы сдвинулись или цель ушла с линии. Свинец цел."))
		return null
	return shoot_round(victim, user, null, lead, aimed = TRUE)

/// Веер: щелчок курка, затем за секунду уходят все заряженные каморы с разбросом.
/obj/item/heretic_path_relic/lead_revolver/proc/start_fan(atom/target, mob/living/user, datum/eldritch_knowledge/base_lead/lead)
	fan_free = lead.fan_extra()
	fan_left = lead.combat_resource + fan_free
	heretic_lead_sound(src, "fan", 60, TRUE)
	user.visible_message(span_danger("[user] накрывает курок [src] ладонью: сейчас будет веер!"), span_notice("Веер: [fan_left] [fan_left == 1 ? "камора" : "камор"] за секунду."))
	log_combat(user, target, "раскручивает веер из Шестизарядника по", src, "камор: [fan_left]")
	fan_timer = addtimer(CALLBACK(src, PROC_REF(fan_shot), WEAKREF(user), WEAKREF(target)), HERETIC_LEAD_FAN_TELEGRAPH, TIMER_STOPPABLE)
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/proc/fan_shot(datum/weakref/user_ref, datum/weakref/target_ref)
	fan_timer = null
	var/mob/living/user = user_ref?.resolve()
	var/atom/target = target_ref?.resolve()
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(fan_left <= 0 || !lead?.can_use(user) || !user.is_holding(src) || QDELETED(target) || (lead.combat_resource <= 0 && fan_free <= 0))
		return end_fan(lead, user, fan_left > 0)
	fan_left--
	var/free = lead.combat_resource <= 0
	if(free)
		fan_free--
	shoot_round(target, user, null, lead, fan = TRUE, free = free)
	if(fan_left > 0 && (lead.combat_resource > 0 || fan_free > 0))
		fan_timer = addtimer(CALLBACK(src, PROC_REF(fan_shot), user_ref, target_ref), HERETIC_LEAD_FAN_TIME / HERETIC_LEAD_CAPACITY, TIMER_STOPPABLE)
		return TRUE
	return end_fan(lead, user)

/// Веер кончился: стиль сам возвращается к обычному выстрелу, и стрелок об этом слышит.
/obj/item/heretic_path_relic/lead_revolver/proc/end_fan(datum/eldritch_knowledge/base_lead/lead, mob/living/user, interrupted = FALSE)
	deltimer(fan_timer)
	fan_timer = null
	fan_left = 0
	fan_free = 0
	COOLDOWN_START(src, fan_lockout, HERETIC_LEAD_FAN_LOCKOUT)
	if(lead)
		lead.drum_style = HERETIC_LEAD_STYLE_PLAIN
		lead.update_drum_hud()
	if(user)
		balloon_alert(user, "обычный выстрел")
		to_chat(user, span_notice("[interrupted ? "Веер оборван" : "Веер отстрелян"]: стиль снова «обычный выстрел», [HERETIC_LEAD_FAN_LOCKOUT / (1 SECONDS)] секунды ствол остывает. Снова веер - дважды «Использовать в руке»."))
	return FALSE

/obj/item/heretic_path_relic/lead_revolver/dropped(mob/user, silent)
	. = ..()
	if(focus_timer)
		clear_focus()
	if(fan_timer)
		end_fan(owner_lead(user), user, TRUE)

/obj/item/heretic_path_relic/lead_revolver/examine(mob/user)
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(!lead || user.mind != creator?.resolve())
		return
	. += span_eldritch("Барабан:[lead.drum_state()]")
	. += span_notice("Alt-клик - выбрать камору ([HERETIC_LEAD_DRUM_TURN / (1 SECONDS)] с); со Слухом стрелка при полном барабане там же взводится Шестая камора - Последний патрон по человеку. Ctrl-клик - прокрутить барабан на удачу: выпавшая пуля бьёт на [HERETIC_LEAD_LUCK_BONUS]% сильнее, раз в [HERETIC_LEAD_SPIN_COOLDOWN / (1 SECONDS)] секунд. «Использовать в руке» меняет стиль: обычный, прицельный, веер.")
	. += span_notice("Пули: Свинцовая [HERETIC_LEAD_REVOLVER_DAMAGE] ушибов с пробитием, Тяжёлая [HERETIC_LEAD_ROUND_DAMAGE] и валит на [replacetext("[HERETIC_LEAD_HEAVY_KNOCKDOWN / (1 SECONDS)]", ".", ",")] секунды сквозь броню, Меченая [HERETIC_LEAD_ROUND_DAMAGE] и Мишень, Пороховая [HERETIC_LEAD_POWDER_DAMAGE] и поджигает, ещё [HERETIC_LEAD_POWDER_BURN] ожогов сквозь броню, Звонкая [HERETIC_LEAD_ROUND_DAMAGE] и рикошет на [HERETIC_LEAD_RING_DAMAGE] в соседа в [HERETIC_LEAD_RING_RANGE] клетках. Закрытая камора бьёт Свинцовой.")
	. += span_notice("Вплотную в намерении «Вред» - удар рукоятью: [HERETIC_LEAD_BUTT_DAMAGE] ушибов, шаг цели сбит на [HERETIC_LEAD_BUTT_SLOW / (1 SECONDS)] секунды, единица Свинца; раз в [HERETIC_LEAD_BUTT_COOLDOWN / (1 SECONDS)] секунду. Патронташ: [lead.bandolier] из [HERETIC_LEAD_BANDOLIER], пустой барабан дозаряжается из него за [HERETIC_LEAD_RELOAD_TIME / (1 SECONDS)] секунду.")
	var/penetration = lead.sacrifice_penetration()
	if(penetration)
		. += span_notice("Принятые души добавляют всем пулям [penetration] пробития (не больше [HERETIC_LEAD_SACRIFICE_PENETRATION_CAP]).")
	if(!COOLDOWN_FINISHED(src, drum_spin))
		. += span_notice("Барабан остынет через [CEILING(COOLDOWN_TIMELEFT(src, drum_spin) / (1 SECONDS), 1)] с.")

/obj/item/projectile/bullet/heretic_lead/heavy
	name = "heavy Mansus bullet"
	damage = HERETIC_LEAD_ROUND_DAMAGE
	armour_penetration = 0
	color = "#6f8fd0"
	round_name = "Тяжёлая"

/// Тяжёлая пуля валит с ног сквозь броню, но одну цель не чаще раза в 6 секунд.
/obj/item/projectile/bullet/heretic_lead/heavy/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	if(!istype(victim) || blocked >= 100 || QDELETED(victim) || victim.has_status_effect(/datum/status_effect/heretic_lead_staggered))
		return
	victim.apply_status_effect(/datum/status_effect/heretic_lead_staggered)
	victim.Knockdown(HERETIC_LEAD_HEAVY_KNOCKDOWN)
	if(ismob(firer))
		log_combat(firer, victim, "сбивает с ног Тяжёлой пулей Шестизарядника")

/obj/item/projectile/bullet/heretic_lead/marked
	name = "marked Mansus bullet"
	damage = HERETIC_LEAD_ROUND_DAMAGE
	armour_penetration = 0
	color = "#e0444c"
	round_name = "Меченая"

/obj/item/projectile/bullet/heretic_lead/marked/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!istype(victim) || blocked >= 100 || !lead || QDELETED(lead.lead_body) || !isturf(victim.loc) || !heretic_can_affect(lead.lead_body, victim, chargecost = 0, notify = FALSE))
		return
	victim.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	log_combat(lead.lead_body, victim, "вешает Мишень Меченой пулей Шестизарядника")

/obj/item/projectile/bullet/heretic_lead/powder
	name = "powder Mansus bullet"
	damage = HERETIC_LEAD_POWDER_DAMAGE
	armour_penetration = 0
	color = "#f08a2c"
	round_name = "Пороховая"

/// Пороховая пуля поджигает цель, а вспышка пороха обжигает её сквозь броню; у Канонира ещё и хлопает.
/obj/item/projectile/bullet/heretic_lead/powder/on_hit(atom/target, blocked = FALSE, pierce_hit)
	var/turf/place = get_turf(src)
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead?.school == HERETIC_LEAD_SCHOOL_CANNONEER)
		heretic_lead_pop(isliving(target) ? get_turf(target) : place, lead)
	var/mob/living/victim = target
	if(!istype(victim) || blocked >= 100 || QDELETED(victim))
		return
	victim.apply_damage(HERETIC_LEAD_POWDER_BURN, BURN, def_zone)
	victim.adjust_fire_stacks(HERETIC_LEAD_POWDER_STACKS)
	victim.IgniteMob()
	if(ismob(firer))
		log_combat(firer, victim, "поджигает Пороховой пулей Шестизарядника")

/obj/item/projectile/bullet/heretic_lead/ringing
	name = "ringing Mansus bullet"
	damage = HERETIC_LEAD_ROUND_DAMAGE
	armour_penetration = 0
	color = "#ead26a"
	round_name = "Звонкая"

/obj/item/projectile/bullet/heretic_lead/ringing/on_hit(atom/target, blocked = FALSE, pierce_hit)
	var/turf/place = get_turf(src)
	. = ..()
	if(!isliving(target) || blocked < 100)
		ring_off(place, target)

/// Звонкая пуля отскакивает от цели или стены к ближайшему врагу в 4 клетках, путь рикошета виден всем.
/obj/item/projectile/bullet/heretic_lead/ringing/proc/ring_off(turf/place, atom/struck)
	var/turf/origin = isliving(struck) ? get_turf(struck) : place
	var/mob/living/victim = heretic_lead_ring_target(origin, struck, firer)
	new /obj/effect/temp_visual/heretic_lead/ricochet(origin)
	heretic_lead_sound(origin, "ricochet", 50, TRUE)
	if(!victim)
		return null
	origin.Beam(victim, icon_state = "ring_line", icon = LEAD_DRUM_ICON, time = LEAD_RING_TRACE, maxdistance = HERETIC_LEAD_RING_RANGE + 1)
	var/obj/item/projectile/bullet/heretic_lead/rebound/bullet = new(origin)
	bullet.firer = firer
	bullet.fired_from = fired_from
	bullet.lead_ref = lead_ref
	bullet.def_zone = BODY_ZONE_CHEST
	LAZYSET(bullet.impacted, struck, TRUE)
	bullet.preparePixelProjectile(victim, origin)
	if(QDELETED(bullet))
		return null
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.school_tracer(bullet)
	bullet.fire()
	if(ismob(firer))
		log_combat(firer, victim, "достаёт рикошетом Звонкой пули Шестизарядника")
	return bullet

/proc/heretic_lead_ring_target(turf/origin, atom/struck, atom/firer)
	var/mob/living/best
	var/best_distance
	for(var/mob/living/candidate in range(HERETIC_LEAD_RING_RANGE, origin))
		if(candidate == struck || candidate == firer || candidate.stat == DEAD || !isturf(candidate.loc) || IS_HERETIC(candidate) || IS_HERETIC_MONSTER(candidate))
			continue
		var/distance = get_dist_euclidian(origin, candidate)
		if(best && distance >= best_distance)
			continue
		if(heretic_edge_line_clear(origin, candidate))
			best = candidate
			best_distance = distance
	return best

/obj/item/projectile/bullet/heretic_lead/rebound
	name = "ricochet"
	damage = HERETIC_LEAD_RING_DAMAGE
	armour_penetration = 0
	color = "#ead26a"
	round_name = "Рикошет"
	refunds = FALSE

/obj/item/projectile/bullet/heretic_lead/piercing
	name = "armor-piercing Mansus bullet"
	damage = HERETIC_LEAD_REVOLVER_DAMAGE
	armour_penetration = HERETIC_LEAD_PIERCING_PENETRATION
	color = "#5fe0cf"
	round_name = "Бронебойная"

/// Не даёт Тяжёлой пуле валить одну и ту же цель подряд.
/datum/status_effect/heretic_lead_staggered
	id = "heretic_lead_staggered"
	duration = HERETIC_LEAD_HEAVY_REPEAT
	tick_interval = -1
	alert_type = null

/// Звон в ушах после пули в голову: пару секунд цель ничего не слышит.
/datum/status_effect/heretic_lead_ringing
	id = "heretic_lead_ringing"
	duration = HERETIC_LEAD_HEADSHOT_RING
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_lead_ringing/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_DEAF, id)
	SEND_SOUND(owner, sound('sound/weapons/flash_ring.ogg', volume = 40))
	to_chat(owner, span_warning("Пуля чиркает по голове, и в ушах звенит: на миг вы ничего не слышите."))

/datum/status_effect/heretic_lead_ringing/on_remove()
	REMOVE_TRAIT(owner, TRAIT_DEAF, id)
	return ..()

#undef LEAD_DRUM_ICON
#undef LEAD_DRUM_RING
#undef LEAD_RING_TRACE
#undef LEAD_FOCUS_TRACE
#undef LEAD_BELT_TEXT_HEIGHT
