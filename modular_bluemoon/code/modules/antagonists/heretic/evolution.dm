/datum/antagonist/heretic
	/// Облик пути на теле: появляется с первой ступенью облика и уходит со снятием роли.
	var/datum/heretic_evolution/evolution

/// Сколько порогов облика пути пройдено, без вознесения.
/datum/antagonist/heretic/proc/evolution_stage_tier(path_id = selected_path)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	. = 0
	for(var/stage in path?.evolution_thresholds)
		if(path_stage >= stage)
			.++

/// Ступень облика: вознесение на одну выше последнего порога.
/datum/antagonist/heretic/proc/evolution_tier()
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(!path || role_removed)
		return 0
	return ascended ? length(path.evolution_thresholds) + 1 : evolution_stage_tier()

/// force - завести облик и без ступени: мутация Сумрака держится за базовое знание, а не за путь.
/datum/antagonist/heretic/proc/refresh_evolution(force = FALSE)
	if(role_removed)
		clear_evolution()
		return
	if(!evolution)
		if(!force && !evolution_tier())
			return
		evolution = new /datum/heretic_evolution(src)
	evolution.refresh()

/datum/antagonist/heretic/proc/clear_evolution()
	QDEL_NULL(evolution)

/// Своя способность пути: заклинание разума, которое не выдано общим или побочным знанием.
/datum/antagonist/heretic/proc/is_path_spell(obj/effect/proc_holder/spell/spell)
	if(!selected_path || !(spell in owner?.spell_list))
		return FALSE
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/spell/knowledge = researched_knowledge[knowledge_type]
		if(istype(knowledge) && knowledge.granted_spell == spell)
			return knowledge.route == selected_path
	return TRUE

/datum/heretic_path
	/// Ступени пути, после которых меняется облик; ступень облика сверх списка - вознесение.
	var/list/evolution_thresholds = list(HERETIC_EVOLUTION_FIRST_STAGE, HERETIC_EVOLUTION_SECOND_STAGE)
	/// Листы облика: null - ищутся по id пути в heretic_evolution, нет файла или стейта - слой пропускается.
	var/evolution_icon
	var/evolution_icon_64
	var/list/evolution_states
	var/list/evolution_states_64
	/// Строки осмотра на каждую ступень облика: list(часть тела = строка).
	var/list/evolution_examine

/datum/heretic_path/proc/evolution_load()
	if(evolution_states)
		return
	evolution_icon ||= heretic_evolution_sheet(id, FALSE)
	evolution_icon_64 ||= heretic_evolution_sheet(id, TRUE)
	evolution_states = heretic_evolution_state_set(evolution_icon)
	evolution_states_64 = heretic_evolution_state_set(evolution_icon_64)

/// Листы облика вкомпилированы в ресурсы явными ссылками: путь без листа получает null и рисуется без облика.
/proc/heretic_evolution_sheet(path_id, big)
	var/static/list/sheets = list(
		"ash" = 'modular_bluemoon/icons/mob/heretic_evolution/ash.dmi',
		"blade" = 'modular_bluemoon/icons/mob/heretic_evolution/blade.dmi',
		"blood" = 'modular_bluemoon/icons/mob/heretic_evolution/blood.dmi',
		"cosmic" = 'modular_bluemoon/icons/mob/heretic_evolution/cosmic.dmi',
		"dance" = 'modular_bluemoon/icons/mob/heretic_evolution/dance.dmi',
		"echo" = 'modular_bluemoon/icons/mob/heretic_evolution/echo.dmi',
		"flesh" = 'modular_bluemoon/icons/mob/heretic_evolution/flesh.dmi',
		"glass" = 'modular_bluemoon/icons/mob/heretic_evolution/glass.dmi',
		"lead" = 'modular_bluemoon/icons/mob/heretic_evolution/lead.dmi',
		"lock" = 'modular_bluemoon/icons/mob/heretic_evolution/lock.dmi',
		"moon" = 'modular_bluemoon/icons/mob/heretic_evolution/moon.dmi',
		"rust" = 'modular_bluemoon/icons/mob/heretic_evolution/rust.dmi',
		"sand" = 'modular_bluemoon/icons/mob/heretic_evolution/sand.dmi',
		"spirit" = 'modular_bluemoon/icons/mob/heretic_evolution/spirit.dmi',
		"tide" = 'modular_bluemoon/icons/mob/heretic_evolution/tide.dmi',
		"tide_64" = 'modular_bluemoon/icons/mob/heretic_evolution/tide_64.dmi',
		"void" = 'modular_bluemoon/icons/mob/heretic_evolution/void.dmi',
		"wax" = 'modular_bluemoon/icons/mob/heretic_evolution/wax.dmi',
	)
	return sheets["[lowertext(path_id)][big ? "_64" : ""]"]

