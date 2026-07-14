/////////////
// DRIVERS // Starter spells
/////////////

//Stargazer: Creates a stargazer, a cheap power generator that utilizes starlight.
/datum/clockwork_scripture/create_object/stargazer
	descname = "Генератор от звёздного света"
	name = "Stargazer"
	desc = "Создает слабую структуру, которая генерирует энергию каждую секунду, пока находится в пределах трех клеток от звездного света."
	invocations = list("Запечатлей для нас их низший свет.")
	channel_time = 50
	power_cost = 200
	object_path = /obj/structure/destructible/clockwork/stargazer
	creator_message = "<span class='brass'>Вы создаете звездонаблюдателя, который будет генерировать энергию под воздействием звездного света.</span>"
	observer_message = "<span class='warning'>Появляется огромный аппарат в форме фонаря!</span>"
	usage_tip = "По понятным причинам обязательно разместите это рядом с окном или в другом месте, откуда открывается вид на космос!"
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	whispered = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 1
	quickbind = TRUE
	quickbind_desc = "Создает звездонаблюдателя, который вырабатывает энергию, находясь рядом со светом звёзд."

/datum/clockwork_scripture/create_object/stargazer/check_special_requirements()
	var/area/A = get_area(invoker)
	var/turf/T = get_turf(invoker)
	if(A?.area_flags & CULTMAGIC_BYPASS)
		return ..()
	if(!is_station_level(invoker.z) || isspaceturf(T) || !(A?.area_flags & CULT_PERMITTED))
		to_chat(invoker, "<span class='danger'>Звездонаблюдатели нельзя строить вне станции.</span>")
		return
	return ..()


//Integration Cog: Creates an integration cog that can be inserted into APCs to passively siphon power.
/datum/clockwork_scripture/create_object/integration_cog
	descname = "Воровство энергии у ЛКП"
	name = "Integration Cog"
	desc = "Создает интеграционную шестерню, которую можно установить на открытый ЛКП для замены его внутренних компонентов и пассивного поглощения его энергии."
	invocations = list("Возьми то, что их поддерживает.")
	channel_time = 10
	power_cost = 10
	whispered = TRUE
	object_path = /obj/item/clockwork/integration_cog
	creator_message = "<span class='brass'>Вы создаете интеграционную шестерню, которую можно вставить в открытый ЛКП для пассивного поглощения его энергии.</span>"
	usage_tip = "Следы взлома видны только после вскрытия ЛКП. Чтобы открыть запертый ЛКП, воспользуйтесь этой шестерней."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_STRUCTURE
	space_allowed = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 2
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Создает интеграционную шестерню, с помощью которой можно пассивно поглощать энергию из ЛКП."


//Sigil of Transgression: Creates a sigil of transgression, which briefly stuns and applies Belligerent to the first non-servant to cross it.
/datum/clockwork_scripture/create_object/sigil_of_transgression
	descname = "Сигил-ловушка"
	name = "Sigil of Transgression"
	desc = "Создает на плитке сигил, который на короткое время оглушит следующего человека, не являющегося Слугой, пересекающего его, и наложит на него эффект Воинственности."
	invocations = list("Божество, нанеси удар...", "...по тем, кто незаконно проникает сюда.")
	channel_time = 50
	power_cost = 50
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/transgression
	creator_message = "<span class='brass'>Под вами незаметно появляется сигил. Следующий человек, не являющийся Слугой, который пересечёт его, будет поражён.</span>"
	usage_tip = "Этот сигил не лишает жертву дара речи и, как правило, используется для смягчения потенциальных новообращённых или возможных захватчиков"
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 3
	quickbind = TRUE
	quickbind_desc = "Создаёт сигил нарушения, который на короткое время оглушит и замедлит следующего человека, не являющегося Слугой, который пересечёт её."


//Sigil of Submission: Creates a sigil of submission, which converts one heretic above it after a delay.
/datum/clockwork_scripture/create_object/sigil_of_submission
	descname = "Конвертация"
	name = "Sigil of Submission"
	desc = "Создаёт светящийся сигил, который преобразует всех людей, не являющихся Слугами, которые останутся на нём в течение 8 секунд."
	invocations = list("Божество, просвети...", "...тех, кто незаконно проникает сюда.")
	channel_time = 60
	power_cost = 125
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/submission
	creator_message = "<span class='brass'>Под вами появляется светящийся сигил. Любой, кто не является Слугой и пересечет его, будет обращён и через 8 секунд излечен от большинства ран, если не сдвинется с места.</span>"
	usage_tip = "Это основной метод конвертации, хотя он не способен проникнуть через импланты щита разума."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_STRUCTURE
	one_per_tile = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 4
	quickbind = TRUE
	quickbind_desc = "Создает сигил покорности, который преобразует всех, кто не является Слугой и останется на нём."
	requires_full_power = TRUE

