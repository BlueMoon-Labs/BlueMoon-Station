/datum/heretic_path
	var/book_type = /obj/item/forbidden_book
	var/book_name = "Кодекс Рубцов"
	var/book_title = "Кодекс Рубцов"
	var/book_subtitle = "Двенадцать дорог за одну завесу"
	var/book_desc = "Строки проступают между старыми шрамами на страницах."
	var/book_cover = "codex"
	var/book_ink = "#b2ac7d"
	var/book_tint = "#ffffff"
	var/book_rune = "sigil_ash"
	var/book_open_sound = 'modular_bluemoon/sound/heretic/book_open.ogg'
	var/book_page_sound = 'modular_bluemoon/sound/heretic/book_page.ogg'

/datum/heretic_path/ash
	book_type = /obj/item/forbidden_book/ash
	book_name = "Псалтирь последнего огня"
	book_title = "Псалтирь последнего огня"
	book_subtitle = "Не гаси то, что ещё помнит тепло"
	book_desc = "Обугленный молитвенник. В щелях переплёта тлеют угольки, а пепел между страницами складывается в буквы."
	book_cover = "ash"
	book_ink = "#ff9944"
	book_tint = "#ffd6b3"
	book_rune = "sigil_ash"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_ash_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_ash_page.ogg'

/datum/heretic_path/rust
	book_type = /obj/item/forbidden_book/rust
	book_name = "Железный завет"
	book_title = "Железный завет"
	book_subtitle = "Всякая вещь однажды станет почвой"
	book_desc = "Тяжёлый том в железных пластинах. Петли скрипят, застёжка проросла зелёным налётом; гравюры медленно разъедает ржавчина."
	book_cover = "rust"
	book_ink = "#a6c359"
	book_tint = "#ddcd99"
	book_rune = "sigil_rust"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_rust_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_rust_page.ogg'

/datum/heretic_path/flesh
	book_type = /obj/item/forbidden_book/flesh
	book_name = "Анатомия голода"
	book_title = "Анатомия голода"
	book_subtitle = "Ни один шов не бывает последним"
	book_desc = "Тёплая книга, перетянутая сухожилиями. Обложка дышит под ладонью; страницы приходится разнимать, словно края раны."
	book_cover = "flesh"
	book_ink = "#e55d70"
	book_tint = "#ffb8b0"
	book_rune = "sigil_flesh"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_flesh_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_flesh_page.ogg'

/datum/heretic_path/void
	book_type = /obj/item/forbidden_book/void
	book_name = "Палимпсест зимы"
	book_title = "Палимпсест зимы"
	book_subtitle = "За последним словом начинается тишина"
	book_desc = "Бледный том, покрытый инеем. Страницы холоднее воздуха, а забытые строки видны только там, где на них осело дыхание."
	book_cover = "void"
	book_ink = "#b4e5f5"
	book_tint = "#c3e8ff"
	book_rune = "sigil_void"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_void_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_void_page.ogg'

/datum/heretic_path/blade
	book_type = /obj/item/forbidden_book/blade
	book_name = "Трактат о последнем ударе"
	book_title = "Трактат о последнем ударе"
	book_subtitle = "Не торопись. Он сам оставит открытие"
	book_desc = "Узкий боевой трактат в потёртой коже. На полях вычерчены стойки и дуги ударов; стальные уголки заточены до бритвенной остроты."
	book_cover = "blade"
	book_ink = "#e9d29d"
	book_tint = "#e2ddca"
	book_rune = "sigil_blade"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_blade_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_blade_page.ogg'

/datum/heretic_path/moon
	book_type = /obj/item/forbidden_book/moon
	book_name = "Зерцало без лица"
	book_title = "Зерцало без лица"
	book_subtitle = "Отражение перевернёт страницу первым"
	book_desc = "Серебряная книга с зеркальными страницами. Отражение читателя смотрит в сторону ещё до того, как он поворачивает голову."
	book_cover = "moon"
	book_ink = "#d4bef8"
	book_tint = "#ebdfff"
	book_rune = "sigil_moon"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_moon_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_moon_page.ogg'

