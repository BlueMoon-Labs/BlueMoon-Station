//No, not that kind.
/obj/structure/destructible/clockwork/trap
	name = "base clockwork trap"
	desc = "Ты не должен этого видеть. Отправьте сообщение о баге!"
	clockwork_desc = "Ловушка, которой не должно быть, и вы должны сообщить об этом как о баге."
	var/list/wired_to

/obj/structure/destructible/clockwork/trap/Initialize(mapload)
	. = ..()
	wired_to = list()

/obj/structure/destructible/clockwork/trap/Destroy()
	for(var/V in wired_to)
		var/obj/structure/destructible/clockwork/trap/T = V
		T.wired_to -= src
	return ..()

/obj/structure/destructible/clockwork/trap/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "Он подключен к:"
		if(!wired_to.len)
			. += "Ничему."
		else
			for(var/V in wired_to)
				var/obj/O = V
				var/distance = get_dist(src, O)
				. += "[O] ([distance == 0 ? "на той же клетке" : "[distance] клеток на [dir2text(get_dir(src, O))]"])"

/obj/structure/destructible/clockwork/trap/wrench_act(mob/living/user, obj/item/I)
	if(!is_servant_of_ratvar(user))
		return ..()
	to_chat(user, "<span class='notice'>Вы превращаете хрупкие компоненты [src] в латунь.</span>")
	I.play_tool_sound(src)
	new/obj/item/stack/tile/brass(get_turf(src))
	qdel(src)
	return TRUE

/obj/structure/destructible/clockwork/trap/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/clockwork/slab) && is_servant_of_ratvar(user))
		var/obj/item/clockwork/slab/F = I
		if(!F.linking)
			to_chat(user, "<span class='notice'>Начало связи. Альт-клик по плите для отмены, или используйте плиту на другой ловушке, чтобы связать их.</span>")
			F.linking = src
		else
			if(F.linking in wired_to)
				to_chat(user, "<span class='warning'>Эти два объекта уже соединены!</span>")
				return
			if(F.linking.z != z)
				to_chat(user, "<span class='warning'>Чтобы соединить два объекта в разных секторах, вам понадобится <b>намного</b> более прочная плита.</span>")
				return
			to_chat(user, "<span class='notice'>Вы соединяете [F.linking] с [src].</span>")
			wired_to += F.linking
			F.linking.wired_to += src
			F.linking = null
		return
	..()

/obj/structure/destructible/clockwork/trap/wirecutter_act(mob/living/user, obj/item/I)
	if(!is_servant_of_ratvar(user))
		return
	if(!wired_to.len)
		to_chat(user, "<span class='warning'>[src] не имеет никаких связей!</span>")
		return
	to_chat(user, "<span class='notice'>Вы разрываете все связи с [src].</span>")
	I.play_tool_sound(src)
	for(var/V in wired_to)
		var/obj/structure/destructible/clockwork/trap/T = V
		T.wired_to -= src
		wired_to -= T
	return TRUE

/obj/structure/destructible/clockwork/trap/proc/activate()
	return

//These objects send signals to normal traps to activate
/obj/structure/destructible/clockwork/trap/trigger
	name = "base trap trigger"
	max_integrity = 5
	break_message = "<span class='warning'>Триггер разламывается на части!</span>"
	density = FALSE

/obj/structure/destructible/clockwork/trap/trigger/Initialize(mapload)
	. = ..()
	for(var/obj/structure/destructible/clockwork/trap/T in get_turf(src))
		if(!istype(T, /obj/structure/destructible/clockwork/trap/trigger))
			wired_to += T
			T.wired_to += src
			to_chat(usr, "<span class='alloy'>[src] автоматически связывается с [T] под ним.</span>")

/obj/structure/destructible/clockwork/trap/trigger/activate()
	for(var/obj/structure/destructible/clockwork/trap/T in wired_to)
		if(istype(T, /obj/structure/destructible/clockwork/trap/trigger)) //Triggers don't go off multiple times
			continue
		T.activate()
