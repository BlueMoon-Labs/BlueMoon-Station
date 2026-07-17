//Spatial gateway: A usually one-way rift to another location.
/obj/effect/clockwork/spatial_gateway
	name = "spatial gateway"
	desc = "Легко вибрирующий разрыв в реальности."
	clockwork_desc = "Пространственный разлом."
	icon_state = "spatial_gateway"
	density = TRUE
	light_range = 2
	light_power = 3
	light_color = "#6A4D2F"
	var/sender = TRUE //If this gateway is made for sending, not receiving
	var/both_ways = FALSE
	var/lifetime = 25 //How many deciseconds this portal will last
	var/uses = 1 //How many objects or mobs can go through the portal
	var/obj/effect/clockwork/spatial_gateway/linked_gateway //The gateway linked to this one
	var/timerid
	var/is_stable = FALSE
	var/busy = FALSE //If someone is already working on closing the gateway, only needed for stable gateways but in the parent to not need typecasting

/obj/effect/clockwork/spatial_gateway/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(check_setup)), 1)

/obj/effect/clockwork/spatial_gateway/Destroy()
	deltimer(timerid)
	return ..()

/obj/effect/clockwork/spatial_gateway/proc/check_setup()
	if(!linked_gateway)
		qdel(src)
		return
	if(both_ways)
		clockwork_desc = "Пространственный разлом. Он может как отправлять, так и принимать объекты."
	else
		clockwork_desc = "Пространственный разлом. Он может только [sender ? "отправлять" : "принимать"] объекты."
	if(is_stable)
		return
	timerid = QDEL_IN_STOPPABLE(src, lifetime) //We only need this if the gateway is not stable

//set up a gateway with another gateway
/obj/effect/clockwork/spatial_gateway/proc/setup_gateway(obj/effect/clockwork/spatial_gateway/gatewayB, set_duration, set_uses, two_way)
	if(!gatewayB)
		return FALSE

	if((!set_duration || !uses) && !is_stable)
		return FALSE
	linked_gateway = gatewayB
	gatewayB.linked_gateway = src
	if(two_way)
		both_ways = TRUE
		gatewayB.both_ways = TRUE
	else
		sender = TRUE
		gatewayB.sender = FALSE
		gatewayB.density = FALSE
	lifetime = set_duration
	gatewayB.lifetime = set_duration
	uses = set_uses
	gatewayB.uses = set_uses
	return TRUE

/obj/effect/clockwork/spatial_gateway/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='brass'> [is_stable ? "Он стабилизирован и может использоваться столько, сколько понадобится." : "Он имеет ещё [uses] использовани[uses % 10 == 1 && uses % 100 != 11 ? "е" : (uses % 10 >= 2 && uses % 10 <= 4 && !(uses % 100 >= 12 && uses % 100 <= 14) ? "я" : "й")]."]</span>"

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/clockwork/spatial_gateway/attack_ghost(mob/user)
	if(linked_gateway)
		user.forceMove(get_turf(linked_gateway))
	..()

/obj/effect/clockwork/spatial_gateway/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!uses)
		return FALSE
	if(user.pulling && user.a_intent == INTENT_GRAB && isliving(user.pulling))
		var/mob/living/L = user.pulling
		if(L.buckled || L.anchored || L.has_buckled_mobs())
			return FALSE
		user.visible_message("<span class='warning'>[user] толкает [L] в [src]!</span>", "<span class='danger'>Вы толкаете [L] в [src]!</span>")
		user.stop_pulling()
		pass_through_gateway(L)
		return TRUE
	if(!user.canUseTopic(src))
		return FALSE
	user.visible_message("<span class='warning'>[user] пробирается через [src]!</span>", "<span class='danger'>Собравшись с духом, вы проходите через [src]...</span>")
	pass_through_gateway(user)
	return TRUE

/obj/effect/clockwork/spatial_gateway/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/nullrod))
		user.visible_message("<span class='warning'>[user] развеивает [src] с помощью [I]!</span>", "<span class='danger'>Вы закрываете [src] с помощью [I]!</span>")
		qdel(linked_gateway)
		qdel(src)
		return TRUE
	if(istype(I, /obj/item/clockwork/slab))
		to_chat(user, "<span class='heavy_brass'>\"Не думаю, что ты захочешь уронить туда свою плиту.\"\n\"Если уж так хочется, попробуй бросить её.\"</span>")
		return TRUE
	if(uses && user.dropItemToGround(I))
		user.visible_message("<span class='warning'>[user] бросает [I] в [src]!</span>", "<span class='danger'>Вы бросаете [I] в [src]!</span>")
		pass_through_gateway(I, TRUE)
		return TRUE
	return ..()

