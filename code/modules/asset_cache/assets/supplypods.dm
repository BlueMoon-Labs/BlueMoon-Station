/datum/asset/spritesheet_batched/supplypods
	name = "supplypods"

/datum/asset/spritesheet_batched/supplypods/create_spritesheets()
	for(var/style in 1 to length(GLOB.podstyles))
		if(style == STYLE_SEETHROUGH)
			insert_icon("pod_asset[style]", uni_icon('icons/obj/supplypods.dmi', "seethrough-icon", SOUTH))
			continue
		var/base = GLOB.podstyles[style][POD_BASE]
		if(!base)
			insert_icon("pod_asset[style]", uni_icon('icons/obj/supplypods.dmi', "invisible-icon", SOUTH))
			continue
		var/datum/universal_icon/pod_icon = uni_icon('icons/obj/supplypods.dmi', base, SOUTH)
		var/door = GLOB.podstyles[style][POD_DOOR]
		if(door)
			door = "[base]_door"
			pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', door, SOUTH), ICON_OVERLAY)
		var/shape = GLOB.podstyles[style][POD_SHAPE]
		if(shape == POD_SHAPE_NORML)
			var/decal = GLOB.podstyles[style][POD_DECAL]
			if(decal)
				pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', decal, SOUTH), ICON_OVERLAY)
			var/glow = GLOB.podstyles[style][POD_GLOW]
			if(glow)
				glow = "pod_glow_[glow]"
				pod_icon.blend_icon(uni_icon('icons/obj/supplypods.dmi', glow, SOUTH), ICON_OVERLAY)
		insert_icon("pod_asset[style]", pod_icon)
