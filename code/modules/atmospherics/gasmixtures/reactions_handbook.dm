// Метаданные реакций для внутриигрового справочника по атмосу.
//
// Держится отдельно от reactions.dm, чтобы логика реакций читалась без стены
// текста. Здесь же задаются названия: name у реакции нигде, кроме справочника,
// не показывается, поэтому переводить его в reactions.dm незачем - весь текст
// для игрока лежит в одном файле и правится одной правкой.
//
// Всё написано по-русски по той же причине, по которой написаны описания
// газов: игрок обязан узнавать правила из игры, а не с вики.

/// Одна и та же строка у всех катализируемых реакций: игрок должен видеть, что
/// флюксин делает ровно одно и то же везде, а не гадать по каждой отдельно.
#define FLUXIN_HANDBOOK_FACTOR "Необязательный катализатор: поднимает верхнюю границу температурного окна и срезает расход сырья до [FLUXIN_MAX_BONUS * 100]% на [FLUXIN_FULL_EFFECT_MOLES] молях. Медленно тратится."

/datum/gas_reaction/nobliumsupression/init_factors()
	name = "Подавление реакций гипернобелем"
	desc = "Гипернобель глушит вообще все остальные реакции в смеси, пока его в ней достаточно. Лучшее аварийное средство: заглушает и пожар, и разгон супермтерии."
	factor = list(
		/datum/gas/hypernoblium = "Нужно не меньше [REACTION_OPPRESSION_THRESHOLD] молей, чтобы подавление включилось",
		"Temperature" = "Подавляет реакции только выше [REACTION_OPPRESSION_MIN_TEMP] К",
	)

/datum/gas_reaction/water_vapor/init_factors()
	name = "Водяной пар"
	desc = "Пар тушит огонь на открытом турфе, а на холоде вместо этого запускает фреоновые эффекты и намерзает льдом."
	factor = list(
		/datum/gas/water_vapor = "Нужно не меньше [MOLES_GAS_VISIBLE] молей",
		"Temperature" = "Выше [WATER_VAPOR_FREEZE] К тушит пожар; на этой отметке и ниже идёт фреоновый эффект",
		"Location" = "Работает только на открытом турфе",
	)

/datum/gas_reaction/tritfire/init_factors()
	name = "Горение трития"
	desc = "Тритий горит в кислороде жарче плазмы и облучает всё вокруг. Считается раньше горения плазмы."
	factor = list(
		/datum/gas/tritium = "Топливо; скорость горения зависит от доли кислорода",
		/datum/gas/oxygen = "Окислитель",
		/datum/gas/water_vapor = "Продукт горения",
		"Temperature" = "Нужно не меньше [FIRE_MINIMUM_TEMPERATURE_TO_EXIST] К",
		"Radiation" = "При большом расходе топлива выдаёт импульсы радиации",
		"Energy" = "Выделяет [FIRE_HYDROGEN_ENERGY_RELEASED] джоулей на моль сгоревшего топлива",
		"Location" = "На открытом турфе поджигает его",
	)

/datum/gas_reaction/plasmafire/init_factors()
	name = "Горение плазмы"
	desc = "Основной пожар станции. При большом избытке кислорода вместо углекислоты даёт тритий - на этом и строят его добычу."
	factor = list(
		/datum/gas/plasma = "Основное топливо; скорость горения растёт с температурой",
		/datum/gas/oxygen = "Окислитель; при высоком отношении кислорода к плазме вместо углекислоты рождается тритий",
		/datum/gas/carbon_dioxide = "Продукт, пока отношение кислорода к плазме ниже [SUPER_SATURATION_THRESHOLD]",
		/datum/gas/tritium = "Продукт, когда отношение кислорода к плазме выше [SUPER_SATURATION_THRESHOLD]",
		"Temperature" = "Нужно не меньше [FIRE_MINIMUM_TEMPERATURE_TO_EXIST] К",
		"Energy" = "Выделяет [FIRE_PLASMA_ENERGY_RELEASED] джоулей на моль сгоревшей плазмы",
		"Location" = "На открытом турфе поджигает его",
	)

/datum/gas_reaction/genericfire/init_factors()
	name = "Общее горение"
	desc = "Универсальное горение всего остального: у каждого газа своя температура воспламенения, свой окислитель и свои продукты. Плазма и тритий считаются отдельно."
	factor = list(
		"Temperature" = "Каждый газ горит только выше собственной температуры воспламенения или окисления",
		"Energy" = "Тепло берётся из энтальпии конкретного газа, продукты тоже свои у каждого",
		"Location" = "На лавовой планете азот топливом не считается",
	)

