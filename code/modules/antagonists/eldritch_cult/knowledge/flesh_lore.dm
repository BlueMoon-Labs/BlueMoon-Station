/datum/eldritch_knowledge/base_flesh
	name = "Принцип Голода"
	desc = "Открывает вам Путь Плоти. \
		Позволяет вам трансмутировать кухонный нож и лужу крови в Кровавый клинок."
	gain_text = "Сотни из нас голодали, но не я... Меня питала моя алчность."
	banned_knowledge = list(/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/final_eldritch/ash_final,/datum/eldritch_knowledge/final_eldritch/rust_final,/datum/eldritch_knowledge/final_eldritch/void_final,/datum/eldritch_knowledge/base_void)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_grasp)
	required_atoms = list(/obj/item/kitchen/knife,/obj/effect/decal/cleanable/blood)
	result_atoms = list(/obj/item/melee/sickly_blade/flesh)
	cost = 0
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_ghoul
	name = "Незавершенный Ритуал"
	desc = "Позволяет произвести ритуал трансмутации мертвого тела и мака для создания Безмолвного Мертвеца. \
		Безмолвный мертвец не способен говорить и имеет 50 очков здоровья, но он может использовать Кровавый клинок. "
	gain_text = "Мною были найдены запретные темные знания, их незаконченные обрывки...пока, незаконченные. Я продолжил двигаться вперед."
	cost = 1
	required_atoms = list(/mob/living/carbon/human,/obj/item/reagent_containers/food/snacks/grown/poppy)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_mark,/datum/eldritch_knowledge/void_cloak,/datum/eldritch_knowledge/ashen_eyes)
	route = PATH_FLESH
	var/max_amt = 2
	var/current_amt = 0
	var/list/ghouls = list()

/datum/eldritch_knowledge/flesh_ghoul/on_finished_recipe(mob/living/user,list/atoms,loc)
	var/mob/living/carbon/human/humie = locate() in atoms
	if(QDELETED(humie) || humie.stat != DEAD)
		return

	if(length(ghouls) >= max_amt)
		return

	if(HAS_TRAIT(humie,TRAIT_HUSK))
		return

	humie.grab_ghost()

	if(!humie.mind || !humie.client)
		var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as a [humie.real_name], a voiceless dead.", ROLE_HERETIC, null, ROLE_HERETIC, 50,humie)
		if(!LAZYLEN(candidates))
			return
		var/mob/dead/observer/C = pick(candidates)
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(humie)]) to replace an AFK player.")
		humie.ghostize(0)
		humie.key = C.key

	ADD_TRAIT(humie,TRAIT_MUTE,MAGIC_TRAIT)
	log_game("[key_name_admin(humie)] has become a voiceless dead, their master is [user.real_name]")
	humie.revive(full_heal = TRUE, admin_revive = TRUE)
	humie.setMaxHealth(75)
	humie.health = 75 // Voiceless dead are much tougher than ghouls
	humie.become_husk()
	humie.faction |= "heretics"

	var/datum/antagonist/heretic_monster/heretic_monster = humie.mind.add_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic_monster.set_owner(master)
	atoms -= humie
	RegisterSignal(humie,COMSIG_MOB_DEATH, PROC_REF(remove_ghoul))
	ghouls += humie

/datum/eldritch_knowledge/flesh_ghoul/proc/remove_ghoul(datum/source)
	var/mob/living/carbon/human/humie = source
	ghouls -= humie
	humie.mind.remove_antag_datum(/datum/antagonist/heretic_monster)
	UnregisterSignal(source,COMSIG_MOB_DEATH)

/datum/eldritch_knowledge/flesh_grasp
	name = "Хватка Плоти"
	desc = "Теперь ваша Хватка Мансуса может создать гуля из трупа с присутствующей в нем душой. \
		Гули имеют только 25 очков здоровья и выглядят в глазах неверных как хаски, но они могут использовать Кровавый клинок."
	gain_text = "Мои новоприобретенные страсти вели меня к новым высотам."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/flesh_ghoul)
	var/ghoul_amt = 4
	var/list/spooky_scaries
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!ishuman(target) || target == user)
		return

	if(iscarbon(target))
		user.reagents.add_reagent(/datum/reagent/eldritch, 5)

	var/mob/living/carbon/human/human_target = target
	var/datum/status_effect/eldritch/eldritch_effect = human_target.has_status_effect(/datum/status_effect/eldritch/rust) || human_target.has_status_effect(/datum/status_effect/eldritch/ash) || human_target.has_status_effect(/datum/status_effect/eldritch/flesh)  || human_target.has_status_effect(/datum/status_effect/eldritch/void)
	if(eldritch_effect)
		. = TRUE
		eldritch_effect.on_effect()
		if(iscarbon(target))
			var/mob/living/carbon/carbon_target = target
			var/obj/item/bodypart/bodypart = pick(carbon_target.bodyparts)
			var/datum/wound/slash/severe/crit_wound = new
			crit_wound.apply_wound(bodypart)

	if(QDELETED(human_target) || human_target.stat != DEAD)
		return

	human_target.grab_ghost()

	if(!human_target.mind || !human_target.client)
		to_chat(user, "<span class='warning'>There is no soul connected to this body...</span>")
		return

	if(HAS_TRAIT(human_target, TRAIT_HUSK))
		to_chat(user, "<span class='warning'>You cannot revive a dead ghoul!</span>")
		return

	if(LAZYLEN(spooky_scaries) >= ghoul_amt)
		to_chat(user, "<span class='warning'>Your patron cannot support more ghouls on this plane!</span>")
		return

	LAZYADD(spooky_scaries, human_target)
	log_game("[key_name_admin(human_target)] has become a ghoul, their master is [user.real_name]")
	//we change it to true only after we know they passed all the checks
	. = TRUE
	RegisterSignal(human_target,COMSIG_MOB_DEATH, PROC_REF(remove_ghoul))
	human_target.revive(full_heal = TRUE, admin_revive = TRUE)
	human_target.setMaxHealth(40)
	human_target.health = 40
	human_target.become_husk()
	human_target.faction |= "heretics"
	var/datum/antagonist/heretic_monster/heretic_monster = human_target.mind.add_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic_monster.set_owner(master)
	return


