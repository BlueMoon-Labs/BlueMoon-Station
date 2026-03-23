/datum/eldritch_knowledge/base_ash
	name = "Секрет Ночного Стража"
	desc = "Открывает перед вами путь пепла. \
		Позволяет трансмутировать спичку и кухонный нож в Пепельный клинок."
	gain_text = "Ночная стража знает своё дело. Если вы загляните к ним ночью, то они расскажут вам историю о пепельном фонаре."
	banned_knowledge = list(/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/base_flesh,/datum/eldritch_knowledge/final_eldritch/rust_final,/datum/eldritch_knowledge/final_eldritch/flesh_final,/datum/eldritch_knowledge/final_eldritch/void_final,/datum/eldritch_knowledge/base_void)
	next_knowledge = list(/datum/eldritch_knowledge/ashen_grasp)
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/match)
	result_atoms = list(/obj/item/melee/sickly_blade/ash)
	cost = 0
	route = PATH_ASH

/datum/eldritch_knowledge/spell/ashen_shift
	name = "Пепельная Тропа"
	gain_text = "Ему были ведомы пути огибающие реальность."
	desc = "Позволяет вам использовать Пепельные Тропы, которые позволяют игнорировать материальные преграды на короткий промежуток времени."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	next_knowledge = list(/datum/eldritch_knowledge/ash_mark,/datum/eldritch_knowledge/essence,/datum/eldritch_knowledge/ashen_eyes)
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp
	name = "Власть Пепла"
	gain_text = "Ночной Страж был первым среди достойных, и всё началось с его предательства. Его фонарь обратился в пепел, его дозор завершился."
	desc = "Ваша хватка Мансуса опаляет глаза ваших жертв, нанося им урон и ослепляя их."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/spell/ashen_shift)
	route = PATH_ASH

/datum/eldritch_knowledge/ashen_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!iscarbon(target))
		return

	var/mob/living/carbon/C = target
	var/datum/status_effect/eldritch/E = C.has_status_effect(/datum/status_effect/eldritch/rust) || C.has_status_effect(/datum/status_effect/eldritch/ash) || C.has_status_effect(/datum/status_effect/eldritch/flesh) || C.has_status_effect(/datum/status_effect/eldritch/void)
	if(E)
		. = TRUE
		E.on_effect()
		for(var/X in user.mind.spell_list)
			if(!istype(X,/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp))
				continue
			var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/MG = X
			MG.charge_counter = min(round(MG.charge_counter + MG.charge_max * 0.75),MG.charge_max) // refunds 75% of charge.
	var/atom/throw_target = get_edge_target_turf(C, user.dir)
	if(!C.anchored)
		. = TRUE
		C.throw_at(throw_target, rand(4,8), 14, user)
	return

/datum/eldritch_knowledge/ashen_eyes
	name = "Пепльный глаз"
	gain_text = "Его пронзительный взгляд вёл его через мирские страдания."
	desc = "Позволяет вам создать амулет теплового зрения, преобразовав глаза и стеклянный осколок."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/spell/ashen_shift,/datum/eldritch_knowledge/flesh_ghoul)
	required_atoms = list(/obj/item/organ/eyes,/obj/item/shard)
	result_atoms = list(/obj/item/clothing/neck/eldritch_amulet)

/datum/eldritch_knowledge/ash_mark
	name = "Метка Пепла"
	gain_text = "И тогда я узрел их, отмеченных. Они были недостижимы. А крики их наполнены агонией."
	desc = "Ваша хватка Мансуса теперь так же накладывает и Метку Пепла. Метка активируется с помощью удара Пепельным клинком. Когда метка активируется, жертва страдает от урона по выносливости и жутких ожогов. После чего соседние цели так же помечаются. С каждым последующим распространением от активации предыдущей метки урон уменьшается."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/mad_mask)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/flesh_mark,/datum/eldritch_knowledge/void_mark)
	route = PATH_ASH

/datum/eldritch_knowledge/ash_mark/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(isliving(target))
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/eldritch/ash,5)

/datum/eldritch_knowledge/mad_mask
	name = "Маска безумия"
	desc = "Позволяет трансмутировать любую маску, свечу и глаза в Маску безумия. \
		Маска вселяет страх в окружающих вас неверных, нанося им урон по их выносливости, а также вызывая галлюцинации и безумие. \
		Её также можно надеть на неверного, после чего тот уже не сможет её снять..."
	gain_text = "Ночной Страж пропал. Так подумала Стража. Но он всё ещё блуждал по миру, незримый для всех."
	cost = 1
	result_atoms = list(/obj/item/clothing/mask/void_mask)
	required_atoms = list(/obj/item/organ/eyes,/obj/item/clothing/mask,/obj/item/candle)
	next_knowledge = list(/datum/eldritch_knowledge/curse/corrosion,/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/curse/paralysis)
	route = PATH_ASH

