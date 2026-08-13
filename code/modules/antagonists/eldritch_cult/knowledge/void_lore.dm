/datum/eldritch_knowledge/base_void
	name = "Мерцание зимы"
	desc = "Открывает перед вами путь Пустоты. \
		Позволяет трансмутировать нож при минусовой температуре в Клинок Пустоты."
	gain_text = "Я чувствую мерцание вокруг, воздух вокруг меня становится холоднее. \
		Я начинаю осознавать пустоту существования. Что-то наблюдает за мной."
	banned_knowledge = list(/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_flesh,/datum/eldritch_knowledge/final_eldritch/ash_final,/datum/eldritch_knowledge/final_eldritch/flesh_final,/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/final_eldritch/rust_final)
	next_knowledge = list(/datum/eldritch_knowledge/void_grasp)
	required_atoms = list(/obj/item/kitchen/knife)
	result_atoms = list(/obj/item/melee/sickly_blade/void)
	cost = 0
	route = PATH_VOID

/datum/eldritch_knowledge/base_void/recipe_snowflake_check(list/atoms, loc)
	. = ..()
	var/turf/open/turfie = loc
	if(turfie.GetTemperature() > T0C)
		return FALSE

/datum/eldritch_knowledge/void_grasp
	name = "Хватка Пустоты"
	desc = "Временно лишает жертву дара речи, а также снижает температуру ее тела."
	gain_text = "Я чувствую незримого наблюдателя, который смотрит за мной. Холод растет во мне. \
		Это лишь первый шаг в познании тайны."
	cost = 1
	route = PATH_VOID
	next_knowledge = list(/datum/eldritch_knowledge/cold_snap)

/datum/eldritch_knowledge/void_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!iscarbon(target))
		return
	var/mob/living/carbon/carbon_target = target
	var/turf/open/turfie = get_turf(carbon_target)
	turfie.TakeTemperature(-20)
	carbon_target.adjust_bodytemperature(-40)
	carbon_target.silent = clamp(carbon_target.silent + 4, 0, 20)
	return TRUE

/datum/eldritch_knowledge/void_grasp/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	var/datum/status_effect/eldritch/E = H.has_status_effect(/datum/status_effect/eldritch/rust) || H.has_status_effect(/datum/status_effect/eldritch/ash) || H.has_status_effect(/datum/status_effect/eldritch/flesh)  || H.has_status_effect(/datum/status_effect/eldritch/void)
	if(!E)
		return
	E.on_effect()
	H.silent = clamp(H.silent + 3, 0, 20)

/datum/eldritch_knowledge/cold_snap
	name = "Путь Аристократа"
	desc = "Делает вас невосприимчивым к низким температурам, и убирает потребность в дыхании. \
		Однако вы все еще можете получить урон от недостатка давления."
	gain_text = "Я нашел нить ледяного дыхания. Она привела меня в странное святилище, сплошь состоящее из кристаллов. \
		Полупрозачное, белоснежное изображение благородного человека стояло передо мной."
	cost = 1
	route = PATH_VOID
	next_knowledge = list(/datum/eldritch_knowledge/void_cloak,/datum/eldritch_knowledge/void_mark,/datum/eldritch_knowledge/armor)

/datum/eldritch_knowledge/cold_snap/on_gain(mob/user)
	. = ..()
	ADD_TRAIT(user,TRAIT_RESISTCOLD,MAGIC_TRAIT)
	ADD_TRAIT(user, TRAIT_NOBREATH, MAGIC_TRAIT)

/datum/eldritch_knowledge/cold_snap/on_lose(mob/user)
	. = ..()
	REMOVE_TRAIT(user,TRAIT_RESISTCOLD,MAGIC_TRAIT)
	ADD_TRAIT(user, TRAIT_NOBREATH, MAGIC_TRAIT)

/datum/eldritch_knowledge/void_cloak
	name = "Плащ пустоты"
	desc = "Плащ, который по желанию может становиться невидимым, скрывая предметы, которые вы храните в нем. Чтобы создать его, преобразуйте стеклянный осколок, любой предмет одежды, который можно надеть поверх униформы, и любую простыню."
	gain_text = "Сова - хранительница вещей, которых совсем нет на практике, но которые теоретически существуют."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/flesh_ghoul,/datum/eldritch_knowledge/cold_snap)
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/void)
	required_atoms = list(/obj/item/shard,/obj/item/clothing/suit,/obj/item/bedsheet)

