/**
 * Разбор газовой смеси, отданной /proc/gas_mixture_parser: состав, параметры и
 * реакции. Компонент общий - его берут окна анализатора, омни-машин и канистры,
 * поэтому он не знает ни одного конкретного интерфейса, не ходит в стор и всё
 * получает пропсами.
 *
 * @file
 * @license MIT
 */
import { ReactNode } from 'react';

import { Box, Button, LabeledList } from '../../components';
import { getGasColor, getGasName } from '../../constants';

/** Газ: строковый идентификатор, английское имя от бэкенда, моли. */
export type GasmixGas = [string, string, number];

/**
 * Реакция: идентификатор, имя, значение. Значение всегда null - слой данных
 * отдаёт реакции-КАНДИДАТЫ, потому что идущие реакции себя нигде не отмечают.
 */
export type GasmixReaction = [string, string, number | null];

export type Gasmix = {
  name?: string;
  gases: GasmixGas[];
  temperature: number | null;
  volume: number | null;
  pressure: number | null;
  total_moles: number | null;
  reactions: GasmixReaction[];
  reference: string;
};

type GasmixParserProps = {
  gasmix: Gasmix;
  gasesOnClick?: (gas_id: string) => void;
  temperatureOnClick?: () => void;
  volumeOnClick?: () => void;
  pressureOnClick?: () => void;
  reactionOnClick?: (reaction_id: string) => void;
  /** Показывать реакции отдельными строками со значением, а не общим списком. */
  detailedReactions?: boolean;
};

/** Число с единицей измерения; прочерк, если бэкенд значения не дал. */
const formatValue = (value: number | null, unit: string): string =>
  typeof value === 'number' ? `${value.toFixed(2)} ${unit}` : `- ${unit}`;

/**
 * Подпись значения реакции. Числа у нас нет и не будет, пока реакции не начнут
 * отмечаться в смеси, поэтому кандидат подписывается словом, а не пустотой.
 */
const formatReaction = (amount: number | null): string =>
  typeof amount === 'number' ? amount.toFixed(2) : 'возможна';

/** Подпись строки: кнопка, если на неё есть обработчик, иначе просто текст. */
const clickableLabel = (label: string, onClick?: () => void): ReactNode =>
  onClick ? <Button content={label} onClick={onClick} /> : label;

export const GasmixParser = (props: GasmixParserProps) => {
  const {
    gasmix,
    gasesOnClick,
    temperatureOnClick,
    volumeOnClick,
    pressureOnClick,
    reactionOnClick,
    detailedReactions,
  } = props;

  const { gases, temperature, volume, pressure, total_moles, reactions } =
    gasmix;

  if (!total_moles) {
    return (
      <Box nowrap italic mb="10px">
        Газ не обнаружен!
      </Box>
    );
  }

  return (
    <LabeledList>
      {gases.map((gas) => (
        <LabeledList.Item
          key={gas[0]}
          labelColor={getGasColor(gas[0]) || 'label'}
          label={clickableLabel(
            // Бэкенд шлёт английское имя - оно запасное, показываем русское.
            getGasName(gas[0], gas[1]),
            gasesOnClick && (() => gasesOnClick(gas[0])),
          )}
        >
          {`${gas[2].toFixed(2)} моль (${((gas[2] / total_moles) * 100).toFixed(2)} %)`}
        </LabeledList.Item>
      ))}
      <LabeledList.Item label={clickableLabel('Температура', temperatureOnClick)}>
        {formatValue(temperature, 'К')}
      </LabeledList.Item>
      <LabeledList.Item label={clickableLabel('Объём', volumeOnClick)}>
        {formatValue(volume, 'л')}
      </LabeledList.Item>
      <LabeledList.Item label={clickableLabel('Давление', pressureOnClick)}>
        {formatValue(pressure, 'кПа')}
      </LabeledList.Item>
      {detailedReactions ? (
        reactions.map((reaction) => (
          <LabeledList.Item
            key={`${gasmix.reference}-${reaction[0]}`}
            label={clickableLabel(
              reaction[1],
              reactionOnClick && (() => reactionOnClick(reaction[0])),
            )}
          >
            {formatReaction(reaction[2])}
          </LabeledList.Item>
        ))
      ) : (
        <LabeledList.Item label="Возможные реакции">
          {reactions.length > 0
            ? reactions.map((reaction) => (
              <Box key={reaction[0]} mb="0.5em">
                {reactionOnClick ? (
                  <Button
                    content={reaction[1]}
                    onClick={() => reactionOnClick(reaction[0])}
                  />
                ) : (
                  reaction[1]
                )}
                {`: ${formatReaction(reaction[2])}`}
              </Box>
            ))
            : 'Подходящих реакций нет'}
        </LabeledList.Item>
      )}
    </LabeledList>
  );
};
