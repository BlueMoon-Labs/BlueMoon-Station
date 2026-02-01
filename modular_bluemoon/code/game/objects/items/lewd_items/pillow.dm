/*
*	ГЛОБАЛЬНЫЙ ХЕЛПЕР
*/

GLOBAL_DATUM_INIT(pillow_piles, /datum/pillow_pile_helper, new)

/datum/pillow_pile_helper

/// Гарантирует: pillows содержит expected подушек.
/datum/pillow_pile_helper/proc/ensure(obj/structure/pile, list/pillows, expected)
	if(!pillows)
		return

	while(pillows.len < expected)
		pillows += new /obj/item/fancy_pillow(pile)

/// Цвет кучи = цвет первой подушки, иначе default_color, иначе дефолт из /obj/item/fancy_pillow::current_color
/datum/pillow_pile_helper/proc/pile_color(list/pillows, default_color)
	var/obj/item/fancy_pillow/pillow = pillows?.len && pillows[1]
	if(istype(pillow))
		return pillow.current_color
	return default_color || /obj/item/fancy_pillow::current_color

/// Синхронизация иконки для tiny: требуется цвет+форма.
/// default_color/default_form: если NULL -> берём из /obj/item/fancy_pillow::current_color/form
/datum/pillow_pile_helper/proc/sync_tiny(obj/structure/bed/pillow_tiny/pile, default_color, default_form)
	if(!pile.pillows || !pile.pillows.len)
		var/color = default_color || /obj/item/fancy_pillow::current_color
		var/form = default_form || /obj/item/fancy_pillow::current_form
		pile.icon_state = "[pile.base_icon_state]_[color]_[form]"
		pile.update_icon()
		return

	var/obj/item/fancy_pillow/P = pile.pillows[1]
	pile.icon_state = "[pile.base_icon_state]_[P.current_color]_[P.current_form]"
	pile.update_icon()

/// Синхронизация иконки для small/large: нужен только цвет.
/datum/pillow_pile_helper/proc/sync_pile(obj/structure/pile, list/pillows, default_color)
	var/c = pile_color(pillows, default_color)
	pile.icon_state = "[pile.base_icon_state]_[c]"
	pile.update_icon()

/*
*	ОБЩИЕ ДЕЙСТВИЯ КУЧ
*/

/// "Снять подушку/разобрать кучу" (AltClick).
/// Возвращает TRUE если обработано.
/datum/pillow_pile_helper/proc/detach(obj/structure/pile, mob/user)
	// tiny -> item
	if(istype(pile, /obj/structure/bed/pillow_tiny))
		var/obj/structure/bed/pillow_tiny/tiny = pile
		to_chat(user, span_notice("You pick up [tiny]."))

		ensure(tiny, tiny.pillows, 1)

		var/obj/item/fancy_pillow/taken = tiny.pillows[1]
		tiny.pillows.Cut()

		taken.forceMove(user)
		user.put_in_hands(taken)

		qdel(tiny)
		return TRUE

	// small -> tiny + item
	if(istype(pile, /obj/structure/chair/pillow_small))
		var/obj/structure/chair/pillow_small/small = pile
		to_chat(user, span_notice("You take [small] from the pile."))

		ensure(small, small.pillows, 2)

		var/obj/item/fancy_pillow/taken = small.pillows[2]
		small.pillows.Cut(2, 3)

		taken.forceMove(user)
		user.put_in_hands(taken)

		var/obj/structure/bed/pillow_tiny/new_tiny = new(get_turf(small))
		var/obj/item/fancy_pillow/pillow = small.pillows[1]

		new_tiny.pillows = list(pillow)
		new_tiny.setDir(user.dir)
		pillow.forceMove(new_tiny)

		sync_tiny(new_tiny)

		qdel(small)
		return TRUE

	// large -> small + item
	if(istype(pile, /obj/structure/bed/pillow_large))
		var/obj/structure/bed/pillow_large/large = pile
		to_chat(user, span_notice("You take [large] from the pile."))

		ensure(large, large.pillows, 3)

		var/obj/item/fancy_pillow/taken = large.pillows[3]
		large.pillows.Cut(3, 4)

		taken.forceMove(user)
		user.put_in_hands(taken)

		var/obj/structure/chair/pillow_small/new_small = new(get_turf(large))
		new_small.pillows = large.pillows.Copy()

		for(var/obj/item/fancy_pillow/P in new_small.pillows)
			P.forceMove(new_small)

		sync_pile(new_small, new_small.pillows)

		qdel(large)
		return TRUE

	return FALSE

