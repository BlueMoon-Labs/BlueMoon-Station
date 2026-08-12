/obj/item/holosign_creator
	name = "holographic sign projector"
	desc = "A handy-dandy holographic projector that displays a janitorial sign."
	icon = 'icons/obj/device.dmi'
	icon_state = "signmaker"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	force = 0
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	item_flags = NOBLUDGEON
	var/list/signs = list()
	var/max_signs = 10
	var/creation_time = 0 //time to create a holosign in deciseconds.
	var/holosign_type = /obj/structure/holosign/wetsign
	var/holocreator_busy = FALSE //to prevent placing multiple holo barriers at once
	///Ёмкость проектора. 0 - проектор без ёмкости, проекции живут вечно
	///(уборочные знаки, барьеры СБ и инженерии).
	var/max_charge = 0
	var/charge = 0
	///Расход ёмкости в секунду на каждую активную проекцию.
	var/charge_drain_per_sign = 0
	///Восстановление ёмкости в секунду, когда активных проекций нет.
	var/charge_recovery = 0
	///Подзарядка в секунду ВО ВРЕМЯ работы. Ноль у обычного проектора; у
	///исследуемого она перекрывает расход одного фана, поэтому один держится
	///сколько угодно, а каждый следующий уводит баланс в минус.
	var/charge_recovery_active = 0
	///Предупреждение о низкой ёмкости уже выдано - чтобы не спамить каждый проход.
	var/charge_warned = FALSE

/obj/item/holosign_creator/Initialize(mapload)
	. = ..()
	charge = max_charge

/obj/item/holosign_creator/Destroy()
	STOP_PROCESSING(SSobj, src)
	// Проекции держит эмиттер: без него они не должны пережить его же поломку,
	// иначе разбитый проектор оставляет вечные фаны в обход всей ёмкости.
	if(max_charge)
		for(var/obj/structure/holosign/sign as anything in signs.Copy())
			qdel(sign)
	return ..()

/obj/item/holosign_creator/examine(mob/user)
	. = ..()
	if(!max_charge)
		return
	. += "<span class='notice'>Заряд эмиттера: <b>[round(charge / max_charge * 100)]%</b>.</span>"
	var/sustainable = charge_drain_per_sign ? round(charge_recovery_active / charge_drain_per_sign) : 0
	if(sustainable > 0)
		. += "<span class='notice'>Отдачи эмиттера хватает на <b>[sustainable]</b> развёрнут[sustainable == 1 ? "ую проекцию" : "ых проекций"] без расхода запаса. Всё сверх этого тратит заряд.</span>"
	else if(length(signs))
		. += "<span class='notice'>Тратится, пока проекции развёрнуты; снимите их, чтобы эмиттер восстановился.</span>"

///Ёмкость тратится только пока проекции развёрнуты, поэтому опрос включается
///при установке и выключается, когда заряд снова полон и проекций нет.
/obj/item/holosign_creator/process()
	if(!max_charge)
		return PROCESS_KILL
	var/seconds = SSobj.wait * 0.1
	var/active_signs = length(signs)
	if(active_signs)
		var/net_drain = charge_drain_per_sign * active_signs - charge_recovery_active
		charge = clamp(charge - net_drain * seconds, 0, max_charge)
		if(charge <= 0)
			shed_one_sign()
			return
		if(!charge_warned && charge <= max_charge * HOLOFAN_PROJECTOR_WARN_RATIO)
			charge_warned = TRUE
			var/mob/holder = get(src, /mob)
			if(holder)
				to_chat(holder, "<span class='warning'>[src] предупреждающе гудит: эмиттер почти разряжен.</span>")
		return
	if(charge >= max_charge)
		charge = max_charge
		charge_warned = FALSE
		return PROCESS_KILL
	charge = min(max_charge, charge + charge_recovery * seconds)
	if(charge > max_charge * HOLOFAN_PROJECTOR_WARN_RATIO)
		charge_warned = FALSE

