//Construct shells that can be activated by ghosts.
/obj/item/clockwork/construct_chassis
	name = "construct chassis"
	desc = "Корпус из латуни, предположительно предназначенный для размещения механизмов."
	clockwork_desc = "Конструктивное шасси. Его может активировать в любой момент любой желающий призрак."
	var/construct_name = "basic construct"
	var/construct_desc = "<span class='alloy'>Для этой платформы нет готового шаблона. Сообщите об этом программисту.</span>"
	icon_state = "anime_fragment"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	w_class = WEIGHT_CLASS_HUGE
	var/creation_message = "<span class='brass'>The chassis shudders and hums to life!</span>"
	var/construct_type //The construct this shell will create

/obj/item/clockwork/construct_chassis/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	if(A && construct_type)
		notify_ghosts("Шасси [construct_name] создано в [A.name]!", 'sound/magic/clockwork/fellowship_armory.ogg', source = src, action = NOTIFY_ATTACK, flashwindow = FALSE, ignore_key = POLL_IGNORE_CONSTRUCT, ignore_dnr_observers = TRUE)
	GLOB.poi_list += src
	LAZYADD(GLOB.mob_spawners[name], src)

/obj/item/clockwork/construct_chassis/Destroy()
	GLOB.poi_list -= src
	LAZYREMOVE(GLOB.mob_spawners[name], src)
	if(!LAZYLEN(GLOB.mob_spawners[name]))
		GLOB.mob_spawners -= name
	. = ..()

/obj/item/clockwork/construct_chassis/examine(mob/user)
	clockwork_desc = "[clockwork_desc]<br>[construct_desc]"
	. = ..()
	clockwork_desc = initial(clockwork_desc)

/obj/item/clockwork/construct_chassis/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(w_class >= WEIGHT_CLASS_HUGE)
		to_chat(user, "<span class='warning'>[src] слишком громоздкий, чтобы носить с собой! Лучше просто тащи его за собой!</span>")
		return
	. = ..()

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/item/clockwork/construct_chassis/attack_ghost(mob/dead/observer/user)
	if(!user.can_reenter_round())
		return FALSE
	if(!SSticker.mode)
		to_chat(user, "<span class='danger'>Вы не можете использовать это до начала игры.</span>")
		return
	if(QDELETED(src))
		to_chat(user, "<span class='danger'>Вы опоздали! Удачи в следующий раз.</span>")
		return
	user.forceMove(get_turf(src)) //If we attack through the alert, jump to the chassis so we know what we're getting into
	if(alert(user, "Стать [construct_name]? Вы больше не сможете быть клонированы!", construct_name, "Да", "Нет") == "Нет")
		return
	if(QDELETED(src))
		to_chat(user, "<span class='danger'>Вы опоздали! Удачи в следующий раз.</span>")
		return
	pre_spawn()
	visible_message(creation_message)
	var/mob/living/construct = new construct_type(get_turf(src))
	user.transfer_ckey(construct, FALSE)
	post_spawn(construct)
	qdel(user)
	qdel(src)

/obj/item/clockwork/construct_chassis/proc/pre_spawn() //Some things might change before the construct spawns; override those on a subtype basis in this proc
	return

/obj/item/clockwork/construct_chassis/proc/post_spawn(mob/living/construct) //And some things might change after it
	return


//Marauder armor, used to create clockwork marauders - sturdy frontline combatants that can deflect projectiles.
/obj/item/clockwork/construct_chassis/clockwork_marauder
	name = "marauder armor"
	desc = "Куча гладких и тщательно отполированных латунных доспехов. В лицевой пластине вставлен небольшой красный драгоценный камень."
	icon_state = "marauder_armor"
	construct_name = "clockwork marauder"
	construct_desc = "<span class='neovgre_small'>Он станет <b>часовым мародером,</b> универсальным бойцом на передовой.</span>"
	creation_message = "<span class='neovgre_small bold'>В доспехах разгорается багровый огонь, и они поднимаются в воздух со всем своим вооружением!</span>"
	construct_type = /mob/living/simple_animal/hostile/clockwork/marauder

//Marauder armor, used to create clockwork marauders - sturdy frontline combatants that can deflect projectiles.
/obj/item/clockwork/construct_chassis/clocktank
	name = "Clocktank Chassis"
	desc = "Куча гладких и тщательно отполированных латунных доспехов. На лицевой пластине вставлены два маленьких красных драгоценных камня."
	icon_state = "smashed_anime_fragment"
	construct_name = "clockwork tahk"
	construct_desc = "<span class='neovgre_small'>Он превратится в <b>часовой танк,</b> универсального бойца на передовой, способного вести огонь из своего оружия.</span>"
	creation_message = "<span class='neovgre_small bold'>В доспехах разгорается багровый огонь, и они поднимаются в воздух со всем своим вооружением!</span>"
	construct_type = /mob/living/simple_animal/hostile/clockwork/clocktank

//Cogscarab shell, used to create cogcarabs - fragile but zippy little drones that build and maintain the base.
/obj/item/clockwork/construct_chassis/cogscarab
	name = "cogscarab shell"
	desc = "Небольшой сложный корпус, напоминающий ремонтный дрон, но гораздо больше по размеру и изготовленный из латуни."
	icon_state = "cogscarab_shell"
	construct_name = "cogscarab"
	construct_desc = "<span class='alloy'>Он превратится в <b>жука-шестерню,</b> небольшого и хрупкого дрона, который занимается строительством, ремонтом и техническим обслуживанием.</span>"
	creation_message = "<span class='alloy bold'>Жук-шестерня щелкает и жужжит, подпрыгивая и оживая!</span>"
	construct_type = /mob/living/simple_animal/drone/cogscarab
	w_class = WEIGHT_CLASS_SMALL
	var/infinite_resources = FALSE //No.
	var/static/obj/item/seasonal_hat //Share it with all other scarabs, since we're from the same cult!

/obj/item/clockwork/construct_chassis/cogscarab/Initialize(mapload)
	. = ..()
	if(GLOB.servants_active)
		infinite_resources = FALSE //This check is relatively irrelevant until *someone* makes the infinite resources var default to true again, so, leaving it in.

/obj/item/clockwork/construct_chassis/cogscarab/pre_spawn()
	if(infinite_resources)
		//During rounds where they can't interact with the station, let them experiment with builds, if an admin allows them to.
		construct_type = /mob/living/simple_animal/drone/cogscarab/ratvar
	if(!seasonal_hat)
		var/obj/item/drone_shell/D = locate() in GLOB.poi_list
		if(D && D.possible_seasonal_hats.len)
			seasonal_hat = pick(D.possible_seasonal_hats)
		else
			seasonal_hat = "none"

/obj/item/clockwork/construct_chassis/cogscarab/post_spawn(mob/living/construct)
	if(infinite_resources) //Allow them to build stuff and recite scripture
		var/list/cached_stuff = construct.GetAllContents()
		for(var/obj/item/clockwork/replica_fabricator/F in cached_stuff)
			F.uses_power = FALSE
		for(var/obj/item/clockwork/slab/S in cached_stuff)
			S.no_cost = TRUE
		if(seasonal_hat && seasonal_hat != "none")
			var/obj/item/hat = new seasonal_hat(construct)
			construct.equip_to_slot_or_del(hat, ITEM_SLOT_HEAD)
