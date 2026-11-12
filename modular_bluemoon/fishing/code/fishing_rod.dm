// Удочки. Собраны под старый API взаимодействия с предметами. attackby навешивает
// компоненты, afterattack забрасывает в место рыбалки, attack_self открывает меню настройки.

/obj/item/fishing_rod
	name = "fishing rod"
	desc = "Этим можно ловить рыбу."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "fishing_rod"
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/equipment/fishing_rod_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/equipment/fishing_rod_righthand.dmi'
	item_state = "rod"
	inhand_icon_state = "rod"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 8
	w_class = WEIGHT_CLASS_HUGE

	var/cast_range = 3
	var/difficulty_modifier = 0
	var/ui_description = "Классическая удочка без особых свойств."
	var/wiki_description = ""

	var/obj/item/bait
	var/obj/item/fishing_line/line = /obj/item/fishing_line
	var/obj/item/fishing_hook/hook = /obj/item/fishing_hook

	var/atom/movable/currently_hooked
	var/datum/beam/fishing_line/fishing_line
	var/casting = FALSE
	var/default_line_color = "gray"
	var/internal = FALSE
	var/reel_overlay = "reel_overlay"
	var/frame_state = "frame_wood"
	var/collapsed = FALSE
	var/list/spin_frequency
	COOLDOWN_DECLARE(casting_cd)

	var/material_fish_chance = 50
	/// Материал удочки. По нему решается, какая материал-рыба может попасться.
	var/datum/material/rod_material
	/// Продвинутые удочки прощают отсутствие наживки.
	var/baitless_fishing = FALSE
	var/experience_multiplier = 1
	var/completion_speed_mult = 1
	var/bait_speed_mult = 1
	var/deceleration_mult = 1
	var/bounciness_mult = 1
	var/gravity_mult = 1
	var/bait_height_mult = 1

/obj/item/fishing_rod/Initialize(mapload)
	. = ..()
	base_icon_state = icon_state
	if(ispath(bait))
		set_slot(new bait(src), ROD_SLOT_BAIT)
	if(ispath(hook))
		set_slot(new hook(src), ROD_SLOT_HOOK)
	if(ispath(line))
		set_slot(new line(src), ROD_SLOT_LINE)
	update_icon()

/obj/item/fishing_rod/proc/set_slot(obj/item/item, slot)
	if(!item)
		return
	item.forceMove(src)
	switch(slot)
		if(ROD_SLOT_BAIT)
			bait = item
		if(ROD_SLOT_LINE)
			line = item
		if(ROD_SLOT_HOOK)
			hook = item
	SEND_SIGNAL(src, COMSIG_ITEM_FISHING_ROD_SLOTTED, item, slot)
	refresh_holder_icons()

/// Обновляет спрайты удочки в руках, когда меняется насадка.
/obj/item/fishing_rod/proc/refresh_holder_icons()
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_icons()

/obj/item/fishing_rod/proc/get_slot(slot)
	switch(slot)
		if(ROD_SLOT_BAIT)
			return bait
		if(ROD_SLOT_LINE)
			return line
		if(ROD_SLOT_HOOK)
			return hook

/obj/item/fishing_rod/proc/clear_slot(slot)
	var/obj/item/item = get_slot(slot)
	if(!item)
		return
	item.forceMove(drop_location())
	switch(slot)
		if(ROD_SLOT_BAIT)
			bait = null
		if(ROD_SLOT_LINE)
			line = null
		if(ROD_SLOT_HOOK)
			hook = null
	SEND_SIGNAL(src, COMSIG_ITEM_FISHING_ROD_UNSLOTTED, item, slot)
	update_icon()
	refresh_holder_icons()

/obj/item/fishing_rod/update_icon_state()
	if(collapsed)
		icon_state = "[base_icon_state]_collapsed"
	else
		icon_state = base_icon_state
	return ..()

/obj/item/fishing_rod/update_overlays()
	. = ..()
	var/line_color = line?.line_color || default_line_color
	var/mutable_appearance/reel = mutable_appearance(icon, reel_overlay)
	reel.color = line_color
	. += reel
	if(hook)
		var/mutable_appearance/line_overlay = mutable_appearance(icon, "line_overlay")
		line_overlay.color = line_color
		. += line_overlay
		. += mutable_appearance(icon, hook.rod_overlay_icon_state || "hook_overlay")

