
///////////
// EASEL //
///////////

/obj/structure/easel
	name = "easel"
	desc = "Only for the finest of art!"
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "easel"
	density = TRUE
	resistance_flags = FLAMMABLE
	max_integrity = 60
	var/obj/item/canvas/painting = null

//Adding canvases
/obj/structure/easel/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/canvas))
		var/obj/item/canvas/canvas = I
		user.dropItemToGround(canvas)
		painting = canvas
		canvas.forceMove(get_turf(src))
		canvas.layer = layer+0.1
		user.visible_message("<span class='notice'>[user] puts \the [canvas] on \the [src].</span>","<span class='notice'>You place \the [canvas] on \the [src].</span>")
	else
		return ..()


//Stick to the easel like glue
/obj/structure/easel/Move()
	var/turf/T = get_turf(src)
	. = ..()
	if(painting && painting.loc == T) //Only move if it's near us.
		painting.forceMove(get_turf(src))
	else
		painting = null

/obj/item/canvas
	name = "Small Сanvas"
	desc = "Draw out your soul on this canvas!"
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "11x11"
	// flags_1 = UNPAINTABLE_1
	resistance_flags = FLAMMABLE
	var/width = 11
	var/height = 11
	var/list/grid
	var/canvas_color = "#ffffff" //empty canvas color
	var/used = FALSE
	var/painting_name = "Untitled Artwork" //Painting name, this is set after framing.
	var/finalized = FALSE //Blocks edits
	var/author_ckey
	var/icon_generated = FALSE
	var/icon/generated_icon
	///boolean that blocks persistence from saving it. enabled from printing copies, because we do not want to save copies.
	var/no_save = FALSE

	// Painting overlay offset when framed
	var/framed_offset_x = 11
	var/framed_offset_y = 10

	pixel_x = 10
	pixel_y = 9

/obj/item/canvas/Initialize(mapload)
	. = ..()
	reset_grid()

/obj/item/canvas/proc/reset_grid()
	grid = new/list(width,height)
	for(var/x in 1 to width)
		for(var/y in 1 to height)
			grid[x][y] = canvas_color

/obj/item/canvas/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/canvas/ui_state(mob/user)
	if(finalized)
		return GLOB.physical_obscured_state
	else
		return GLOB.default_state

/obj/item/canvas/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Canvas", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/canvas/attackby(obj/item/I, mob/living/user, params)
	if(user.a_intent == INTENT_HELP)
		ui_interact(user)
	else
		return ..()

/obj/item/canvas/ui_data(mob/user)
	. = ..()
	.["grid"] = grid
	.["name"] = painting_name
	.["finalized"] = finalized

/obj/item/canvas/examine(mob/user)
	. = ..()
	. += span_notice("It looks like the canvas has a size [width] x [height].")
	ui_interact(user)

/obj/item/canvas/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	switch(action)
		if("paint")
			if(finalized)
				return
			var/obj/item/I = user.get_active_held_item()
			var/color = get_paint_tool_color(I)
			if(!color)
				return FALSE
			var/x = text2num(params["x"])
			var/y = text2num(params["y"])
			grid[x][y] = color
			used = TRUE
			update_icon()
			. = TRUE
		if("finalize")
			if(finalized)
				return
			finalize(user)
			. = TRUE
		if("export")
			var/datum/browser/popup = new(user, "canvas_export", "", 600, 900)
			popup.set_content(get_data_string(TRUE))
			popup.open()
			. = TRUE
		if("import")
			if(finalized)
				return
			// Кол-во символов по размеру картины + 10% на всякий мусор, вроде пробелов или переносов строк
			var/string = tgui_input_text(user, "Вставьте экспортированную картину", "Import", max_length = round(width * height * 7 * 1.1), multiline = TRUE)
			if(!string)
				return
			. = load_data_string(string, user)


/obj/item/canvas/proc/finalize(mob/user)
	finalized = TRUE
	author_ckey = user.ckey
	generate_proper_overlay()
	try_rename(user)

