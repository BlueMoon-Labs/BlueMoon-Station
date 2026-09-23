#define HERETIC_VOID_INK heretic_path_ink(PATH_VOID)
#define HERETIC_VOID_MOTE_RATE 0.25
#define HERETIC_VOID_MOTE_SPIN (6 SECONDS)
#define HERETIC_VOID_MOTE_SEGMENTS 12
#define HERETIC_VOID_DEFLECT_OFFSET 14
#define HERETIC_VOID_DEFLECT_RADIUS 1
#define HERETIC_VOID_DEFLECT_TIME (0.4 SECONDS)
#define HERETIC_VOID_FROST_TIME (0.6 SECONDS)
#define HERETIC_VOID_FLASH_RANGE 2
#define HERETIC_VOID_FLASH_POWER 1.2
#define HERETIC_VOID_FLASH_TIME (0.3 SECONDS)
#define HERETIC_VOID_DEFLECT_THROTTLE (0.25 SECONDS)
#define HERETIC_VOID_FROST_SIZE 2

/datum/status_effect/heretic_void_chill
	id = "heretic_void_chill"
	duration = 4 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_void_chill

/datum/status_effect/heretic_void_chill/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	to_chat(owner, span_warning("Пустота сковывает ваши движения!"))

/datum/status_effect/heretic_void_chill/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	return ..()

/datum/movespeed_modifier/heretic_void_chill
	multiplicative_slowdown = 2
	conflicts_with = /datum/movespeed_modifier/heretic_void_chill

/obj/effect/heretic_combat_zone/void/Initialize(mapload, datum/mind/master)
	. = ..()
	var/datum/movespeed_modifier/chill_modifier = get_cached_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	zone_slowdown.multiplicative_slowdown = chill_modifier.multiplicative_slowdown
	zone_slowdown.conflicts_with = chill_modifier.conflicts_with
	var/mob/living/user = master?.current
	if(!QDELETED(user) && user.stat != DEAD && IS_HERETIC(user))
		tick_zone(user)

/atom/movable/screen/alert/status_effect/heretic_void_chill
	name = "Скованность Пустоты"
	desc = "Магия Пустоты замедляет ваши движения независимо от температуры тела. Эффект проходит через 4 секунды после последнего воздействия. Выйдите из зимнего поля и оторвитесь от еретика, чтобы скованность спала. Повторные воздействия обновляют время, не усиливая замедление."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_void"

/obj/item/melee/sickly_blade/void/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	var/datum/eldritch_knowledge/void_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	if(!upgrade)
		. += span_notice("Для сдвига к отмеченному врагу нужно знание «Ищущий клинок» Пути Пустоты.")
		return
	. += span_notice("Держите клинок в активной руке и нажмите ЛКМ по врагу с Меткой Пустоты вне досягаемости удара, в поле зрения и не дальше 5 клеток. Shift не требуется. Возле цели нужна клетка без препятствий; защита от магии блокирует сдвиг.")
	var/cooldown_text = COOLDOWN_FINISHED(upgrade, blink_cooldown) ? "Ищущий клинок: сдвиг готов." : "Ищущий клинок: сдвиг восстановится через [DisplayTimeText(COOLDOWN_TIMELEFT(upgrade, blink_cooldown))]."
	. += span_notice(cooldown_text)

/proc/heretic_void_overheated(mob/living/owner)
	return owner.on_fire || owner.bodytemperature > BODYTEMP_NORMAL + HERETIC_VOID_HEAT_MARGIN

/// Безвоздушная буря вознесения: снаряды, летящие в еретика, с шансом разворачиваются назад, пока он не разогрет.
/datum/component/heretic_void_storm
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/deflect_chance = HERETIC_VOID_DEFLECT_CHANCE
	var/obj/effect/abstract/heretic_particle_holder/motes
	COOLDOWN_DECLARE(deflect_visual)

/datum/component/heretic_void_storm/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	motes = heretic_vfx_attach_particles(parent, /particles/heretic_ascension/void/motes)
	motes?.SpinAnimation(HERETIC_VOID_MOTE_SPIN, -1, TRUE, HERETIC_VOID_MOTE_SEGMENTS, parallel = FALSE)
	update_motes()

/datum/component/heretic_void_storm/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_RUN_BLOCK, PROC_REF(deflect))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/component/heretic_void_storm/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_PARENT_EXAMINE, COMSIG_LIVING_LIFE))

/datum/component/heretic_void_storm/Destroy()
	heretic_vfx_release_particles(parent, motes)
	motes = null
	return ..()