/datum/eldritch_knowledge/flesh_grasp/proc/remove_ghoul(datum/source)
	var/mob/living/carbon/human/humie = source
	spooky_scaries -= humie
	humie.mind.remove_antag_datum(/datum/antagonist/heretic_monster)
	UnregisterSignal(source, COMSIG_MOB_DEATH)

/datum/eldritch_knowledge/flesh_mark
	name = "Метка Плоти"
	gain_text = "И тогда я узрел их, отмеченных. Они были недостижимы. А крики их наполнены агонией."
	desc = "Ваша Хватка Мансуса теперь накладывает Метку Плоти. Её активация происходит после того, как вы атакуете жертву Кровавым клинком. При активации метка вызывает у носителя обильное кровотечение."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/raw_prophet)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/ash_mark,/datum/eldritch_knowledge/void_mark)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(isliving(target))
		. = TRUE
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/eldritch/flesh)

/datum/eldritch_knowledge/flesh_blade_upgrade
	name = "Иссекающая сталь"
	desc = "Ваш Кровавый клинок теперь вызывает сильное кровотечение при атаке."
	gain_text = "Но Пророк не был одинок. Он привел меня к Маршалу. \
		Ко мне наконец пришло просвещение. И небеса окропили землю кровью."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/rust_blade_upgrade,/datum/eldritch_knowledge/void_blade_upgrade)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_blade_upgrade/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		var/obj/item/bodypart/bodypart = pick(carbon_target.bodyparts)
		var/datum/wound/slash/severe/crit_wound = new
		crit_wound.apply_wound(bodypart)

/datum/eldritch_knowledge/summon/raw_prophet
	name = "Нечестивый Ритуал"
	desc = "Позволяет произвести ритуал трансмутации пары глаз, левой руки и лужи крови для создания Нечестивого Пророка. \
		Нечестивый Пророк видит на большее расстрояние, имеет способность к бестелесному перемещению и имеет возможность смотреть сквозь стены. Помимо всего прочего \
		он может создать телепатическую сеть для общения и ослеплять ваших врагов, но он крайне слаб и легко может быть уничтожен в бою."
	gain_text = "Продолжать путь в одиночестве было невыносимо. И тогда я призвал Пророка, дабы он помог узреть больше. \
		И крики...постоянные крики, они затихли. Его нечестивое присутствие подавляло их. Ничто более не было недостижимым."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes,/obj/item/bodypart/l_arm,/obj/effect/decal/cleanable/blood)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/raw_prophet
	next_knowledge = list(/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/rune_carver,/datum/eldritch_knowledge/curse/paralysis)
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/stalker
	name = "Одинокий Ритуал"
	desc = "Позволяет произвести ритуал трансмутации где хвост, желудок, язык, ручка и лист бумаги используются для создания Преследователя. \
		Преследователи могут становиться нематериальными, испускать ЭМИ импульс, превращаться в небольших существ. Также они весьма сильны в бою."
	gain_text = "Я смешал свою жадность и желания воедино, дабы призвать невиданное доселе сверхестественное существо. \
		И чем сильнее эта масса плоти изменялась, тем больше она узнавала обо мне. Маршал был доволен."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/candle,/obj/item/pen,/obj/item/paper)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/stalker
	next_knowledge = list(/datum/eldritch_knowledge/summon/ashy,/datum/eldritch_knowledge/summon/rusty,/datum/eldritch_knowledge/flesh_blade_upgrade_2)
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/ashy
	name = "Пепельный ритуал"
	gain_text = "Я объединил свой голод с жаждой разрушения. И Ночной Страж знал мое имя."
	desc = "Теперь вы можете вызвать Пепельника, превратив кучку пепла, голову и книгу с помощью круга превращения. Они обладают способностью перемещаться на короткие расстояния и создавать каскад пламени."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/ash,/obj/item/bodypart/head,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/ash_spirit
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/flame_birth)

