GLOBAL_LIST_EMPTY(blood_bond_blackouts)

/datum/action/cooldown/blood_bond/capstone
	min_tier = BLOOD_BOND_TIER_MAX

/datum/action/cooldown/blood_bond/capstone/proc/spend(log_text)
	StartCooldown(bond_cooldown())
	log_game("Blood brother [key_name(owner)] of [brother.team.name] used [name]: [log_text].")

/datum/action/cooldown/blood_bond/capstone/mark
	name = "Метка крови"
	desc = "На 30 секунд живая цель клятвы обводится кровавым контуром, который видят только братья, а Чутьё показывает, где она. Цель почует чужой взгляд, но не узнает чей."
	bond_how = "Нажать кнопку. Цель должна быть жива и на той же станции или корабле, что и вы."
	button_icon_state = "mark"
	cooldown_time = 5 MINUTES

/datum/action/cooldown/blood_bond/capstone/mark/Activate(atom/target)
	var/mob/living/marked = brother.team.oath?.target_mind?.current
	if(!isliving(marked) || QDELETED(marked))
		owner.balloon_alert(owner, "у клятвы нет цели")
		return FALSE
	if(marked.stat == DEAD)
		owner.balloon_alert(owner, "цель мертва")
		return FALSE
	if(!blood_bond_bearing(get_turf(owner), get_turf(marked)))
		owner.balloon_alert(owner, "цель слишком далеко")
		return FALSE
	brother.team.mark_target(marked)
	spend("marked [key_name(marked)]")
	return TRUE

/// Обводка цели клятвы, видная только братьям команды
/datum/atom_hud/alternate_appearance/basic/blood_mark
	var/datum/team/brother_team/team

/datum/atom_hud/alternate_appearance/basic/blood_mark/New(key, image/mark_image, datum/team/brother_team/marking_team)
	team = marking_team
	restyle(mark_image)
	..(key, mark_image, FALSE)
	RegisterSignal(team, COMSIG_PARENT_QDELETING, PROC_REF(expire))
	RegisterSignal(target, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_target_turned))
	RegisterSignal(target, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(on_target_posture))
	for(var/mob/living/body as anything in team.living_brothers())
		if(mobShouldSee(body))
			add_hud_to(body)
	addtimer(CALLBACK(src, PROC_REF(expire)), BROTHER_MARK_DURATION)

/datum/atom_hud/alternate_appearance/basic/blood_mark/Destroy()
	if(team)
		UnregisterSignal(team, COMSIG_PARENT_QDELETING)
		if(team.active_mark == src)
			team.active_mark = null
		team = null
	if(target)
		UnregisterSignal(target, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_LIVING_SET_BODY_POSITION))
	return ..()

/datum/atom_hud/alternate_appearance/basic/blood_mark/mobShouldSee(mob/viewer)
	var/datum/antagonist/brother/viewer_brother = viewer?.mind?.has_antag_datum(/datum/antagonist/brother)
	return viewer_brother && viewer_brother.team == team && viewer_brother.owner.current == viewer && !viewer_brother.is_muted()

/// Копия облика цели с обводкой; дальше по ней тянется только контур вокруг настоящего моба
/datum/atom_hud/alternate_appearance/basic/blood_mark/proc/restyle(image/mark_image, new_dir)
	var/atom/movable/marked = mark_image.loc
	mark_image.appearance = marked.appearance
	if(new_dir)
		mark_image.dir = new_dir
	mark_image.layer = marked.layer - BROTHER_MARK_LAYER_OFFSET
	mark_image.appearance_flags |= KEEP_TOGETHER
	mark_image.filters += filter(arglist(outline_filter(1, BROTHER_MARK_COLOR)))

/datum/atom_hud/alternate_appearance/basic/blood_mark/proc/on_target_turned(atom/movable/source, old_dir, new_dir)
	SIGNAL_HANDLER
	restyle(theImage, new_dir)

