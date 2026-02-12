// ** BATTLE ** //
/obj/machinery/computer/arcade/battle
	name = "arcade machine"
	desc = "Does not support Pinball."
	icon_state = "arcade"
	circuit = /obj/item/circuitboard/computer/arcade/battle

	var/enemy_name = "Space Villain"
	///Enemy health/attack points
	var/enemy_hp = 100
	var/enemy_mp = 40
	///Temporary message, for attack messages, etc
	var/temp = "Победители не употребляют космонаркотики"
	///list of battle messages for the current round, sent to TGUI
	var/list/battle_log = list()
	///enemy max HP, tracked for TGUI health bar
	var/enemy_max_hp = 100
	///player max HP, tracked for TGUI health bar
	var/player_max_hp = 85
	///the list of passive skill the enemy currently has. the actual passives are added in the enemy_setup() proc
	var/list/enemy_passive
	///if all the enemy's weakpoints have been triggered becomes TRUE
	var/finishing_move = FALSE
	///linked to passives, when it's equal or above the max_passive finishing move will become TRUE
	var/pissed_off = 0
	///the number of passives the enemy will start with
	var/max_passive = 3
	///weapon wielded by the enemy, the shotgun doesn't count.
	var/chosen_weapon

	///Player health
	var/player_hp = 85
	///player magic points
	var/player_mp = 20
	///used to remember the last three move of the player before this turn.
	var/list/last_three_move
	///if the enemy or player died. restart the game when TRUE
	var/gameover = FALSE
	///the player cannot make any move while this is set to TRUE. should only TRUE during enemy turns.
	var/blocked = FALSE
	///used to clear the enemy_action proc timer when the game is restarted
	var/timer_id
	///weapon used by the enemy, pure fluff.for certain actions
	var/list/weapons
	///unique to the emag mode, acts as a time limit where the player dies when it reaches 0.
	var/bomb_cooldown = 19

///creates the enemy base stats for a new round along with the enemy passives
/obj/machinery/computer/arcade/battle/proc/enemy_setup(player_skill)
	player_hp = 85
	player_mp = 20
	player_max_hp = 85
	enemy_hp = 100
	enemy_mp = 40
	enemy_max_hp = 100
	gameover = FALSE
	blocked = FALSE
	finishing_move = FALSE
	pissed_off = 0
	last_three_move = null
	battle_log = list()

	enemy_passive = list("short_temper" = TRUE, "poisonous" = TRUE, "smart" = TRUE, "shotgun" = TRUE, "magical" = TRUE, "chonker" = TRUE)
	for(var/i = LAZYLEN(enemy_passive); i > max_passive; i--) //we'll remove passives from the list until we have the number of passive we want
		var/picked_passive = pick(enemy_passive)
		LAZYREMOVE(enemy_passive, picked_passive)

	if(LAZYACCESS(enemy_passive, "chonker"))
		enemy_hp += 20
		enemy_max_hp += 20

	if(LAZYACCESS(enemy_passive, "shotgun"))
		chosen_weapon = "shotgun"
	else if(weapons)
		chosen_weapon = pick(weapons)
	else
		chosen_weapon = "null gun" //if the weapons list is somehow empty, shouldn't happen but runtimes are sneaky bastards.

	if(player_skill)
		player_hp += player_skill * 2
		player_max_hp += player_skill * 2

/obj/machinery/computer/arcade/battle/Reset()
	max_passive = 3
	var/name_action
	var/name_part1
	var/name_part2

	if(SSevents.holidays && SSevents.holidays[HALLOWEEN])
		name_action = pick_list(ARCADE_FILE, "rpg_action_halloween")
		name_part1 = pick_list(ARCADE_FILE, "rpg_adjective_halloween")
		name_part2 = pick_list(ARCADE_FILE, "rpg_enemy_halloween")
		weapons = strings(ARCADE_FILE, "rpg_weapon_halloween")
	else if(SSevents.holidays && SSevents.holidays[CHRISTMAS])
		name_action = pick_list(ARCADE_FILE, "rpg_action_xmas")
		name_part1 = pick_list(ARCADE_FILE, "rpg_adjective_xmas")
		name_part2 = pick_list(ARCADE_FILE, "rpg_enemy_xmas")
		weapons = strings(ARCADE_FILE, "rpg_weapon_xmas")
	else if(SSevents.holidays && SSevents.holidays[VALENTINES])
		name_action = pick_list(ARCADE_FILE, "rpg_action_valentines")
		name_part1 = pick_list(ARCADE_FILE, "rpg_adjective_valentines")
		name_part2 = pick_list(ARCADE_FILE, "rpg_enemy_valentines")
		weapons = strings(ARCADE_FILE, "rpg_weapon_valentines")
	else
		name_action = pick_list(ARCADE_FILE, "rpg_action")
		name_part1 = pick_list(ARCADE_FILE, "rpg_adjective")
		name_part2 = pick_list(ARCADE_FILE, "rpg_enemy")
		weapons = strings(ARCADE_FILE, "rpg_weapon")

	enemy_name = ("The " + name_part1 + " " + name_part2)
	name = (name_action + " " + enemy_name)

	enemy_setup(0) //in the case it's reset we assume the player skill is 0 because the VOID isn't a gamer