/obj/item/canvas/update_overlays()
	. = ..()
	if(icon_generated)
		var/mutable_appearance/detail = mutable_appearance(generated_icon)
		detail.pixel_x = 1
		detail.pixel_y = 1
		. += detail
		return
	if(!used)
		return

	var/mutable_appearance/detail = mutable_appearance(icon, "[icon_state]wip")
	detail.pixel_x = 1
	detail.pixel_y = 1
	. += detail

/obj/item/canvas/proc/generate_proper_overlay()
	if(icon_generated)
		return
	var/png_filename = "data/paintings/temp_painting.png"
	var/result = rustg_dmi_create_png(png_filename,"[width]","[height]",get_data_string())
	if(result)
		CRASH("Error generating painting png : [result]")
	generated_icon = new(png_filename)
	icon_generated = TRUE
	update_icon()

/obj/item/canvas/proc/get_data_string(to_export = FALSE)
	var/list/data = list()
	if(to_export)
		var/list/rows = list()
		for (var/y in 1 to height)
			var/list/row = list()
			for (var/x in 1 to width)
				row += grid[x][y]
			rows += row.Join("")
		return rows.Join("\n")
	else
		for(var/y in 1 to height)
			for(var/x in 1 to width)
				data += grid[x][y]
		return data.Join("")

// BLUEMOON ADD START
// user is optional
/obj/item/canvas/proc/load_data_string(string, mob/user)
	if(!istext(string))
		return

	var/list/colors_list = parse_color_sequence(string) // vailid sting check
	if(!colors_list)
		to_chat(user, span_boldwarning("Некорректная строка!"))
		return
	var/expected = width * height
	if(colors_list.len < expected)
		to_chat(user, span_boldwarning("Картина не подходит по формату! Ожидаемый размер: [expected], полученный размер: [colors_list.len]"))
		return

	var/i = 1
	for(var/y in 1 to height)
		for(var/x in 1 to width)
			grid[x][y] = colors_list[i]
			i++

	used = TRUE
	update_icon()
	return TRUE

#define IS_HEX_DIGIT(ch) \
	(((ch) >= "0" && (ch) <= "9") || \
	((ch) >= "A" && (ch) <= "F") || \
	((ch) >= "a" && (ch) <= "f"))

/obj/item/canvas/proc/parse_color_sequence(string)
	if (!string || !istext(string))
		return

	var/str = ""
	var/L = length(string)

	// Удаляем пробелы, переносы строк и т.д.
	for(var/i = 1, i <= L, i++)
		var/code = text2ascii(string, i)

		// 9  = TAB
		// 10 = LF (\n)
		// 13 = CR (\r)
		// 32 = SPACE
		if(code == 9 || code == 10 || code == 13 || code == 32)
			continue

		str += ascii2text(code)

	L = length(str)

	if (!L || (L % 7))
		// длина не совпадает с форматом #RRGGBB
		return

	var/list/colors_list = list()

	// проверяем каждый блок "#RRGGBB"
	for (var/i = 1; i <= L; i += 7)
		// символ '#' на первом месте блока
		if (copytext(str, i, i + 1) != "#")
			return

		// 6 hex-символов
		for (var/j = i + 1; j <= i + 6; j++)
			var/ch = copytext(str, j, j + 1)
			if (!IS_HEX_DIGIT(ch))
				return

		colors_list += copytext(str, i, i + 7)

	// валидная строка, возвращаем кол-во цветов
	return colors_list

#undef IS_HEX_DIGIT
// BLUEMOON ADD END

//Todo make this element ?
/obj/item/canvas/proc/get_paint_tool_color(obj/item/I)
	if(!I)
		return
	if(istype(I, /obj/item/toy/crayon))
		var/obj/item/toy/crayon/crayon = I
		return crayon.paint_color
	else if(istype(I, /obj/item/pen))
		var/obj/item/pen/P = I
		switch(P.colour)
			if("black")
				return "#000000"
			if("blue")
				return "#0000ff"
			if("red")
				return "#ff0000"
		return P.colour
	else if(istype(I, /obj/item/soap) || istype(I, /obj/item/reagent_containers/rag))
		return canvas_color

