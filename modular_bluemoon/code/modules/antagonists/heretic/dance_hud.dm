#define DANCE_CUE_START_SCALE 2.2
#define DANCE_CUE_ALPHA_COMBAT 230
#define DANCE_CUE_ALPHA_CALM 110
#define DANCE_CUE_PIXEL_Y -27
#define DANCE_PIP_SPACING 6
#define DANCE_PIP_PIXEL_Y -18
#define DANCE_PIP_COOLDOWN_COLOR "#6a625c"
#define DANCE_HINT_FLAGS (RESET_COLOR | RESET_TRANSFORM | RESET_ALPHA | KEEP_APART)

/datum/eldritch_knowledge/base_dance
	/// Подсказки видны только танцору: кольцо следующей доли, шаги фигуры, следующий шаг и цель Вальса.
	var/beat_hints = TRUE
	var/image/cue_ring
	var/image/figure_hud
	var/figure_hud_key
	var/image/next_step_hint
	var/image/lead_hint

/datum/eldritch_knowledge/base_dance/proc/hint_viewer()
	if(!beat_hints || QDELETED(dance_body) || dance_body.stat == DEAD)
		return null
	return dance_body.client

/datum/eldritch_knowledge/base_dance/proc/drop_hint(image/hint)
	if(hint)
		dance_body?.client?.images -= hint

/datum/eldritch_knowledge/base_dance/proc/clear_hints()
	drop_hint(cue_ring)
	drop_hint(figure_hud)
	drop_hint(next_step_hint)
	drop_hint(lead_hint)
	cue_ring = null
	figure_hud = null
	figure_hud_key = null
	next_step_hint = null
	lead_hint = null

/datum/eldritch_knowledge/base_dance/proc/refresh_hints()
	update_figure_hud()
	update_next_step()
	update_lead_hint()

/datum/eldritch_knowledge/base_dance/proc/toggle_hints(mob/living/user)
	beat_hints = !beat_hints
	if(beat_hints)
		refresh_hints()
		update_cue()
	else
		clear_hints()
	user.balloon_alert(user, beat_hints ? "подсказки такта включены" : "подсказки такта скрыты")

/// Кольцо у ног сжимается и смыкается ровно на следующей доле; сильную долю ждёт двойное кольцо.
/datum/eldritch_knowledge/base_dance/proc/update_cue()
	var/client/viewer = hint_viewer()
	if(!viewer)
		drop_hint(cue_ring)
		return
	if(!cue_ring)
		cue_ring = image('modular_bluemoon/icons/obj/heretic_dance_effects.dmi', dance_body, "dance_cue_ring", BELOW_MOB_LAYER)
		cue_ring.pixel_x = -16
		cue_ring.pixel_y = DANCE_CUE_PIXEL_Y
		cue_ring.appearance_flags = DANCE_HINT_FLAGS
		cue_ring.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	viewer.images |= cue_ring
	var/datum/heretic_dance_style/style = current_style()
	var/next_strong = ((beat_index + 1) % meter) == 0
	var/until_next = max(beat_origin + (beat_index + 1) * beat_ds - world.time, world.tick_lag)
	cue_ring.icon_state = next_strong ? "dance_cue_ring_strong" : "dance_cue_ring"
	cue_ring.color = style.color
	cue_ring.transform = matrix() * DANCE_CUE_START_SCALE
	cue_ring.alpha = 0
	animate(cue_ring, transform = matrix(), alpha = in_combat() || combat_resource > 0 ? DANCE_CUE_ALPHA_COMBAT : DANCE_CUE_ALPHA_CALM, time = until_next, easing = LINEAR_EASING)

/// Ромбы под ногами: сколько шагов фигуры уже сделано; серые - фигура остывает. У Тарантеллы - укусы подряд.
/datum/eldritch_knowledge/base_dance/proc/update_figure_hud()
	var/client/viewer = hint_viewer()
	var/datum/heretic_dance_style/style = current_style()
	var/total = length(style.figure) || (style.id == HERETIC_DANCE_STYLE_TARANTELLA ? HERETIC_DANCE_BITE_HITS : 0)
	if(!viewer || !total)
		drop_hint(figure_hud)
		return
	var/done = length(style.figure) ? figure_progress() : bite_chain
	if(figure_held())
		done = total
	var/cooling = length(style.figure) && beat_total < figure_ready_beat
	var/key = "[style.id]-[done]-[total]-[cooling]"
	if(figure_hud && key == figure_hud_key)
		viewer.images |= figure_hud
		return
	figure_hud_key = key
	if(!figure_hud)
		figure_hud = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', dance_body, null, BELOW_MOB_LAYER)
		figure_hud.pixel_y = DANCE_PIP_PIXEL_Y
		figure_hud.appearance_flags = DANCE_HINT_FLAGS
		figure_hud.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/list/pips = list()
	var/start = -(total - 1) * DANCE_PIP_SPACING / 2
	for(var/index in 1 to total)
		var/mutable_appearance/pip = mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', index <= done ? "dance_figure_pip" : "dance_figure_pip_empty")
		pip.pixel_x = round(start + (index - 1) * DANCE_PIP_SPACING)
		pip.color = cooling ? DANCE_PIP_COOLDOWN_COLOR : style.color
		pips += pip
	figure_hud.overlays = pips
	viewer.images |= figure_hud

