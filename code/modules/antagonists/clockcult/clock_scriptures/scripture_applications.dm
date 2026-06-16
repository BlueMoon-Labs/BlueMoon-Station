//////////////////
// APPLICATIONS // For various structures and base building, as well as advanced power generation.
//////////////////


//Sigil of Transmission: Creates a sigil of transmission that can drain and store power for clockwork structures.
/datum/clockwork_scripture/create_object/sigil_of_transmission
	descname = "Питание построек"
	name = "Sigil of Transmission"
	desc = "Сигил: хранит и раздаёт энергию постройкам."
	invocations = list("Divinity...", "...power our creations.")
	channel_time = 70
	power_cost = 200
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/transmission
	creator_message = "<span class='brass'>A sigil silently appears below you. It will automatically power clockwork structures near it and will drain power when activated.</span>"
	usage_tip = "Борги заряжаются, стоя на сигиле 5 сек."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 2
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Сигил Transmission."

//Prolonging Prism: Creates a prism that will delay the shuttle at a power cost
/datum/clockwork_scripture/create_object/prolonging_prism
	descname = "Задержка шаттла"
	name = "Prolonging Prism"
	desc = "Структура: +2 мин к прибытию шаттла, дорого."
	invocations = list("May this prism...", "...grant us time to enact his will.")
	channel_time = 80
	power_cost = 300
	object_path = /obj/structure/destructible/clockwork/powered/prolonging_prism
	creator_message = "<span class='brass'>You form a prolonging prism, which will delay the arrival of an emergency shuttle at a massive power cost.</span>"
	observer_message = "<span class='warning'>An onyx prism forms in midair and sprouts tendrils to support itself!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Цена растёт с каждым использованием."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 4
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Prolonging Prism."

/datum/clockwork_scripture/create_object/prolonging_prism/check_special_requirements()
	if(SSshuttle.emergency.mode == SHUTTLE_DOCKED || SSshuttle.emergency.mode == SHUTTLE_IGNITING || SSshuttle.emergency.mode == SHUTTLE_STRANDED || SSshuttle.emergency.mode == SHUTTLE_ESCAPE)
		to_chat(invoker, "<span class='inathneq'>\"It is too late to construct one of these, champion.\"</span>")
		return FALSE
	var/turf/T = get_turf(invoker)
	if(!T || !is_station_level(T.z))
		to_chat(invoker, "<span class='inathneq'>\"You must be on the station to construct one of these, champion.\"</span>")
		return FALSE
	return ..()

//Mania Motor: Creates a malevolent transmitter that will broadcast the whispers of Sevtug into the minds of nearby nonservants, causing a variety of mental effects at a power cost.
/datum/clockwork_scripture/create_object/mania_motor
	descname = "Зона отрицания"
	name = "Mania Motor"
	desc = "Структура: урон и дебаффы врагам, может конвертить."
	invocations = list("May this transmitter...", "...break the will of all who oppose us.")
	channel_time = 80
	power_cost = 750
	object_path = /obj/structure/destructible/clockwork/powered/mania_motor
	creator_message = "<span class='brass'>You form a mania motor, which causes minor damage and negative mental effects in non-Servants.</span>"
	observer_message = "<span class='warning'>A two-pronged machine rises from the ground!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Лечит галлюцинации у слуг."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 5
	quickbind = TRUE
	quickbind_desc = "Mania Motor."
	requires_full_power = TRUE


//Clockwork Obelisk: Creates a powerful obelisk that can be used to broadcast messages or open a gateway to any servant or clockwork obelisk at a power cost.
/datum/clockwork_scripture/create_object/clockwork_obelisk
	descname = "Хаб телепорта"
	name = "Clockwork Obelisk"
	desc = "Обелиск: сеть, порталы, конвертит тайлы рядом."
	invocations = list("May this obelisk...", "...take us to all places.")
	channel_time = 80
	power_cost = 300
	object_path = /obj/structure/destructible/clockwork/powered/clockwork_obelisk
	creator_message = "<span class='brass'>You form a clockwork obelisk which can broadcast messages or produce Spatial Gateways.</span>"
	observer_message = "<span class='warning'>A brass obelisk appears hanging in midair!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Порталы дороги. Нужна энергосеть."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 3
	quickbind = TRUE
	quickbind_desc = "Clockwork Obelisk."

