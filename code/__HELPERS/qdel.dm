// This is a bit hacky, we do it to avoid people relying on a return value for the macro
// If you need that you should use QDEL_IN_STOPPABLE instead
#define QDEL_IN(item, time) ; \
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), (time) > GC_FILTER_QUEUE ? WEAKREF(item) : item), time);
#define QDEL_IN_STOPPABLE(item, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), (time) > GC_FILTER_QUEUE ? WEAKREF(item) : item), time, TIMER_STOPPABLE)
#define QDEL_IN_CLIENT_TIME(item, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel_weakref_resolve), (time) > GC_FILTER_QUEUE ? WEAKREF(item) : item), time, TIMER_STOPPABLE | TIMER_CLIENT_TIME)
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

/proc/______qdel_list_wrapper(list/L) //the underscores are to encourage people not to use this directly.
	QDEL_LIST(L)
