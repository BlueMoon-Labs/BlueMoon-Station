/datum/team/ghost_role
	name = "Ghost Role"
	show_roundend_report = FALSE
	var/list/players_spawned = new

/datum/antagonist/ghost_role
	name = "\improper Misc Ghost Role"
	job_rank = ROLE_GHOSTROLE
	show_in_antagpanel = FALSE
	soft_antag = TRUE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = TRUE
	antagpanel_category = "Ghost Role"
	var/datum/team/ghost_role/ghost_team

/datum/antagonist/ghost_role/create_team(datum/team/team)
	if(team)
		ghost_team = team
		objectives |= ghost_team.objectives
	else
		ghost_team = new

/datum/antagonist/ghost_role/get_team()
	return ghost_team

//Objects that spawn ghosts in as a certain role when they click on it, i.e. away mission bartenders.
#define spawnOverride TRUE
//Preserved terrarium/seed vault: Spawns in seed vault structures in lavaland. Ghosts become plantpeople and are advised to begin growing plants in the room near them.
/obj/effect/mob_spawn/human/seed_vault
	name = "preserved terrarium"
	desc = "An ancient machine that seems to be used for storing plant matter. The glass is obstructed by a mat of vines."
	mob_name = "a lifebringer"
	job_description = "Lifebringer"
	icon = 'icons/obj/lavaland/spawners.dmi'
	icon_state = "terrarium"
	density = TRUE
	roundstart = FALSE
	death = FALSE
	mob_species = /datum/species/pod
	short_desc = "You are a sentient ecosystem, an example of the mastery over life that your creators possessed."
	flavour_text = "Your masters, benevolent as they were, created uncounted seed vaults and spread them across \
	the universe to every planet they could chart. You are in one such seed vault. \
	Your goal is to cultivate and spread life wherever it will go while waiting for contact from your creators. \
	Estimated time of last contact: Deployment, 5000 millennia ago."
	assignedrole = "Lifebringer"
	category = "offstation"

/obj/effect/mob_spawn/human/seed_vault/Destroy()
	new/obj/structure/fluff/empty_terrarium(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/seed_vault/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn,TRAIT_EXEMPT_HEALTH_EVENTS,GHOSTROLE_TRAIT)
	var/plant_name = pick("Tomato", "Potato", "Broccoli", "Carrot", "Ambrosia", "Pumpkin", "Ivy", "Kudzu", "Banana", "Moss", "Flower", "Bloom", "Root", "Bark", "Glowshroom", "Petal", "Leaf", \
	"Venus", "Sprout","Cocoa", "Strawberry", "Citrus", "Oak", "Cactus", "Pepper", "Juniper")
	new_spawn.real_name = plant_name //why this works when moving it from one function to another is beyond me
	new_spawn.underwear = "Nude" //You're a plant, partner
	new_spawn.undershirt = "Nude" //changing underwear/shirt/socks doesn't seem to function correctly right now because of some bug elsewhere?
	new_spawn.socks = "Nude"
	new_spawn.update_body(TRUE)
	new_spawn.set_active_language(/datum/language/sylvan)

//Ash walker eggs: Spawns in ash walker dens in lavaland. Ghosts become unbreathing lizards that worship the Necropolis and are advised to retrieve corpses to create more ash walkers.

/obj/structure/ash_walker_eggshell
	name = "ash walker egg"
	desc = "A man-sized yellow egg, spawned from some unfathomable creature. A humanoid silhouette lurks within. The egg shell looks resistant to temperature but otherwise rather brittle."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "large_egg"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | FREEZE_PROOF
	max_integrity = 80
	var/obj/effect/mob_spawn/human/ash_walker/egg

/obj/structure/ash_walker_eggshell/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0) //lifted from xeno eggs
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(loc, 'sound/effects/attackblob.ogg', 100, TRUE)
			else
				playsound(src, 'sound/weapons/tap.ogg', 50, TRUE)
		if(BURN)
			if(damage_amount)
				playsound(loc, 'sound/items/welder.ogg', 100, TRUE)

/obj/structure/ash_walker_eggshell/attack_ghost(mob/user) //Pass on ghost clicks to the mob spawner
	if(egg)
		egg.attack_ghost(user)
	. = ..()

/obj/structure/ash_walker_eggshell/Destroy()
	if(!egg)
		return ..()
	var/mob/living/carbon/human/yolk = new /mob/living/carbon/human/(get_turf(src))
	yolk.fully_replace_character_name(null,random_unique_lizard_name(gender))
	yolk.set_species(/datum/species/lizard/ashwalker)
	yolk.underwear = "Nude"
	//yolk.equipOutfit(/datum/outfit/ashwalker)//this is an authentic mess we're making
	yolk.update_body()
	yolk.gib()
	QDEL_NULL(egg)
	return ..()

/obj/effect/mob_spawn/human/ash_walker
	name = "ash walker egg"
	desc = "A man-sized yellow egg, spawned from some unfathomable creature. A humanoid silhouette lurks within."
	mob_name = "an ash walker"
	job_description = "Ashwalker"
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "large_egg"
	mob_species = /datum/species/lizard/ashwalker
	roundstart = FALSE
	death = FALSE
	anchored = FALSE
	move_resist = MOVE_FORCE_NORMAL
	density = FALSE
	loadout_enabled = FALSE
	can_load_appearance = TRUE
	short_desc = "Вы Пеплоход."
	flavour_text = "Ваше племя поклоняется матери Некрополю, как вашей Спасительнице и Наставнице. Священные стены дворца Некрополя \
	дали вашему Тендрилу и вашему Роду защиту. Испокон веков, ваша священная обитель дарует вам Дар Перерождения, из цикла в цикл за \
	жертвоприношения матери Некрополю, ради продолжения Великой Охоты. Однако не так давно на ваши земли вторглось Чужеродное Племя. \
	Несмотря на ваше кровное родство в поклонении Великой Матери, не дайте иноземцам осквернить ваше святилище их изуверскими традициями. \
	Сверх этого, с небесных крепостей из Холодного Камня, на ваши земли спустились скитальцы с далёких Звёзд. Их рудокопы накладывают \
	священные пальцы на Некрополь, свои грязные лапы. Не дайте им украсть дары великой матери и лишить вас пищи. Охота должна быть \
	здравой, цикл должен продолжаться, грядущие поколения должны жить!"
	assignedrole = "Ash Walker"
	var/datum/team/ashwalkers/team
	var/obj/structure/ash_walker_eggshell/eggshell
	category = "offstation"

/obj/effect/mob_spawn/human/ash_walker/Destroy()
	eggshell = null
	return ..()

/obj/effect/mob_spawn/human/ash_walker/allow_spawn(mob/user, silent = FALSE)
	if(!(user.ckey in team.players_spawned) || spawnOverride)//one per person unless you get a bonus spawn
		return TRUE
	to_chat(user, span_warning("<b>You have exhausted your usefulness to the Necropolis</b>."))
	return FALSE

/obj/effect/mob_spawn/human/ash_walker/special(mob/living/new_spawn)
	// new_spawn.real_name = random_unique_lizard_name(gender)
	if(is_mining_level(new_spawn.z))
		to_chat(new_spawn, "<b>Drag the corpses of beasts to your nest. It will absorb them to create more of your kind. Glory to the Necropolis!</b>")
		to_chat(new_spawn, "<b>You can expand the weather proof area provided by your shelters by using the 'New Area' key near the bottom right of your HUD.</b>")
		to_chat(new_spawn, "<b>Dragging injured ashwalkers to the tentacle or using the sleep verb next to it youself causes the body to remade whole after a short delay!</b>")
	else
		to_chat(new_spawn, "<span class='userdanger'>You have been born outside of your natural home! Whether you decide to return home, or make due with your new home is your own decision.</span>")

	new_spawn.add_quirk(/datum/quirk/body_morpher, TRUE)

//Ash walkers on birth understand how to make bone bows, bone arrows and ashen arrows

	if(ishuman(new_spawn))
		var/mob/living/carbon/human/H = new_spawn
		H.underwear = "Nude"
		H.undershirt = "Nude"
		H.socks = "Nude"
		H.update_body()
		if(team)
			new_spawn.mind.add_antag_datum(/datum/antagonist/ashwalker, team)
			team.players_spawned += (new_spawn.ckey)
		eggshell.egg = null
		QDEL_NULL(eggshell)