//Memory Allocation: Finds a willing ghost and makes them into a clockwork guardian for the invoker.
/datum/clockwork_scripture/memory_allocation
	descname = "Личный страж"
	name = "Memory Allocation"
	desc = "Страж в голове: вызывается именем или при низком HP."
	invocations = list("Fright's will...", "...call forth...")
	channel_time = 100
	power_cost = 8000
	usage_tip = "Телохранитель и боец."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	primary_component = GEIS_CAPACITOR
	sort_priority = 6

/datum/clockwork_scripture/memory_allocation/check_special_requirements()
	for(var/mob/living/simple_animal/hostile/clockwork/guardian/M in GLOB.all_clockwork_mobs)
		if(M.host == invoker)
			to_chat(invoker, "<span class='warning'>You can only house one guardian at a time!</span>")
			return FALSE
	return TRUE

/datum/clockwork_scripture/memory_allocation/scripture_effects()
	return create_guardian()

/datum/clockwork_scripture/memory_allocation/proc/create_guardian()
	invoker.visible_message("<span class='warning'>A purple tendril appears from [invoker]'s [slab.name] and impales itself in [invoker.ru_ego()] forehead!</span>", \
	"<span class='sevtug'>A tendril flies from [slab] into your forehead. You begin waiting while it painfully rearranges your thought pattern...</span>")
	//invoker.notransform = TRUE //Vulnerable during the process
	slab.busy = "Thought Modification in progress"
	if(!do_after(invoker, 50, target = invoker))
		invoker.visible_message("<span class='warning'>The tendril, covered in blood, retracts from [invoker]'s head and back into the [slab.name]!</span>", \
		"<span class='userdanger'>Total agony overcomes you as the tendril is forced out early!</span>")
		invoker.Knockdown(100)
		invoker.apply_damage(50, BRUTE, "head")//Sevtug leaves a gaping hole in your face if interrupted.
		slab.busy = null
		return FALSE
	clockwork_say(invoker, text2ratvar("...the mind made..."))
	//invoker.notransform = FALSE
	slab.busy = "Guardian Selection in progress"
	if(!check_special_requirements())
		return FALSE
	to_chat(invoker, "<span class='warning'>The tendril shivers slightly as it selects a guardian...</span>")
	var/list/marauder_candidates = pollGhostCandidates("Do you want to play as the clockwork guardian of [invoker.real_name]?", ROLE_SERVANT_OF_RATVAR, null, FALSE, 50, POLL_IGNORE_HOLOPARASITE)
	if(!check_special_requirements())
		return FALSE
	if(!marauder_candidates.len)
		invoker.visible_message("<span class='warning'>The tendril retracts from [invoker]'s head, sealing the entry wound as it does so!</span>", \
		"<span class='warning'>The tendril was unsuccessful! Perhaps you should try again another time.</span>")
		return FALSE
	clockwork_say(invoker, text2ratvar("...sword and shield!"))
	var/mob/dead/observer/theghost = pick(marauder_candidates)
	var/mob/living/simple_animal/hostile/clockwork/guardian/M = new(invoker)
	M.key = theghost.key
	M.bind_to_host(invoker)
	invoker.visible_message("<span class='warning'>The tendril retracts from [invoker]'s head, sealing the entry wound as it does so!</span>", \
	"<span class='sevtug'>[M.true_name], a clockwork guardian, has taken up residence in your mind. Communicate with it via the \"Linked Minds\" action button.</span>")
	return TRUE