/// Рисует катушку, свисающую леску и крючок на спрайтах в руках.
/// Направление не задаём, оверлеи сами поворачиваются вместе с персонажем.
/obj/item/fishing_rod/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands || !icon_file)
		return
	var/line_color = line?.line_color || default_line_color
	var/mutable_appearance/reel = mutable_appearance(icon_file, "reel_overlay")
	reel.color = line_color
	. += reel
	if(!fishing_line)
		var/mutable_appearance/line_dangle = mutable_appearance(icon_file, "line_overlay")
		line_dangle.color = line_color
		. += line_dangle
		. += mutable_appearance(icon_file, "hook_overlay")

/obj/item/fishing_rod/examine(mob/user)
	. = ..()
	var/list/equipped_stuff = list()
	if(line)
		equipped_stuff += "[icon2html(line, user)] <b>[line.name]</b>"
	if(hook)
		equipped_stuff += "[icon2html(hook, user)] <b>[hook.name]</b>"
	if(bait)
		equipped_stuff += "[icon2html(bait, user)] <b>[bait]</b>"
	if(length(equipped_stuff))
		. += span_notice("Установлено: [english_list(equipped_stuff)].")
	if(!bait)
		. += span_warning("Наживка не прикреплена. Рыбачить будет заметно сложнее!")
	. += span_info("Как рыбачить: ЛКМ по воде, унитазу, раковине или другому месту рыбалки. Дождитесь поклёвки - поплавок дёрнется и появится подсказка. Затем кликните и удерживайте ЛКМ, чтобы поднимать приманку, отпускайте - чтобы она опускалась. Держите приманку на рыбе, пока полоса вываживания не заполнится.")
	if(HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISH))
		. += span_info("Вы можете забросить удочку на расстояние до [get_cast_range(user)] клеток.")

/obj/item/fishing_rod/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/bait))
		if(ismob(item.loc))
			user.transferItemToLoc(item, src)
		if(bait)
			clear_slot(ROD_SLOT_BAIT)
		set_slot(item, ROD_SLOT_BAIT)
		user.visible_message(span_notice("[user] attaches [item] to [src]."), span_notice("You attach [item] to [src]."))
		update_icon()
		return TRUE
	if(istype(item, /obj/item/fishing_line))
		if(ismob(item.loc))
			user.transferItemToLoc(item, src)
		if(line)
			clear_slot(ROD_SLOT_LINE)
		set_slot(item, ROD_SLOT_LINE)
		user.visible_message(span_notice("[user] spools [item] onto [src]."), span_notice("You spool [item] onto [src]."))
		update_icon()
		return TRUE
	if(istype(item, /obj/item/fishing_hook))
		if(ismob(item.loc))
			user.transferItemToLoc(item, src)
		if(hook)
			clear_slot(ROD_SLOT_HOOK)
		set_slot(item, ROD_SLOT_HOOK)
		user.visible_message(span_notice("[user] ties [item] to [src]."), span_notice("You tie [item] to [src]."))
		update_icon()
		return TRUE
	if(istype(item, /obj/item/fishing_rod))
		to_chat(user, span_warning("You can't attach a fishing rod to another fishing rod."))
		return TRUE
	return ..()

/obj/item/fishing_rod/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/fishing_rod/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!isturf(target) && !istype(target, /obj/structure) && !istype(target, /obj/machinery))
		return ..()
	if(!user.contains(src))
		return ..()
	cast_line(target, user)