/// "Прицепить подушку к куче" (attackby).
/// Возвращает TRUE если обработано (даже если отказали по цвету).
/datum/pillow_pile_helper/proc/attach(obj/structure/pile, obj/item/fancy_pillow/used_item, mob/living/user)
	if(!istype(used_item, /obj/item/fancy_pillow))
		return FALSE

	// tiny + pillow -> small
	if(istype(pile, /obj/structure/bed/pillow_tiny))
		var/obj/structure/bed/pillow_tiny/tiny = pile
		ensure(tiny, tiny.pillows, 1)

		var/obj/item/fancy_pillow/used_pillow = used_item
		var/obj/item/fancy_pillow/own_pillow  = tiny.pillows[1]

		if(used_pillow.current_color != own_pillow.current_color)
			to_chat(user, span_notice("You feel that those colours would clash..."))
			return TRUE

		to_chat(user, span_notice("You add [tiny] to a pile."))

		var/obj/structure/chair/pillow_small/new_small = new(get_turf(tiny))
		new_small.pillows = list(own_pillow, used_pillow)

		own_pillow.forceMove(new_small)
		used_pillow.forceMove(new_small)

		sync_pile(new_small, new_small.pillows)

		qdel(tiny)
		return TRUE

	// small + pillow -> large
	if(istype(pile, /obj/structure/chair/pillow_small))
		var/obj/structure/chair/pillow_small/small = pile
		ensure(small, small.pillows, 2)

		var/obj/item/fancy_pillow/used_pillow = used_item
		var/obj/item/fancy_pillow/pillow = small.pillows[1]

		if(used_pillow.current_color != pillow.current_color)
			to_chat(user, span_notice("You feel that those colours would clash..."))
			return TRUE

		to_chat(user, span_notice("You add [small] to the pile."))

		var/obj/structure/bed/pillow_large/new_large = new(get_turf(small))
		new_large.pillows = small.pillows.Copy()

		for(var/obj/item/fancy_pillow/P in new_large.pillows)
			P.forceMove(new_large)

		used_pillow.forceMove(new_large)
		new_large.pillows += used_pillow

		sync_pile(new_large, new_large.pillows)

		qdel(small)
		return TRUE

	// large не апгрейдится
	return FALSE

/// ---------------------------------------------------------------------------
///  Визуальный эффект перьев
/// ---------------------------------------------------------------------------

/obj/effect/temp_visual/feathers
	name = "feathers"
	icon_state = "feathers"
	icon = 'modular_bluemoon/icons/effects/effects.dmi'
	duration = 14

/datum/effect_system/feathers
	effect_type = /obj/effect/temp_visual/feathers

/*
*	ITEM
*/

/// ---------------------------------------------------------------------------
///  Fancy pillow item
/// ---------------------------------------------------------------------------

/obj/item/fancy_pillow
	name = "pillow"
	desc = "A big, soft pillow."
	icon = 'modular_splurt/icons/obj/lewd_items/lewd_items.dmi'
	lefthand_file = 'modular_splurt/icons/mob/inhands/lewd_items/lewd_inhand_left.dmi'
	righthand_file = 'modular_splurt/icons/mob/inhands/lewd_items/lewd_inhand_right.dmi'
	icon_state = "pillow_pink_round"
	base_icon_state = "pillow"

	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE

	custom_materials = list(/datum/material/cloth = MINERAL_MATERIAL_AMOUNT*3)

	var/datum/effect_system/feathers/pillow_feathers

	var/current_color = "pink"
	var/current_form = "round"

	/// Общие радиалки (создаются один раз)
	var/static/list/pillow_colors
	var/static/list/pillow_forms

/obj/item/fancy_pillow/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

	if(!length(pillow_colors))
		_init_radial_colors()
	if(!length(pillow_forms))
		_init_radial_forms()

	update_icon()

	pillow_feathers = new
	pillow_feathers.set_up(2, 0, src)
	pillow_feathers.attach(src)

/obj/item/fancy_pillow/Destroy()
	QDEL_NULL(pillow_feathers)
	return ..()

/obj/item/fancy_pillow/examine(mob/user)
	. = ..()
	. += span_notice("<b>Alt-click</b>, чтобы изменить цвет и форму.")

/obj/item/fancy_pillow/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[current_color]_[current_form]"

/obj/item/fancy_pillow/proc/_can_open_menu(mob/living/user)
	return istype(user) && !user.incapacitated()

/obj/item/fancy_pillow/proc/_init_radial_colors()
	var/icon_file = initial(icon)
	pillow_colors = list(
		"pink" = image(icon = icon_file, icon_state = "pillow_pink_round"),
		"teal" = image(icon = icon_file, icon_state = "pillow_teal_round"),
	)

