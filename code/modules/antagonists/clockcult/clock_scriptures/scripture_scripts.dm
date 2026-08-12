/////////////
// SCRIPTS // Various miscellanious spells for offense/defense/construction.
/////////////


//Replica Fabricator: Creates a replica fabricator, used to convert objects and repair clockwork structures.
/datum/clockwork_scripture/create_object/replica_fabricator
	descname = "Конвертер вещей"
	name = "Replica Fabricator"
	desc = "Создает устройство, которое при применении к определённым объектам заменяет их на их ратварские аналоги. Для работы устройства требуется питание."
	invocations = list("С помощью этого устройства...", "...о его присутствии станет известно.")
	channel_time = 20
	power_cost = 250
	whispered = TRUE
	object_path = /obj/item/clockwork/replica_fabricator
	creator_message = "<span class='brass'>Вы создаете фабрикатор реплик.</span>"
	usage_tip = "Часовые стены заставляют расположенные поблизости тайники мастера пассивно генерировать компоненты, что делает их незаменимым инструментом. Часовые полы восстанавливают урон от токсинов у слуг, стоящих на них."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_EQUIPMENT
	space_allowed = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 1
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Replica Fabricator."


//Ocular Warden: Creates an ocular warden, which defends a small area near it.
/datum/clockwork_scripture/create_object/ocular_warden
	descname = "Турель"
	name = "Ocular Warden"
	desc = "Создает автоматическую турель ближнего действия, которая будет автоматически атаковать находящихся поблизости свободных от оков не-Слуг, которых она видит."
	invocations = list("Стражи Двигателя...", "...судите тех, кто хочет причинить нам вред.")
	channel_time = 100
	power_cost = 2500
	object_path = /obj/structure/destructible/clockwork/ocular_warden
	creator_message = "<span class='brass'>Вы создаете глазного стража, который будет автоматически атаковать находящихся поблизости свободных существ, не являющихся Слугами, которых он может видеть.</span>"
	observer_message = "<span class='warning'>Латунная глазница обретает форму и медленно поднимается в воздух, а её красная радужка сверкает!</span>"
	usage_tip = "Несмотря на свою мощь, страж очень уязвим, и в идеале его следует размещать за баррикадами."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	space_allowed = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 2
	quickbind = TRUE
	quickbind_desc = "Создаёт глазного стража, который будет автоматически атаковать находящихся поблизости свободных существ, не являющихся Слугами, которых он может видеть."

/datum/clockwork_scripture/create_object/ocular_warden/check_special_requirements()
	for(var/obj/structure/destructible/clockwork/ocular_warden/W in range(OCULAR_WARDEN_EXCLUSION_RANGE, invoker))
		to_chat(invoker, "<span class='neovgre'>Вы чувствуете присутствие ещё одного глазного стража, находящегося слишком близко к этому месту. Если разместить ещё одного так близко, между ними начнётся битва.</span>" )
		return FALSE
	return ..()

//Vitality Matrix: Creates a sigil which will drain health from nonservants and can use that health to heal or even revive servants.
/datum/clockwork_scripture/create_object/vitality_matrix
	descname = "Сигил жизни"
	name = "Vitality Matrix"
	desc = "Создаёт печать, которая поглощает жизнь у всех живых существ, не являющихся Слугами, пересекающих её, и генерирует жизненную силу. Однако Слуги, пересекающие эту печать, будут исцелены за счёт имеющейся жизненной силы. \
    Мёртвых Слуг можно воскресить с помощью этой печати за 150 единиц жизненной силы."
	invocations = list("Божественность, впитай их эссенцию...", "...чтобы эта оболочка поглотила её.")
	channel_time = 60
	power_cost = 1000
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/vitality
	creator_message = "<span class='brass'>Под вами появляется матрица жизненной силы. Она будет поглощать жизнь у существ, не являющихся Слугами, и восстанавливать здоровье Слугам, пересекающим её.</span>"
	usage_tip = "Сигил исчезнет при воскрешении Слуги."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 3
	quickbind = TRUE
	quickbind_desc = "Создаёт матрицу жизненной силы, которая поглощает энергию всех существ, не являющихся Слугами, находящихся на ней, чтобы исцелить Слуг, пересекающих её."