/// Направление следующего шага начатой фигуры; null, пока фигура не начата или уже собрана.
/datum/eldritch_knowledge/base_dance/proc/next_figure_dir()
	var/datum/heretic_dance_style/style = current_style()
	var/progress = figure_progress()
	if(!progress || progress >= length(style.figure))
		return null
	var/first = figure_steps[length(figure_steps) - progress + 1]
	return turn(first, style.figure[progress + 1])

/// Медный след на клетке, куда нужен следующий шаг фигуры.
/datum/eldritch_knowledge/base_dance/proc/update_next_step()
	var/client/viewer = hint_viewer()
	var/direction = next_figure_dir()
	var/turf/spot = viewer && direction ? get_step(dance_body, direction) : null
	if(next_step_hint && spot && next_step_hint.loc == spot && next_step_hint.dir == direction)
		return
	drop_hint(next_step_hint)
	next_step_hint = null
	if(!spot)
		return
	next_step_hint = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', spot, "dance_next_step", ABOVE_OPEN_TURF_LAYER, direction)
	viewer.images += next_step_hint

/// Нота над тем, кого подхватит квадрат Вальса: видна за шаг до конца фигуры и пока фигура ждёт цели.
/datum/eldritch_knowledge/base_dance/proc/update_lead_hint()
	var/client/viewer = hint_viewer()
	var/mob/living/target
	if(viewer && style_id == HERETIC_DANCE_STYLE_WALTZ && beat_total >= figure_ready_beat)
		var/datum/heretic_dance_style/waltz = current_style()
		if(figure_held() || figure_progress() >= length(waltz.figure) - 1)
			target = lead_candidate(dance_body)
	if(lead_hint && lead_hint.loc == target)
		viewer?.images |= lead_hint
		return
	drop_hint(lead_hint)
	lead_hint = null
	if(!target)
		return
	lead_hint = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', target, "dance_invite_note", ABOVE_MOB_LAYER)
	var/datum/heretic_dance_style/style = current_style()
	lead_hint.pixel_y = 18
	lead_hint.color = style.color
	lead_hint.appearance_flags = DANCE_HINT_FLAGS
	lead_hint.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	viewer.images += lead_hint

/// Клавиша стиля: null - вернуться к прошлому стилю.
/datum/eldritch_knowledge/base_dance/proc/hotkey_style(mob/living/user, id)
	if(user != dance_body)
		return FALSE
	if(!id)
		id = previous_style_id
		if(!id)
			user.balloon_alert(user, "прошлого стиля ещё нет")
			return FALSE
	if(!style_known(id))
		user.balloon_alert(user, "стиль ещё не открыт")
		return FALSE
	return switch_style(user, id)

/datum/keybinding/living/heretic_dance_style
	description = "Пляска: сменить стиль без кругового меню. В сильную долю - связка, мимо - стиль вступит на следующей сильной доле; повторное нажатие меняет сразу."
	var/style_id

/datum/keybinding/living/heretic_dance_style/down(client/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user.mob)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!dance)
		return FALSE
	dance.hotkey_style(user.mob, style_id)
	return TRUE

/datum/keybinding/living/heretic_dance_style/previous
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_previous"
	full_name = "Пляска: прошлый стиль"

/datum/keybinding/living/heretic_dance_style/waltz
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_waltz"
	full_name = "Пляска: Вальс"
	style_id = HERETIC_DANCE_STYLE_WALTZ

/datum/keybinding/living/heretic_dance_style/tango
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_tango"
	full_name = "Пляска: Танго"
	style_id = HERETIC_DANCE_STYLE_TANGO

/datum/keybinding/living/heretic_dance_style/tarantella
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_tarantella"
	full_name = "Пляска: Тарантелла"
	style_id = HERETIC_DANCE_STYLE_TARANTELLA

/datum/keybinding/living/heretic_dance_style/cancan
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_cancan"
	full_name = "Пляска: Канкан"
	style_id = HERETIC_DANCE_STYLE_CANCAN

/datum/keybinding/living/heretic_dance_style/macabre
	hotkey_keys = list("Unbound")
	name = "heretic_dance_style_macabre"
	full_name = "Пляска: Пляска смерти"
	style_id = HERETIC_DANCE_STYLE_MACABRE

#undef DANCE_CUE_START_SCALE
#undef DANCE_CUE_ALPHA_COMBAT
#undef DANCE_CUE_ALPHA_CALM
#undef DANCE_CUE_PIXEL_Y
#undef DANCE_PIP_SPACING
#undef DANCE_PIP_PIXEL_Y
#undef DANCE_PIP_COOLDOWN_COLOR
#undef DANCE_HINT_FLAGS
