/// Окно, за которое считаются база, детекторы и вердикт.
#define PING_DIAG_WINDOW_DS (5 MINUTES)
/// Ёмкость кольца сэмплов без окна диагностики: пять минут рассылок раз в 1.8 с и запас.
#define PING_DIAG_BASE_SAMPLES 200
/// Ёмкость кольца у того, на кого смотрит окно: пять минут ускоренного замера раз в 0.5 с и запас.
#define PING_DIAG_MAX_SAMPLES 800
/// Номер пачки в команде ускоренного замера: настоящие пачки нумеруются с 1.
#define PING_DIAG_PROBE_BATCH -1
/// Сколько ускоренных замеров может висеть без ответа: остальные ответы не принимаются.
#define PING_DIAG_MAX_PROBES_IN_FLIGHT 10
/// Потолок замера от клиента, мс.
#define PING_DIAG_MAX_RTT_MS 60000
/// Больше открытых пачек - старые закрываются силой.
#define PING_DIAG_MAX_OPEN_BATCHES 10
/// Сколько последних пачек массового молчания помнить для поздних ответов.
#define PING_DIAG_MAX_MASS_BATCHES 20
/// Меньше ответивших в пачке - общую задержку не считаем.
#define PING_DIAG_SHARED_MIN_CLIENTS 5
/// Через сколько пачка закрывается, а молчащий клиент считается подвисшим.
#define PING_DIAG_BATCH_CLOSE_DS 30
#define PING_DIAG_SPIKE_MIN_MS 100
#define PING_DIAG_SPIKE_MEDIAN_FACTOR 3
/// TCP повторяет потерянный сегмент не раньше чем через ~200 мс.
#define PING_DIAG_LOSS_MIN_MS 180
/// Спайки ближе этого склеиваются в один эпизод.
#define PING_DIAG_BURST_GAP_DS 50
#define PING_DIAG_PERIODIC_MIN_SPIKES 4
#define PING_DIAG_PERIODIC_MAX_CV 0.15
#define PING_DIAG_SHARED_EVENT_MS 60
#define PING_DIAG_SHARED_EVENT_FRACTION 0.6
#define PING_DIAG_SERVER_LOAD_CPU 90
/// Как TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD: выше - рассылка карты съедает тик.
#define PING_DIAG_SERVER_LOAD_MAP_CPU 30
/// Как heavy_run_threshold детектора тик-спайков: прогон подсистемы на столько % тика держит ответы на пинг.
#define PING_DIAG_SERVER_LOAD_RUN 40
/// Меньше этой доли замеров с известной общей задержкой - подсказку в чат не шлём.
#define PING_DIAG_SHARED_KNOWN_MIN 0.5
#define PING_DIAG_MIN_SAMPLES 20
#define PING_DIAG_NOTICEABLE_EXTRA_MS 20
#define PING_DIAG_FREEZE_MIN 2
#define PING_DIAG_PC_LOOP_LAG_MS 50
#define PING_DIAG_PC_MIN_FPS 20
#define PING_DIAG_LOSS_PER_MIN 1
#define PING_DIAG_JITTER_MS 30
#define PING_DIAG_FAR_BASE_MS 150
#define PING_DIAG_FAR_MIN_MS 80
#define PING_DIAG_BROWSER_HISTORY 12
/// Окно потока чата: сколько сообщений в секунду SSchat шлёт клиенту.
#define PING_DIAG_FLOOD_WINDOW_DS (30 SECONDS)
#define PING_DIAG_FLOOD_BUCKETS (PING_DIAG_FLOOD_WINDOW_DS / (1 SECONDS))
/// Короче наблюдать поток не считаем: первая пачка после входа не раздувает число.
#define PING_DIAG_FLOOD_MIN_SPAN_DS (10 SECONDS)
/// Живой прогон: клиент разбирает около 40 сообщений/с, и DS-пинг стоит в той же очереди.
#define PING_DIAG_FLOOD_RATE 10
/// p95 выше базы на столько - след очереди за чатом.
#define PING_DIAG_FLOOD_P95_EXTRA_MS 200
#define PING_DIAG_CHAT_MAX_MESSAGES 100000
#define PING_DIAG_FAST_PROBE_DS 5
#define PING_DIAG_VERDICT_EVERY_DS (10 SECONDS)
#define PING_DIAG_CSV_EVERY_DS (1 MINUTES)
#define PING_DIAG_HINT_HOLD_DS (3 MINUTES)
#define PING_DIAG_MAX_EVENTS 100
#define PING_DIAG_GRAPH_POINTS 300
#define PING_DIAG_REPORT_MAX_LEN 3000

#define PING_VERDICT_COLLECTING "collecting"
#define PING_VERDICT_OK "ok"
#define PING_VERDICT_SERVER "server"
#define PING_VERDICT_FLOOD "flood"
#define PING_VERDICT_FREEZE "freeze"
#define PING_VERDICT_PC "pc"
#define PING_VERDICT_PERIODIC "periodic"
#define PING_VERDICT_LOSS "loss"
#define PING_VERDICT_JITTER "jitter"
#define PING_VERDICT_FAR "far"

#define PING_EVENT_SERVER_STALL "server"
#define PING_EVENT_SERVER_LOAD "server_load"
#define PING_EVENT_HOST_NETWORK "host_network"
/// Пачка закрылась, а молчат почти все: обрыв канала или сервера, не подвисания игроков.
#define PING_EVENT_MASS_FREEZE "mass_freeze"

/// Радиус "людей рядом" в тайлах: примерно экран.
#define PING_DIAG_NEAR_RANGE 10

#define PING_DIAG_CSV_HEADER "time,world_time,ckey,build,mob_kind,view,z_clients,near_clients,samples,base,rtt_median,rtt_p95,personal_median,spikes_per_min,loss_per_min,period_s,freezes,stall_mean,shared_mean,personal_mean,loop_lag,fps,browser_rtt,chat_rate,chat_messages,verdict,old_build"
/// Хвост ss_* - цена самой подсистемы за минуту: фаеры, их сумма и максимум, чтение /proc, запись логов, расчёт минутных строк, мс.
#define PING_DIAG_HOST_CSV_HEADER "time,world_time,clients,tx_kbps,rx_kbps,retrans_per_min,retrans_pct,shared_events,ours_fraction,ss_fires,ss_fire_ms,ss_fire_max_ms,ss_proc_read_ms,ss_log_write_ms,ss_rows_ms"

/// Таймеры rustg_time_microseconds для самозамера подсистемы.
#define PING_DIAG_FIRE_TIMER "ping_diag_fire"
#define PING_DIAG_IO_TIMER "ping_diag_io"
#define PING_DIAG_ROWS_TIMER "ping_diag_rows"