/datum/clockwork_scripture/create_object/vitality_matrix/check_special_requirements()
	if(locate(object_path) in range(1, invoker))
		to_chat(invoker, "<span class='danger'>Матрицы жизненной энергии, расположенные рядом друг с другом, могут создавать помехи и вызывать петлю обратной связи! Отодвиньте их подальше друг от друга!</span>")
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/vitality_matrix/get_spawn_path(mob/user)
	if(!is_servant_of_ratvar(user, TRUE))
		return /obj/effect/clockwork/sigil/vitality/neutered
	return ..()

//Sigil of Rites: Creates a sigil that allows to perform certain rites on it. More information on these can be found in clock_rites.dm, they usually require power, materials and sometimes a target.
/datum/clockwork_scripture/create_object/sigil_of_rites
	descname = "Доступ к ритуалам"
	name = "Sigil of Rites"
	desc = "Размещает сигил, при взаимодействии с которым на нём можно проводить различные ритуалы. Для этого обычно требуются батарейки, часовая энергия и некоторые другие компоненты."
	invocations = list("Двигатель, позволь нам...", "...получить благословение твоих обрядов")
	channel_time = 80
	power_cost = 1400
	invokers_required = 2
	multiple_invokers_used = TRUE
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/rite
	creator_message = "<span class='brass'>Под вами появляется сигил Ритуалов. При наличии достаточного количества материалов и силы он позволит вам проводить определённые ритуалы.</span>"
	usage_tip = "Возможно, будет полезно скоординировать свои действия, чтобы быстро приобрести необходимые материалы."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 4

//Judicial Visor: Creates a judicial visor, which can smite an area.
/datum/clockwork_scripture/create_object/judicial_visor
	descname = "Отложенный удар по зоне очками"
	name = "Judicial Visor"
	desc = "Создает визор, который может поразить пространство, придавая ему Воинственность и ненадолго ошеломляя. Пораженная область взорвется через 3 секунды."
	invocations = list("Даруй мне пламя Двигателя.")
	channel_time = 10
	power_cost = 400
	whispered = TRUE
	object_path = /obj/item/clothing/glasses/judicial_visor
	creator_message = "<span class='brass'>Вы формируете судебный визор, который способен поражать небольшую область.</span>"
	usage_tip = "После использования визор перезаряжается в течение тридцати секунд."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_EQUIPMENT
	space_allowed = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 5
	quickbind = TRUE
	quickbind_desc = "Создает cудебный визор, который может поразить область, применив Воинственность и на короткое время оглушив противника."

//Nezbere's shield: Creates a ratvarian shield which absorbs attacks, see ratvarian_shield.dm for details.
/datum/clockwork_scripture/create_object/nezberes_shield
	descname = "Щит"
	name = "Nezbere's shield"
	desc = "Создает щит, который накапливает энергию, блокируя урон, и использует ее для усиления своих ударов. Щит сделан из латуни и, несмотря на свою прочность, крайне уязвим для лазеров и тем более для энергетического оружия."
	invocations = list("Защити меня...", "...от надвигающейся тьмы.")
	channel_time = 20
	power_cost = 600 //Shouldn't be too spammable but not too hard to get either
	whispered = TRUE
	creator_message = "Вы создаете ратварский щит, который способен поглощать заблокированные атаки, чтобы усилить свои удары."
	object_path = /obj/item/shield/riot/ratvarian
	usage_tip = "Удары будут использовать заряд только в том случае, если они выполняются с намерением причинить вред(harm/4ый intent)."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_EQUIPMENT
	space_allowed = TRUE
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Создает ратварский щит, который может поглощать энергию атак и использовать ее для нанесения мощных ударов."