/obj/effect/mob_spawn/human/ash_walker/Initialize(mapload, datum/team/ashwalkers/ashteam)
	. = ..()
	var/area/A = get_area(src)
	team = ashteam
	eggshell = new /obj/structure/ash_walker_eggshell(get_turf(loc))
	eggshell.egg = src
	src.forceMove(eggshell)
	if(A)
		notify_ghosts("An ash walker egg is ready to hatch in \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE, ignore_key = POLL_IGNORE_ASHWALKER, ignore_dnr_observers = TRUE)

/datum/outfit/ashwalker
	name ="Ashwalker"
	head = /obj/item/clothing/head/helmet/gladiator
	uniform = /obj/item/clothing/under/costume/gladiator/ash_walker


//Timeless prisons: Spawns in Wish Granter prisons in lavaland. Ghosts become age-old users of the Wish Granter and are advised to seek repentance for their past.
/obj/effect/mob_spawn/human/exile
	name = "timeless prison"
	desc = "Although this stasis pod looks medicinal, it seems as though it's meant to preserve something for a very long time."
	mob_name = "a penitent exile"
	job_description = "Exiled Prisoner"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	death = FALSE
	mob_species = /datum/species/shadow
	short_desc = "You are cursed."
	flavour_text = "Years ago, you sacrificed the lives of your trusted friends and the humanity of yourself to reach the Wish Granter. Though you \
	did so, it has come at a cost: your very body rejects the light, dooming you to wander endlessly in this horrible wasteland."
	assignedrole = "Exile"

/obj/effect/mob_spawn/human/exile/Destroy()
	new/obj/structure/fluff/empty_sleeper(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/exile/special(mob/living/new_spawn)
	new_spawn.real_name = "Wish Granter's Victim ([rand(1,999)])"
	var/wish = rand(1,4)
	switch(wish)
		if(1)
			to_chat(new_spawn, "<b>You wished to kill, and kill you did. You've lost track of how many, but the spark of excitement that murder once held has winked out. You feel only regret.</b>")
		if(2)
			to_chat(new_spawn, "<b>You wished for unending wealth, but no amount of money was worth this existence. Maybe charity might redeem your soul?</b>")
		if(3)
			to_chat(new_spawn, "<b>You wished for power. Little good it did you, cast out of the light. You are the [gender == MALE ? "king" : "queen"] of a hell that holds no subjects. You feel only remorse.</b>")
		if(4)
			to_chat(new_spawn, "<b>You wished for immortality, even as your friends lay dying behind you. No matter how many times you cast yourself into the lava, you awaken in this room again within a few days. There is no escape.</b>")

//Golem shells: Spawns in Free Golem ships in lavaland. Ghosts become mineral golems and are advised to spread personal freedom.
/obj/effect/mob_spawn/human/golem
	name = "inert free golem shell"
	desc = "A humanoid shape, empty, lifeless, and full of potential."
	mob_name = "a free golem"
	job_description = "Free Golem"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "construct"
	mob_species = /datum/species/golem
	roundstart = FALSE
	death = FALSE
	anchored = FALSE
	move_resist = MOVE_FORCE_NORMAL
	density = FALSE
	var/has_owner = FALSE
	var/can_transfer = TRUE //if golems can switch bodies to this new shell
	var/mob/living/owner = null //golem's owner if it has one
	short_desc = "Вы - свободный голем. Ваша семья поклоняется Освободителю."
	flavour_text = "В своей бесконечной и божественной мудрости Освободитель освободил ваш клан, чтобы \
	путешествовать по звездам с одним единственным заявлением: \ 'Да, делай что хочешь.'\ Хотя вы связаны с тем, кто вас создал, в вашем обществе принято повторять эти же слова новорожденным \
	големам, чтобы ни один голем никогда не был вынужден служить снова."
	important_info = "Вы не антагонист."
	category = "offstation"

/obj/effect/mob_spawn/human/golem/Initialize(mapload, datum/species/golem/species = null, mob/creator = null)
	if(species) //spawners list uses object name to register so this goes before ..()
		name += " ([initial(species.prefix)])"
		mob_species = species
	. = ..()
	var/area/A = get_area(src)
	if(!mapload && A)
		notify_ghosts("\A [initial(species.prefix)] golem shell has been completed in \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE, ignore_key = POLL_IGNORE_GOLEM, ignore_dnr_observers = TRUE)
	if(has_owner && creator)
		short_desc = "You are a golem."
		flavour_text = "You move slowly, but are highly resistant to heat and cold as well as blunt trauma. You are unable to wear clothes, but can still use most tools."
		important_info = "Serve [creator], and assist [creator.ru_na()] in completing [creator.ru_ego()] goals at any cost."
		owner = creator

/obj/effect/mob_spawn/human/golem/special(mob/living/new_spawn, name)
	. = ..()
	var/datum/species/golem/X = mob_species
	to_chat(new_spawn, "[initial(X.info_text)]")
	if(!owner)
		to_chat(new_spawn, "Build golem shells in the autolathe, and feed refined mineral sheets to the shells to bring them to life! You are generally a peaceful group unless provoked.")
	else
		new_spawn.mind.store_memory("<b>Serve [owner.real_name], your creator.</b>")
		new_spawn.mind.enslave_mind_to_creator(owner)
		log_game("[key_name(new_spawn)] possessed a golem shell enslaved to [key_name(owner)].")
		log_admin("[key_name(new_spawn)] possessed a golem shell enslaved to [key_name(owner)].")
	if(ishuman(new_spawn))
		var/mob/living/carbon/human/H = new_spawn
		if(has_owner)
			var/datum/species/golem/G = H.dna.species
			G.owner = owner
		H.set_cloned_appearance()
		if(!name)
			if(has_owner)
				H.real_name = "[initial(X.prefix)] Golem ([rand(1,999)])"
			else
				H.real_name = H.dna.species.random_name()
		else
			H.real_name = name
	if(has_owner)
		new_spawn.mind.assigned_role = "Servant Golem"
	else
		new_spawn.mind.assigned_role = "Free Golem"

/obj/effect/mob_spawn/human/golem/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(isgolem(user) && can_transfer)
		var/transfer_choice = alert("Transfer your soul to [src]? (Warning, your old body will die!)",,"Да","Нет")
		if(transfer_choice != "Да" || QDELETED(src) || uses <= 0 || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERY, NO_TK))
			return
		log_game("[key_name(user)] golem-swapped into [src]")
		user.visible_message("<span class='notice'>A faint light leaves [user], moving to [src] and animating it!</span>","<span class='notice'>You leave your old body behind, and transfer into [src]!</span>")
		show_flavour = FALSE
		create(ckey = user.ckey, name = user.real_name)
		user.death()
		return

/obj/effect/mob_spawn/human/golem/servant
	has_owner = TRUE
	name = "inert servant golem shell"
	job_description = "Servant Golem"


/obj/effect/mob_spawn/human/golem/adamantine
	name = "dust-caked free golem shell"
	desc = "A humanoid shape, empty, lifeless, and full of potential."
	mob_name = "a free golem"
	can_transfer = FALSE
	mob_species = /datum/species/golem/adamantine

//Malfunctioning cryostasis sleepers: Spawns in makeshift shelters in lavaland. Ghosts become hermits with knowledge of how they got to where they are now.
/obj/effect/mob_spawn/human/hermit
	name = "malfunctioning cryostasis sleeper"
	desc = "A humming sleeper with a silhouetted occupant inside. Its stasis function is broken and it's likely being used as a bed."
	mob_name = "a stranded hermit"
	job_description = "Lavaland Hermit"
	icon = 'icons/obj/lavaland/spawners.dmi'
	icon_state = "cryostasis_sleeper"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "Вы застряли в этом Безбожном Месте."
	flavour_text = "Каждый день вы еле-еле сводите концы с концами, \
	враждебными существами и Пепельными Дрейками, слетающими с безоблачного неба. Все, что вы можете пожелать, это почувствовать мягкую траву между пальцами ног и \
	свежий воздух Земли. Эти мысли развеиваются очередным воспоминанием о том, как вы сюда попали..."
	assignedrole = "Hermit"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	antagonist_type = /datum/antagonist/ghost_role/hermit
	category = "offstation"

/obj/effect/mob_spawn/human/hermit/Initialize(mapload)
	. = ..()
	var/arrpee = rand(1,4)
	switch(arrpee)
		if(1)
			flavour_text += "вы были помощником [pick("Оружейника", "Корабельщика", "Финансового Менеджера")] на небольшой торговой станции в нескольких секторах отсюда. Рейдеры напали на ваше судно и в спасательном отсеке оставалась \
			всего только одна капсула. Вы отбросили или отвлекли, или вас пропустили и в итоге благодаря спасательной капсуле вы... спаслись? Так или иначе, вы не забудете ту кучу испуганных лиц в момент вашего отлёта."
			outfit.uniform = /obj/item/clothing/under/misc/assistantformal
			outfit.shoes = /obj/item/clothing/shoes/sneakers/black
			outfit.back = /obj/item/storage/backpack
		if(2)
			flavour_text += "вы изгнанник из кооператива 'Тигр'. Их технологический фанатизм заставил вас усомниться в силе и убеждениях Экзолитиков и они сочли вас \
			еретиком, и подвергли вас многочасовым ужасным пыткам. Вы были в нескольких часах от казни, когда ваш высокопоставленный друг в Кооперативе сумел достать для вас капсулу, \
			зашифровал координаты места назначения и запустил ее. Вы очнулись от стазиса, когда приземлились... и с тех пор выживаете - с трудом, но выживаете."
			outfit.uniform = /obj/item/clothing/under/rank/prisoner
			outfit.shoes = /obj/item/clothing/shoes/sneakers/orange
			outfit.back = /obj/item/storage/backpack
		if(3)
			flavour_text += "Вы были врачом на одной из космических станций Nanotrasen, но вы оставили позади тиранию этой проклятой корпорации и все то, за что она стояла. Из метафорического ада \
			в буквальный - вы обнаружили, что вам все же не хватает чистого воздуха и теплых полов из сего того, что вы оставили... но вы все равно предпочтете быть здесь, а не там."
			outfit.uniform = /obj/item/clothing/under/rank/medical/doctor
			outfit.suit = /obj/item/clothing/suit/toggle/labcoat
			outfit.back = /obj/item/storage/backpack/medic
			outfit.shoes = /obj/item/clothing/shoes/sneakers/black
		if(4)
			flavour_text += "Ваши друзья всегда подшучивали над вами за то, что вы 'Не Играете с Полной Колодой', как они так доброжелательно выражались. Похоже, они были правы, когда вы, находясь на экскурсии \
			по одному из самых современных исследовательских комплексов Nanotrasen, оказались в одной из спасательных капсул в одиночестве и увидели красную кнопку. Она была большой и блестящей, и это привлекло ваше внимание. Вы нажали на неё \
			и после ужасающего, и быстрого путешествия в течение нескольких дней вы оказались здесь. С тех пор у вас было время поумнеть и вы думаете, что ваши старые друзья сейчас бы не смеялись."
			outfit.uniform = /obj/item/clothing/under/color/grey/glorf
			outfit.shoes = /obj/item/clothing/shoes/sneakers/black
			outfit.back = /obj/item/storage/backpack

/obj/effect/mob_spawn/human/hermit/Destroy()
	new/obj/structure/fluff/empty_cryostasis_sleeper(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/hermit/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn,TRAIT_EXEMPT_HEALTH_EVENTS,GHOSTROLE_TRAIT)

//Broken rejuvenation pod: Spawns in animal hospitals in lavaland. Ghosts become disoriented interns and are advised to search for help.
/obj/effect/mob_spawn/human/doctor/alive/lavaland
	name = "Broken Rejuvenation Pod"
	desc = "A small sleeper typically used to instantly restore minor wounds. This one seems broken, and its occupant is comatose."
	job_description = "Lavaland Veterinarian"
	mob_name = "a translocated vet"
	short_desc = "Вы - врач-животновод, только что проснувшийся в Лаваланде."
	flavour_text = "Что...? Где вы? Где остальные? Это все еще больница для животных - вы должны знать, вы были здесь интерном в течение нескольких недель - но \
	вы видите, что очутились где-то в неизвестном месте прямо сейчас. Так где же \
	все? Куда они делись? Что случилось с больницей? И этот запах дыма? Вам нужно найти кого-нибудь еще. Может быть, они думают, что все ушли. Одна из кошек поцарапала тебя всего несколько минут назад. Поэтому вы и были в капсуле - чтобы залечить царапину. Струпья еще свежие..."
	important_info = "Вы не антагонист."
	assignedrole = "Translocated Vet"
	can_load_appearance = TRUE
	category = "offstation"

/obj/effect/mob_spawn/human/doctor/alive/lavaland/Destroy()
	var/obj/structure/fluff/empty_sleeper/S = new(drop_location())
	S.setDir(dir)
	return ..()

//Prisoner containment sleeper: Spawns in crashed prison ships in lavaland. Ghosts become escaped prisoners and are advised to find a way out of the mess they've gotten themselves into.
/obj/effect/mob_spawn/human/prisoner_transport
	name = "prisoner containment sleeper"
	desc = "A sleeper designed to put its occupant into a deep coma, unbreakable until the sleeper turns off. This one's glass is cracked and you can see a pale, sleeping face staring out."
	mob_name = "an escaped prisoner"
	job_description = "Escaped Prisoner"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	outfit = /datum/outfit/lavalandprisoner
	roundstart = FALSE
	death = FALSE
	short_desc = "You're a prisoner, sentenced to hard work in one of Nanotrasen's labor camps, but it seems as \
	though fate has other plans for you."
	flavour_text = "Good. It seems as though your ship crashed. You remember that you were convicted of "
	assignedrole = "Escaped Prisoner"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/prisoner_transport/special(mob/living/L)
	. = ..()
	L.real_name = "NTP #LL-0[rand(111,999)]" //Nanotrasen Prisoner #Lavaland-(numbers)
	L.name = L.real_name

/obj/effect/mob_spawn/human/prisoner_transport/Initialize(mapload)
	. = ..()
	var/list/crimes = list("murder", "larceny", "embezzlement", "unionization", "dereliction of duty", "kidnapping", "gross incompetence", "grand theft", "collaboration with the Syndicate", \
	"worship of a forbidden deity", "interspecies relations", "mutiny")
	flavour_text += "[pick(crimes)]. but regardless of that, it seems like your crime doesn't matter now. You don't know where you are, but you know that it's out to kill you, and you're not going \
	to lose this opportunity. Find a way to get out of this mess and back to where you rightfully belong - your [pick("house", "apartment", "spaceship", "station")]."

/datum/outfit/lavalandprisoner
	name = "Lavaland Prisoner"
	uniform = /obj/item/clothing/under/rank/prisoner
	mask = /obj/item/clothing/mask/breath
	shoes = /obj/item/clothing/shoes/sneakers/orange
	r_pocket = /obj/item/tank/internals/emergency_oxygen


/obj/effect/mob_spawn/human/prisoner_transport/Destroy()
	new/obj/structure/fluff/empty_sleeper/syndicate(get_turf(src))
	return ..()

//Space Hotel Staff
/obj/effect/mob_spawn/human/hotel_staff //not free antag u little shits
	name = "staff sleeper"
	desc = "A sleeper designed for long-term stasis between guest visits."
	mob_name = "hotel staff member"
	job_description = "Hotel Staff"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	death = FALSE
	roundstart = FALSE
	random = TRUE
	outfit = /datum/outfit/hotelstaff
	short_desc = "Вы - член обслуживающего персонала космического отеля."
	flavour_text = "Вы нанялись в качестве персонала общего профиля для уборки, готовки, обслуживания гостей и всего, что прикажет менеджер на время пребывания на борту космического отеля. Ни в коем случае не грубите, не хамите и не ругайтесь с посетителями. Помните, что в вашем случае, клиент всегда прав."
	important_info = "Персоналу отеля запрещается покидать его (кроме неординарных случаев или установки телепада)."
	assignedrole = "Hotel Staff"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	antagonist_type = /datum/antagonist/ghost_role/space_hotel
	category = "offstation"

/datum/outfit/hotelstaff
	name = "Hotel Staff"
	uniform = /obj/item/clothing/under/suit/red
	shoes = /obj/item/clothing/shoes/laceup
	head = /obj/item/clothing/head/hotel
	r_pocket = /obj/item/radio/off
	back = /obj/item/storage/backpack
	implants = list(/obj/item/implant/mindshield)

/obj/effect/mob_spawn/human/hotel_staff/security
	name = "hotel security sleeper"
	mob_name = "hotel security member"
	job_description = "Hotel Security"
	outfit = /datum/outfit/hotelstaff/security
	short_desc = "Вы - охранник космического отеля."
	flavour_text = "Вы были назначены в этот отель, чтобы защищать интересы компании Nanotrasen, недавно выкупившей его. Ведите себя вежливо, не размахивайте оружием и бронёй, не грубите посетителям - в первую очередь, вы не должны мешать наслаждаться пребыванием и отпугивать адекватных клиентов."
	important_info = "Персоналу отеля запрещается покидать его (кроме неординарных случаев или для установки телепада). Не ведите себя как СБ со станции - вы обычный гражданский и не обучены для борьбы с террористами, предателями, аномалиями и другими неординарными сущностями."

/datum/outfit/hotelstaff/security
	name = "Hotel Secuirty"
	uniform = /obj/item/clothing/under/rank/security/officer/blueshirt
	shoes = /obj/item/clothing/shoes/jackboots
	suit = /obj/item/clothing/suit/armor/vest/blueshirt
	head = /obj/item/clothing/head/helmet/blueshirt
	back = /obj/item/storage/backpack/security
	belt = /obj/item/storage/belt/security/full

/obj/effect/mob_spawn/human/hotel_staff/Destroy()
	new/obj/structure/fluff/empty_sleeper/syndicate(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/hotel_staff/special(mob/living/carbon/human/new_spawn)
	. = ..()
	ADD_TRAIT(new_spawn,TRAIT_EXEMPT_HEALTH_EVENTS,GHOSTROLE_TRAIT)

/obj/effect/mob_spawn/human/demonic_friend
	name = "Essence of friendship"
	desc = "Oh boy! Oh boy! A friend!"
	mob_name = "Demonic friend"
	job_description = "Demonic Friend"
	icon = 'icons/obj/cardboard_cutout.dmi'
	icon_state = "cutout_basic"
	outfit = /datum/outfit/demonic_friend
	death = FALSE
	roundstart = FALSE
	random = TRUE
	id_job = "SuperFriend"
	id_access = "assistant"
	var/obj/effect/proc_holder/spell/targeted/summon_friend/spell
	var/datum/mind/owner
	assignedrole = "SuperFriend"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/demonic_friend/Initialize(mapload, datum/mind/owner_mind, obj/effect/proc_holder/spell/targeted/summon_friend/summoning_spell)
	. = ..()
	if(!owner_mind)
		return
	owner = owner_mind
	flavour_text = "You have been given a reprieve from your eternity of torment, to be [owner.name]'s friend for [owner.ru_ego()] short mortal coil."
	important_info = "Be aware that if you do not live up to [owner.name]'s expectations, they can send you back to hell with a single thought. [owner.name]'s death will also return you to hell."
	var/area/A = get_area(src)
	if(!mapload && A)
		notify_ghosts("\A friendship shell has been completed in \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE, ignore_dnr_observers = TRUE)
	objectives = "Be [owner.name]'s friend, and keep [owner.name] alive, so you don't get sent back to hell."
	spell = summoning_spell


/obj/effect/mob_spawn/human/demonic_friend/special(mob/living/L)
	. = ..()
	if(!QDELETED(owner.current) && owner.current.stat != DEAD)
		L.real_name = "[owner.name]'s best friend"
		L.name = L.real_name
		soullink(/datum/soullink/oneway, owner.current, L)
		spell.friend = L
		spell.charge_counter = spell.charge_max
		L.mind.hasSoul = FALSE
		var/mob/living/carbon/human/H = L
		var/obj/item/worn = H.wear_id
		var/obj/item/card/id/id = worn.GetID()
		id.registered_name = L.real_name
		id.update_label()
	else
		to_chat(L, "<span class='userdanger'>Your owner is already dead!  You will soon perish.</span>")
		addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, dust), 150)) //Give em a few seconds as a mercy.

/datum/outfit/demonic_friend
	name = "Demonic Friend"
	uniform = /obj/item/clothing/under/misc/assistantformal
	shoes = /obj/item/clothing/shoes/laceup
	r_pocket = /obj/item/radio/off
	back = /obj/item/storage/backpack
	implants = list(/obj/item/implant/mindshield) //No revolutionaries, he's MY friend.
	id = /obj/item/card/id

/obj/effect/mob_spawn/human/syndicate
	name = "Syndicate Operative"
	roundstart = FALSE
	death = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	outfit = /datum/outfit/syndicate_empty
	assignedrole = "Space Syndicate"	//I know this is really dumb, but Syndicate operative is nuke ops
	can_load_appearance = TRUE
	category = "syndicate"

/obj/effect/mob_spawn/human/solfed
	name = "Solar Federation Marine"
	roundstart = FALSE
	death = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	outfit = /datum/outfit/ert/sol_soldier
	assignedrole = "Solar Federation Operative"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	category = "sol"

/obj/effect/mob_spawn/human/solfed/demoman
	name = "Solar Federation Support"
	outfit = /datum/outfit/ert/sol_soldier_support

/obj/effect/mob_spawn/human/solfed/field_officer
	name = "Solar Federation Field Officer"
	outfit = /datum/outfit/ert/sol_soldier_leader

/obj/effect/mob_spawn/human/solfed/diplomacy
	name = "Solar Federation Diplomacy Worker"
	short_desc = "Вы - дипломат Солнечной Федерации."
	flavour_text = "Вы - дипломат, который должен обеспечить мирное сосуществование с другими расами. Вы - не боец, но вы должны быть готовы защищать себя и своих коллег."
	important_info = "Защитите корабль и Адмирала ценой своей жизни."
	outfit = /datum/outfit/sol_diplomacy

/obj/effect/mob_spawn/human/solfed/diplomacy/secret_service
	name = "Solar Federation Secret Service"
	short_desc = "Вы - член Секретной Службы Солнечной Федерации."
	flavour_text = "Вы - дипломат, который должен обеспечить мирное сосуществование с другими расами. Вы - боец, вы должны быть готовы защищать себя и своих коллег."
	outfit = /datum/outfit/sol_diplomacy/secret_service

/obj/effect/mob_spawn/human/solfed/diplomacy/slut
	name = "Solar Federation Secretary (SLUT)"
	outfit = /datum/outfit/sol_diplomacy/slut

/obj/effect/mob_spawn/human/solfed/diplomacy/admiral
	name = "Solar Federation Battle Admiral"
	short_desc = "Вы - Адмирал Солнечной Федерации."
	flavour_text = "Вы - Адмирал. Вы - лидер экипажа и ответственный за его безопасность. Вам нужно найти способ обеспечить корабль энергией."
	important_info = "Защитите корабль и секретные документы ценой своей жизни."
	outfit = /datum/outfit/sol_diplomacy/consul/admiral

/datum/outfit/syndicate_empty
	name = "Syndicate Operative Empty"
	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/syndicate/alt
	back = /obj/item/storage/backpack
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/deathrattle/centcom, /obj/item/implant/explosive, /obj/item/implant/mindshield)
	id = /obj/item/card/id/syndicate

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/syndicate_empty/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.faction |= ROLE_SYNDICATE

	var/obj/item/implant/mindshield/L = new //Here you go Deuryn
	L.implant(H, null, 1)

