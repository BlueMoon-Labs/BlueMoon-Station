/// Global proc that sets up all MOD themes as singletons in a list and returns it.
/proc/setup_mod_themes()
	. = list()
	for(var/path in typesof(/datum/mod_theme))
		var/datum/mod_theme/new_theme = new path()
		.[path] = new_theme

/// MODsuit theme, instanced once and then used by MODsuits to grab various statistics.
/datum/mod_theme
	/// Theme name for the MOD.
	var/name = "standard"
	/// Description added to the MOD.
	var/desc = "Гражданский костюм от Nakamura Engineering, не предлагает многого, кроме немного более быстрого передвижения."
	/// Extended description on examine_more
	var/extended_desc = "Модульный костюм третьего поколения от Nakamura Engineering, \
		этот костюм является основным выбором по всей галактике для гражданских применений. Эти костюмы обеспечивают кислород, \
		пригодны для космоса, устойчивы к огню и химическим угрозам, и иммунизированы против всего — \
		от чихания до биологического оружия. Однако их боевые применения крайне минимальны, так как по умолчанию \
		не установлена бронепластина, а их приводы лишь немного увеличивают скорость по сравнению с обычной."
	/// Default skin of the MOD.
	var/default_skin = "standard"
	/// Armor shared across the MOD pieces.
	var/armor = list(MELEE = 10, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 5, RAD = 0)
	/// Resistance flags shared across the MOD pieces.
	var/resistance_flags = NONE
	/// Max heat protection shared across the MOD pieces.
	var/max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	/// Max cold protection shared across the MOD pieces.
	var/min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	/// Permeability shared across the MOD pieces.
	var/permeability_coefficient = 0.01
	/// Siemens shared across the MOD pieces.
	var/siemens_coefficient = 0.5
	/// How much modules can the MOD carry without malfunctioning.
	var/complexity_max = DEFAULT_MAX_COMPLEXITY
	/// How much battery power the MOD uses by just being on
	var/cell_drain = DEFAULT_CHARGE_DRAIN
	/// Slowdown of the MOD when not active.
	var/slowdown_inactive = 1.1
	/// Slowdown of the MOD when active.
	var/slowdown_active = 0
	/// Theme used by the MOD TGUI.
	var/ui_theme = "ntos"
	/// Allowed items in the chestplate's suit storage.
	var/list/allowed = list(/obj/item/flashlight, /obj/item/tank/internals)
	/// List of inbuilt modules. These are different from the pre-equipped suits, you should mainly use these for unremovable modules with 0 complexity.
	var/list/inbuilt_modules = list()
	/// Modules blacklisted from the MOD.
	var/list/module_blacklist = list()
	/// List of skins with their appropriate clothing flags.
	var/list/skins = list(
		"standard" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
		"civilian" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
	)