/// Сигнал положения тела идёт раньше нового transform: копию снимаем на следующем тике
/datum/atom_hud/alternate_appearance/basic/blood_mark/proc/on_target_posture(atom/movable/source)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(restyle), theImage), world.tick_lag)

/datum/atom_hud/alternate_appearance/basic/blood_mark/proc/expire()
	SIGNAL_HANDLER
	if(QDELETED(src))
		return
	target?.remove_alt_appearance(appearance_key)
	if(!QDELETED(src))
		qdel(src)

/// Чутьё к цели под Меткой крови
/datum/status_effect/brother_sense/blood_mark
	id = "brother_blood_mark"
	duration = BROTHER_MARK_DURATION
	tick_interval = BROTHER_SENSE_INTERVAL

/datum/status_effect/brother_sense/blood_mark/tick()
	refresh()

/datum/status_effect/brother_sense/blood_mark/refresh()
	if(!linked_alert || !tracked)
		return
	linked_alert.name = "Метка крови"
	linked_alert.color = BROTHER_MARK_COLOR
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(tracked.current)
	linked_alert.desc = "[tracked.name] под меткой. Где: [blood_bond_direction_text(here, there) || "не понять"]."
	point_alert(here, there)

/datum/team/brother_team
	var/datum/atom_hud/alternate_appearance/basic/blood_mark/active_mark

/datum/team/brother_team/proc/mark_target(mob/living/marked)
	var/key = "blood_mark_[REF(src)]"
	marked.remove_alt_appearance(key)
	active_mark = new /datum/atom_hud/alternate_appearance/basic/blood_mark(key, image(loc = marked), src)
	if(GET_CLIENT(marked))
		to_chat(marked, span_warning("Затылок холодеет: кто-то не сводит с вас глаз."))
	for(var/mob/living/body as anything in living_brothers())
		var/datum/antagonist/brother/body_brother = body.mind?.has_antag_datum(/datum/antagonist/brother)
		if(!body_brother || body_brother.is_muted())
			continue
		body.remove_status_effect(/datum/status_effect/brother_sense/blood_mark)
		body.apply_status_effect(/datum/status_effect/brother_sense/blood_mark, marked.mind)
		to_chat(body, span_cultitalic("Метка крови легла на [marked.mind.name]."))

/datum/action/cooldown/blood_bond/capstone/stash
	name = "Схрон крови"
	desc = "Общий карман братьев на 5 предметов не больше обычного размера. Открыть его может любой брат, со стороны его не видно. Диск ядерной аутентификации и ничего живого туда не спрятать. Если братьев не останется или венец пропадёт, вещи высыплются под ноги тому, кто открывал карман последним."
	bond_how = "Нажать кнопку, чтобы открыть или закрыть карман. Класть и брать - как в рюкзаке."
	button_icon_state = "stash"

/datum/action/cooldown/blood_bond/capstone/stash/Activate(atom/target)
	return brother.team.open_stash(owner)

/// Держатель Схрона крови: живёт в nullspace и переезжает в открывшего брата, пока у того открыто окно
/obj/item/storage/blood_stash
	name = "blood stash"
	desc = "Общий тайник кровных братьев."
	item_flags = ABSTRACT
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	component_type = /datum/component/storage/concrete/blood_stash

/datum/component/storage/concrete/blood_stash
	max_items = BROTHER_STASH_MAX_ITEMS
	max_w_class = WEIGHT_CLASS_NORMAL
	max_combined_w_class = BROTHER_STASH_MAX_ITEMS * WEIGHT_CLASS_NORMAL
	silent = TRUE
	rustle_sound = FALSE
	/// ui_show() сам зовёт ui_hide() перед показом: в это время схрон остаётся у брата
	var/showing = FALSE

/datum/component/storage/concrete/blood_stash/Initialize()
	. = ..()
	var/static/list/stash_cant_hold = typecacheof(list(/obj/item/disk/nuclear))
	cant_hold = stash_cant_hold

