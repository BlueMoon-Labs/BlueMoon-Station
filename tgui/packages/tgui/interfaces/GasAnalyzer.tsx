/**
 * Окно ручного газоанализатора. Показывает СНИМОК последнего скана, а не живые
 * данные: анализатор уносят от того, что просканировали.
 *
 * @file
 * @license MIT
 */
import { useBackend } from '../backend';
import { Button, NoticeBox, Section } from '../components';
import { Window } from '../layouts';
import type { Gasmix } from './common/GasmixParser';
import { GasmixParser } from './common/GasmixParser';

export type GasAnalyzerData = {
  gasmixes: Gasmix[];
  /**
   * REF смеси -> нестабильность недавней реакции синтеза. Лежит рядом со смесью,
   * а не внутри неё: структура смеси общая для всех окон.
   */
  fusion_instability?: Record<string, number>;
};

export const GasAnalyzerContent = () => {
  const { data } = useBackend<GasAnalyzerData>();
  const gasmixes = data.gasmixes || [];
  const fusionInstability = data.fusion_instability;

  if (gasmixes.length === 0) {
    return <NoticeBox>Сканирование ещё не проводилось.</NoticeBox>;
  }

  return (
    <>
      {gasmixes.map((gasmix) => {
        const instability = fusionInstability?.[gasmix.reference];
        return (
          <Section title={gasmix.name} key={gasmix.reference}>
            <GasmixParser gasmix={gasmix} />
            {typeof instability === 'number' && (
              <NoticeBox mt={1}>
                {`Зафиксировано много свободных нейтронов: поблизости прошла реакция синтеза. Нестабильность: ${instability}.`}
              </NoticeBox>
            )}
          </Section>
        );
      })}
    </>
  );
};

export const GasAnalyzer = () => {
  const { act } = useBackend<GasAnalyzerData>();
  return (
    <Window width={500} height={450}>
      <Window.Content scrollable>
        {/* Анализатор - тот прибор, который в руках ровно в тот момент, когда
            игрок смотрит на незнакомый газ и не понимает, чем он опасен. */}
        <Section
          title="Газоанализатор"
          buttons={
            <Button
              icon="book"
              content="Справочник"
              tooltip="Газы, реакции, инструменты и правила по давлению в трубах"
              onClick={() => act('handbook')}
            />
          }
        />
        <GasAnalyzerContent />
      </Window.Content>
    </Window>
  );
};
