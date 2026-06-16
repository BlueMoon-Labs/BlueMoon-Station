//////////////////
// APPLICATIONS // For various structures and base building, as well as advanced power generation.
//////////////////


//Sigil of Transmission: Creates a sigil of transmission that can drain and store power for clockwork structures.
/datum/clockwork_scripture/create_object/sigil_of_transmission
	descname = "Питание построек"
	name = "Sigil of Transmission"
	desc = "Создаёт сигил, способный поглощать и накапливать энергию для питания часовых конструкций."
	invocations = list("Божественность...", "...обеспечь энергией наши творения.")
	channel_time = 70
	power_cost = 200
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/transmission
	creator_message = "<span class='brass'>Под вами незаметно появляется сигил. Он будет автоматически питать энергией расположенные поблизости часовые механизмы и расходовать энергию при активации.</span>"
	usage_tip = "Борги могут восполнить запас энергии, находясь над этим сигилом в течение 5 секунд."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 2
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Создает сигил передачи, который может поглощать и накапливать энергию для механических конструкций."

//Prolonging Prism: Creates a prism that will delay the shuttle at a power cost
/datum/clockwork_scripture/create_object/prolonging_prism
	descname = "Задержка шаттла"
	name = "Prolonging Prism"
	desc = "Создает механизированную призму, которая задержит прибытие аварийного шаттла на 2 минуты, потребляя при этом огромное количество энергии."
	invocations = list("Пусть эта призма...", "...дарует нам время, чтобы исполнить Его волю.")
	channel_time = 80
	power_cost = 300
	object_path = /obj/structure/destructible/clockwork/powered/prolonging_prism
	creator_message = "<span class='brass'>Вы образуете удлиняющуюся призму, которая задержит прибытие аварийного шаттла, что потребует огромных затрат энергии.</span>"
	observer_message = "<span class='warning'>В воздухе возникает ониксовая призма, из которой вырастают щупальца, чтобы удержать её!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Затраты энергии на задержку шаттла увеличиваются в зависимости от количества использований."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 4
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Создает призму задержки, которая за счёт огромных затрат энергии задержит прибытие аварийного шаттла на 2 минуты."

/datum/clockwork_scripture/create_object/prolonging_prism/check_special_requirements()
	if(SSshuttle.emergency.mode == SHUTTLE_DOCKED || SSshuttle.emergency.mode == SHUTTLE_IGNITING || SSshuttle.emergency.mode == SHUTTLE_STRANDED || SSshuttle.emergency.mode == SHUTTLE_ESCAPE)
		to_chat(invoker, "<span class='inathneq'>\"Строить такое уже слишком поздно, чемпион.\"</span>")
		return FALSE
	var/turf/T = get_turf(invoker)
	if(!T || !is_station_level(T.z))
		to_chat(invoker, "<span class='inathneq'>\"Чтобы построить такой сигил тебе нужно находиться на станции, чемпион.\"</span>")
		return FALSE
	return ..()

//Mania Motor: Creates a malevolent transmitter that will broadcast the whispers of Sevtug into the minds of nearby nonservants, causing a variety of mental effects at a power cost.
/datum/clockwork_scripture/create_object/mania_motor
	descname = "Зона отрицания"
	name = "Mania Motor"
	desc = "Создаёт мотор мании, который наносит небольшой урон и вызывает различные негативные психические эффекты у находящихся поблизости людей, не являющихся Слугами, вплоть до обращения."
	invocations = list("Пусть этот передатчик...", "...сломит волю всех, кто противостоит нам.")
	channel_time = 80
	power_cost = 750
	object_path = /obj/structure/destructible/clockwork/powered/mania_motor
	creator_message = "<span class='brass'>Вы создаете мотор мании, который наносит незначительный урон и оказывает негативное воздействие на психику тех, кто не является Слугами.</span>"
	observer_message = "<span class='warning'>Из земли поднимается машина с двумя зубцами!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Кроме того, это избавит от галлюцинаций и повреждений мозга находящихся поблизости Слуг."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 5
	quickbind = TRUE
	quickbind_desc = "Создает мотор мании, который наносит незначительный урон и оказывает негативное воздействие на психику у тех, кто не является Слугами."
	requires_full_power = TRUE


