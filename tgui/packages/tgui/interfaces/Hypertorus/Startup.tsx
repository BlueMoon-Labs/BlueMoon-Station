import { Fragment } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Icon, Section, Stack, Tooltip } from '../../components';
import { getStartupSteps } from './helpers';
import { HypertorusData } from './types';

/**
 * Пусковая цепочка: четыре тумблера в том порядке, в котором их разрешено
 * трогать. Стрелки между шагами показывают зависимость, тултип - причину
 * блокировки.
 */
export const Startup = () => {
  const { act, data } = useBackend<HypertorusData>();
  const steps = getStartupSteps(data);

  return (
    <Section title="Пусковая цепочка">
      <Stack align="center">
        {steps.map((step, index) => (
          <Fragment key={step.id}>
            {index > 0 && (
              <Stack.Item>
                <Icon
                  className={`Hypertorus__chainArrow${
                    steps[index - 1].active ? ' Hypertorus__chainArrow--live' : ''
                  }`}
                  name="angle-right"
                />
              </Stack.Item>
            )}
            <Stack.Item grow basis={0}>
              <Tooltip content={step.hint}>
                {/* Гасим только шаги, до которых очередь ещё не дошла. Работающий
                    шаг, который нельзя выключить, остаётся ярким: его состояние
                    важнее того, что кнопка сейчас заперта. */}
                <Box
                  className={`Hypertorus__step${
                    step.active ? ' Hypertorus__step--active' : ''
                  }${step.disabled && !step.active ? ' Hypertorus__step--locked' : ''}`}
                >
                  <Box className="Hypertorus__stepLabel">
                    <Icon name={step.icon} mr={1} />
                    {step.label}
                    {step.disabled && step.active && (
                      <Icon name="lock" ml={0.5} color="label" />
                    )}
                  </Box>
                  <Button
                    fluid
                    textAlign="center"
                    disabled={step.disabled}
                    icon={step.active ? 'power-off' : 'times'}
                    content={step.active ? 'Вкл' : 'Выкл'}
                    selected={step.active}
                    onClick={() => act(step.id)}
                  />
                </Box>
              </Tooltip>
            </Stack.Item>
          </Fragment>
        ))}
      </Stack>
    </Section>
  );
};
