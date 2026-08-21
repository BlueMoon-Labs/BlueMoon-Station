/// Сколько символов влезает на плакат.
#define PICKET_SIGN_LABEL_MAX_LEN 30
/// Сколько занимает вкопать плакат в пол и выдернуть обратно.
#define PICKET_SIGN_PLANT_TIME (2 SECONDS)

/// Годится ли [tool] для письма. Штампы сюда не попадают - у них MODE_STAMPING.
/proc/is_writing_implement(obj/item/tool)
	var/list/details = tool?.get_writing_implement_details()
	return details && details["interaction_mode"] == MODE_WRITING

/// Стоит ли уже на тайле [spot] вкопанный плакат. Повешенные на стену не в счёт - они висят над полом.
/proc/get_planted_picket_sign(turf/spot)
	for(var/obj/structure/picket_sign/standing in spot)
		if(istype(standing, /obj/structure/picket_sign/wall))
			continue
		return standing
	return null

/**
 * Спрашивает у [user] новую надпись для плаката [sign] и возвращает её.
 *
 * [writing_implement] задан, когда пишут предметом - тогда работает проверка грамотности
 * и самого инструмента. Нано-плакат силикон перепрограммирует без инструмента вообще.
 * Возвращает `null`, если писать нечем, некому или диалог отменили.
 */
/proc/ask_picket_label(atom/sign, mob/user, obj/item/writing_implement, current_label)
	if(!user?.client) //диалог показывать некому
		return null
	if(writing_implement && !user.can_write(writing_implement))
		return null

	var/new_label = tgui_input_text(user, "Что написать на плакате?", "Надпись на плакате", current_label, PICKET_SIGN_LABEL_MAX_LEN, encode = TRUE)
	if(isnull(new_label) || !user.canUseTopic(sign, BE_CLOSE))
		return null

	return new_label

/obj/item/picket_sign
	icon_state = "picket"
	name = "blank picket sign"
	desc = "It's blank."
	force = 5
	w_class = WEIGHT_CLASS_BULKY
	attack_verb = list("bashed","smacked")
	resistance_flags = FLAMMABLE

	var/label = ""
	/// Можно ли воткнуть плакат в пол. Модульный плакат борга - часть модуля, его вкапывать нечем.
	var/plantable = TRUE
	COOLDOWN_DECLARE(picket_sign_cooldown)

/obj/item/picket_sign/cyborg
	name = "metallic nano-sign"
	desc = "A high tech picket sign used by silicons that can reprogram its surface at will. Probably hurts to get hit by, too."
	force = 13
	resistance_flags = NONE
	plantable = FALSE
	actions_types = list(/datum/action/item_action/nano_picket_sign)

/obj/item/picket_sign/Initialize(mapload)
	. = ..()
	// Надпись могли выставить варэдитом или на карте. Пустую не трогаем: она бы затёрла
	// имя, выставленное там же напрямую.
	if(label)
		set_label(label)

/obj/item/picket_sign/examine(mob/user)
	. = ..()
	. += span_notice("Надпись меняется ручкой или мелком. Пустая надпись стирает плакат.")
	if(plantable)
		. += span_notice("На \"помощи\" плакат вкапывается в пол и вешается на стену.")

/// Пишет на плакате [new_label]. Пустая строка возвращает плакат к чистому виду.
/obj/item/picket_sign/proc/set_label(new_label)
	label = new_label || ""
	if(label)
		name = "[label] sign"
		desc = "It reads: [label]"
	else
		name = initial(name)
		desc = initial(desc)

/// Спрашивает у [user] новую надпись и наносит её. Аргументы - как у ask_picket_label().
/obj/item/picket_sign/proc/retext(mob/user, obj/item/writing_implement)
	set waitfor = FALSE

	var/new_label = ask_picket_label(src, user, writing_implement, label)
	if(isnull(new_label))
		return
	set_label(new_label)
	playsound(src, SFX_WRITING_PEN, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, SOUND_FALLOFF_EXPONENT + 3, ignore_walls = FALSE)

/obj/item/picket_sign/attackby(obj/item/attacking_item, mob/user, params)
	if(!is_writing_implement(attacking_item))
		return ..()
	retext(user, attacking_item)
	// Иначе следом отработает afterattack инструмента: ручка откроет своё окно
	// переименования по UNIQUE_RENAME, мелок нарисует поверх плаката граффити.
	return STOP_ATTACK_PROC_CHAIN

/obj/item/picket_sign/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!plantable || !proximity_flag || user.a_intent != INTENT_HELP)
		return
	if(iswallturf(target))
		hang_on_wall(target, user)
		return
	if(isopenturf(target) && !isspaceturf(target))
		plant_in_floor(target, user)

/// Вкапывает плакат в тайл пола [spot].
/obj/item/picket_sign/proc/plant_in_floor(turf/open/spot, mob/user)
	if(spot == get_turf(user))
		balloon_alert(user, "не под собой")
		return
	if(get_planted_picket_sign(spot))
		balloon_alert(user, "тут уже стоит плакат")
		return

	user.visible_message(span_notice("[user] начинает вкапывать [src]."), span_notice("Вы начинаете вкапывать [src]."))
	if(!do_after(user, PICKET_SIGN_PLANT_TIME, spot))
		return
	// do_after следит только за тем, что копающий не ушёл. Плакат за это время могли
	// вырвать из рук или убрать в сумку - без проверки он телепортировался бы из чужого
	// кармана в пол.
	if(QDELETED(src) || !user.is_holding(src) || get_planted_picket_sign(spot))
		return

	var/obj/structure/picket_sign/planted = new(spot)
	planted.set_label(label)
	qdel(src)