/obj/effect/clockwork/spatial_gateway/ex_act(severity, target, origin)
	if(severity == 1 && uses)
		uses = 0
		visible_message("<span class='warning'>[src] разрушен!</span>")
		animate(src, alpha = 0, transform = matrix()*2, time = 10, flags = ANIMATION_END_NOW)
		deltimer(timerid)
		timerid = QDEL_IN_STOPPABLE(src, 10)
		linked_gateway.uses = 0
		linked_gateway.visible_message("<span class='warning'>[linked_gateway] разрушен!</span>")
		animate(linked_gateway, alpha = 0, transform = matrix()*2, time = 10, flags = ANIMATION_END_NOW)
		deltimer(linked_gateway.timerid)
		linked_gateway.timerid = QDEL_IN_STOPPABLE(linked_gateway, 10)
		return TRUE
	return FALSE


/obj/effect/clockwork/spatial_gateway/singularity_act()
	return

/obj/effect/clockwork/spatial_gateway/singularity_pull()
	return


/obj/effect/clockwork/spatial_gateway/Bumped(atom/movable/AM)
	..()
	if(!QDELETED(AM))
		pass_through_gateway(AM)

/obj/effect/clockwork/spatial_gateway/proc/pass_through_gateway(atom/movable/A, no_cost = FALSE)
	if(!linked_gateway)
		qdel(src)
		return FALSE
	if(!sender)
		visible_message("<span class='warning'>[A] отскакивает от [src]!</span>")
		return FALSE
	if(!uses)
		return FALSE
	if(!do_teleport(A, get_turf(linked_gateway), channel = TELEPORT_CHANNEL_CULT, forced = TRUE))
		visible_message("<span class='warning'>[A] отскакивает от [src]!</span>")
		return FALSE
	if(isliving(A))
		var/mob/living/user = A
		to_chat(user, "<span class='warning'><b>Вы проходите через [src] и появляетесь в другом месте!</b></span>")
	linked_gateway.visible_message("<span class='warning'>Фигура появляется в [linked_gateway], прежде чем выйти!</span>")
	playsound(src, 'sound/effects/empulse.ogg', 50, 1)
	playsound(linked_gateway, 'sound/effects/empulse.ogg', 50, 1)
	transform = matrix() * 1.5
	linked_gateway.transform = matrix() * 1.5
	if(!no_cost)
		uses = max(0, uses - 1)
		linked_gateway.uses = max(0, linked_gateway.uses - 1)
	if(!uses)
		animate(src, transform = matrix() * 0.1, time = 10, flags = ANIMATION_END_NOW)
		animate(linked_gateway, transform = matrix() * 0.1, time = 10, flags = ANIMATION_END_NOW)
		density = FALSE
		linked_gateway.density = FALSE
	else
		animate(src, transform = matrix() / 1.5, time = 10, flags = ANIMATION_END_NOW)
		animate(linked_gateway, transform = matrix() / 1.5, time = 10, flags = ANIMATION_END_NOW)
	addtimer(CALLBACK(src, PROC_REF(check_uses)), 10)
	return TRUE

/obj/effect/clockwork/spatial_gateway/proc/check_uses()
	if(!uses)
		qdel(src)
		qdel(linked_gateway)

