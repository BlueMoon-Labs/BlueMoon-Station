#define SOLAR_TIME(display_only, wtime) ((((wtime - SSticker.round_start_time) * SSticker.station_time_rate_multiplier) + SSticker.gametime_offset) % 864000) - (display_only? GLOB.timezoneOffset : 0)

#define SOLAR_TIME_TIMESTAMP(format, wtime) time2text(SOLAR_TIME(TRUE, wtime), format)

/// Сдвиг московского времени от UTC: игрокам часы показываются по МСК
#define MSK_UTC_OFFSET_HOURS 3