/obj/item/canvas/proc/try_rename(mob/user)
	var/new_name = stripped_input(user,"What do you want to name the painting?")
	if(new_name != painting_name && new_name && user.canUseTopic(src,BE_CLOSE))
		painting_name = new_name
		SStgui.update_uis(src)

/obj/item/canvas/nineteenXnineteen
	name = "Medium Canvas"
	icon_state = "19x19"
	width = 19
	height = 19
	pixel_x = 6
	pixel_y = 9
	framed_offset_x = 8
	framed_offset_y = 9

/obj/item/canvas/twentythreeXnineteen
	name = "Big Canvas"
	icon_state = "23x19"
	width = 23
	height = 19
	pixel_x = 4
	pixel_y = 10
	framed_offset_x = 6
	framed_offset_y = 8

/obj/item/canvas/twentythreeXtwentythree
	name = "B-Big Canvas"
	icon_state = "23x23"
	width = 23
	height = 23
	pixel_x = 5
	pixel_y = 9
	framed_offset_x = 5
	framed_offset_y = 6

/obj/item/canvas/ultra_big
	name = "B-B-Big Canvas"
	icon_state = "32x32"
	width = 31
	height = 31
	pixel_x = 1
	pixel_y = 1
	framed_offset_x = 1
	framed_offset_y = 1

/obj/item/canvas/twentyfour_twentyfour
	name = "Ai Universal Standard Canvas"
	desc = "Besides being very large, the AI can accept these as a display from their internal database after you've hung it up."
	icon_state = "24x24"
	width = 24
	height = 24
	pixel_x = 2
	pixel_y = 1
	framed_offset_x = 4
	framed_offset_y = 5

/obj/item/canvas/thirtysix_twentyfour
	name = "Large Canvas"
	desc = "A very large canvas to draw out your soul on. You'll need a larger frame to put it on a wall."
	icon_state = "32x32" //The vending spritesheet needs the icons to be 32x32. We'll set the actual icon on Initialize.
	width = 36
	height = 24
	pixel_x = -4
	pixel_y = 4
	framed_offset_x = 14
	framed_offset_y = 4
	w_class = WEIGHT_CLASS_BULKY

	custom_price = PRICE_NORMAL * 1.25

	base_pixel_x = -4
	base_pixel_y = 4

/obj/item/canvas/thirtysix_twentyfour/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.8)
	icon = 'icons/obj/art/artstuff_64x64.dmi'
	icon_state = "36x24"

/obj/item/canvas/fortyfive_twentyseven
	name = "Ultra-Large Canvas"
	desc = "The largest canvas available on the space market. You'll need a larger frame to put it on a wall."
	icon_state = "32x32" //The vending spritesheet needs the icons to be 32x32. We'll set the actual icon on Initialize.
	width = 45
	height = 27
	pixel_x = -8
	pixel_y = 2
	framed_offset_x = 9
	framed_offset_y = 4
	w_class = WEIGHT_CLASS_BULKY

	custom_price = PRICE_NORMAL * 1.75

	base_pixel_x = -8
	base_pixel_y = 4

/obj/item/canvas/fortyfive_twentyseven/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/item_scaling, 1, 0.7)
	icon = 'icons/obj/art/artstuff_64x64.dmi'
	icon_state = "45x27"

/obj/item/wallframe/painting
	name = "painting frame"
	desc = "The perfect showcase for your favorite deathtrap memories."
	icon = 'icons/obj/decals.dmi'
	custom_materials = list(/datum/material/wood = 2000)
	flags_1 = NONE
	icon_state = "frame-empty"
	result_path = /obj/structure/sign/painting