/datum/clockwork_scripture/create_object/station_clock_curse
	descname = "Портальный шторм"
	name = "Station Reinforcement"
	desc = "Создаёт сферу, при разбитии вызывающую портальный шторм, что создаёт множество других враждебных культистов."
	invocations = list("Я прошу, пришли подкрепление...", "...мы в тебе нуждаемся.")
	channel_time = 20
	power_cost = 50000
	whispered = TRUE
	creator_message = "Вы сформировали сферу с проклятием для станции."
	object_path = /obj/item/station_clock_curse
	usage_tip = "Максимум 3 раза за раунд."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_MOBS
	space_allowed = TRUE
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Создаёт сферу, при разбитии создающую портальный шторм на станции"

/datum/clockwork_scripture/create_object/station_clock_curse/creation_update()
	var/should_hide = /obj/item/station_clock_curse::curse_uses >= STATION_CLOCK_CURSE_MAX_USES
	if(hidden_from_ui != should_hide)
		hidden_from_ui = should_hide
		return TRUE
	return FALSE

/datum/clockwork_scripture/create_object/station_clock_curse/check_special_requirements()
	if(/obj/item/station_clock_curse::curse_uses >= STATION_CLOCK_CURSE_MAX_USES)
		to_chat(invoker, "<span class='notice'>Мы исчерпали свою способность проклинать Космическую Станцию.</span>")
		return FALSE
	return ..()

//Clockwork Armaments: Grants the invoker the ability to call forth a Ratvarian spear and clockwork armor.
/datum/clockwork_scripture/clockwork_armaments
	descname = "Броня и копьё"
	name = "Clockwork Armaments"
	desc = "Позволяет заклинателю по желанию вызывать часовую броню и ратварское копье. Атаки копьем будут генерировать жизненную силу, используемую для исцеления."
	invocations = list("Даруй мне оружие...", "...из кузницы Оружейника.")
	channel_time = 20
	power_cost = 250
	whispered = TRUE
	usage_tip = "Метание копья в моба нанесет огромный урон и собьет его с ног, но сломает копье. Вам нужно будет подождать 30 секунд, прежде чем вызвать его повторно."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_EQUIPMENT
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 8
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Навсегда привязывает к вам заводную броню и ратварское копье."

/datum/clockwork_scripture/clockwork_armaments/check_special_requirements()
	for(var/datum/action/innate/clockwork_armaments/F in invoker.actions)
		to_chat(invoker, "<span class='warning'>Вы уже привязали к себе ратварское копье!</span>")
		return FALSE
	return invoker.can_hold_items()

/datum/clockwork_scripture/clockwork_armaments/scripture_effects()
	invoker.visible_message("<span class='warning'>Мерцание желтого света проникает в [invoker]!</span>", \
	"<span class='brass'>Вы привязываете к себе часовое снаряжение. Используйте Clockwork Armaments и призыв Копье, чтобы вызвать его.</span>")
	var/datum/action/innate/call_weapon/ratvarian_spear/S = new()
	S.Grant(invoker)
	var/datum/action/innate/clockwork_armaments/A = new()
	A.Grant(invoker)
	return TRUE

//Clockwork Armaments: Equips a set of clockwork armor. Three-minute cooldown.
/datum/action/innate/clockwork_armaments
	name = "Clockwork Armaments"
	desc = "Наденьте на себя полный комплект ратварских доспехов."
	icon_icon = 'icons/mob/actions/actions_clockcult.dmi'
	button_icon_state = "clockwork_armor"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	buttontooltipstyle = "clockcult"
	var/cooldown = 0
	var/static/list/ratvarian_armor_typecache = typecacheof(list(
	/obj/item/clothing/suit/armor/clockwork,
	/obj/item/clothing/head/helmet/clockwork,
	/obj/item/clothing/gloves/clockwork,
	/obj/item/clothing/shoes/clockwork)) //don't replace this ever
	var/static/list/better_armor_typecache = typecacheof(list(
	/obj/item/clothing/suit/space,
	/obj/item/clothing/head/helmet/space,
	/obj/item/clothing/shoes/magboots)) //replace this only if ratvar is up

/datum/action/innate/clockwork_armaments/IsAvailable(silent = FALSE)
	if(!is_servant_of_ratvar(owner))
		qdel(src)
		return
	if(cooldown > world.time)
		return
	return ..()