/datum/heretic_path/cosmic
	book_type = /obj/item/forbidden_book/cosmic
	book_name = "Атлас внутреннего неба"
	book_title = "Атлас внутреннего неба"
	book_subtitle = "Звёзды движутся, пока ты не смотришь"
	book_desc = "Звёздный атлас в невозможном переплёте. Между страницами вращаются небесные сферы, а созвездия меняются при каждом открытии."
	book_cover = "cosmic"
	book_ink = "#81e7ee"
	book_tint = "#c6ecff"
	book_rune = "sigil_cosmic"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_cosmic_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_cosmic_page.ogg'

/datum/heretic_path/lock
	book_type = /obj/item/forbidden_book/lock
	book_name = "Каталог невозможных дверей"
	book_title = "Каталог невозможных дверей"
	book_subtitle = "У каждого выхода есть обратная сторона"
	book_desc = "Книга в тяжёлом переплёте с несколькими замочными скважинами. На каждой странице чертёж двери; ни одна не открывается туда, куда обещает."
	book_cover = "lock"
	book_ink = "#d8b674"
	book_tint = "#f3dfb2"
	book_rune = "sigil_lock"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_lock_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_lock_page.ogg'

/datum/heretic_path/tide
	book_type = /obj/item/forbidden_book/tide
	book_name = "Лоция бездонного моря"
	book_title = "Лоция бездонного моря"
	book_subtitle = "Последний берег остался над вами"
	book_desc = "Отсыревшая лоция в переплёте из чёрной парусины. Бронзовые уголки обросли солью, а между страницами слышен прибой моря, которого нет на картах."
	book_cover = "tide"
	book_ink = "#56bbb3"
	book_tint = "#b8e4d9"
	book_rune = "sigil_tide"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_tide_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_tide_page.ogg'

/obj/item/forbidden_book
	var/book_path
	var/book_open = FALSE
	var/matrix/book_rest_transform
	var/book_rest_y
	var/book_rest_alpha
	COOLDOWN_DECLARE(page_turn_cooldown)

/datum/heretic_path/glass
	book_type = /obj/item/forbidden_book/glass
	book_name = "Евангелие разбитого света"
	book_title = "Евангелие разбитого света"
	book_subtitle = "Целое скрывает то, что видно в осколках"
	book_desc = "Том в переплёте из тёмного витражного стекла. Свинцовые прожилки держат острые грани; между страницами свет распадается на чужие цвета."
	book_cover = "glass"
	book_ink = "#d8b3e2"
	book_tint = "#f3dff2"
	book_rune = "sigil_glass"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_glass_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_glass_page.ogg'

/datum/heretic_path/blood
	book_type = /obj/item/forbidden_book/blood
	book_name = "Служебник алой десятины"
	book_title = "Служебник алой десятины"
	book_subtitle = "Каждая строка требует свою каплю"
	book_desc = "Служебник в винно-красной коже с золотыми застёжками. По желобкам обложки медленно стекает алая влага; сухие страницы пахнут железом."
	book_cover = "blood"
	book_ink = "#d75169"
	book_tint = "#ffbbc7"
	book_rune = "sigil_blood"
	book_open_sound = 'modular_bluemoon/sound/heretic/book_blood_open.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/book_blood_page.ogg'

/obj/item/forbidden_book/glass
	book_path = PATH_GLASS

/datum/heretic_path/echo
	book_type = /obj/item/forbidden_book/echo
	book_name = "Партитура последнего голоса"
	book_title = "Партитура последнего голоса"
	book_subtitle = "Голос смолк. Дождись ответа"
	book_desc = "Партитура в переплёте из тёмной кожи с костяными накладками. Глаз под латунной скобой следит за пальцами читателя. Струны вдоль корешка отзываются на прикосновение; последняя нота звучит уже после того, как книга закрыта."
	book_cover = "echo"
	book_ink = "#d9bb73"
	book_tint = "#ffffff"
	book_rune = "sigil_echo"
	book_open_sound = 'modular_bluemoon/sound/heretic/echo_cast.ogg'
	book_page_sound = 'modular_bluemoon/sound/heretic/echo_grasp.ogg'

/obj/item/forbidden_book/echo
	book_path = PATH_ECHO

/obj/item/forbidden_book/blood
	book_path = PATH_BLOOD

/obj/item/forbidden_book/ash
	book_path = PATH_ASH

