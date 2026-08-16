// Ссылка в отложенном qdel'е ВСЕГДА слабая.
//
// Раньше короткие таймеры (<= GC_FILTER_QUEUE, две минуты) клали в колбэк жёсткую
// ссылку - якобы дешевле, чем заводить weakref. Цена оказалась другой: пока таймер
// не сработал, объект держится этой ссылкой, а окно варнфейла сборщика - ровно те
// же две минуты. Любой объект, которого удалили ДРУГИМ путём раньше срока
// (спейсвинд-визуал на сменившемся турфе, эффект на удалённом атоме), гарантированно
// не собирался и уезжал в харддел - а харддел морозит весь процесс на 150-690 мс.
// В проде это 26 хардделов space_wind на 4.3 секунды заморозки за 16 раундов, и
// столько же по остальным temp_visual.
//
// qdel_weakref_resolve() принимает обе формы, поэтому все 173 места вызова
// работают без правок: неразрешившийся weakref означает "объекта уже нет", то
// есть ровно то, ради чего отложенный qdel и заводили.
//
// Исключений два, и оба идут сильной ссылкой. Первое - не-датумы (WEAKREF() на них
// даёт null, и отложенный qdel стал бы no-op). Второе - /client: у нас он объявлен
// с parent_type = /datum (client_defines.dm), то есть isdatum() на нём ИСТИНЕН и
// без явной развилки клиент уехал бы слабой ссылкой. AFK-кик в SSserver_maint
// делает QDEL_IN(C, 1) и обязан дойти до qdel(), а разрешаемость weakref'а на
// клиенте (locate() по его \ref, сверка weak_reference) - лишний вопрос там, где
// ссылку можно просто не ослаблять: держим её один тик, как было до этой правки.
//
// Развилка живёт в проке, а не в тернарнике макроса: аргумент бывает выражением с
// побочным эффектом (QDEL_IN(new /obj/..., 5) в тресерах), и двойная подстановка
// создала бы второй объект, который уже никто не удалит.
#define QDEL_IN_TARGET(item) qdel_in_target(item)
// This is a bit hacky, we do it to avoid people relying on a return value for the macro
// If you need that you should use QDEL_IN_STOPPABLE instead
#define QDEL_IN(item, time) ; \
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), QDEL_IN_TARGET(item)), time);
#define QDEL_IN_STOPPABLE(item, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), QDEL_IN_TARGET(item)), time, TIMER_STOPPABLE)
#define QDEL_IN_CLIENT_TIME(item, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), QDEL_IN_TARGET(item)), time, TIMER_STOPPABLE | TIMER_CLIENT_TIME)
#define QDEL_NULL(item) qdel(item); item = null
// Итерируем снапшот, а не сам список. Очень многие Destroy() вычёркивают себя из списка
// владельца по ходу удаления - так делают /obj/item/bodypart, /obj/item/organ, /datum/quirk,
// /datum/surgery и другие. BYOND при удалении текущего элемента во время for(var/I in L)
// сдвигает индекс и пропускает КАЖДЫЙ ВТОРОЙ элемент: половина списка оставалась живой и
// с живой ссылкой на владельца. Copy() на пути разрушения дешевле такой утечки.
#define QDEL_LIST(L) if(L) { for(var/qdel_list_item in (L).Copy()) qdel(qdel_list_item); (L).Cut(); }
#define QDEL_LIST_IN(L, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(______qdel_list_wrapper), L), time, TIMER_STOPPABLE)
#define QDEL_LIST_ASSOC(L) if(L) { var/list/qdel_list_snapshot = (L).Copy(); for(var/qdel_list_key in qdel_list_snapshot) { qdel(qdel_list_snapshot[qdel_list_key]); qdel(qdel_list_key); } (L).Cut(); }
#define QDEL_LIST_ASSOC_VAL(L) if(L) { var/list/qdel_list_snapshot = (L).Copy(); for(var/qdel_list_key in qdel_list_snapshot) qdel(qdel_list_snapshot[qdel_list_key]); (L).Cut(); }

/// Что именно кладётся в колбэк отложенного qdel'а: слабая ссылка на датум, сам
/// объект - на /client и на всё, что датумом не является. См. шапку файла.
/proc/qdel_in_target(item)
	if(istype(item, /client))
		return item
	return isdatum(item) ? WEAKREF(item) : item

/proc/______qdel_list_wrapper(list/L) //the underscores are to encourage people not to use this directly.
	QDEL_LIST(L)
