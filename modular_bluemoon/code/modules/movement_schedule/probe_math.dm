// Счётная часть зонда шагов. Мира не касается, поэтому проверяется тестами.

/// Интервал между двумя шагами в целых тиках. world.time приходит с плавающим
/// хвостом, а шаг случается только на тике, поэтому округляем к ближайшему.
/proc/movement_probe_tick_delta(now, previous, tick_lag)
	if(isnull(previous) || tick_lag <= 0)
		return 0
	return round(((now - previous) / tick_lag) + 0.5)

/// За сколько тиков атом пересечёт тайл с данным glide_size.
///
/// Живёт здесь, а не в математике расписания: боевой код glide только
/// выставляет, обращать его назад нужно одному замеру.
/proc/movement_probe_ticks_to_cross(glide_size, icon_size)
	if(glide_size <= 0)
		return INFINITY
	return icon_size / glide_size

/// Сколько тиков атом простоял, доехав до тайла раньше следующего шага.
/// Отрицательное значение означает обратное - его двинули, пока он ещё ехал.
/// Знак сохраняем: это два разных диагноза, и путать их нельзя.
/proc/movement_probe_idle_ticks(glide_size, icon_size, actual_ticks)
	return actual_ticks - movement_probe_ticks_to_cross(glide_size, icon_size)

/// На сколько пикселей спрайт не доехал до тайла к моменту следующего шага.
///
/// Считать недоезд в тиках и смотреть на знак бессмысленно: любой множитель
/// чуть меньше единицы делает отрицательным почти каждый шаг, и счётчик
/// показывает 90% при недоезде в четверть пикселя. Видно глазом не знак, а
/// величину - её и меряем, сразу в пикселях.
/proc/movement_probe_undershoot_pixels(glide_size, icon_size, actual_ticks)
	return max(0, icon_size - (glide_size * actual_ticks))

/// Скачок недоезда между соседними шагами - вот что действительно видно.
///
/// Сам по себе уровень недоезда глазу недоступен. При LONG_GLIDE спрайт не
/// прыгает на новый тайл, а продолжает ехать из той точки, где стоит, поэтому
/// постоянный недоезд - это постоянное отставание спрайта от серверной позиции,
/// то есть просто сдвиг картинки на пиксель. Его нельзя заметить, не с чем
/// сравнивать.
///
/// Заметен переход: шаг доехал полностью, следующий отстал на треть тайла - вот
/// здесь скорость спрайта меняется рывком. Ровно это и меряем.
///
/// Практический пример, ради которого метрика и переделана: при просевшем на
/// 3% сервере множитель glide честно уводит недоезд в пиксель на КАЖДОМ шаге.
/// Уровень кричит "302 шага из 397", скачок молчит - и молчит правильно.
/proc/movement_probe_undershoot_jump(undershoot, previous_undershoot)
	return abs(undershoot - previous_undershoot)

/// Почему интервал между шагами получился таким. Разбор идёт от самой
/// конкретной причины к самой общей.
///
/// Смена скорости сверяется по базовой цене, до диагонали: после выравнивания
/// по тику прямой ход и диагональ стоят разное и чередуются постоянно, и по
/// итоговой цене каждый поворот выглядел бы сменой скорости.
/proc/movement_probe_classify(actual_ticks, nominal_ticks, base_changed, moved)
	if(!moved)
		return MOVEMENT_PROBE_BLOCKED
	if(base_changed)
		return MOVEMENT_PROBE_SPEED_CHANGE
	if(actual_ticks > nominal_ticks + MOVEMENT_PROBE_STALL_MARGIN)
		return MOVEMENT_PROBE_STALL
	return MOVEMENT_PROBE_NORMAL

/// Насколько серверное время поспевало за настоящим на отрезке между шагами.
/// Единица означает, что сервер шёл вровень, меньше - что он проседал.
/proc/movement_probe_dilation(world_delta, real_delta)
	if(real_delta <= 0)
		return 1
	return world_delta / real_delta