/datum/component/storage/concrete/blood_stash/can_be_inserted(obj/item/I, stop_messages = FALSE, mob/M)
	if(istype(I) && (locate(/mob) in I.GetAllContents()))
		if(!stop_messages)
			to_chat(M, span_warning("Живое в схрон не спрятать."))
		return FALSE
	return ..()

/datum/component/storage/concrete/blood_stash/ui_show(mob/M)
	showing = TRUE
	. = ..()
	showing = FALSE

/datum/component/storage/concrete/blood_stash/ui_hide(mob/M, client/leaving_client)
	. = ..()
	var/obj/item/stash = parent
	if(!showing && !LAZYLEN(is_using) && !QDELETED(stash) && stash.loc)
		stash.moveToNullspace()

/datum/team/brother_team
	/// Разум брата, открывавшего Схрон крови последним
	var/datum/mind/stash_last_user

/datum/team/brother_team/proc/open_stash(mob/living/user)
	if(abandoned || (user.mind in departed_minds))
		user.balloon_alert(user, "схрона больше нет")
		return FALSE
	if(QDELETED(stash))
		stash = new /obj/item/storage/blood_stash(null)
	var/datum/component/storage/storage = stash.GetComponent(/datum/component/storage)
	if(user in storage.is_using)
		storage.close(user)
		return TRUE
	stash_last_user = user.mind
	storage.close_all()
	stash.forceMove(user)
	storage.user_show_to_mob(user, TRUE)
	if(!(user in storage.is_using))
		stash.moveToNullspace()
	log_game("Blood brother [key_name(user)] of [name] opened the blood stash.")
	return TRUE

/// Закрыть окно Схрона у брата, который ушёл, заглушён или сменил тело
/datum/team/brother_team/proc/close_stash(mob/living/viewer)
	if(stash && viewer)
		SEND_SIGNAL(stash, COMSIG_TRY_STORAGE_HIDE_FROM, viewer)

/// Высыпать Схрон под ноги открывавшему последним, иначе первому живому брату, иначе ушедшему последним
/datum/team/brother_team/proc/dump_stash()
	if(QDELETED(stash))
		stash = null
		return
	var/list/candidates = list(stash_last_user?.current) + living_brothers()
	for(var/departed_index in length(departed_minds) to 1 step -1)
		var/datum/mind/departed = departed_minds[departed_index]
		candidates += departed.current
	var/atom/drop_spot
	for(var/mob/living/body in candidates)
		if(!QDELETED(body) && get_turf(body))
			drop_spot = body.drop_location()
			break
	var/datum/component/storage/storage = stash.GetComponent(/datum/component/storage)
	storage.close_all()
	if(drop_spot)
		for(var/obj/item/stashed in stash)
			storage.remove_from_storage(stashed, drop_spot)
	log_game("Blood brothers [name] stash dumped at [drop_spot ? AREACOORD(drop_spot) : "nowhere"].")
	QDEL_NULL(stash)
	stash_last_user = null

/datum/action/cooldown/blood_bond/capstone/unshackle
	name = "Разрыв оков"
	desc = "Рвёт оковы на вас и на братьях на соседних клетках: стяжки, кабельные путы и болы лопаются, а наручники и капканы падают на пол."
	bond_how = "Нажать кнопку. Работает и в наручниках."
	button_icon_state = "unshackle"
	cooldown_time = 5 MINUTES
	required_mobility_flags = NONE

/datum/action/cooldown/blood_bond/capstone/unshackle/Activate(atom/target)
	var/list/freed = break_restraints()
	if(!length(freed))
		owner.balloon_alert(owner, "рвать нечего")
		return FALSE
	playsound(owner, 'sound/effects/snap.ogg', BROTHER_UNSHACKLE_VOLUME, TRUE)
	var/list/freed_keys = list()
	for(var/mob/living/body as anything in freed)
		freed_keys += "[key_name(body)] ([english_list(freed[body])])"
	spend("broke the restraints of [english_list(freed_keys)]")
	return TRUE