/datum/eldritch_knowledge/spell/flame_birth
	name = "Возрождение Ночного Стража"
	desc = "Обучает вас Возрождению Ночного Стража, этот навык гасит огонь на вас и поджигает находящихся рядом с вами неверных. \
		Те, кто находятся в огне, лечат вас пропорционально количеству горящих. \
		Если же жертва находилась в критическом состоянии - она мгновенно умрет."
	gain_text = "Огонь уже было не остановить, но всё же, жизнь теплилась в его обугленном теле. \
		Ночной Страж был особенным человеком, смотрящим..."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/fiery_rebirth
	next_knowledge = list(/datum/eldritch_knowledge/spell/cleave,/datum/eldritch_knowledge/summon/ashy,/datum/eldritch_knowledge/flame_immunity)
	route = PATH_ASH

/datum/eldritch_knowledge/flame_immunity
	name = "Благословение ночного стража"
	gain_text = "Истинный Свет может разрушить всё и создать что то новое в людях. Если бы только они приняли его."
	desc = "Становясь единым целым с пеплом, вы становитесь невосприимчивы к огню и жаре, что позволяет вам процветать в любых экстремальных условиях."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/nightwatchers_rite)
	route = PATH_ASH
	var/list/trait_list = list(TRAIT_RESISTHEAT,TRAIT_NOFIRE)

/datum/eldritch_knowledge/flame_immunity/on_gain(mob/living/user)
	to_chat(user, "<span class='warning'>[gain_text]</span>")
	for(var/X in trait_list)
		ADD_TRAIT(user,X,MAGIC_TRAIT)

/datum/eldritch_knowledge/spell/nightwatchers_rite
	name = "Ритуал ночных стражей"
	gain_text = "Когда сияние Фонаря сожжет их кожу, уже ничто не защитит их от пепла."
	desc = "Выпустите из своей руки пять огненных потоков, каждый из которых поджигает пораженные цели и опаляет их при попадании."
	cost = 2
	sacs_needed = 3
	spell_to_add = /obj/effect/proc_holder/spell/pointed/nightwatchers_rite
	next_knowledge = list(/datum/eldritch_knowledge/final_eldritch/ash_final)
	route = PATH_ASH

/datum/eldritch_knowledge/spell/nightwatchers_rite/on_gain(mob/user)
	. = ..()
	priority_announce("Внимание, [station_name()]. [user.real_name] излучает пространственную нестабильность, в связи с которой обнаружены крупные тепловые сигнатуры! Надвигается разрастающийся пламенный ужас..", sound = 'sound/misc/notice1.ogg')

/datum/eldritch_knowledge/ash_blade_upgrade
	name = "Огненный клинок"
	desc = "Теперь атаки вашим клинком поджигают жертв."
	gain_text = "Он вернулся, с клинком в руке, покачивая им, покуда пепел падал с небес. \
		Его город, люди, которых он поклялся защищать... и дозор, который он нёс. Всё это сгорело до тла."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/flame_birth)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_blade_upgrade,/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/void_blade_upgrade)
	route = PATH_ASH

/datum/eldritch_knowledge/ash_blade_upgrade/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.adjust_fire_stacks(1)
		C.IgniteMob()

/datum/eldritch_knowledge/curse/corrosion
	name = "Проклятие корозии"
	gain_text = "Проклятая земля, проклятый человек, проклятый разум."
	desc = "Проклясть человека на 2 минуты рвоты и серьезных повреждений органов. Используя кусачки, лужу крови, сердце, левую и правую руку, а также предмет, к которому жертва прикасалась голыми руками."
	cost = 1
	required_atoms = list(/obj/item/wirecutters,/obj/effect/decal/cleanable/blood,/obj/item/organ/heart,/obj/item/bodypart/l_arm,/obj/item/bodypart/r_arm)
	next_knowledge = list(/datum/eldritch_knowledge/mad_mask,/datum/eldritch_knowledge/spell/area_conversion)
	timer = 2 MINUTES

/datum/eldritch_knowledge/curse/corrosion/curse(mob/living/chosen_mob)
	. = ..()
	chosen_mob.apply_status_effect(/datum/status_effect/corrosion_curse)