/obj/item/fishing_rod/proc/cast_line(atom/target, mob/user)
	if(casting || currently_hooked)
		return
	if(!hook)
		balloon_alert(user, "сначала установите крючок!")
		return
	if(!COOLDOWN_FINISHED(src, casting_cd))
		return
	var/cast_range = get_cast_range(user)
	if(target.z != user.z || get_dist(user, target) > cast_range)
		balloon_alert(user, "слишком далеко!")
		return
	for(var/turf/turf in get_line(user, target))
		if(turf == get_turf(user) || turf == get_turf(target))
			continue
		if(isclosedturf(turf))
			balloon_alert(user, "леска заблокирована!")
			return
	COOLDOWN_START(src, casting_cd, 1 SECONDS)
	if(!HAS_TRAIT(target, TRAIT_FISHING_SPOT))
		var/turf/target_turf = get_turf(target)
		if(target_turf?.liquids?.reagent_list[/datum/reagent/water])
			target.AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/any])
	if(SEND_SIGNAL(target, COMSIG_FISHING_ROD_CAST, src, user) & FISHING_ROD_CAST_HANDLED)
		return
	hook_item(user, target)

/obj/item/fishing_rod/proc/hook_item(mob/user, atom/target_atom)
	if(currently_hooked)
		return
	if(!hook.can_be_hooked(target_atom))
		balloon_alert(user, "это не зацепить!")
		return
	if(!create_fishing_line(target_atom, user))
		return
	currently_hooked = target_atom
	hook.hook_attached(target_atom, src)
	SEND_SIGNAL(src, COMSIG_FISHING_ROD_HOOKED_ITEM, target_atom, user)

/obj/item/fishing_rod/proc/create_fishing_line(atom/movable/target, mob/living/firer, target_py = null)
	if(internal)
		return null
	if(fishing_line)
		QDEL_NULL(fishing_line)
	var/line_color = line?.line_color || default_line_color
	fishing_line = new /datum/beam/fishing_line(firer, target, 'icons/effects/beam.dmi', "fishing_line", INFINITY, 20)
	fishing_line.beam_color = line_color
	fishing_line.set_holder(firer, src)
	fishing_line.override_target_pixel_y = target_py || 0
	RegisterSignal(fishing_line, COMSIG_PARENT_QDELETING, PROC_REF(on_fishing_line_deleted))
	INVOKE_ASYNC(fishing_line, TYPE_PROC_REF(/datum/beam, Start))
	if(QDELETED(fishing_line))
		return null
	refresh_holder_icons()
	return fishing_line

/obj/item/fishing_rod/proc/on_fishing_line_deleted(datum/source)
	SIGNAL_HANDLER
	if(source == fishing_line)
		fishing_line = null
		currently_hooked = null
		refresh_holder_icons()

/obj/item/fishing_rod/proc/clear_fishing_line()
	if(fishing_line)
		UnregisterSignal(fishing_line, COMSIG_PARENT_QDELETING)
		QDEL_NULL(fishing_line)
	currently_hooked = null
	refresh_holder_icons()

/obj/item/fishing_rod/proc/get_cast_range(mob/living/user)
	. = max(cast_range + (line?.cast_range || 0), 1)
	user = user || loc
	if(!isliving(user) || !user.mind)
		return
	. += round((user.mind.get_skill_level(/datum/skill/level/fishing) || 0) * 0.5)
	return max(., 1)

/obj/item/fishing_rod/proc/reason_we_cant_fish(datum/fish_source/target_fish_source)
	return hook?.reason_we_cant_fish(target_fish_source)

/// Достаёт преобладающий материал удочки, если он вообще есть.
/obj/item/fishing_rod/proc/get_master_material()
	if(rod_material)
		return rod_material
	if(!length(custom_materials))
		return null
	var/datum/material/master
	var/master_amount = 0
	for(var/mat in custom_materials)
		if(custom_materials[mat] <= master_amount)
			continue
		master_amount = custom_materials[mat]
		master = SSmaterials.GetMaterialRef(mat)
	return master

/// Шанс, что пойманная рыба окажется из материала самой удочки.
/obj/item/fishing_rod/proc/get_material_fish_chance(mob/user)
	. = material_fish_chance
	if(bait)
		if(HAS_TRAIT(bait, TRAIT_GREAT_QUALITY_BAIT))
			. += 16
		else if(HAS_TRAIT(bait, TRAIT_GOOD_QUALITY_BAIT))
			. += 8
		else if(HAS_TRAIT(bait, TRAIT_BASIC_QUALITY_BAIT))
			. += 4
	if(user?.mind)
		. += user.mind.get_skill_level(/datum/skill/level/fishing) * 1.5

/obj/item/fishing_rod/proc/get_frame(datum/fishing_challenge/challenge)
	return frame_state