/// Сорвать оковы с себя и братьев на соседних клетках; возвращает освобождённый -> названия оков
/datum/action/cooldown/blood_bond/capstone/unshackle/proc/break_restraints()
	. = list()
	var/datum/team/brother_team/team = brother.team
	for(var/datum/antagonist/brother/kin as anything in team.brother_antags())
		var/mob/living/carbon/body = kin.owner.current
		if(!iscarbon(body) || (kin.owner in team.departed_minds) || kin.is_muted() || !(body.handcuffed || body.legcuffed))
			continue
		if(body != owner && !owner.Adjacent(body))
			continue
		var/obj/item/hand_restraint = body.handcuffed
		var/obj/item/leg_restraint = body.legcuffed
		body.uncuff()
		var/list/what_happened = list()
		var/list/restraint_names = list()
		if(hand_restraint)
			restraint_names += hand_restraint.name
			what_happened += snap_restraint(hand_restraint) ? "стяжки лопаются" : "наручники падают"
		if(leg_restraint)
			restraint_names += leg_restraint.name
			what_happened += snap_restraint(leg_restraint) ? "путы на ногах рвутся" : "оковы с ног падают"
		new /obj/effect/temp_visual/blood_brothers/unshackle_flash(get_turf(body))
		var/what_text = what_happened.Join(", ")
		body.visible_message(span_danger("Оковы на [body] рвутся изнутри: [what_text]!"), span_notice("Кровь брата рвёт оковы: [what_text]."))
		.[body] = restraint_names

/// Стяжки, кабель и болы рвутся; металлические оковы остаются целыми на полу
/datum/action/cooldown/blood_bond/capstone/unshackle/proc/snap_restraint(obj/item/restraint)
	var/static/list/brittle_restraints = typecacheof(list(/obj/item/restraints/handcuffs/cable, /obj/item/restraints/handcuffs/sinew, /obj/item/restraints/legcuffs/bola))
	if(!is_type_in_typecache(restraint, brittle_restraints))
		return FALSE
	qdel(restraint)
	return TRUE

/datum/action/cooldown/blood_bond/capstone/bulwark
	name = "Заслон"
	desc = "15 секунд половина ушибов и ожогов, которые получает выбранный сосед, ложится на вас - мимо вашей брони и стойкости. Пока Заслон держится, между вами тянется кровавая нить. Заслон спадает, если вы погибнете или отойдёте дальше 7 клеток."
	bond_how = "Встать рядом с тем, кого прикрыть, и нажать кнопку."
	button_icon_state = "bulwark"
	cooldown_time = 4 MINUTES

/datum/action/cooldown/blood_bond/capstone/bulwark/Activate(atom/target)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/neighbour in orange(1, owner))
		if(neighbour.stat != DEAD && !HAS_TRAIT(neighbour, TRAIT_BROTHER_BULWARK) && owner.Adjacent(neighbour))
			candidates += neighbour
	if(!length(candidates))
		owner.balloon_alert(owner, "рядом некого прикрыть")
		return FALSE
	var/mob/living/carbon/human/chosen = candidates[1]
	if(length(candidates) > 1)
		chosen = tgui_input_list(owner, "Кого прикрыть?", name, candidates)
		if(!chosen || QDELETED(src) || !IsAvailable() || !owner.Adjacent(chosen) || chosen.stat == DEAD)
			return FALSE
	var/mob/living/guard = owner
	if(!guard.apply_status_effect(/datum/status_effect/brother_bulwark, chosen))
		owner.balloon_alert(owner, "не выходит прикрыть")
		return FALSE
	to_chat(owner, span_notice("Вы прикрываете [chosen]: половина ран теперь ляжет на вас."))
	spend("shielded [key_name(chosen)]")
	return TRUE

