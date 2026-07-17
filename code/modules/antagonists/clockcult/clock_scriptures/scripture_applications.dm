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
	desc = "Выделяет часть вашего сознания для Часового Стража, разновидности Мародёра, обитающего внутри вас, которого можно \
	вызвать, произнеся его Истинное Имя, или же в случае, если ваш запас здоровья станет крайне низким.<br>\
	Если он остается рядом с вами, его здоровье будет постепенно восстанавливаться до небольшого значения, но он погибнет, если удалится от вас слишком далеко."
	invocations = list("Воля Страха...", "...призовет...")
	channel_time = 100
	power_cost = 8000
	usage_tip = "Стражи полезны в качестве личных телохранителей и бойцов на передовой."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	primary_component = GEIS_CAPACITOR
	sort_priority = 6

/datum/clockwork_scripture/memory_allocation/check_special_requirements()
	for(var/mob/living/simple_animal/hostile/clockwork/guardian/M in GLOB.all_clockwork_mobs)
		if(M.host == invoker)
			to_chat(invoker, "<span class='warning'>Одновременно можно иметь только одного стража!</span>")
			return FALSE
	return TRUE

/datum/clockwork_scripture/memory_allocation/scripture_effects()
	return create_guardian()

/datum/clockwork_scripture/memory_allocation/proc/create_guardian()
	invoker.visible_message("<span class='warning'>Из [slab.name] в руках [invoker] появляется пурпурное щупальце и вонзается в [invoker.ru_ego()] лоб!</span>", \
	"<span class='sevtug'>Из [slab] к твоему лбу выстреливает щупальце. Ты начинаешь ждать, пока оно мучительно перестраивает структуру твоих мыслей...</span>")
	//invoker.notransform = TRUE //Vulnerable during the process
	slab.busy = "Происходит изменение мыслей"
	if(!do_after(invoker, 50, target = invoker))
		invoker.visible_message("<span class='warning'>Окровавленная щупальце отрывается от головы [invoker] и возвращается в [slab.name]!</span>", \
		"<span class='userdanger'>Тебя охватывает невыносимая боль, когда щупальце вырывается раньше времени!</span>")
		invoker.Knockdown(100)
		invoker.apply_damage(50, BRUTE, "head")//Sevtug leaves a gaping hole in your face if interrupted.
		slab.busy = null
		return FALSE
	clockwork_say(invoker, text2ratvar("...сознание создано..."))
	//invoker.notransform = FALSE
	slab.busy = "Происходит выбор стража"
	if(!check_special_requirements())
		slab.busy = null
		return FALSE
	to_chat(invoker, "<span class='warning'>Щупальце слегка дрожит, выбирая стража...</span>")
	var/list/marauder_candidates = pollGhostCandidates("Хотите сыграть за часового стража [invoker.real_name]?", ROLE_SERVANT_OF_RATVAR, null, FALSE, 50, POLL_IGNORE_HOLOPARASITE)
	if(!check_special_requirements())
		slab.busy = null
		return FALSE
	if(!marauder_candidates.len)
		invoker.visible_message("<span class='warning'>Щупальце оттягивается от головы [invoker], при этом запечатывая рану в месте проникновения!</span>", \
		"<span class='warning'>Попытка не удалась! Возможно, стоит попробовать ещё раз в другой раз.</span>")
		slab.busy = null
		return FALSE
	clockwork_say(invoker, text2ratvar("...меч и щит!"))
	var/mob/dead/observer/theghost = pick(marauder_candidates)
	var/mob/living/simple_animal/hostile/clockwork/guardian/M = new(invoker)
	M.key = theghost.key
	M.bind_to_host(invoker)
	slab.busy = null
	invoker.visible_message("<span class='warning'>Щупальце оттягивается от головы [invoker], при этом запечатывая рану в месте проникновения!</span>", \
	"<span class='sevtug'>[M.true_name], механический страж, поселился в вашем сознании. Общайтесь с ним с помощью кнопки действия \"Linked Minds\".</span>")
	return TRUE