/obj/effect/mob_spawn/human/syndicate/battlecruiser
	name = "Syndicate Battlecruiser Ship Operative"
	short_desc = "You are a crewmember aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to follow your captain's orders, maintain the ship, and keep the engine running. If you are not familiar with how the supermatter engine functions: do not attempt to start it."
	important_info = "The armory is not a candy store, and your role is not to assault the station directly, leave that work to the assault operatives."
	outfit = /datum/outfit/syndicate_empty/battlecruiser
	can_load_appearance = TRUE

/datum/outfit/syndicate_empty/battlecruiser
	name = "Syndicate Battlecruiser Ship Operative"
	l_pocket = /obj/item/gun/ballistic/automatic/pistol
	r_pocket = /obj/item/kitchen/knife/combat/survival
	belt = /obj/item/storage/belt/military/assault
	r_hand = /obj/item/syndicate_uplink_high

/obj/effect/mob_spawn/human/syndicate/battlecruiser/assault
	short_desc = "You are an assault operative aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to follow your captain's orders, keep intruders out of the ship, and assault Space Station 13. There is an armory, multiple assault ships, and beam cannons to attack the station with."
	important_info = "Work as a team with your fellow operatives and work out a plan of attack. If you are overwhelmed, escape back to your ship!"
	outfit = /datum/outfit/syndicate_empty/battlecruiser/assault