/datum/mod_theme/engineering
	name = "engineering"
	desc = "Инженерный костюм с термо- и электрозащитой. Классика Nakamura Engineering."
	extended_desc = "Классика от Nakamura Engineering, и, несомненно, их путь к славе. Эта модель является \
		улучшением над прототипами первого поколения, созданными ещё до Войны Пустоты, и обладает множеством функций. \
		Модульная гибкость базового дизайна была совмещена с внутренним взрывопоглощающим изоляционным слоем и \
		внешним ударостойким слоем, делая костюм почти неуязвимым даже к экстремальному высоковольтному электричеству. \
		Однако потенциал для модификации остаётся таким же, как у гражданских моделей."
	default_skin = "engineering"
	armor = list(MELEE = 20, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 20, BIO = 100, FIRE = 100, ACID = 25, WOUND = 10, RAD = 100)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	skins = list(
		"engineering" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
		"atmospheric" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 15, BULLET = 10, LASER = 10, ENERGY = 15, BOMB = 70, BIO = 100, FIRE = 100, ACID = 100, WOUND = 10, RAD = 35)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	complexity_max = DEFAULT_MAX_COMPLEXITY + 5
	siemens_coefficient = 0
	inbuilt_modules = list(/obj/item/mod/module/magboot/advanced)
	skins = list(
		"advanced" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 40, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 30, BIO = 100, FIRE = 100, ACID = 75, WOUND = 15, RAD = 0)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cell_drain = DEFAULT_CHARGE_DRAIN * 2
	complexity_max = DEFAULT_MAX_COMPLEXITY + 5
	inbuilt_modules = list(/obj/item/mod/module/orebag)
	skins = list(
		"mining" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEFACE,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 5, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 10, BIO = 100, FIRE = 60, ACID = 75, WOUND = 5, RAD = 0)
	cell_drain = DEFAULT_CHARGE_DRAIN * 1.3
	inbuilt_modules = list(/obj/item/mod/module/quick_carry)
	skins = list(
		"medical" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
		"corpsman" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 10, BULLET = 10, LASER = 5, ENERGY = 5, BOMB = 10, BIO = 100, FIRE = 100, ACID = 100, WOUND = 5, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cell_drain = DEFAULT_CHARGE_DRAIN * 1.2
	inbuilt_modules = list(/obj/item/mod/module/quick_carry/advanced)
	skins = list(
		"rescue" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 20, BULLET = 15, LASER = 5, ENERGY = 5, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100, WOUND = 15, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	inbuilt_modules = list(/obj/item/mod/module/reagent_scanner/advanced)
	skins = list(
		"research" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 30, BULLET = 20, LASER = 30, ENERGY = 30, BOMB = 30, BIO = 100, FIRE = 100, ACID = 75, WOUND = 15, RAD = 0)
	siemens_coefficient = 0
	complexity_max = DEFAULT_MAX_COMPLEXITY - 5
	inbuilt_modules = list(/obj/item/mod/module/magnetic_harness)
	skins = list(
		"security" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEFACE,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
	)

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
	armor = list(MELEE = 40, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 30, BIO = 100, FIRE = 100, ACID = 95, WOUND = 15, RAD = 0) // BLUEMOON EDIT - was "MELEE = 15, BULLET = 15, LASER = 15, ENERGY = 15, BOMB = 40"
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	complexity_max = DEFAULT_MAX_COMPLEXITY - 5
	skins = list(
		"safeguard" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 30, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 15, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	complexity_max = DEFAULT_MAX_COMPLEXITY + 5
	skins = list(
		"magnate" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	cell_drain = DEFAULT_CHARGE_DRAIN * 0.25
	slowdown_active = 1.25
	/*inbuilt_modules = list(/obj/item/mod/module/waddle)*/ // Waddling element not ported, commented for now as it is a prerequisite.
	skins = list(
		"cosmohonk" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEEARS|HIDEHAIR,
				SEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEYES|HIDEFACE|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 25, BULLET = 35, LASER = 25, ENERGY = 15, BOMB = 30, BIO = 100, FIRE = 50, ACID = 90, WOUND = 25, RAD = 0) // BLUEMOON EDIT - was "MELEE = 15, BULLET = 20, LASER = 15"
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "syndicate"
	inbuilt_modules = list()
	skins = list(
		"syndicate" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 45, BULLET = 45, LASER = 35, ENERGY = 30, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 25, RAD = 0) // BLUEMOON EDIT - was "MELEE = 35, BULLET = 30, LASER = 35"
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	ui_theme = "syndicate"
	inbuilt_modules = list()
	skins = list(
		"elite" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	cell_drain = DEFAULT_CHARGE_DRAIN * 2
	slowdown_active = 1.2
	ui_theme = "hackerman"
	inbuilt_modules = list(/obj/item/mod/module/kinesis)
	skins = list(
		"prototype" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 50, BULLET = 40, LASER = 50, ENERGY = 50, BOMB = 50, BIO = 100, FIRE = 100, ACID = 90, WOUND = 10, RAD = 0)
	resistance_flags = FIRE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	slowdown_inactive = 0.5
	slowdown_active = 0
	skins = list(
		"responsory" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
		"inquisitory" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	complexity_max = DEFAULT_MAX_COMPLEXITY + 10
	skins = list(
		"apocryphal" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEEARS|HIDEHAIR,
				SEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEYES|HIDEFACE|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	armor = list(MELEE = 40, BULLET = 50, LASER = 30, ENERGY = 30, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100, WOUND = 15, RAD = 0)
	resistance_flags = FIRE_PROOF|ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	skins = list(
		"corporate" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEFACE,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	complexity_max = 50
	skins = list(
		"debug" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
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
	complexity_max = 100
	cell_drain = DEFAULT_CHARGE_DRAIN * 0
	skins = list(
		"debug" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE,
				UNSEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE,
			),
		),
	)