//Clockwork Marauder: Creates a construct shell for a clockwork marauder, a well-rounded frontline fighter.
/datum/clockwork_scripture/create_object/construct/clockwork_marauder
	descname = "Боевой конструкт"
	name = "Clockwork Marauder"
	desc = "Создает оболочку для Часового мародёра, сбалансированного конструкта для переднего фронта, способного отражать снаряды своим щитом."
	invocations = list("Восстань, воплощение Арбитра!", "Защищай Ковчег с мстительным рвением!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Из вашей плиты выпадает несколько кусков сплава репликантов, которые принимают форму вибрирующих доспехов.</span>"
	usage_tip = "Если повторять этот отрывок из Священного Писания несколько раз за короткий промежуток времени, это займет больше времени!"
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Создает механического мародера, предназначенного для ведения боя на передовой."
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
			to_chat(invoker, "<span class='brass'>Эта станция находится слишком далеко от зоны действия Сети Иерофанта. Здесь невозможно вызвать мародера.</span>")
			return FALSE
		if(world.time < (last_marauder + CONFIG_GET(number/marauder_delay_non_reebe)))
			to_chat(invoker, "<span class='brass'>Сеть иерофанта по-прежнему испытывает нагрузку из-за последнего призыва мародёра в измерении без сильной энергетической связи с Рибом, которая могла бы его поддержать. \
			Вам нужно подождать ещё [DisplayTimeText((last_marauder + CONFIG_GET(number/marauder_delay_non_reebe)) - world.time, TRUE)]!</span>")
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
	desc = "Создает оболочку для механического танка, сбалансированного боевого конструкта, способного вести огонь из своего орудия."
	channel_time = 80
	power_cost = 25000
	quickbind = TRUE
	quickbind_desc = "Создает механический танк, предназначенный для ведения боевых действий на передовой."
	object_path = /obj/item/clockwork/construct_chassis/clocktank
	construct_type = /mob/living/simple_animal/hostile/clockwork/clocktank

//Summon Neovgre: Summon a very powerful combat mech that explodes when destroyed for massive damage.
/datum/clockwork_scripture/create_object/summon_arbiter
	descname = "Боевой мех"
	name = "Summon Neovgre, the Anima Bulwark"
	desc = "Призывает могучий Бастион Анимы, двухместный мех с выдающимися защитными и наступательными возможностями. Он \
			постепенно восстанавливает здоровье, а находясь на часовых плитках, увеличивает скорость втрое. \
			При необходимости мех автоматически получает энергию от расположенных поблизости сигилов передачи. \
			Его лазерная пушка Арбитра способна уничтожать врагов на большом расстоянии и пробивать любые преграды, вставшие на пути. \
			Однако имейте в виду: решение пилотировать или находиться на борту Неовгре это обязательство на всю жизнь: как только вы \
            попадете внутрь, вы не сможете уйти, а когда он будет уничтожен, он взорвётся с катастрофическими последствиями, унеся жизни всех, кто окажется внутри."
	invocations = list("Силой сплава...", "...призовите Арбитра!!")
	channel_time = 200 // This is a strong fucking weapon, 20 seconds channel time is getting off light I tell ya.
	power_cost = 40000 //40 KW. Why the hell did I think making this cost 5k more than the ARK was a good idea-KeRSe
	usage_tip = "Неовгре мощный мех, который разгромит ваших врагов!"
	invokers_required = 5
	multiple_invokers_used = TRUE
	object_path = /obj/vehicle/sealed/mecha/combat/neovgre
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	primary_component = BELLIGERENT_EYE
	sort_priority = 8
	creator_message = "<span class='brass'>Неовгре, Бастион Анимы возвышается над тобой… Час расплаты для твоих врагов пробил.</span>"

/datum/clockwork_scripture/create_object/summon_arbiter/check_special_requirements()
	if(GLOB.neovgre_exists)
		to_chat(invoker, "<span class='nezbere'>\"В этом временном потоке может существовать только одно из моих оружий!\"</span>")
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/construct/cogscarab
	descname = "Строительный дрон"
	name = "Cogscarab"
	desc = "Создает панцирь для жука-шестерни, трутня, который помогает строить вашу базу!"
	invocations = list("Встань, дрон!", "Создай защиту для истинного света!")
	channel_time = 80
	power_cost = 8000
	creator_message = "<span class='brass'>Из вашей плиты выпадает несколько кусков сплава репликантов, которые принимают форму паукообразной оболочки.</span>"
	usage_tip = "Эти инструменты помогут вам заложить основу, пока вы будете заниматься поиском новых слуг."
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_MOBS
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Создает жука-шестерню, полезного для тыла."
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