/obj/machinery/computer/arcade/battle/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeBattle", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/arcade/battle/ui_data(mob/user)
	var/list/data = list()
	data["enemy_name"] = enemy_name
	data["enemy_hp"] = enemy_hp
	data["enemy_max_hp"] = enemy_max_hp
	data["enemy_mp"] = enemy_mp
	data["player_hp"] = player_hp
	data["player_max_hp"] = player_max_hp
	data["player_mp"] = player_mp
	data["battle_log"] = battle_log
	data["gameover"] = gameover
	data["blocked"] = blocked
	data["finishing_move"] = finishing_move
	data["emagged"] = !!(obj_flags & EMAGGED)
	data["bomb_cooldown"] = bomb_cooldown
	data["enemy_passive"] = enemy_passive
	data["chosen_weapon"] = chosen_weapon
	return data

/obj/machinery/computer/arcade/battle/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/gamerSkill = 0

	switch(action)
		if("newgame")
			battle_log = list("Новый раунд!")
			if(obj_flags & EMAGGED)
				Reset()
				obj_flags &= ~EMAGGED
			enemy_setup(gamerSkill)
			. = TRUE

		if("attack", "defend", "counter_attack", "power_attack")
			if(blocked || gameover)
				return
			var/attackamt = rand(5,7) + rand(0, gamerSkill)

			if(finishing_move)
				attackamt *= 100

			switch(action)
				if("attack")
					battle_log = list("Вы наносите быстрый удар на [attackamt] урона!")
					enemy_hp -= attackamt
					arcade_action(usr, "attack", attackamt)

				if("defend")
					battle_log = list("Вы принимаете защитную стойку и получаете 10 МП!")
					player_mp += 10
					arcade_action(usr, "defend", attackamt)
					playsound(src, 'sound/arcade/mana.ogg', 50, TRUE, extrarange = -3)

				if("counter_attack")
					if(player_mp >= 10)
						battle_log = list("Вы готовитесь контратаковать!")
						player_mp -= 10
						arcade_action(usr, "counter_attack", attackamt)
					else
						battle_log = list("Недостаточно МП для контратаки — вы защищаетесь и получаете 10 МП!")
						player_mp += 10
						arcade_action(usr, "defend", attackamt)
					playsound(src, 'sound/arcade/mana.ogg', 50, TRUE, extrarange = -3)

				if("power_attack")
					if(player_mp >= 20)
						battle_log = list("Вы атакуете [enemy_name] изо всех сил на [attackamt * 2] урона!")
						enemy_hp -= attackamt * 2
						player_mp -= 20
						arcade_action(usr, "power_attack", attackamt)
					else
						battle_log = list("Недостаточно МП для мощной атаки — лёгкая атака на [attackamt] урона!")
						enemy_hp -= attackamt
						arcade_action(usr, "attack", attackamt)
			. = TRUE

	add_fingerprint(usr)

///happens after a player action and before the enemy turn. the enemy turn will be cancelled if there's a gameover.
/obj/machinery/computer/arcade/battle/proc/arcade_action(mob/user,player_stance,attackamt)
	blocked = TRUE
	if(player_stance == "attack" || player_stance == "power_attack")
		if(attackamt > 40)
			playsound(src, 'sound/arcade/boom.ogg', 50, TRUE, extrarange = -3)
		else
			playsound(src, 'sound/arcade/hit.ogg', 50, TRUE, extrarange = -3)

	timer_id = addtimer(CALLBACK(src, PROC_REF(enemy_action),player_stance,user),1 SECONDS,TIMER_STOPPABLE)
	gameover_check(user)

