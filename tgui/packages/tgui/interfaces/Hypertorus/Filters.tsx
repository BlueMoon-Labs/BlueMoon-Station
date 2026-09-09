import { toFixed } from 'common/math';

import { useBackend } from '../../backend';
import { Box, Button, Icon, LabeledList, Section, Slider, Tooltip } from '../../components';
import { getGasName } from '../../constants';
import { gasCountWord, getLimit, WASTE_REMOVE_MAX_POWER_LEVEL } from './helpers';
import { HypertorusData } from './types';

/**
 * Отвод отходов из модератора. Скорость фильтрации делится поровну между
 * выбранными газами - это единственное место, где число галочек меняет темп.
 */
export const Filters = () => {
  const { act, data } = useBackend<HypertorusData>();
  const { waste_remove, mod_filtering_rate, filter_types = [], power_level } = data;
  const limit = getLimit(data.limits, 'filtering_rate');
  const enabled = filter_types.filter((filter) => filter.enabled);
  const perGasRate = enabled.length ? mod_filtering_rate / enabled.length : 0;
  const present = new Set(
    (data.moderator_gases ?? [])
      .filter((gas) => gas.amount > 0.01)
      .map((gas) => gas.id),
  );
  const wasteLocked = power_level > WASTE_REMOVE_MAX_POWER_LEVEL;

  return (
    <>
      <Section title="Отвод отходов">
        <LabeledList>
          <LabeledList.Item label="Фильтрация">
            <Tooltip
              content={
                wasteLocked
                  ? `Уровень мощности выше ${WASTE_REMOVE_MAX_POWER_LEVEL}: выхлоп слишком горяч, отвод заблокирован.`
                  : 'Выкачивает выбранные газы из модератора в порт отходов.'
              }
            >
              <Box inline>
                <Button
                  disabled={wasteLocked}
                  icon={waste_remove ? 'power-off' : 'times'}
                  content={waste_remove ? 'Вкл' : 'Выкл'}
                  selected={waste_remove}
                  onClick={() => act('waste_remove')}
                />
              </Box>
            </Tooltip>
          </LabeledList.Item>
          <LabeledList.Item label="Скорость">
            <Slider
              value={mod_filtering_rate}
              minValue={limit.min}
              maxValue={limit.max}
              step={1}
              stepPixelSize={3}
              onDrag={(event, value) => act('mod_filtering_rate', { mod_filtering_rate: value })}
            >
              {`${mod_filtering_rate} моль/с`}
            </Slider>
          </LabeledList.Item>
          <LabeledList.Item label="На каждый газ">
            <Box color={enabled.length ? 'good' : 'average'}>
              {enabled.length
                ? `${toFixed(perGasRate, 2)} моль/с на ${enabled.length} ${gasCountWord(
                    enabled.length,
                  )}`
                : 'ни один газ не выбран - фильтрация простаивает'}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section
        title="Газы на фильтрацию"
        buttons={
          <Tooltip content="Скорость фильтрации делится поровну между выбранными газами: чем больше галочек, тем медленнее уходит каждый.">
            <Box inline color="label">
              Выбрано: {enabled.length}
              <Icon name="question-circle" ml={0.5} />
            </Box>
          </Tooltip>
        }
      >
        <Box className="Hypertorus__filterGrid">
          {filter_types.map((filter) => (
            <Button
              key={filter.gas_id}
              className="Hypertorus__filterButton"
              selected={filter.enabled}
              icon={present.has(filter.gas_id) ? 'circle' : undefined}
              tooltip={
                present.has(filter.gas_id)
                  ? 'Сейчас есть в модераторе'
                  : 'Сейчас в модераторе отсутствует'
              }
              content={getGasName(filter.gas_id, filter.gas_name)}
              onClick={() => act('filter', { mode: filter.gas_id })}
            />
          ))}
        </Box>
      </Section>
    </>
  );
};