/datum/outfit/syndicate_empty/battlecruiser/assault
	name = "Syndicate Battlecruiser Assault Operative"
	uniform = /obj/item/clothing/under/syndicate/combat
	l_pocket = /obj/item/ammo_box/magazine/m10mm
	r_pocket = /obj/item/kitchen/knife/combat/survival
	belt = /obj/item/storage/belt/military
	suit = /obj/item/clothing/suit/armor/vest
	suit_store = /obj/item/gun/ballistic/automatic/pistol
	back = /obj/item/storage/backpack/security
	mask = /obj/item/clothing/mask/gas/syndicate
	l_hand = /obj/item/melee/transforming/energy/sword/saber/red

/obj/effect/mob_spawn/human/syndicate/battlecruiser/captain
	name = "Syndicate Battlecruiser Captain"
	short_desc = "You are the captain aboard the syndicate flagship: the SBC Starfury."
	flavour_text = "Your job is to oversee your crew, defend the ship, and destroy Space Station 13. The ship has an armory, multiple ships, beam cannons, and multiple crewmembers to accomplish this goal."
	important_info = "As the captain, this whole operation falls on your shoulders. You do not need to nuke the station, causing sufficient damage and preventing your ship from being destroyed will be enough."
	outfit = /datum/outfit/syndicate_empty/battlecruiser/assault/captain
	id_access_list = list(150,151)
	can_load_appearance = TRUE

/datum/outfit/syndicate_empty/battlecruiser/assault/captain
	name = "Syndicate Battlecruiser Captain"
	l_pocket = /obj/item/melee/transforming/energy/sword/saber/red
	r_pocket = /obj/item/melee/classic_baton/telescopic
	suit = /obj/item/clothing/suit/toggle/captains_parade/syndicate
	suit_store = /obj/item/gun/ballistic/revolver/mateba
	back = /obj/item/storage/backpack/satchel/leather
	head = /obj/item/clothing/head/HoS/syndicate
	mask = /obj/item/clothing/mask/cigarette/cigar/havana
	glasses = /obj/item/clothing/glasses/thermal/eyepatch

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/syndicate_empty/battlecruiser/assault/captain/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

//Ancient cryogenic sleepers. Players become NT crewmen from a hundred year old space station, now on the verge of collapse.
/obj/effect/mob_spawn/human/oldsec
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise a security uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	mob_name = "a security officer"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "You are a security officer working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. \
	The last thing you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_info = "Work as a team with your fellow survivors and do not abandon them."
	uniform = /obj/item/clothing/under/rank/security/officer
	shoes = /obj/item/clothing/shoes/jackboots
	id = /obj/item/card/id/away/old/sec
	r_pocket = /obj/item/restraints/handcuffs
	l_pocket = /obj/item/assembly/flash/handheld
	job_description = "Oldstation Crew"
	assignedrole = "Ancient Crew"
	can_load_appearance = TRUE
	category = "offstation"

/obj/effect/mob_spawn/human/oldsec/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/obj/effect/mob_spawn/human/oldeng
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise an engineering uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	mob_name = "an engineer"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	job_description = "Oldstation Crew"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "You are an engineer working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. The last thing \
	you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_info = "Work as a team with your fellow survivors and do not abandon them."
	uniform = /obj/item/clothing/under/rank/engineering/engineer
	shoes = /obj/item/clothing/shoes/workboots
	id = /obj/item/card/id/away/old/eng
	gloves = /obj/item/clothing/gloves/color/fyellow/old
	l_pocket = /obj/item/tank/internals/emergency_oxygen
	assignedrole = "Ancient Crew"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/oldeng/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/obj/effect/mob_spawn/human/oldsci
	name = "old cryogenics pod"
	desc = "A humming cryo pod. You can barely recognise a science uniform underneath the built up ice. The machine is attempting to wake up its occupant."
	mob_name = "a scientist"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "You are a scientist working for Nanotrasen, stationed onboard a state of the art research station."
	flavour_text = "You vaguely recall rushing into a cryogenics pod due to an oncoming radiation storm. \
	The last thing you remember is the station's Artificial Program telling you that you would only be asleep for eight hours. As you open \
	your eyes, everything seems rusted and broken, a dark feeling swells in your gut as you climb out of your pod."
	important_info = "Work as a team with your fellow survivors and do not abandon them."
	uniform = /obj/item/clothing/under/rank/rnd/scientist
	shoes = /obj/item/clothing/shoes/laceup
	id = /obj/item/card/id/away/old/sci
	l_pocket = /obj/item/stack/medical/suture
	assignedrole = "Ancient Crew"
	job_description = "Oldstation Crew"
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/oldsci/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/obj/effect/mob_spawn/human/pirate
	name = "Space Pirate Sleeper"
	desc = "A cryo sleeper smelling faintly of rum. The sleeper looks unstable. <i>Perhaps the pirate within can be killed with the right tools...</i>"
	job_description = "Space Pirate"
	random = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_name = "a space pirate"
	mob_species = /datum/species/skeleton/space
	outfit = /datum/outfit/pirate/space
	roundstart = FALSE
	death = FALSE
	anchored = TRUE
	density = FALSE
	show_flavour = FALSE //Flavour only exists for spawners menu
	short_desc = "You are a space pirate."
	flavour_text = "Станция отказалась платить вам за крышу. Похитьте её ресурсы, обнесите хранилище на кредиты. Избегайте ненужных жертв. Не забывайте следить за своим кораблем."
	assignedrole = "Space Pirate"
	var/rank = "Mate"
	can_load_appearance = FALSE
	category = "midround"

/obj/effect/mob_spawn/human/pirate/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(user.mind.has_antag_datum(/datum/antagonist/pirate))
		to_chat(user, "<span class='notice'>Your shipmate sails within their dreams for now. Perhaps they may wake up eventually.</span>")
	else
		to_chat(user, "<span class='notice'>If you want to kill the pirate off, something to pry open the sleeper might be the best way to do it.</span>")


/obj/effect/mob_spawn/human/pirate/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_CROWBAR && user.a_intent != INTENT_HARM)
		if(user.mind.has_antag_datum(/datum/antagonist/pirate))
			to_chat(user,"<span class='warning'>Why would you want to do that to your shipmate? That'd kill them.</span>")
			return
		user.visible_message("<span class='warning'>[user] start to pry open [src]...</span>",
				"<span class='notice'>You start to pry open [src]...</span>",
				"<span class='italics'>You hear prying...</span>")
		W.play_tool_sound(src)
		if(do_after(user, 100*W.toolspeed, target = src))
			user.visible_message("<span class='warning'>[user] pries open [src], disrupting the sleep of the pirate within and killing them.</span>",
				"<span class='notice'>You pry open [src], disrupting the sleep of the pirate within and killing them.</span>",
				"<span class='italics'>You hear prying, followed by the death rattling of bones.</span>")
			log_game("[key_name(user)] has successfully pried open [src] and disabled a space pirate spawner.")
			W.play_tool_sound(src)
			playsound(src.loc, 'modular_citadel/sound/voice/scream_skeleton.ogg', 50, 1, 4, 1.2)
			if(rank == "Captain")
				new /obj/effect/mob_spawn/human/pirate/corpse/captain(get_turf(src))
			else
				new /obj/effect/mob_spawn/human/pirate/corpse(get_turf(src))
			qdel(src)
	else
		..()

/obj/effect/mob_spawn/human/pirate/corpse //occurs when someone pries a pirate out of their sleeper.
	mob_name = "Dead Space Pirate"
	death = TRUE
	instant = TRUE
	random = FALSE

/obj/effect/mob_spawn/human/pirate/corpse/Destroy()
	return ..()

/obj/effect/mob_spawn/human/pirate/corpse/captain
	rank = "Captain"
	mob_name = "Dead Space Pirate Captain"
	outfit = /datum/outfit/pirate/space/captain

/obj/effect/mob_spawn/human/pirate/special(mob/living/new_spawn)
	new_spawn.fully_replace_character_name(new_spawn.real_name,generate_pirate_name())
	new_spawn.mind.add_antag_datum(/datum/antagonist/pirate)

/obj/effect/mob_spawn/human/pirate/proc/generate_pirate_name()
	var/beggings = strings(PIRATE_NAMES_FILE, "beginnings")
	var/endings = strings(PIRATE_NAMES_FILE, "endings")
	return "[rank] [pick(beggings)] [pick(endings)]"

/obj/effect/mob_spawn/human/pirate/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/obj/effect/mob_spawn/human/pirate/captain
	rank = "Captain"
	outfit = /datum/outfit/pirate/space/captain

/obj/effect/mob_spawn/human/pirate/gunner
	rank = "Gunner"