///Заряд кончился: гасим ОДНУ проекцию, последнюю поставленную, и оставляем себе
///немного заряда. Стена, погасшая целиком и мгновенно, вскрывает отсек одним
///кадром; стена, осыпающаяся по фану, даёт увидеть это и уйти. Заодно расход
///падает с каждым сброшенным фаном, так что заграждение само оседает до того
///размера, который эмиттер тянет. Холофаны с карты в списке не числятся и не
///гаснут.
/obj/item/holosign_creator/proc/shed_one_sign()
	if(!length(signs))
		return
	var/obj/structure/holosign/doomed = signs[length(signs)]
	doomed.visible_message("<span class='warning'>Проекция срывается и гаснет.</span>")
	playsound(doomed, 'sound/machines/click.ogg', 30, TRUE)
	qdel(doomed)
	charge = max_charge * HOLOFAN_PROJECTOR_SHED_BUFFER_RATIO
	charge_warned = TRUE
	var/mob/holder = get(src, /mob)
	if(holder)
		to_chat(holder, "<span class='warning'>Эмиттер [src] не тянет нагрузку: [length(signs) ? "последняя проекция погасла" : "проекция погасла"].</span>")

/obj/item/holosign_creator/afterattack(atom/target, mob/user, flag)
	. = ..()
	if(flag)
		if(!check_allowed_items(target, 1))
			return
		var/turf/T = get_turf(target)
		var/obj/structure/holosign/H = locate(holosign_type) in T
		if(H)
			to_chat(user, "<span class='notice'>You use [src] to deactivate [H].</span>")
			qdel(H)
		else
			if(!is_blocked_turf(T, TRUE)) //can't put holograms on a tile that has dense stuff
				if(holocreator_busy)
					to_chat(user, "<span class='notice'>[src] is busy creating a hologram.</span>")
					return
				if(max_charge && charge < max_charge * HOLOFAN_PROJECTOR_DEPLOY_RATIO)
					to_chat(user, "<span class='warning'>Эмиттер [src] разряжен - проекция погаснет, не успев развернуться.</span>")
					return
				if(signs.len < max_signs)
					playsound(src.loc, 'sound/machines/click.ogg', 20, 1)
					if(creation_time)
						holocreator_busy = TRUE
						if(!do_after(user, creation_time, target = target))
							holocreator_busy = FALSE
							return
						holocreator_busy = FALSE
						if(signs.len >= max_signs)
							return
						if(is_blocked_turf(T, TRUE)) //don't try to sneak dense stuff on our tile during the wait.
							return
					H = new holosign_type(get_turf(target), src)
					to_chat(user, "<span class='notice'>You create \a [H] with [src].</span>")
					if(max_charge)
						START_PROCESSING(SSobj, src)
				else
					to_chat(user, "<span class='notice'>[src] is projecting at max capacity!</span>")

/obj/item/holosign_creator/attack(mob/living/carbon/human/M, mob/user)
	return

/obj/item/holosign_creator/attack_self(mob/user)
	if(signs.len)
		for(var/H in signs)
			qdel(H)
		to_chat(user, "<span class='notice'>You clear all active holograms.</span>")


/obj/item/holosign_creator/security
	name = "security holobarrier projector"
	desc = "A holographic projector that creates holographic security barriers."
	icon_state = "signmaker_sec"
	holosign_type = /obj/structure/holosign/barrier
	creation_time = 30
	max_signs = 6

/obj/item/holosign_creator/engineering
	name = "engineering holobarrier projector"
	desc = "A holographic projector that creates holographic engineering barriers."
	icon_state = "signmaker_engi"
	holosign_type = /obj/structure/holosign/barrier/engineering
	creation_time = 30
	max_signs = 6