/proc/heretic_evolution_state_set(sheet)
	. = list()
	if(!sheet)
		return
	for(var/state in icon_states(sheet))
		.[state] = TRUE

/datum/heretic_path/proc/evolution_has(state)
	evolution_load()
	return evolution_states[state] || evolution_states_64[state]

/// Крупный лист 64x64 берётся первым для слоёв поверх одежды и всплеска.
/datum/heretic_path/proc/evolution_add(list/looks, state, layer, big_first = FALSE)
	evolution_load()
	var/sheet
	var/offset = 0
	if(big_first && evolution_states_64[state])
		sheet = evolution_icon_64
		offset = HERETIC_EVOLUTION_BIG_OFFSET
	else if(evolution_states[state])
		sheet = evolution_icon
	else
		return
	var/mutable_appearance/look = mutable_appearance(sheet, state, layer)
	look.pixel_x = offset
	look.pixel_y = offset
	look.appearance_flags = RESET_COLOR
	looks += look

/// Кожа под одеждой, кисти под перчатками, лицо под капюшоном и маской, макушка под капюшоном и шлемом, остальное поверх одежды.
/datum/heretic_path/proc/evolution_build_overlays(datum/heretic_evolution/evolution, obj/item/gone)
	. = list()
	if(!evolution.tier || evolution.body.stat == DEAD)
		return
	var/prefix = "[lowertext(id)]_evo[evolution.tier]"
	evolution_add(., prefix, -BODY_ADJ_LAYER)
	if(!evolution.part_hidden(HERETIC_EVOLUTION_HANDS, gone))
		evolution_add(., "[prefix]_open", -HERETIC_EVOLUTION_HANDS_LAYER)
	// Глаза в общем лице прячут и очки; отдельный стейт глаз оставляет лицо открытым под очками.
	var/eyes_state = "[prefix]_eyes"
	var/split_eyes = evolution_has(eyes_state)
	var/eyes_hidden = evolution.part_hidden(HERETIC_EVOLUTION_EYES, gone)
	if(!evolution.part_hidden(HERETIC_EVOLUTION_FACE, gone) && (split_eyes || !eyes_hidden))
		evolution_add(., "[prefix]_face", -HERETIC_EVOLUTION_FACE_LAYER)
	if(split_eyes && !eyes_hidden)
		evolution_add(., eyes_state, -HERETIC_EVOLUTION_FACE_LAYER)
	if(!evolution.part_hidden(HERETIC_EVOLUTION_HAIR, gone))
		evolution_add(., "[prefix]_head", -HERETIC_EVOLUTION_FACE_LAYER)
	evolution_add(., "[prefix]_over", -BODY_FRONT_LAYER, TRUE)

/datum/heretic_path/proc/evolution_build_burst(datum/heretic_evolution/evolution)
	. = list()
	var/prefix = "[lowertext(id)]_evo[evolution.tier]_burst"
	evolution_add(., prefix, -BODY_FRONT_LAYER, TRUE)
	if(!evolution.part_hidden(HERETIC_EVOLUTION_FACE) && !evolution.part_hidden(HERETIC_EVOLUTION_EYES))
		evolution_add(., "[prefix]_face", -HERETIC_EVOLUTION_FACE_LAYER, TRUE)