/// Кто виноват в паузе.
///
/// Длинный интервал сам по себе диагноза не даёт, и одного числа тиков мало.
/// Разводим три случая: сервер проседал, игрок сам отпустил клавишу, и
/// клавиша была зажата насквозь при исправном сервере - вот это и есть
/// настоящая потеря ввода.
///
/// Между "проседал" и "шёл вровень" есть полоса, где вердикт по одному замеру
/// ненадёжен. Делать вид, что он надёжен, хуже, чем честно сказать "на грани":
/// худший выброс прошлого забега дал ровно 0.903 при пороге 0.9 и был назван
/// не-сервером на разнице в три тысячных.
/proc/movement_probe_stall_source(dilation, key_held_through)
	if(dilation < MOVEMENT_PROBE_DILATION_MARGIN)
		return MOVEMENT_PROBE_STALL_SERVER
	if(dilation < MOVEMENT_PROBE_DILATION_UNCERTAIN)
		return MOVEMENT_PROBE_STALL_UNCLEAR
	if(!key_held_through)
		return MOVEMENT_PROBE_STALL_RELEASED
	return MOVEMENT_PROBE_STALL_ELSEWHERE

/// Была ли клавиша движения зажата всю паузу насквозь.
///
/// keys_held хранит момент нажатия, поэтому вопрос решается одним сравнением:
/// если самую старую зажатую клавишу нажали уже после предыдущего шага, игрок
/// её отпускал, и пауза - его собственная. Если раньше - он держал её всё
/// время, и шаг не состоялся не по его вине.
/proc/movement_probe_key_held_through(key_pressed_at, previous_step_time)
	if(!key_pressed_at)
		return FALSE
	return key_pressed_at <= previous_step_time

/// Момент нажатия самой старой из зажатых сейчас клавиш движения.
/// Ноль означает, что ни одной не зажато.
/proc/movement_probe_movement_key_time(list/keys_held, list/movement_keys)
	. = 0
	if(!length(keys_held) || !length(movement_keys))
		return 0
	for(var/key in keys_held)
		if(!movement_keys[key])
			continue
		var/pressed = keys_held[key]
		if(!. || pressed < .)
			. = pressed

/// Стоит ли показывать интервал в списке выбросов.
///
/// Критерий один и тот же для всех причин: шаг попадает в список, только если
/// он чего-то стоил - уехал от номинала больше чем на тик или дёрнул спрайт.
/// Сама причина роли не играет.
///
/// Раньше упор в препятствие попадал сюда безусловно, и на чистом забеге список
/// выглядел так: восемь строк "3 тика против номинала 3, простой 0 мс, скачок
/// 0 px" и одна настоящая. Упор в стену - обычная игра, он ничего не стоит,
/// пока укладывается в свой номинал, а сколько его было, видно из гистограммы
/// причин. Дорогой упор - тот, что съел лишние тики, - проходит по общему
/// правилу и остаётся виден.
///
/// Судим по скачку недоезда, а не по его уровню. Прежний порог в четверть тика
/// ловил уровень, и на слегка просевшем сервере в выбросы попадала половина
/// забега - 192 строки из 397 шагов, среди них "11 тиков против номинала 11,
/// простой -15 мс". Список, в котором выброс - каждый второй шаг, не список.
/proc/movement_probe_is_outlier(undershoot_jump, actual_ticks, nominal_ticks)
	if(abs(actual_ticks - nominal_ticks) > MOVEMENT_PROBE_STALL_MARGIN)
		return TRUE
	return undershoot_jump >= MOVEMENT_PROBE_UNDERSHOOT_JUMP_PIXELS

/// Сколько раз встретилось каждое значение. Ключи текстовые: обращение к
/// списку по числовому ключу в DM читается как индекс, а не как ключ.
/proc/movement_probe_histogram(list/values)
	var/list/counts = list()
	for(var/value in values)
		var/key = "[value]"
		counts[key] = (counts[key] || 0) + 1
	return counts

/// Гистограмма в одну строку: "5 тик(ов) x3, 6 тик(ов) x2".
///
/// Единица измерения приходит снаружи, потому что строка печатает и интервалы,
/// и причины. Зашитое "тик(ов)" давало в отчёте "норма тик(ов) x101".
/proc/movement_probe_histogram_line(list/histogram, unit)
	var/list/parts = list()
	for(var/key in histogram)
		parts += "[unit ? "[key] [unit]" : key] x[histogram[key]]"
	return parts.Join(", ")