/obj/item/holosign_creator/atmos
	name = "ATMOS holofan projector"
	desc = "Проектор голографических вентиляторов. Людей пропускает, газ нет. Платой за то, что фан не надо нести и собирать, идёт время: эмиттер тратит заряд, пока фаны развёрнуты, и восстанавливает его, когда все сняты."
	icon_state = "signmaker_atmos"
	holosign_type = /obj/structure/holosign/barrier/atmos
	creation_time = 0
	max_signs = 3
	max_charge = HOLOFAN_PROJECTOR_MAX_CHARGE
	charge_drain_per_sign = HOLOFAN_PROJECTOR_DRAIN_PER_SIGN
	charge_recovery = HOLOFAN_PROJECTOR_RECOVERY

/obj/item/holosign_creator/atmos/sustained
	name = "sustained holofan projector"
	desc = "Проектор холофанов с эмиттером на замкнутом контуре: он подзаряжается прямо во время работы. Отдачи хватает ровно на одну развёрнутую проекцию - она держится сколько угодно. Каждая следующая уводит баланс в минус и ест запас, зато запас у него заметно больше обычного."
	icon_state = "signmaker_atmos_adv"
	max_signs = 4
	max_charge = HOLOFAN_SUSTAINED_MAX_CHARGE
	charge_drain_per_sign = HOLOFAN_SUSTAINED_DRAIN_PER_SIGN
	charge_recovery = HOLOFAN_SUSTAINED_RECOVERY
	charge_recovery_active = HOLOFAN_SUSTAINED_RECOVERY_ACTIVE

/obj/item/holosign_creator/firelock
	name = "ATMOS holofirelock projector"
	desc = "A holographic projector that creates holographic barriers that prevent changes in temperature conditions."
	icon_state = "signmaker_engi"
	holosign_type = /obj/structure/holosign/barrier/firelock
	creation_time = 0
	max_signs = 3

/obj/item/holosign_creator/combifan
	name = "ATMOS holo-combifan projector"
	desc = "Проектор голографических комбифанов. Держит и газ, и тепло, людей пропускает. Эмиттер тратит заряд, пока фаны развёрнуты, и восстанавливает его, когда все сняты."
	icon_state = "signmaker_atmos"
	holosign_type = /obj/structure/holosign/barrier/combifan
	creation_time = 0
	max_signs = 6
	max_charge = HOLOFAN_PROJECTOR_MAX_CHARGE
	charge_drain_per_sign = HOLOFAN_PROJECTOR_DRAIN_PER_SIGN
	charge_recovery = HOLOFAN_PROJECTOR_RECOVERY

/obj/item/holosign_creator/medical
	name = "\improper PENLITE barrier projector"
	desc = "A holographic projector that creates PENLITE holobarriers. Useful during quarantines since they halt those with malicious diseases."
	icon_state = "signmaker_med"
	holosign_type = /obj/structure/holosign/barrier/medical
	creation_time = 30
	max_signs = 3

/obj/item/holosign_creator/cyborg
	name = "Energy Barrier Projector"
	desc = "A holographic projector that creates fragile energy fields."
	creation_time = 15
	max_signs = 9
	holosign_type = /obj/structure/holosign/barrier/cyborg
	var/shock = 0

/obj/item/holosign_creator/cyborg/attack_self(mob/user)
	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user

		if(shock)
			to_chat(user, "<span class='notice'>You clear all active holograms, and reset your projector to normal.</span>")
			holosign_type = /obj/structure/holosign/barrier/cyborg
			creation_time = 5
			if(signs.len)
				for(var/H in signs)
					qdel(H)
			shock = 0
			return
		else if(R.emagged&&!shock)
			to_chat(user, "<span class='warning'>You clear all active holograms, and overload your energy projector!</span>")
			holosign_type = /obj/structure/holosign/barrier/cyborg/hacked
			creation_time = 30
			if(signs.len)
				for(var/H in signs)
					qdel(H)
			shock = 1
			return
		else
			if(signs.len)
				for(var/H in signs)
					qdel(H)
				to_chat(user, "<span class='notice'>You clear all active holograms.</span>")
	if(signs.len)
		for(var/H in signs)
			qdel(H)
		to_chat(user, "<span class='notice'>You clear all active holograms.</span>")