/datum/heretic_path/proc/evolution_live_overlays(datum/heretic_evolution/evolution)
	return evolution.body_overlays

/// Первую ступень замечают вплотную, вторую - с пары клеток, и только на открытых частях тела; вознесённого видно всегда.
/datum/heretic_path/proc/evolution_examine_lines(datum/heretic_evolution/evolution, mob/examiner, list/examine_list)
	var/tier = evolution.tier
	if(!tier || !examiner || evolution.body.stat == DEAD)
		return
	if(tier > length(evolution_thresholds))
		evolution_examine_tier(evolution, tier, examine_list, TRUE)
		return
	var/distance = get_dist(examiner, evolution.body)
	for(var/level in 1 to tier)
		if(distance <= (level == 1 ? HERETIC_EVOLUTION_FIRST_RANGE : HERETIC_EVOLUTION_SECOND_RANGE))
			evolution_examine_tier(evolution, level, examine_list, FALSE)

/datum/heretic_path/proc/evolution_examine_tier(datum/heretic_evolution/evolution, level, list/examine_list, revealed)
	if(level > length(evolution_examine))
		return
	var/list/lines = evolution_examine[level]
	for(var/part in lines)
		if(!evolution.part_hidden(part))
			examine_list += revealed ? span_warning(lines[part]) : span_notice(lines[part])

/// Облик на теле еретика: слои ступени, их скрытие одеждой, осмотр и всплеск при способностях пути.
/datum/heretic_evolution
	var/datum/antagonist/heretic/heretic
	var/mob/living/carbon/human/body
	var/tier = 0
	var/list/body_overlays = list()
	var/list/burst_overlays = list()
	COOLDOWN_DECLARE(burst_cooldown)

/datum/heretic_evolution/New(datum/antagonist/heretic/heretic)
	src.heretic = heretic
	if(heretic.owner)
		RegisterSignal(heretic.owner, COMSIG_MIND_TRANSFER, PROC_REF(on_mind_transfer))

/datum/heretic_evolution/Destroy()
	if(heretic?.owner)
		UnregisterSignal(heretic.owner, COMSIG_MIND_TRANSFER)
	detach()
	heretic = null
	return ..()

