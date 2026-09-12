/datum/eldritch_knowledge/base_ash
	name = "Секрет Ночного Стража"
	desc = "Открывает Путь Пепла: поджигайте врагов, собирайте угольки и отступайте через собственное пламя. \
		Спичка и нож превращаются в пепельный клинок. Угасание расходует уголёк, тушит вас, лечит и оставляет огненный след."
	gain_text = "Ночная стража знает своё дело. Если вы загляните к ним ночью, то они расскажут вам историю о пепельном фонаре."
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/match)
	result_atoms = list(/obj/item/melee/sickly_blade/ash)
	cost = 0
	route = PATH_ASH

/datum/eldritch_knowledge/spell/ashen_shift
	name = "Пепельная Тропа"
	gain_text = "Ему были ведомы пути, огибающие реальность."
	desc = "Позволяет вам использовать Пепельные Тропы, которые позволяют игнорировать материальные преграды на короткий промежуток времени."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp
	name = "Власть Пепла"
	gain_text = "Ночной Страж был первым среди достойных, и всё началось с его предательства. Его фонарь обратился в пепел, его дозор завершился."
	desc = "Хватка Мансуса обжигает глаза и затуманивает зрение. При хватке горящего врага вы получаете уголёк, не чаще раза в 15 секунд."
	cost = 1
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target) || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/carbon/victim = target
	victim.adjustOrganLoss(ORGAN_SLOT_EYES, 5)
	victim.blur_eyes(6)
	if(victim.on_fire && COOLDOWN_FINISHED(src, resource_harvest))
		var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
		var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
		path?.gain_combat_resource()
		COOLDOWN_START(src, resource_harvest, 15 SECONDS)
	return TRUE

/datum/eldritch_knowledge/ashen_eyes
	name = "Пепельный глаз"
	gain_text = "Его пронзительный взгляд вёл его через мирские страдания."
	desc = "Позволяет вам создать амулет теплового зрения, преобразовав глаза и стеклянный осколок."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes,/obj/item/shard)
	result_atoms = list(/obj/item/clothing/neck/eldritch_amulet)

/datum/eldritch_knowledge/ash_mark
	name = "Метка Пепла"
	gain_text = "И тогда я узрел их, отмеченных. Они были недостижимы. А крики их наполнены агонией."
	desc = "Хватка накладывает Метку Пепла. Удар пепельным клинком активирует её: 15 ожогов, 30 урона выносливости и уголёк для Угасания. Метка переходит к соседнему врагу, слабея после каждого из пяти срабатываний."
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
	desc = "Позволяет трансмутировать любую маску, свечу и глаза в Маску безумия. \
		Маска вселяет страх в окружающих вас неверных, нанося им урон по их выносливости, а также вызывая галлюцинации и безумие. \
		Её также можно надеть на неверного, после чего тот уже не сможет её снять..."
	gain_text = "Ночной Страж пропал. Так подумала Стража. Но он всё ещё блуждал по миру, незримый для всех."
	cost = 1
	result_atoms = list(/obj/item/clothing/mask/gas/void_mask)
	required_atoms = list(/obj/item/organ/eyes,/obj/item/clothing/mask,/obj/item/candle)
	route = PATH_ASH

/datum/eldritch_knowledge/spell/flame_birth
	name = "Возрождение Ночного Стража"
	desc = "Погасите огонь на себе и вытяните жар из четырёх горящих врагов в пределах 4 клеток. Каждый получает 15 ожогов и восстанавливает вам по 10 ушибов и ожогов. Сначала подожгите противников клинком или Угасанием."
	gain_text = "Огонь уже было не остановить, но всё же жизнь теплилась в его обугленном теле. \
		Ночной Страж был особенным человеком, смотрящим..."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/fiery_rebirth
	route = PATH_ASH

/datum/eldritch_knowledge/flame_immunity
	name = "Благословение ночного стража"
	gain_text = "Истинный Свет может разрушить всё и пробудить что-то новое в людях. Если бы только они приняли его."
	desc = "Вы невосприимчивы к огню и жаре. Соедините зажигалку, мензурку и лист бумаги, чтобы создать кадильницу углей: собирайте пламя с горящих существ и выпускайте его конусом, расходуя уголёк."
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
	gain_text = "Когда сияние Фонаря сожжёт их кожу, уже ничто не защитит их от пепла."
	desc = "Выпустите из своей руки пять огненных потоков, каждый из которых поджигает поражённые цели и опаляет их при попадании."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/pointed/nightwatchers_rite
	route = PATH_ASH

/datum/eldritch_knowledge/ash_blade_upgrade
	name = "Огненный клинок"
	desc = "Теперь атаки вашим клинком поджигают жертв."
	gain_text = "Он вернулся, с клинком в руке, покачивая им, покуда пепел падал с небес. \
		Его город, люди, которых он поклялся защищать... и дозор, который он нёс. Всё это сгорело до тла."
	cost = 2
	route = PATH_ASH

/datum/eldritch_knowledge/ash_blade_upgrade/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.adjust_fire_stacks(passive_values[passive_level])
		C.IgniteMob()

/datum/eldritch_knowledge/curse/corrosion
	name = "Проклятие коррозии"
	gain_text = "Проклятая земля, проклятый человек, проклятый разум."
	desc = "Наложите на человека проклятие: 2 минуты рвоты и серьёзных повреждений органов. Для обряда нужны кусачки, лужа крови, сердце, левая и правая рука. На саму руну положите предмет с отпечатками голых рук жертвы: он должен оставаться там до конца обряда, но не будет израсходован."
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
	gain_text = "Искази плоть, заставь её подчиниться."
	desc = "Наложите на жертву проклятие, которое лишит её возможности ходить на 5 минут. Принесите в жертву нож, лужу крови, пару ног и топор. На саму руну положите предмет с отпечатками голых рук жертвы: он должен оставаться там до конца обряда, но не будет израсходован."
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
	gain_text = "Сначала я не понимал, что это за орудия войны, но священник посоветовал мне использовать их, несмотря ни на что. Скоро, сказал он, я буду хорошо их знать."
	desc = "Даёт заклинание, которое ранит цель и существ рядом с ней, вызывая кровотечение."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/cleave

/datum/eldritch_knowledge/final_eldritch/ash_final
	name = "Ритуал Пепельного Лорда"
	desc = "После трёх подношений принесите три мёртвых тела на руну. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение даёт защиту от огня, холода и давления, Каскад Огня и Клятву Пламени. Поджигайте врагов и поддерживайте себя Возрождением Ночного Стража."
	gain_text = "Его фонарь обратился в пепел, Ночной Страж сгорел вместе с ним. Но его пламя разгорится вновь, \
		во имя Ночного стража я завершу этот ритуал! Он продолжает наблюдать, и теперь я един с пламенем, \
		УЗРИТЕ ЖЕ МОЁ ВОЗНЕСЕНИЕ, ПЕПЕЛЬНЫЙ ФОНАРЬ ЗАЖЖЕТСЯ ВНОВЬ!"
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	route = PATH_ASH
	parallax_scene = ANTAG_SCENE_HERETIC_ASH
	ascension_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD, TRAIT_RESISTHIGHPRESSURE, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHEAT, TRAIT_NOFIRE)
	ascension_spells = list(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big, /obj/effect/proc_holder/spell/targeted/fire_sworn)

/datum/eldritch_knowledge/final_eldritch/ash_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	user.client?.give_award(/datum/award/achievement/misc/ash_ascension, user)
	return TRUE