/obj/item/fancy_pillow/proc/_init_radial_forms()
	var/icon_file = initial(icon)
	pillow_forms = list(
		"square" = image(icon = icon_file, icon_state = "pillow_pink_square"),
		"round"  = image(icon = icon_file, icon_state = "pillow_pink_round"),
	)

/obj/item/fancy_pillow/AltClick(mob/user)
	. = ..()
	var/list/choice_lists = list("colors" = pillow_colors, "forms" = pillow_forms)
	for(var/key in choice_lists)
		var/list/menu = choice_lists[key]
		var/choice = show_radial_menu(
			user,
			src,
			menu,
			custom_check = CALLBACK(src, PROC_REF(_can_open_menu), user),
			radius = 36,
			require_near = TRUE
		)
		if(!choice)
			break

		switch(key)
			if("colors")
				current_color = choice
			if("forms")
				current_form = choice

		update_icon()

/// ---------------------------------------------------------------------------
///  Удар подушкой
/// ---------------------------------------------------------------------------

/obj/item/fancy_pillow/attack(mob/living/carbon/human/H, mob/living/carbon/human/user)
	. = ..()
	if(!istype(H))
		return

	pillow_feathers?.start()

	var/msg = _build_pillow_hit_message(user, H)

	if(prob(10))
		H.emote(pick("laugh_soft", "giggle"))

	user.visible_message(span_notice("[user] [msg]!"))
	playsound(loc, 'modular_sand/sound/interactions/hug.ogg', 50, 1, -1)


/obj/item/fancy_pillow/proc/_build_pillow_hit_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/is_self = (user == target)

	switch(user.zone_selected)
		if(BODY_ZONE_HEAD)
			return is_self \
				? pick(
					"hits [target.p_them()]self with [src]",
					"hits [target.p_their()] head with [src]") \
				: pick(
					"hits [target] with [src]",
					"hits [target] over the head with [src]! Luckily, [src] is soft.")

		if(BODY_ZONE_CHEST)
			return is_self \
				? pick(
					"has a solo pillow fight, hitting [target.p_them()]self with [src]",
					"hits [target.p_them()]self with [src]") \
				: pick(
					"hits [target] in the chest with [src]",
					"playfully hits [target]'s chest with [src]")

		else
			return is_self \
				? pick(
					"hits [target.p_them()]self with [src]",
					"playfully hits [target.p_them()]self with a [src]",
					"grabs [src], hitting [target.p_them()]self with it") \
				: pick(
					"hits [target] with [src]",
					"playfully hits [target] with [src].",
					"hits [target] with [src]. Looks like fun")


/// ---------------------------------------------------------------------------
///  Положить подушку на пол => tiny-куча, внутрь переносится тот же предмет
/// ---------------------------------------------------------------------------

/obj/item/fancy_pillow/attack_self(mob/user)
	. = ..()
	var/turf/T = get_turf(src)
	// Если на тайле уже есть куча подушек, просто улучшаем ее
	var/static/list/pile_types = list(
									/obj/structure/bed/pillow_tiny,
									/obj/structure/chair/pillow_small,
									/obj/structure/bed/pillow_large,
								)
	var/some_pile
	for(var/pile_type in pile_types)
		some_pile = locate(pile_type) in T
		if(some_pile)
			GLOB.pillow_piles.attach(some_pile, src, user)
			return

	// Если подушек нет, создаем новую
	var/obj/structure/bed/pillow_tiny/pile = new(T)
	pile.pillows = list(src)
	pile.setDir(user.dir)
	forceMove(pile)

	GLOB.pillow_piles.sync_tiny(pile)
	to_chat(user, span_notice("You set [src] down on the floor."))

/*
*	TINY
*/

/// ---------------------------------------------------------------------------
///  Tiny-куча (bed): хранит 1 подушку (лениво)
/// ---------------------------------------------------------------------------

/obj/structure/bed/pillow_tiny
	name = "pillow"
	desc = "A tiny pillow, for tiny heads."
	icon = 'modular_bluemoon/icons/obj/pillows.dmi'
	icon_state = "pillow_pink_round"
	base_icon_state = "pillow"
	bolts = FALSE

	max_integrity = 40
	resistance_flags = FLAMMABLE

	var/list/pillows = list()

	buildstacktype = /obj/item/stack/sheet/cloth
	custom_materials = list(/datum/material/cloth = MINERAL_MATERIAL_AMOUNT*3)
	buildstackamount = 3

