#define HERETIC_LEAD_NAMED_DAMAGE 3
#define HERETIC_LEAD_NAMED_SPEED 5
#define HERETIC_LEAD_JAM_NOTICE (1 SECONDS)
#define HERETIC_LEAD_PATINA_KEY "heretic_lead_patina"
#define HERETIC_LEAD_RECALL_TRACE (0.4 SECONDS)
#define HERETIC_LEAD_PATINA_HOT "#760c12b0"
#define HERETIC_LEAD_PATINA_DIM "#4a070b50"
#define HERETIC_LEAD_PATINA_PULSE (1.2 SECONDS)
#define HERETIC_LEAD_RECALL_HALLOW (1 MINUTES)

/// Боевой огнестрел и магазины к нему, которые берёт заговор: внутренний барабан ружья заговаривают вместе с ружьём, игрушки - никогда.
/proc/heretic_lead_curseable(atom/target)
	if(istype(target, /obj/item/gun/ballistic))
		return !istype(target, /obj/item/gun/ballistic/revolver/russian) && heretic_lead_ballistic_type(heretic_lead_gun_projectile(target))
	if(!istype(target, /obj/item/ammo_box) || istype(target, /obj/item/ammo_box/magazine/internal))
		return FALSE
	var/obj/item/ammo_box/box = target
	return heretic_lead_casing_lethal(box.ammo_type)

/// Свинцовую патину различают детектив, капеллан и еретики.
/proc/heretic_lead_sees_patina(mob/user)
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return TRUE
	return (user?.mind?.assigned_role in list("Detective", "Chaplain"))

/// Картинка патины поверх заговорённого оружия: её получают только те, кто различает свинцовый заговор, в том числе пришедшие позже.
/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina

/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/New(key, image/I)
	..(key, I, FALSE)
	for(var/mob/viewer as anything in GLOB.alive_mob_list | GLOB.dead_mob_list)
		if(mobShouldSee(viewer))
			add_hud_to(viewer)
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_spawn))

/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN)
	return ..()

/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/mobShouldSee(mob/viewer)
	return viewer?.mind && heretic_lead_sees_patina(viewer)

/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/proc/on_job_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	if(mobShouldSee(spawned) && !hudusers[spawned])
		add_hud_to(spawned)

/// Получивший или потерявший право видеть патину (роль еретика или слуги, новое тело) видит её сразу, без нового входа в игру.
/proc/heretic_lead_refresh_patina(mob/viewer)
	if(istype(viewer, /datum/weakref))
		var/datum/weakref/viewer_ref = viewer
		viewer = viewer_ref.resolve()
	if(QDELETED(viewer))
		return
	for(var/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/patina in GLOB.active_alternate_appearances)
		var/sees = patina.mobShouldSee(viewer)
		if(sees && !patina.hudusers[viewer])
			patina.add_hud_to(viewer)
		else if(!sees && patina.hudusers[viewer])
			patina.remove_hud_from(viewer, TRUE)

/// Роль снимается после remove_innate_effects: право видеть пересчитывается на следующем тике.
/proc/heretic_lead_refresh_patina_later(mob/viewer)
	if(viewer)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_refresh_patina), WEAKREF(viewer)), 1)

/// Заговор Свинца: выстрел не-еретика даёт осечку и клинит ствол; магазин или коробка передают заговор оружию, которое ими зарядили.
/datum/component/heretic_lead_curse
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/lead_ref
	var/charges = HERETIC_LEAD_CURSE_CHARGES
	/// Заговор Хваткой идёт в дело пути и в предел заговоров; Сглаз - нет.
	var/crafted = TRUE
	var/jam_until = 0
	var/spent = FALSE
	var/expire_timer
	COOLDOWN_DECLARE(jam_notice)