//Kindle: Charges the slab with blazing energy. It can be released to stun and silence a target.
/datum/clockwork_scripture/ranged_ability/kindle
	descname = "Оглушение одного вблизи"
	name = "Kindle"
	desc = "Заряжает вашу плиту божественной энергией, позволяя вам ослепить цель светом Ратвара."
	invocations = list("Божество, яви им Свой свет.")
	whispered = TRUE
	channel_time = 25 //2.5 seconds should be a okay compromise between being able to use it when needed, and not being able to just pause in combat for a second and hardstunning your enemy
	power_cost = 125
	usage_tip = "Светом можно пользоваться на расстоянии до двух клеток. Полученный урон ЗНАЧИТЕЛЬНО СОКРАЩАЕТ продолжительность оглушения."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_ATTACK
	primary_component = BELLIGERENT_EYE
	sort_priority = 5
	slab_overlay = "volt"
	ranged_type = /obj/effect/proc_holder/slab/kindle
	ranged_message = "<span class='brass'><i>Вы заряжаете часовую плиту божественной энергией.</i>\n\
	<b>Нажмите левой кнопкой мыши на цель, находящейся в пределах ближнего боя, чтобы оглушить её!\n\
	Нажмите на свою плиту, чтобы отменить.</b></span>"
	timeout_time = 150
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Ошеломляет и лишает цели возможности говорить с близкого расстояния."

//Hateful Manacles: Applies restraints from melee over several seconds. The restraints function like handcuffs and break on removal.
/datum/clockwork_scripture/ranged_ability/hateful_manacles
	descname = "Наручники"
	name = "Hateful Manacles"
	desc = "Создает вокруг запястий цели сковывающие наручники, которые действуют как обычные наручники."
	invocations = list("Сковать еретика!", "Сломите их телом и духом.")
	channel_time = 15
	power_cost = 25
	whispered = TRUE
	usage_tip = "Наручники по прочности примерно такие же, как стяжки, и ломаются при снятии."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_ATTACK
	primary_component = BELLIGERENT_EYE
	sort_priority = 6
	ranged_type = /obj/effect/proc_holder/slab/hateful_manacles
	slab_overlay = "hateful_manacles"
	ranged_message = "<span class='neovgre_small'><i>Вы заряжаете часовую плиту божественной энергией.</i>\n\
	<b>Щелкните левой кнопкой мыши по цели, находящейся в пределах ближнего боя, чтобы наложить оковы!\n\
	Нажмите на свою плиту, чтобы отменить.</b></span>"
	timeout_time = 200
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Надевает наручники на пораженную цель."


//Belligerent: Channeled for up to fifteen times over thirty seconds. Forces non-servants that can hear the chant to walk, doing minor damage. Nar-Sian cultists are burned.
/datum/clockwork_scripture/channeled/belligerent
	descname = "Замедление вокруг"
	name = "Belligerent"
	desc = "Заставляет всех находящихся поблизости не-слуг идти, а не бежать, нанося при этом незначительный урон. Произносится каждые две секунды в течение не более тридцати секунд."
	chant_invocations = list("Накажите их за слепоту!", "Не торопитесь, действуйте не спеша!", "Преклоните колени перед Юстициаром!", "Остановите их наступление!", "Остановите приливы!")
	chant_amount = 15
	chant_interval = 20
	channel_time = 20
	power_cost = 300
	usage_tip = "Полезно для контроля над толпой в людных местах и пресечения массовых передвижений."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_ATTACK
	primary_component = BELLIGERENT_EYE
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Заставляет находящихся поблизости не-Слуг идти, нанося небольшой урон при каждом заклинании.<br><b>Максимум 15 заклинаний.</b>"

/datum/clockwork_scripture/channeled/belligerent/chant_effects(chant_number)
	for(var/mob/living/carbon/C in hearers(7, invoker))
		C.apply_status_effect(STATUS_EFFECT_BELLIGERENT)
	new /obj/effect/temp_visual/ratvar/belligerent(get_turf(invoker))
	return TRUE