/datum/status_effect/brother_bulwark
	id = "brother_bulwark"
	duration = BROTHER_BULWARK_DURATION
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/brother_bulwark
	on_remove_on_mob_delete = TRUE
	var/mob/living/carbon/human/protected
	/// Множители физиологии подзащитного поставлены этим эффектом
	var/shielding = FALSE
	/// Ушибы и ожоги подзащитного до удара, который сейчас проходит
	var/brute_before
	var/burn_before
	/// world.time снимка: снимок без пересчёта здоровья в тот же тик устарел
	var/snapshot_time
	var/datum/beam/thread
	/// Урон, переданный брату, не передаётся дальше по чужим Заслонам
	var/static/redirecting = FALSE

/datum/status_effect/brother_bulwark/on_creation(mob/living/new_owner, mob/living/carbon/human/new_protected)
	protected = new_protected
	return ..()

/datum/status_effect/brother_bulwark/on_apply()
	. = ..()
	if(!ishuman(protected) || protected == owner || QDELETED(protected) || HAS_TRAIT(protected, TRAIT_BROTHER_BULWARK))
		return FALSE
	ADD_TRAIT(protected, TRAIT_BROTHER_BULWARK, BLOOD_OATH_TRAIT)
	protected.physiology.brute_mod *= BROTHER_BULWARK_SHARE
	protected.physiology.burn_mod *= BROTHER_BULWARK_SHARE
	shielding = TRUE
	RegisterSignal(protected, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_protected_hit))
	RegisterSignal(protected, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_protected_health))
	RegisterSignal(protected, COMSIG_PARENT_QDELETING, PROC_REF(on_protected_gone))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_guard_stat))
	thread = owner.Beam(protected, "blood_thread", 'modular_bluemoon/icons/effects/blood_brothers.dmi', BROTHER_BULWARK_DURATION, BROTHER_BULWARK_RANGE + 1)

/datum/status_effect/brother_bulwark/on_remove()
	QDEL_NULL(thread)
	UnregisterSignal(owner, COMSIG_MOB_STATCHANGE)
	if(protected)
		UnregisterSignal(protected, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_CARBON_UPDATEHEALTH, COMSIG_PARENT_QDELETING))
		if(shielding)
			REMOVE_TRAIT(protected, TRAIT_BROTHER_BULWARK, BLOOD_OATH_TRAIT)
			if(protected.physiology)
				protected.physiology.brute_mod /= BROTHER_BULWARK_SHARE
				protected.physiology.burn_mod /= BROTHER_BULWARK_SHARE
	shielding = FALSE
	protected = null
	return ..()

/// Брат жив, связь не заглушена, подзащитный жив и рядом
/datum/status_effect/brother_bulwark/proc/holds()
	var/datum/antagonist/brother/guard = owner.mind?.has_antag_datum(/datum/antagonist/brother)
	return guard && !guard.is_muted() && owner.stat != DEAD && protected.stat != DEAD && brother_within(owner, protected, BROTHER_BULWARK_RANGE)

/datum/status_effect/brother_bulwark/proc/on_protected_hit(mob/living/carbon/human/source, damage, damagetype)
	SIGNAL_HANDLER
	if(redirecting || damage <= 0 || (damagetype != BRUTE && damagetype != BURN))
		return
	if(!holds())
		qdel(src)
		return
	brute_before = protected.getBruteLoss()
	burn_before = protected.getFireLoss()
	snapshot_time = world.time