/datum/action/innate/clockwork_armaments/Activate()
	var/do_message = 0
	var/obj/item/I = owner.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(remove_item_if_better(I, owner))
		do_message += owner.equip_to_slot_or_del(new/obj/item/clothing/suit/armor/clockwork(null), ITEM_SLOT_OCLOTHING)
	I = owner.get_item_by_slot(ITEM_SLOT_HEAD)
	if(remove_item_if_better(I, owner))
		do_message += owner.equip_to_slot_or_del(new/obj/item/clothing/head/helmet/clockwork(null), ITEM_SLOT_HEAD)
	I = owner.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(remove_item_if_better(I, owner))
		do_message += owner.equip_to_slot_or_del(new/obj/item/clothing/gloves/clockwork(null), ITEM_SLOT_GLOVES)
	I = owner.get_item_by_slot(ITEM_SLOT_FEET)
	if(remove_item_if_better(I, owner))
		do_message += owner.equip_to_slot_or_del(new/obj/item/clothing/shoes/clockwork(null), ITEM_SLOT_FEET)
	if(do_message)
		owner.visible_message("<span class='warning'>Странная броня появляется на [owner]!</span>", "<span class='heavy_brass'>Яркое сияние струится по вашему телу, одевая на вас ратварскую броню.</span>")
		playsound(owner, 'sound/magic/clockwork/fellowship_armory.ogg', 15 * do_message, TRUE) //get sound loudness based on how much we equipped
		cooldown = CLOCKWORK_ARMOR_COOLDOWN + world.time //no cooldown if nothing was equipped, so a failed attempt (e.g. undroppable equipment) can be retried
		owner.update_action_buttons_icon()
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, update_action_buttons_icon)), CLOCKWORK_ARMOR_COOLDOWN)
	else
		to_chat(owner, "<span class='warning'>Ваше снаряжение невозможно заменить бронёй Ратвара! Снимите его и попробуйте снова.</span>")
	return TRUE

/datum/action/innate/clockwork_armaments/proc/remove_item_if_better(obj/item/I, mob/user)
	if(!I)
		return TRUE
	if(is_type_in_typecache(I, ratvarian_armor_typecache))
		return FALSE
	if(!GLOB.ratvar_awakens && is_type_in_typecache(I, better_armor_typecache))
		return FALSE
	return user.dropItemToGround(I)

//Call Spear: Calls forth a powerful Ratvarian spear.
/datum/action/innate/call_weapon/ratvarian_spear
	name = "Call Spear"
	desc = "Призывает ратварское копье в ваши руки, чтобы сразиться с вашими врагами."
	weapon_type = /obj/item/clockwork/weapon/ratvarian_spear


//Mending Mantra: Channeled for up to ten times over twenty seconds to repair structures and heal allies
/datum/clockwork_scripture/channeled/mending_mantra
	descname = "Ремонт и лечение"
	name = "Mending Mantra"
	desc = "Восстанавливает близлежащие строения и конструкции. Слуги, одетые в часовую броню, также будут исцелены. Произносится каждые две секунды в течение максимум двадцати секунд."
	chant_invocations = list("Залатайте наши раны!", "Залечите наши царапины!", "Почините наши шестерни!")
	chant_amount = 10
	chant_interval = 20
	power_cost = 400
	usage_tip = "Это очень эффективный способ быстро укрепить базу после атаки."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_SUPPORT
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Восстанавливает близлежащие строения и конструкциии. Слуги, одетые в часовую броню, также будут исцелены.<br><b>Максимум 10 заклинаний."
	var/heal_attempts = 4
	var/heal_amount = 5
	var/static/list/damage_heal_order = list(BRUTE, BURN, OXY)
	var/static/list/heal_finish_messages = list("Ну вот, все починено!", "Старайтесь не слишком сильно пострадать.", "У вас больше не будет ран и царапин!", "Чемпионы никогда не умирают.", "Все подлатано.", \
	"Ах, дитя мое, теперь все в порядке.", "Боль временно.", "То, что вы делаете для Юстициара, вечно.", "Потерпи это ради меня.", "Будь сильным, дитя.", "Пожалуйста, будьте осторожны!", \
	"Если ты умрешь, тебя будут помнить.")
	var/static/list/heal_target_typecache = typecacheof(list(
	/obj/structure/destructible/clockwork,
	/obj/machinery/door/airlock/clockwork,
	/obj/machinery/door/window/clockwork,
	/obj/structure/window/reinforced/clockwork,
	/obj/structure/table/reinforced/brass))
	var/static/list/ratvarian_armor_typecache = typecacheof(list(
	/obj/item/clothing/suit/armor/clockwork,
	/obj/item/clothing/head/helmet/clockwork,
	/obj/item/clothing/gloves/clockwork,
	/obj/item/clothing/shoes/clockwork))