/datum/component/heretic_lead_curse/Initialize(datum/eldritch_knowledge/base_lead/lead, charges = HERETIC_LEAD_CURSE_CHARGES, crafted = TRUE, lifetime)
	if(!heretic_lead_curseable(parent) || !istype(lead))
		return COMPONENT_INCOMPATIBLE
	// Дубль при COMPONENT_DUPE_UNIQUE создаётся и сразу удаляется: он не трогает вещь и знание.
	if(parent.GetComponent(/datum/component/heretic_lead_curse))
		return
	lead_ref = WEAKREF(lead)
	src.charges = charges
	src.crafted = crafted
	if(crafted)
		lead.curses += src
	if(lifetime)
		expire_timer = addtimer(CALLBACK(src, PROC_REF(expire)), lifetime, TIMER_STOPPABLE)
	var/obj/item/item = parent
	RegisterSignal(item, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(item, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(item, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	if(istype(item, /obj/item/gun))
		RegisterSignal(item, COMSIG_GUN_TRY_FIRE, PROC_REF(on_try_fire))
	else
		RegisterSignal(item, COMSIG_ITEM_PRE_ATTACK, PROC_REF(on_load))
	RegisterSignal(item, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	show_patina(item)

/datum/component/heretic_lead_curse/Destroy(force, silent)
	deltimer(expire_timer)
	expire_timer = null
	var/obj/item/item = parent
	if(lead_ref && item)
		UnregisterSignal(item, list(COMSIG_PARENT_EXAMINE, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_GUN_TRY_FIRE, COMSIG_ITEM_PRE_ATTACK, COMSIG_MOVABLE_MOVED))
		hide_patina(item)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.on_curse_removed(src)
	lead_ref = null
	return ..()

/// Патина: металл тускнеет до матового свинца, по краю тлеет багровый кант. Видят её только детектив, капеллан и еретики, остальным оружие кажется обычным.
/datum/component/heretic_lead_curse/proc/show_patina(obj/item/item)
	var/image/patina = image(item.icon, item, item.icon_state)
	patina.override = TRUE
	patina.dir = item.dir
	patina.copy_overlays(item)
	patina.filters += filter(type = "color", color = list(0.62, 0.13, 0.14, 0.24, 0.77, 0.27, 0.05, 0.05, 0.6))
	patina.filters += filter(type = "outline", size = 1, color = HERETIC_LEAD_PATINA_DIM, flags = OUTLINE_SHARP)
	animate(patina.filters[2], color = HERETIC_LEAD_PATINA_HOT, time = HERETIC_LEAD_PATINA_PULSE, loop = -1, easing = SINE_EASING)
	animate(color = HERETIC_LEAD_PATINA_DIM, time = HERETIC_LEAD_PATINA_PULSE, easing = SINE_EASING)
	item.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina, HERETIC_LEAD_PATINA_KEY, patina)
	LAZYADD(item.update_on_z, patina)
	place_patina(item)
	RegisterSignal(item, COMSIG_ATOM_UPDATED_ICON, PROC_REF(refresh_patina))
	RegisterSignals(item, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED), PROC_REF(place_patina))

/datum/component/heretic_lead_curse/proc/patina_hud(obj/item/item)
	return LAZYACCESS(item?.alternate_appearances, HERETIC_LEAD_PATINA_KEY)

/// Оружие сменило облик (магазин, затвор): картинка патины повторяет его.
/datum/component/heretic_lead_curse/proc/refresh_patina(obj/item/source)
	SIGNAL_HANDLER
	var/datum/atom_hud/alternate_appearance/basic/hud = patina_hud(source)
	var/image/patina = hud?.theImage
	if(!patina)
		return
	patina.icon = source.icon
	patina.icon_state = source.icon_state
	patina.dir = source.dir
	patina.copy_overlays(source, TRUE)

/// У картинки-подмены плавающие слой и плоскость берутся не от ствола, и патина рисовалась поверх стоящих на стволе людей.
/// Поэтому они явные: на полу как у самого ствола (этаж мульти-Z ведёт update_on_z), в руке, слоте и открытой сумке - поверх интерфейса, как и сам предмет.
/datum/component/heretic_lead_curse/proc/place_patina(obj/item/source)
	SIGNAL_HANDLER
	var/datum/atom_hud/alternate_appearance/basic/hud = patina_hud(source)
	var/image/patina = hud?.theImage
	if(!patina)
		return
	if(isturf(source.loc))
		patina.layer = source.layer
		patina.plane = source.plane
	else
		patina.layer = ABOVE_HUD_LAYER
		patina.plane = ABOVE_HUD_PLANE

/datum/component/heretic_lead_curse/proc/hide_patina(obj/item/item)
	if(!item)
		return
	UnregisterSignal(item, list(COMSIG_ATOM_UPDATED_ICON, COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED))
	var/datum/atom_hud/alternate_appearance/basic/hud = patina_hud(item)
	LAZYREMOVE(item.update_on_z, hud?.theImage)
	item.remove_alt_appearance(HERETIC_LEAD_PATINA_KEY)

/datum/component/heretic_lead_curse/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(spent || !heretic_lead_sees_patina(user))
		return
	var/datum/atom_hud/alternate_appearance/basic/heretic_lead_patina/hud = patina_hud(source)
	if(hud && !hud.hudusers[user])
		hud.add_hud_to(user)
	if(IS_HERETIC(user))
		examine_list += span_eldritch("Свинцовый заговор[crafted ? "" : " Сглаза"]: осечек осталось [charges]. Нулевой жезл или святая вода его снимут.")
		return
	if(get_dist(user, source) > 1)
		return
	examine_list += span_warning("На металле тусклая свинцовая патина, холодная на ощупь: оружие заговорено и даст осечку, а того, у кого уже дважды осекалось, может подстрелить. Нулевой жезл или святая вода снимут заговор.")

/datum/component/heretic_lead_curse/proc/on_attackby(atom/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	cleanse(user, "нулевым жезлом")
	return COMPONENT_NO_AFTERATTACK

/datum/component/heretic_lead_curse/proc/on_exposed(atom/source, list/exposed, datum/reagents/holder, method)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in exposed)
		if(istype(reagent, /datum/reagent/water/holywater))
			cleanse(null, "святой водой")
			return

/datum/component/heretic_lead_curse/proc/cleanse(mob/living/user, how)
	var/atom/item = parent
	if(user)
		user.visible_message(span_warning("[user] касается [item] [how], и свинцовая патина осыпается серой пылью."), span_notice("Вы касаетесь [item] [how], и свинцовая патина осыпается: заговор снят."))
	else
		item.visible_message(span_warning("Свинцовая патина на [item] шипит и осыпается серой пылью."))
	log_game("[user ? key_name(user) : "Святая вода"] снимает заговор Свинца с [item] ([item.type]) [how] в [AREACOORD(item)].")
	heretic_craft_dispel_fx(item, lead_ref?.resolve())
	qdel(src)

/datum/component/heretic_lead_curse/proc/expire()
	expire_timer = null
	qdel(src)

/// Выстрел не-еретика: осечка, шёпот и ствол заклинило; заклинивание переживает последнюю осечку.
/datum/component/heretic_lead_curse/proc/on_try_fire(obj/item/gun/source, mob/living/user, atom/target)
	SIGNAL_HANDLER
	if(!isliving(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	if(world.time < jam_until)
		if(COOLDOWN_FINISHED(src, jam_notice))
			COOLDOWN_START(src, jam_notice, HERETIC_LEAD_JAM_NOTICE)
			to_chat(user, span_warning("[source] заклинило: курок не поддаётся."))
			source.balloon_alert(user, "заклинило")
		return COMPONENT_CANCEL_GUN_FIRE
	if(spent)
		return NONE
	charges--
	jam_until = world.time + HERETIC_LEAD_JAM_TIME
	COOLDOWN_START(src, jam_notice, HERETIC_LEAD_JAM_NOTICE)
	heretic_lead_sound(source, "misfire", 50, TRUE)
	source.balloon_alert(user, "осечка!")
	user.visible_message(span_warning("[source] в руках [user] сухо щёлкает вместо выстрела!"), span_userdanger("Осечка! Из ствола [source] доносится чужой шёпот: «Не твоя пуля». Курок заклинило на [HERETIC_LEAD_JAM_TIME / (1 SECONDS)] секунды."))
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.on_misfire(source, user, crafted)
	if(charges <= 0 && !QDELETED(src))
		spend()
	return COMPONENT_CANCEL_GUN_FIRE

/// Последняя осечка: заговор больше не держит слот и не видна патина, но ствол клинит до конца заклинивания.
/datum/component/heretic_lead_curse/proc/spend()
	spent = TRUE
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.on_curse_removed(src)
	hide_patina(parent)
	deltimer(expire_timer)
	expire_timer = addtimer(CALLBACK(src, PROC_REF(expire)), max(1, jam_until - world.time), TIMER_STOPPABLE)

/datum/component/heretic_lead_curse/proc/on_load(obj/item/source, atom/target, mob/user, params)
	SIGNAL_HANDLER
	if(target != source && heretic_lead_curseable(target))
		transfer(target)

/datum/component/heretic_lead_curse/proc/on_moved(obj/item/source, atom/old_loc)
	SIGNAL_HANDLER
	place_patina(source)
	if(!istype(source, /obj/item/gun) && istype(source.loc, /obj/item/gun/ballistic))
		transfer(source.loc)

/// Магазином или коробкой зарядили оружие: заговор уходит в него.
/datum/component/heretic_lead_curse/proc/transfer(obj/item/receiver)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(spent || !lead || QDELETED(receiver) || receiver.GetComponent(/datum/component/heretic_lead_curse))
		return FALSE
	var/lifetime = expire_timer ? timeleft(expire_timer) : null
	var/datum/component/heretic_lead_curse/moved = receiver.AddComponent(/datum/component/heretic_lead_curse, lead, charges, crafted, lifetime)
	if(QDELETED(moved))
		return FALSE
	log_game("Заговор Свинца переходит с [parent] на [receiver] ([receiver.type]) в [AREACOORD(receiver)].")
	qdel(src)
	return TRUE

/obj/item/heretic_path_relic/lead_revolver
	name = "Mansus six-shooter"
	desc = "Тяжёлый револьвер с длинным гранёным стволом в латунных бандажах и красной мушкой. Барабан из тусклого свинца, на тёмной рукояти выжжено красное перекрестие, а с неё свисает латунный шнур с пулей-оберегом. В барабане шесть камор, на донце каждой своя метка, а патронов нет: каморы подряд от курка заряжает Свинец хозяина, единица на камору. Свинцовая бьёт на 35 ушибов и пробивает броню, Тяжёлая валит с ног, Меченая вешает Мишень, Пороховая поджигает, Звонкая рикошетит в соседа, а Шестая, взведённая Alt-кликом при полном барабане, уходит в человека Последним патроном: 1,5 секунды к цели тянется красная линия и горит прицел на груди, затем пуля на 45 ушибов. Попадание в живого врага возвращает единицу Свинца, а убитый человек - ещё три; опустевший барабан за секунду дозаряжается из патронташа хозяина, а без Свинца щёлкает вхолостую. Вплотную хозяин бьёт им наотмашь: тяжёлая рукоять оставляет 20 ушибов и сбивает шаг. Не-еретик, нажавший на спуск, получает пулю в ногу, а чужой еретик не выстрелит вовсе. Потерянный револьвер кнопка «Призвать Шестизарядник» за секунду возвращает в свободную руку хозяина за единицу Свинца, а из его кармана или сумки - даром. Нулевой жезл в руке держащего или святая вода на металле удержат револьвер."
	icon = 'modular_bluemoon/icons/obj/heretic_lead.dmi'
	icon_state = "lead_revolver"
	item_state = "lead_revolver"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_lead_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_lead_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	COOLDOWN_DECLARE(shot_cooldown)
	COOLDOWN_DECLARE(butt_cooldown)

/obj/item/heretic_path_relic/lead_revolver/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(user.a_intent != INTENT_HARM || target == user || !authorized(user) || !lead?.can_use(user))
		return ..()
	return pistol_whip(target, user, lead)

/// Удар рукоятью вплотную: ушибы, сбитый шаг и единица Свинца, раз в секунду.
/obj/item/heretic_path_relic/lead_revolver/proc/pistol_whip(mob/living/target, mob/living/user, datum/eldritch_knowledge/base_lead/lead)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("Вы не хотите никого ранить."))
		return FALSE
	if(!COOLDOWN_FINISHED(src, butt_cooldown))
		balloon_alert(user, "рукоять ещё не готова")
		return FALSE
	COOLDOWN_START(src, butt_cooldown, HERETIC_LEAD_BUTT_COOLDOWN)
	user.do_attack_animation(target)
	var/was_alive = target.stat != DEAD
	var/zone = check_zone(user.zone_selected)
	target.apply_damage(HERETIC_LEAD_BUTT_DAMAGE, BRUTE, zone, target.run_armor_check(zone, MELEE, silent = TRUE))
	playsound(target, 'sound/weapons/genhit3.ogg', 50, TRUE)
	lead.mark_combat()
	user.visible_message(span_danger("[user] бьёт [target] рукоятью [src]!"), span_notice("Вы бьёте [target] тяжёлой рукоятью."), null, COMBAT_MESSAGE_RANGE)
	log_combat(user, target, "бьёт рукоятью Шестизарядника", src)
	if(QDELETED(target) || !was_alive || IS_HERETIC(target) || IS_HERETIC_MONSTER(target))
		return TRUE
	target.apply_status_effect(/datum/status_effect/heretic_lead_slowed/butt)
	lead.gain_combat_resource()
	SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "butt", target)
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(QDELETED(target) || target == user || (target in user.contents))
		return
	if(proximity_flag && (!ismob(target) || user.a_intent == INTENT_HARM))
		return
	fire_at(target, user, click_parameters)

/// Настоящая причина, по которой револьвер не слушается, или null: чужой разум, рука, шкаф, захват, оглушение.
/obj/item/heretic_path_relic/lead_revolver/proc/use_block_reason(mob/living/user)
	if(!isliving(user) || !user.mind || user.mind != creator?.resolve())
		return "настроен на чужой разум"
	var/datum/eldritch_knowledge/knowledge = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(!lead || !knowledge || heretic?.get_knowledge(knowledge.type) != knowledge)
		return "Свинец вам больше не отвечает"
	if(!user.is_holding(src))
		return "возьмите его в руку"
	if(!isturf(user.loc))
		return "отсюда не выстрелить, выберитесь наружу"
	if(heretic_incapacitated(user))
		return heretic_lead_incapacity(user)
	if(!lead.can_use(user))
		return "Свинец не отвечает этому телу"
	return null

/proc/heretic_lead_incapacity(mob/living/user)
	if(user.stat == DEAD)
		return "вы мертвы"
	if(user.stat || user.IsUnconscious())
		return "вы без сознания"
	if(user.restrained(TRUE))
		return "руки скованы"
	if(user.restrained())
		return "вас держат в захвате, вырвитесь"
	if(IS_IN_STASIS(user))
		return "вас держит стазис"
	if(user.IsStun() || user.IsParalyzed())
		return "вы оглушены"
	if(user.combat_flags & COMBAT_FLAG_HARD_STAMCRIT)
		return "вы выбились из сил"
	return "вы не можете действовать"

/// Щелчок по цели: мгновенный выстрел Стрелка, Последний патрон, прицельный выстрел, веер или пуля из каморы под курком.
/obj/item/heretic_path_relic/lead_revolver/proc/fire_at(atom/target, mob/living/user, params)
	if(!isliving(user) || !user.is_holding(src) || !COOLDOWN_FINISHED(src, shot_cooldown))
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	COOLDOWN_START(src, shot_cooldown, lead ? lead.shot_delay() : CLICK_CD_RANGE)
	if(!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		return backfire(user)
	var/reason = use_block_reason(user)
	if(reason)
		return refuse(user, reason)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("Вы не хотите никого ранить."))
		return FALSE
	if(drum_busy())
		balloon_alert(user, "курок уже взведён")
		return FALSE
	if(!COOLDOWN_FINISHED(src, fan_lockout))
		balloon_alert(user, "ствол горячий после веера")
		return FALSE
	if(!COOLDOWN_FINISHED(src, drum_turn))
		balloon_alert(user, "барабан проворачивается")
		return FALSE
	// Мгновенные выстрелы Стрелка идут раньше Шестой каморы: Мгновение не ждёт полторы секунды прицела.
	if(lead.standoff_shot_ready() && isliving(target) && (lead.combat_resource || lead.crucible_shot()))
		lead.mark_combat()
		lead.standoff_shots--
		lead.notify_resource_changed()
		return shoot_round(target, user, params, lead, aimed = TRUE)
	if(lead.drum_style != HERETIC_LEAD_STYLE_FAN && lead.sixth_cocked() && heretic_lead_last_round_target(target, user))
		lead.mark_combat()
		return start_last_round(target, user)
	if(!lead.combat_resource && (lead.drum_style == HERETIC_LEAD_STYLE_FAN || !lead.crucible_shot()))
		return click_empty(user)
	lead.mark_combat()
	if(lead.drum_style == HERETIC_LEAD_STYLE_FAN)
		return start_fan(target, user, lead)
	if(lead.drum_style == HERETIC_LEAD_STYLE_AIMED && heretic_lead_aim_target(target, user, lead.aim_range()))
		return start_focus(target, user)
	return shoot_round(target, user, params, lead)

/obj/item/heretic_path_relic/lead_revolver/proc/click_empty(mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead(user)
	if(lead?.bandolier > 0)
		lead.check_reload()
		balloon_alert(user, "дозарядка")
		return FALSE
	heretic_lead_sound(src, "empty", 40, TRUE)
	balloon_alert(user, "барабан пуст")
	to_chat(user, span_warning("Щёлк: в барабане и патронташе ни крупицы Свинца. Его вернут попадания, удары клинком и рукоятью, гильзы и металл под Хваткой, пули рядом, а вне боя он сам копится до [HERETIC_LEAD_RESERVE_CAP]."))
	return FALSE

/// Пуля из каморы под курком; барабан затем проворачивается к следующей.
/obj/item/heretic_path_relic/lead_revolver/proc/shoot_round(atom/target, mob/living/user, params, datum/eldritch_knowledge/base_lead/lead, aimed = FALSE, fan = FALSE, free = FALSE)
	var/round_type = free ? /obj/item/projectile/bullet/heretic_lead : lead.chamber_round(lead.drum_hammer)
	var/lucky = !free && lead.drum_lucky
	if(!free && !lead.crucible_shot() && !lead.spend_combat_resource())
		return click_empty(user)
	var/obj/item/projectile/bullet/heretic_lead/bullet = new round_type(get_turf(user))
	bullet.firer = user
	bullet.fired_from = src
	bullet.lead_ref = WEAKREF(lead)
	bullet.armour_penetration += lead.sacrifice_penetration()
	var/bonus = 100
	if(lucky)
		bonus += HERETIC_LEAD_LUCK_BONUS
	if(aimed)
		bonus += HERETIC_LEAD_AIM_BONUS
		bullet.armour_penetration += HERETIC_LEAD_AIM_PENETRATION
	if(fan)
		bonus *= HERETIC_LEAD_FAN_DAMAGE / 100
	bullet.damage *= bonus / 100
	bullet.def_zone = fan ? BODY_ZONE_CHEST : check_zone(user.zone_selected)
	bullet.preparePixelProjectile(target, user, (user.client && !fan) ? params : null, fan ? rand(-HERETIC_LEAD_FAN_SPREAD, HERETIC_LEAD_FAN_SPREAD) : 0)
	if(QDELETED(bullet))
		return FALSE
	if(!fan)
		lead.assist_aim(bullet)
	lead.school_tracer(bullet)
	bullet.fire(null, (isliving(target) && get_dist(user, target) <= 1) ? target : null)
	lead.advance_drum()
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(get_turf(user))
	flash.setDir(get_dir(user, target))
	heretic_lead_sound(src, "shot", 60, TRUE)
	heretic_lead_drop_casing(get_turf(user), null, 25)
	if(aimed)
		user.visible_message(span_danger("[user] спускает курок [src] точно в [target]!"), null, null, COMBAT_MESSAGE_RANGE)
		log_combat(user, target, "стреляет прицельным выстрелом Шестизарядника ([bullet.round_name]) в", src)
	else
		user.visible_message(span_danger("[user] стреляет из [src]!"), null, null, COMBAT_MESSAGE_RANGE)
	user.changeNext_move(lead.shot_delay())
	return bullet

/// Чужие пальцы на спуске: револьвер выворачивается и стреляет держащему в ногу.
/obj/item/heretic_path_relic/lead_revolver/proc/backfire(mob/living/user)
	var/leg = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		human_user.apply_damage(HERETIC_LEAD_REVOLVER_DAMAGE, BRUTE, leg)
	else
		user.adjustBruteLoss(HERETIC_LEAD_REVOLVER_DAMAGE)
	heretic_lead_sound(src, "shot", 60, TRUE)
	user.dropItemToGround(src, TRUE)
	user.visible_message(span_danger("[src] выворачивается из пальцев [user] и стреляет [user.ru_emu()] в ногу!"), span_userdanger("Револьвер выворачивается из пальцев и стреляет вам в ногу!"))
	log_combat(user, user, "получает пулю в ногу от", src)
	return FALSE

/datum/eldritch_knowledge/lead_relic
	var/obj/effect/proc_holder/spell/self/heretic_lead/recall/recall_power

/datum/eldritch_knowledge/lead_relic/on_body_gain(mob/living/user)
	. = ..()
	if(user?.mind && QDELETED(recall_power))
		recall_power = new
		user.mind.AddSpell(recall_power)

/datum/eldritch_knowledge/lead_relic/on_body_lose(mob/living/user)
	QDEL_NULL(recall_power)
	return ..()

/datum/eldritch_knowledge/lead_relic/Destroy()
	QDEL_NULL(recall_power)
	return ..()

/datum/eldritch_knowledge/base_lead
	var/recall_timer

/datum/eldritch_knowledge/base_lead/proc/own_revolver()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic?.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = recipe?.new_path_relic_ref?.resolve()
	return QDELETED(revolver) ? null : revolver

/// Первый живой, в чьих вещах лежит предмет: в руке, в кармане или в сумке.
/proc/heretic_lead_holder(obj/item/item)
	for(var/atom/place = item.loc, place && !isturf(place), place = place.loc)
		if(isliving(place))
			return place
	return null

/datum/eldritch_knowledge/base_lead/proc/recall_block_reason(mob/living/user, obj/item/heretic_path_relic/lead_revolver/revolver, cost)
	if(!revolver)
		return "Шестизарядника больше нет: соберите новый на руне из гильзы и листа железа."
	if(user.is_holding(revolver))
		return "Шестизарядник уже у вас в руке."
	if(!length(user.get_empty_held_indexes()))
		return "Обе руки заняты: освободите одну, и револьвер ляжет в неё."
	if(recall_timer)
		return "Шестизарядник уже летит к вам."
	if(heretic_lead_holder(revolver) == user)
		return null
	var/turf/place = get_turf(revolver)
	if(!place)
		return "Шестизарядник затерян вне мира: призыву не за что ухватиться."
	if(is_centcom_level(place.z))
		return "Шестизарядник на Центральном командовании: туда призыв не дотягивается."
	var/area/place_area = get_area(place)
	if(place_area.area_flags & NOTELEPORT)
		return "Шестизарядник в зоне, закрытой для телепортации: оттуда его не вырвать."
	if(lead_total() < cost)
		return "Для призыва издалека нужен Свинец ([cost]), а барабан и патронташ пусты. Вне боя Свинец копится сам."
	return null

/// Нулевой жезл в руке держащего или свежая святая вода на револьвере срывают призыв издалека.
/datum/eldritch_knowledge/base_lead/proc/recall_ward(obj/item/heretic_path_relic/lead_revolver/revolver)
	if(revolver.hallowed_until > world.time)
		return "святая вода"
	var/mob/living/holder = heretic_lead_holder(revolver)
	if(holder && (locate(/obj/item/nullrod) in holder.held_items))
		return "нулевой жезл"
	return null

/datum/eldritch_knowledge/base_lead/proc/break_recall(mob/living/user, obj/item/heretic_path_relic/lead_revolver/revolver, ward)
	var/mob/living/holder = heretic_lead_holder(revolver)
	if(ward == "нулевой жезл")
		to_chat(user, span_warning("Призыв Шестизарядника сорван: [holder] держит нулевой жезл, и револьвер не вырвать. Свинец цел."))
		to_chat(holder, span_notice("[revolver] дёргается к хозяину, но нулевой жезл в вашей руке гасит рывок."))
	else
		to_chat(user, span_warning("Призыв Шестизарядника сорван: на револьвере святая вода, и он не отзывается. Свинец цел."))
		if(holder)
			to_chat(holder, span_notice("[revolver] дёргается, но святая вода на металле шипит, и он затихает."))
		else
			revolver.visible_message(span_notice("[revolver] вздрагивает, но святая вода на металле шипит, и он затихает."))
	heretic_craft_dispel_fx(revolver, src)
	user.balloon_alert(user, "призыв сорван")
	log_combat(user, holder || revolver, "не смог призвать Шестизарядник ([ward]) у")
	return TRUE

/// Призыв Шестизарядника: из своих вещей - сразу в руку и без отката, издалека - секунда дрожи на месте и единица Свинца.
/datum/eldritch_knowledge/base_lead/proc/recall_revolver(mob/living/user, recall_time, cost)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = own_revolver()
	lead_failure = recall_block_reason(user, revolver, cost)
	if(lead_failure)
		return FALSE
	if(heretic_lead_holder(revolver) == user)
		return land_revolver(user, revolver)
	var/ward = recall_ward(revolver)
	if(ward)
		return break_recall(user, revolver, ward)
	var/turf/place = get_turf(revolver)
	new /obj/effect/temp_visual/heretic_lead/ricochet(place)
	heretic_lead_sound(place, "drum_spin", 45, TRUE)
	var/mob/living/holder = heretic_lead_holder(revolver)
	if(holder)
		to_chat(holder, span_warning("[revolver] дёргается и рвётся прочь, будто его тянут за невидимый шнур! Нулевой жезл в руке или святая вода на металле его удержат."))
	heretic_lead_sound(user, "cock", 35, TRUE, SILENCED_SOUND_EXTRARANGE)
	user.balloon_alert(user, "револьвер летит")
	recall_timer = addtimer(CALLBACK(src, PROC_REF(finish_recall), WEAKREF(user), cost), recall_time, TIMER_STOPPABLE)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/finish_recall(datum/weakref/user_ref, cost)
	recall_timer = null
	var/mob/living/user = user_ref?.resolve()
	if(!user)
		return FALSE
	if(!can_use(user, TRUE))
		to_chat(user, span_warning("Призыв Шестизарядника сорвался: вы не в состоянии его поймать. Свинец цел."))
		return FALSE
	var/obj/item/heretic_path_relic/lead_revolver/revolver = own_revolver()
	lead_failure = recall_block_reason(user, revolver, cost)
	var/remote = !lead_failure && heretic_lead_holder(revolver) != user
	var/ward = remote && recall_ward(revolver)
	if(ward)
		break_recall(user, revolver, ward)
		return FALSE
	if(lead_failure || (remote && !spend_combat_resource(cost)))
		to_chat(user, span_warning("Призыв Шестизарядника сорвался. [lead_failure || "Не хватило Свинца."]"))
		return FALSE
	return land_revolver(user, revolver, remote)

/datum/eldritch_knowledge/base_lead/proc/land_revolver(mob/living/user, obj/item/heretic_path_relic/lead_revolver/revolver, remote = FALSE)
	var/turf/from = get_turf(revolver)
	var/mob/living/holder = heretic_lead_holder(revolver)
	if(holder && revolver.loc == holder)
		holder.temporarilyRemoveItemFromInventory(revolver, TRUE)
	if(holder && holder != user)
		holder.visible_message(span_warning("[revolver] вырывается из вещей [holder] и улетает!"), span_userdanger("[revolver] вырывается у вас и улетает к хозяину!"))
		log_combat(user, holder, "призывает к себе Шестизарядник от")
	var/turf/here = get_turf(user)
	var/obj/item/evidencebag/bag = revolver.loc
	revolver.forceMove(here)
	if(istype(bag))
		bag.handle_atom_del(revolver)
	if(!user.put_in_hands(revolver))
		to_chat(user, span_warning("Шестизарядник падает к вашим ногам: рука не удержала."))
	if(from && from != here && from.z == here.z)
		heretic_lead_trace(from, here, "lead_finger_tracer", HERETIC_LEAD_RECALL_TRACE)
	heretic_lead_sound(user, "cock", 45, TRUE)
	if(remote)
		log_game("[key_name(user)] призывает Шестизарядник из [AREACOORD(from)] в [AREACOORD(here)].")
	return TRUE

/obj/item/heretic_path_relic/lead_revolver
	/// До этого времени на металле святая вода: призыв издалека срывается.
	var/hallowed_until = 0

/obj/item/heretic_path_relic/lead_revolver/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))

/obj/item/heretic_path_relic/lead_revolver/proc/on_exposed(atom/source, list/exposed, datum/reagents/holder, method)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in exposed)
		if(istype(reagent, /datum/reagent/water/holywater))
			hallowed_until = world.time + HERETIC_LEAD_RECALL_HALLOW
			visible_message(span_warning("Святая вода шипит на [src], и красная мушка гаснет: Мансус его пока не дозовётся."))
			return