/datum/status_effect/brother_bulwark/proc/on_protected_health(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	if(isnull(brute_before))
		return
	var/fresh = snapshot_time == world.time
	var/share_ratio = (1 - BROTHER_BULWARK_SHARE) / BROTHER_BULWARK_SHARE
	var/brute_taken = max(protected.getBruteLoss() - brute_before, 0) * share_ratio
	var/burn_taken = max(protected.getFireLoss() - burn_before, 0) * share_ratio
	brute_before = null
	burn_before = null
	if(!fresh)
		return
	var/mob/living/guard = owner
	redirecting = TRUE
	if(brute_taken > 0)
		guard.apply_damage(brute_taken, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	if(burn_taken > 0)
		guard.apply_damage(burn_taken, BURN, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	redirecting = FALSE

/datum/status_effect/brother_bulwark/proc/on_protected_gone(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/brother_bulwark/proc/on_guard_stat(mob/living/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat == DEAD)
		qdel(src)

/atom/movable/screen/alert/status_effect/brother_bulwark
	name = "Заслон"
	desc = "Половина ушибов и ожогов того, кого вы прикрываете, ложится на вас."
	icon = 'modular_bluemoon/icons/mob/blood_brothers/actions.dmi'
	icon_state = "bulwark"

/datum/action/cooldown/blood_bond/capstone/sign_eyes
	name = "Глаза знаков"
	desc = "До 10 секунд смотреть через любой целый знак братства, оставленный вашей командой. Шаг, любой урон, оглушение или падение с ног вернут взгляд в тело."
	bond_how = "Нажать кнопку и выбрать знак."
	button_icon_state = "sign_eyes"
	cooldown_time = 2 MINUTES
	var/atom/movable/viewed_sign
	var/view_timer
	/// Здоровье смотрящего с прошлого пересчёта: падение - урон, даже мимо apply_damage
	var/view_health
	var/static/list/disabling_signals = list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_UNCONSCIOUS, COMSIG_LIVING_STATUS_SLEEP)

/datum/action/cooldown/blood_bond/capstone/sign_eyes/Remove(mob/remove_from)
	end_view()
	return ..()

/datum/action/cooldown/blood_bond/capstone/sign_eyes/Activate(atom/target)
	var/list/choices = sign_choices()
	if(!length(choices))
		owner.balloon_alert(owner, "целых знаков нет")
		return FALSE
	var/atom/movable/sign = choices[choices[1]]
	if(length(choices) > 1)
		var/choice = tgui_input_list(owner, "Через какой знак смотреть?", name, choices)
		sign = choices[choice]
		if(!sign || QDELETED(src) || !IsAvailable() || QDELETED(sign) || !(sign in brother.team.signs))
			return FALSE
	start_view(sign)
	spend("looked through a brother sign at [AREACOORD(sign)]")
	return TRUE

/// Подписи «Зона» для выбора знака; одноимённые зоны нумеруются
/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/sign_choices()
	var/list/choices = list()
	for(var/atom/movable/sign as anything in brother.team.signs)
		if(QDELETED(sign) || !get_turf(sign))
			continue
		var/base_label = get_area_name(sign, TRUE)
		var/label = base_label
		var/copy = 1
		while(choices[label])
			copy++
			label = "[base_label] ([copy])"
		choices[label] = sign
	return choices

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/start_view(atom/movable/sign)
	viewed_sign = sign
	RegisterSignal(sign, COMSIG_PARENT_QDELETING, PROC_REF(on_view_broken))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_view_broken))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_viewer_hit))
	RegisterSignal(owner, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_viewer_health))
	RegisterSignals(owner, disabling_signals, PROC_REF(on_viewer_disabled))
	var/mob/living/viewer = owner
	view_health = viewer.health
	owner.reset_perspective(sign)
	view_timer = addtimer(CALLBACK(src, PROC_REF(end_view)), BROTHER_SIGN_EYES_DURATION, TIMER_STOPPABLE)
	to_chat(owner, span_cultitalic("Вы смотрите глазами знака: [get_area_name(sign, TRUE)]. Шаг, любой урон, оглушение или падение с ног вернут взгляд в тело."))

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/end_view()
	if(!viewed_sign)
		return
	deltimer(view_timer)
	view_timer = null
	UnregisterSignal(viewed_sign, COMSIG_PARENT_QDELETING)
	viewed_sign = null
	if(!owner)
		return
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_APPLY_DAMAGE, COMSIG_CARBON_UPDATEHEALTH) + disabling_signals)
	owner.reset_perspective(null)
	to_chat(owner, span_notice("Взгляд возвращается в тело."))

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/on_view_broken(datum/source)
	SIGNAL_HANDLER
	end_view()

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/on_viewer_hit(mob/living/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		end_view()

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/on_viewer_health(mob/living/source)
	SIGNAL_HANDLER
	if(source.health < view_health)
		end_view()
		return
	view_health = source.health

/datum/action/cooldown/blood_bond/capstone/sign_eyes/proc/on_viewer_disabled(mob/living/source, amount)
	SIGNAL_HANDLER
	if(amount > 0)
		end_view()

/datum/action/cooldown/blood_bond/capstone/blackout
	name = "Глушь"
	desc = "Свет в зоне, где вы стоите, мигает 3 секунды и гаснет на 20 секунд - только на вашей палубе. Лампы остаются целыми, а выключатель зажигает свет раньше."
	bond_how = "Нажать кнопку в нужной зоне."
	button_icon_state = "blackout"
	cooldown_time = 4 MINUTES

/datum/action/cooldown/blood_bond/capstone/blackout/Activate(atom/target)
	var/area/dark_area = get_area(owner)
	var/refusal = blood_bond_blackout_refusal(dark_area, owner.z)
	if(refusal)
		owner.balloon_alert(owner, refusal)
		return FALSE
	blood_bond_blackout_start(dark_area, owner.z)
	spend("blacked out [dark_area.type] on z[owner.z]")
	return TRUE

/// Лампы, которыми управляет Глушь: целые, без своего выключателя и на палубе z_level
/proc/blood_bond_blackout_lamps(area/dark_area, z_level)
	. = list()
	for(var/obj/machinery/light/lamp in dark_area)
		if(lamp.z == z_level && lamp.status == LIGHT_OK && isnull(lamp.individual_switch_state))
			. += lamp

/// Почему Глушь не берёт зону, или null
/proc/blood_bond_blackout_refusal(area/dark_area, z_level)
	if(!dark_area || !length(blood_bond_blackout_lamps(dark_area, z_level)))
		return "здесь нечего гасить"
	if(dark_area in GLOB.blood_bond_blackouts)
		return "свет здесь уже гаснет"
	if(!dark_area.lightswitch || !dark_area.power_light)
		return "здесь и так темно"
	return null

/// GLOB.blood_bond_blackouts: зона -> палуба, на которой гаснет свет
/proc/blood_bond_blackout_start(area/dark_area, z_level)
	GLOB.blood_bond_blackouts[dark_area] = z_level
	dark_area.lightswitch = FALSE
	blood_bond_blackout_switches(dark_area)
	blood_bond_blackout_step(dark_area, 1)

/// Шаг мерцания: нечётные гасят лампы, чётные зажигают, шаг после последнего - темнота до конца Глуши
/proc/blood_bond_blackout_step(area/dark_area, step)
	if(!(dark_area in GLOB.blood_bond_blackouts))
		return
	if(dark_area.lightswitch)
		blood_bond_blackout_end(dark_area)
		return
	var/dark = step > BROTHER_BLACKOUT_FLICKERS
	for(var/obj/machinery/light/lamp as anything in blood_bond_blackout_lamps(dark_area, GLOB.blood_bond_blackouts[dark_area]))
		lamp.on = !dark && ISEVEN(step)
		lamp.update(trigger = FALSE, silent = TRUE)
	if(dark)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(blood_bond_blackout_end), dark_area), BROTHER_BLACKOUT_DURATION)
		return
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(blood_bond_blackout_step), dark_area, step + 1), BROTHER_BLACKOUT_FLICKER_TIME / BROTHER_BLACKOUT_FLICKERS)