/obj/structure/bed/pillow_tiny/Initialize(mapload)
	. = ..()
	GLOB.pillow_piles.sync_tiny(src)

/obj/structure/bed/pillow_tiny/examine(mob/user)
	. = ..()
	. += span_notice("<b>Alt-click</b>, чтобы забрать подушку.")

/obj/structure/bed/pillow_tiny/AltClick(mob/user)
	. = ..()
	GLOB.pillow_piles.detach(src, user)

/obj/structure/bed/pillow_tiny/post_buckle_mob(mob/living/M)
	. = ..()
	M.pixel_y = M.get_standard_pixel_y_offset(TRUE) + 5

/obj/structure/bed/pillow_tiny/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.pixel_y = M.get_standard_pixel_y_offset(TRUE)

/obj/structure/bed/pillow_tiny/attackby(obj/item/used_item, mob/living/user, params)
	if(!GLOB.pillow_piles.attach(src, used_item, user))
		return ..()

/*
*	SMALL
*/

/// ---------------------------------------------------------------------------
///  Small-куча (chair): хранит 2 подушки (лениво)
/// ---------------------------------------------------------------------------

/obj/structure/chair/pillow_small
	name = "small pillow pile"
	desc = "A small pile of pillows. A comfortable seat, especially for taurs or nagas."
	icon = 'modular_bluemoon/icons/obj/pillows.dmi'
	icon_state = "pillowpile_small_pink"
	base_icon_state = "pillowpile_small"
	bolts = FALSE

	max_integrity = 60
	resistance_flags = FLAMMABLE

	pseudo_z_axis = 4

	var/list/pillows = list()

	buildstacktype = /obj/item/stack/sheet/cloth
	custom_materials = list(/datum/material/cloth = MINERAL_MATERIAL_AMOUNT*6)
	buildstackamount = 6
	item_chair = null

/obj/structure/chair/pillow_small/Initialize(mapload)
	. = ..()
	GLOB.pillow_piles.sync_pile(src, pillows)

/obj/structure/chair/pillow_small/ComponentInitialize()
	. = ..()
	qdel(GetComponent(/datum/component/simple_rotation))

/obj/structure/chair/pillow_small/examine(mob/user)
	. = ..()
	. += span_notice("<b>Alt-click</b>, чтобы забрать подушку.")

/obj/structure/chair/pillow_small/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "[icon_state]_armrest", ABOVE_MOB_LAYER, src, appearance_flags = KEEP_APART)

/obj/structure/chair/pillow_small/AltClick(mob/user)
	. = ..()
	GLOB.pillow_piles.detach(src, user)

/obj/structure/chair/pillow_small/attackby(obj/item/used_item, mob/living/user, params)
	if(!GLOB.pillow_piles.attach(src, used_item, user))
		return ..()

// Мы сидим на куче подушек, поэтому мешаем пройти + пропозти
/obj/structure/chair/pillow_small/post_buckle_mob(mob/living/M)
	. = ..()
	density = TRUE

/obj/structure/chair/pillow_small/post_unbuckle_mob(mob/living/M)
	. = ..()
	density = FALSE

/*
*	LARGE (BED)
*/

/// ---------------------------------------------------------------------------
///  Large-куча (bed): хранит 3 подушки (лениво)
/// ---------------------------------------------------------------------------

/obj/structure/bed/pillow_large
	name = "large pillow pile"
	desc = "A large pile of pillows. Jump on it!"
	icon = 'modular_bluemoon/icons/obj/pillows.dmi'
	icon_state = "pillowpile_large_pink"
	base_icon_state = "pillowpile_large"
	bolts = FALSE

	resistance_flags = FLAMMABLE
	max_integrity = 80

	pseudo_z_axis = 4

	var/list/pillows = list()

	buildstacktype = /obj/item/stack/sheet/cloth
	custom_materials = list(/datum/material/cloth = MINERAL_MATERIAL_AMOUNT*9)
	buildstackamount = 9

/obj/structure/bed/pillow_large/Initialize(mapload)
	. = ..()
	GLOB.pillow_piles.sync_pile(src, pillows)

/obj/structure/bed/pillow_large/examine(mob/user)
	. = ..()
	. += span_notice("<b>Alt-click</b>, чтобы забрать подушку.")

/obj/structure/bed/pillow_large/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "[icon_state]_armrest", ABOVE_MOB_LAYER, src, appearance_flags = KEEP_APART)

/obj/structure/bed/pillow_large/AltClick(mob/user)
	. = ..()
	GLOB.pillow_piles.detach(src, user)
