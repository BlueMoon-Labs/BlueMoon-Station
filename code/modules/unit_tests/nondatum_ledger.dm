/**
 * Книга недатумных аллокаций: арифметика и формулировки.
 *
 * Прибор такого рода ошибается молча - его читают только после того, как раунд уже умер,
 * и проверить задним числом нечем. Поэтому здесь проверяется всё, что можно проверить без
 * живого раунда: ширина книги, монотонность записи, дельта по каждой категории и то, что
 * пустая дельта НАЗЫВАЕТ себя пустой, а не выглядит как содержательная строка из нулей.
 */
/datum/unit_test/nondatum_ledger_arithmetic
	requires_full_map = FALSE

/datum/unit_test/nondatum_ledger_arithmetic/Run()
	// Ширина книги и ширина дефайна обязаны совпадать: разъехавшись, они дают снимок, у
	// которого последняя категория молча всегда нулевая.
	TEST_ASSERT_EQUAL(length(GLOB.nondatum_ledger), NONDATUM_LEDGER_LEN, "Длина книги обязана совпадать с NONDATUM_LEDGER_LEN")

	var/list/before = nondatum_ledger_snapshot()
	TEST_ASSERT_EQUAL(length(before), NONDATUM_LEDGER_LEN, "Снимок обязан быть той же ширины, что и книга")

	note_nondatum_alloc(NONDATUM_LEDGER_ICONS, 3)
	note_nondatum_alloc(NONDATUM_LEDGER_ICON_PIXELS, 2000000)
	note_nondatum_alloc(NONDATUM_LEDGER_ASSET_BYTES, 1048576)
	var/list/after = nondatum_ledger_snapshot()

	// Снимок обязан быть КОПИЕЙ: ссылка на живую книгу означала бы, что дельта всегда ноль.
	TEST_ASSERT_EQUAL(after[NONDATUM_LEDGER_ICONS] - before[NONDATUM_LEDGER_ICONS], 3, "Снимок обязан быть копией, а не ссылкой на живую книгу")

	var/line = nondatum_ledger_delta_line(before, after)
	TEST_ASSERT(findtext(line, "иконок 3"), "Дельта обязана называть число иконок: [line]")
	TEST_ASSERT(findtext(line, "2 Мпикс"), "Дельта обязана называть пиксели иконок: [line]")
	TEST_ASSERT(findtext(line, "1 МБ"), "Дельта обязана переводить байты в мегабайты: [line]")
	// Категории, в которых за окно ничего не было, в строку не попадают: строка из семи
	// нулей читается как содержательная, а сообщает ровно ничего.
	TEST_ASSERT(!findtext(line, "tgui"), "Нулевые категории не должны попадать в строку: [line]")

	// Нулевая и отрицательная запись отсекается в одной точке - у вызывающих нет своих гардов.
	var/list/guard_before = nondatum_ledger_snapshot()
	note_nondatum_alloc(NONDATUM_LEDGER_TGUI_BYTES, 0)
	note_nondatum_alloc(NONDATUM_LEDGER_TGUI_BYTES, -5)
	var/list/guard_after = nondatum_ledger_snapshot()
	TEST_ASSERT_EQUAL(guard_after[NONDATUM_LEDGER_TGUI_BYTES], guard_before[NONDATUM_LEDGER_TGUI_BYTES], "Нулевая и отрицательная запись не должны двигать книгу")

	// Пустая дельта - это ОТВЕТ ("ни один известный аллокатор не работал"), и он обязан
	// быть произнесён вслух: без него читатель решает, что прибор просто промолчал.
	var/empty_line = nondatum_ledger_delta_line(guard_before, guard_after)
	TEST_ASSERT(findtext(empty_line, "пусто"), "Пустая дельта обязана называть себя пустой: [empty_line]")

	// Первый скачок раунда приходит без предыдущего снимка - строка обязана это пережить.
	TEST_ASSERT(findtext(nondatum_ledger_delta_line(null, after), "снимка нет"), "Отсутствие снимка обязано быть названо, а не выдано за пустую книгу")
	TEST_ASSERT(findtext(nondatum_ledger_delta_line(list(0), after), "снимка нет"), "Снимок неправильной ширины обязан быть отвергнут")

	// Единственное непроверяемое допущение книги: length() на ресурсе отдаёт БАЙТЫ, а не
	// длину его строкового представления. Ошибись оно - и все байтовые категории тихо
	// встали бы в ноль, а строка скачка читалась бы как "аллокаторы не работали".
	var/resource_bytes = length(file('icons/effects/effects.dmi'))
	TEST_ASSERT(resource_bytes > 100, "length() на файле-ресурсе обязан отдавать его вес в байтах, получено [resource_bytes]")

/**
 * Выход getFlatIcon по оверлею ниже -1000 обязан попадать в книгу.
 *
 * Сборка плоской иконки - крупнейший известный недатумный аллокатор, и учёт стоит в хвосте
 * прока. Но оверлей с layer <= -1000 отдаёт собранную заготовку прямо из середины цикла, и
 * этот путь проходил мимо учёта молча. Недосчитанная иконка неотличима от честного нуля -
 * ровно то различие, ради которого книга и заведена, поэтому путь закрыт тестом.
 *
 * Иконка и стейт подобраны произвольно: несуществующий стейт лишь поднимает noIcon, а до
 * ветки оверлеев поток доходит в любом случае - её открывает непустой overlays.
 */
/datum/unit_test/nondatum_ledger_counts_early_return_icon
	requires_full_map = FALSE

/datum/unit_test/nondatum_ledger_counts_early_return_icon/Run()
	var/image/subject = image('icons/effects/effects.dmi')
	var/image/deep_overlay = image('icons/effects/effects.dmi')
	deep_overlay.layer = -1001
	// Смещение - это ДЕТЕКТОР ветки, а не украшение. Пройди поток мимо раннего выхода,
	// оверлей вклеился бы со сдвигом и заготовка расширилась бы; ранний выход отдаёт её
	// нетронутой. Без этой проверки тест засчитал бы учёт из хвоста прока и прошёл бы
	// вхолостую даже с откаченной правкой.
	deep_overlay.pixel_x = 64
	subject.overlays += deep_overlay
	TEST_ASSERT(length(subject.overlays), "оверлей не лёг на подопытного - тест не дошёл бы до проверяемой ветки")

	var/icon/template = icon('icons/effects/effects.dmi', "nothing")
	var/list/before = nondatum_ledger_snapshot()
	var/icon/flat = getFlatIcon(subject, no_anim = TRUE)
	var/list/after = nondatum_ledger_snapshot()

	TEST_ASSERT_EQUAL(flat.Width(), template.Width(), "заготовка расширилась - значит ранний выход по оверлею ниже -1000 не сработал и проверка ниже ничего не значит")
	TEST_ASSERT_EQUAL(after[NONDATUM_LEDGER_ICONS] - before[NONDATUM_LEDGER_ICONS], 1, "ранний выход по оверлею ниже -1000 обязан считаться книгой ровно один раз")