/proc/blood_bond_blackout_end(area/dark_area)
	if(!(dark_area in GLOB.blood_bond_blackouts))
		return
	var/z_level = GLOB.blood_bond_blackouts[dark_area]
	GLOB.blood_bond_blackouts -= dark_area
	dark_area.lightswitch = TRUE
	for(var/obj/machinery/light/lamp as anything in blood_bond_blackout_lamps(dark_area, z_level))
		lamp.on = lamp.has_power()
		lamp.update(trigger = FALSE, silent = TRUE)
	blood_bond_blackout_switches(dark_area)

/proc/blood_bond_blackout_switches(area/dark_area)
	dark_area.update_appearance()
	for(var/obj/machinery/light_switch/light_switch in dark_area)
		light_switch.update_appearance()

/datum/team/brother_team
	/// Тела братьев, чьи раны слушает Круг троих
	var/list/mob/living/circle_watched = list()
	/// world.time последней раны кого-то из круга
	var/circle_hit_at = 0

/// Венцы исполненных клятв и венец данной: у первой - с высшей ступенью, у следующих - с последней печатью
/datum/team/brother_team/proc/earned_capstones()
	. = list()
	for(var/datum/blood_oath/fulfilled as anything in fulfilled_oaths)
		if(fulfilled.capstone_type)
			. |= fulfilled.capstone_type
	if(oath?.capstone_type && bond_tier >= BLOOD_BOND_TIER_MAX && (!length(fulfilled_oaths) || !oath.current_step()))
		. |= oath.capstone_type