/datum/clockwork_scripture/channeled/mending_mantra/proc/is_synthetic_servant(mob/living/L)
	if(L.stat == DEAD || !is_servant_of_ratvar(L))
		return FALSE
	if(isrobotic(L))
		return TRUE
	if(issilicon(L) && !istype(L, /mob/living/silicon/ai))
		return TRUE
	return FALSE

/datum/clockwork_scripture/channeled/mending_mantra/chant_effects(chant_number)
	var/turf/T
	for(var/atom/movable/M in range(7, invoker))
		if(isliving(M))
			if(isclockmob(M) || istype(M, /mob/living/simple_animal/drone/cogscarab))
				var/mob/living/simple_animal/S = M
				if(S.health == S.maxHealth || S.stat == DEAD)
					continue
				T = get_turf(M)
				for(var/i in 1 to heal_attempts)
					if(S.health < S.maxHealth)
						S.adjustHealth(-heal_amount)
						new /obj/effect/temp_visual/heal(T, "#1E8CE1")
						if(i == heal_attempts && S.health >= S.maxHealth) //we finished healing on the last tick, give them the message
							to_chat(S, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
							break
					else
						to_chat(S, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
						break
			else if(is_synthetic_servant(M))
				var/mob/living/L = M
				if(!L.getBruteLoss() && !L.getFireLoss() && L.health >= L.maxHealth)
					continue
				T = get_turf(M)
				for(var/i in 1 to heal_attempts)
					if(L.getBruteLoss() || L.getFireLoss() || L.health < L.maxHealth)
						L.heal_overall_damage(heal_amount, heal_amount, only_robotic = FALSE, only_organic = FALSE)
						new /obj/effect/temp_visual/heal(T, "#1E8CE1")
						if(i == heal_attempts && !L.getBruteLoss() && !L.getFireLoss() && L.health >= L.maxHealth)
							to_chat(L, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
							break
					else
						to_chat(L, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
						break
			else if(ishuman(M))
				var/mob/living/carbon/human/H = M
				if(H.health == H.maxHealth || H.stat == DEAD || !is_servant_of_ratvar(H))
					continue
				T = get_turf(M)
				var/heal_ticks = 0 //one heal tick for each piece of ratvarian armor worn
				var/obj/item/I = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
				if(is_type_in_typecache(I, ratvarian_armor_typecache))
					heal_ticks++
				I = H.get_item_by_slot(ITEM_SLOT_HEAD)
				if(is_type_in_typecache(I, ratvarian_armor_typecache))
					heal_ticks++
				I = H.get_item_by_slot(ITEM_SLOT_GLOVES)
				if(is_type_in_typecache(I, ratvarian_armor_typecache))
					heal_ticks++
				I = H.get_item_by_slot(ITEM_SLOT_FEET)
				if(is_type_in_typecache(I, ratvarian_armor_typecache))
					heal_ticks++
				if(heal_ticks)
					for(var/i in 1 to heal_ticks)
						if(H.health < H.maxHealth)
							H.heal_ordered_damage(heal_amount, damage_heal_order)
							new /obj/effect/temp_visual/heal(T, "#1E8CE1")
							if(i == heal_ticks && H.health >= H.maxHealth)
								to_chat(H, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
								break
						else
							to_chat(H, "<span class='inathneq'>\"[text2ratvar(pick(heal_finish_messages))]\"</span>")
							break
		else if(istype(M, /obj/vehicle/sealed/mecha/combat/neovgre))
			var/obj/vehicle/sealed/mecha/combat/neovgre/N = M
			if(N.obj_integrity >= N.max_integrity && (!N.cell || N.cell.charge >= N.cell.maxcharge))
				continue
			T = get_turf(M)
			for(var/i in 1 to heal_attempts)
				var/needs_more = FALSE
				if(N.obj_integrity < N.max_integrity)
					N.obj_integrity = min(N.obj_integrity + heal_amount, N.max_integrity)
					needs_more = TRUE
				if(N.cell && N.cell.charge < N.cell.maxcharge)
					N.cell.charge = min(N.cell.charge + heal_amount * 10, N.cell.maxcharge)
					needs_more = TRUE
				if(needs_more)
					new /obj/effect/temp_visual/heal(T, "#1E8CE1")
				else
					break
		else if(is_type_in_typecache(M, heal_target_typecache))
			var/obj/structure/destructible/clockwork/C = M
			if(C.obj_integrity == C.max_integrity || (istype(C) && !C.can_be_repaired))
				continue
			T = get_turf(M)
			for(var/i in 1 to heal_attempts)
				if(C.obj_integrity < C.max_integrity)
					C.obj_integrity = min(C.obj_integrity + 5, C.max_integrity)
					C.update_icon()
					new /obj/effect/temp_visual/heal(T, "#1E8CE1")
				else
					break
	new /obj/effect/temp_visual/ratvar/mending_mantra(get_turf(invoker))
	return TRUE

//Volt Blaster: Channeled for up to five times over ten seconds to fire up to five rays of energy at target locations.
/datum/clockwork_scripture/channeled/volt_blaster
	descname = "Энерголучи"
	name = "Volt Blaster"
	desc = "Позволяет вам стрелять пятью энергетическими лучами по целям. Произносится каждые четверть секунды в течение максимум десяти секунд."
	channel_time = 30
	invocations = list("Сила тока...", "...даруй мне свою силу!")
	chant_invocations = list("Используй заряд, чтобы убивать!", "Убивай силой!", "Охотьтесь с энергией!")
	chant_amount = 5
	chant_interval = 4
	power_cost = 500
	usage_tip = "Хотя это требует, чтобы вы стояли неподвижно, это Писания может нанести огромный урон."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_ATTACK
	primary_component = BELLIGERENT_EYE
	sort_priority = 6
	quickbind = TRUE
	quickbind_desc = "Позволяет вам стрелять энергетическими лучами по целям.<br><b>Максимум 5 заклинаний.</b>"
	var/static/list/nzcrentr_insults = list("Ты не очень хорошо целишься.", "Ты плохо охотишься.", "Какая пустая трата энергии.", "Почти забавно наблюдать за этим.",
	"Босс говорит </span><span class='heavy_brass'>\"Нажми куда-то, идиот!\"</span><span class='nzcrentr'>.", "Перестань тратить энергию впустую, если не можешь прицелиться.")

/datum/clockwork_scripture/channeled/volt_blaster/chant_effects(chant_number)
	slab.busy = null
	var/datum/clockwork_scripture/ranged_ability/volt_ray/ray = new
	ray.slab = slab
	ray.invoker = invoker
	var/turf/T = get_turf(invoker)
	if(!ray.run_scripture() && slab && invoker)
		if(can_recite() && T == get_turf(invoker))
			to_chat(invoker, "<span class='nzcrentr'>\"[text2ratvar(pick(nzcrentr_insults))]\"</span>")
		else
			return FALSE
	return TRUE

/obj/effect/ebeam/volt_ray
	name = "volt_ray"
	layer = LYING_MOB_LAYER

/datum/clockwork_scripture/ranged_ability/volt_ray
	name = "Volt Ray"
	slab_overlay = "volt"
	allow_mobility = FALSE
	ranged_type = /obj/effect/proc_holder/slab/volt
	ranged_message = "<span class='nzcrentr_small'><i>Вы заряжаете часовую плиту шокирующей мощью.</i>\n\
	<b>Щелкните левой кнопкой мыши на цель, чтобы выстрелить, быстро!</b></span>"
	timeout_time = 20

/datum/clockwork_scripture/void_volt
	descname = "ЕМП-взрыв"
	name = "Void Volt"
	desc = "Заклинание, высвобождающее импульс, который вытягивает энергию из всего в радиусе восьми клеток, но обжигает заклинателя.\
	Может быть использовано совместно с другими Слугами для увеличения радиуса действия и равномерного распределения получаемого урона между всеми заклинателями.\
	Кроме того, восполняет запас энергии Ратвара на небольшую долю от количества поглощённой энергии, что позволяет частично компенсировать энергетические затраты этого писания."
	invocations = list("Возьмите энергию...", "...их изобретений...", "...и даруйте ее Двигателю...",  "...ибо они и так живут в кромешной тьме!")
	channel_time = 130 //You need alot of time, but it pays off. - ten times as powerful as a regular drain (done by transmission sigils) and recurses + affects weapons - incredibly useful if you can pull this off before a big fight.
	power_cost = 500 //Relatively medium powercost, but can be offset due to it adding a part of drained power to the power pool.
	multiple_invokers_used = TRUE
	multiple_invokers_optional = TRUE
	usage_tip = "Следите за тем, чтобы не получить травму при использовании этого устройства, иначе сила, проходящая через вас, может подавить ваше тело."
	tier = SCRIPTURE_SCRIPT
	category = SCRIPTURE_CATEGORY_ATTACK
	primary_component = GEIS_CAPACITOR
	sort_priority = 11
	quickbind = TRUE
	quickbind_desc = "Быстро истощает энергию в области вокруг вызывающего, вызывая ожоги, пропорциональные количеству израсходованной энергии."

/datum/clockwork_scripture/void_volt/chant()
	invoker.visible_message("<span class='warning'>[invoker] светится ярким золотистым светом!</span>")
	invoker.add_atom_colour("#FFD700", ADMIN_COLOUR_PRIORITY)
	invoker.light_power = 2
	invoker.light_range = 4
	invoker.light_color = LIGHT_COLOR_FIRE
	invoker.update_light()
	addtimer(CALLBACK(invoker, TYPE_PROC_REF(/mob, stop_void_volt_glow)), channel_time)
	..()//Do the timer & Chant

/mob/proc/stop_void_volt_glow() //Needed so the scripture being qdel()d doesn't prevent it.
	visible_message("<span class='warning'>[src] перестает светиться...</span>")
	remove_atom_colour(ADMIN_COLOUR_PRIORITY)
	light_power = 0
	light_range = 0
	update_light()

/datum/clockwork_scripture/void_volt/scripture_effects()
	var/power_drained = 0
	var/power_mod = 0.005 //Amount of power drained (generally) is multiplied with this, and subsequently dealt in damage to the invoker, then 15 times that is added to the clockwork cult's power reserves.
	var/drain_range = 12
	var/additional_chanters = 0
	var/list/chanters = list()
	chanters += invoker
	for(var/mob/living/L in orange(1, invoker))
		if(!L.stat && is_servant_of_ratvar(L))
			additional_chanters++
			chanters += L
	drain_range = min(drain_range + 2 * additional_chanters, drain_range * 2) //s u c c
	for(var/t in spiral_range_turfs(drain_range, invoker))
		var/turf/T = t
		for(var/M in T)
			var/atom/movable/A = M
			power_drained += A.power_drain(TRUE, TRUE, TRUE, MIN_CLOCKCULT_POWER * 10) //Yes, this absolutely does drain weaponry, aswell as recurse through objects. No more hiding in lockers / mechs to avoid it.
	new /obj/effect/temp_visual/ratvar/sigil/transgression(invoker.loc, 1 + (power_drained * power_mod))
	var/datum/effect_system/spark_spread/S = new
	S.set_up(round(1 + (power_drained * power_mod), 1), 0, get_turf(invoker))
	S.start()
	adjust_clockwork_power(power_drained * power_mod * 15)
	for(var/mob/living/L in chanters)
		L.adjustFireLoss(round(clamp(power_drained * power_mod / (1 + additional_chanters), 0, 70), 0.1)) //No you won't just immediately melt if you do this in a very power-rich area, but it'll be close.


	return TRUE