/**
 * Вешает плакат на стену [wall].
 *
 * Как и остальные настенные знаки, объект стоит на тайле вешающего и сдвинут пикселями
 * на стену - иначе он был бы виден с обеих её сторон.
 */
/obj/item/picket_sign/proc/hang_on_wall(turf/closed/target_wall, mob/user)
	var/turf/user_turf = get_turf(user)
	var/hang_dir = get_dir(user_turf, target_wall)
	if(!(hang_dir in GLOB.cardinals)) //по диагонали плакат повис бы сразу на двух стенах
		balloon_alert(user, "встаньте напротив стены")
		return
	for(var/obj/structure/picket_sign/wall/hanging in user_turf)
		if(hanging.dir == hang_dir)
			balloon_alert(user, "тут уже висит плакат")
			return

	user.visible_message(span_notice("[user] начинает вешать [src] на [target_wall]."), span_notice("Вы начинаете вешать [src] на [target_wall]."))
	if(!do_after(user, PICKET_SIGN_PLANT_TIME, target_wall))
		return
	if(QDELETED(src) || !user.is_holding(src) || !iswallturf(target_wall) || get_turf(user) != user_turf)
		return

	var/obj/structure/picket_sign/wall/hung = new(user_turf)
	hung.set_label(label)
	hung.setDir(hang_dir)
	switch(hang_dir)
		if(NORTH)
			hung.pixel_y = 32
		if(SOUTH)
			hung.pixel_y = -32
		if(EAST)
			hung.pixel_x = 32
		if(WEST)
			hung.pixel_x = -32
	qdel(src)

/obj/item/picket_sign/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, /datum/action/item_action/nano_picket_sign))
		retext(user)
		return
	return ..()

/obj/item/picket_sign/attack_self(mob/user)
	if(!isliving(user))
		return ..()

	if(!COOLDOWN_FINISHED(src, picket_sign_cooldown))
		balloon_alert(user, "плакат ещё опущен")
		return

	COOLDOWN_START(src, picket_sign_cooldown, 5 SECONDS)

	if(label)
		user.emote("me", message = "размахивает плакатом с надписью \"[label]\".")
		user.say(label)
		user.balloon_alert_to_viewers("[label]")
	else
		user.emote("me", message = "размахивает пустым плакатом.")
		user.balloon_alert_to_viewers("пустой плакат")

	var/direction = prob(50) ? -1 : 1
	if(NSCOMPONENT(user.dir))
		animate(user, pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
	else
		animate(user, pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

	user.changeNext_move(CLICK_CD_MELEE)

/**
 * Вкопанный плакат.
 *
 * Держит надпись сам, чтобы пикет пережил хозяина: снятый руками плакат отдаёт
 * обратно предмет с той же надписью, разбитый - ничего.
 */
/obj/structure/picket_sign
	name = "blank picket sign"
	desc = "It's blank."
	icon = 'icons/obj/picket_sign.dmi' //спрайты floor_sign/wall_sign из ParadiseSS13, CC-BY-SA 3.0
	icon_state = "planted"
	anchored = TRUE
	density = FALSE
	max_integrity = 50
	resistance_flags = FLAMMABLE

	var/label = ""

/// Плакат, повешенный на стену. Живёт на тайле перед стеной, сдвинутый на неё пикселями.
/obj/structure/picket_sign/wall
	icon_state = "wall"
	plane = ABOVE_WALL_PLANE
	layer = SIGN_LAYER

/obj/structure/picket_sign/Initialize(mapload)
	. = ..()
	// Надпись могли выставить варэдитом или на карте. Пустую не трогаем: она бы затёрла
	// имя, выставленное там же напрямую.
	if(label)
		set_label(label)

/obj/structure/picket_sign/examine(mob/user)
	. = ..()
	. += span_notice("Надпись меняется ручкой или мелком. Плакат снимается руками.")

/// Пишет на плакате [new_label]. Пустая строка возвращает плакат к чистому виду.
/obj/structure/picket_sign/proc/set_label(new_label)
	label = new_label || ""
	if(label)
		name = "[label] sign"
		desc = "It reads: [label]"
	else
		name = initial(name)
		desc = initial(desc)

/// Спрашивает у [user] новую надпись и наносит её. Аргументы - как у ask_picket_label().
/obj/structure/picket_sign/proc/retext(mob/user, obj/item/writing_implement)
	set waitfor = FALSE

	var/new_label = ask_picket_label(src, user, writing_implement, label)
	if(isnull(new_label))
		return
	set_label(new_label)
	playsound(src, SFX_WRITING_PEN, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, SOUND_FALLOFF_EXPONENT + 3, ignore_walls = FALSE)

/// Превращает плакат обратно в предмет, сохраняя надпись.
/obj/structure/picket_sign/proc/uproot(mob/user)
	var/obj/item/picket_sign/sign = new(get_turf(src))
	sign.set_label(label)
	user?.put_in_hands(sign)
	return sign

/obj/structure/picket_sign/attackby(obj/item/attacking_item, mob/user, params)
	if(!is_writing_implement(attacking_item))
		return ..()
	retext(user, attacking_item)
	return STOP_ATTACK_PROC_CHAIN

/obj/structure/picket_sign/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(act_intent != INTENT_HELP)
		return

	user.visible_message(span_notice("[user] начинает снимать [src]."), span_notice("Вы начинаете снимать [src]."))
	if(!do_after(user, PICKET_SIGN_PLANT_TIME, src))
		return
	uproot(user)
	qdel(src)

/obj/structure/picket_sign/deconstruct(disassembled = TRUE)
	if(disassembled && !(flags_1 & NODECONSTRUCT_1))
		uproot()
	return ..()

#undef PICKET_SIGN_LABEL_MAX_LEN
#undef PICKET_SIGN_PLANT_TIME
