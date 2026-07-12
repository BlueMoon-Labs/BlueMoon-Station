//Components: Used in scripture.
/obj/item/clockwork/component
	name = "meme component"
	desc = "Фрагмент известного мема."
	clockwork_desc = null
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/component_id //What the component is identified as
	var/cultist_message = "Ты не достоин этого мема." //Showed to Nar'Sian cultists if they pick up the component in addition to chaplains
	var/list/servant_of_ratvar_messages = list("ayy" = FALSE, "lmao" = TRUE) //Fluff, shown to servants of Ratvar on a low chance, if associated value is TRUE, will automatically apply ratvarian
	var/message_span = "heavy_brass"

/obj/item/clockwork/component/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='[get_component_span(component_id)]'>Вы можете активировать этот компонент, находящийся у вас в руке, чтобы разбить его для получения энергии.</span>"

/obj/item/clockwork/component/attack_self(mob/living/user)
	if(is_servant_of_ratvar(user))
		user.visible_message("<span class='notice'>[user] ломает [src] в [user.ru_ego()] руке!</span>", \
		"<span class='alloy'>Вы ломаете [src], поглощая уходящую энергию для использования в качестве электроэнергии.</span>")
		playsound(user, 'sound/effects/pop_expl.ogg', 50, TRUE)
		adjust_clockwork_power(POWER_WALL_TOTAL)
		qdel(src)

/obj/item/clockwork/component/pickup(mob/living/user)
	..()
	if(iscultist(user) || (user.mind && user.mind.isholy))
		to_chat(user, "<span class='[message_span]'>[cultist_message]</span>")
		if(user.mind && user.mind.isholy)
			to_chat(user, "<span class='boldannounce'>Сила твоей веры плавит [src]!</span>")
			var/obj/item/stack/ore/slag/wrath = new /obj/item/stack/ore/slag
			qdel(src)
			user.put_in_active_hand(wrath)
	if(is_servant_of_ratvar(user) && prob(20))
		var/pickedmessage = pick(servant_of_ratvar_messages)
		to_chat(user, "<span class='[message_span]'>[servant_of_ratvar_messages[pickedmessage] ? "[text2ratvar(pickedmessage)]" : pickedmessage]</span>")

/obj/item/clockwork/component/belligerent_eye
	name = "belligerent eye"
	desc = "Латунная конструкция с вращающимся красным центром. Словно она ищет, что бы поранить."
	icon_state = "belligerent_eye"
	component_id = BELLIGERENT_EYE
	cultist_message = "Глаз бросает на вас взгляд, полный ненависти."
	servant_of_ratvar_messages = list("\"...\"" = FALSE, "На мгновение твой разум наполняется крайне жестокими мыслями." = FALSE, "\"...Умри.\"" = TRUE)
	message_span = "neovgre"

/obj/item/clockwork/component/belligerent_eye/blind_eye
	name = "blind eye"
	desc = "Тяжелый латунный глаз, красная радужка которого потемнела."
	clockwork_desc = "Разбитый глазной охранник, весь в вмятинах."
	icon_state = "blind_eye"
	cultist_message = "Глаз бросает на тебя взгляд, полный яростной ненависти, а затем погружается в темноту."
	servant_of_ratvar_messages = list("Глаз мерцает, а затем погружается в темноту." = FALSE, "Вы чувствуете, что за вами наблюдают." = FALSE, "\"...\"" = FALSE)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/clockwork/component/belligerent_eye/lens_gem
	name = "lens gem"
	desc = "Небольшой розоватый самоцвет. Он необычно отражает свет, словно светится."
	clockwork_desc = "Драгоценный камень из линзы стража."
	icon_state = "lens_gem"
	cultist_message = "На мгновение драгоценный камень потемнел и стал холодным, но затем вновь засиял своим обычным светом."
	servant_of_ratvar_messages = list("\"Отвратительный провал.\"" = TRUE, "Вы чувствуете на себе пристальный взгляд." = FALSE, "\"Слабаки.\"" = TRUE, "\"Жалкие оправдания.\"" = TRUE)
	w_class = WEIGHT_CLASS_TINY
	light_range = 1.4
	light_power = 0.4
	light_color = "#F42B9D"

/obj/item/clockwork/component/vanguard_cogwheel
	name = "vanguard cogwheel"
	desc = "Прочная латунная шестерня со слабо светящимся голубым камнем в центре."
	icon_state = "vanguard_cogwheel"
	component_id = VANGUARD_COGWHEEL
	cultist_message = "\"Помолись своему богу, чтобы мы никогда не встретились.\""
	servant_of_ratvar_messages = list("\"Береги себя, дитя.\"" = FALSE, "Вы испытываете необъяснимое чувство комфорта." = FALSE, "\"Никогда не забывай: боль это временно. А то, что ты делаешь для Юстициара - вечно.\"" = FALSE)
	message_span = "inathneq"