///the enemy turn, the enemy's action entirely depend on their current passive and a teensy tiny bit of randomness
/obj/machinery/computer/arcade/battle/proc/enemy_action(player_stance,mob/user)
	var/list/list_temp = list()

	switch(LAZYLEN(last_three_move)) //we keep the last three action of the player in a list here
		if(0 to 2)
			LAZYADD(last_three_move, player_stance)
		if(3)
			for(var/i in 1 to 2)
				last_three_move[i] = last_three_move[i + 1]
			last_three_move[3] = player_stance

		if(4 to INFINITY)
			last_three_move = null //this shouldn't even happen but we empty the list if it somehow goes above 3

	var/enemy_stance
	var/attack_amount = rand(8,10) //making the attack amount not vary too much so that it's easier to see if the enemy has a shotgun

	if(player_stance == "defend")
		attack_amount -= 5

	//if emagged, cuban pete will set up a bomb acting up as a timer. when it reaches 0 the player fucking dies
	if(obj_flags & EMAGGED)
		switch(bomb_cooldown--)
			if(18)
				list_temp += "<br><center><h3>[enemy_name] берёт два баллона и соединяет их вместе, что он задумал?<center><h3>"
			if(15)
				list_temp += "<br><center><h3>[enemy_name] добавляет пульт к баллону... о боже, это бомба?!<center><h3>"
			if(12)
				list_temp += "<br><center><h3>[enemy_name] бросает бомбу рядом с вами, вы слишком напуганы, чтобы её поднять.<center><h3>"
			if(6)
				list_temp += "<br><center><h3>Рука [enemy_name] касается пульта от бомбы, у вас сердце ушло в пятки.<center><h3>"
			if(2)
				list_temp += "<br><center><h3>[enemy_name] сейчас нажмёт кнопку! Сейчас или никогда!<center><h3>"
			if(0)
				player_hp -= attack_amount * 1000 //hey it's a maxcap we might as well go all in

	//yeah I used the shotgun as a passive, you know why? because the shotgun gives +5 attack which is pretty good
	if(LAZYACCESS(enemy_passive, "shotgun"))
		if(weakpoint_check("shotgun","defend","defend","power_attack"))
			list_temp += "<br><center><h3>Вам удалось обезоружить [enemy_name] внезапной мощной атакой и расстрелять из его дробовика!<center><h3> "
			enemy_hp -= 10
			chosen_weapon = "пустой дробовик"
		else
			attack_amount += 5

	//heccing chonker passive, only gives more HP at the start of a new game but has one of the hardest weakpoint to trigger.
	if(LAZYACCESS(enemy_passive, "chonker"))
		if(weakpoint_check("chonker","attack","attack","power_attack"))
			list_temp += "<br><center><h3>После двух атак ваша мощная атака опрокидывает [enemy_name] под тяжестью его собственного веса!<center><h3> "
			enemy_hp -= 30

	//smart passive trait, mainly works in tandem with other traits, makes the enemy unable to be counter_attacked
	if(LAZYACCESS(enemy_passive, "smart"))
		if(weakpoint_check("smart","defend","defend","attack"))
			list_temp += "<br><center><h3>[enemy_name] сбит с толку вашей нелогичной стратегией!<center><h3> "
			attack_amount -= 5

		else if(attack_amount >= player_hp)
			player_hp -= attack_amount
			list_temp += "<br><center><h3>[enemy_name] понимает, что вы на грани смерти и добивает вас своим [chosen_weapon]!<center><h3>"
			enemy_stance = "attack"

		else if(player_stance == "counter_attack")
			list_temp += "<br><center><h3>[enemy_name] не клюёт на вашу уловку.<center><h3> "
			if(LAZYACCESS(enemy_passive, "short_temper"))
				list_temp += "Однако сдерживание ненависти к вам всё равно бьёт по его здоровью!"
				enemy_hp -= 5
				enemy_mp -= 5
			enemy_stance = "defensive"

	//short temper passive trait, gets easily baited into being counter attacked but will bypass your counter when low on HP
	if(LAZYACCESS(enemy_passive, "short_temper"))
		if(weakpoint_check("short_temper","counter_attack","counter_attack","counter_attack"))
			list_temp += "<br><center><h3>[enemy_name] в ярости от ваших контратак и устраивает истерику!<center><h3>"
			enemy_hp -= attack_amount

		else if(player_stance == "counter_attack")
			if(!(LAZYACCESS(enemy_passive, "smart")) && enemy_hp > 30)
				list_temp += "<br><center><h3>[enemy_name] попался на уловку и получил контратаку на [attack_amount * 2] урона!<center><h3>"
				player_hp -= attack_amount
				enemy_hp -= attack_amount * 2
				enemy_stance = "attack"

			else if(enemy_hp <= 30) //will break through the counter when low enough on HP even when smart.
				list_temp += "<br><center><h3>[enemy_name] устал от ваших уловок и пробивает вашу контратаку своим [chosen_weapon]!<center><h3>"
				player_hp -= attack_amount
				enemy_stance = "attack"

		else if(!enemy_stance)
			var/added_temp

			if(prob(80))
				added_temp = "вас на [attack_amount + 5] урона!"
				player_hp -= attack_amount + 5
				enemy_stance = "attack"
			else
				added_temp = "стену, разбивая себе череп и теряя [attack_amount] хп!" //[enemy_name] you have a literal dent in your skull
				enemy_hp -= attack_amount
				enemy_stance = "attack"

			list_temp += "<br><center><h3>[enemy_name] скрежещет зубами и несётся прямо в [added_temp]<center><h3>"

	//in the case none of the previous passive triggered, Mainly here to set an enemy stance for passives that needs it like the magical passive.
	if(!enemy_stance)
		enemy_stance = pick("attack","defensive")
		if(enemy_stance == "attack")
			player_hp -= attack_amount
			list_temp += "<br><center><h3>[enemy_name] атакует вас на [attack_amount] урона своим [chosen_weapon]<center><h3>"
			if(player_stance == "counter_attack")
				enemy_hp -= attack_amount * 2
				list_temp += "<br><center><h3>Вы контратакуете [enemy_name] и наносите [attack_amount * 2] урона!<center><h3>"

		if(enemy_stance == "defensive" && enemy_mp < 15)
			list_temp += "<br><center><h3>[enemy_name] берёт паузу, чтобы восстановить мп!<center><h3> "
			enemy_mp += attack_amount

		else if (enemy_stance == "defensive" && enemy_mp >= 15 && !(LAZYACCESS(enemy_passive, "magical")))
			list_temp += "<br><center><h3>[enemy_name] быстро лечится на 5 хп!<center><h3> "
			enemy_mp -= 15
			enemy_hp += 5

	//magical passive trait, recharges MP nearly every turn it's not blasting you with magic.
	if(LAZYACCESS(enemy_passive, "magical"))
		if(player_mp >= 50)
			list_temp += "<br><center><h3>Огромное количество накопленной магической энергии выбивает [enemy_name] из равновесия!<center><h3>"
			enemy_mp = 0
			LAZYREMOVE(enemy_passive, "magical")
			pissed_off++

		else if(LAZYACCESS(enemy_passive, "smart") && player_stance == "counter_attack" && enemy_mp >= 20)
			list_temp += "<br><center><h3>[enemy_name] бьёт вас магией издалека на 10 урона до того, как вы успели контратаковать!<center><h3>"
			player_hp -= 10
			enemy_mp -= 20

		else if(enemy_hp >= 20 && enemy_mp >= 40 && enemy_stance == "defensive")
			list_temp += "<br><center><h3>[enemy_name] обрушивает на вас магический удар издалека!<center><h3>"
			enemy_mp -= 40
			player_hp -= 30
			enemy_stance = "attack"

		else if(enemy_hp < 20 && enemy_mp >= 20 && enemy_stance == "defensive") //it's a pretty expensive spell so they can't spam it that much
			list_temp += "<br><center><h3>[enemy_name] лечится магией и восстанавливает 20 хп!<center><h3>"
			enemy_hp += 20
			enemy_mp -= 30
		else
			list_temp += "<br><center><h3>Магическая природа [enemy_name] позволяет ему восстановить мп!<center><h3>"
			enemy_mp += attack_amount

	//poisonous passive trait, while it's less damage added than the shotgun it acts up even when the enemy doesn't attack at all.
	if(LAZYACCESS(enemy_passive, "poisonous"))
		if(weakpoint_check("poisonous","attack","attack","attack"))
			list_temp += "<br><center><h3>Ваш шквал атак отбрасывает ядовитый газ обратно на [enemy_name] и заставляет его задыхаться!<center><h3> "
			enemy_hp -= 5
		else
			list_temp += "<br><center><h3>Вонючее дыхание [enemy_name] наносит вам 3 урона!<center><h3> "
			player_hp -= 3

	//if all passive's weakpoint have been triggered, set finishing_move to TRUE
	if(pissed_off >= max_passive && !finishing_move)
		list_temp += "<br><center><h3>Вы достаточно ослабили [enemy_name], чтобы обнажить его слабое место — следующая атака нанесёт в 10 раз больше урона!<center><h3> "
		finishing_move = TRUE

	playsound(src, 'sound/arcade/heal.ogg', 50, TRUE, extrarange = -3)

	battle_log += list_temp
	gameover_check(user)
	SStgui.update_uis(src)
	blocked = FALSE


