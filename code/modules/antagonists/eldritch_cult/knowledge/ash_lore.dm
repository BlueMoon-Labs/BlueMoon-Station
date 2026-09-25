/datum/eldritch_knowledge/base_ash
	name = "Секрет Ночного Стража"
	summary = "Хватка гасит открытый огонь ради угольков, Угасание за уголёк тушит и лечит; нож и спичка дают клинок."
	details = list(
		"Хватка гасит пожар на полу, горящие свечу, зажигалку, сварочник, фальшфейер или спичку: +1 уголёк раз в 15 секунд.",
		"Огонь на полу в новом отделе идёт в дело пути, огонь в руках даёт только уголёк.",
		"Угасание за 1 уголёк тушит вас, лечит 15 ожогов и 10 ушибов и оставляет вокруг огонь на 6 секунд.",
		"Огонь Угасания поджигает врагов в 1 клетке от центра; еретиков, слуг и защищённых от магии не трогает.",
		"Перезарядка Угасания 20 секунд.",
		"Вода и пена гасят огонь Угасания. Готовую цель на своём огне сердце уводит в изнанку за 1 секунду, пока та не встанет.",
		"Нож и спичка на руне дают пепельный клинок.",
	)
	role = HERETIC_ROLE_CRAFT
	resource_rules = list(
		"Запас до 4 угольков.",
		"Хватка по открытому огню даёт уголёк раз в 15 секунд; обычный уголь не нужен.",
		"С Властью Пепла хватка по загоревшемуся врагу тоже даёт уголёк раз в 15 секунд.",
		"Взрыв Метки Пепла клинком даёт уголёк.",
		"Угасание и выдох кадильницы тратят по 1 угольку.",
	)
	gain_text = "Ночная стража знает своё дело. Если вы загляните к ним ночью, то они расскажут вам историю о пепельном фонаре."
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/match)
	result_atoms = list(/obj/item/melee/sickly_blade/ash)
	cost = 0
	route = PATH_ASH