/obj/item/fishing_rod/proc/on_reward_caught(atom/movable/reward, mob/user)
	if(isnull(reward))
		return
	var/isfish = isfish(reward)
	if(isfish && HAS_TRAIT(reward, TRAIT_FISH_JUST_SPAWNED))
		var/obj/item/fish/caught_fish = reward
		// Удочка из материала умеет превращать улов в рыбу из того же материала.
		if(length(custom_materials) && prob(get_material_fish_chance(user)))
			var/datum/material/master = get_master_material()
			if(master)
				caught_fish.set_custom_materials(list(master.type = max(caught_fish.weight, 1)))
		// Улучшенная наживка приманивает улов покрупнее.
		if(bait && HAS_TRAIT(bait, TRAIT_GREAT_QUALITY_BAIT) && prob(25))
			caught_fish.randomize_size_and_weight(caught_fish.average_size * 1.2, caught_fish.average_weight * 1.2, 0.25)
	if(isnull(bait) || HAS_TRAIT(bait, TRAIT_BAIT_UNCONSUMABLE))
		return
	if(isliving(reward))
		var/mob/living/caught_mob = reward
		if(caught_mob.stat == DEAD)
			return
	else if(!isfish)
		return
	if(isfish && HAS_TRAIT(bait, TRAIT_POISONOUS_BAIT) && !HAS_TRAIT(reward, TRAIT_FISH_TOXIN_IMMUNE))
		var/obj/item/fish/caught_fish = reward
		var/kill_fish = TRUE
		for(var/bait_identifier in caught_fish.favorite_bait)
			if(is_matching_bait(bait, bait_identifier))
				kill_fish = FALSE
				break
		if(kill_fish)
			caught_fish.set_status(FISH_DEAD, silent = TRUE)
	qdel(bait)
	bait = null
	update_icon()

/obj/item/fishing_rod/proc/reel(mob/user)
	if(QDELETED(currently_hooked))
		currently_hooked = null
		return
	if(!currently_hooked)
		return
	playsound(src, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE)
	if(!do_after(user, 1 SECONDS, currently_hooked))
		return
	if(currently_hooked.anchored || currently_hooked.move_resist >= MOVE_FORCE_STRONG)
		balloon_alert(user, "[currently_hooked.p_they()] не поддаётся!")
		return
	if(!isitem(currently_hooked) && get_dist(currently_hooked, get_turf(src)) < 1)
		QDEL_NULL(fishing_line)
		currently_hooked = null
		return
	step_towards(currently_hooked, get_turf(src))
	if(!isitem(currently_hooked))
		if(get_dist(currently_hooked, get_turf(src)) <= 1)
			QDEL_NULL(fishing_line)
			currently_hooked = null
		return
	var/obj/item/item = currently_hooked
	if(item.loc == user.loc)
		user.put_in_inactive_hand(item)
		QDEL_NULL(fishing_line)
		currently_hooked = null

/obj/item/fishing_rod/interact(mob/user)
	if(currently_hooked)
		reel(user)
	else
		ui_interact(user)

/obj/item/fishing_rod/dropped(mob/user, silent)
	. = ..()
	QDEL_NULL(fishing_line)
	currently_hooked = null

/obj/item/fishing_rod/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FishingRod", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/fishing_rod/ui_data(mob/user)
	var/list/data = list()
	data["bait"] = bait ? "[bait.name]" : null
	data["line"] = line ? "[line.name]" : null
	data["hook"] = hook ? "[hook.name]" : null
	data["difficulty_modifier"] = difficulty_modifier
	data["ui_description"] = ui_description
	data["wiki_description"] = wiki_description
	data["cast_range"] = get_cast_range(user)
	data["experience_multiplier"] = experience_multiplier
	data["completion_speed_mult"] = completion_speed_mult
	data["bait_speed_mult"] = bait_speed_mult
	data["deceleration_mult"] = deceleration_mult
	data["bounciness_mult"] = bounciness_mult
	data["gravity_mult"] = gravity_mult
	data["bait_height_mult"] = bait_height_mult
	return data