/obj/structure/sign/painting
	name = "Painting"
	desc = "Art or \"Art\"? You decide."
	icon = 'icons/obj/decals.dmi'
	icon_state = "frame-empty"
	// base_icon_state = "frame"
	custom_materials = list(/datum/material/wood = 2000)
	buildable_sign = FALSE
	///Canvas we're currently displaying.
	var/obj/item/canvas/current_canvas
	///Description set when canvas is added.
	var/desc_with_canvas
	var/persistence_id
	/// The list of canvas types accepted by this frame
	var/list/accepted_canvas_types = list(
		/obj/item/canvas,
		/obj/item/canvas/nineteenXnineteen,
		/obj/item/canvas/twentythreeXnineteen,
		/obj/item/canvas/twentythreeXtwentythree,
		/obj/item/canvas/twentyfour_twentyfour,
		/obj/item/canvas/ultra_big
	)
	/// the type of wallframe it 'disassembles' into
	var/wallframe_type = /obj/item/wallframe/painting
	var/transform_old
	var/pixel_y_old
	var/pixel_x_old

/obj/item/wallframe/painting/large
	name = "large painting frame"
	desc = "The perfect showcase for your favorite deathtrap memories. Make sure you have enough space to mount this one to the wall."
	custom_materials = list(/datum/material/wood = 2000*2)
	result_path = /obj/structure/sign/painting/large
	pixel_shift = 0
	custom_price = PRICE_NORMAL * 1.25

/obj/item/wallframe/painting/large/Initialize(mapload)
	. = ..()
	icon = 'icons/obj/art/artstuff_64x64.dmi' //The vending spritesheet needs the icons to be 32x32. We'll set the actual icon on Initialize.

/obj/item/wallframe/painting/large/try_build(turf/on_wall, mob/user)
	. = ..()
	if(!.)
		return
	var/our_dir = get_dir(user, on_wall)
	var/check_dir = our_dir & (EAST|WEST) ? NORTH : EAST
	var/turf/closed/wall/second_wall = get_step(on_wall, check_dir)
	if(!istype(second_wall) || !user.CanReach(second_wall))
		to_chat(user, span_warning("You need a reachable wall to the [check_dir == EAST ? "right" : "left"] of this one to mount this frame!"))
		return FALSE

/obj/item/wallframe/painting/large/after_attach(obj/object)
	. = ..()
	var/obj/structure/sign/painting/large/our_frame = object
	our_frame.finalize_size()

/obj/structure/sign/painting/large
	icon = 'icons/obj/art/artstuff_64x64.dmi'
	custom_materials = list(/datum/material/wood = 2000*2)
	accepted_canvas_types = list(
		/obj/item/canvas/thirtysix_twentyfour,
		/obj/item/canvas/fortyfive_twentyseven,
	)
	wallframe_type = /obj/item/wallframe/painting/large

/obj/structure/sign/painting/large/Initialize(mapload)
	. = ..()
	// Necessary so that the painting is framed correctly by the frame overlay when flipped.
	ADD_KEEP_TOGETHER(src, INNATE_TRAIT)
	if(mapload)
		finalize_size()

/obj/structure/sign/painting/large/library
	name = "\improper Large Painting Exhibit mounting"
	desc = "For the bulkier art pieces, hand-picked by the curator."
	desc_with_canvas = "A curated, large piece of art (or \"art\"). Hopefully the price of the canvas was worth it."
	persistence_id = "library_large"

/obj/structure/sign/painting/large/library_private
	name = "\improper Private Painting Exhibit mounting"
	desc = "For the privier and less tasteful compositions that oughtn't to be shown in a parlor nor to the masses."
	desc_with_canvas = "A painting that oughn't to be shown to the less open-minded commoners."
	persistence_id = "library_large_private"

/obj/structure/sign/painting/large/frame_canvas(mob/user, obj/item/canvas/new_canvas)
	. = ..()
	if(.)
		set_painting_offsets()

/obj/structure/sign/painting/large/load_persistent()
	deoffset_painting()
	. = ..()
	if(.)
		set_painting_offsets()

