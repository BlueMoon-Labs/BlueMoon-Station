/// Max |x|/|y| for IE chips on the TGUI canvas (must match wire-scale panning).
#define IE_TGUI_COMPONENT_COORD_LIMIT 25000

#define IC_TOPIC_UNHANDLED 0
#define IC_TOPIC_HANDLED 1
#define IC_TOPIC_REFRESH 2
#define IC_FLAG_ANCHORABLE 1
#define IC_FLAG_CAN_FIRE 2

/// Max characters for printer "load program" JSON (layout fields etc. inflate size).
#define MAX_IC_PRINTER_JSON_LEN (512 * 1024)