/datum/heretic_evolution/proc/attach(mob/living/carbon/human/new_body)
	if(body == new_body)
		return
	detach()
	if(!ishuman(new_body) || QDELETED(new_body))
		return
	body = new_body
	RegisterSignal(body, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	RegisterSignal(body, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(body, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignal(body, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equipped))
	RegisterSignal(body, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_unequipped))
	RegisterSignal(body, COMSIG_CARBON_FACE_COVER_UPDATED, PROC_REF(on_cover_updated))
	RegisterSignal(body, COMSIG_MOB_CAST_SPELL, PROC_REF(on_cast))
	RegisterSignals(body, list(SIGNAL_TRAIT(TRAIT_HERETIC_ASCENDED), SIGNAL_REMOVETRAIT(TRAIT_HERETIC_ASCENDED)), PROC_REF(on_ascension_changed))

/datum/heretic_evolution/proc/detach()
	if(!body)
		return
	var/mob/living/carbon/human/old_body = body
	UnregisterSignal(old_body, list(COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_PARENT_EXAMINE, COMSIG_PARENT_QDELETING, COMSIG_MOB_STATCHANGE, COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_CARBON_FACE_COVER_UPDATED, COMSIG_MOB_CAST_SPELL, SIGNAL_TRAIT(TRAIT_HERETIC_ASCENDED), SIGNAL_REMOVETRAIT(TRAIT_HERETIC_ASCENDED)))
	body = null
	tier = 0
	body_overlays = list()
	burst_overlays = list()
	old_body.update_icon(UPDATE_OVERLAYS)

/// Облик идёт за разумом в текущее тело; gone - вещь, которую снимают прямо сейчас, она уже не закрывает.
/datum/heretic_evolution/proc/refresh(obj/item/gone)
	var/mob/living/current = heretic.owner?.current
	if(body != current)
		attach(current)
	if(!body)
		return
	tier = heretic.evolution_tier()
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
	body_overlays = path?.evolution_build_overlays(src, gone) || list()
	if(!tier || body.stat == DEAD)
		burst_overlays = list()
	body.update_icon(UPDATE_OVERLAYS)

/datum/heretic_evolution/proc/worn(obj/item/item, obj/item/gone)
	return item && item != gone

/datum/heretic_evolution/proc/part_hidden(part, obj/item/gone)
	switch(part)
		if(HERETIC_EVOLUTION_HANDS)
			if(worn(body.gloves, gone) || !body.get_bodypart(BODY_ZONE_L_ARM) || !body.get_bodypart(BODY_ZONE_R_ARM))
				return TRUE
			var/obj/item/suit = worn(body.wear_suit, gone) ? body.wear_suit : null
			return suit && ((suit.flags_inv & HIDEGLOVES) || (suit.body_parts_covered & HANDS))
		if(HERETIC_EVOLUTION_FACE, HERETIC_EVOLUTION_EYES)
			if(!body.get_bodypart(BODY_ZONE_HEAD))
				return TRUE
			var/eyes = part == HERETIC_EVOLUTION_EYES
			var/obj/item/head = worn(body.head, gone) ? body.head : null
			if(head && ((head.flags_inv & (HIDEFACE | HIDEHAIR | (eyes ? HIDEEYES : NONE))) || (head.flags_cover & (eyes ? HEADCOVERSEYES : HEADCOVERSMOUTH))))
				return TRUE
			var/obj/item/mask = worn(body.wear_mask, gone) ? body.wear_mask : null
			if(mask && ((mask.flags_inv & (HIDEFACE | (eyes ? HIDEEYES : NONE))) || (mask.flags_cover & (eyes ? MASKCOVERSEYES : MASKCOVERSMOUTH))))
				return TRUE
			return eyes && worn(body.glasses, gone) && (body.glasses.flags_cover & GLASSESCOVERSEYES)
		if(HERETIC_EVOLUTION_HAIR)
			if(!body.get_bodypart(BODY_ZONE_HEAD))
				return TRUE
			var/obj/item/head = worn(body.head, gone) ? body.head : null
			var/obj/item/mask = worn(body.wear_mask, gone) ? body.wear_mask : null
			return (head && (head.flags_inv & HIDEHAIR)) || (mask && (mask.flags_inv & HIDEHAIR))
	return FALSE

/datum/heretic_evolution/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
	var/list/live = path?.evolution_live_overlays(src)
	if(length(live))
		overlays += live
	if(length(burst_overlays))
		overlays += burst_overlays

/datum/heretic_evolution/proc/on_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
	path?.evolution_examine_lines(src, examiner, examine_list)

/datum/heretic_evolution/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	detach()

/datum/heretic_evolution/proc/on_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	refresh()

/datum/heretic_evolution/proc/on_stat_change(mob/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if((new_stat == DEAD) != (old_stat == DEAD))
		refresh()

/datum/heretic_evolution/proc/on_equipped(mob/source, obj/item/item, slot)
	SIGNAL_HANDLER
	if(tier && (slot & (ITEM_SLOT_GLOVES | ITEM_SLOT_EYES | ITEM_SLOT_OCLOTHING)))
		refresh()

/// Сигнал приходит, пока вещь ещё в слоте: она передаётся как уже снятая.
/datum/heretic_evolution/proc/on_unequipped(mob/source, obj/item/item)
	SIGNAL_HANDLER
	if(tier && item && (item == body.gloves || item == body.glasses || item == body.wear_suit))
		refresh(item)

/datum/heretic_evolution/proc/on_cover_updated(mob/source)
	SIGNAL_HANDLER
	if(tier)
		refresh()

/datum/heretic_evolution/proc/on_ascension_changed(mob/source)
	SIGNAL_HANDLER
	refresh()

/// Способность пути даёт короткий всплеск ступени, не чаще раза за HERETIC_EVOLUTION_BURST_COOLDOWN.
/datum/heretic_evolution/proc/on_cast(mob/source, obj/effect/proc_holder/spell/spell)
	SIGNAL_HANDLER
	if(!tier || body.stat == DEAD || !COOLDOWN_FINISHED(src, burst_cooldown) || !heretic.is_path_spell(spell))
		return
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
	var/list/looks = path?.evolution_build_burst(src)
	if(!length(looks))
		return
	COOLDOWN_START(src, burst_cooldown, HERETIC_EVOLUTION_BURST_COOLDOWN)
	burst_overlays = looks
	body.update_icon(UPDATE_OVERLAYS)
	addtimer(CALLBACK(src, PROC_REF(end_burst)), HERETIC_EVOLUTION_BURST_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/heretic_evolution/proc/end_burst()
	burst_overlays = list()
	body?.update_icon(UPDATE_OVERLAYS)

/datum/heretic_path/ash
	evolution_examine = list(
		list(HERETIC_EVOLUTION_EYES = "Если присмотреться, в зрачках тлеют крошечные угольки."),
		list(HERETIC_EVOLUTION_HANDS = "Пальцы и тыльная сторона кистей в серых хлопьях пепла, кожа на них сухая, как обугленная бумага."),
		list(HERETIC_EVOLUTION_ANY = "Кожа растрескалась, сквозь трещины тлеет жар, с плеч сыплется пепел: Пепел горит в этом теле, не скрываясь."),
	)

/datum/heretic_path/rust
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Ногти в мелких рыжих крапинах, будто их отмачивали в ржавой воде.", HERETIC_EVOLUTION_EYES = "В белках глаз проступают рыжие крапины."),
		list(HERETIC_EVOLUTION_HANDS = "На кистях рыжие пятна, кожа на них шелушится хлопьями, как краска на старом металле.", HERETIC_EVOLUTION_FACE = "По шее ползут рыжие пятна, похожие на коррозию."),
		list(HERETIC_EVOLUTION_ANY = "Ржавчина расползлась по всему телу: кожа в металлических струпьях, с пальцев капает рыжая вода."),
	)

/datum/heretic_path/flesh
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Вены на запястьях потемнели и проступают сильнее, чем должны."),
		list(HERETIC_EVOLUTION_HANDS = "На тыльной стороне ладони складка кожи, похожая на сомкнутые губы, а вены на руках вздулись и пульсируют.", HERETIC_EVOLUTION_FACE = "На шее вздулись тёмные вены и мерно пульсируют."),
		list(HERETIC_EVOLUTION_ANY = "Кожа местами раскрыта до мышц, на руках лишние пальцы и рты, а тело мерно дышит целиком: Плоть больше не прячется."),
	)

/datum/heretic_path/void
	evolution_examine = list(
		list(HERETIC_EVOLUTION_FACE = "На ресницах белеет иней, а губы бледные, будто с мороза."),
		list(HERETIC_EVOLUTION_HANDS = "Кожа на кистях бледно-голубая, по ней ползут морозные узоры.", HERETIC_EVOLUTION_FACE = "Изо рта идёт пар, хотя вокруг тепло."),
		list(HERETIC_EVOLUTION_ANY = "Тело местами прозрачно, внутри только холодная пустота, вокруг кружат иней и снежинки: Пустота забирает его по кусочку."),
	)

/datum/heretic_path/blade
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "На пальцах тонкие свежие порезы, ровные, как от бумаги."),
		list(HERETIC_EVOLUTION_HANDS = "Кисти и предплечья в серебристых шрамах, ровных, как по линейке.", HERETIC_EVOLUTION_EYES = "В зрачках мелькает стальной блик, как отражение лезвия."),
		list(HERETIC_EVOLUTION_ANY = "Кожа рассечена ровными порезами, и в каждом блестит сталь: Клинок прорастает сквозь тело."),
	)