/obj/machinery/computer/arcade/battle/proc/gameover_check(mob/user)
	var/xp_gained = 0
	if(enemy_hp <= 0)
		if(!gameover)
			if(timer_id)
				deltimer(timer_id)
				timer_id = null
			if(player_hp <= 0)
				player_hp = 1 //let's just pretend the enemy didn't kill you so not both the player and enemy look dead.
			gameover = TRUE
			blocked = FALSE
			battle_log += "[enemy_name] повержен! Победа!"
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)

			if(obj_flags & EMAGGED)
				new /obj/effect/spawner/newbomb/timer/syndicate(loc)
				new /obj/item/clothing/head/collectable/petehat(loc)
				message_admins("[ADMIN_LOOKUPFLW(usr)] перебомбил Кубинца Пита и получил бомбу.")
				log_game("[key_name(usr)] перебомбил Кубинца Пита и получил бомбу.")
				Reset()
				obj_flags &= ~EMAGGED
				xp_gained += 100
			else
				prizevend(user)
				xp_gained += 50
			SSblackbox.record_feedback("nested tally", "arcade_results", 1, list("win", (obj_flags & EMAGGED ? "emagged":"normal")))

	else if(player_hp <= 0)
		if(timer_id)
			deltimer(timer_id)
			timer_id = null
		gameover = TRUE
		battle_log += "Вы были разгромлены! ИГРА ОКОНЧЕНА"
		playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
		xp_gained += 10//pity points
		if(obj_flags & EMAGGED)
			var/mob/living/living_user = user
			if (istype(living_user))
				living_user.gib()
		SSblackbox.record_feedback("nested tally", "arcade_results", 1, list("loss", "hp", (obj_flags & EMAGGED ? "emagged":"normal")))

	// if(gameover)
	// 	user?.mind?.adjust_experience(/datum/skill/gaming, xp_gained+1)//always gain at least 1 point of XP