/datum/gas_reaction/fusion/init_factors()
	name = "Плазменный синтез"
	desc = "Хаотичный синтез на плазме и углекислоте. В штатной обработке атмоса отключён и живёт только в HFR."
	factor = list(
		/datum/gas/plasma = "Основное топливо; нужно больше [FUSION_MOLE_THRESHOLD] молей",
		/datum/gas/carbon_dioxide = "Нужно больше [FUSION_MOLE_THRESHOLD] молей; управляет нестабильностью",
		/datum/gas/tritium = "Расходуется по [FUSION_TRITIUM_MOLES_USED] моля за тик",
		/datum/gas/oxygen = "Рождается при экзотермическом ходе реакции",
		/datum/gas/nitrous_oxide = "Рождается при экзотермическом ходе реакции",
		/datum/gas/bz = "Рождается при эндотермическом ходе реакции",
		/datum/gas/nitryl = "Рождается при эндотермическом ходе реакции",
		"Temperature" = "Нужно не меньше [FUSION_TEMPERATURE_THRESHOLD] К",
		"Radiation" = "Излучает радиацию, а на высоких энергиях порождает ядерные частицы",
		"Energy" = "Величина непредсказуема: в неё входит превращение массы плазмы в энергию",
	)

/datum/gas_reaction/nitrylformation/init_factors()
	name = "Синтез нитрила"
	desc = "Кислород и азот в жаре собираются в нитрил, закись азота работает катализатором. Реакция поглощает тепло."
	factor = list(
		/datum/gas/oxygen = "Расходуется один к одному со скоростью реакции",
		/datum/gas/nitrogen = "Расходуется один к одному со скоростью реакции",
		/datum/gas/nitrous_oxide = "Катализатор; нужно не меньше 5 молей",
		/datum/gas/nitryl = "Рождается вдвое быстрее скорости реакции",
		"Temperature" = "Скорость растёт с температурой выше [FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 25] К",
		"Energy" = "Поглощает [NITRYL_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/bzformation/init_factors()
	name = "Синтез BZ"
	desc = "Закись азота и плазма при НИЗКОМ давлении дают BZ - катализатор половины верхней химии. Чем ниже давление, тем выше выход, поэтому камеру специально разрежают."
	factor = list(
		/datum/gas/nitrous_oxide = "Расходуется один к одному со скоростью реакции; нужно не меньше 10 молей",
		/datum/gas/plasma = "Расходуется вдвое быстрее закиси; нужно не меньше 10 молей",
		/datum/gas/bz = "Рождается один к одному со скоростью реакции",
		/datum/gas/oxygen = "Может выделиться, когда закись азота кончилась",
		"Pressure" = "Чем ниже давление, тем выше выход; лучше всего около 10 кПа",
		"Energy" = "Выделяет [FIRE_CARBON_ENERGY_RELEASED * 2] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/stimformation/init_factors()
	name = "Синтез стимулума"
	desc = "Самая требовательная цепочка в игре: тритий, плазма и нитрил разом, плюс BZ катализатором. В зависимости от температуры греет или холодит."
	factor = list(
		/datum/gas/tritium = "Расходуется один к одному с тепловым множителем; нужно не меньше 30 молей",
		/datum/gas/plasma = "Расходуется один к одному с тепловым множителем; нужно не меньше 10 молей",
		/datum/gas/nitryl = "Расходуется один к одному с тепловым множителем; нужно не меньше 30 молей",
		/datum/gas/bz = "Обязательный катализатор; нужно не меньше 20 молей",
		/datum/gas/stimulum = "Рождается в объёме 0.1 от теплового множителя",
		"Temperature" = "Выход идёт по кривой пятой степени от температуры, делённой на [STIMULUM_HEAT_SCALE]",
		"Energy" = "Знак и величина зависят от температуры: реакция бывает и экзо-, и эндотермической",
	)

/datum/gas_reaction/nobliumformation/init_factors()
	name = "Конденсация гипернобеля"
	desc = "Азот и тритий на криогенном холоде сходятся в гипернобель. BZ в смеси удешевляет реакцию по тритию, но и тепла даёт меньше."
	factor = list(
		/datum/gas/nitrogen = "10 молей на каждый моль гипернобеля",
		/datum/gas/tritium = "5 молей на моль без BZ, с BZ - меньше",
		/datum/gas/bz = "Снижает расход трития и выделяемое тепло",
		/datum/gas/hypernoblium = "Продукт реакции",
		"Temperature" = "Идёт только ниже [NOBLIUM_FORMATION_MAX_TEMP] К",
		"Energy" = "Выделяет [NOBLIUM_FORMATION_ENERGY] джоулей на моль (с BZ меньше)",
	)

/datum/gas_reaction/miaster/init_factors()
	name = "Сухая стерилизация миазмы"
	desc = "Сухой жар выжигает трупный газ, оставляя вместо него кислород. Влага реакцию срывает, поэтому камеру сушат."
	factor = list(
		/datum/gas/miasma = "Сгорает до 20 + (T - 443.15) / 20 молей за тик",
		/datum/gas/oxygen = "Рождается один к одному из сожжённой миазмы",
		/datum/gas/water_vapor = "Больше 0.1 моля пара полностью останавливает реакцию",
		"Temperature" = "Нужно не меньше [T0C + 170] К (170 °C)",
		"Energy" = "Чуть греет смесь: около +0.002 К на моль очистки",
	)

/datum/gas_reaction/nitric_oxide/init_factors()
	name = "Распад оксида азота"
	desc = "На холоде оксид азота либо разваливается обратно на азот и кислород, либо доокисляется до нитрила."
	factor = list(
		/datum/gas/nitric_oxide = "Распадается на азот и кислород либо доокисляется до нитрила",
		/datum/gas/oxygen = "Если он есть, вместо распада идёт синтез нитрила",
		/datum/gas/nitryl = "Продукт реакции с кислородом",
		/datum/gas/nitrogen = "Продукт распада",
		"Temperature" = "Идёт только ниже [FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100] К",
	)

/datum/gas_reaction/hagedorn/init_factors()
	name = "Распад Хагедорна"
	desc = "При запредельных энергиях адроны разваливаются и вся смесь превращается в кварковую материю."
	factor = list(
		/datum/gas/quark_matter = "Вся энергия смеси уходит в моли кварковой материи",
		"Temperature" = "Нужно не меньше 2e12 К",
		"Energy" = "Полная тепловая энергия смеси сохраняется",
	)

/datum/gas_reaction/dehagedorn/init_factors()
	name = "Конденсация Хагедорна"
	desc = "Остыв ниже температуры Хагедорна, кварковая материя сворачивается обратно в случайные газы."
	factor = list(
		/datum/gas/quark_matter = "Расходуется целиком и задаёт, сколько газа родится",
		"Temperature" = "Идёт только ниже 1.99e12 К",
		"Energy" = "Тепловая энергия распределяется по случайным газам (кроме трития и гипернобеля)",
	)

/datum/gas_reaction/freonfire/init_factors()
	name = "Горение фреона"
	desc = "Единственное горение, которое смесь охлаждает, а не греет. Прото-нитрат в смеси поднимает верхнюю границу окна горения."
	factor = list(
		/datum/gas/freon = "Топливо; скорость горения растёт по мере приближения к 0 °C",
		/datum/gas/oxygen = "Окислитель, расходуется вместе с фреоном",
		/datum/gas/carbon_dioxide = "Рождается один к одному из сожжённого фреона",
		/datum/gas/proto_nitrate = "Поднимает верхнюю границу горения до [FREON_CATALYST_MAX_TEMPERATURE] К",
		"Temperature" = "Горит между [FREON_TERMINAL_TEMPERATURE] и [FREON_MAXIMUM_BURN_TEMPERATURE] К (с прото-нитратом - до [FREON_CATALYST_MAX_TEMPERATURE] К)",
		"Energy" = "Поглощает [FIRE_FREON_ENERGY_CONSUMED] джоулей на моль сгоревшего фреона",
		"Location" = "На открытом турфе между [FREON_HOT_ICE_MIN_TEMP] и [FREON_HOT_ICE_MAX_TEMP] К намораживает горячий лёд",
	)

/datum/gas_reaction/freonformation/init_factors()
	name = "Синтез фреона"
	desc = "Плазма, углекислота и BZ в жаре собираются во фреон. Реакция поглощает тепло, поэтому контур приходится подогревать."
	factor = list(
		/datum/gas/plasma = "Расходуется по 0.6 на единицу реакции",
		/datum/gas/carbon_dioxide = "Расходуется по 0.3 на единицу реакции",
		/datum/gas/bz = "Расходуется по 0.1 на единицу реакции",
		/datum/gas/freon = "Рождается по 10 на единицу реакции",
		"Temperature" = "Нужно не меньше [FREON_FORMATION_MIN_TEMPERATURE] К; скорость растёт с избытком тепла",
		"Energy" = "Поглощает [FREON_FORMATION_ENERGY_CONSUMED] джоулей на единицу реакции",
	)

/datum/gas_reaction/halon_o2removal/init_factors()
	name = "Поглощение кислорода галоном"
	desc = "Галон связывает кислород и отдаёт вместо него плуоксий, попутно охлаждая смесь. Так гасят пожар без воды."
	factor = list(
		/datum/gas/halon = "Расходуется один к одному со скоростью реакции",
		/datum/gas/oxygen = "Расходуется по 20 молей на моль галона",
		/datum/gas/pluoxium = "Рождается в объёме 2.5 от скорости реакции",
		"Temperature" = "Нужно не меньше [HALON_COMBUSTION_MIN_TEMPERATURE] К; скорость растёт с температурой",
		"Energy" = "Поглощает [HALON_COMBUSTION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/healium_formation/init_factors()
	name = "Синтез хилия"
	desc = "BZ и фреон в узком температурном окне дают лечебный газ. Основа медицинской атмосферики."
	factor = list(
		/datum/gas/freon = "Расходуется в объёме 2.75 от скорости реакции",
		/datum/gas/bz = "Расходуется в объёме 0.25 от скорости реакции",
		/datum/gas/healium = "Рождается втрое быстрее скорости реакции",
		/datum/gas/fluxin = FLUXIN_HANDBOOK_FACTOR,
		"Temperature" = "Идёт только между [HEALIUM_FORMATION_MIN_TEMP] и [HEALIUM_FORMATION_MAX_TEMP] К",
		"Energy" = "Выделяет [HEALIUM_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/zauker_formation/init_factors()
	name = "Синтез заукера"
	desc = "Гипернобель и нитрий в чудовищной жаре дают самый смертоносный газ в игре. Обе составляющие сами по себе - конец собственных цепочек."
	factor = list(
		/datum/gas/hypernoblium = "Расходуется в объёме 0.01 от скорости реакции",
		/datum/gas/nitrium = "Расходуется в объёме 0.5 от скорости реакции",
		/datum/gas/zauker = "Рождается в объёме 0.5 от скорости реакции",
		/datum/gas/fluxin = FLUXIN_HANDBOOK_FACTOR,
		"Temperature" = "Идёт только между [ZAUKER_FORMATION_MIN_TEMPERATURE] и [ZAUKER_FORMATION_MAX_TEMPERATURE] К",
		"Energy" = "Поглощает [ZAUKER_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/zauker_decomp/init_factors()
	name = "Распад заукера"
	desc = "В присутствии азота заукер разваливается сам. Именно поэтому залив станции заукером не превращается в вечный - и именно поэтому азотный баллон лучшее противоядие."
	factor = list(
		/datum/gas/zauker = "Распадается до [ZAUKER_DECOMPOSITION_MAX_RATE] молей за тик",
		/datum/gas/nitrogen = "Обязательный катализатор, расходуется вместе с заукером",
		/datum/gas/oxygen = "Рождается в объёме 0.3 от скорости распада",
		"Energy" = "Выделяет [ZAUKER_DECOMPOSITION_ENERGY] джоулей на моль распада",
	)

/datum/gas_reaction/nitrium_formation/init_factors()
	name = "Синтез нитрия"
	desc = "Тритий, азот и щепотка BZ в жаре дают боевой стимулятор. Реакция поглощает тепло."
	factor = list(
		/datum/gas/tritium = "Расходуется один к одному со скоростью реакции; нужно не меньше 20 молей",
		/datum/gas/nitrogen = "Расходуется один к одному со скоростью реакции; нужно не меньше 10 молей",
		/datum/gas/bz = "Расходуется в объёме 0.05 от скорости реакции; нужно не меньше 5 молей",
		/datum/gas/nitrium = "Рождается один к одному со скоростью реакции",
		"Temperature" = "Нужно не меньше [NITRIUM_FORMATION_MIN_TEMP] К; скорость растёт с температурой",
		"Energy" = "Поглощает [NITRIUM_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/nitrium_decomposition/init_factors()
	name = "Распад нитрия"
	desc = "Нагретый нитрий разваливается на азот и водород. Хранить его в горячем контуре бессмысленно."
	factor = list(
		/datum/gas/nitrium = "Расходуется один к одному со скоростью реакции",
		/datum/gas/nitrogen = "Рождается один к одному со скоростью реакции",
		/datum/gas/hydrogen = "Рождается один к одному со скоростью реакции",
		"Temperature" = "Идёт только ниже [NITRIUM_DECOMPOSITION_MAX_TEMP] К; скорость растёт с температурой",
		"Energy" = "Выделяет [NITRIUM_DECOMPOSITION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/pluox_formation/init_factors()
	name = "Синтез плуоксия"
	desc = "Углекислота, кислород и капля трития дают плотный носитель кислорода. Дешёвый вход в верхнюю химию: сырьё есть на любой станции."
	factor = list(
		/datum/gas/carbon_dioxide = "Один моль на моль плуоксия",
		/datum/gas/oxygen = "Два моля на моль плуоксия",
		/datum/gas/tritium = "0.01 моля на моль плуоксия",
		/datum/gas/pluoxium = "Рождается до [PLUOXIUM_FORMATION_MAX_RATE] молей за тик",
		/datum/gas/hydrogen = "Побочный продукт, 0.01 моля на моль плуоксия",
		/datum/gas/fluxin = FLUXIN_HANDBOOK_FACTOR,
		"Temperature" = "Идёт только между [PLUOXIUM_FORMATION_MIN_TEMP] и [PLUOXIUM_FORMATION_MAX_TEMP] К",
		"Energy" = "Выделяет [PLUOXIUM_FORMATION_ENERGY] джоулей на моль плуоксия",
	)

/datum/gas_reaction/proto_nitrate_formation/init_factors()
	name = "Синтез прото-нитрата"
	desc = "Плуоксий и водород в жаре дают реактивный газ, по-разному отвечающий на другие газы. На этих ответах и строят каскадные схемы."
	factor = list(
		/datum/gas/pluoxium = "Расходуется в объёме 0.2 от скорости реакции",
		/datum/gas/hydrogen = "Расходуется вдвое быстрее скорости реакции",
		/datum/gas/proto_nitrate = "Рождается в объёме 2.2 от скорости реакции",
		/datum/gas/fluxin = FLUXIN_HANDBOOK_FACTOR,
		"Temperature" = "Идёт только между [PN_FORMATION_MIN_TEMPERATURE] и [PN_FORMATION_MAX_TEMPERATURE] К",
		"Energy" = "Выделяет [PN_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/proto_nitrate_hydrogen_response/init_factors()
	name = "Прото-нитрат и водород"
	desc = "Лишний водород прото-нитрат перерабатывает в самого себя. Так контур сам себя раскармливает."
	factor = list(
		/datum/gas/hydrogen = "Расходуется до [PN_HYDROGEN_CONVERSION_MAX_RATE] молей за тик; нужно не меньше [PN_HYDROGEN_CONVERSION_THRESHOLD] молей",
		/datum/gas/proto_nitrate = "Прибавляется в объёме 0.5 от скорости переработки",
		"Energy" = "Поглощает [PN_HYDROGEN_CONVERSION_ENERGY] джоулей на моль переработки",
	)

/datum/gas_reaction/proto_nitrate_tritium_response/init_factors()
	name = "Прото-нитрат и тритий"
	desc = "На умеренном нагреве прото-нитрат разбирает тритий обратно на водород - и тем самым гасит радиацию в контуре."
	factor = list(
		/datum/gas/tritium = "Расходуется один к одному со скоростью переработки",
		/datum/gas/proto_nitrate = "Расходуется в объёме 0.01 от скорости переработки",
		/datum/gas/hydrogen = "Рождается один к одному со скоростью переработки",
		"Temperature" = "Идёт только между [PN_TRITIUM_CONVERSION_MIN_TEMP] и [PN_TRITIUM_CONVERSION_MAX_TEMP] К",
		"Energy" = "Выделяет [PN_TRITIUM_CONVERSION_ENERGY] джоулей на моль переработки",
	)

/datum/gas_reaction/proto_nitrate_bz_response/init_factors()
	name = "Прото-нитрат и BZ"
	desc = "Прото-нитрат разбирает BZ на азот, гелий и плазму. Дорогой, но единственный способ убрать BZ из смеси."
	factor = list(
		/datum/gas/bz = "Расходуется один к одному со скоростью реакции",
		/datum/gas/proto_nitrate = "Расходуется один к одному со скоростью реакции",
		/datum/gas/nitrogen = "Рождается в объёме 0.4 от скорости реакции",
		/datum/gas/helium = "Рождается в объёме 1.6 от скорости реакции",
		/datum/gas/plasma = "Рождается в объёме 0.8 от скорости реакции",
		"Temperature" = "Идёт только между [PN_BZASE_MIN_TEMP] и [PN_BZASE_MAX_TEMP] К",
		"Energy" = "Выделяет [PN_BZASE_ENERGY] джоулей на моль реакции",
	)

/datum/gas_reaction/antinoblium_replication/init_factors()
	name = "Размножение антиноблия"
	desc = "Антиноблий переводит соседние газы в самого себя и остужает смесь. Оставленный без присмотра, он съедает содержимое контура целиком."
	factor = list(
		/datum/gas/antinoblium = "Катализатор; нужно не меньше [MOLES_GAS_VISIBLE] молей",
		"Temperature" = "Нужно выше [REACTION_OPPRESSION_MIN_TEMP] К",
		"Energy" = "Реакция поглощает тепло: смесь остывает по мере переработки",
	)

/datum/gas_reaction/pyronite_formation/init_factors()
	name = "Синтез пиронита"
	desc = "Пиронит варится из трития и плазмы на прото-нитрате как катализаторе. Газовый насос такого давления не даёт: контур додавливают объёмным насосом или нагревом."
	factor = list(
		/datum/gas/tritium = "Расходуется в объёме [PYRONITE_TRITIUM_PER_UNIT] от скорости реакции, нужно не меньше 20 молей",
		/datum/gas/plasma = "Расходуется в объёме [PYRONITE_PLASMA_PER_UNIT] от скорости реакции, нужно не меньше 20 молей",
		/datum/gas/proto_nitrate = "Катализатор, расходуется в объёме [PYRONITE_CATALYST_PER_UNIT] от скорости реакции, нужно не меньше 5 молей",
		/datum/gas/pyronite = "Рождается в объёме [PYRONITE_YIELD_PER_UNIT] от скорости реакции",
		"Temperature" = "Идёт только между [PYRONITE_FORMATION_MIN_TEMP] и [PYRONITE_FORMATION_MAX_TEMP] К",
		"Pressure" = "Нужно не меньше [GAS_HIGH_PRESSURE_SYNTHESIS] кПа - выше потолка газового насоса. Дальнейший рост давления ускоряет реакцию до [PYRONITE_PRESSURE_SCALE_CAP] раз",
		"Energy" = "Поглощает [PYRONITE_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

/datum/gas_reaction/fluxin_formation/init_factors()
	name = "Синтез флюксина"
	desc = "Флюксин варится из гелия, BZ и плазмы. Как и пиронит, требует давления выше потолка газового насоса."
	factor = list(
		/datum/gas/helium = "Расходуется в объёме [FLUXIN_HELIUM_PER_UNIT] от скорости реакции, нужно не меньше 20 молей",
		/datum/gas/bz = "Расходуется в объёме [FLUXIN_BZ_PER_UNIT] от скорости реакции, нужно не меньше 10 молей",
		/datum/gas/plasma = "Расходуется в объёме [FLUXIN_PLASMA_PER_UNIT] от скорости реакции, нужно не меньше 10 молей",
		/datum/gas/fluxin = "Рождается в объёме [FLUXIN_YIELD_PER_UNIT] от скорости реакции",
		"Temperature" = "Идёт только между [FLUXIN_FORMATION_MIN_TEMP] и [FLUXIN_FORMATION_MAX_TEMP] К",
		"Pressure" = "Нужно не меньше [GAS_HIGH_PRESSURE_SYNTHESIS] кПа - выше потолка газового насоса",
		"Energy" = "Поглощает [FLUXIN_FORMATION_ENERGY] джоулей на единицу скорости реакции",
	)

#undef FLUXIN_HANDBOOK_FACTOR