//Vanguard: Provides twenty seconds of greatly increased stamina regeneration and stun immunity. At the end of the twenty seconds, 25% of all stuns absorbed aswell as 50% of healed stamloss are applied to the invoker.
/datum/clockwork_scripture/vanguard
	descname = "Иммунитет к стану"
	name = "Vanguard"
	desc = "Обеспечивает на 20 секунд значительно ускоренное восстановление выносливости и иммунитет к оглушению. По истечении 20 секунд заклинатель падает на землю под действием оглушения, эквивалентного 25% от общего количества поглощенных им оглушений, а также теряет 50% восстановленной выносливости в виде потери выносливости. \
    Чрезмерное поглощение оглушений приводит к потере сознания."
	invocations = list("Защити меня...", "...от тьмы!")
	channel_time = 30
	power_cost = 75
	usage_tip = "Вы не можете повторно активировать Авангард, пока находитесь под его защитой."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_SUPPORT
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 8
	quickbind = TRUE
	quickbind_desc = "Позволяет временно быстро восстанавливать выносливость и поглощать оглушения. Часть поглощённых оглушений и восстановленной выносливости будет учитываться при отключении эффекта."

/datum/clockwork_scripture/vanguard/check_special_requirements()
	if(!GLOB.ratvar_awakens && islist(invoker.stun_absorption) && invoker.stun_absorption["vanguard"] && invoker.stun_absorption["vanguard"]["end_time"] > world.time)
		to_chat(invoker, "<span class='warning'>Вы уже находитесь под защитой Авангарда!</span>")
		return FALSE
	return TRUE

/datum/clockwork_scripture/vanguard/scripture_effects()
	if(GLOB.ratvar_awakens)
		for(var/mob/living/L in view(7, get_turf(invoker)))
			if(L.stat != DEAD && is_servant_of_ratvar(L))
				L.apply_status_effect(STATUS_EFFECT_VANGUARD)
			CHECK_TICK
	else
		invoker.apply_status_effect(STATUS_EFFECT_VANGUARD)
	return TRUE


//Sentinel's Compromise: Allows the invoker to select a nearby servant and convert their brute, burn, and oxygen damage into half as much toxin damage.
/datum/clockwork_scripture/ranged_ability/sentinels_compromise
	descname = "Лечение слуг"
	name = "Sentinel's Compromise"
	desc = "Заряжает вашу плиту целительной силой, позволяя преобразовывать весь урон от ушибов, ожогов и нехватки кислорода, нанесенный целевому Служителю, в урон от яда, равный половине от исходного урона."
	invocations = list("Исцели раны...", "...моей несовершенной плоти.")
	channel_time = 30
	power_cost = 100
	usage_tip = "Компромисс очень быстро вызывается и удаляет святую воду с целевого Слуги."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_SUPPORT
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Позволяет преобразовывать урон ушибов, ожогов и удушья слуги в урон от яда, равный половине исходного урона. <br><b>Щелкните по плите, чтобы отключить."
	slab_overlay = "compromise"
	ranged_type = /obj/effect/proc_holder/slab/compromise
	ranged_message = "<span class='inathneq_small'><i>Вы заряжаете часовую пластину целебной силой.</i>\n\
	<b>Щелкните левой кнопкой мыши по другому Слуге или по себе, чтобы восстановить здоровье!\n\
	Нажмите на свою плиту, чтобы отменить.</b></span>"


/*//commenting this out until its reworked to actually do random teleports
//Abscond: Used to return to Reebe.
/datum/clockwork_scripture/abscond
	descname = "Safety warp, teleports you somewhere random. moderately high power cost to use."
	name = "Abscond"
	desc = "Yanks you through space, putting you in hopefully a safe location."
	invocations = list("As we bid farewell, and return to the stars...", "...we shall find our way home.")
	whispered = TRUE
	channel_time = 3.5
	power_cost = 10000
	usage_tip = "This can't be used while on Reebe, for obvious reasons."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_SUPPORT
	primary_component = GEIS_CAPACITOR
	sort_priority = 9
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Teleports you somewhere random, or to an active Ark if one exists. Use in emergencies."
	var/client_color
	requires_full_power = TRUE

/datum/clockwork_scripture/abscond/check_special_requirements()
	if(is_reebe(invoker.z))
		to_chat(invoker, "<span class='danger'>You're at Reebe, attempting to warp in the void could cause you to share your masters fate of banishment!.</span>")
		return
	if(!isturf(invoker.loc))
		to_chat(invoker, "<span class='danger'>You must be visible to warp!</span>")
		return
	return TRUE

/datum/clockwork_scripture/abscond/recital()
	. = ..()

/datum/clockwork_scripture/abscond/scripture_effects()
	var/turf/T
	if(GLOB.ark_of_the_clockwork_justiciar)
		T = get_step(GLOB.ark_of_the_clockwork_justiciar, SOUTH)
	else
		T = get_turf(pick(GLOB.servant_spawns))
	if(!do_teleport(invoker, T, channel = TELEPORT_CHANNEL_CULT, forced = TRUE))
		return
	invoker.visible_message("<span class='warning'>[invoker] flickers and phases out of existence!</span>", \
	"<span class='bold sevtug_small'>You feel a dizzying sense of vertigo as you're yanked through the fabric of reality!</span>")
	T.visible_message("<span class='warning'>[invoker] flickers and phases into existence!</span>")
	playsound(invoker, 'sound/magic/magic_missile.ogg', 50, TRUE)
	playsound(T, 'sound/magic/magic_missile.ogg', 50, TRUE)
	do_sparks(5, TRUE, invoker)
	do_sparks(5, TRUE, T)*/