/obj/structure/sign/painting/large/proc/set_painting_offsets()
	icon_state = null
	transform_old = transform
	pixel_x_old = pixel_x
	pixel_y_old = pixel_y
	switch(dir)
		if(EAST)
			transform = transform.Turn(90)
		if(WEST)
			transform = transform.Turn(90)
			pixel_y += 32
		if(NORTH)
			transform = transform.Turn(180)

/obj/structure/sign/painting/large/proc/deoffset_painting()
	icon_state = "frame-empty"
	transform = transform_old
	pixel_x = pixel_x_old
	pixel_y = pixel_y_old

/**
 * This frame is visually put between two wall turfs and it has an icon that's bigger than 32px, and because
 * of the way it's designed, the pixel_shift variable from the wallframe item won't do.
 * Also we want higher bounds so it actually covers an extra wall turf, so that it can count toward check_wall_item calls for
 * that wall turf.
 */
/obj/structure/sign/painting/large/proc/finalize_size()
	switch(dir)
		if(SOUTH)
			bound_width = 64
		if(NORTH)
			transform = transform.Turn(180)
			pixel_y = -32
			bound_width = 64
		if(WEST)
			// Totally intended so that the frame sprite doesn't spill behind the wall and get partly covered by the darkness plane.
			// Ditto for the ones below.
			bound_height = 64
		if(EAST)
			transform = transform.Turn(180)
			pixel_x = -32
			bound_height = 64
	transform_old = transform
	pixel_x_old = pixel_x
	pixel_y_old = pixel_y

/obj/structure/sign/painting/Initialize(mapload, dir, building)
	. = ..()
	SSpersistence.painting_frames += src
	AddElement(/datum/element/art, 20)
	if(dir)
		setDir(dir)
	if(building)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -30 : 30)
		pixel_y = (dir & 3)? (dir ==1 ? -30 : 30) : 0
	desc = current_canvas ? desc_with_canvas : initial(desc)

/obj/structure/sign/painting/Destroy()
	. = ..()
	SSpersistence.painting_frames -= src

/obj/structure/sign/painting/attackby(obj/item/I, mob/user, params)
	if(!current_canvas && istype(I, /obj/item/canvas))
		frame_canvas(user,I)
	else if(current_canvas && current_canvas.painting_name == initial(current_canvas.painting_name) && istype(I,/obj/item/pen))
		try_rename(user)
	else
		return ..()

/obj/structure/sign/painting/examine(mob/user)
	. = ..()
	if(persistence_id)
		. += "<span class='notice'>Any painting placed here will be archived at the end of the shift.</span>"
	else
		. += span_notice("Use screwdriver to remove frame from the wall.")
	if(current_canvas)
		current_canvas.ui_interact(user)
		. += "<span class='notice'>Use wirecutters to remove the painting.</span>"

/obj/structure/sign/painting/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(persistence_id)
		return
	user.visible_message("<span class='notice'>[user] starts removing [src]...</span>", \
							"<span class='notice'>You start unscrewing [src].</span>")
	I.play_tool_sound(src)
	if(I.use_tool(src, user, 3 SECONDS))
		playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
		user.visible_message("<span class='notice'>[user] unscrews [src].</span>", \
							"<span class='notice'>You unscrew [src].</span>")
		new wallframe_type(get_turf(user))
		remove_canvas()
		qdel(src)
		return TRUE

/obj/structure/sign/painting/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(remove_canvas())
		I.play_tool_sound(src)
		to_chat(user, "<span class='notice'>You remove the painting from the frame.</span>")
		return TRUE

/obj/structure/sign/painting/proc/remove_canvas()
	if(!current_canvas)
		return

	if(istype(src, /obj/structure/sign/painting/large))
		var /obj/structure/sign/painting/large/P = src
		P.deoffset_painting()
	current_canvas.forceMove(drop_location())
	current_canvas = null
	update_icon()
	return TRUE