/datum/eldritch_knowledge/curse/corrosion/uncurse(mob/living/chosen_mob)
	. = ..()
	chosen_mob.remove_status_effect(/datum/status_effect/corrosion_curse)

/datum/eldritch_knowledge/curse/paralysis
	name = "Проклятие парализации"
	gain_text = "Искази плоть, заставь ее подчиниться."
	desc = "Наложите на жертву проклятие, которое лишит ее возможности ходить на 5 минут. Принесите в жертву нож, лужу крови, пару ног, топор и предмет, к которому жертва прикасалась голыми руками. "
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife,/obj/effect/decal/cleanable/blood,/obj/item/bodypart/l_leg,/obj/item/bodypart/r_leg,/obj/item/hatchet)
	next_knowledge = list(/datum/eldritch_knowledge/mad_mask,/datum/eldritch_knowledge/summon/raw_prophet)
	timer = 5 MINUTES

/datum/eldritch_knowledge/curse/paralysis/curse(mob/living/chosen_mob)
	. = ..()
	ADD_TRAIT(chosen_mob,TRAIT_PARALYSIS_L_LEG,MAGIC_TRAIT)
	ADD_TRAIT(chosen_mob,TRAIT_PARALYSIS_R_LEG,MAGIC_TRAIT)
	chosen_mob.update_mobility()

/datum/eldritch_knowledge/curse/paralysis/uncurse(mob/living/chosen_mob)
	. = ..()
	REMOVE_TRAIT(chosen_mob,TRAIT_PARALYSIS_L_LEG,MAGIC_TRAIT)
	REMOVE_TRAIT(chosen_mob,TRAIT_PARALYSIS_R_LEG,MAGIC_TRAIT)
	chosen_mob.update_mobility()

/datum/eldritch_knowledge/spell/cleave
	name = "Кровавый раскол"
	gain_text = "Сначала я не понимал, что это за орудия войны, но священник посоветовал мне использовать их, несмотря ни на что. Скоро, сказал он, я буду хорошо их знать."
	desc = "Дает заклинание, которое наносит раны и вызывает кровотечение цели, а также в небольшом радиусе вокруг нее."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/cleave
	next_knowledge = list(/datum/eldritch_knowledge/spell/entropic_plume,/datum/eldritch_knowledge/spell/flame_birth)

/datum/eldritch_knowledge/final_eldritch/ash_final
	name = "Ритуал Пепельного Лорда"
	desc = "Ритуал вознесения Пути Пепла. \
		Принесите 3 горящих трупа или хаска к руне трансмутации для начала ритуала. \
		Когда ритуал будет завершен, вы станете Предвестником Пламени, а также получите два навыка. \
		Каскад Огня, который раскаляет воздух вокруг вас, \
		и Клятву Пламени, создающую кольцо огня вокруг вас. \
		Вы также становитесь иммунны к урону от огня, давления, холода и другим эффектам окружающей вас среды."
	gain_text = "Его фонарь обратился в пепел, Ночной Страж сгорел вместе с ним. Но его пламя разгорится вновь, \
		во имя Ночного стража я завершу этот ритуал! Он продолжает наблюдать, и теперь я един с пламенем, \
		УЗРИТЕ ЖЕ МОЁ ВОЗНЕСЕНИЕ, ПЕПЕЛЬНЫЙ ФОНАРЬ ЗАЖЖЕТСЯ ВНОВЬ!"
	required_atoms = list(/mob/living/carbon/human)
	cost = 5
	sacs_needed = 5
	route = PATH_ASH
	var/list/trait_list = list(TRAIT_NOBREATH,TRAIT_RESISTCOLD,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE)

/datum/eldritch_knowledge/final_eldritch/ash_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Бойтесь огня! Князь пепла, [user.real_name] вознёсся! Языки пламени поглотят всё! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'modular_bluemoon/kovac_shitcode/sound/eldritch/ash_lore.ogg')
	user.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big)
	user.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/fire_sworn)
	var/mob/living/carbon/human/H = user
	H.physiology.brute_mod *= 0.5
	H.physiology.burn_mod *= 0.5
	var/datum/antagonist/heretic/ascension = H.mind.has_antag_datum(/datum/antagonist/heretic)
	ascension.ascended = TRUE
	H.client?.give_award(/datum/award/achievement/misc/ash_ascension, H)
	for(var/X in trait_list)
		ADD_TRAIT(user,X,MAGIC_TRAIT)
	return ..()