/obj/item/fishing_rod/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("remove_bait")
			clear_slot(ROD_SLOT_BAIT)
		if("remove_line")
			clear_slot(ROD_SLOT_LINE)
		if("remove_hook")
			clear_slot(ROD_SLOT_HOOK)
		else
			return FALSE
	. = TRUE

/obj/item/fishing_rod/fiberglass
	name = "fibreglass fishing rod"
	desc = "Надёжная стеклопластиковая удочка."
	icon_state = "fishing_rod"
	custom_materials = list(/datum/material/glass = 2000, /datum/material/plastic = 500)
	material_fish_chance = 50
	difficulty_modifier = -2
	experience_multiplier = 1.2
	ui_description = "Надёжная удочка, немного облегчающая рыбалку."

/obj/item/fishing_rod/gold
	name = "golden fishing rod"
	desc = "Красивая удочка с золотой отделкой. Дорогая. Ловит быстрее."
	icon_state = "fishing_rod_master"
	custom_materials = list(/datum/material/gold = 2000)
	material_fish_chance = 50
	reel_overlay = "reel_master"
	frame_state = "frame_master"
	completion_speed_mult = 1.4
	bait_speed_mult = 1.15
	ui_description = "Роскошная удочка, заметно быстрее вываживающая рыбу."

/obj/item/fishing_rod/titanium
	name = "titanium fishing rod"
	desc = "Отлично собранная титановая удочка. Ловит рыбу получше."
	icon_state = "fishing_rod_material"
	custom_materials = list(/datum/material/titanium = 2000)
	material_fish_chance = 50
	reel_overlay = "reel_material"
	frame_state = "frame_material"
	difficulty_modifier = -3
	experience_multiplier = 1.35
	ui_description = "Крепкая удочка, помогающая ловить более редкую рыбу."

/obj/item/fishing_rod/lunar
	name = "lunar fishing rod"
	desc = "Розовая удочка. Небо знает, откуда у неё такой цвет."
	icon_state = "fishing_rod_master"
	custom_materials = list(/datum/material/silver = 2000)
	material_fish_chance = 50
	reel_overlay = "reel_master"
	frame_state = "frame_master"
	difficulty_modifier = -1
	bounciness_mult = 0.8
	ui_description = "Странная удочка, будто успокаивающая леску."

/obj/item/fishing_rod/telescopic
	name = "telescopic fishing rod"
	desc = "Компактная удочка, которая выдвигается при необходимости."
	icon_state = "fishing_rod_telescopic"
	custom_materials = list(/datum/material/iron = 1200)
	material_fish_chance = 50
	reel_overlay = "reel_telescopic"
	frame_state = "frame_telescopic"
	cast_range = 4

/obj/item/fishing_rod/telescopic/update_icon_state()
	icon_state = collapsed ? "fishing_rod_telescopic_collapsed" : "fishing_rod_telescopic"
	return ..()

/obj/item/fishing_rod/bone
	name = "bone fishing rod"
	desc = "Мрачная удочка, вырезанная из кости."
	icon_state = "fishing_rod_bone"
	custom_materials = list(/datum/material/bone = 2000)
	material_fish_chance = 50
	reel_overlay = "reel_bone"
	frame_state = "frame_bone"
	difficulty_modifier = 2
	experience_multiplier = 1.25
	ui_description = "Грубая удочка. Сложнее в использовании, но странно щедрая."

/obj/item/fishing_rod/science
	name = "science fishing rod"
	desc = "Точная удочка со встроенной катушкой."
	icon_state = "fishing_rod_science"
	custom_materials = list(/datum/material/silver = 1000, /datum/material/glass = 1000)
	material_fish_chance = 50
	baitless_fishing = TRUE
	reel_overlay = "reel_science"
	frame_state = "frame_science"
	difficulty_modifier = -4
	completion_speed_mult = 1.25
	bait_speed_mult = 1.1
	ui_description = "Высокотехнологичная удочка с отличным контролем. Не требует наживки."