//Replicant: Creates a new clockwork slab.
/datum/clockwork_scripture/create_object/replicant
	descname = "Новая часовая плита"
	name = "Replicant"
	desc = "Создает новую часовую плиту."
	invocations = list("Металл, стань лучше.")
	channel_time = 10
	power_cost = 25
	whispered = TRUE
	object_path = /obj/item/clockwork/slab
	creator_message = "<span class='brass'>Вы копируете кусок сплава репликанта и приказываете ему сформироваться в новую плиту.</span>"
	usage_tip = "Это неэффективный способ производства энергии, поскольку полученную плиту должен удерживать тот, у кого нет других плит, чтобы произвести что-либо."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_SUPPORT
	space_allowed = TRUE
	primary_component = GEIS_CAPACITOR
	sort_priority = 11
	important = TRUE
	quickbind = TRUE
	quickbind_desc = "Создает новую часовую плиту."


//Wraith Spectacles: Creates a pair of wraith spectacles, which grant xray vision but damage vision slowly.
/datum/clockwork_scripture/create_object/wraith_spectacles
	descname = "Очки-рентген"
	name = "Wraith Spectacles"
	desc = "Изготавливает очки, которые даруют истинное зрение, но приводят к постепенной потере зрения."
	invocations = list("Покажи мне правду об этом мире.")
	channel_time = 10
	power_cost = 50
	whispered = TRUE
	object_path = /obj/item/clothing/glasses/wraith_spectacles
	creator_message = "<span class='brass'>Вы создаете пару очков-призраков, которые дают истинное зрение, но приводят к постепенной потере зрения.</span>"
	usage_tip = "\"Истинное зрение\" означает, что вы способны видеть сквозь стены и в темноте."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_EQUIPMENT
	space_allowed = TRUE
	primary_component = GEIS_CAPACITOR
	sort_priority = 12
	quickbind = TRUE
	quickbind_desc = "Призрачные очки"

//Spatial Gateway: Allows the invoker to teleport themselves and any nearby allies to a conscious servant or clockwork obelisk.
/datum/clockwork_scripture/spatial_gateway
	descname = "Портал к слуге/обелиску"
	name = "Spatial Gateway"
	desc = "Слёзы открывают миниатюрный портал в пространстве-времени для любого сознательного слуги, способного переносить предметы или существ к месту назначения. \
    Каждый слуга, участвующий в заклинании, добавляет одно дополнительное использование и четыре дополнительные секунды к количеству использований и продолжительности действия портала."
	invocations = list("Пространственный разлом...", "...активируйся.")
	channel_time = 30
	power_cost = 400
	whispered = TRUE
	multiple_invokers_used = TRUE
	multiple_invokers_optional = TRUE
	usage_tip = "Этот портал является строго односторонним и пропускает объекты только через портал вызывающего."
	tier = SCRIPTURE_DRIVER
	category = SCRIPTURE_CATEGORY_SUPPORT
	primary_component = GEIS_CAPACITOR
	sort_priority = 10
	quickbind = TRUE
	quickbind_desc = "Позволяет создать односторонний пространственный портал к живому Слуге или часовому обелиску."

/datum/clockwork_scripture/spatial_gateway/check_special_requirements()
	if(!isturf(invoker.loc))
		to_chat(invoker, "<span class='warning'>Чтобы использовать этот отрывок из Священного Писания, вы не должны находиться внутри объекта!</span>")
		return FALSE
	var/other_servants = 0
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(is_servant_of_ratvar(L) && !L.stat && L != invoker)
			other_servants++
	for(var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/O in GLOB.all_clockwork_objects)
		if(O.anchored)
			other_servants++
	if(!other_servants)
		to_chat(invoker, "<span class='warning'>Здесь нет ни других сознательных слуг, ни закреплённых механических обелисков!</span>")
		return FALSE
	return TRUE

/datum/clockwork_scripture/spatial_gateway/scripture_effects()
	var/portal_uses = 0
	var/duration = 0
	for(var/mob/living/L in range(1, invoker))
		if(!L.stat && is_servant_of_ratvar(L))
			portal_uses++
			duration += 40 //4 seconds
	if(GLOB.ratvar_awakens)
		portal_uses = max(portal_uses, 100) //Very powerful if Ratvar has been summoned
		duration = max(duration, 100)
	return slab.procure_gateway(invoker, duration, portal_uses)