/datum/heretic_path/moon
	evolution_examine = list(
		list(HERETIC_EVOLUTION_EYES = "Вокруг зрачков тонкий серебристый ободок."),
		list(HERETIC_EVOLUTION_FACE = "Улыбка чуть шире, чем бывает у людей, а кожа лица бледно мерцает, как в лунном свете.", HERETIC_EVOLUTION_HANDS = "Кожа на кистях бледно мерцает, по ней скользят розовые блики."),
		list(HERETIC_EVOLUTION_ANY = "Кожа светится холодным светом Луны, по ней бегут розовые блики.", HERETIC_EVOLUTION_FACE = "Улыбка растянута до ушей, а в глазах сменяются лунные фазы."),
	)

/datum/heretic_path/cosmic
	evolution_examine = list(
		list(HERETIC_EVOLUTION_EYES = "В одном зрачке горит крошечная звезда."),
		list(HERETIC_EVOLUTION_HANDS = "Кисти усыпаны веснушками, которые медленно мерцают, как звёзды.", HERETIC_EVOLUTION_FACE = "По скулам рассыпаны мерцающие веснушки, похожие на далёкие звёзды."),
		list(HERETIC_EVOLUTION_ANY = "Кожа стала куском звёздного неба, и по рукам ползут созвездия: Космос светит прямо сквозь тело."),
	)