/obj/structure/sign/painting/proc/frame_canvas(mob/user,obj/item/canvas/new_canvas)
	if(!(new_canvas.type in accepted_canvas_types))
		to_chat(user, span_warning("[new_canvas] won't fit in this frame."))
		return FALSE
	if(user.transferItemToLoc(new_canvas,src))
		current_canvas = new_canvas
		if(!current_canvas.finalized)
			current_canvas.finalize(user)
		to_chat(user,"<span class='notice'>You frame [current_canvas].</span>")
		update_icon()
		return TRUE
	return FALSE

/obj/structure/sign/painting/proc/try_rename(mob/user)
	if(current_canvas.painting_name == initial(current_canvas.painting_name))
		current_canvas.try_rename(user)

// /obj/structure/sign/painting/update_name(updates)
// 	name = current_canvas ? "painting - [current_canvas.painting_name]" : initial(name)
// 	return ..()

// /obj/structure/sign/painting/update_desc(updates)
// 	desc = current_canvas ? desc_with_canvas : initial(desc)
// 	return ..()

/obj/structure/sign/painting/update_icon_state()
	// icon_state = "[base_icon_state]-[current_canvas?.generated_icon ? "overlay" : "empty"]"
	if(current_canvas?.generated_icon)
		icon_state = "frame-empty"
	else
		icon_state = "frame-empty" // or "frame-empty"
	return ..()

/obj/structure/sign/painting/update_overlays()
	. = ..()
	if(!current_canvas?.generated_icon)
		return

	var/mutable_appearance/MA = mutable_appearance(current_canvas.generated_icon)
	MA.pixel_x = current_canvas.framed_offset_x
	MA.pixel_y = current_canvas.framed_offset_y
	. += MA
	var/mutable_appearance/frame = mutable_appearance(current_canvas.icon,"[current_canvas.icon_state]frame")
	frame.pixel_x = current_canvas.framed_offset_x - 1
	frame.pixel_y = current_canvas.framed_offset_y - 1
	. += frame

/obj/structure/sign/painting/proc/load_persistent()
	if(!persistence_id)
		return
	if(!SSpersistence.paintings || !SSpersistence.paintings[persistence_id] || !length(SSpersistence.paintings[persistence_id]))
		return
	var/list/chosen = pick(SSpersistence.paintings[persistence_id])
	var/title = chosen["title"]
	var/author = chosen["ckey"]
	var/png = "data/paintings/[persistence_id]/[chosen["md5"]].png"
	if(!title)
		title = "Untitled Artwork" //Should prevent NULL named art from loading as NULL, if you're still getting the admin log chances are persistence is broken
	if(!title)
		message_admins("<span class='notice'>Painting with NO TITLE loaded on a [persistence_id] frame in [get_area(src)]. Please delete it, it is saved in the database with no name and will create bad assets.</span>")
	if(!fexists(png))
		stack_trace("Persistent painting [chosen["md5"]].png was not found in [persistence_id] directory.")
		return
	var/icon/I = new(png)
	var/obj/item/canvas/new_canvas
	var/w = I.Width()
	var/h = I.Height()
	for(var/T in typesof(/obj/item/canvas))
		new_canvas = T
		if(initial(new_canvas.width) == w && initial(new_canvas.height) == h)
			new_canvas = new T(src)
			break
	new_canvas.fill_grid_from_icon(I)
	new_canvas.generated_icon = I
	new_canvas.icon_generated = TRUE
	new_canvas.finalized = TRUE
	new_canvas.painting_name = title
	new_canvas.author_ckey = author
	new_canvas.name = "painting - [title]"
	current_canvas = new_canvas
	current_canvas.update_icon()
	update_icon()
	return TRUE

