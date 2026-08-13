import { classes } from 'common/react';

/** Сторона ячейки под иконку - один тайл BYOND. */
const TILE_SIZE = 32;
/** Класс размера листа design для спрайта ровно в тайл: DM его не шлёт, он дефолтный. */
const DEFAULT_SIZE_CLASS = `design${TILE_SIZE}x${TILE_SIZE}`;
const SIZE_CLASS_REGEX = /design(\d+)x(\d+)/;

/**
 * Во сколько раз ужать спрайт, чтобы он целиком поместился в тайл.
 *
 * Класс размера приходит из DM только для спрайтов крупнее тайла (см.
 * oversized_icon_classes): без ужимания широкая иконка обрезалась бы по 32px,
 * а высокая распирала бы строку списка.
 */
export const designIconScale = (sizeClass?: string) => {
  const match = SIZE_CLASS_REGEX.exec(sizeClass || '');
  if (!match) {
    return 1;
  }
  const longestSide = Math.max(
    parseInt(match[1], 10),
    parseInt(match[2], 10),
  );
  if (!longestSide || longestSide <= TILE_SIZE) {
    return 1;
  }
  return TILE_SIZE / longestSide;
};

type DesignIconProps = {
  /** Идентификатор дизайна - он же имя спрайта в листе design. */
  readonly id: string;
  /** Класс размера из design_sizes; пусто - значит спрайт ровно в тайл. */
  readonly sizeClass?: string;
};

/**
 * Иконка дизайна в списках производства. Занимает ровно тайл при любом размере
 * спрайта, поэтому строки списка не разъезжаются по ширине и высоте.
 */
export const DesignIcon = (props: DesignIconProps) => {
  const { id, sizeClass } = props;
  const scale = designIconScale(sizeClass);

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        verticalAlign: 'middle',
        width: `${TILE_SIZE}px`,
        height: `${TILE_SIZE}px`,
        overflow: 'hidden',
        flex: 'none',
      }}>
      <span
        className={classes([sizeClass || DEFAULT_SIZE_CLASS, id])}
        style={scale === 1 ? undefined : { transform: `scale(${scale})` }}
      />
    </span>
  );
};