//Clockwork Marauder: Creates a construct shell for a clockwork marauder, a well-rounded frontline fighter.
/datum/clockwork_scripture/create_object/construct/clockwork_marauder
	descname = "Боевой конструкт"
	name = "Clockwork Marauder"
	desc = "Оболочка мародёра: щит отражает снаряды."
	invocations = list("Arise, avatar of Arbiter!", "Defend the Ark with vengeful zeal!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Your slab disgorges several chunks of replicant alloy that form into a suit of thrumming armor.</span>"
	usage_tip = "Спам увеличивает время чтения."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Clockwork Marauder."
	object_path = /obj/item/clockwork/construct_chassis/clockwork_marauder
	construct_type = /mob/living/simple_animal/hostile/clockwork/marauder
	combat_construct = TRUE
	var/static/last_marauder = 0

/datum/clockwork_scripture/create_object/construct/clockwork_marauder/post_recital()
	last_marauder = world.time
	return ..()

/datum/clockwork_scripture/create_object/construct/clockwork_marauder/pre_recital()
	if(!is_reebe(invoker.z))
		if(!CONFIG_GET(flag/allow_clockwork_marauder_on_station))
			to_chat(invoker, "<span class='brass'>This particular station is too far from the influence of the Hierophant Network. You can not summon a marauder here.</span>")
			return FALSE
		if(world.time < (last_marauder + CONFIG_GET(number/marauder_delay_non_reebe)))
			to_chat(invoker, "<span class='brass'>The hierophant network is still strained from the last summoning of a marauder on a plane without the strong energy connection of Reebe to support it. \
			You must wait another [DisplayTimeText((last_marauder + CONFIG_GET(number/marauder_delay_non_reebe)) - world.time, TRUE)]!</span>")
			return FALSE
	return ..()

/datum/clockwork_scripture/create_object/construct/clockwork_marauder/update_construct_limit()
	var/human_servants = 0
	for(var/V in SSticker.mode.servants_of_ratvar)
		var/datum/mind/M = V
		var/mob/living/L = M.current
		if(ishuman(L) && L.stat != DEAD)
			human_servants++
	construct_limit = round(clamp((human_servants / 4), 1, 3))	//1 per 4 human servants, maximum of 3

//Clockwork Marauder: Creates a construct shell for a clockwork marauder, a well-rounded frontline fighter.
/datum/clockwork_scripture/create_object/construct/clockwork_marauder/clockwork_tank
	descname = "Танк-конструкт"
	name = "Clockwork Tank"
	desc = "Оболочка танка: пушка на передовой."
	channel_time = 80
	power_cost = 25000
	quickbind = TRUE
	quickbind_desc = "Clockwork Tank."
	object_path = /obj/item/clockwork/construct_chassis/clocktank
	construct_type = /mob/living/simple_animal/hostile/clockwork/clocktank

//Summon Neovgre: Summon a very powerful combat mech that explodes when destroyed for massive damage.
/datum/clockwork_scripture/create_object/summon_arbiter
	descname = "Боевой мех"
	name = "Summon Neovgre, the Anima Bulwark"
	desc = "Двухместный мех: лазер, реген на ратварских тайлах."
	invocations = list("By the strength of the alloy...!!", "...call forth the Arbiter!!")
	channel_time = 200 // This is a strong fucking weapon, 20 seconds channel time is getting off light I tell ya.
	power_cost = 40000 //40 KW. Why the hell did I think making this cost 5k more than the ARK was a good idea-KeRSe
	usage_tip = "Нельзя выйти. Взрыв при уничтожении."
	invokers_required = 5
	multiple_invokers_used = TRUE
	object_path = /obj/vehicle/sealed/mecha/combat/neovgre
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	primary_component = BELLIGERENT_EYE
	sort_priority = 8
	creator_message = "<span class='brass'>Neovgre, the Anima Bulwark towers over you... your enemies reckoning has come.</span>"

/datum/clockwork_scripture/create_object/summon_arbiter/check_special_requirements()
	if(GLOB.neovgre_exists)
		to_chat(invoker, "<span class='nezbere'>\"Only one of my weapons may exist in this temporal stream!\"</span>")
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/construct/cogscarab
	descname = "Строительный дрон"
	name = "Cogscarab"
	desc = "Оболочка когскараба: строит базу."
	invocations = list("Arise, drone!", "Create defenses for the true light!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Your slab disgorges several chunks of replicant alloy that form into a spiderlike shell.</span>"
	usage_tip = "Стройка, пока вы ищете последователей."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Cogscarab."
	object_path = /obj/item/clockwork/construct_chassis/cogscarab/
	construct_type = /mob/living/simple_animal/drone/cogscarab
	combat_construct = FALSE

/datum/clockwork_scripture/create_object/construct/cogscarab/update_construct_limit()
	var/human_servants = 0
	for(var/V in SSticker.mode.servants_of_ratvar)
		var/datum/mind/M = V
		var/mob/living/L = M.current
		if(ishuman(L) && L.stat != DEAD)
			human_servants++
	construct_limit = round(clamp((human_servants / 4), 1, 3))	//1 per 4 human servants, maximum of 3