/obj/item/fishing_rod/master
	name = "master fishing rod"
	desc = "Удочка мастерской работы."
	icon_state = "fishing_rod_master"
	custom_materials = list(/datum/material/gold = 1000, /datum/material/titanium = 1000)
	material_fish_chance = 50
	baitless_fishing = TRUE
	reel_overlay = "reel_master"
	frame_state = "frame_master"
	difficulty_modifier = -5
	experience_multiplier = 1.5
	completion_speed_mult = 1.3
	ui_description = "Вершина рыбацкой инженерии. Не требует наживки."

/// Луч лески, привязанный к кончику удочки, а не к телу моба.
/datum/beam/fishing_line
	/// Удочка зажата в левой руке?
	var/lefthand = FALSE

	var/righthand_s_px = 13
	var/righthand_s_py = 16
	var/righthand_e_px = 18
	var/righthand_e_py = 16
	var/righthand_w_px = -20
	var/righthand_w_py = 18
	var/righthand_n_px = -14
	var/righthand_n_py = 16

	var/lefthand_s_px = -13
	var/lefthand_s_py = 15
	var/lefthand_e_px = 24
	var/lefthand_e_py = 18
	var/lefthand_w_px = -17
	var/lefthand_w_py = 16
	var/lefthand_n_px = 13
	var/lefthand_n_py = 15

/datum/beam/fishing_line/proc/set_holder(mob/living/firer, obj/item/fishing_rod/rod)
	if(!firer || !rod)
		return
	var/index = firer.get_held_index_of_item(rod)
	lefthand = !!(index && (index % 2 == 1))
	update_offsets(firer.dir)

/datum/beam/fishing_line/Start()
	if(origin)
		update_offsets(origin.dir)
		RegisterSignal(origin, COMSIG_ATOM_DIR_CHANGE, PROC_REF(handle_dir_change))
	return ..()

/datum/beam/fishing_line/Destroy()
	if(origin)
		UnregisterSignal(origin, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/datum/beam/fishing_line/proc/handle_dir_change(atom/movable/source, olddir, newdir)
	SIGNAL_HANDLER
	update_offsets(newdir)
	INVOKE_ASYNC(src, PROC_REF(redraw_line))

/datum/beam/fishing_line/proc/redraw_line()
	if(finished)
		return
	Reset()
	Draw()

/datum/beam/fishing_line/proc/update_offsets(user_dir)
	switch(user_dir)
		if(SOUTH)
			override_origin_pixel_x = lefthand ? lefthand_s_px : righthand_s_px
			override_origin_pixel_y = lefthand ? lefthand_s_py : righthand_s_py
		if(EAST)
			override_origin_pixel_x = lefthand ? lefthand_e_px : righthand_e_px
			override_origin_pixel_y = lefthand ? lefthand_e_py : righthand_e_py
		if(WEST)
			override_origin_pixel_x = lefthand ? lefthand_w_px : righthand_w_px
			override_origin_pixel_y = lefthand ? lefthand_w_py : righthand_w_py
		if(NORTH)
			override_origin_pixel_x = lefthand ? lefthand_n_px : righthand_n_px
			override_origin_pixel_y = lefthand ? lefthand_n_py : righthand_n_py
	if(origin)
		override_origin_pixel_x += origin.pixel_x
		override_origin_pixel_y += origin.pixel_y


// Рецепты протолата на удочки.
/datum/design/fishing_rod_fiberglass
	name = "Fibreglass Fishing Rod"
	desc = "Надёжная удочка из стекловолокна. Ловит материал-рыбу в тон материалу."
	id = "fishing_rod_fiberglass"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2000, /datum/material/plastic = 500)
	build_path = /obj/item/fishing_rod/fiberglass
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/fishing_rod_titanium
	name = "Titanium Fishing Rod"
	desc = "Крепкая титановая удочка. Ловит материал-рыбу в тон материалу."
	id = "fishing_rod_titanium"
	build_type = PROTOLATHE
	materials = list(/datum/material/titanium = 2000)
	build_path = /obj/item/fishing_rod/titanium
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/fishing_rod_science
	name = "Science Fishing Rod"
	desc = "Продвинутая удочка, которой не нужна наживка. Ловит материал-рыбу в тон материалу."
	id = "fishing_rod_science"
	build_type = PROTOLATHE
	materials = list(/datum/material/silver = 1000, /datum/material/glass = 1000)
	build_path = /obj/item/fishing_rod/science
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SERVICE