/datum/heretic_path/lock
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "На ладони шрам в форме замочной скважины."),
		list(HERETIC_EVOLUTION_HANDS = "На тыльной стороне кисти тёмная замочная скважина, а под кожей перекатываются мелкие зубцы.", HERETIC_EVOLUTION_FACE = "На шее тянутся швы, похожие на бородку ключа."),
		list(HERETIC_EVOLUTION_ANY = "Тело в скважинах и петлях, сквозь некоторые видна темнота, а при каждом движении что-то лязгает: Замок открыл в нём все двери."),
	)

/datum/heretic_path/tide
	evolution_examine = list(
		list(HERETIC_EVOLUTION_FACE = "Кожа влажная, на подбородке дрожит капля, хотя вокруг сухо."),
		list(HERETIC_EVOLUTION_HANDS = "На запястьях мокрые потёки, белые пятна соли и мелкие ракушки.", HERETIC_EVOLUTION_FACE = "Лицо в разводах соли, волосы липнут к мокрому лбу."),
		list(HERETIC_EVOLUTION_ANY = "С тела без конца стекает вода, на нём ракушки и водоросли: Прилив забрал его себе.", HERETIC_EVOLUTION_FACE = "На шее раскрываются и смыкаются жабры."),
	)

/datum/heretic_path/sand
	evolution_examine = list(
		list(HERETIC_EVOLUTION_EYES = "В морщинках у глаз застряли песчинки."),
		list(HERETIC_EVOLUTION_HANDS = "Кожа на кистях сухая и растрескалась, как земля в пустыне, а из рукава то и дело сыплется песок.", HERETIC_EVOLUTION_FACE = "Губы и щёки сухие, в мелких трещинах, как высохшая глина."),
		list(HERETIC_EVOLUTION_ANY = "Тело осыпается песком, из рукавов текут струйки, у ног растёт горка: Песок течёт сквозь него.", HERETIC_EVOLUTION_EYES = "В зрачках пересыпаются песочные часы."),
	)

