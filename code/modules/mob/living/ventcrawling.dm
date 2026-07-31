
GLOBAL_LIST_INIT(ventcrawl_machinery, typecacheof(list(
	/obj/machinery/atmospherics/components/unary/vent_pump,
	/obj/machinery/atmospherics/components/unary/vent_scrubber)))

//VENTCRAWLING

/mob/living/proc/handle_ventcrawl(atom/A, ventcrawler)
	if(!ventcrawler || !Adjacent(A))
		return
	. = TRUE //return value to stop the client from being shown the turf contents stat tab on alt-click.
	if(stat)
		to_chat(src, "You must be conscious to do this!")
		return
	if(lying)
		to_chat(src, "You can't vent crawl while you're stunned!")
		return
	if(restrained())
		to_chat(src, "You can't vent crawl while you're restrained!")
		return
	if(has_buckled_mobs())
		// attempt once
		unbuckle_all_mobs()
		if(has_buckled_mobs())
			to_chat(src, "You can't vent crawl with other creatures on you!")
			return
	if(buckled)
		to_chat(src, "You can't vent crawl while buckled!")
		return

	var/obj/machinery/atmospherics/components/unary/vent_found


	if(A)
		vent_found = A
		if(!istype(vent_found) || !vent_found.can_crawl_through())
			vent_found = null

	if(!vent_found)
		for(var/obj/machinery/atmospherics/machine in range(1,src))
			if(is_type_in_typecache(machine, GLOB.ventcrawl_machinery))
				vent_found = machine

			if(!vent_found.can_crawl_through())
				vent_found = null

			if(vent_found)
				break


	if(vent_found)
		var/datum/pipeline/vent_found_parent = vent_found.parents[1]
		if(vent_found_parent && (vent_found_parent.members.len || vent_found_parent.other_atmosmch))
			visible_message("<span class='notice'>[src] лезет в вентиляцию...</span>" ,"<span class='notice'>Ты лезешь в вентиляцию...</span>")

			if(!do_after(src, 25, target = vent_found))
				return

			if(!client)
				return

			if(iscarbon(src) && ventcrawler==VENTCRAWLER_NUDE)
				if(length(get_equipped_items(include_pockets = TRUE)) || get_num_held_items())
					to_chat(src, "<span class='warning'>You can't crawl around in the ventilation ducts with items!</span>")
					return

			visible_message("<span class='notice'>[src] scrambles into the ventilation ducts!</span>","<span class='notice'>You climb into the ventilation ducts.</span>")
			forceMove(vent_found)
	else
		to_chat(src, "<span class='warning'>This ventilation duct is not connected to anything!</span>")

/mob/living/simple_animal/slime/handle_ventcrawl(atom/A)
	if(buckled)
		to_chat(src, "<i>I can't vent crawl while feeding...</i>")
		return
	..()


/// Collects members of pipenet_members whose turf lies inside the square box of
/// half-size view_half around source_turf, appending them to output.
/// The bounds are hoisted out of the loop on purpose: the old path called
/// in_view_range() -> getviewsize() (a proc call plus a list allocation) once
/// per pipe, which on a station distro loop is thousands of calls per
/// ventcrawl step (perf.log: 750k in_view_range calls per round).
/proc/collect_pipes_in_view(turf/source_turf, view_half, list/pipenet_members, list/output)
	var/min_x = source_turf.x - view_half
	var/max_x = source_turf.x + view_half
	var/min_y = source_turf.y - view_half
	var/max_y = source_turf.y + view_half
	var/source_z = source_turf.z
	for(var/obj/machinery/atmospherics/member as anything in pipenet_members)
		var/turf/member_turf = member.loc
		if(!isturf(member_turf))
			member_turf = get_turf(member)
			if(isnull(member_turf))
				continue
		// z check is new vs in_view_range(): it compared raw x/y only, so pipes
		// on other z-levels at matching coordinates got phantom vision images
		if(member_turf.z != source_z)
			continue
		if(member_turf.x < min_x || member_turf.x > max_x || member_turf.y < min_y || member_turf.y > max_y)
			continue
		output += member

/mob/living/proc/add_ventcrawl(obj/machinery/atmospherics/starting_machine)
	if(!istype(starting_machine) || !starting_machine.can_see_pipes())
		return
	if(!client) // pipe vision images are per-client; without one there is nothing to build
		return

	var/mob/viewer = client.mob || src
	var/turf/source_turf = get_turf(viewer)
	if(isnull(source_turf))
		return

	// in_view_range() used the view width for both axes; keep that behavior
	var/list/view_size = getviewsize(client.view)
	var/view_half = view_size[1]

	var/any_members = FALSE
	var/list/visible_members = list()
	for(var/datum/pipeline/pipenet in starting_machine.returnPipenets())
		if(length(pipenet.members) || length(pipenet.other_atmosmch))
			any_members = TRUE
		collect_pipes_in_view(source_turf, view_half, pipenet.members, visible_members)
		collect_pipes_in_view(source_turf, view_half, pipenet.other_atmosmch, visible_members)

	if(!any_members)
		return

	var/list/new_images = list()
	for(var/obj/machinery/atmospherics/shown as anything in visible_members)
		if(!shown.pipe_vision_img)
			shown.pipe_vision_img = image(shown, shown.loc, layer = ABOVE_HUD_LAYER, dir = shown.dir)
			shown.pipe_vision_img.plane = ABOVE_HUD_PLANE
		new_images += shown.pipe_vision_img
	if(length(new_images))
		client.images += new_images // single batched list op instead of one per pipe
		pipes_shown += new_images
	setMovetype(movement_type | VENTCRAWLING)


/mob/living/proc/remove_ventcrawl()
	if(client && length(pipes_shown))
		client.images -= pipes_shown // batched removal instead of one list op per image
	pipes_shown.len = 0
	setMovetype(movement_type & ~VENTCRAWLING)




//OOP
/atom/proc/update_pipe_vision(atom/new_loc = null)
	return

/mob/living/update_pipe_vision(atom/new_loc = null)
	. = loc
	if(new_loc)
		. = new_loc
	remove_ventcrawl()
	add_ventcrawl(.)