/obj/effect/proc_holder/spell/self/heretic_lead/recall
	name = "Призвать Шестизарядник"
	desc = "Шестизарядник при вас - в кармане, на поясе или в сумке - сразу ложится в свободную руку, и кнопка не уходит на перезарядку. Потерянный, отнятый или запертый в шкафу револьвер за 1 секунду дрожит на месте, затем вырывается даже из чужих рук и летит к вам за 1 Свинец. Нулевой жезл в руке держащего или святая вода на металле срывают такой призыв, Свинец цел. С Центрального командования и из зон без телепортации его не дозваться. Нужна свободная рука; работает и в чужой хватке. Перезарядка призыва издалека 10 секунд."
	summary = "Шестизарядник в руку: из своих вещей - даром и без отката, издалека - за секунду и 1 Свинец."
	charge_max = 10 SECONDS
	usable_while_grabbed = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_lead.dmi'
	action_icon_state = "lead_revolver"
	var/recall_time = 1 SECONDS
	var/recall_cost = 1

/obj/effect/proc_holder/spell/self/heretic_lead/recall/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/reason = lead.recall_block_reason(user, lead.own_revolver(), recall_cost)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_lead/recall/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(user)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = lead?.own_revolver()
	var/from_pack = revolver && heretic_lead_holder(revolver) == user
	if(!lead?.recall_revolver(user, recall_time, recall_cost))
		heretic_revert_cast(user, lead?.lead_failure)
	else if(from_pack)
		revert_cast(user)