/obj/effect/mob_spawn/human/ghostcafe
	name = "Ghost Cafe Sleeper"
	uses = -1
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_name = "a ghost cafe visitor"
	roundstart = FALSE
	anchored = TRUE
	density = FALSE
	death = FALSE
	loadout_enabled = FALSE
	assignedrole = "Ghost Cafe Visitor"
	short_desc = "Вы посетитель Призрачного Кафе!"
	flavour_text = "Вы совершенно уверены в одном. Вы не живое существо. Вы в симуляции? Заходя за данную роль вы соглашаетесь с тем, что на территории Гост-Кафе полностью отсутствуют какие-либо правила Ролевой Игры. Тем не менее, базовые серверные правила не отменяются. Вы должны вести себя адекватно так, чтобы не мешать другим игрокам и не портить саму локацию. Если в чём-то не уверены или нужна помощь - всегда можете попросить помощи Администратора. Несоблюдение базовых норм поведения повлекут за собой наказание."
	skip_reentry_check = TRUE
	banType = ROLE_GHOSTCAFE
	back = /obj/item/storage/backpack/holding/satchel // BLUEMOON ADD
	can_load_appearance = 2
	antagonist_type = /datum/antagonist/ghost_role/ghost_cafe // BLUEMOON ADD

/datum/action/toggle_dead_chat_mob
	icon_icon = 'icons/mob/mob.dmi'
	button_icon_state = "ghost"
	name = "Toggle deadchat"
	desc = "Turn off or on your ability to hear ghosts."

/datum/action/toggle_dead_chat_mob/Trigger()
	if(!..())
		return FALSE
	var/mob/M = target
	if(HAS_TRAIT_FROM(M,TRAIT_SIXTHSENSE,GHOSTROLE_TRAIT))
		REMOVE_TRAIT(M,TRAIT_SIXTHSENSE,GHOSTROLE_TRAIT)
		to_chat(M,"<span class='notice'>You're no longer hearing deadchat.</span>")
	else
		ADD_TRAIT(M,TRAIT_SIXTHSENSE,GHOSTROLE_TRAIT)
		to_chat(M,"<span class='notice'>You're once again longer hearing deadchat.</span>")


/datum/action/disguise
	name = "Disguise"
	button_icon_state = "ling_transform"
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	background_icon_state = "bg_mime"
	var/currently_disguised = FALSE
	var/static/list/mob_blacklist = typecacheof(list(
		/mob/living/simple_animal/pet,
		/mob/living/simple_animal/hostile/retaliate/goose,
		/mob/living/simple_animal/hostile/poison,
		/mob/living/simple_animal/hostile/retaliate/goat,
		/mob/living/simple_animal/cow,
		/mob/living/simple_animal/chick,
		/mob/living/simple_animal/chicken,
		/mob/living/simple_animal/kiwi,
		/mob/living/simple_animal/babyKiwi,
		/mob/living/simple_animal/deer,
		/mob/living/simple_animal/parrot,
		/mob/living/simple_animal/hostile/lizard,
		/mob/living/simple_animal/crab,
		/mob/living/simple_animal/cockroach,
		/mob/living/simple_animal/butterfly,
		/mob/living/simple_animal/mouse,
		/mob/living/simple_animal/sloth,
		/mob/living/simple_animal/opossum,
		/mob/living/simple_animal/hostile/bear,
		/mob/living/simple_animal/hostile/asteroid/polarbear,
		/mob/living/simple_animal/hostile/asteroid/wolf,
		/mob/living/carbon/monkey,
		/mob/living/simple_animal/hostile/gorilla,
		/mob/living/carbon/alien/larva,
		/mob/living/simple_animal/hostile/retaliate/frog
	))


/datum/action/disguise/Trigger()
	var/mob/living/carbon/human/H = owner
	if(!currently_disguised)
		var/user_object_type = input(H, "Disguising as OBJECT or MOB?") as null|anything in list("OBJECT", "MOB")
		if(user_object_type)
			var/search_term = stripped_input(H, "Enter the search term")
			if(search_term)
				var/list_to_search
				if(user_object_type == "MOB")
					list_to_search = subtypesof(/mob) - mob_blacklist
				else
					list_to_search = subtypesof(/obj)
				var/list/filtered_results = list()
				for(var/some_search_item in list_to_search)
					if(findtext("[some_search_item]", search_term))
						filtered_results += some_search_item
				if(!length(filtered_results))
					to_chat(H, "Nothing matched your search query!")
				else
					var/disguise_selection = input("Select item to disguise as") as null|anything in filtered_results
					if(disguise_selection)
						var/atom/disguise_item = disguise_selection
						var/image/I = image(icon = initial(disguise_item.icon), icon_state = initial(disguise_item.icon_state), loc = H)
						I.override = TRUE
						I.layer = ABOVE_MOB_LAYER
						H.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "ghost_cafe_disguise", I)
						currently_disguised = TRUE
	else
		H.remove_alt_appearance("ghost_cafe_disguise")
		currently_disguised = FALSE

/obj/effect/mob_spawn/human/ghostcafe/special(mob/living/carbon/human/new_spawn)
	. = ..()
	if(new_spawn.client)
		new_spawn.client.prefs.copy_to(new_spawn)
		var/datum/antagonist/ghost_role/ghost_cafe/GC = new_spawn.mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe)
		GC.adittonal_allowed_area = get_area(src)
		GC.adittonal_allowed_area = GC.adittonal_allowed_area.type
		var/datum/outfit/O = new /datum/outfit/ghostcafe()
		O.equip(new_spawn, FALSE, new_spawn.client)
		SSjob.equip_loadout(null, new_spawn)
		SSjob.post_equip_loadout(null, new_spawn)
		SSquirks.AssignQuirks(new_spawn, new_spawn.client, TRUE, TRUE, null, FALSE, new_spawn)
		SSlanguage.AssignLanguage(new_spawn, new_spawn.client)
		new_spawn.ghost_cafe_traits(TRUE, GC.adittonal_allowed_area)
		to_chat(new_spawn,"<span class='boldwarning'>Ghosting is free!</span>")

/datum/outfit/ghostcafe
	name = "ID, jumpsuit and shoes"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	id = /obj/item/card/id/no_banking
	r_hand = /obj/item/storage/box/syndie_kit/chameleon/ghostcafe


/datum/outfit/ghostcafe/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if (isplasmaman(H))
		head = /obj/item/clothing/head/helmet/space/plasmaman
		uniform = /obj/item/clothing/under/plasmaman
		l_hand= /obj/item/tank/internals/plasmaman/belt/full
		mask = /obj/item/clothing/mask/breath
		return

	var/suited = !preference_source || preference_source.prefs.jumpsuit_style == PREF_SUIT
	if (CONFIG_GET(flag/grey_assistants))
		uniform = suited ? /obj/item/clothing/under/color/grey : /obj/item/clothing/under/color/jumpskirt/grey
	else
		if(SSevents.holidays && SSevents.holidays[PRIDE_MONTH])
			uniform = suited ? /obj/item/clothing/under/color/rainbow : /obj/item/clothing/under/color/jumpskirt/rainbow
		else
			uniform = suited ? /obj/item/clothing/under/color/random : /obj/item/clothing/under/color/jumpskirt/random

/datum/outfit/ghostcafe/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.internal = H.get_item_for_held_index(1)

/obj/item/storage/box/syndie_kit/chameleon/ghostcafe
	name = "ghost cafe costuming kit"
	desc = "Look just the way you did in life - or better!"

/obj/item/storage/box/syndie_kit/chameleon/ghostcafe/PopulateContents() // Doesn't contain a PDA, for isolation reasons.
	new /obj/item/clothing/under/chameleon(src)
	new /obj/item/clothing/suit/chameleon(src)
	new /obj/item/clothing/gloves/chameleon(src)
	new /obj/item/clothing/shoes/chameleon(src)
	new /obj/item/clothing/glasses/chameleon(src)
	new /obj/item/clothing/head/chameleon(src)
	new /obj/item/clothing/mask/chameleon(src)
	new /obj/item/storage/backpack/chameleon(src)
	new /obj/item/clothing/neck/cloak/chameleon(src)

//Port Tarkof, 6 people trapped in a revamped charlie-station like ghost role. Survive the aliens and threats, Fix the port and/or finish construction

/obj/effect/mob_spawn/human/tarkon
	name = "P-T Abandoned Crew"
	mob_name = "an abandoned Port Tarkov member"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "Вы - брошенный таинственными работодателями сотрудник Порта 'Тарков' Корпорации, пытающейся создать устойчивые жилые условия внутри крупных астероидов для бедных. По какой-то причине вы понятия не имеете, что такое Синдикат и ваше последнее воспоминание о Nanotrasen - это гадкая Корпорация, предавшая вас тем или иным образом."
	flavour_text = "Что-то пошло не так. Эксперименты пошли наперекосяк, расширения были сделаны до того, как проверки были полностью завершены. Теперь вы должны разобраться с последствия исхода прошлого экипажа. Приведите порт 'Тарков' к успеху, который планировался, либо умрите - стараясь."
	important_info = "Не конфликтуйте без особой на то причины, используйте свой корабль для покупки дополнительных предметов или получения помощи. Не обменивайте своё специальное, бесценное оборудование. Непрошеные и незваные гости могут оказаться сотрудником вашей станции."
	outfit = /datum/outfit/tarkoff
	assignedrole = "Ancient Crew"
	job_description = "Oldstation Crew"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	computer_area = /area/ruin/space/has_grav/bluemoon/port_tarkon/centerhall
	make_bank_account = TRUE

	give_cooler_to_mob_if_synth = TRUE

	antagonist_type = /datum/antagonist/ghost_role/tarkov
	category = "offstation"

/datum/outfit/tarkoff
	name = "Default Port Tarkov Outfit"
	uniform = /obj/item/clothing/under/rank/cargo/util
	back = /obj/item/storage/backpack
	shoes = /obj/item/clothing/shoes/winterboots
	gloves = /obj/item/clothing/gloves/fingerless
	glasses = /obj/item/clothing/glasses/sunglasses
	id = /obj/item/card/id/away/tarkoff/cargo
	l_pocket = /obj/item/card/mining_point_card
	r_pocket = /obj/item/mining_voucher
	ears = /obj/item/radio/headset/tarkoff

	implants = list(/obj/item/implant/anchor)

/datum/outfit/tarkoff/post_equip(mob/living/carbon/human/tarkoff, visualsOnly = FALSE)
	var/obj/item/card/id/id_card = tarkoff.wear_id
	if(istype(id_card))
		id_card.registered_name = tarkoff.real_name
		id_card.update_label()
		id_card.update_icon()
	var/obj/item/radio/target_radio = tarkoff.ears
	target_radio.set_frequency(FREQ_TARKOFF)
	target_radio.recalculateChannels()

	return ..()