/datum/heretic_path/glass
	evolution_examine = list(
		list(HERETIC_EVOLUTION_FACE = "На скуле блестит гладкая грань, будто кожа там стала стеклом."),
		list(HERETIC_EVOLUTION_HANDS = "На тыльной стороне кисти гранёный осколок, он ловит и преломляет свет.", HERETIC_EVOLUTION_FACE = "На скулах поблёскивают стеклянные чешуйки."),
		list(HERETIC_EVOLUTION_ANY = "Кожа местами стала витражом в сколах и трещинах, сквозь неё играют красные, синие и золотые блики: Стекло заменяет плоть."),
	)

/datum/heretic_path/blood
	evolution_examine = list(
		list(HERETIC_EVOLUTION_EYES = "Белки глаз налиты кровью."),
		list(HERETIC_EVOLUTION_HANDS = "Под ногтями засохшая кровь, будто её никак не отмыть.", HERETIC_EVOLUTION_FACE = "Под носом подсохший след крови, на лице проступает тонкая сетка сосудов."),
		list(HERETIC_EVOLUTION_ANY = "Кожа сочится кровью, под ногами натекает лужица: Кровь больше не держится внутри.", HERETIC_EVOLUTION_FACE = "По щекам текут кровавые слёзы."),
	)

/datum/heretic_path/echo
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Если долго смотреть на кисти, их контур будто чуть двоится."),
		list(HERETIC_EVOLUTION_HANDS = "Иногда за кистью на миг отстаёт бледный полупрозрачный контур, как эхо движения.", HERETIC_EVOLUTION_FACE = "Иногда голова на миг двоится, и бледный двойник отстаёт от поворота."),
		list(HERETIC_EVOLUTION_ANY = "Вокруг тела кружат полупрозрачные двойники, каждый отстаёт по-своему: Эхо повторяет его снова и снова."),
	)

/datum/heretic_path/spirit
	evolution_examine = list(
		list(HERETIC_EVOLUTION_FACE = "Дыхание выходит холодным паром."),
		list(HERETIC_EVOLUTION_HANDS = "Кисти полупрозрачные, сквозь них еле видно то, что за ними.", HERETIC_EVOLUTION_FACE = "Лицо призрачно-бледное, с синевой у губ."),
		list(HERETIC_EVOLUTION_ANY = "Края тела растворяются в воздухе, из него тянутся призрачные пряди: Дух уже наполовину по ту сторону.", HERETIC_EVOLUTION_FACE = "На глазах лежат медные монеты, как у покойника."),
	)

/datum/heretic_path/wax
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "На пальце застыла капля воска."),
		list(HERETIC_EVOLUTION_HANDS = "По кистям застывшие потёки воска, кожа гладкая и блестит, как свеча.", HERETIC_EVOLUTION_FACE = "По шее стекают и застывают капли воска."),
		list(HERETIC_EVOLUTION_ANY = "Тело оплывает воском, наплывы застывают и снова тают: Воск превращает его в свечу.", HERETIC_EVOLUTION_HAIR = "Голову покрывает восковая шапка, над макушкой горит фитиль."),
	)

/datum/heretic_path/dance
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Кисти чуть покачиваются, будто в такт какой-то своей музыке."),
		list(HERETIC_EVOLUTION_HANDS = "На запястьях шрамы, как от тугих лент, а пальцы всё время отбивают ритм."),
		list(HERETIC_EVOLUTION_ANY = "Тело ни на миг не замирает, вокруг вьются ленты света, а отражение на полу пляшет в такт: Пляска не отпускает его."),
	)

/datum/heretic_path/lead
	evolution_examine = list(
		list(HERETIC_EVOLUTION_HANDS = "Пальцы в пороховом нагаре, как у того, кто много стреляет."),
		list(HERETIC_EVOLUTION_HANDS = "Ладони в ожогах от отдачи, а вены на запястьях свинцово-серые."),
		list(HERETIC_EVOLUTION_ANY = "Кожа тускло-серая, в ней латунные шрамы от пуль, а из рукавов сыплются гильзы: Свинец сделал оружием само тело."),
	)