/// Удар рукоятью сбивает шаг; держится отдельно от замедления дождя.
/datum/status_effect/heretic_lead_slowed/butt
	id = "heretic_lead_butted"
	duration = HERETIC_LEAD_BUTT_SLOW
	examine_text = span_warning("SUBJECTPRONOUN пошатывается после удара рукоятью револьвера.")
	slow_type = /datum/movespeed_modifier/heretic_lead_slowed/butt

/datum/movespeed_modifier/heretic_lead_slowed/butt

/// Пуля Шестизарядника: обычная пуля, место её удара запоминает Рикошет; в голову стоящему бьёт сильнее и глушит.
/obj/item/projectile/bullet/heretic_lead
	name = "Mansus bullet"
	damage = HERETIC_LEAD_REVOLVER_DAMAGE
	armour_penetration = HERETIC_LEAD_REVOLVER_PENETRATION
	wound_bonus = 10
	shrapnel_type = null
	embedding = null
	color = "#c8d0dc"
	var/round_name = "Свинцовая"
	var/datum/weakref/lead_ref
	/// Попадание в живого врага возвращает Свинец; рикошет и призрачный ствол - нет, Последний патрон - только за убийство.
	var/refunds = TRUE
	var/headshot = FALSE
	/// Цель была жива до попадания: убийство пулей считается отдельно.
	var/hit_alive = FALSE

