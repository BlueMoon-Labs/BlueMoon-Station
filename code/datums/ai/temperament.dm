// Характер особи: два карпа одного типа не обязаны вести себя одинаково.
//
// Вся вариативность поведения до этого была на уровне ТИПА: один и тот же
// профиль давал один и тот же порог отступления, ту же паузу обнаружения и то же
// терпение погони у каждого экземпляра. Характер сдвигает эти пороги на особь.
//
// Пресеты именованные, а не чистый рандом по трём шкалам, намеренно: игрок
// должен читать поведение как характер ("этот трусливый"), а не как шум. Пять
// пресетов плюс обычный, взвешенно - большинство мобов остаются обычными, и
// характер работает как исключение, которое видно.

///Взвешенный пул характеров: тип -> вес. Обычный доминирует намеренно.
GLOBAL_LIST_INIT(ai_temperament_weights, list(
	/datum/ai_temperament = 10,
	/datum/ai_temperament/skittish = 3,
	/datum/ai_temperament/bold = 3,
	/datum/ai_temperament/stubborn = 2,
	/datum/ai_temperament/cautious = 2,
	/datum/ai_temperament/curious = 2,
))

///Синглтоны характеров: тип -> инстанс
GLOBAL_LIST_EMPTY(ai_temperaments)

/datum/ai_temperament
	var/name = "обычный"
	///Множитель порога здоровья, ниже которого моб отступает. Больше = трусливее.
	var/retreat_threshold_mult = 1
	///Множитель читаемой паузы перед броском. Больше = дольше присматривается.
	var/alert_pause_mult = 1
	///Множитель терпения и поводка погони. Больше = дольше не отпускает.
	var/pursuit_mult = 1
	///Множитель вероятности уворота в ближнем бою.
	var/dodge_mult = 1

///Робкий: отступает рано, присматривается долго, гонится недалеко
/datum/ai_temperament/skittish
	name = "робкий"
	retreat_threshold_mult = 1.5
	alert_pause_mult = 1.4
	pursuit_mult = 0.6
	dodge_mult = 1.3

///Дерзкий: бросается почти без паузы и дерётся до последнего
/datum/ai_temperament/bold
	name = "дерзкий"
	retreat_threshold_mult = 0.6
	alert_pause_mult = 0.4
	pursuit_mult = 1.2
	dodge_mult = 0.8

///Упрямый: отпускать цель не умеет, но и уворачиваться не считает нужным
/datum/ai_temperament/stubborn
	name = "упрямый"
	retreat_threshold_mult = 0.8
	pursuit_mult = 1.8
	dodge_mult = 0.7

///Осторожный: рано отходит и активно виляет
/datum/ai_temperament/cautious
	name = "осторожный"
	retreat_threshold_mult = 1.3
	alert_pause_mult = 1.2
	pursuit_mult = 0.9
	dodge_mult = 1.4

///Любопытный: реагирует быстро и идёт проверять дальше прочих
/datum/ai_temperament/curious
	name = "любопытный"
	alert_pause_mult = 0.7
	pursuit_mult = 1.3

///Синглтон характера по типу
/proc/get_ai_temperament(temperament_type)
	if(!temperament_type)
		temperament_type = /datum/ai_temperament
	. = GLOB.ai_temperaments[temperament_type]
	if(.)
		return
	. = new temperament_type
	GLOB.ai_temperaments[temperament_type] = .

///Характер этого контроллера. Роллится лениво и один раз: так за него не платят
///мобы, которые за раунд ни разу не подрались, и порядок инициализации профилей
///на результат не влияет.
/datum/ai_controller/proc/get_temperament()
	if(temperament)
		return temperament
#ifdef UNIT_TESTS
	//В тестах характер по умолчанию нейтральный. Иначе случайный ролл сдвигает
	//ровно те пороги, которые тесты проверяют на точные значения (пауза
	//обнаружения, порог отступления, поводок погони), и каждый тест на тайминг
	//боя становится флаки с вероятностью, зависящей от веса пресета. Тест,
	//которому нужен характер, назначает его полю temperament явно.
	temperament = get_ai_temperament()
	return temperament
#endif
	temperament = get_ai_temperament(pickweight(GLOB.ai_temperament_weights))
	return temperament