//This proc creates and sets up a gateway from invoker input.
/atom/movable/proc/procure_gateway(mob/living/invoker, time_duration, gateway_uses, two_way)
	var/list/possible_targets = list()
	var/list/teleportnames = list()

	for(var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/O in GLOB.all_clockwork_objects)
		if(!O.Adjacent(invoker) && O != src && !is_away_level(O.z) && O.anchored) //don't list obelisks that we're next to
			var/area/A = get_area(O)
			var/locname = initial(A.name)
			possible_targets[avoid_assoc_duplicate_keys("[locname] [O.name]", teleportnames)] = O

	for(var/mob/living/L in GLOB.alive_mob_list)
		if(!L.stat && is_servant_of_ratvar(L) && !L.Adjacent(invoker) && !is_away_level(L.z)) //People right next to the invoker can't be portaled to, for obvious reasons
			possible_targets[avoid_assoc_duplicate_keys("[L.name] ([L.real_name])", teleportnames)] = L

	if(!possible_targets.len)
		to_chat(invoker, "<span class='warning'>Нет других подходящих целей для пространственного портала!</span>")
		return FALSE
	var/input_target_key = input(invoker, "Выберите цель, с которой нужно создать разлом.", "Пространственный портал") as null|anything in possible_targets
	var/atom/movable/target = possible_targets[input_target_key]
	if(!src || !input_target_key || !invoker || !invoker.canUseTopic(src, !issilicon(invoker)) || !is_servant_of_ratvar(invoker) || (isitem(src) && invoker.get_active_held_item() != src) || !invoker.can_speak_vocal())
		return FALSE //if any of the involved things no longer exist, the invoker is stunned, too far away to use the object, or does not serve ratvar, or if the object is an item and not in the mob's active hand, fail
	if(!target) //if we have no target, but did have a key, let them retry
		to_chat(invoker, "<span class='warning'>Эта цель больше не существует!</span>")
		return procure_gateway(invoker, time_duration, gateway_uses, two_way)
	if(isliving(target))
		var/mob/living/L = target
		if(!is_servant_of_ratvar(L))
			to_chat(invoker, "<span class='warning'>Эта цель больше не является Слугой!</span>")
			return procure_gateway(invoker, time_duration, gateway_uses, two_way)
		if(L.stat != CONSCIOUS)
			to_chat(invoker, "<span class='warning'>Этот слуга потерял сознание!</span>")
			return procure_gateway(invoker, time_duration, gateway_uses, two_way)
	var/istargetobelisk = istype(target, /obj/structure/destructible/clockwork/powered/clockwork_obelisk)
	var/issrcobelisk = istype(src, /obj/structure/destructible/clockwork/powered/clockwork_obelisk)
	if(!issrcobelisk && target.z != invoker.z && (is_reebe(invoker.z) || is_reebe(target.z)) && !GLOB.ratvar_awakens) //You need obilisks to get from and to reebe. Costs alot of power, unless you use stable gateways.
		to_chat(invoker, "<span class='heavy brass'>Расстояние между Рибом и миром смертных слишком велико для создания разлома с помощью твоей плиты, дитя.\
		Используй обелиск!</span>")
		return procure_gateway(invoker, time_duration, gateway_uses, two_way)
	if(issrcobelisk)
		if(!anchored)
			to_chat(invoker, "<span class='warning'>[src] больше не закреплён!</span>")
			return FALSE
		var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/CO = src //foolish as I am, how I set this proc up makes substypes unfeasible
		if(CO.active)
			to_chat(invoker, "<span class='warning'>[src] уже поддерживает пространственный разлом!</span>")
			return FALSE
	if(istargetobelisk)
		if(!target.anchored)
			to_chat(invoker, "<span class='warning'>[target.name] больше не закреплён!</span>")
			return procure_gateway(invoker, time_duration, gateway_uses, two_way)
		var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/CO = target
		if(CO.active)
			to_chat(invoker, "<span class='warning'>[target.name] уже поддерживает пространственный разлом и не может принять другой!</span>")
			return procure_gateway(invoker, time_duration, gateway_uses, two_way)
		var/efficiency = CO.get_efficiency_mod()
		gateway_uses = round(gateway_uses * (2 * efficiency), 1)
		time_duration = round(time_duration * (2 * efficiency), 1)
		CO.active = TRUE //you'd be active in a second but you should update immediately
	if(issrcobelisk && istargetobelisk && src.z != target.z && (is_reebe(src.z) || is_reebe(target.z)))
		invoker.visible_message("<span class='warning'>Воздух перед [invoker] дрожит и внезапно разрывается!</span>", \
		"<span class='brass'>Словом ты разрываешь реальность, создавая стабильный двусторонний разлом между Рибом и миром смертных.</span>")
		var/obj/effect/clockwork/spatial_gateway/stable/stable_S1 = new(get_turf(src))
		var/obj/effect/clockwork/spatial_gateway/stable/stable_S2 = new(get_turf(target))
		stable_S1.setup_gateway(stable_S2)
		stable_S2.visible_message("<span class='warning'>Воздух перед [target] дрожит и внезапно разрывается!</span>")
	else
		invoker.visible_message("<span class='warning'>Воздух перед [invoker] дрожит и внезапно разрывается!</span>", \
		"<span class='brass'>Словом ты разрываешь [two_way ? "двусторонний" : "односторонний"] разлом к [input_target_key]. Он просуществует [DisplayTimeText(time_duration)] и имеет [gateway_uses] использовани[gateway_uses % 10 == 1 && gateway_uses % 100 != 11 ? "е" : (gateway_uses % 10 >= 2 && gateway_uses % 10 <= 4 && !(gateway_uses % 100 >= 12 && gateway_uses % 100 <= 14) ? "я" : "й")].</span>")
		var/obj/effect/clockwork/spatial_gateway/S1 = new(issrcobelisk ? get_turf(src) : get_step(get_turf(invoker), invoker.dir))
		var/obj/effect/clockwork/spatial_gateway/S2 = new(istargetobelisk ? get_turf(target) : get_step(get_turf(target), target.dir))

		//Set up the portals now that they've spawned
		S1.setup_gateway(S2, time_duration, gateway_uses, two_way)
		S2.visible_message("<span class='warning'>Воздух перед [target] дрожит и внезапно разрывается!</span>")
	return TRUE