/obj/item/projectile/bullet/heretic_lead/prehit_pierce(atom/target)
	. = ..()
	var/mob/living/victim = target
	if(istype(victim))
		hit_alive = victim.stat != DEAD
	if(headshot || (. != PROJECTILE_PIERCE_NONE && . != PROJECTILE_PIERCE_HIT) || !istype(victim) || victim.lying || check_zone(def_zone) != BODY_ZONE_HEAD)
		return
	headshot = TRUE
	damage *= 1 + HERETIC_LEAD_HEADSHOT_BONUS / 100

/obj/item/projectile/bullet/heretic_lead/on_hit(atom/target, blocked = FALSE, pierce_hit)
	var/turf/place = get_turf(src)
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.record_impact(place)
	var/mob/living/victim = target
	if(!istype(victim) || blocked >= 100)
		return
	if(refunds)
		lead?.revolver_hit(victim, hit_alive)
	if(headshot && !QDELETED(victim) && victim.get_ear_protection() < 1)
		victim.apply_status_effect(/datum/status_effect/heretic_lead_ringing)
		if(ismob(firer))
			log_combat(firer, victim, "попадает в голову пулей Шестизарядника")
	if(lead)
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "round_hit", victim, type)

/// Пуля с именем: медленная, видимая, доворачивает к своей цели и не узнаёт чужих.
/obj/item/projectile/heretic_lead_named
	name = "named bullet"
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_named_bullet"
	damage = HERETIC_LEAD_NAMED_DAMAGE
	damage_type = BRUTE
	flag = BULLET
	hitsound = null
	nondirectional_sprite = TRUE
	pixels_per_second = TILES_TO_PIXELS(HERETIC_LEAD_NAMED_SPEED)
	range = HERETIC_LEAD_NAMED_RANGE + 4
	var/datum/weakref/lead_ref
	var/datum/weakref/named_ref
	/// Цель приняла пулю телом, а не щитом.
	var/struck = FALSE