/datum/eldritch_knowledge/spell/ashen_shift
	name = "Пепельный переход"
	summary = "На 1,5 секунды вы обращаетесь в пепел и проходите сквозь стены и двери."
	details = list(
		"Вы исчезаете и 1,5 секунды свободно движетесь сквозь преграды.",
		"Затем 2,5 секунды вы проявляетесь на месте и не можете сдвинуться.",
		"Переход гасит огонь на вас.",
		"Работает в чужой хватке; до вознесения - не под оглушением и не в стамкрите.",
		"Вход и выход видны по пеплу и пару. Перезарядка 15 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Ему были ведомы пути, огибающие реальность."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp
	name = "Власть Пепла"
	summary = "Хватка поджигает врага и мутит ему зрение, а горящий враг даёт уголёк."
	details = list(
		"Хватка добавляет заряд горения, поджигает, ранит глаза на 5 и размывает зрение.",
		"Если цель загорелась, вы получаете уголёк, не чаще раза в 15 секунд.",
		"Огнетушитель, вода и катание по полу тушат; защита от магии срывает поджог.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Ночной Страж был первым среди достойных, и всё началось с его предательства. Его фонарь обратился в пепел, его дозор завершился."
	cost = 1
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target) || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/carbon/victim = target
	victim.adjustOrganLoss(ORGAN_SLOT_EYES, 5)
	victim.blur_eyes(6)
	victim.adjust_fire_stacks(1)
	victim.IgniteMob()
	if(victim.on_fire && COOLDOWN_FINISHED(src, resource_harvest))
		var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
		var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
		path?.gain_combat_resource()
		COOLDOWN_START(src, resource_harvest, 15 SECONDS)
	return TRUE

/datum/eldritch_knowledge/ashen_eyes
	name = "Пепельный глаз"
	summary = "Глаза и осколок стекла дают медальон теплового зрения."
	details = list(
		"Глаза и осколок стекла на руне дают медальон с живым глазом.",
		"На шее еретика или его слуги глаз видит тепло живых тел сквозь стены.",
		"На чужой шее глаз спит.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Его пронзительный взгляд вёл его через мирские страдания."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes,/obj/item/shard)
	result_atoms = list(/obj/item/clothing/neck/eldritch_amulet)

/datum/eldritch_knowledge/ash_mark
	name = "Метка Пепла"
	summary = "Хватка ставит метку на 15 секунд, удар пепельным клинком её взрывает."
	details = list(
		"Взрыв: 15 ожогов, 30 урона выносливости и уголёк для Угасания.",
		"Метка перескакивает на врага рядом и с каждым переходом слабеет, всего до 5 взрывов.",
		"Через 15 секунд метка спадает сама.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "И тогда я узрел их, отмеченных. Они были недостижимы. А крики их наполнены агонией."
	cost = 2
	route = PATH_ASH

/datum/eldritch_knowledge/ash_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(heretic_can_affect(user, target))
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/eldritch/ash,5)
		return TRUE

/datum/eldritch_knowledge/mad_mask
	name = "Маска безумия"
	summary = "Маска, свеча и глаза дают Маску безумия: она пугает и выматывает неверных вокруг."
	details = list(
		"Любая маска, свеча и глаза на руне дают Маску безумия.",
		"На вашем лице она бьёт по людям в 9 клетках: галлюцинации, дрожь, головокружение, смех с потерей выносливости.",
		"Каждого человека маска задевает не чаще раза в 10 секунд; еретиков и слуг не трогает.",
		"Надетую на неверного маску он сам снять не может.",
		"Маска горит.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Ночной Страж пропал. Так подумала Стража. Но он всё ещё блуждал по миру, незримый для всех."
	cost = 1
	result_atoms = list(/obj/item/clothing/mask/gas/void_mask)
	required_atoms = list(/obj/item/organ/eyes,/obj/item/clothing/mask,/obj/item/candle)
	route = PATH_ASH

/datum/eldritch_knowledge/spell/flame_birth
	name = "Возрождение ночного дозорного"
	summary = "Гасит вас и вытягивает жар из 4 горящих врагов рядом: им 15 ожогов, вам лечение."
	details = list(
		"Вы гаснете, а до 4 горящих врагов в 4 клетках получают по 15 ожогов.",
		"За каждого из них вы лечите по 10 ушибов и 10 ожогов.",
		"Без огня на вас и горящих врагов рядом способность не срабатывает.",
		"Сначала подожгите врагов хваткой, клинком или Угасанием; защита от магии спасает цель.",
		"Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Огонь уже было не остановить, но всё же жизнь теплилась в его обугленном теле. \
		Ночной Страж был особенным человеком, смотрящим..."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/fiery_rebirth
	route = PATH_ASH

/datum/eldritch_knowledge/flame_immunity
	name = "Благословение ночного стража"
	summary = "Огонь и жара вам не страшны; зажигалка, мензурка и бумага дают кадильницу углей."
	details = list(
		"Вы не горите и не получаете урона от жары.",
		"Зажигалка, мензурка и лист бумаги на руне дают кадильницу.",
		"Кадильница гасит горящее существо касанием и копит до 3 зарядов пламени.",
		"Касание центра своего огня Угасания забирает его как 1 заряд.",
		"В руке: после замаха 0,8 секунды весь запас бьёт конусом на 3 клетки, 6 ожогов за заряд и поджог.",
		"Выдох стоит 1 уголёк, между выдохами 12 секунд.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Истинный Свет может разрушить всё и пробудить что-то новое в людях. Если бы только они приняли его."
	required_atoms = list(/obj/item/lighter, /obj/item/reagent_containers/glass/beaker, /obj/item/paper)
	result_atoms = list(/obj/item/heretic_relic/censer)
	cost = 2
	route = PATH_ASH
	var/list/trait_list = list(TRAIT_RESISTHEAT,TRAIT_NOFIRE)

/datum/eldritch_knowledge/flame_immunity/on_body_gain(mob/living/user)
	if(!user)
		return
	for(var/X in trait_list)
		ADD_TRAIT(user, X, REF(src))

/datum/eldritch_knowledge/flame_immunity/on_body_lose(mob/living/user)
	if(!user)
		return
	for(var/trait in trait_list)
		REMOVE_TRAIT(user, trait, REF(src))

/datum/eldritch_knowledge/spell/nightwatchers_rite
	name = "Ритуал ночных стражей"
	summary = "5 потоков огня веером на 15 клеток: 8 ожогов и поджог каждому на пути."
	details = list(
		"Укажите направление: 5 огненных потоков расходятся веером на 15 клеток.",
		"Каждый поток жжёт всех на своём пути на 8 и поджигает, клетки вспыхивают.",
		"Стены останавливают поток; мехи получают 45 урона.",
		"Защита от магии отводит поток. Перезарядка 30 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Когда сияние Фонаря сожжёт их кожу, уже ничто не защитит их от пепла."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/pointed/nightwatchers_rite
	route = PATH_ASH

/datum/eldritch_knowledge/ash_blade_upgrade
	name = "Огненный клинок"
	summary = "Пепельный клинок жжёт на 2 и поджигает цель, улучшения поднимают ожоги до 6."
	details = list(
		"Каждый удар пепельным клинком: прямые ожоги и заряд горения, цель загорается.",
		"Улучшения: 2 / 4 / 6 ожогов и 1 / 2 / 3 заряда горения за удар.",
		"Прямой урон проходит и по негорящей цели.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Он вернулся, с клинком в руке, покачивая им, покуда пепел падал с небес. \
		Его город, люди, которых он поклялся защищать... и дозор, который он нёс. Всё это сгорело до тла."
	cost = 2
	route = PATH_ASH

/datum/eldritch_knowledge/ash_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	victim.adjustFireLoss(2 * passive_values[passive_level])
	victim.adjust_fire_stacks(passive_values[passive_level])
	victim.IgniteMob()

/datum/eldritch_knowledge/curse/corrosion
	name = "Проклятие коррозии"
	summary = "Проклинает человека по отпечаткам: 2 минуты рвоты и повреждения органов."
	details = list(
		"Кусачки, лужа крови, сердце, левая и правая рука на руне.",
		"В центр руны - предмет с отпечатками голых рук жертвы, он останется после обряда.",
		"Цель выбирается из хозяев отпечатков и проклинается там, где находится.",
		"Защита от магии спасает от проклятия.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Проклятая земля, проклятый человек, проклятый разум."
	cost = 1
	required_atoms = list(/obj/item/wirecutters,/obj/effect/decal/cleanable/blood,/obj/item/organ/heart,/obj/item/bodypart/l_arm,/obj/item/bodypart/r_arm)
	timer = 2 MINUTES

/datum/eldritch_knowledge/curse/corrosion/curse(mob/living/chosen_mob)
	. = ..()
	chosen_mob.apply_status_effect(/datum/status_effect/corrosion_curse)

/datum/eldritch_knowledge/curse/corrosion/uncurse(mob/living/chosen_mob)
	. = ..()
	chosen_mob.remove_status_effect(/datum/status_effect/corrosion_curse)

/datum/eldritch_knowledge/curse/paralysis
	name = "Проклятие паралича"
	summary = "Проклинает человека по отпечаткам: 5 минут он не может ходить."
	details = list(
		"Нож, лужа крови, левая и правая нога и топорик на руне.",
		"В центр руны - предмет с отпечатками голых рук жертвы, он останется после обряда.",
		"Цель выбирается из хозяев отпечатков и проклинается там, где находится.",
		"Защита от магии спасает от проклятия.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Искази плоть, заставь её подчиниться."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife,/obj/effect/decal/cleanable/blood,/obj/item/bodypart/l_leg,/obj/item/bodypart/r_leg,/obj/item/hatchet)
	timer = 5 MINUTES

/datum/eldritch_knowledge/curse/paralysis/curse(mob/living/chosen_mob)
	. = ..()
	ADD_TRAIT(chosen_mob, TRAIT_PARALYSIS_L_LEG, REF(src))
	ADD_TRAIT(chosen_mob, TRAIT_PARALYSIS_R_LEG, REF(src))
	chosen_mob.update_mobility()

/datum/eldritch_knowledge/curse/paralysis/uncurse(mob/living/chosen_mob)
	. = ..()
	REMOVE_TRAIT(chosen_mob, TRAIT_PARALYSIS_L_LEG, REF(src))
	REMOVE_TRAIT(chosen_mob, TRAIT_PARALYSIS_R_LEG, REF(src))
	chosen_mob.update_mobility()

/datum/eldritch_knowledge/spell/cleave
	name = "Кровавый раскол"
	summary = "Режет человека в 7 клетках и врагов рядом с ним: 20 ушибов, рана и кровотечение."
	details = list(
		"Укажите живого человека: он и враги в клетке от него получают 20 ушибов и резаную рану.",
		"Раны кровоточат.",
		"Действует только на людей с конечностями; защита от магии спасает.",
		"Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Сначала я не понимал, что это за орудия войны, но священник посоветовал мне использовать их, несмотря ни на что. Скоро, сказал он, я буду хорошо их знать."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/cleave

/datum/eldritch_knowledge/final_eldritch/ash_final
	name = "Ритуал Пепельного Лорда"
	summary = "Пламя на вас лечит ожоги и оставляет огненный след, открываются Огненный каскад и Клятва огня."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место и 30 секунд может помешать.",
		"Общая стойкость вознесения, защита от огня и жары.",
		"Пока вы сухи, пламя на вас лечит по 3 ожога каждые 2 секунды, ушибы не трогает.",
		"Покинутая клетка горит 4 секунды и поджигает врагов; еретиков, слуг, защищённых от магии и газ не трогает.",
		"Огненный каскад: волна на 10 клеток, 15 ожогов и поджог, перезарядка 30 секунд.",
		"Клятва огня: 60 секунд кольцо огня жжёт врагов рядом, перезарядка 2 минуты.",
		"Слабость: вода и пена гасят пламя на 7 секунд - ни следа, ни лечения.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Его фонарь обратился в пепел, Ночной Страж сгорел вместе с ним. Но его пламя разгорится вновь, \
		во имя Ночного стража я завершу этот ритуал! Он продолжает наблюдать, и теперь я един с пламенем: \
		оно идёт за мной по пятам, и лишь вода может его унять. \
		УЗРИТЕ ЖЕ МОЁ ВОЗНЕСЕНИЕ, ПЕПЕЛЬНЫЙ ФОНАРЬ ЗАЖЖЕТСЯ ВНОВЬ!"
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	route = PATH_ASH
	parallax_scene = ANTAG_SCENE_HERETIC_ASH
	ascension_traits = list(TRAIT_RESISTHEAT, TRAIT_NOFIRE)
	ascension_spells = list(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big, /obj/effect/proc_holder/spell/targeted/fire_sworn)

/datum/eldritch_knowledge/final_eldritch/ash_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	if(!simulated)
		user.client?.give_award(/datum/award/achievement/misc/ash_ascension, user)
	return TRUE