/obj/item/clockwork/component/vanguard_cogwheel/onyx_prism
	name = "onyx prism"
	desc = "Ониксовая призма с небольшим отверстием. Она очень тяжелая."
	clockwork_desc = "Сломанная призма из удлиняющей призмы."
	icon_state = "onyx_prism"
	cultist_message = "Призма становится невыносимо горячей в руках."
	servant_of_ratvar_messages = list("Призма не становится легче." = FALSE, "\"Так что... ты ещё не провалился. Не теряй надежду, дитя.\"" = TRUE, \
	"\"Пусть лучше ломаются эти машины, чем ты.\"" = TRUE)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/clockwork/component/geis_capacitor
	name = "geis capacitor"
	desc = "Странная холодная латунная штуковина. Похоже, ей совсем не нравится, когда её берут в руки."
	icon_state = "geis_capacitor"
	component_id = GEIS_CAPACITOR
	cultist_message = "\"Постарайся не сойти с ума - он мне еще пригодится. Хе-хе...\""
	servant_of_ratvar_messages = list("\"Отвратительно.\"" = FALSE, "\"Ну, разве ты не любознательный парень?\"" = FALSE, "Какое-то зловещее ощущение наполняет твой разум, а затем исчезает." = FALSE, \
	"\"То, что Ратвару приходится полагаться на таких простаков, как ты, просто возмутительно.\"" = FALSE)
	message_span = "sevtug"

/obj/item/clockwork/component/geis_capacitor/fallen_armor
	name = "fallen armor"
	desc = "Безжизненные куски брони. Они имеют странную форму и не подойдут тебе по размеру."
	clockwork_desc = "Броня бывшего механического мародера. <b>Может служить заменой конденсатору Гейса.</b>"
	icon_state = "fallen_armor"
	cultist_message = "Из глазницы маски вырывается красное пламя, а затем погасает."
	servant_of_ratvar_messages = list("Часть доспехов на мгновение отрывается от остальных." = FALSE, "В нагруднике вспыхивает красное пламя, а затем гаснет." = FALSE)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/clockwork/component/geis_capacitor/antennae
	name = "mania motor antennae"
	desc = "Пара помятых и погнутых антенн. Из них постоянно слышен шум статического электричества."
	clockwork_desc = "Антенны от двигателя мании."
	icon_state = "mania_motor_antennae"
	cultist_message = "В вашей голове раздается шум, словно от статического электричества."
	servant_of_ratvar_messages = list("\"Кто это сломал?\"" = TRUE, "\"Это ты их СВОИМИ РУКАМИ сломал?\"" = TRUE, "\"А зачем мы вообще отдали это таким дуракам?\"" = TRUE, \
	"\"По крайней мере, мы можем их как-то использовать - в отличие от тебя.\"" = TRUE)

/obj/item/clockwork/component/replicant_alloy
	name = "replicant alloy"
	desc = "Кусок металла, кажущийся прочным, но на самом деле очень податливый. Создается впечатление, будто он хочет превратиться в нечто большее."
	icon_state = "replicant_alloy"
	component_id = REPLICANT_ALLOY
	cultist_message = "На мгновение сплав принимает облик кричащего лица."
	servant_of_ratvar_messages = list("\"Дела всегда найдутся. Приступай.\"" = FALSE, "\"Безделье хуже, чем работа. За работу!\"" = FALSE, \
	"На мгновение в сплаве появляется четкое изображение Ратвара." = FALSE)
	message_span = "nezbere"

/obj/item/clockwork/component/replicant_alloy/smashed_anima_fragment
	name = "smashed anima fragment"
	desc = "Разбитые куски металла. Повреждены без возможности ремонта и совершенно непригодны для использования."
	clockwork_desc = "Печальные останки фрагмента анимы."
	icon_state = "smashed_anime_fragment"
	cultist_message = "Осколки на мгновение задрожали в твоих руках."
	servant_of_ratvar_messages = list("\"...продолжай бороться...\"" = FALSE, "\"...где я...?\"" = FALSE, "\"...верни меня... обратно...\"" = FALSE)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/clockwork/component/replicant_alloy/replication_plate
	name = "replication plate"
	desc = "A flat, heavy disc of metal with a triangular formation on its surface."
	clockwork_desc = "The replication plate from a tinkerer's daemon."
	icon_state = "replication_plate"
	cultist_message = "The plate shudders in your hands, as though trying to get away."
	servant_of_ratvar_messages = list("\"Put this in a slab and get back to work.\"" = FALSE, "\"Worse servants than you have held these.\"" = TRUE, \
	"\"It would be wise to protect these better, friend.\"" = TRUE)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/clockwork/component/hierophant_ansible
	name = "hierophant ansible"
	desc = "Some sort of transmitter? It seems as though it's trying to say something."
	icon_state = "hierophant_ansible"
	component_id = HIEROPHANT_ANSIBLE
	cultist_message = "\"Gur obff fnlf vg'f abg ntnvafg gur ehyrf gb-xvyy lbh.\""
	servant_of_ratvar_messages = list("\"Exile is such a bore. There's nothing I can hunt in here.\"" = TRUE, "\"What's keeping you? I want to go kill something.\"" = TRUE, \
	"\"HEHEHEHEHEHEH!\"" = FALSE, "\"If I killed you fast enough, do you think the boss would notice?\"" = TRUE)
	message_span = "nzcrentr"