/obj/item/projectile/heretic_lead_named/setAngle(new_angle, hitscan_store_segment = TRUE, interrupt_movement = TRUE)
	. = ..()
	var/static/list/quarters = list(NORTH, EAST, SOUTH, WEST)
	dir = quarters[round(((Angle + 45) % 360) / 90) + 1]

/obj/item/projectile/heretic_lead_named/proc/aim_at(mob/living/victim)
	named_ref = WEAKREF(victim)
	RegisterSignal(victim, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_named_struck))

/obj/item/projectile/heretic_lead_named/proc/on_named_struck(datum/source, obj/item/projectile/projectile, def_zone)
	SIGNAL_HANDLER
	if(projectile == src)
		struck = TRUE

/obj/item/projectile/heretic_lead_named/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.named_hit(src, target)

/obj/item/projectile/heretic_lead_named/Destroy()
	var/mob/living/victim = named_ref?.resolve()
	if(victim)
		UnregisterSignal(victim, COMSIG_LIVING_HIT_BY_PROJECTILE)
	named_ref = null
	lead_ref = null
	return ..()

#undef HERETIC_LEAD_NAMED_DAMAGE
#undef HERETIC_LEAD_NAMED_SPEED
#undef HERETIC_LEAD_JAM_NOTICE
#undef HERETIC_LEAD_PATINA_KEY
#undef HERETIC_LEAD_RECALL_TRACE
#undef HERETIC_LEAD_PATINA_HOT
#undef HERETIC_LEAD_PATINA_DIM
#undef HERETIC_LEAD_PATINA_PULSE
#undef HERETIC_LEAD_RECALL_HALLOW