/obj/item/forbidden_book/rust
	book_path = PATH_RUST

/obj/item/forbidden_book/flesh
	book_path = PATH_FLESH

/obj/item/forbidden_book/void
	book_path = PATH_VOID

/obj/item/forbidden_book/blade
	book_path = PATH_BLADE

/obj/item/forbidden_book/moon
	book_path = PATH_MOON

/obj/item/forbidden_book/cosmic
	book_path = PATH_COSMIC

/obj/item/forbidden_book/lock
	book_path = PATH_LOCK

/obj/item/forbidden_book/tide
	book_path = PATH_TIDE

/obj/item/forbidden_book/Initialize(mapload)
	. = ..()
	if(book_path)
		set_book_form(book_path)

/obj/item/forbidden_book/pickup(mob/user)
	. = ..()
	attune_book(user)

/obj/item/forbidden_book/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(user.is_holding(src))
		attune_book(user)
	else
		close_book(user, FALSE)

/obj/item/forbidden_book/dropped(mob/user, silent = FALSE)
	clear_hunt_tracking()
	close_book(user, FALSE)
	return ..()

/obj/item/forbidden_book/proc/attune_book(mob/user, announce = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic?.selected_path || heretic.selected_path == book_path)
		return FALSE
	var/was_open = book_open
	close_book(user, FALSE)
	set_book_form(heretic.selected_path)
	if(announce)
		to_chat(user, span_eldritch("Переплёт меняется под вашей ладонью. Теперь в ваших руках «[name]»."))
	if(was_open)
		open_book(user)
	return TRUE

/obj/item/forbidden_book/proc/set_book_form(path_id)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return FALSE
	book_path = path_id
	name = path.book_name
	desc = path.book_desc
	icon = 'modular_bluemoon/icons/obj/heretic_books.dmi'
	icon_state = path.book_cover
	item_state = path.book_cover
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_books_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_books_righthand.dmi'
	color = null
	update_icon()
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_inv_hands()
	return TRUE

/obj/item/forbidden_book/update_icon_state()
	var/datum/heretic_path/path = GLOB.heretic_paths[book_path]
	var/state = path?.book_cover || "codex"
	icon_state = book_open ? "[state]_open" : state

/obj/item/forbidden_book/update_overlays()
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[book_path]
	if(!book_open || !path)
		return
	var/mutable_appearance/seal = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', path.book_rune, ABOVE_OBJ_LAYER)
	seal.appearance_flags = RESET_COLOR
	seal.transform = matrix() * 0.6
	seal.pixel_y = 7
	. += seal
	if(book_path == PATH_COSMIC)
		var/mutable_appearance/orbit = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', "cosmic_ring", ABOVE_OBJ_LAYER)
		orbit.pixel_y = 10
		. += orbit

