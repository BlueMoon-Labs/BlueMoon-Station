/datum/mod_theme/engineering
	name = "engineering"
	desc = "Инженерный костюм с термо- и электрозащитой. Классика Nakamura Engineering."
	extended_desc = "Классика от Nakamura Engineering, и, несомненно, их путь к славе. Эта модель является \
		улучшением над прототипами первого поколения, созданными ещё до Войны Пустоты, и обладает множеством функций. \
		Модульная гибкость базового дизайна была совмещена с внутренним взрывопоглощающим изоляционным слоем и \
		внешним ударостойким слоем, делая костюм почти неуязвимым даже к экстремальному высоковольтному электричеству. \
		Однако потенциал для модификации остаётся таким же, как у гражданских моделей."
	default_skin = "engineering"
	armor = list(MELEE = 20, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 20, BIO = 100, FIRE = 95, ACID = 25, WOUND = 10, RAD = 80)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	skins = list(
		"engineering" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/atmospheric
	name = "atmospheric"
	desc = "Атмосфероустойчивый костюм от Nakamura Engineering, обеспечивающий крайне высокую термозащиту по сравнению с инженерным."
	extended_desc = "Модифицированная версия промышленной модели Nakamura Engineering. Эта модель была \
		усилена новейшими жаропрочными сплавами в сочетании с рядом продвинутых теплоотводов. \
		Кроме того, материалы, использованные при создании этого костюма, сделали его крайне стойким к \
		коррозионным газам и жидкостям, что полезно в мире труб. \
		Однако потенциал для модификации остаётся таким же, как у гражданских моделей."
	default_skin = "atmospheric"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 10, BIO = 100, FIRE = 100, ACID = 75, WOUND = 10, RAD = 35)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	skins = list(
		"atmospheric" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/advanced
	name = "advanced"
	desc = "Продвинутая версия классического костюма Nakamura Engineering, сияющая белой кислото- и огнеупорной полировкой."
	extended_desc = "Флагманская версия промышленной модели Nakamura Engineering и их новейший продукт. \
		Объединяя в себе все функции других промышленных моделей, с взрывостойкостью, почти приближающейся к \
		некоторым сапёрным костюмам, снаружи он покрыт белой полировкой, о которой ходят слухи как о корпоративной тайне. \
		Использованная краска практически полностью невосприимчива к коррозии и, безусловно, выглядит чертовски хорошо. \
		В комплекте предустановлены магнитные ботинки с продвинутой системой автоматического включения и выключения при ходьбе."
	default_skin = "advanced"
	armor = list(MELEE = 15, BULLET = 10, LASER = 10, ENERGY = 15, BOMB = 70, BIO = 100, FIRE = 100, ACID = 100, WOUND = 10, RAD = 100)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	complexity_max = COMMAND_MAX_COMPLEXITY
	siemens_coefficient = 0
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"advanced" = MOD_PRESET_DEFAULT,
		)