/obj/effect/mob_spawn/human/tarkon/sci
	mob_name = "an abandoned scientist"
	outfit = /datum/outfit/tarkoff/sci

/datum/outfit/tarkoff/sci
	name = "Port tarkoff Science Outfit"
	uniform = /obj/item/clothing/under/rank/rnd/scientist/util
	glasses = /obj/item/clothing/glasses/hud/diagnostic
	id = /obj/item/card/id/away/tarkoff/sci
	l_hand = /obj/item/inducer
	l_pocket = null
	r_pocket = /obj/item/stock_parts/cell/high

/obj/effect/mob_spawn/human/tarkon/med
	mob_name = "an abandoned medical resident"
	outfit = /datum/outfit/tarkoff/med

/datum/outfit/tarkoff/med
	name = "Port Tarkov Medical Outfit"
	uniform = /obj/item/clothing/under/rank/medical/doctor/util
	glasses = /obj/item/clothing/glasses/hud/health
	id = /obj/item/card/id/away/tarkoff/med
	neck = /obj/item/clothing/neck/stethoscope
	l_pocket = /obj/item/healthanalyzer
	r_pocket = /obj/item/stack/medical/suture/medicated

/obj/effect/mob_spawn/human/tarkon/engi
	mob_name = "an abandoned maintenance engineer"
	outfit = /datum/outfit/tarkoff/engi

/datum/outfit/tarkoff/engi
	name = "Port tarkoff Engineering Outfit"
	uniform = /obj/item/clothing/under/rank/engineering/engineer/util
	glasses = /obj/item/clothing/glasses/meson/engine/tray
	id = /obj/item/card/id/away/tarkoff/engi
	gloves = /obj/item/clothing/gloves/combat
	l_pocket = /obj/item/tank/internals/emergency_oxygen/engi
	r_pocket = /obj/item/stack/cable_coil

/obj/effect/mob_spawn/human/tarkon/sec
	mob_name = "an abandoned security deputy"
	outfit = /datum/outfit/tarkoff/sec

/datum/outfit/tarkoff/sec
	name = "Port tarkoff Security Outfit"
	uniform = /obj/item/clothing/under/rank/security/officer/util
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	gloves = /obj/item/clothing/gloves/tackler/combat
	id = /obj/item/card/id/away/tarkoff/sec
	l_pocket = /obj/item/melee/classic_baton/telescopic
	r_pocket = /obj/item/grenade/barrier

/obj/effect/mob_spawn/human/tarkon/ensign
	name = "P-T Abandoned Ensign"
	mob_name = "an abandoned ensign"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper-o"
	short_desc = "Вы получили задание от 'Тарков Индастриз' и были высланы в Порт Тарков в качестве члена командования низшего уровня. Вы, не имея никакого фактического командования, но будучи просто еще одним козлом отпущения, на которого можно свалить вину в случае неудачи... провалились."
	flavour_text = "Что-то пошло не так. Эксперименты пошли наперекосяк, расширения были сделаны до того, как проверки были полностью завершены. Теперь вы должны разобраться с последствия исхода прошлого экипажа. Приведите порт 'Тарков' к успеху, который планировался, либо умрите - стараясь."
	important_info = "Не конфликтуйте без особой на то причины, используйте свой корабль для покупки дополнительных предметов или получения помощи. Не обменивайте своё специальное, бесценное оборудование. Непрошеные и незваные гости могут оказаться сотрудником вашей станции."
	outfit = /datum/outfit/tarkoff/ensign

/datum/outfit/tarkoff/ensign //jack of all trades, master of none, spent all his credits, every last one
	name = "Port tarkoff Ensigns Outfit"
	uniform = /obj/item/clothing/under/rank/captain/util
	ears = /obj/item/radio/headset/tarkoff/ensign
	id = /obj/item/card/id/away/tarkoff/ensign
	neck = /obj/item/clothing/neck/cloak/alt/boatcloak/command
	gloves = /obj/item/clothing/gloves/combat
	l_pocket = /obj/item/melee/classic_baton/telescopic
	r_pocket = /obj/item/grenade/barrier

/obj/item/radio/headset/tarkoff
	name = "Tarkov Headset"
	freerange = TRUE
	freqlock = TRUE
	keyslot = new /obj/item/encryptionkey/headset_cargo/tarkoff

/obj/item/radio/headset/tarkoff/ensign
	name = "Tarkov Ensign headset"
	desc = "A headset personally handed to trusted crew of tarkoff. It fills you with will to do... Something."
	command = TRUE
/obj/item/card/id/away/tarkoff
	assignment = "P-T Cargo Personell"
	access = list(ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_TARKOFF)

/obj/item/card/id/away/tarkoff/sec
	assignment = "P-T Port Guard"
	access = list(ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_BRIG, ACCESS_TARKOFF, ACCESS_AWAY_SEC)

/obj/item/card/id/away/tarkoff/med
	assignment = "P-T Trauma Medic"
	access = list(ACCESS_MEDICAL, ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_TARKOFF)

/obj/item/card/id/away/tarkoff/eng
	assignment = "P-T Maintenance Crew"
	access = list(ACCESS_ROBOTICS, ACCESS_AWAY_GENERAL, ACCESS_TARKOFF, ACCESS_ATMOSPHERICS, ACCESS_ENGINE_EQUIP)

/obj/item/card/id/away/tarkoff/sci
	assignment = "P-T Field Researcher"
	access = list(ACCESS_ROBOTICS, ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_TARKOFF)

/obj/item/card/id/away/tarkoff/ensign
	assignment = "Tarkov Ensign"
	access = list(ACCESS_MEDICAL, ACCESS_ROBOTICS, ACCESS_AWAY_GENERAL, ACCESS_TARKOFF, ACCESS_WEAPONS, ACCESS_BRIG, ACCESS_ATMOSPHERICS, ACCESS_AWAY_SEC, ACCESS_ENGINE_EQUIP)

/obj/item/card/id/away/tarkoff/sci
	name = "P-T field researcher's access card"
	desc = "An access card designated for \"The Science Team\". You are forgotten basically immediately when it comes to the lab."

/obj/item/card/id/away/tarkoff/med
	name = "P-T trauma medic's access card"
	desc = "An access card designated for \"Medical Staff\". You provide the medic bags."

/obj/item/card/id/away/tarkoff/sec
	name = "P-T resident deputy's access card"
	desc = "An access card designated for \"Security Members\". Everyone wants your guns, partner. Yee-haw."

/obj/item/card/id/away/tarkoff/cargo
	name = "P-T cargo hauler's access card"
	desc = "An access card designated for \"Cargo's Finest\". You're also a part time space miner, when cargonia is quiet."


/obj/item/card/id/away/tarkoff/engi
	name = "P-T maintenance engineer's access card"
	desc = "An access card designated for \"engineering staff\". You're going to be the one everyone points at to fix stuff, lets be honest."

/obj/item/card/id/away/tarkoff/ensign
	name = "Tarkov Ensign's Access Card"
	desc = "An access card designated for \"Tarkov Ensign\". No one has to listen to you... but you're the closest there is for command around here."

// CENTCOM

/obj/effect/mob_spawn/human/centcom_syndicate
	name = "Special Operations Forces Syndicate Intern"
	roundstart = FALSE
	death = FALSE
	job_description = "Special Operations Forces Syndicate Intern"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Интерн-Специалист, взятый на работу Центральным Командованием в качестве очередной рабочей единицы."
	flavour_text = "Не так давно вы были взяты на работу в качестве дежурного на Аванпосту Центрального Командования. Ваша задача проста - следить за факсом и отвечать на сообщения, полученные через факс. Помните, что часть сообщений поступает из иного пласта Вселенной, потому не пугайтесь, если вдруг окажется, что где-то там вызывают Кровавого Бога. Просто выполняйте свою работу и отправляйте инструкции."
	important_info = "Вы не антагонист. Вы гид-помощник. Отвечайте на Факсы и создавайте ролевую ценность в идущем раунде с использованием своих возможностей. Bы можете выдавать около-шуточные требования и указания в Эксту. Ни в коем случае не оказывайте прямое влияние на станцию в Динамику."
	outfit = /datum/outfit/centcom_syndicate
	computer_area = /area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms
	assignedrole = "Centcom Intern"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	antagonist_type = /datum/antagonist/ghost_role/centcom_intern
	category = "offstation"

/datum/outfit/centcom_syndicate
	name = "Special Ops Syndicate Intern"
	head = /obj/item/clothing/head/HoS/beret/syndicate
	ears = /obj/item/radio/headset/syndicate/alt
	mask = /obj/item/clothing/mask/cigarette/cigar/havana
	glasses = /obj/item/clothing/glasses/aviators
	suit = /obj/item/clothing/suit/armor/vest/warden/syndicate
	uniform = /obj/item/clothing/under/syndicate/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	shoes = /obj/item/clothing/shoes/combat/swat

	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	back = /obj/item/storage/backpack/satchel/sec
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/regular=1,
		/obj/item/stamp/chameleon=1,
		)
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/deathrattle/centcom, /obj/item/implant/explosive, /obj/item/implant/mindshield, /obj/item/implant/radio/centcom)
	cybernetic_implants = list(/obj/item/organ/cyberimp/eyes/hud/security,/obj/item/organ/cyberimp/chest/nutrimentextreme, /obj/item/organ/cyberimp/chest/chem_implant)
	id = /obj/item/card/id/ert

/datum/outfit/centcom_syndicate/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()
	W.access += get_centcom_access("Special Ops Syndicate Intern")
	W.assignment = "Special Ops Syndicate Intern"
	W.registered_name = H.real_name
	W.update_label()

	var/obj/item/radio/headset/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

/obj/effect/mob_spawn/human/centcom_nanotrasen
	name = "Special Operations Forces Nanotrasen Intern"
	roundstart = FALSE
	death = FALSE
	job_description = "Special Operations Forces Nanotrasen Intern"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Интерн-Специалист, взятый на работу Центральным Командованием в качестве очередной рабочей единицы."
	flavour_text = "Не так давно вы были взяты на работу в качестве дежурного на Аванпосту Центрального Командования. Ваша задача проста - следить за факсом и отвечать на сообщения, полученные через факс. Помните, что часть сообщений поступает из иного пласта Вселенной, потому не пугайтесь, если вдруг окажется, что где-то там вызывают Кровавого Бога. Просто выполняйте свою работу и отправляйте инструкции."
	important_info = "Вы не антагонист. Вы гид-помощник. Отвечайте на Факсы и создавайте ролевую ценность в идущем раунде с использованием своих возможностей. Bы можете выдавать около-шуточные требования и указания в Эксту. Ни в коем случае не оказывайте прямое влияние на станцию в Динамику."
	outfit = /datum/outfit/centcom_nanotrasen
	computer_area = /area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms
	assignedrole = "Centcom Intern"
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	antagonist_type = /datum/antagonist/ghost_role/centcom_intern
	category = "offstation"