/obj/item/forbidden_book/proc/open_book(mob/user)
	if(book_open)
		return
	book_open = TRUE
	book_rest_transform = matrix(transform)
	book_rest_y = pixel_y
	book_rest_alpha = alpha
	update_icon()
	var/datum/heretic_path/path = GLOB.heretic_paths[book_path]
	flick("[path?.book_cover || "codex"]_opening", src)
	if(user)
		user.playsound_local(get_turf(user), path?.book_open_sound || 'modular_bluemoon/sound/heretic/book_open.ogg', 25, FALSE)
	if(!path)
		return
	var/matrix/opening = matrix(book_rest_transform)
	switch(book_path)
		if(PATH_ASH)
			opening.Turn(-6)
			animate(src, transform = opening, time = 1)
			animate(transform = book_rest_transform, time = 2)
		if(PATH_RUST)
			opening.Scale(0.65, 1)
			transform = opening
			animate(src, transform = book_rest_transform, time = 12, easing = CUBIC_EASING)
		if(PATH_FLESH)
			opening.Scale(1.12, 1.06)
			animate(src, transform = opening, time = 5)
			animate(transform = book_rest_transform, time = 7)
		if(PATH_VOID)
			animate(src, pixel_y = book_rest_y + 3, time = 16, easing = SINE_EASING)
		if(PATH_BLADE)
			opening.Scale(0.3, 1)
			transform = opening
			animate(src, transform = book_rest_transform, time = 3)
		if(PATH_MOON)
			alpha = min(alpha, 110)
			animate(src, alpha = book_rest_alpha, time = 10)
		if(PATH_COSMIC)
			opening.Turn(12)
			animate(src, transform = opening, pixel_y = book_rest_y + 2, time = 5)
			animate(transform = book_rest_transform, time = 10)

		if(PATH_LOCK)
			opening.Scale(0.6, 1)
			transform = opening
			animate(src, transform = book_rest_transform, time = 0.4 SECONDS, easing = CUBIC_EASING)
		if(PATH_TIDE)
			animate(src, pixel_y = book_rest_y + 2, time = 0.8 SECONDS, easing = SINE_EASING)
			animate(pixel_y = book_rest_y, time = 0.8 SECONDS, easing = SINE_EASING)
		if(PATH_GLASS)
			opening.Scale(0.92, 1.02)
			animate(src, transform = opening, time = 0.3 SECONDS, easing = SINE_EASING)
			animate(transform = book_rest_transform, time = 0.7 SECONDS, easing = SINE_EASING)
		if(PATH_BLOOD)
			opening.Scale(1.06, 1.03)
			animate(src, transform = opening, time = 0.4 SECONDS, easing = SINE_EASING)
			animate(transform = book_rest_transform, time = 0.9 SECONDS, easing = SINE_EASING)
		if(PATH_ECHO)
			opening.Turn(2)
			var/matrix/settling = matrix(book_rest_transform)
			settling.Turn(-1)
			animate(src, transform = opening, time = 0.15 SECONDS, easing = SINE_EASING)
			animate(transform = settling, time = 0.2 SECONDS, easing = SINE_EASING)
			animate(transform = book_rest_transform, time = 0.15 SECONDS, easing = SINE_EASING)

/obj/item/forbidden_book/proc/close_book(mob/user, audible = TRUE)
	if(!book_open)
		return
	book_open = FALSE
	animate(src)
	transform = book_rest_transform
	pixel_y = book_rest_y
	alpha = book_rest_alpha
	book_rest_transform = null
	update_icon()
	var/datum/heretic_path/path = GLOB.heretic_paths[book_path]
	flick("[path?.book_cover || "codex"]_closing", src)
	if(audible && user)
		user.playsound_local(get_turf(user), 'modular_bluemoon/sound/heretic/book_close.ogg', 20, FALSE)

/obj/item/forbidden_book/proc/turn_page(mob/user)
	if(!user?.is_holding(src) || !IS_HERETIC(user) || user.incapacitated() || !COOLDOWN_FINISHED(src, page_turn_cooldown))
		return FALSE
	COOLDOWN_START(src, page_turn_cooldown, 0.3 SECONDS)
	var/datum/heretic_path/path = GLOB.heretic_paths[book_path]
	user.playsound_local(get_turf(user), path?.book_page_sound || 'modular_bluemoon/sound/heretic/book_page.ogg', 18, FALSE)
	return TRUE

/datum/antagonist/heretic/proc/attune_books(mob/user)
	var/list/books = user.GetAllContents(/obj/item/forbidden_book)
	for(var/obj/item/forbidden_book/book in summon_items)
		books |= book
	for(var/obj/item/forbidden_book/book as anything in books)
		book.attune_book(user, TRUE)

/obj/effect/temp_visual/heretic_script
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	icon_state = "sigil_ash"
	duration = 1 SECONDS
	layer = ABOVE_MOB_LAYER
	alpha = 190

/obj/effect/temp_visual/heretic_script/Initialize(mapload, path_id)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(path)
		icon_state = path.book_rune
	animate(src, alpha = 0, pixel_y = 10, time = duration)

/obj/effect/eldritch
	var/rune_path

/obj/effect/eldritch/proc/inscribe_path(path_id)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return
	rune_path = path_id
	update_icon()

/obj/effect/eldritch/update_overlays()
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[rune_path]
	if(!path)
		return
	var/mutable_appearance/seal = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', path.book_rune)
	seal.transform = matrix() * 0.8
	seal.appearance_flags = RESET_COLOR | PIXEL_SCALE
	. += seal

/datum/eldritch_knowledge/codex_cicatrix/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
	var/book_type = path?.book_type || /obj/item/forbidden_book
	new book_type(loc)
	return TRUE