/datum/eldritch_knowledge/summon/rusty
	name = "Ржавый ритуал"
	gain_text = "Я объединил свой принцип голода со своим стремлением к разложению. И Ржавые холмы назвали мое имя."
	desc = "Теперь вы можете вызвать Ржавого Ходока, преобразовав лужу рвоты, отрубленную голову и книгу с помощью круга превращения. Ржавые ходоки обладают способностью распространять ржавчину и могут стрелять ржавыми разрядами, еще больше разъедая местность."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/vomit,/obj/item/bodypart/head,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/rust_spirit
	next_knowledge = list(/datum/eldritch_knowledge/spell/voidpull,/datum/eldritch_knowledge/spell/entropic_plume)

/datum/eldritch_knowledge/spell/blood_siphon
	name = "Кровавый сифон"
	gain_text = "Независимо от того, кто мы, все равно будем истекать кровью. Вот что сказал мне маршал."
	desc = "Вы получаете заклинание, которое высасывает жизненную силу из ваших врагов, чтобы восстановить свою собственную."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/blood_siphon
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/voidpull)

/datum/eldritch_knowledge/final_eldritch/flesh_final
	name = "Последний Гимн Жреца"
	desc = "Ритуал вознесения Пути Плоти. \
		Принесите 4 трупа к руне трансмутации чтобы начать ритуал. \
		Когда ритуал будет завершён вы получите возможность отринуть вашу человеческую личину \
		дабы превратиться в Повелителя Ночи, крайне могущественное существо. \
		Во время превращения сердца окружающих вас неверных наполнятся страхом и они получат психологическую травму. \
		Находясь в форме Повелителя Ночи вы можете лечиться и становиться сильнее пожирая руки своих жертв. \
		Также теперь вы можете создать в три раза больше Гулей и Безмолвных Мертвецов, \
		кроме того вы можете создать сколько угодно Кровавых Клинков для того, чтобы вооружить их ими."
	gain_text = "Благодаря познаниям Маршала мои силы достигли пика. Трон ждет своего обладателя. \
		Услышьте же меня, жители мира сего, время пришло! Маршал ведет мою армию! \
		Реальность покорится ПОВЕЛИТЕЛЮ НОЧИ или будет уничтожена! УЗРИТЕ МОЁ ВОЗВЫШЕНИЕ!"
	required_atoms = list(/mob/living/carbon/human)
	cost = 5
	sacs_needed = 5
	route = PATH_FLESH

/datum/eldritch_knowledge/final_eldritch/flesh_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Вихрь крутится в вечном танце. Реальность выворачивается наизнанку. ПОВЕЛИТЕЛЬ, [user.real_name] вознёсся! Бойтесь длани господня! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'modular_bluemoon/kovac_shitcode/sound/eldritch/flesh_lore.ogg')
	user.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/shed_human_form)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/lord_of_arms = user
	lord_of_arms.physiology.brute_mod *= 0.5
	lord_of_arms.physiology.burn_mod *= 0.5
	lord_of_arms.client?.give_award(/datum/award/achievement/misc/flesh_ascension, lord_of_arms)
	var/datum/antagonist/heretic/heretic_datum = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/flesh_grasp/grasp_ghoul = heretic_datum.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	grasp_ghoul.ghoul_amt *= 3
	var/datum/eldritch_knowledge/flesh_ghoul/better_ghoul = heretic_datum.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	better_ghoul.max_amt *= 3


/datum/eldritch_knowledge/flesh_blade_upgrade_2
	name = "Воспоминание"
	gain_text = "Боль - это не то, что легко забывается."
	desc = "Ваш клинок помнит больше, и помнит, как легко ломались кости, точно так же, как и его плоть, гарантируя вывих или перелом костей."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/spell/touch_of_madness)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_blade_upgrade_2/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		var/obj/item/bodypart/bodypart = pick(carbon_target.bodyparts)
		var/datum/wound/blunt/moderate/moderate_wound = new
		moderate_wound.apply_wound(bodypart)

/datum/eldritch_knowledge/spell/touch_of_madness
	name = "Касание безумия"
	gain_text = "Невежественный разум, обитающий в их слабых телах, рухнет, когда они признают - вольно или невольно - истину."
	desc = "Навязывая своим врагам знания Мансуса, я могу показать им то, что свело бы с ума любого нормального человека."
	cost = 2
	sacs_needed = 3
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	next_knowledge = list(/datum/eldritch_knowledge/final_eldritch/flesh_final)
	route = PATH_FLESH

/datum/eldritch_knowledge/spell/touch_of_madness/on_gain(mob/user)
	. = ..()
	priority_announce("Внимание, [station_name()]. [user.real_name] излучает пространственную нестабильность, в связи с которой смрад гнилой плоти разносится по округе... надвигается нечто поистине мерзкое!", sound = 'sound/misc/notice1.ogg')
