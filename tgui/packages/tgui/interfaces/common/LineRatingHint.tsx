import { Box } from '../../components';

/**
 * Номинал линии на выходе устройства и что будет, если его перекрыть.
 *
 * У труб есть рабочее давление, и превышение медленно их портит. Без этой
 * строки игрок узнаёт правило только по факту: свищ уже шипит, а почему -
 * непонятно. Поэтому подсказка висит всегда, а не только при перегрузе, и
 * никогда ничего не блокирует: она информирует, а решает игрок.
 */

// Во сколько раз давление должно перекрыть номинал, чтобы дойти до разрыва.
// Держать в согласии с PIPE_STRESS_RUPTURE_RATIO в atmospherics.dm.
const RUPTURE_RATIO = 1.8;

// На чём останавливается объёмный насос. MAX_OUTPUT_PRESSURE обычного насоса
// вдвое ниже, поэтому разорвать линию способен только объёмный.
// Держать в согласии с VOLUME_PUMP_PRESSURE_CEILING в atmospherics.dm.
const VOLUME_PUMP_CEILING = 9000;

type Props = {
  /** Номинал слабейшего звена выходной линии. Нет линии - нет и подсказки. */
  rating?: number | null;
  /** Что сравнивать с номиналом: уставку насоса или текущее давление. */
  value?: number | null;
  /**
   * target - устройство задаёт давление напрямую, сравниваем уставку.
   * flow - устройство задаёт расход, уставку сравнивать бессмысленно;
   *   говорим про потолок, до которого оно не остановится.
   * info - справка без предупреждений, для порогов не по давлению.
   */
  variant?: 'target' | 'flow' | 'info';
};

export const LineRatingHint = (props: Props) => {
  const { rating, value, variant = 'target' } = props;
  if (!rating) {
    return null;
  }
  const base = `Номинал линии: ${rating} кПа`;
  const current = value ?? 0;

  if (variant === 'info') {
    return <Box color="label">{base}</Box>;
  }

  if (variant === 'flow') {
    if (current > rating) {
      return (
        <Box color="bad">
          {base} — насос не остановится до {VOLUME_PUMP_CEILING} кПа, это выше
          предела линии
        </Box>
      );
    }
    return <Box color="label">{base}</Box>;
  }

  if (current > rating * RUPTURE_RATIO) {
    return <Box color="bad">{base} — выше предела, линию разорвёт</Box>;
  }
  if (current > rating) {
    return (
      <Box color="average">{base} — выше номинала, линия начнёт травить</Box>
    );
  }
  return <Box color="label">{base}</Box>;
};