/datum/eldritch_knowledge/void_mark
	name = "Знак Пустоты"
	desc = "Ваша Хватка Мансуса теперь накладывает Метку Пустоты. Чтобы активировать метку, ударьте жертву Клинком Пустоты. \
		При срабатывании он заставляет жертву замолчать и значительно понижает температуру ее тела."
	gain_text = "Порыв ветра? Может быть, мерцание в воздухе. Его присутствие подавляет, \
		все мои чувства предали меня, мой разум - мой враг."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/void_phase)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/ash_mark,/datum/eldritch_knowledge/flesh_mark)
	route = PATH_VOID

/datum/eldritch_knowledge/void_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target))
		return
	. = TRUE
	var/mob/living/living_target = target
	living_target.apply_status_effect(/datum/status_effect/eldritch/void)

/datum/eldritch_knowledge/spell/void_phase
	name = "Пустотный сдвиг"
	desc = "Вы получаете рывок, позволяющий вам  \
		мгновенно телепортироваться в нужное место, нанося урон вокруг вас и выбранного вами места."
	gain_text = "Существо назвало себя Аристократом. Он легко проходят по воздуху, как \
		сквозь пустоту, оставляя за собой резкий холодный ветер. Он исчез, оставляв меня в снегу."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/void_blink
	next_knowledge = list(/datum/eldritch_knowledge/rune_carver,/datum/eldritch_knowledge/crucible,/datum/eldritch_knowledge/void_blade_upgrade)
	route = PATH_VOID

/datum/eldritch_knowledge/rune_carver
	name = "Нож резьбы"
	gain_text = "Запечатленные, высеченные на камне... вечные. Я могу вырезать монолит и пробудить его силу!"
	desc = "Вы можете создать нож для резьбы, который позволяет создавать на полу до 3 рисунков, оказывающих различное воздействие на неверующих, которые по ним ходят. Из них получается довольно удобное метательное оружие. Чтобы создать нож для резьбы, соедините нож с осколком стекла и листом бумаги."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/spell/void_phase,/datum/eldritch_knowledge/summon/raw_prophet)
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/shard,/obj/item/paper)
	result_atoms = list(/obj/item/melee/rune_knife)

/datum/eldritch_knowledge/crucible
	name = "Разинутый тигель"
	gain_text = "Это сущая агония, я не смог вызвать отверженного императора, но я наткнулся на другой рецепт..."
	desc = "Позволяет вам создать разинутый тигель, сверхъестественную структуру, которая позволяет вам создавать зелья с различными эффектами, для этого преобразуйте стол в резервуар для воды."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/spell/void_phase,/datum/eldritch_knowledge/spell/area_conversion)
	required_atoms = list(/obj/structure/reagent_dispensers/watertank,/obj/structure/table)
	result_atoms = list(/obj/structure/eldritch_crucible)

/datum/eldritch_knowledge/void_blade_upgrade
	name = "Ищущий Клинок"
	desc = "Теперь вы можете использовать свой клинок на удаленной отмеченной цели, чтобы переместиться к ней и атаковать."
	gain_text = "Мимолетные воспоминания путь имеющий начало, но не имеющий конца. Я отмечаю свой путь кровью на снегу. Я не помню кто я и куда я иду"
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/voidpull)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/rust_blade_upgrade)
	route = PATH_VOID

/datum/eldritch_knowledge/void_blade_upgrade/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	. = ..()
	var/mob/living/carbon/carbon_human = user
	var/mob/living/carbon/human/human_target = target
	var/datum/status_effect/eldritch/effect = human_target.has_status_effect(/datum/status_effect/eldritch/rust) || human_target.has_status_effect(/datum/status_effect/eldritch/ash) || human_target.has_status_effect(/datum/status_effect/eldritch/flesh) || human_target.has_status_effect(/datum/status_effect/eldritch/void)
	if(!effect)
		return
	var/dir = angle2dir(dir2angle(get_dir(user,human_target))+180)
	carbon_human.forceMove(get_step(human_target,dir))
	var/obj/item/melee/sickly_blade/blade = carbon_human.get_active_held_item()
	blade.melee_attack_chain(carbon_human,human_target,attackchain_flags = ATTACK_IGNORE_CLICKDELAY)

/datum/eldritch_knowledge/spell/voidpull
	name = "Притяжение пустоты"
	desc = "Вы получаете способность, которая позволяет вам притягивать к себе окружающих вас людей и ненадолго оглушать их."
	gain_text = "Все мимолетно, но что еще остается? Я близок к завершению начатого. \
		Я снова видел Аристократа. Он сказал мне, что я опаздываю. Его тяга огромна, я не могу повернуть назад."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/void_pull
	next_knowledge = list(/datum/eldritch_knowledge/spell/boogiewoogie,/datum/eldritch_knowledge/spell/blood_siphon,/datum/eldritch_knowledge/summon/rusty)
	route = PATH_VOID

