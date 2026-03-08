/mob/var/mode = "RGB to Greyscale"

/mob/verb/ChangeMode()
	set name = "Change mode"
	mode = mode == "RGB to Greyscale" ? "Greyscale to RGB" : "RGB to Greyscale"
	world << "Current mode: [mode]"

/mob/verb/ChooseDMI(dmi as icon)
	if(isicon(dmi))
		SliceNDice(dmi)
	else
		world << "\red Bad DMI file '[file2text(dmi)]'"

/datum/greyscale_holder
	var/name
	var/list/what_we_got = list()
	var/base_icon_state_name

/mob/proc/gen_grayscale(icon/sourceIcon, icon/outputIcon, state)
	var/icon/rgb_icon = icon(sourceIcon, state)

	var/icon/red = icon(rgb_icon)
	red.Blend(rgb(0,255,255), ICON_SUBTRACT)
	red.SwapColor(rgb(0,0,0),rgb(0,0,0,0))
	red.MapColors(1,1,1, 0,0,0, 0,0,0, 0,0,0)
	outputIcon.Insert(red, "[state]_primary")
	var/icon/green = icon(rgb_icon)
	green.Blend(rgb(255,0,255), ICON_SUBTRACT)
	green.SwapColor(rgb(0,0,0),rgb(0,0,0,0))
	green.MapColors(0,0,0, 1,1,1, 0,0,0, 0,0,0)
	outputIcon.Insert(green, "[state]_secondary")
	var/icon/blue = icon(rgb_icon)
	blue.Blend(rgb(255,255,0), ICON_SUBTRACT)
	blue.SwapColor(rgb(0,0,0),rgb(0,0,0,0))
	blue.MapColors(0,0,0, 0,0,0, 1,1,1, 0,0,0)
	outputIcon.Insert(blue, "[state]_tertiary")
//	world << "RGB -> Grayscale: \icon[rgb_icon] -> \icon[red] \icon[green] \icon[blue]"

/mob/proc/SliceNDice(dmifile)
	var/icon/sourceIcon = icon(dmifile)
	var/list/states = sourceIcon.IconStates()
	world << "<B>[dmifile] - states: [states.len]</B>"

	var/icon/outputIcon = new /icon()
	var/icon/outputIcon2 = new /icon()
	var/filename
	if(mode == "Greyscale to RGB")
		filename = "[copytext("[dmifile]", 1, -4)]"
		fdel("[filename]-rgb.dmi")
		fdel("[filename]-rgb-welded.dmi")
	else
		filename = "[copytext("[dmifile]", 1, -4)]-greyscale.dmi"
		fdel(filename)

	var/list/states_groups = alist()
	if(mode == "RGB to Greyscale")
		for(var/state in states)
			gen_grayscale(sourceIcon, outputIcon, state)

	else if(mode == "Greyscale to RGB")
		for(var/state in states)
			var/used_color = findtext(state, "_primary") ? "_primary" : findtext(state, "_secondary") ? "_secondary" : findtext(state, "_tertiary") ? "_tertiary" : "single"
			if(used_color != "single")
				var/base_icon_state_name = "[copytext("[state]", 1, -length(used_color))]"
				var/added = FALSE
				for(var/datum/greyscale_holder/i in states_groups)
					if(i.name == base_icon_state_name)
						i.what_we_got += state
						added = TRUE
						break
				if(!added)
					var/datum/greyscale_holder/group = new(src.contents)
					group.name = base_icon_state_name
					group.what_we_got += state
					states_groups += group

			var/icon/curren_icon = icon(sourceIcon, state)
			switch(used_color)
				if("_primary", "single")
					curren_icon.SetIntensity(1,0,0)
				if("_secondary")
					curren_icon.SetIntensity(0,1,0)
				if("_tertiary")
					curren_icon.SetIntensity(0,0,1)
			outputIcon.Insert(curren_icon, state)
		for(var/datum/greyscale_holder/i in states_groups)
			var/icon/first_layer
			var/icon/second_layer
			var/icon/third_layer
			if("[i.name]_primary" in i.what_we_got)
				first_layer = icon(outputIcon, "[i.name]_primary")
			else if(i.what_we_got.len == 1)
				first_layer = icon(outputIcon, i.what_we_got[1])
			if("[i.name]_secondary" in i.what_we_got)
				second_layer = icon(outputIcon, "[i.name]_secondary")
				if(first_layer)
					first_layer.Blend(second_layer, ICON_OVERLAY)
			if("[i.name]_tertiary" in i.what_we_got)
				third_layer = icon(outputIcon, "[i.name]_tertiary")
				if(first_layer)
					first_layer.Blend(third_layer, ICON_OVERLAY)
				else if(second_layer)
					second_layer.Blend(third_layer, ICON_OVERLAY)
			if(first_layer || second_layer || third_layer)
				outputIcon2.Insert(first_layer ? first_layer : second_layer ? second_layer : third_layer, i.name)

	if(mode == "RGB to Greyscale")
		fcopy(outputIcon, filename)	//Update output icon each iteration
		world << "Finished [filename]"
	else
		fcopy(outputIcon, "[filename]-rgb.dmi")
		fcopy(outputIcon2, "[filename]-rgb-welded.dmi")
		world << "Finished [filename]-rgb.dmi!"
		world << "Finished [filename]-rgb-welded.dmi!"
