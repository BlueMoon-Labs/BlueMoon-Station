/*

	† † † † † † † † † † † † † † † † † † † † † † † † † † † † † †

	Отче наш, сущий на небесах!

	Да святится имя Твое;

	Да приидет Царствие Твое;

	да будет воля Твоя и на земле, как на небе;

	Хлеб наш насущный дай нам на сей день;

	И прости нам долги наши, как и мы прощаем должникам нашим;

	И не введи нас в искушение, но избавь нас от лукавого.

	Ибо Твое есть Царство и сила и слава вовеки. Аминь.

													Мф. 6:9-13.

	† † † † † † † † † † † † † † † † † † † † † † † † † † † † † †

*/

/atom/movable/screen/plane_master
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	var/show_alpha = 255
	var/hide_alpha = 0

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob)

/atom/movable/screen/plane_master/Destroy()
	for(var/filter_name in list("singularity_0", "singularity_1", "singularity_2", "singularity_3"))
		var/filter = get_filter(filter_name)
		if(filter)
			animate(filter)
	return ..()

///Things rendered on "openspace"; holes in multi-z
/atom/movable/screen/plane_master/openspace
	name = "open space plane master"
	plane = OPENSPACE_BACKDROP_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
	alpha = 255

/atom/movable/screen/plane_master/openspace/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("displacer", 1, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 1, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 2, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

	filters += filter(type="alpha", render_source=FIELD_OF_VISION_RENDER_TARGET, flags=MASK_INVERSE)
	filters += filter(type="alpha", render_source = LIGHTING_RENDER_TARGET, flags = MASK_INVERSE)
	filters += filter(type = "drop_shadow", color = "#04080FAA", size = -10)
	filters += filter(type = "drop_shadow", color = "#04080FAA", size = -15)
	filters += filter(type = "drop_shadow", color = "#04080FAA", size = -20)

/atom/movable/screen/plane_master/proc/outline(_size, _color)
	filters += filter(type = "outline", size = _size, color = _color)

/atom/movable/screen/plane_master/proc/shadow(_size, _offset = 0, _x = 0, _y = 0, _color = "#04080FAA")
	filters += filter(type = "drop_shadow", x = _x, y = _y, color = _color, size = _size, offset = _offset)

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/floor/backdrop(mob/mymob)
	if(mymob?.client?.prefs?.ambientocclusion)
		var/blur_lvl = mymob?.client?.prefs?.lighting_blur || 0
		add_filter("ambient_occlusion", 0, AMBIENT_OCCLUSION_SCALED(2, "#04080F32", blur_lvl))
	else
		remove_filter("ambient_occlusion")

/atom/movable/screen/plane_master/floor/Initialize(mapload)
	. = ..()
	add_filter("displacer", 1, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 1, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 2, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

/atom/movable/screen/plane_master/wall
	name = "wall plane master"
	plane = WALL_PLANE
	appearance_flags = PLANE_MASTER

/atom/movable/screen/plane_master/wall/backdrop(mob/mymob)
	if(mymob?.client?.prefs?.ambientocclusion)
		var/blur_lvl = mymob?.client?.prefs?.lighting_blur || 0
		add_filter("ambient_occlusion", 0, AMBIENT_OCCLUSION_SCALED(4, "#04080FAA", blur_lvl))
	else
		remove_filter("ambient_occlusion")

/atom/movable/screen/plane_master/above_wall
	name = "above wall plane master"
	plane = ABOVE_WALL_PLANE
	appearance_flags = PLANE_MASTER

/atom/movable/screen/plane_master/above_wall/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("displacer", 1, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 1, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 2, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

	add_filter("vision_cone", 100, list(type="alpha", render_source=FIELD_OF_VISION_RENDER_TARGET, flags=MASK_INVERSE))

/atom/movable/screen/plane_master/above_wall/backdrop(mob/mymob)
	if(mymob?.client?.prefs?.ambientocclusion)
		var/blur_lvl = mymob?.client?.prefs?.lighting_blur || 0
		add_filter("ambient_occlusion", 0, AMBIENT_OCCLUSION_SCALED(3, "#04080F64", blur_lvl))
	else
		remove_filter("ambient_occlusion")

///Contains most things in the game world
/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world/Initialize(mapload, datum/hud/hud_owner)
	. = ..()

	add_filter("displacer", 1, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 1, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 2, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

	add_filter("vision_cone", 100, list(type="alpha", render_source=FIELD_OF_VISION_RENDER_TARGET, flags=MASK_INVERSE))

/atom/movable/screen/plane_master/game_world/backdrop(mob/mymob)
	if(mymob?.client?.prefs?.ambientocclusion)
		var/blur_lvl = mymob?.client?.prefs?.lighting_blur || 0
		add_filter("ambient_occlusion", 0, AMBIENT_OCCLUSION_SCALED(4, "#04080FAA", blur_lvl))
	else
		remove_filter("ambient_occlusion")

///Contains all shadow cone masks, whose image overrides are displayed only to their respective owners.
/atom/movable/screen/plane_master/field_of_vision
	name = "field of vision mask plane master"
	plane = FIELD_OF_VISION_PLANE
	render_target = FIELD_OF_VISION_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/field_of_vision/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	filters += filter(type="alpha", render_source=FIELD_OF_VISION_BLOCKER_RENDER_TARGET, flags=MASK_INVERSE)

///Used to display the owner and its adjacent surroundings through the FoV plane mask.
/atom/movable/screen/plane_master/field_of_vision_blocker
	name = "field of vision blocker plane master"
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	render_target = FIELD_OF_VISION_BLOCKER_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

///Stores the visible portion of the FoV shadow cone.
/atom/movable/screen/plane_master/field_of_vision_visual
	name = "field of vision visual plane master"
	plane = FIELD_OF_VISION_VISUAL_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/field_of_vision_visual/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	filters += filter(type="alpha", render_source=FIELD_OF_VISION_BLOCKER_RENDER_TARGET, flags=MASK_INVERSE)

///Contains all lighting objects
/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	if(!mymob)
		return
	mymob.overlay_fullscreen("lighting_backdrop_lit", /atom/movable/screen/fullscreen/special/lighting_backdrop/lit)
	mymob.overlay_fullscreen("lighting_backdrop_unlit", /atom/movable/screen/fullscreen/special/lighting_backdrop/unlit)
	var/blur_level = mymob?.client?.prefs?.lighting_blur || 0
	var/effective_blur = LIGHTING_BLUR_BASE + blur_level * LIGHTING_BLUR_MULTIPLIER
	if(effective_blur > 0)
		add_filter("lighting_blur", 0, list("type" = "blur", "size" = effective_blur))
		// Force alpha=1 after blur to prevent edge bleeding — blur samples transparent pixels
		// outside the render target boundary, creating semi-transparent edges that weaken
		// BLEND_MULTIPLY darkening and produce false light strips at screen edges
		add_filter("lighting_blur_edge_fix", 1, color_matrix_filter(list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,0, 0,0,0,1)))
	else
		remove_filter("lighting_blur")
		remove_filter("lighting_blur_edge_fix")

/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */

/atom/movable/screen/plane_master/lighting/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("emissives", 2, alpha_mask_filter(render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("object_lighting", 3, alpha_mask_filter(render_source = O_LIGHTING_VISUAL_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("displacer", 4, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 2, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 3, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "emissive plane master"
	plane = EMISSIVE_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = EMISSIVE_RENDER_TARGET

/atom/movable/screen/plane_master/emissive/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("em_block_masking", 1, color_matrix_filter(GLOB.em_mask_matrix))
	// emissive_bloom added conditionally in backdrop() based on blur quality setting

/atom/movable/screen/plane_master/emissive/backdrop(mob/mymob)
	var/blur_level = mymob?.client?.prefs?.lighting_blur || 0
	if(blur_level >= 2)
		// Bloom on emissive at medium+ quality — screens and indicators glow subtly
		add_filter("emissive_bloom", 2, bloom_filter(threshold = COLOR_BLACK, size = blur_level, offset = 1))
	else
		remove_filter("emissive_bloom")

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = PLANE_SPACE_PARALLAX_RENDER_TARGET

/atom/movable/screen/plane_master/parallax_white
	name = "parallax backdrop/space turf plane master"
	plane = PLANE_SPACE

/atom/movable/screen/plane_master/parallax_white/Initialize(mapload)
	. = ..()
	add_filter("displacer", 3, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

	add_filter("singularity_0", 1, displacement_map_filter(render_source = SINGULARITY_0_RENDER_TARGET, size = -20))
	add_filter("singularity_1", 2, displacement_map_filter(render_source = SINGULARITY_1_RENDER_TARGET, size = 75))
	add_filter("singularity_2", 3, displacement_map_filter(render_source = SINGULARITY_2_RENDER_TARGET, size = 400))
	add_filter("singularity_3", 4, displacement_map_filter(render_source = SINGULARITY_3_RENDER_TARGET, size = 700))

	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

/atom/movable/screen/plane_master/camera_static
	name = "camera static plane master"
	plane = CAMERA_STATIC_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

//Reserved to chat messages, so they are still displayed above the field of vision masking.
/atom/movable/screen/plane_master/chat_messages
	name = "runechat plane master"
	plane = CHAT_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY


/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	render_target = GRAVITY_PULSE_RENDER_TARGET
	blend_mode = BLEND_ADD
