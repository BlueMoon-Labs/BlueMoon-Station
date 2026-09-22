/datum/mod_theme/engineering/default_engineer
	name = "engineering"
	desc = "Инженерный костюм с термо- и электрозащитой. Классика Nakamura Engineering."
	extended_desc = "Классика от Nakamura Engineering, и, несомненно, их путь к славе. Эта модель является \
		улучшением над прототипами первого поколения, созданными ещё до Войны Пустоты, и обладает множеством функций. \
		Модульная гибкость базового дизайна была совмещена с внутренним взрывопоглощающим изоляционным слоем и \
		внешним ударостойким слоем, делая костюм почти неуязвимым даже к экстремальному высоковольтному электричеству. \
		Однако потенциал для модификации остаётся таким же, как у гражданских моделей."
	default_skin = "engineering"
	armor = /datum/armor/mod/engineer
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	allowed = ALLOWED_ENGINERING
	skins = list(
		"engineering" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/engineering/fire_protected/atmospheric
	name = "atmospheric"
	desc = "Атмосфероустойчивый костюм от Nakamura Engineering, обеспечивающий крайне высокую термозащиту по сравнению с инженерным."
	extended_desc = "Модифицированная версия промышленной модели Nakamura Engineering. Эта модель была \
		усилена новейшими жаропрочными сплавами в сочетании с рядом продвинутых теплоотводов. \
		Кроме того, материалы, использованные при создании этого костюма, сделали его крайне стойким к \
		коррозионным газам и жидкостям, что полезно в мире труб. \
		Однако потенциал для модификации остаётся таким же, как у гражданских моделей."
	default_skin = "atmospheric"
	armor = /datum/armor/mod/atmosphere_tech
	skins = list(
		"atmospheric" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/engineering/fire_protected/advanced
	name = "advanced"
	desc = "Продвинутая версия классического костюма Nakamura Engineering, сияющая белой кислото- и огнеупорной полировкой."
	extended_desc = "Флагманская версия промышленной модели Nakamura Engineering и их новейший продукт. \
		Объединяя в себе все функции других промышленных моделей, с взрывостойкостью, почти приближающейся к \
		некоторым сапёрным костюмам, снаружи он покрыт белой полировкой, о которой ходят слухи как о корпоративной тайне. \
		Использованная краска практически полностью невосприимчива к коррозии и, безусловно, выглядит чертовски хорошо. \
		В комплекте предустановлены магнитные ботинки с продвинутой системой автоматического включения и выключения при ходьбе."
	default_skin = "advanced"
	armor = /datum/armor/mod/chief_engineer
	complexity_max = COMMAND_MAX_COMPLEXITY
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"advanced" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/cargo_default/mining
	name = "mining"
	desc = "Высокомощный шахтёрский костюм Nanotrasen, поддерживающий больше модулей при большем расходе энергии."
	extended_desc = "Высокомощный костюм, разработанный Nanotrasen на основе работ Nakamura Engineering. \
		Хотя изначальные проекты создавались для суровых условий астероидной добычи, с встроенной керамической защитой от взрывов, \
		шахтёрские команды с тех пор значительно доработали костюм самостоятельно. Добавлены дополнительные бронепластины, \
		обеспечивающие невероятную защиту от коррозии и термозащиту, достаточную для вулканических условий. \
		Системы также были модернизированы, освободив место для дальнейших модификаций. \
		Однако всё это оказалось изнурительным для батареи и приводов костюма, \
		заставляя его требовать больше энергии взамен."
	default_skin = "mining"
	armor = /datum/armor/mod/mining
	skins = list(
		"mining" = MOD_PRESET_DEFAULT,
		"asteroid" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_medbay/medical
	name = "medical"
	desc = "Лёгкий костюм от DeForest Medical Corporation, обеспечивающий более лёгкое передвижение."
	extended_desc = "Лёгкий костюм, произведённый DeForest Medical Corporation на основе работ \
		Nakamura Engineering. В нём использованы новейшие технологии, чтобы сделать его иммунным к \
		аллергенам, токсинам в воздухе и обычным патогенам. Главное достоинство этого костюма — скорость, \
		достигнутая за счёт сочетания высокомощных сервоприводов с карбоновой конструкцией. Хотя брони здесь очень мало, \
		он невероятно кислотостойкий. Энергопотребление немного выше, чем у гражданских моделей, \
		и он слаб против постукиваний пальцами по стеклу."
	default_skin = "medical"
	armor = /datum/armor/mod/medical
	skins = list(
		"medical" = MOD_PRESET_DEFAULT,
		"corpsman" = MOD_PRESET_DEFAULT,
		"dyne-guardian" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_medbay/rescue
	name = "rescue"
	desc = "Продвинутая версия медицинского костюма DeForest Medical Corporation, предназначенная для быстрого спасения тел из самых опасных условий."
	extended_desc = "Улучшенная бронированная версия медицинского костюма DeForest Medical Corporation, \
		предназначенная для быстрого спасения тел из самых опасных условий. Здесь используются те же продвинутые сервоприводы ног, \
		что и в базовой версии, дарящие парамедикам невероятную скорость, но такие же сервоприводы установлены и в руках. \
		Пользователи способны быстро тащить даже самых тяжёлых членов экипажа, используя этот костюм, \
		при этом оставаясь полностью иммунными к химическим и термическим угрозам. \
		Энергопотребление немного выше, чем у гражданских моделей, и он слаб против постукиваний пальцами по стеклу."
	default_skin = "rescue"
	armor = /datum/armor/mod/paramedic
	skins = list(
		"rescue" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/research
	name = "research"
	desc = "Частный военный сапёрный костюм от Aussec Armory, предназначенный для исследования взрывчатки. Громоздкий, но ёмкий."
	extended_desc = "Частный военный сапёрный костюм от Aussec Armory, созданный на основе работ Nakamura Engineering. \
		Предназначен для исследования взрывчатки, собран невероятно громоздко и с максимальным покрытием. \
		Оснащён встроенным химическим сканирующим массивом, этот костюм использует два слоя пластитановой брони, \
		разделённые инертным слоем для рассеивания кинетической энергии в костюм и от пользователя; \
		превосходя даже лучшие традиционные сапёрные костюмы. Однако, несмотря на иммунитет даже к \
		ракетам и артиллерии, броня не эффективнее стандартных костюмов против \
		других типов оружия и физического урона; а вся взрывостойкость в основном работает, чтобы сохранить пользователя целым, \
		но не живым. Также пользователь обнаружит, что узкие дверные проёмы практически невозможно преодолеть."
	default_skin = "research"
	armor = /datum/armor/mod/research_director
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	hardlight_color = MOD_RESEARCH_COLOR
	allowed = ALLOWED_SCIENCE
	skins = list(
		"research" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_combat/security
	name = "security"
	desc = "Костюм безопасности от Apadyne Technologies, обеспечивающий защиту от ударов и большую скорость за счёт грузоподъёмности."
	extended_desc = "Классика от Apadyne Technologies, эта модель костюма MOD была разработана для быстрого реагирования на \
		враждебные ситуации. Эти костюмы покрыты пластинами, достойными огня и коррозионных сред, \
		и оснащены композитной амортизацией и продвинутой сотовой структурой под обшивкой для защиты \
		от переломов или возможных отрывов. Ноги костюма получили более прочные приводы, \
		позволяющие костюму лучше справляться с весом. Наконец, рукавицы оснащены ударопоглощающим \
		изоляционным слоем, гарантирующим, что пользователь не подвергается риску поражения током. \
		Однако системы, используемые в этих костюмах, устарели более чем на несколько лет, \
		что приводит к общему снижению ёмкости модулей."
	default_skin = "security"
	armor = /datum/armor/mod/security_officer
	skins = list(
		"security" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_combat/security/expeditor
	name = "Vanguard"
	desc = "Армированный МОД, в котором не страшно ступить даже в самые опасные заброшенные станции и обломки кораблей."
	default_skin = "vanguard"
	hardlight_color = "#800080"
	skins = list(
		"vanguard" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_combat/security/blueshied
	name = "Blueshied"
	desc = "Прототип костюма класса Magnate, выданный для использования станционными синими щитами"
	extended_desc = "Прототип костюма класса Magnate, выданный для использования станционными синими щитами, \
		он может похвастаться исключительной защитой своего преемника, жертвуя частью вместимости модулей.\
		Вся защита Magnate — и никакого комфорта! В визоре используется синий свет, скрывающий \
		лицо владельца и придающий его облику внушительность. В отличие от изящного и роскошного дизайна, \
		появившегося позднее, этот костюм ничуть не скрывает своего предназначения: усиленные пластины, наложенные \
		поверх утеплённой внутренней брони, обеспечивают защиту от агрессивных жидкостей, взрывов, \
		огня, электрических разрядов и презрения со стороны остального экипажа."
	default_skin = "praetorian"
	armor = /datum/armor/mod/blueshied
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"praetorian" = MOD_PRESET_DEFAULT,
		"blacksec" = MOD_PRESET_DEFAULT,
		"souless" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/station_combat/security/blueshied/souless
	default_skin = "souless"

/datum/mod_theme/station_combat/security/blueshied/blacksec
	default_skin = "blacksec"

/datum/mod_theme/centcom/safeguard
	name = "safeguard"
	desc = "Продвинутый костюм безопасности от Apadyne Technologies, обеспечивающий большую скорость и огнезащиту по сравнению со стандартной моделью."
	extended_desc = "Продвинутый костюм безопасности от Apadyne Technologies и их новейшая модель. Этот вариант полностью \
		отказался от усиленного стеклянного забрала, заменив его 'взрывозащитным визором', использующим \
		маленькую камеру с левой стороны для отображения внешнего мира пользователю. Бронирование костюма было \
		значительно усилено, особенно в наплечниках, придавая носителю внушительный силуэт. \
		По бокам костюма установлены теплоотводы, а для изоляции от \
		коррозионных сред и внезапных ударов по суставам пользователя применены более совершенные технологии."
	default_skin = "safeguard"
	armor = /datum/armor/mod/head_of_sec
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	complexity_max = STATION_COMBAT_MAX_COMPLEXITY
	skins = list(
		"safeguard" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/centcom/magnate
	name = "magnate"
	desc = "Шикарный, высокозащитный костюм для капитанов Nanotrasen. Ударо-, огне- и кислотостойкий, при этом имеющий большую ёмкость и высокую скорость."
	extended_desc = "Говорят, стоимость работы этого костюма MOD составляет четыреста тысяч кредитов... на двенадцать секунд. \
		Костюм Magnate разработан для защиты, комфорта и роскоши капитанов Nanotrasen. \
		Бортовые воздушные фильтры предварительно запрограммированы на пятьсот различных ароматов, которые можно \
		накачать в шлем, все из них — из высокоэндемичных цветов. В запястье установлены эксклюзивные механические часы Tralex, \
		а комплект Magnate включает углеродные запонки для ношения под костюмом. \
		Боже, в нём даже гранитная отделка. Двойно-секретная краска, которая была тщательно нанесена на корпус, \
		обеспечивает защиту от ударов, огня и самых сильных кислот. Бортовые системы использую мета-позитронное обучение \
		и блюспейс-обработку для поддержки широкого спектра модулей, а для скорости задействованы только лучшие приводы. \
		Сходство с шлемом Gorlex Marauder — чистое совпадение."
	default_skin = "magnate"
	armor = /datum/armor/mod/captain
	skins = list(
		"magnate" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/simple_civilian/cosmohonk
	name = "cosmohonk"
	desc = "Костюм от Honk Ltd. Защищает от низкого юмористического окружения. Большая часть технологий пошла на снижение энергопотребления."
	extended_desc = "Костюм Cosmohonk MOD изначально был разработан для межзвёздной комедии в условиях низкого юмора. \
		Он использует вольфрамовый электрокерамический корпус и хромовые биполяры, покрытые цирконий-борной краской под \
		дерматирелианским субпространственным сплавом. Несмотря на вопиюще очевидные оптронные вакуумные педали привода, \
		эта конкретная модель не использует марганцевые биполярные очистители конденсаторов, слава Хонк-Матери. \
		Всё, что вам известно, — этот костюм загадочно энергоэффективен и слишком пёстрый, чтобы Мим мог его украсть."
	default_skin = "cosmohonk"
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"cosmohonk" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/syndicate
	name = "syndicate"
	desc = "Костюм, разработанный Gorlex Marauders, с бронёй, запрещённой в большей части Spinward Stellar."
	extended_desc = "Продвинутый боевой костюм в зловещей багрово-красной цветовой гамме, произведённый и изготовленный \
		для специальных наёмнических операций. Конструкция представляет собой обтекаемое многослойное покрытие из формованной пластали \
		и композитной керамики, а подкостюмник подбит лёгким гибридным плетением из кевлара и дюраткани \
		для обеспечения достаточной защиты пользователю там, где нет пластин, с нелегальным встроенным абляционным \
		щитовым модулем, питаемым от бортовой ячейки, для сопротивления обычному энергетическому оружию. \
		С него свисает маленькая бирка с надписью: 'Собственность Gorlex Marauders при содействии Cybersun Industries. \
		Все права защищены, вмешательство в костюм аннулирует гарантию."
	default_skin = "syndicate"
	armor = /datum/armor/mod/syndicate_simple
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	ui_theme = "syndicate"
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"syndicate" = MOD_PRESET_DEFAULT,
		"cybersun" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/elite
	name = "elite"
	desc = "Элитный костюм, модернизированный Cybersun Industries, с улучшенными показателями брони."
	extended_desc = "Эволюция синдикатного костюма, отличающийся более массивной конструкцией и матовой чёрной цветовой гаммой, \
		этот костюм производится только для высокопоставленных офицеров Синдиката и элитных ударных групп. \
		Он оснащён дополнительным слоем керамики и кевлара в пластинах, обеспечивающим \
		исключительно лучшую защиту вместе с огне- и кислотостойкостью. С него свисает маленькая бирка с надписью: \
		'Собственность Gorlex Marauders при содействии Cybersun Industries. \
		Все права защищены, вмешательство в костюм аннулирует продолжительность жизни.'"
	default_skin = "elite"
	armor = /datum/armor/mod/syndicate_elite
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	ui_theme = "syndicate"
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"elite"            = MOD_PRESET_DEFAULT,
		"admiral"          = MOD_PRESET_DEFAULT,
		"admiral-cybersun" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/cargo_default/prototype
	name = "prototype"
	desc = "Прототип модульного костюма с приводом от локомотивов. Хоть он и комфортен и имеет большую ёмкость, он остаётся очень громоздким и энерго-неэффективным."
	extended_desc = "Это прототип силового экзоскелета, дизайн, который не видели сотни лет, первый \
		модульный костюм эпохи послевоенной Пустоты, когда-либо безопасно использовавшийся оператором. Эта древняя громыхающая машина всё ещё функционирует, \
		ho в ней отсутствуют некоторые современные удобства из обновлённых разработок Nakamura Engineering. \
		Прежде всего, миоэлектрический слой костюма полностью отсутствует, а сервоприводы почти не \
		помогают равномерно распределять вес по телу носителя, делая его медленным и громоздким в движении. \
		Кроме того, бронепластины так и не были запущены в производство, за исключением плеч, предплечий и шлема; \
		что делает его бесполезным против прямых атак. Внутренний дисплей на лобовом стекле отображается почти нечитаемым голубым цветом, \
		как и подразумевает забрало, не позволяя пользователю видеть на дальние расстояния. \
		Однако способ складывания шлема довольно крутой."
	default_skin = "prototype"
	armor = /datum/armor/mod/mining
	ui_theme = "hackerman"
	skins = list(
		"prototype" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/centcom/responsory
	name = "responsory"
	desc = "Высокоскоростной спасательный костюм от Nanotrasen, предназначенный для команд экстренного реагирования."
	extended_desc = "Обтекаемый костюм дизайна Nanotrasen, эти гладкие чёрные костюмы носят только \
		элитные сотрудники экстренного реагирования, чтобы спасти день. Хотя стройная и ловкая конструкция костюма \
		сокращает использование керамики и аблятивов, снижая защиту, \
		она сохраняет носителя в безопасности от суровой пустоты космоса, не жертвуя ни каплей скорости. \
		Нося его, вы чувствуете крайнее почтение к тьме."
	default_skin = "responsory"
	armor = /datum/armor/mod/ert_red_code
	skins = list(
		"responsory"  = MOD_PRESET_DEFAULT,
		"inquisitory" = MOD_PRESET_DEFAULT,
		"marine"      = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/centcom/apocryphal
	name = "apocryphal"
	desc = "Высокотехнологичный, лишь формально легальный бронированный костюм, созданный совместными усилиями Nanotrasen и Apadyne Technologies."
	extended_desc = "Громоздкий и лишь формально легальный костюм, этот зловещий чёрно-красный MOD-костюм носят только \
		команды чёрных операций Nanotrasen. Если вы видите этот костюм, вы облажались. Совместное творение \
		Apadyne и Nanotrasen — конструкция и модули даруют пользователю надёжную защиту от \
		всего, что может быть в него запущено, а также острые инструменты боевого осознания для его носителя. \
		Использовать ли их — решение самого носителя. \
		На запястье, кажется, есть маленькая гравировка: 'squiddie', милашка."
	default_skin = "apocryphal"
	armor = /datum/armor/mod/deathsquad
	skins = list(
		"apocryphal" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/corporate
	name = "corporate"
	desc = "Шикарный высокотехнологичный костюм для высокопоставленных офицеров Nanotrasen."
	extended_desc = "Ещё более дорогая версия модели Magnate, корпоративный костюм — это термоизолированный, \
		с антикоррозионным покрытием костюм для высокопоставленных офицеров CentCom, оснащённый безупречной защитной бронёй и \
		продвинутыми приводами, кажущийся практически невесомым при включении. Царапание краски этого костюма \
		считается военным преступлением и поводом для немедленной казни на более чем пятидесяти космических станциях Nanotrasen. \
		Сходство с шлемом Gorlex Marauder — чистое совпадение."
	default_skin = "corporate"
	armor = /datum/armor/mod/nanotrasen_representative
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	allowed = ALLOWED_SECURITY
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"corporate" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/debug
	name = "debug"
	desc = "Странно ностальгический."
	extended_desc = "Продвинутый костюм с двумя ионными двигателями, достаточно мощными, чтобы дать гуманоиду полёт. \
		Содержит внутренний самозаряжающийся высокотоковый конденсатор для коротких, мощных взры- \
		Ой, стоп, это на самом деле не костюм для полёта. Бля."
	default_skin = "debug"
	armor = /datum/armor/mod/debug
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	complexity_max = DEBUG_COMPLEXITY
	allowed = ALLOWED_SECURITY
	skins = list(
		"debug" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/debug/administrative
	name = "administrative"
	desc = "Костюм из админиума. Кто придумывает эти тупые названия минералов?"
	extended_desc = "Да, ладно, думаю, это можно назвать ивентом. Но то, что я считаю ивентом, — это что-то на самом деле \
		весёлое и увлекательное для игроков — вместо этого большинство сидели в стороне, мертвы или разобраны на части, в то время как счастливчикам досталось \
		всё веселье. Если это продолжит быть паттерном для ваших \"ивентов\" (Админ-абьюз), \
		будет админ-жалоба. Вы были предупреждены."
	default_skin = "debug"
	resistance_flags = INDESTRUCTIBLE|LAVA_PROOF|FIRE_PROOF|UNACIDABLE|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	cell_drain = DEBUG_LOW_CHARGE_DRAIN
	skins = list(
		"debug" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/inteq_nuclear
	name = "InteQ"
	desc = "Высокотехнологичный боевой костюм, выполненный в зловещих тёмно-синих тонах и изготовленный специально для наёмников, участвующих в специальных операциях. "
	extended_desc = "Высокотехнологичный боевой костюм, выполненный в зловещих тёмно-синих тонах и изготовленный специально для наёмников, участвующих в специальных операциях. Конструкция представляет собой обтекаемую многослойную систему из формованного пласталя и композитной керамики, а нижний слой выполнен из лёгкого кевлара и гибридной ткани «дуратри». На костюме висит небольшая бирка с надписью: «Изготовлено в сотрудничестве компаний Fox и Ghost. Все права защищены. Несанкционированное изменение конструкции костюма приведёт к его немедленному уничтожению»."
	default_skin = "InteQ"
	armor = /datum/armor/mod/inteq_nuclear
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	ui_theme = "inteq"
	hardlight_color = MOD_INTEQ_COLOR
	skins = list(
		"InteQ" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/traitor
	name = "InteQ"
	desc = "Модный и современный боевой костюм, предназначенный для солдат ЧВК Интекью, не предпочитающих скрываться.\
	Неплохая броня и улучшенный джетпак позволяют вести уверенный бой в условиях космоса и разгерметизаций, а \
	встроенная кобура - прятать оружие, оно не помещается в рюкзак. "
	default_skin = "inteqe"
	armor = /datum/armor/mod/inteq_traitor
	skins = list(
		"inteqe" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/infiltrator
	name = "Infiltrator"
	desc = "Высокотехнологичный боевой костюм, изготовленный специально для наёмников, участвующих в специальных операциях. "
	extended_desc = "Высокотехнологичный боевой костюм, изготовленный специально для наёмников, участвующих в специальных операциях. Конструкция представляет собой обтекаемую многослойную систему из формованного пласталя и композитной керамики, а нижний слой выполнен из лёгкого кевлара и гибридной ткани «дуратри». На костюме висит небольшая бирка с надписью: «Изготовлено в сотрудничестве компаний Fox и Ghost. Все права защищены. Несанкционированное изменение конструкции костюма приведёт к его немедленному уничтожению»."
	default_skin = "infiltrator"
	armor = /datum/armor/mod/inteq_infiltrator
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	ui_theme = "inteq"
	skins = list(
		"infiltrator" = MOD_PRESET_WITHOUT_PRESSURE_PROTECT,
	)

/datum/mod_theme/lustwish
	name = "Lustwish"
	desc = "Специальный дизайн гражданского модулярного костюма от компании LustWish™."
	extended_desc = "Классика от Nakamura Engineering, изменённая дизайнерами компании LustWish™, с её брендовыми цветами \
		и, конечно же, латексными вставками, которые создают особые ощущения при ношении."
	default_skin = "lustwish"
	hardlight_color = MOD_LUSTWISH_COLOR
	can_activate_without_deploy_all_parts = FALSE
	need_block_storage_when_not_active = TRUE
	compatible_with_armor_modules = FALSE
	skins = list(
		"lustwish" = MOD_PRESET_WITHOUT_PRESSURE_PROTECT,
	)

/datum/mod_theme/antagonist/spider_clan
	name = "Ninja"
	desc = "Уникальный, защищенный от вакуума и температур модулярный костюм, разработанный специально для убийц из клана Паука."
	extended_desc = "Уникальный, защищенный от вакуума и температур модулярный костюм, разработанный специально для убийц из клана Паука"
	default_skin = "ninja"
	armor = /datum/armor/mod/ninja
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	ui_theme = "ninja"
	hardlight_color = MOD_NINJA_COLOR
	skins = list(
		"ninja" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/antagonist/mage
	name = "Enchanted"
	desc = "Странный, инкрустированный самоцветами модулярный костюм, излучающий магическую энергию."
	extended_desc = "Экспериментальный модулярный костюм, созданный Федерацией магов.\
		Внешне напоминающий церемониальное одеяние древних магов, костюм покрыт множеством синтетических кристаллов \
		и резонансных пластин, способных накапливать, фокусировать и перенаправлять различные формы энергии. \
		Встроенные системы стабилизации поля позволяют владельцу выдерживать экстремальные температуры, \
		биологические и радиационные угрозы, а также частично гасить кинетические и энергетические воздействия. \
		Несмотря на внешнюю «магическую» эстетику, вся работа обеспечивается передовыми технологиями: \
		кристаллы служат высокоёмкими конденсаторами, а светящиеся узоры — проекциями хардлайт-полей."
	default_skin = "enchanted"
	armor = /datum/armor/mod/magican
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	ui_theme = "enchanted"
	hardlight_color = MOD_MAGE_FEDERATION_COLOR
	skins = list(
		"enchanted" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/cargo_default/cargo_worker
	name = "Cargo"
	desc = "Усиленный костюм-погрузчик Nanotrasen, оптимизированный для работы с тяжёлыми грузами и модульным оборудованием."
	extended_desc = "Усиленный рабочий костюм, разработанный Nanotrasen совместно с Nakamura Engineering \
		для нужд логистических и снабженческих операций. \
		Изначально созданный для погрузки и разгрузки транспортных контейнеров, \
		костюм оснащён гидравлическими усилителями конечностей и усиленной рамой, \
		способной выдерживать экстремальные нагрузки при перемещении ящиков, паллет и оборудования."
	default_skin = "loader"
	complexity_max = COMMAND_MAX_COMPLEXITY
	skins = list(
		//НЕ защищает от космоса. Он НЕ герметичный. Это просто рама для тягания тяжестей.
		"loader" = MOD_PRESET_WITHOUT_PRESSURE_PROTECT_NO_JUMSUIT_HIDE,
	)