/datum/team/brother_team/proc/holds_capstone(capstone_type)
	return capstone_type in earned_capstones()

/datum/team/brother_team/proc/capstone_tick()
	if(stash && !holds_capstone(/datum/action/cooldown/blood_bond/capstone/stash))
		dump_stash()
	if(!holds_capstone(/datum/blood_bond_passive/circle))
		watch_circle(list())
		return
	var/list/mob/living/bodies = list()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/mob/living/body = brother.owner.current
		if(!(brother.owner in departed_minds) && isliving(body) && !QDELETED(body))
			bodies += body
	watch_circle(bodies)
	circle_tick()

/// Слушать раны этих тел; тело, которое круг видит впервые, считается только что раненым
/datum/team/brother_team/proc/watch_circle(list/mob/living/bodies)
	for(var/mob/living/stale as anything in circle_watched - bodies)
		UnregisterSignal(stale, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_PARENT_QDELETING))
	for(var/mob/living/fresh as anything in bodies - circle_watched)
		RegisterSignal(fresh, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_circle_hit))
		RegisterSignal(fresh, COMSIG_PARENT_QDELETING, PROC_REF(on_circle_body_deleted))
		circle_hit_at = world.time
	circle_watched = bodies

/datum/team/brother_team/proc/on_circle_hit(mob/living/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		circle_hit_at = world.time

/datum/team/brother_team/proc/on_circle_body_deleted(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_PARENT_QDELETING))
	circle_watched -= source

/// Круг троих: все трое живы, не при смерти, не заглушены, попарно рядом и давно не ранены - каждый лечится
/datum/team/brother_team/proc/circle_tick()
	var/list/mob/living/circle = list()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		if(brother.owner in departed_minds)
			continue
		var/mob/living/body = brother.owner.current
		if(brother.is_muted() || !isliving(body) || QDELETED(body) || body.stat == DEAD || body.InCritical())
			return FALSE
		circle += body
	if(length(circle) < BROTHER_TEAM_MAX_SIZE || world.time - circle_hit_at < BROTHER_CIRCLE_QUIET_TIME)
		return FALSE
	for(var/first_index in 1 to length(circle) - 1)
		for(var/second_index in first_index + 1 to length(circle))
			if(!brother_within(circle[first_index], circle[second_index], BROTHER_CIRCLE_RANGE))
				return FALSE
	for(var/mob/living/body as anything in circle)
		body.heal_overall_damage(BROTHER_CIRCLE_HEAL, BROTHER_CIRCLE_HEAL)
	return TRUE