/datum/outfit/centcom_nanotrasen
	name = "Special Ops Nanotrasen Intern"
	head = /obj/item/clothing/head/beret/black
	ears = /obj/item/radio/headset/syndicate/alt
	glasses = /obj/item/clothing/glasses/aviators
	suit = /obj/item/clothing/suit/space/officer
	uniform = /obj/item/clothing/under/syndicate
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	shoes = /obj/item/clothing/shoes/combat/swat

	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/regular=1,
		/obj/item/stamp/chameleon=1,
		)
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/deathrattle/centcom, /obj/item/implant/explosive, /obj/item/implant/mindshield, /obj/item/implant/radio/centcom)
	cybernetic_implants = list(/obj/item/organ/cyberimp/eyes/hud/security,/obj/item/organ/cyberimp/chest/nutrimentextreme, /obj/item/organ/cyberimp/chest/chem_implant)
	id = /obj/item/card/id/ert

/datum/outfit/centcom_nanotrasen/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()
	W.access += get_centcom_access("Special Ops Centcom Intern")
	W.assignment = "Special Ops Centcom Intern"
	W.registered_name = H.real_name
	W.update_label()

	var/obj/item/radio/headset/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

//DS-2.
/obj/effect/mob_spawn/human/ds2
	name = "DS-2 personnel"
	mob_name = "DS-2 personnel"
	short_desc = "Вы Специалист Синдиката, работающий на Общем Корабле Синдиката из ячейки 'Глубокий Космос Два' под названием \
	'Благославлённый' под Начальством Адмирала одной из Сторон и изучающий аномальное поле Системы Синих Лун."
	flavour_text = "Синдикат счел нужным направить передовую оперативную базу в Сектор Тринадцать для наблюдения за \
	операциями NT и Кордоном. Ваш приказ - поддерживать целостность корабля и по возможности не высовываться."
	important_info = "Вы не антагонист."
	roundstart = FALSE
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	use_outfit_name = TRUE
	computer_area = /area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms
	antagonist_type = /datum/antagonist/ghost_role/ds2
	make_bank_account = TRUE // BLUEMOON ADD
	category = "syndicate"

/obj/effect/mob_spawn/human/ds2/prisoner
	name = "Syndicate Prisoner"
	mob_name = "a Syndicate prisoner"
	short_desc = "По какой-то причине вы оказались в тюремной части Корабля 'Благославлённый' с неизвестным сроком."
	flavour_text = "Не осознавая, где вы находитесь, вы знаете только то, что вы в плену. Вы были высокопоставленным лицом \
	Nanotrasen или же серьёзно нарушили кодекс Синдиката, или являетесь кем бы то не было другим и это единственная информация, \
	которая таится в вашей голове. Что касается того, почему вы здесь? Ваша голова раскалывается и вы просто не помните..."
	important_info = "Вы все еще подчиняетесь стандартной политике заключенных и должны обратиться к администратору, прежде чем враждовать с DS-2."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	outfit = /datum/outfit/ds2/prisoner
	starting_money = 50 // BLUEMOON ADD

/obj/effect/mob_spawn/human/ds2/syndicate
	name = "Syndicate Operative"
	mob_name = "a Syndicate operative"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Специалист Синдиката, работающий на Оперативной Базе Синдиката из формирования 'Глубокий Космос Два' под названием \
	'Благославлённый' под Начальством Адмирала одной из Сторон и изучающий аномальное поле Системы Синих Лун."
	flavour_text = "Синдикат счел нужным направить передовую оперативную базу в Сектор Тринадцать для наблюдения за операциями NT и Кордоном. \
	Ваш приказ - поддерживать целостность корабля и по возможности не высовываться."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/ds2/syndicate
	starting_money = 1000 // BLUEMOON ADD

/obj/effect/mob_spawn/human/ds2/syndicate_command
	name = "Syndicate Command Operative"
	mob_name = "a Syndicate leader"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Адмирал одной из ячеек Синдиката, работающий на Корабле Синдиката из ячейки 'Глубокий Космос Два' под названием 'Благославлённый'. \
	Приведите Объект под вашей ответственностью к успеху, который планировался, либо умрите - стараясь."
	flavour_text = "Синдикат счел нужным направить передовую оперативную базу в Сектор Тринадцать для наблюдения за операциями NT и Кордоном. \
	Ваш приказ - поддерживать целостность корабля и по возможности не высовываться."
	important_info = "Вы не антагонист."
	outfit = /datum/outfit/ds2/syndicate_command
	starting_money = 5000 // BLUEMOON ADD

/obj/effect/mob_spawn/human/ds2/syndicate/special(mob/living/carbon/human/new_spawn)
	. = ..()
	new_spawn.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)

	var/obj/item/implant/anchor/ghost_anchor = new
	ghost_anchor.implant(new_spawn, null, TRUE)

/obj/effect/mob_spawn/human/ds2/syndicate_command/special(mob/living/carbon/human/new_spawn)
	. = ..()
	new_spawn.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)

	var/obj/item/implant/anchor/ghost_anchor = new
	ghost_anchor.implant(new_spawn, null, TRUE)

/obj/effect/mob_spawn/human/ds2/syndicate/service
	mob_name = "a Waffle Co worker"
	outfit = /datum/outfit/ds2/syndicate/service

/obj/effect/mob_spawn/human/ds2/syndicate/miner
	mob_name = "a Donk Co mining worker"
	outfit = /datum/outfit/ds2/syndicate/miner

/obj/effect/mob_spawn/human/ds2/syndicate/enginetech
	mob_name = "a GEC ship engineer"
	outfit = /datum/outfit/ds2/syndicate/enginetech

/obj/effect/mob_spawn/human/ds2/syndicate/researcher
	mob_name = "a Cybersun research specialist"
	outfit = /datum/outfit/ds2/syndicate/researcher

/obj/effect/mob_spawn/human/ds2/syndicate/stationmed
	mob_name = "an Interdyne medical doctor"
	outfit = /datum/outfit/ds2/syndicate/stationmed

/obj/effect/mob_spawn/human/ds2/syndicate/brigoff
	mob_name = "a Gorlex Marauders soldier"
	outfit = /datum/outfit/ds2/syndicate/brigoff

/obj/effect/mob_spawn/human/ds2/syndicate_command/masteratarms
	mob_name = "a Gorlex Marauders sergeant"
	outfit = /datum/outfit/ds2/syndicate_command/masteratarms

/obj/effect/mob_spawn/human/ds2/syndicate_command/corporateliaison
	mob_name = "a Triglav Syndicate representative"
	outfit = /datum/outfit/ds2/syndicate_command/corporateliaison

/obj/effect/mob_spawn/human/ds2/syndicate_command/comms
	mob_name = "Syndicate Comms Agent"
	outfit = /datum/outfit/ds2/syndicate_command/comms

/obj/effect/mob_spawn/human/ds2/syndicate_command/admiral
	mob_name = "a Triglav Syndicate admiral"
	outfit = /datum/outfit/ds2/syndicate_command/admiral
	starting_money = 10000 // BLUEMOON ADD

/datum/outfit/ds2
	name = "default ds2 outfit"

/datum/outfit/ds2/post_equip(mob/living/carbon/human/syndicate, visualsOnly = FALSE)
	var/obj/item/card/id/id_card = syndicate.wear_id
	if(istype(id_card))
		id_card.registered_name = syndicate.real_name
		id_card.update_label()
		id_card.update_icon()

	return ..()

//DS-2 Hostage
/datum/outfit/ds2/prisoner
	name = "Syndicate Prisoner"
	uniform = /obj/item/clothing/under/rank/prisoner/syndicate
	shoes = /obj/item/clothing/shoes/sneakers/crimson
	id = /obj/item/card/id/syndicate/advanced/ds/prisoner
	id_trim = /datum/id_trim/syndicom/ds2/prisoner

//DS-2 Crew
/datum/outfit/ds2/syndicate
	name = "DS-2 Operative"
	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	ears = /obj/item/radio/headset/ds2
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		)
	id = /obj/item/card/id/syndicate/advanced/ds
	id_trim = /datum/id_trim/syndicom/ds2
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/deathrattle/deepspacecrew)

/datum/outfit/ds2/syndicate/miner
	name = "DS-2 Mining Officer"
	uniform = /obj/item/clothing/under/syndicate/overalls
	belt = /obj/item/storage/bag/ore
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/kitchen/knife/combat/survival = 1,
		/obj/item/t_scanner/adv_mining_scanner/lesser = 1,
		/obj/item/gun/energy/kinetic_accelerator = 1,
		)
	l_pocket = /obj/item/card/mining_point_card
	r_pocket = /obj/item/mining_voucher
	head = /obj/item/clothing/head/soft/black
	id = /obj/item/card/id/syndicate/advanced/ds/mining
	id_trim = /datum/id_trim/syndicom/ds2/miner

/obj/item/card/id/syndicate/advanced/ds/mining
	assignment = "DS-2 Mining Officer"
	icon_state = "id_dsblack"

/datum/outfit/ds2/syndicate/service
	name = "DS-2 General Staff"
	uniform = /obj/item/clothing/under/syndicate
	back = /obj/item/storage/backpack/duffelbag/syndie
	suit = /obj/item/clothing/suit/apron/chef
	head = /obj/item/clothing/head/soft/mime
	id = /obj/item/card/id/syndicate/advanced/ds/general
	id_trim = /datum/id_trim/syndicom/ds2/syndicatestaff

/obj/item/card/id/syndicate/advanced/ds/general
	assignment = "DS-2 General Staff"

/datum/outfit/ds2/syndicate/enginetech
	name = "DS-2 Engine Technician"
	uniform = /obj/item/clothing/under/syndicate/overalls
	head = /obj/item/clothing/head/soft/sec/syndicate
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		)
	l_pocket = /obj/item/storage/bag/material
	r_pocket = /obj/item/storage/bag/construction
	glasses = /obj/item/clothing/glasses/welding
	belt = /obj/item/storage/belt/utility/syndicate
	gloves = /obj/item/clothing/gloves/combat
	id = /obj/item/card/id/syndicate/advanced/ds/enginetech
	id_trim = /datum/id_trim/syndicom/ds2/enginetechnician