///used to check if the last three move of the player are the one we want in the right order and if the passive's weakpoint has been triggered yet
/obj/machinery/computer/arcade/battle/proc/weakpoint_check(passive,first_move,second_move,third_move)
	if(LAZYLEN(last_three_move) < 3)
		return FALSE

	if(last_three_move[1] == first_move && last_three_move[2] == second_move && last_three_move[3] == third_move && LAZYACCESS(enemy_passive, passive))
		LAZYREMOVE(enemy_passive, passive)
		pissed_off++
		return TRUE
	else
		return FALSE


/obj/machinery/computer/arcade/battle/Destroy()
	enemy_passive = null
	weapons = null
	last_three_move = null
	battle_log = null
	return ..() //well boys we did it, lists are no more

/obj/machinery/computer/arcade/battle/examine_more(mob/user)
	var/list/msg = list("<span class='notice'><i>Вы замечаете надписи, нацарапанные на боку [src]...</i></span>")
	msg += "\t<span class='info'>умный -> защита, защита, лёгкая атака</span>"
	msg += "\t<span class='info'>дробовик -> защита, защита, мощная атака</span>"
	msg += "\t<span class='info'>вспыльчивый -> контратака, контратака, контратака</span>"
	msg += "\t<span class='info'>ядовитый -> лёгкая атака, лёгкая атака, лёгкая атака</span>"
	msg += "\t<span class='info'>толстяк -> лёгкая атака, лёгкая атака, мощная атака</span>"
	return msg

/obj/machinery/computer/arcade/battle/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='warning'>Из динамиков автомата начинает звучать завораживающая Румба!</span>")
	battle_log = list("Если вы умрёте в игре — вы умрёте по-настоящему!")
	max_passive = 6
	bomb_cooldown = 18
	var/gamerSkill = 0
	// if(usr?.mind)
	// 	gamerSkill = usr.mind.get_skill_level(/datum/skill/gaming)
	enemy_setup(gamerSkill)
	enemy_hp += 100 //extra HP just to make cuban pete even more bullshit
	enemy_max_hp += 100
	player_hp += 30 //the player will also get a few extra HP in order to have a fucking chance
	player_max_hp += 30

	gameover = FALSE

	obj_flags |= EMAGGED

	enemy_name = "Кубинец Пит"
	name = "Перебомби Кубинца Пита"

	SStgui.update_uis(src)
	return TRUE