/// Снег бури кружит вокруг вознесённого, пока жар не заглушит её.
/datum/component/heretic_void_storm/proc/update_motes()
	var/mob/living/owner = parent
	if(!motes?.particles)
		return
	var/rate = (owner.stat == DEAD || heretic_void_overheated(owner)) ? 0 : HERETIC_VOID_MOTE_RATE
	if(motes.particles.spawning != rate)
		motes.particles.spawning = rate

/datum/component/heretic_void_storm/proc/on_life(mob/living/source, seconds, times_fired)
	SIGNAL_HANDLER
	update_motes()

/datum/component/heretic_void_storm/proc/deflect(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(heretic_void_overheated(source))
		return BLOCK_NONE
	var/obj/item/projectile/projectile = heretic_try_deflect(source, real_attack, object, attack_type, deflect_chance)
	if(!projectile)
		return BLOCK_NONE
	playsound(source, pick('modular_bluemoon/sound/heretic/void_deflect1.ogg', 'modular_bluemoon/sound/heretic/void_deflect2.ogg', 'modular_bluemoon/sound/heretic/void_deflect3.ogg'), 50, TRUE)
	source.visible_message(span_warning("Безвоздушная буря вокруг [source] сбивает [projectile] с курса!"), span_notice("Буря разворачивает [projectile] назад."))
	heretic_vfx_pulse(projectile, HERETIC_VOID_INK, HERETIC_VOID_FROST_SIZE, HERETIC_VOID_FROST_TIME)
	if(COOLDOWN_FINISHED(src, deflect_visual) && heretic_vfx_watched(source))
		COOLDOWN_START(src, deflect_visual, HERETIC_VOID_DEFLECT_THROTTLE)
		show_deflect(source, projectile.Angle)
	return BLOCK_SUCCESS | BLOCK_REDIRECTED

/// Пространство рябит в точке попадания, иней сыплется по новому курсу снаряда, воздух вспыхивает холодом.
/datum/component/heretic_void_storm/proc/show_deflect(mob/living/source, angle)
	heretic_vfx_shockwave(source, HERETIC_VOID_INK, HERETIC_VOID_DEFLECT_RADIUS, HERETIC_VOID_DEFLECT_TIME, sin(angle) * HERETIC_VOID_DEFLECT_OFFSET, cos(angle) * HERETIC_VOID_DEFLECT_OFFSET)
	heretic_vfx_spray(source, /particles/heretic_ascension/void/frost, angle, HERETIC_VOID_DEFLECT_OFFSET)
	heretic_vfx_flash(source, HERETIC_VOID_INK, HERETIC_VOID_FLASH_RANGE, HERETIC_VOID_FLASH_POWER, HERETIC_VOID_FLASH_TIME)

/datum/component/heretic_void_storm/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(heretic_void_overheated(source))
		examine_list += span_notice("Буря вокруг стихла: тело слишком разогрето, и снаряды долетают без помех.")
	else
		examine_list += span_warning("Вокруг бушует безвоздушная буря, часть снарядов разворачивается назад. Огонь и жар её глушат.")

/// Пустота: снег, медленно кружащий вокруг вознесённого.
/particles/heretic_ascension/void/motes
	count = 10
	spawning = HERETIC_VOID_MOTE_RATE
	position = generator("circle", 10, 22)
	velocity = generator("circle", 0, 0.3)
	gravity = list(0, 0)
	friction = 0.02
	drift = generator("box", list(-0.05, -0.05, 0), list(0.05, 0.05, 0))
	lifespan = 2.5 SECONDS
	fade = 1 SECONDS
	fadein = 0.5 SECONDS

/// Пустота: иней, сорванный с отклонённого снаряда или отброшенного врага.
/particles/heretic_ascension/void/frost
	count = 10
	spawning = 10
	friction = 0.12
	gravity = list(0, -0.05)
	lifespan = 0.7 SECONDS
	fade = 0.35 SECONDS
	fadein = 0

#undef HERETIC_VOID_INK
#undef HERETIC_VOID_MOTE_RATE
#undef HERETIC_VOID_MOTE_SPIN
#undef HERETIC_VOID_MOTE_SEGMENTS
#undef HERETIC_VOID_DEFLECT_OFFSET
#undef HERETIC_VOID_DEFLECT_RADIUS
#undef HERETIC_VOID_DEFLECT_TIME
#undef HERETIC_VOID_FROST_TIME
#undef HERETIC_VOID_FLASH_RANGE
#undef HERETIC_VOID_FLASH_POWER
#undef HERETIC_VOID_FLASH_TIME
#undef HERETIC_VOID_DEFLECT_THROTTLE
#undef HERETIC_VOID_FROST_SIZE