/obj/structure/sign/painting/proc/save_persistent()
	if(!persistence_id || !current_canvas || current_canvas.no_save)
		return
	if(sanitize_filename(persistence_id) != persistence_id)
		stack_trace("Invalid persistence_id - [persistence_id]")
		return
	if(!current_canvas.painting_name)
		current_canvas.painting_name = "Untitled Artwork"
	var/data = current_canvas.get_data_string()
	var/md5 = md5(lowertext(data))
	var/list/current = SSpersistence.paintings[persistence_id]
	if(!current)
		current = list()
	for(var/list/entry in current)
		if(entry["md5"] == md5)
			return
	var/png_directory = "data/paintings/[persistence_id]/"
	var/png_path = png_directory + "[md5].png"
	var/result = rustg_dmi_create_png(png_path,"[current_canvas.width]","[current_canvas.height]",data)
	if(result)
		CRASH("Error saving persistent painting: [result]")
	current += list(list("title" = current_canvas.painting_name , "md5" = md5, "ckey" = current_canvas.author_ckey))
	SSpersistence.paintings[persistence_id] = current

/obj/item/canvas/proc/fill_grid_from_icon(icon/I)
	var/h = I.Height() + 1
	for(var/x in 1 to width)
		for(var/y in 1 to height)
			grid[x][y] = I.GetPixel(x,h-y)

//Presets for art gallery mapping, for paintings to be shared across stations
/obj/structure/sign/painting/library
	name = "\improper Public Painting Exhibit mounting"
	desc = "For art pieces hung by the public."
	desc_with_canvas = "A piece of art (or \"art\"). Anyone could've hung it."
	persistence_id = "library"

/obj/structure/sign/painting/library_secure
	name = "\improper Curated Painting Exhibit mounting"
	desc = "For masterpieces hand-picked by the curator."
	desc_with_canvas = "A masterpiece hand-picked by the curator, supposedly."
	persistence_id = "library_secure"

/obj/structure/sign/painting/library_private // keep your smut away from prying eyes, or non-librarians at least
	name = "\improper Private Painting Exhibit mounting"
	desc = "For art pieces deemed too subversive or too illegal to be shared outside of curators."
	desc_with_canvas = "A painting hung away from lesser minds."
	persistence_id = "library_private"

/obj/structure/sign/painting/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_REMOVE_PAINTING, "Remove Persistent Painting")

/obj/structure/sign/painting/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_REMOVE_PAINTING])
		if(!check_rights(NONE))
			return
		var/mob/user = usr
		if(!persistence_id || !current_canvas)
			to_chat(user,"<span class='warning'>This is not a persistent painting.</span>")
			return
		var/md5 = md5(lowertext(current_canvas.get_data_string()))
		var/author = current_canvas.author_ckey
		var/list/current = SSpersistence.paintings[persistence_id]
		if(current)
			for(var/list/entry in current)
				if(entry["md5"] == md5)
					current -= entry
			var/png = "data/paintings/[persistence_id]/[md5].png"
			fdel(png)
		for(var/obj/structure/sign/painting/P in SSpersistence.painting_frames)
			if(P.current_canvas && md5(P.current_canvas.get_data_string()) == md5)
				QDEL_NULL(P.current_canvas)
				P.update_icon()
		log_admin("[key_name(user)] has deleted a persistent painting made by [author].")
		message_admins("<span class='notice'>[key_name_admin(user)] has deleted persistent painting made by [author].</span>")



// Library public assets
/obj/structure/sign/painting/large/library/directional/north
	dir = SOUTH
	pixel_y = 32

/obj/structure/sign/painting/large/library/directional/south
	dir = NORTH
	pixel_y = -64

/obj/structure/sign/painting/large/library/directional/east
	dir = WEST
	pixel_x = 32

/obj/structure/sign/painting/large/library/directional/west
	dir = EAST
	pixel_x = -64

// Library private assets
/obj/structure/sign/painting/large/library_private/directional/north
	dir = SOUTH
	pixel_y = 32

/obj/structure/sign/painting/large/library_private/directional/south
	dir = NORTH
	pixel_y = -64

/obj/structure/sign/painting/large/library_private/directional/east
	dir = WEST
	pixel_x = 32

/obj/structure/sign/painting/large/library_private/directional/west
	dir = EAST
	pixel_x = -64
