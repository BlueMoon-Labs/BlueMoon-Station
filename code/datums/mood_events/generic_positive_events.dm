
/datum/mood_event/hug
	description = "<span class='nicegreen'>Обожаю обнимашки!</span>\n"
	mood_change = 1
	timeout = 2 MINUTES

/datum/mood_event/arcade
	description = "<span class='nicegreen'>Эта аркадная игра мне не ровень!</span>\n"
	mood_change = 3
	timeout = 3000

/datum/mood_event/blessing
	mood_change = 3
	timeout = 3000

/datum/mood_event/blessing/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Я благословлен[owner_mob.ru_a()].</span>\n"

/datum/mood_event/book_nerd
	description = "<span class='nicegreen'>Это была отличная книга.</span>\n"
	mood_change = 3
	timeout = 3000

/datum/mood_event/exercise
	description = "<span class='nicegreen'>Тренировка позволила мне выработать эндорфин!</span>\n"
	mood_change = 3
	timeout = 3000

/datum/mood_event/pet_animal
	description = "<span class='nicegreen'>Животные такие милые! Не могу перестать их гладить!</span>\n"
	mood_change = 5
	timeout = 5 MINUTES

/datum/mood_event/pet_animal/add_effects(mob/animal)
	description = "<span class='nicegreen'>[animal.name] - так[animal.ru_aya_oy()] мил[animal.ru_aya()]! Не могу перестать [animal.ru_ego()] гладить!</span>\n"

/datum/mood_event/honk
	description = "<span class='nicegreen'>Может, клоуны и не такие уж и плохие? Хонк!</span>\n"
	mood_change = 2
	timeout = 2400

/datum/mood_event/bshonk
	description = "<span class='nicegreen'>Квантовая механика может быть как весёлой, так и глупой! Хонк!</span>\n"
	mood_change = 6
	timeout = 4800

/datum/mood_event/perform_cpr
	description = "<span class='nicegreen'>Спасать чужие жизни - прекрасно.</span>\n"
	mood_change = 6
	timeout = 3000

/datum/mood_event/oblivious
	description = "<span class='nicegreen'>Какой чудесный день.</span>\n"
	mood_change = 3

/datum/mood_event/jolly
	description = "<span class='nicegreen'>Радуюсь безо всякой причины!</span>\n"
	mood_change = 6
	timeout = 2 MINUTES

/datum/mood_event/focused
	description = "<span class='nicegreen'>У меня есть цель, и я достигну её во что бы то ни стало!</span>\n" //Used for syndies, nukeops etc so they can focus on their goals
	mood_change = 12
	hidden = TRUE

/datum/mood_event/revolution
	description = "<span class='nicegreen'>НАШЕ ДЕЛО ПРАВОЕ! ПОБЕДА БУДЕТ ЗА РЕВОЛЮЦИЕЙ!</span>\n"
	mood_change = 3
	hidden = TRUE

/datum/mood_event/cult
	mood_change = 40 //maybe being a cultist isnt that bad after all
	hidden = TRUE

/datum/mood_event/cult/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Я узрел[owner_mob.ru_a()] правду. Восславьтесь же, высшие силы!</span>\n"

/datum/mood_event/heretics
	description = "<span class='nicegreen'>ЧЕМ СИЛЬНЕЕ Я ВОЗВЫШАЮСЬ, ТЕМ ЛУЧШЕ ВИЖУ.</span>\n"
	mood_change = 12 //maybe being a cultist isnt that bad after all
	hidden = TRUE

/datum/mood_event/family_heirloom
	description = "<span class='nicegreen'>Моя семейная реликвия в безопасности, рядом со мной.</span>\n"
	mood_change = 1

/datum/mood_event/goodmusic
	description = "<span class='nicegreen'>В этой музыке что-то есть.</span>\n"
	mood_change = 3
	timeout = 600

/datum/mood_event/chemical_euphoria
	description = "<span class='nicegreen'>Хи...хи-хи-хи...хи-хи-ха-ха...</span>\n"
	mood_change = 4

/datum/mood_event/chemical_laughter
	description = "<span class='nicegreen'>Смех - лучшее лекарство! Или нет?</span>\n"
	mood_change = 4
	timeout = 3 MINUTES

/datum/mood_event/chemical_superlaughter
	description = "<span class='nicegreen'>*ЗАДЫХАЮСЬ ОТ СМЕХА*</span>\n"
	mood_change = 12
	timeout = 3 MINUTES

/datum/mood_event/betterhug
	description = "<span class='nicegreen'>Кто-то оказался очень добр ко мне.</span>\n"
	mood_change = 3
	timeout = 3000

/datum/mood_event/betterhug/add_effects(mob/friend)
	description = "<span class='nicegreen'>[friend.name] был[friend.ru_a()] очень добр[friend.ru_a()] ко мне.</span>\n"

/datum/mood_event/besthug
	description = "<span class='nicegreen'>Кто-то очень крутой рядом, он заставляет меня переполняться счастьем!</span>\n"
	mood_change = 5
	timeout = 3000

/datum/mood_event/besthug/add_effects(mob/friend)
	description = "<span class='nicegreen'>Так классно, что [friend.name] находится рядом. Не могу нарадоваться!</span>\n"

/datum/mood_event/happy_empath
	description = "<span class='warning'>Кто-то неподалеку пребывает в хорошем настроении!</span>\n"
	mood_change = 3
	timeout = 600

