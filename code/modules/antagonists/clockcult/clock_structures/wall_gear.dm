//A massive gear, effectively a girder for clocks.
/obj/structure/destructible/clockwork/wall_gear
	name = "massive gear"
	icon_state = "wall_gear"
	unanchored_icon = "wall_gear"
	climbable = TRUE
	max_integrity = 100
	construction_value = 3
	desc = "Массивная латунная шестерня. Вероятно, вы могли бы закрепить или снять ее с помощью гаечного ключа или просто перелезть через нее."
	break_message = "<span class='warning'>Шестеренка разлетается на куски сплава!</span>"
	debris = list(/obj/item/clockwork/alloy_shards/large = 1, \
	/obj/item/clockwork/alloy_shards/medium = 4, \
	/obj/item/clockwork/alloy_shards/small = 2) //slightly more debris than the default, totals 26 alloy

/obj/structure/destructible/clockwork/wall_gear/displaced
	anchored = FALSE

/obj/structure/destructible/clockwork/wall_gear/Initialize(mapload)
	. = ..()
	new /obj/effect/temp_visual/ratvar/gear(get_turf(src))

/obj/structure/destructible/clockwork/wall_gear/emp_act(severity)
	return

/obj/structure/destructible/clockwork/wall_gear/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		default_unfasten_wrench(user, I, 10)
		return TRUE
	else if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(anchored)
			to_chat(user, "<span class='warning'>[src] должен быть откручен, чтобы его можно было разобрать!</span>")
		else
			user.visible_message("<span class='warning'>[user] начинает разбирать [src].</span>", "<span class='notice'>Вы начинаете разбирать [src]...</span>")
			if(I.use_tool(src, user, 30, volume=100) && !anchored)
				to_chat(user, "<span class='notice'>Вы разбираете [src].</span>")
				deconstruct(TRUE)
		return TRUE
	else if(istype(I, /obj/item/stack/tile/brass))
		var/obj/item/stack/tile/brass/W = I
		if(W.get_amount() < 1)
			to_chat(user, "<span class='warning'>Вам нужен минимум один лист латуни для этого!</span>")
			return
		var/turf/T = get_turf(src)
		if(iswallturf(T))
			to_chat(user, "<span class='warning'>Здесь уже есть стена!</span>")
			return
		if(!isfloorturf(T))
			to_chat(user, "<span class='warning'>Для создания [anchored ? "фальшивой ":""]стены здесь должен быть пол!</span>")
			return
		if(locate(/obj/structure/falsewall) in T.contents)
			to_chat(user, "<span class='warning'>Здесь уже есть фальшивая стена!</span>")
			return
		to_chat(user, "<span class='notice'>Вы начинаете добавлять [W] к [src]...</span>")
		if(do_after(user, 20, target = src))
			var/brass_floor = FALSE
			if(istype(T, /turf/open/floor/clockwork)) //if the floor is already brass, costs less to make(conservation of masssssss)
				brass_floor = TRUE
			if(W.use(2 - brass_floor))
				if(anchored)
					T.PlaceOnTop(/turf/closed/wall/clockwork)
				else
					T.PlaceOnTop(/turf/open/floor/clockwork, flags = CHANGETURF_INHERIT_AIR)
					new /obj/structure/falsewall/brass(T)
				qdel(src)
			else
				to_chat(user, "<span class='warning'>Вам нужно больше латуни, чтобы создать [anchored ? "фальшивую ":""]стену!</span>")
		return TRUE
	return ..()

/obj/structure/destructible/clockwork/wall_gear/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1) && disassembled)
		new /obj/item/stack/tile/brass(loc, 3)
	return ..()