//Stable Gateway: Used to travel to and from reebe without any further powercost. Needs a clockwork obilisk to keep active, but stays active as long as it is not deactivated via an null rod or a slab, or the obilisk is destroyed
/obj/effect/clockwork/spatial_gateway/stable
	name = "stable gateway"
	is_stable = TRUE

/obj/effect/clockwork/spatial_gateway/stable/ex_act(severity, target, origin)
	if(severity == 1)
		start_shutdown() //Yes, you can chain devastation-level explosions to delay a gateway shutdown, if you somehow manage to do it without breaking the obelisk. Is it worth it? Probably not.
		return TRUE
	return FALSE

/obj/effect/clockwork/spatial_gateway/stable/setup_gateway(obj/effect/clockwork/spatial_gateway/stable/gatewayB) //Reduced setup call due to some things being irrelevant for stable gateways
	return ..(gatewayB, 1, 1, TRUE) //Uses and time irrelevant due to is_stable

/obj/effect/clockwork/spatial_gateway/stable/attackby(obj/item/I, mob/living/user, params)
	if(!istype(I, /obj/item/clockwork/slab) || !is_servant_of_ratvar(user) || busy)
		return ..()
	busy = TRUE
	linked_gateway.busy = TRUE
	user.visible_message("<span class='warning'>Разлом начинает дрожать, когда [user] направляет [user.ru_ego()] на него!</span>", "<span class='brass'> Вы начинаете отключать стабилизированный разлом с помощью своей плиты.</span>")
	linked_gateway.visible_message("<span class='warning'>[linked_gateway] начинает дрожать, но через него ничего не проходит.</span>")
	var/datum/beam/B = user.Beam(src, icon_state = "nzcrentrs_power", maxdistance = 50, time = 80) 	//Not too fancy, but this'll do.. for now.
	if(do_after(user, 80, target = src)) //Eight seconds to initiate the closing, then another two before is closes.
		to_chat(user, "<span class='brass'>Вы успешно настроили отключение разлома через две секунды.</span>")
		start_shutdown()
	qdel(B)
	busy = FALSE
	linked_gateway.busy = FALSE
	return TRUE

/obj/effect/clockwork/spatial_gateway/stable/proc/start_shutdown()
		deltimer(timerid)
		deltimer(linked_gateway.timerid)
		timerid = QDEL_IN_STOPPABLE(src, 20)
		linked_gateway.timerid = QDEL_IN_STOPPABLE(linked_gateway, 20)
		animate(src, alpha = 0, transform = matrix()*2, time = 20, flags = ANIMATION_END_NOW)
		animate(linked_gateway, alpha = 0, transform = matrix()*2, time = 20, flags = ANIMATION_END_NOW)
		src.visible_message("<span class='warning'>[src] начинает дестабилизироваться!</span>")
		linked_gateway.visible_message("<span class='warning'>[linked_gateway] начинает дестабилизироваться!</span>")

/obj/effect/clockwork/spatial_gateway/stable/pass_through_gateway(atom/movable/A, no_cost = TRUE)
	return ..()