/datum/mood_event/happy_empath/add_effects(var/mob/happytarget)
	description = "<span class='nicegreen'>Позитив [happytarget.name] распространяется на окружающих словно зараза!</span>\n"

/datum/mood_event/headpat
	description = "<span class='nicegreen'>Поглаживания по голове прекрасны.</span>\n"
	mood_change = 2
	timeout = 2 MINUTES

/datum/mood_event/hugbox
	mood_change = 1
	timeout = 2 MINUTES

/datum/mood_event/hugbox/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Недавно я обнял[owner_mob.ru_a()] коробку обнимашек.</span>\n"

/datum/mood_event/plushpet
	mood_change = 1
	timeout = 3000

/datum/mood_event/plushpet/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Недавно я погладил[owner_mob.ru_a()] мягкую игрушку.</span>\n"

/datum/mood_event/plushplay
	mood_change = 3
	timeout = 3000

/datum/mood_event/plushplay/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Недавно я поиграл[owner_mob.ru_a()] с мягкой игрушкой.</span>\n"

/datum/mood_event/breakfast
	description = "<span class='nicegreen'>Нет ничего лучше вкусного завтрака в начале рабочей смены.</span>\n"
	mood_change = 2
	timeout = 15 MINUTES

/datum/mood_event/nanite_happiness
	description = "<span class='nicegreen robot'>+++++++УЛУЧШЕНИЕ СЧАСТЬЯ+++++++</span>\n"
	mood_change = 7

/datum/mood_event/nanite_happiness/add_effects(message)
	description = "<span class='nicegreen robot'>+++++++[message]+++++++</span>\n"

/datum/mood_event/area
	description = "" //Fill this out in the area
	mood_change = 0
//Power gamer stuff below
/datum/mood_event/drankblood
	mood_change = 10
	timeout = 900

/datum/mood_event/drankblood/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Недавно я отведал[owner_mob.ru_a()] сладостной крови.</span>\n"

/datum/mood_event/coffinsleep
	mood_change = 8
	timeout = 1200

/datum/mood_event/coffinsleep/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Недавно я поспал[owner_mob.ru_a()] в гробу. Чувствую, будто заново родил[owner_mob.ru_sya()].</span>\n"

//Cursed stuff below.

/datum/mood_event/orgasm
	mood_change = 3
	timeout = 3 MINUTES

/datum/mood_event/orgasm/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='userlove'>Я кончил[owner_mob.ru_a()]!</span>\n" //funny meme haha

/datum/mood_event/fedpred
	mood_change = 3

/datum/mood_event/fedpred/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Я кого-то сожрал[owner_mob.ru_a()]!</span>\n"

/datum/mood_event/fedprey
	description = "<span class='nicegreen'>А здесь довольно уютно.</span>\n"
	mood_change = 3

/datum/mood_event/hope_lavaland
	description = "<span class='nicegreen'>Какая своеобразная эмблема. Даёт мне надежду на будущее.</span>\n"
	mood_change = 5

/datum/mood_event/artok
	description = "<span class='nicegreen'>Прекрасно видеть, как окружающие творят на холсте.</span>\n"
	mood_change = 2
	timeout = 2 MINUTES

/datum/mood_event/artgood
	description = "<span class='nicegreen'>Какой воодушевляющий рисунок. Я его на какое-то время запомню.</span>\n"
	mood_change = 3
	timeout = 3 MINUTES

/datum/mood_event/artgreat
	description = "<span class='nicegreen'>Этот рисунок был так прекрасен, что заставил меня поверить в величие человечества. Это многое говорит о нашем обществе.</span>\n"
	mood_change = 4
	timeout = 4 MINUTES

/datum/mood_event/cleared_stomach
	description = "<span class='nicegreen'>Хорошо, что та дрянь теперь не в моем желудке.</span>\n"
	mood_change = 3

/datum/mood_event/high_five
	description = "<span class='nicegreen'>Я люблю давать пять!</span>\n"
	mood_change = 2
	timeout = 45 SECONDS

/datum/mood_event/high_ten
	description = "<span class='nicegreen'>КРУТО! ЛАДУШКИ!</span>\n"
	mood_change = 3
	timeout = 45 SECONDS

/datum/mood_event/down_low
	description = "<span class='nicegreen'>ХА! Какая чушь, у них и шанса то не было</span>\n"
	mood_change = 4
	timeout = 1.5 MINUTES

/datum/mood_event/sacrifice_good
	description = "<span class='nicegreen'>Боги довольны моим подношением!</span>\n"
	mood_change = 5
	timeout = 3 MINUTES

/datum/mood_event/kiss
	description = span_nicegreen("Кто-то поцеловал меня. Должно быть, я настоящая находка!\n")
	mood_change = 4.5
	timeout = 2 MINUTES

//BM Add
/datum/mood_event/knotting_satisfied
	description = span_love("Всё внутри переполнено теплом и наслаждением... Узел держит вас вместе.\n")
	mood_change = 3
	timeout = 4 MINUTES

/datum/mood_event/knotting_linked
	description = span_love("Сладкое ощущение связи и близости... Ваши тела едины.\n")
	mood_change = 2
	timeout = 4 MINUTES

/datum/mood_event/maso_medicine
	description = span_love("Лекарства делают своё дело. Боль от неё крайне приятная.\n")
	mood_change = 2
	timeout = 1 MINUTES