/datum/mod_theme/mining
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
	armor = list(MELEE = 20, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 50, BIO = 100, FIRE = 100, ACID = 75, WOUND = 25, RAD = 50)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cell_drain = VERY_HIGHT_CHARGE_DRAIN
	complexity_max = COMMAND_MAX_COMPLEXITY
	hardlight_color = MOD_CARGO_BLUE
	skins = list(
		"mining" = MOD_PRESET_DEFAULT,
		"asteroid" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/medical
	name = "medical"
	desc = "Лёгкий костюм от DeForest Medical Corporation, обеспечивающий более лёгкое передвижение."
	extended_desc = "Лёгкий костюм, произведённый DeForest Medical Corporation на основе работ \
		Nakamura Engineering. В нём использованы новейшие технологии, чтобы сделать его иммунным к \
		аллергенам, токсинам в воздухе и обычным патогенам. Главное достоинство этого костюма — скорость, \
		достигнутая за счёт сочетания высокомощных сервоприводов с карбоновой конструкцией. Хотя брони здесь очень мало, \
		он невероятно кислотостойкий. Энергопотребление немного выше, чем у гражданских моделей, \
		и он слаб против постукиваний пальцами по стеклу."
	default_skin = "medical"
	cell_drain = CIVILIAN_LOW_CHARGE_DRAIN
	hardlight_color = MOD_MEDBAY_COLOR
	skins = list(
		"medical" = MOD_PRESET_DEFAULT,
		"corpsman" = MOD_PRESET_DEFAULT,
		"dyne-guardian" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/rescue
	name = "rescue"
	desc = "Продвинутая версия медицинского костюма DeForest Medical Corporation, предназначенная для быстрого спасения тел из самых опасных условий."
	extended_desc = "Улучшенная бронированная версия медицинского костюма DeForest Medical Corporation, \
		предназначенная для быстрого спасения тел из самых опасных условий. Здесь используются те же продвинутые сервоприводы ног, \
		что и в базовой версии, дарящие парамедикам невероятную скорость, но такие же сервоприводы установлены и в руках. \
		Пользователи способны быстро тащить даже самых тяжёлых членов экипажа, используя этот костюм, \
		при этом оставаясь полностью иммунными к химическим и термическим угрозам. \
		Энергопотребление немного выше, чем у гражданских моделей, и он слаб против постукиваний пальцами по стеклу."
	default_skin = "rescue"
	armor = list(MELEE = 5, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 10, BIO = 100, FIRE = 100, ACID = 100, WOUND = 5, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	hardlight_color = MOD_MEDBAY_COLOR
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
	armor = list(MELEE = 20, BULLET = 15, LASER = 5, ENERGY = 5, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100, WOUND = 15, RAD = 40)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	hardlight_color = MOD_RESEARCH_COLOR
	skins = list(
		"research" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/security
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
	armor = list(MELEE = 30, BULLET = 20, LASER = 20, ENERGY = 45, BOMB = 25, BIO = 100, FIRE = 75, ACID = 75, WOUND = 30, RAD = 50)
	siemens_coefficient = 0
	complexity_max = STATION_COMBAT_MAX_COMPLEXITY
	hardlight_color = MOD_SEC_COLOR
	skins = list(
		"security" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/security/expeditor
	name = "Vanguard"
	desc = "Армированный МОД, в котором не страшно ступить даже в самые опасные заброшенные станции и обломки кораблей."
	default_skin = "vanguard"
	complexity_max = STATION_COMBAT_MAX_COMPLEXITY
	hardlight_color = "#800080"
	skins = list(
		"vanguard" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/blueshied
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
	armor = list(MELEE = 40, BULLET = 20, LASER = 20, ENERGY = 45, BOMB = 25, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 30)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"praetorian" = MOD_PRESET_DEFAULT,
		"blacksec" = MOD_PRESET_DEFAULT,
		"souless" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/blueshied/souless
	default_skin = "souless"

/datum/mod_theme/blueshied/blacksec
	default_skin = "blacksec"

/datum/mod_theme/safeguard
	name = "safeguard"
	desc = "Продвинутый костюм безопасности от Apadyne Technologies, обеспечивающий большую скорость и огнезащиту по сравнению со стандартной моделью."
	extended_desc = "Продвинутый костюм безопасности от Apadyne Technologies и их новейшая модель. Этот вариант полностью \
		отказался от усиленного стеклянного забрала, заменив его 'взрывозащитным визором', использующим \
		маленькую камеру с левой стороны для отображения внешнего мира пользователю. Бронирование костюма было \
		значительно усилено, особенно в наплечниках, придавая носителю внушительный силуэт. \
		По бокам костюма установлены теплоотводы, а для изоляции от \
		коррозионных сред и внезапных ударов по суставам пользователя применены более совершенные технологии."
	default_skin = "safeguard"
	armor = list(MELEE = 30, BULLET = 20, LASER = 30, ENERGY = 45, BOMB = 25, BIO = 100, FIRE = 100, ACID = 75, WOUND = 30, RAD = 50) // BLUEMOON EDIT - was "MELEE = 15, BULLET = 15, LASER = 15, ENERGY = 15, BOMB = 40"
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	complexity_max = STATION_COMBAT_MAX_COMPLEXITY
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"safeguard" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/magnate
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
	armor = list(MELEE = 30, BULLET = 35, LASER = 45, ENERGY = 25, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 25, RAD = 100)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	complexity_max = COMMAND_MAX_COMPLEXITY
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"magnate" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/cosmohonk
	name = "cosmohonk"
	desc = "Костюм от Honk Ltd. Защищает от низкого юмористического окружения. Большая часть технологий пошла на снижение энергопотребления."
	extended_desc = "Костюм Cosmohonk MOD изначально был разработан для межзвёздной комедии в условиях низкого юмора. \
		Он использует вольфрамовый электрокерамический корпус и хромовые биполяры, покрытые цирконий-борной краской под \
		дерматирелианским субпространственным сплавом. Несмотря на вопиюще очевидные оптронные вакуумные педали привода, \
		эта конкретная модель не использует марганцевые биполярные очистители конденсаторов, слава Хонк-Матери. \
		Всё, что вам известно, — этот костюм загадочно энергоэффективен и слишком пёстрый, чтобы Мим мог его украсть."
	default_skin = "cosmohonk"
	armor = list(MELEE = 5, BULLET = 5, LASER = 20, ENERGY = 20, BOMB = 10, BIO = 100, FIRE = 60, ACID = 30, WOUND = 5, RAD = 0)
	cell_drain = CIVILIAN_LOW_CHARGE_DRAIN
	hardlight_color = MOD_SYNDICATE_COLOR
	/*inbuilt_modules = list(/obj/item/mod/module/waddle)*/ // Waddling element not ported, commented for now as it is a prerequisite.
	skins = list(
		"cosmohonk" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/syndicate
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
	armor = list(MELEE = 40, BULLET = 35, LASER = 15, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 100, FIRE = 50, ACID = 90, RAD = 100, WOUND = 25)
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "syndicate"
	inbuilt_modules = list()
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"syndicate" = MOD_PRESET_DEFAULT,
		"cybersun" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/elite
	name = "elite"
	desc = "Элитный костюм, модернизированный Cybersun Industries, с улучшенными показателями брони."
	extended_desc = "Эволюция синдикатного костюма, отличающийся более массивной конструкцией и матовой чёрной цветовой гаммой, \
		этот костюм производится только для высокопоставленных офицеров Синдиката и элитных ударных групп. \
		Он оснащён дополнительным слоем керамики и кевлара в пластинах, обеспечивающим \
		исключительно лучшую защиту вместе с огне- и кислотостойкостью. С него свисает маленькая бирка с надписью: \
		'Собственность Gorlex Marauders при содействии Cybersun Industries. \
		Все права защищены, вмешательство в костюм аннулирует продолжительность жизни.'"
	default_skin = "elite"
	armor = list(MELEE = 60, BULLET = 60, LASER = 50, ENERGY = 25, BOMB = 55, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 30, RAD = 100)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "syndicate"
	inbuilt_modules = list()
	hardlight_color = MOD_SYNDICATE_COLOR
	skins = list(
		"elite"            = MOD_PRESET_DEFAULT,
		"admiral"          = MOD_PRESET_DEFAULT,
		"admiral-cybersun" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/prototype
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
	armor = list(MELEE = 35, BULLET = 35, LASER = 35, ENERGY = 20, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 15, RAD = 35)
	resistance_flags = FIRE_PROOF
	cell_drain = VERY_HIGHT_CHARGE_DRAIN
	ui_theme = "hackerman"
	skins = list(
		"prototype" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/responsory
	name = "responsory"
	desc = "Высокоскоростной спасательный костюм от Nanotrasen, предназначенный для команд экстренного реагирования."
	extended_desc = "Обтекаемый костюм дизайна Nanotrasen, эти гладкие чёрные костюмы носят только \
		элитные сотрудники экстренного реагирования, чтобы спасти день. Хотя стройная и ловкая конструкция костюма \
		сокращает использование керамики и аблятивов, снижая защиту, \
		она сохраняет носителя в безопасности от суровой пустоты космоса, не жертвуя ни каплей скорости. \
		Нося его, вы чувствуете крайнее почтение к тьме."
	default_skin = "responsory"
	armor = list(MELEE = 45, BULLET = 45, LASER = 45, ENERGY = 50, BOMB = 50, BIO = 100, FIRE = 100, ACID = 90, WOUND = 10, RAD = 0)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	hardlight_color = MOD_COMMAND_COLOR
	skins = list(
		"responsory"  = MOD_PRESET_DEFAULT,
		"inquisitory" = MOD_PRESET_DEFAULT,
		"marine"      = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/apocryphal
	name = "apocryphal"
	desc = "Высокотехнологичный, лишь формально легальный бронированный костюм, созданный совместными усилиями Nanotrasen и Apadyne Technologies."
	extended_desc = "Громоздкий и лишь формально легальный костюм, этот зловещий чёрно-красный MOD-костюм носят только \
		команды чёрных операций Nanotrasen. Если вы видите этот костюм, вы облажались. Совместное творение \
		Apadyne и Nanotrasen — конструкция и модули даруют пользователю надёжную защиту от \
		всего, что может быть в него запущено, а также острые инструменты боевого осознания для его носителя. \
		Использовать ли их — решение самого носителя. \
		На запястье, кажется, есть маленькая гравировка: 'squiddie', милашка."
	default_skin = "apocryphal"
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 60, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100, WOUND = 25, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	complexity_max = CENTCOMM_MAX_COMPLEXITY
	hardlight_color = MOD_SYNDICATE_COLOR
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
	armor = list(MELEE = 30, BULLET = 35, LASER = 45, ENERGY = 25, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 25, RAD = 75)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
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
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100, WOUND = 100, RAD = 35)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	complexity_max = DEBUG_COMPLEXITY
	skins = list(
		"debug" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/administrative
	name = "administrative"
	desc = "Костюм из админиума. Кто придумывает эти тупые названия минералов?"
	extended_desc = "Да, ладно, думаю, это можно назвать ивентом. Но то, что я считаю ивентом, — это что-то на самом деле \
		весёлое и увлекательное для игроков — вместо этого большинство сидели в стороне, мертвы или разобраны на части, в то время как счастливчикам досталось \
		всё веселье. Если это продолжит быть паттерном для ваших \"ивентов\" (Админ-абьюз), \
		будет админ-жалоба. Вы были предупреждены."
	default_skin = "debug"
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100, WOUND = 100, RAD = 100)
	resistance_flags = INDESTRUCTIBLE|LAVA_PROOF|FIRE_PROOF|UNACIDABLE|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	complexity_max = DEBUG_COMPLEXITY
	cell_drain = DEBUG_LOW_CHARGE_DRAIN
	skins = list(
		"debug" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/inteq
	name = "InteQ"
	desc = "Высокотехнологичный боевой костюм, выполненный в зловещих тёмно-синих тонах и изготовленный специально для наёмников, участвующих в специальных операциях. "
	extended_desc = "Высокотехнологичный боевой костюм, выполненный в зловещих тёмно-синих тонах и изготовленный специально для наёмников, участвующих в специальных операциях. Конструкция представляет собой обтекаемую многослойную систему из формованного пласталя и композитной керамики, а нижний слой выполнен из лёгкого кевлара и гибридной ткани «дуратри». На костюме висит небольшая бирка с надписью: «Изготовлено в сотрудничестве компаний Fox и Ghost. Все права защищены. Несанкционированное изменение конструкции костюма приведёт к его немедленному уничтожению»."
	default_skin = "InteQ"
	armor = list(MELEE = 60, BULLET = 60, LASER = 50, ENERGY = 25, BOMB = 55, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 30, RAD = 100)
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "inteq"
	inbuilt_modules = list()
	hardlight_color = MOD_INTEQ_COLOR
	skins = list(
		"InteQ" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/inteq/traitor
	name = "InteQ"
	desc = "Модный и современный боевой костюм, предназначенный для солдат ЧВК Интекью, не предпочитающих скрываться.\
	Неплохая броня и улучшенный джетпак позволяют вести уверенный бой в условиях космоса и разгерметизаций, а \
	встроенная кобура - прятать оружие, оно не помещается в рюкзак. "
	default_skin = "inteqe"
	armor = list(MELEE = 40, BULLET = 35, LASER = 15, ENERGY = 15, BOMB = 35, BIO = 100, RAD = 100, FIRE = 50, ACID = 90, RAD = 100, WOUND = 25)
	skins = list(
		"inteqe" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/inteq/infiltrator
	name = "Infiltrator"
	desc = "Высокотехнологичный боевой костюм, изготовленный специально для наёмников, участвующих в специальных операциях. "
	extended_desc = "Высокотехнологичный боевой костюм, изготовленный специально для наёмников, участвующих в специальных операциях. Конструкция представляет собой обтекаемую многослойную систему из формованного пласталя и композитной керамики, а нижний слой выполнен из лёгкого кевлара и гибридной ткани «дуратри». На костюме висит небольшая бирка с надписью: «Изготовлено в сотрудничестве компаний Fox и Ghost. Все права защищены. Несанкционированное изменение конструкции костюма приведёт к его немедленному уничтожению»."
	default_skin = "infiltrator"
	armor = list(MELEE = 45, BULLET = 50, LASER = 45, ENERGY = 55, BOMB = 75, BIO = 100, RAD = 70, FIRE = 100, ACID = 100, WOUND = 55)
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "inteq"
	inbuilt_modules = list()
	hardlight_effect = /datum/overlay_effect/mod_effect/white_noize
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
	skins = list(
		"lustwish" = MOD_PRESET_WITHOUT_PRESSURE_PROTECT,
	)

/datum/mod_theme/spider_clan
	name = "Ninja"
	desc = "Уникальный, защищенный от вакуума и температур модулярный костюм, разработанный специально для убийц из клана Паука."
	extended_desc = "Уникальный, защищенный от вакуума и температур модулярный костюм, разработанный специально для убийц из клана Паука"
	default_skin = "ninja"
	armor = list(MELEE = 40, BULLET = 30, LASER = 20, ENERGY = 30, BOMB = 50, BIO = 100, RAD = 30, FIRE = 100, ACID = 100)
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	complexity_max = ANTAG_MAX_COMPLEXITY
	siemens_coefficient = 0
	ui_theme = "ninja"
	inbuilt_modules = list()
	hardlight_effect = /datum/overlay_effect/mod_effect/white_noize
	hardlight_color = MOD_NINJA_COLOR
	skins = list(
		"ninja" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/mage
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
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 35, BIO = 100, RAD = 50, FIRE = 100, ACID = 100, WOUND = 30)
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	complexity_max = ANTAG_MAX_COMPLEXITY
	siemens_coefficient = 0
	ui_theme = "enchanted"
	inbuilt_modules = list()
	hardlight_effect = /datum/overlay_effect/mod_effect/white_noize
	hardlight_color = MOD_MAGE_FEDERATION_COLOR
	skins = list(
		"enchanted" = MOD_PRESET_DEFAULT,
	)

/datum/mod_theme/cargo
	name = "Cargo"
	desc = "Усиленный костюм-погрузчик Nanotrasen, оптимизированный для работы с тяжёлыми грузами и модульным оборудованием."
	extended_desc = "Усиленный рабочий костюм, разработанный Nanotrasen совместно с Nakamura Engineering \
		для нужд логистических и снабженческих операций. \
		Изначально созданный для погрузки и разгрузки транспортных контейнеров, \
		костюм оснащён гидравлическими усилителями конечностей и усиленной рамой, \
		способной выдерживать экстремальные нагрузки при перемещении ящиков, паллет и оборудования."
	default_skin = "loader"
	armor = list(MELEE = 20, BULLET = 20, LASER = 10, ENERGY = 5, BOMB = 50, BIO = 100, FIRE = 70, ACID = 75, WOUND = 35, RAD = 50)
	cell_drain = DEFAULT_CHARGE_DRAIN
	complexity_max = COMMAND_MAX_COMPLEXITY
	hardlight_color = MOD_CARGO_BLUE
	skins = list(
		//НЕ защищает от космоса. Он НЕ герметичный. Это просто рама для тягания тяжестей.
		"loader" = MOD_PRESET_WITHOUT_PRESSURE_PROTECT_NO_JUMSUIT_HIDE,
	)