/obj/item/clockwork/component/hierophant_ansible/obelisk
	name = "obelisk prism"
	desc = "Призма, которая время от времени ярко светится. Кажется, что её как будто нет."
	clockwork_desc = "Призма из часового обелиска."
	cultist_message = "Призма начинает яростно мерцать в ваших руках, а затем снова приобретает обычное сияние."
	servant_of_ratvar_messages = list("На мгновение раздается характерный звуковой сигнал сети Иерофант." = FALSE, "\"Сбо'й тра'нсля'ции И'ерофа'нта.\"" = TRUE, \
	"Обелиск яростно мерцает, словно пытаясь открыть портал." = FALSE, "\"Оши'бка про'странст'венного раз'лома.\"" = TRUE)
	icon_state = "obelisk_prism"
	w_class = WEIGHT_CLASS_NORMAL

//Shards of Alloy, suitable only as a source of power for a replica fabricator.
/obj/item/clockwork/alloy_shards
	name = "replicant alloy shards"
	desc = "Осколки какого-то странного, податливого металла. Иногда они шевелятся и, кажется, светятся."
	clockwork_desc = "Осколки сломанного сплава репликантов."
	icon_state = "alloy_shards2"
	base_icon_state = "alloy_shards"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/randomsinglesprite = FALSE
	var/randomspritemax = 2
	var/sprite_shift = 9

/obj/item/clockwork/alloy_shards/Initialize(mapload)
	. = ..()
	if(randomsinglesprite)
		replace_name_desc()
		icon_state = "[base_icon_state][rand(1, randomspritemax)]"
		pixel_x = rand(-sprite_shift, sprite_shift)
		pixel_y = rand(-sprite_shift, sprite_shift)

/obj/item/clockwork/alloy_shards/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='brass'>Может использоваться производителем реплик в качестве источника энергии.</span>"

/obj/item/clockwork/alloy_shards/proc/replace_name_desc()
	name = "replicant alloy shard"
	desc = "Осколок какого-то странного, податливого металла. Он время от времени шевелится и, кажется, светится."
	clockwork_desc = "Осколки сломанного сплава репликантов."

/obj/item/clockwork/alloy_shards/clockgolem_remains
	name = "clockwork golem scrap"
	desc = "Куча металлолома. Похоже, он поврежден так, что его уже не починить."
	clockwork_desc = "Печальные останки механического голема. Он сломан безвозвратно."
	icon_state = "clockgolem_dead"
	sprite_shift = 0

/obj/item/clockwork/alloy_shards/large
	w_class = WEIGHT_CLASS_TINY
	randomsinglesprite = TRUE
	icon_state = "shard_large"
	sprite_shift = 9

/obj/item/clockwork/alloy_shards/medium
	w_class = WEIGHT_CLASS_TINY
	randomsinglesprite = TRUE
	icon_state = "shard_medium"
	sprite_shift = 10

/obj/item/clockwork/alloy_shards/medium/gear_bit
	randomspritemax = 4
	icon_state = "gear_bit"
	sprite_shift = 12

/obj/item/clockwork/alloy_shards/medium/gear_bit/replace_name_desc()
	name = "gear bit"
	desc = "Осколок сломанной шестерни. Тебе это нужно."
	clockwork_desc = "Осколок сломанной шестерни."

/obj/item/clockwork/alloy_shards/medium/gear_bit/large //gives more power

/obj/item/clockwork/alloy_shards/medium/gear_bit/large/replace_name_desc()
	..()
	name = "complex gear bit"

/obj/item/clockwork/alloy_shards/small
	w_class = WEIGHT_CLASS_TINY
	randomsinglesprite = TRUE
	randomspritemax = 3
	icon_state = "shard_small"
	sprite_shift = 12

/obj/item/clockwork/alloy_shards/pinion_lock
	name = "pinion lock"
	desc = "Помятая и поцарапанная шестерня. Она очень тяжелая."
	clockwork_desc = "Неисправный фиксатор шестерни для шлюзов."
	icon_state = "pinion_lock"