/obj/item/card/id/syndicate/advanced/ds/enginetech
	assignment = "DS-2 Engine Technician"

/datum/outfit/ds2/syndicate/researcher
	name = "DS-2 Researcher"
	uniform = /obj/item/clothing/under/rank/rnd/scientist/utility/syndicate
	suit = /obj/item/clothing/suit/toggle/labcoat/science
	glasses = /obj/item/clothing/glasses/science
	gloves = /obj/item/clothing/gloves/color/black
	back = /obj/item/storage/backpack/duffelbag/syndie
	id = /obj/item/card/id/syndicate/advanced/ds/researcher
	id_trim = /datum/id_trim/syndicom/ds2/researcher

/obj/item/card/id/syndicate/advanced/ds/researcher
	assignment = "DS-2 Researcher"

/datum/outfit/ds2/syndicate/stationmed
	name = "DS-2 Medical Officer"
	uniform = /obj/item/clothing/under/syndicate/scrubs
	suit = /obj/item/clothing/suit/toggle/labcoat/syndicate
	belt = /obj/item/storage/belt/medolier/full
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	back = /obj/item/storage/backpack/duffelbag/syndie
	id = /obj/item/card/id/syndicate/advanced/ds/stationmed
	id_trim = /datum/id_trim/syndicom/ds2/medicalofficer
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/storage/firstaid/tactical = 1,
		)

/obj/item/card/id/syndicate/advanced/ds/stationmed
	assignment = "DS-2 Medical Officer"

/datum/outfit/ds2/syndicate/brigoff
	name = "DS-2 Brig Officer"
	uniform = /obj/item/clothing/under/syndicate/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	suit = /obj/item/clothing/suit/armor/bulletproof/old
	back = /obj/item/storage/backpack/duffelbag/syndie
	head = /obj/item/clothing/head/helmet/swat/ds
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	r_pocket = /obj/item/flashlight/seclite
	mask = /obj/item/clothing/mask/gas/syndicate
	ears = /obj/item/radio/headset/ds2
	id = /obj/item/card/id/syndicate/advanced/ds/command/brigoff
	id_trim = /datum/id_trim/syndicom/ds2/brigofficer

/obj/item/card/id/syndicate/advanced/ds/command/brigoff
	assignment = "DS-2 Brig Officer"
	icon_state = "id_dsblack"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate/post_equip(mob/living/carbon/human/syndicate)
	syndicate.faction |= ROLE_SYNDICATE
	return ..()

//DS-2 Command
/datum/outfit/ds2/syndicate_command
	name = "DS-2 Command Operative"
	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	ears = /obj/item/radio/headset/ds2/command
	back = /obj/item/storage/backpack/duffelbag/syndie
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/lighter/gonzofist = 1)
	id = /obj/item/card/id/syndicate/advanced/ds/gold/command
	implants = list(/obj/item/implant/weapons_auth, /obj/item/implant/deathrattle/deepspacecrew)
	id_trim = /datum/id_trim/syndicom/ds2

/obj/item/card/id/syndicate/advanced/ds/gold/command
	assignment = "DS-2 Command Operative"
	icon_state = "id_dsgold"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate_command/masteratarms
	name = "DS-2 Master At Arms"
	uniform = /obj/item/clothing/under/syndicate/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	suit = /obj/item/clothing/suit/armor/vest/warden/syndicate
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/duffelbag/syndie
	head = /obj/item/clothing/head/HoS/beret/syndicate
	r_pocket = /obj/item/flashlight/seclite
	implants = list(
		/obj/item/implant/weapons_auth,
		/obj/item/implant/krav_maga,
		/obj/item/implant/deathrattle/deepspacecrew
		)
	id = /obj/item/card/id/syndicate/advanced/ds/gold/command/masteratarms
	id_trim = /datum/id_trim/syndicom/ds2/masteratarms

/obj/item/card/id/syndicate/advanced/ds/gold/command/masteratarms
	assignment = "DS-2 Master At Arms"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate_command/corporateliaison
	name = "DS-2 Corporate Liasion"
	uniform = /obj/item/clothing/under/syndicate/sniper
	head = /obj/item/clothing/head/fedora
	shoes = /obj/item/clothing/shoes/laceup
	back = /obj/item/storage/backpack/duffelbag/syndie
	id_trim = /datum/id_trim/syndicom/ds2/corporateliasion
	id = /obj/item/card/id/syndicate/advanced/ds/gold/command/corporateliaison

/obj/item/card/id/syndicate/advanced/ds/gold/command/corporateliaison
	assignment = "DS-2 Corporate Liasion"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate_command/comms
	name = "Space Syndicate Comms Agent"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	mask = /obj/item/clothing/mask/chameleon
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	back = /obj/item/storage/backpack/duffelbag/syndie
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	implants = list(/obj/item/implant/weapons_auth)
	id = /obj/item/card/id/syndicate/advanced/ds/comms
	id_trim = /datum/id_trim/syndicom/ds2/comms

/obj/item/card/id/syndicate/advanced/ds/comms
	assignment = "Space Syndicate Comms Agent"
	icon_state = "card_black"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate_command/admiral
	name = "DS-2 Admiral"
	uniform = /obj/item/clothing/under/rank/captain/utility/syndicate
	neck = /obj/item/clothing/neck/cloak/syndieadm
	suit = /obj/item/clothing/suit/toggle/captains_parade/syndicate
	back = /obj/item/storage/backpack/duffelbag/syndie
	belt = /obj/item/gun/ballistic/automatic/pistol/APS
	head = /obj/item/clothing/head/HoS/syndicate
	id = /obj/item/card/id/syndicate/advanced/ds/gold/admiral
	id_trim = /datum/id_trim/syndicom/ds2/stationadmiral

/obj/item/card/id/syndicate/advanced/ds/gold/admiral
	assignment = "DS-2 Admiral"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/datum/outfit/ds2/syndicate_command/post_equip(mob/living/carbon/human/syndicate)
	syndicate.faction |= ROLE_SYNDICATE
	return ..()

/// DS-2

/datum/id_trim/syndicom/ds2
	assignment = "DS-2 Operative"
	trim_state = "idunknown"
	department_color = COLOR_ASSEMBLY_BLACK
	subdepartment_color = COLOR_SYNDIE_RED

/datum/id_trim/syndicom/ds2/prisoner
	assignment = "DS-2 Hostage"
	trim_state = "idds2hostage"
	subdepartment_color = COLOR_MAROON
	sechud_icon_state = SECHUD_DS2_PRISONER
	access = list()

/datum/id_trim/syndicom/ds2/miner
	assignment = "DS-2 Mining Officer"
	trim_state = "idds2miningofficer"
	sechud_icon_state = SECHUD_DS2_MININGOFFICER

/datum/id_trim/syndicom/ds2/syndicatestaff
	assignment = "DS-2 General Staff"
	trim_state = "idds2generalstaff"
	sechud_icon_state = SECHUD_DS2_GENSTAFF

/datum/id_trim/syndicom/ds2/researcher
	assignment = "DS-2 Researcher"
	trim_state = "idds2researcher"
	sechud_icon_state = SECHUD_DS2_RESEARCHER
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS)

/datum/id_trim/syndicom/ds2/enginetechnician
	assignment = "DS-2 Engine Technician"
	trim_state = "idds2enginetechnician"
	sechud_icon_state = SECHUD_DS2_ENGINETECHNICIAN

/datum/id_trim/syndicom/ds2/medicalofficer
	assignment = "DS-2 Medical Officer"
	trim_state = "idds2medicalofficer"
	sechud_icon_state = SECHUD_DS2_DOCTOR

/datum/id_trim/syndicom/ds2/masteratarms
	assignment = "DS-2 Master At Arms"
	trim_state = "idds2masteratarms"
	sechud_icon_state = SECHUD_DS2_MASTERATARMS
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS, ACCESS_SYNDICATE_LEADER)

/datum/id_trim/syndicom/ds2/brigofficer
	assignment = "DS-2 Brig Officer"
	trim_state = "idds2brigofficer"
	sechud_icon_state = SECHUD_DS2_BRIGOFFICER
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS, ACCESS_SYNDICATE_LEADER)

/datum/id_trim/syndicom/ds2/corporateliasion // DS2 HoP
	assignment = "DS-2 Corporate Liaison"
	trim_state = "idds2corporateliaison"
	sechud_icon_state = SECHUD_DS2_CORPLIAISON
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS, ACCESS_SYNDICATE_LEADER)

/datum/id_trim/syndicom/ds2/comms
	assignment = "Space Syndicate Comms Agent"
	trim_state = "idsyndicate"
	sechud_icon_state = SECHUD_SYNDICATE
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS, ACCESS_SYNDICATE_LEADER)

/datum/id_trim/syndicom/ds2/stationadmiral
	assignment = "DS-2 Admiral"
	trim_state = "idds2admiral"
	sechud_icon_state = SECHUD_DS2_ADMIRAL
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS, ACCESS_SYNDICATE_LEADER)

//Затычка до Id_Trim.

/obj/item/card/id/syndicate/advanced/prisoner
	name = "Prisoner"
	assignment = "DS-2 Hostage"
	icon_state = "card_ds2prisoner"
	access = list()

/obj/item/card/id/syndicate/advanced/ds/prisoner // Карта выше - объект для новых заключённых, эта - для заключённых-ролей
	name = "Prisoner"
	assignment = "DS-2 Hostage"
	access = list()

/obj/item/card/id/syndicate/advanced/ds
	name = "Deep Space Card"
	icon_state = "id_ds"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE)

/obj/item/card/id/syndicate/advanced/ds/gold
	name = "Deep Space Gold Card"
	icon_state = "id_dsgold"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE)

//CRYO CONSOLES
/obj/machinery/computer/cryopod/ds1
	radio = /obj/item/radio/headset/ds1
	announcement_channel = RADIO_CHANNEL_DS1
	req_one_access = list(ACCESS_SYNDICATE_LEADER)

/obj/machinery/computer/cryopod/ds2
	radio = /obj/item/radio/headset/ds2
	announcement_channel = RADIO_CHANNEL_DS2
	req_one_access = list(ACCESS_SYNDICATE_LEADER)

/obj/machinery/computer/cryopod/tarkoff
	radio = /obj/item/radio/headset/tarkoff
	announcement_channel = RADIO_CHANNEL_TARKOFF
	req_one_access = list(ACCESS_TARKOFF)