//Clockwork Obelisk: Creates a powerful obelisk that can be used to broadcast messages or open a gateway to any servant or clockwork obelisk at a power cost.
/datum/clockwork_scripture/create_object/clockwork_obelisk
	descname = "Хаб телепорта"
	name = "Clockwork Obelisk"
	desc = "Создаёт часовой обелиск, способный передавать сообщения через Сеть Иерофанта или открывать Пространственный портал к любому живому Служителю или часовому обелиску."
	invocations = list("Пусть этот обелиск...", "...приведет нас во все места.")
	channel_time = 80
	power_cost = 300
	object_path = /obj/structure/destructible/clockwork/powered/clockwork_obelisk
	creator_message = "<span class='brass'>Вы создаете часовой обелиск, способный передавать сообщения или создавать пространственные порталы.</span>"
	observer_message = "<span class='warning'>В воздухе появляется латунный обелиск!</span>"
	invokers_required = 2
	multiple_invokers_used = TRUE
	usage_tip = "Создание портала требует значительных затрат энергии. Порталы, ведущие к часовым обелискам или соединяющие их между собой, получают удвоенную продолжительность действия и количество использований."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 3
	quickbind = TRUE
	quickbind_desc = "Создаёт Часовой обелиск, который при наличии энергии может отправлять сообщения или открывать пространственные врата."

//Memory Allocation: Finds a willing ghost and makes them into a clockwork guardian for the invoker.
/datum/clockwork_scripture/memory_allocation
	descname = "Личный страж"
	name = "Memory Allocation"
	desc = "Allocates part of your consciousness to a Clockwork Guardian, a variant of Marauder that lives within you, able to be \
	called forth by Speaking its True Name or if you become exceptionally low on health.<br>\
	If it remains close to you, you will gradually regain health up to a low amount, but it will die if it goes too far from you."
	invocations = list("Fright's will...", "...call forth...")
	channel_time = 100
	power_cost = 8000
	usage_tip = "Guardians are useful as personal bodyguards and frontline warriors."
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
	desc = "Creates a shell for a clockwork marauder, a balanced frontline construct that can deflect projectiles with its shield."
	invocations = list("Arise, avatar of Arbiter!", "Defend the Ark with vengeful zeal!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Your slab disgorges several chunks of replicant alloy that form into a suit of thrumming armor.</span>"
	usage_tip = "Reciting this scripture multiple times in a short period will cause it to take longer!"
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Creates a clockwork marauder, used for frontline combat."
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
	desc = "Creates a shell for a clockwork tank, a balanced frontline construct that can fire his gun."
	channel_time = 80
	power_cost = 25000
	quickbind = TRUE
	quickbind_desc = "Creates a clockwork tank, used for frontline combat."
	object_path = /obj/item/clockwork/construct_chassis/clocktank
	construct_type = /mob/living/simple_animal/hostile/clockwork/clocktank

//Summon Neovgre: Summon a very powerful combat mech that explodes when destroyed for massive damage.
/datum/clockwork_scripture/create_object/summon_arbiter
	descname = "Боевой мех"
	name = "Summon Neovgre, the Anima Bulwark"
	desc = "Calls forth the mighty Anima Bulwark, a two-person mech with superior defensive and offensive capabilities. It will \
			steadily regenerate HP and triple its regeneration speed while standing \
			on a clockwork tile. It will automatically draw power from nearby sigils of \
			transmission should the need arise. Its Arbiter laser cannon can decimate foes \
			from a range and is capable of smashing through any barrier presented to it. \
			Be warned however, choosing to pilot or man Neovgre is a lifetime commitment, once you are \
			in you cannot leave and when it is destroyed it will explode catastrophically, with everyone inside."
	invocations = list("By the strength of the alloy...!!", "...call forth the Arbiter!!")
	channel_time = 200 // This is a strong fucking weapon, 20 seconds channel time is getting off light I tell ya.
	power_cost = 40000 //40 KW. Why the hell did I think making this cost 5k more than the ARK was a good idea-KeRSe
	usage_tip = "Neovgre is a powerful mech that will crush your enemies!"
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
	desc = "Creates a shell for a cogscarab, a drone that helps build your base!"
	invocations = list("Arise, drone!", "Create defenses for the true light!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Your slab disgorges several chunks of replicant alloy that form into a spiderlike shell.</span>"
	usage_tip = "These machines will help you get a base built up while you go out to look for more followers."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Creates a cogscarab, good for the backline."
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