/datum/eldritch_knowledge/spell/boogiewoogie
	name = "Аплодисменты пустоты"
	gain_text = "Занавес опускается, и я уверен, что Аристократ гордится мной."
	desc = "Хлопнув в ладоши, вы можете поменяться местами с кем-то, кто находится в пределах вашего поля зрения."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/pointed/boogie_woogie
	next_knowledge = list(/datum/eldritch_knowledge/spell/domain_expansion)
	route = PATH_VOID

/datum/eldritch_knowledge/spell/domain_expansion
	name = "Бесконечная пустота"
	gain_text = "Этот мир станет моей сценой, и ничто не будет для меня недоступно."
	desc = "После небольшой задержки вы получаете возможность помечать область размером 7х7 как свой домен. Существа в вашем домене замедляются и помечаются знаком пустоты, что позволяет вам быстро телепортироваться к ним и наносить им удары, что еще больше ограничивает их способность передвигаться."
	cost = 2
	sacs_needed = 3
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	next_knowledge = list(/datum/eldritch_knowledge/final_eldritch/void_final)
	route = PATH_VOID

/datum/eldritch_knowledge/spell/domain_expansion/on_gain(mob/user)
	. = ..()
	priority_announce("Внимание, [station_name()]. [user.real_name] излучает пространственную нестабильность, в связи с которой эхо утерянных в космосе душ разносится по округе... вы можете ощутить зловещее присутствие! ", sound = 'sound/misc/notice1.ogg')

/datum/eldritch_knowledge/final_eldritch/void_final
	name = "Вальс Конца Времен"
	desc = "Ритуал вознесения Пути Пустоты. \
		Принесите 3 трупа на руну начертанную при минусовой температуре, чтобы выполнить ритуал. \
		После завершения вызывает пустотную бурю \
		что окутывает станцию, замораживает и ранит язычников. Те, кто находится поблизости, замерзают ещё быстрее, а также теряют возможность говорить. \
		Кроме того, вы приобретете иммунитет к воздействию космоса."
	gain_text = "Мир погружается во тьму. Я стою на пороге пустоты, вокруг, мерцая острыми гранями, бушует ледяной шторм. \
		Передо мной стоит Аристократ, жестом приглашая меня станцевать. Мы сыграем вальс под шепот умирающей реальности, \
		пока мир разрушается на наших глазах. Пустота обратит все в ничто, СТАНЬТЕ СВИДЕТЕЛЕМ МОЕГО ВОЗНЕСЕНИЯ!"
	cost = 5
	sacs_needed = 5
	required_atoms = list(/mob/living/carbon/human)
	route = PATH_VOID
	///soundloop for the void theme
	var/datum/looping_sound/void_loop/sound_loop
	///Reference to the ongoing voidstorm that surrounds the heretic
	var/datum/weather/void_storm/storm

/datum/eldritch_knowledge/final_eldritch/void_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/mob/living/carbon/human/waltzing = user
	waltzing.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/repulse/eldritch)
	waltzing.physiology.brute_mod *= 0.5
	waltzing.physiology.burn_mod *= 0.5
	ADD_TRAIT(waltzing, TRAIT_RESISTLOWPRESSURE, MAGIC_TRAIT)
	waltzing.client?.give_award(/datum/award/achievement/misc/void_ascension, waltzing)
	priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Дворянин пустоты, [waltzing.real_name], прибыл к вам, кружась в вальсе кончины миров! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'modular_bluemoon/kovac_shitcode/sound/eldritch/void_lore.ogg')
	sound_loop = new(user, TRUE, TRUE)
	return ..()

/datum/eldritch_knowledge/final_eldritch/void_final/on_death()
	if(sound_loop)
		sound_loop.stop()
	if(storm)
		storm.end()
		QDEL_NULL(storm)

/datum/eldritch_knowledge/final_eldritch/void_final/on_life(mob/user)
	. = ..()
	if(!finished)
		return

	for(var/mob/living/carbon/livies in spiral_range(7,user)-user)
		if(IS_HERETIC_MONSTER(livies) || IS_HERETIC(livies))
			return
		livies.silent = clamp(livies.silent + 1, 0, 5)
		livies.adjust_bodytemperature(-20)

	var/turf/turfie = get_turf(user)
	if(!isopenturf(turfie))
		return
	var/turf/open/open_turfie = turfie
	open_turfie.TakeTemperature(-20)

	var/area/user_area = get_area(user)
	var/turf/user_turf = get_turf(user)

	if(!storm)
		storm = new /datum/weather/void_storm(list(user_turf.z))
		storm.telegraph()

	storm.area_type = user_area.type
	storm.impacted_areas = list(user_area)
	storm.update_areas()
