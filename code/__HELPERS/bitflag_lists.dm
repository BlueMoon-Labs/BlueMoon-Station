GLOBAL_LIST_EMPTY(bitflag_lists)

#define SET_SMOOTHING_GROUPS(read_from, set_into) \
	do { \
		var/txt_signature = read_from; \
		if(isnull((set_into = GLOB.bitflag_lists[txt_signature]))) { \
			var/list/new_bitflag_list = list(); \
			var/list/decoded = UNWRAP_SMOOTHING_GROUPS(txt_signature, decoded); \
			for(var/value in decoded) { \
				if (value < 0) { \
					value = MAX_S_TURF + 1 + abs(value); \
				} \
				new_bitflag_list["[round(value / 24)]"] |= (1 << (value % 24)); \
			}; \
			set_into = GLOB.bitflag_lists[txt_signature] = new_bitflag_list; \
		}; \
	} while (FALSE)
