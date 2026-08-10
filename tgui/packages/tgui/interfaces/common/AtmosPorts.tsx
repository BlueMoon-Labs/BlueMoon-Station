import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';

import { useBackend } from '../../backend';
import { Box, LabeledList, Section } from '../../components';

const T0C = 273.15;

export type PortReading = {
  name: string;
  pressure: number;
  temperature: number;
  moles?: number;
  connected?: BooleanLike;
};

type PortsData = {
  ports?: PortReading[];
};

export const formatPressure = (value: number): string =>
  `${toFixed(value, 2)} кПа`;

export const formatTemperature = (value: number): string =>
  `${toFixed(value, 2)} К (${toFixed(value - T0C, 1)} °C)`;

/**
 * Что реально стоит на портах устройства. Раньше девайсовые окна показывали
 * одну уставку, и давление приходилось выставлять вслепую.
 */
export const AtmosPorts = (props: { readonly title?: string }) => {
  const { data } = useBackend<PortsData>();
  const ports = data.ports || [];
  if (ports.length === 0) {
    return null;
  }
  return (
    <Section title={props.title || 'Показания'}>
      <LabeledList>
        {ports.map((port, index) => (
          <LabeledList.Item key={index} label={port.name}>
            {port.connected === 0 || port.connected === false ? (
              <Box color="average">Труба не подключена</Box>
            ) : (
              <>
                {formatPressure(port.pressure)}
                <Box as="span" color="label">
                  {' · '}
                  {formatTemperature(port.temperature)}
                </Box>
              </>
            )}
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};
