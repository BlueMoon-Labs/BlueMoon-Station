import { Fragment } from 'inferno';

import { useBackend, useSharedState } from '../backend';
import { AnimatedNumber, Box, Button, ColorBox, LabeledList, NumberInput, Section, Table } from '../components';
import { Window } from '../layouts';

export const ChemMaster = (props, context) => {
  const { data } = useBackend(context);
  const { screen } = data;
  return (
    <Window
      width={465}
      height={550}
      resizable>
      <Window.Content overflow="auto">
        {screen === 'analyze' && (
          <AnalysisResults />
        ) || (
          <ChemMasterContent />
        )}
      </Window.Content>
    </Window>
  );
};

const ChemMasterContent = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    screen,
    beakerContents = [],
    bufferContents = [],
    beakerCurrentVolume,
    beakerMaxVolume,
    isBeakerLoaded,
    isPillBottleLoaded,
    pillBottleCurrentAmount,
    pillBottleMaxAmount,
  } = data;
  if (screen === 'analyze') {
    return <AnalysisResults />;
  }
  return (
    <Fragment>
      <Section
        title="Ёмкость"
        buttons={!!data.isBeakerLoaded && (
          <Fragment>
            <Box inline color="label" mr={2}>
              <AnimatedNumber
                value={beakerCurrentVolume}
                initial={0} />
              {` / ${beakerMaxVolume} u`}
            </Box>
            <Button
              icon="eject"
              content="Извлечь"
              onClick={() => act('eject')} />
          </Fragment>
        )}>
        {!isBeakerLoaded && (
          <Box color="label" mt="3px" mb="5px">
            Ёмкость отсутствует.
          </Box>
        )}
        {!!isBeakerLoaded && beakerContents.length === 0 && (
          <Box color="label" mt="3px" mb="5px">
            Ёмкость пуста.
          </Box>
        )}
        <ChemicalBuffer>
          {beakerContents.map(chemical => (
            <ChemicalBufferEntry
              key={chemical.id}
              chemical={chemical}
              transferTo="buffer" />
          ))}
        </ChemicalBuffer>
      </Section>
      <Section
        title="Буфер"
        buttons={(
          <Fragment>
            <Box inline color="label" mr={1}>
              Режим:
            </Box>
            <Button
              color={data.mode ? 'good' : 'bad'}
              icon={data.mode ? 'exchange-alt' : 'times'}
              content={data.mode ? 'Переместить' : 'Утилизировать'}
              onClick={() => act('toggleMode')} />
          </Fragment>
        )}>
        {bufferContents.length === 0 && (
          <Box color="label" mt="3px" mb="5px">
            Буфер пуст.
          </Box>
        )}
        <ChemicalBuffer>
          {bufferContents.map(chemical => (
            <ChemicalBufferEntry
              key={chemical.id}
              chemical={chemical}
              transferTo="beaker" />
          ))}
        </ChemicalBuffer>
      </Section>
      <Section
        title="Упаковка">
        <PackagingControls />
      </Section>
      {!!isPillBottleLoaded && (
        <Section
          title="Таблетница"
          buttons={(
            <Fragment>
              <Box inline color="label" mr={2}>
                {pillBottleCurrentAmount} / {pillBottleMaxAmount} pills
              </Box>
              <Button
                icon="eject"
                content="Извлечь"
                onClick={() => act('ejectPillBottle')} />
            </Fragment>
          )} />
      )}
    </Fragment>
  );
};

const ChemicalBuffer = Table;

const ChemicalBufferEntry = (props, context) => {
  const { act } = useBackend(context);
  const { chemical, transferTo } = props;
  return (
    <Table.Row key={chemical.id}>
      <Table.Cell color="label">
        <AnimatedNumber
          value={chemical.volume}
          initial={0} />
        {`u ${chemical.name}`}
      </Table.Cell>
      <Table.Cell collapsing>
        <Button
          content="1"
          onClick={() => act('transfer', {
            id: chemical.id,
            amount: 1,
            to: transferTo,
          })} />
        <Button
          content="5"
          onClick={() => act('transfer', {
            id: chemical.id,
            amount: 5,
            to: transferTo,
          })} />
        <Button
          content="10"
          onClick={() => act('transfer', {
            id: chemical.id,
            amount: 10,
            to: transferTo,
          })} />
        <Button
          content="All"
          onClick={() => act('transfer', {
            id: chemical.id,
            amount: 1000,
            to: transferTo,
          })} />
        <Button
          icon="ellipsis-h"
          title="Произвольное кол-во"
          onClick={() => act('transfer', {
            id: chemical.id,
            amount: -1,
            to: transferTo,
          })} />
        <Button
          icon="question"
          title="Анализ"
          onClick={() => act('analyze', {
            id: chemical.id,
          })} />
      </Table.Cell>
    </Table.Row>
  );
};

const PackagingControlsItem = (props, context) => {
  const { data } = useBackend(context);
  const {
    label,
    amountUnit,
    amount,
    onChangeAmount,
    onCreate,
    sideNote,
  } = props;
  return (
    <LabeledList.Item label={label}>
      <NumberInput
        width="84px"
        unit={amountUnit}
        step={1}
        stepPixelSize={15}
        value={amount}
        minValue={1}
        maxValue={20 * (data.max_create_amount_multiplier || 1)}
        onChange={onChangeAmount} />
      <Button
        ml={1}
        content="Создать"
        onClick={onCreate} />
      <Box inline ml={1} color="label">
        {sideNote}
      </Box>
    </LabeledList.Item>
  );
};

const PackagingControls = (props, context) => {
  const { act, data } = useBackend(context);
  const [
    pillAmount,
    setPillAmount,
  ] = useSharedState(context, 'pillAmount', 1);
  const [
    patchAmount,
    setPatchAmount,
  ] = useSharedState(context, 'patchAmount', 1);
  const [
    bottleAmount,
    setBottleAmount,
  ] = useSharedState(context, 'bottleAmount', 1);
  const [
    packAmount,
    setPackAmount,
  ] = useSharedState(context, 'packAmount', 1);
  const [
    vialAmount,
    setvialAmount,
  ] = useSharedState(context, 'setvialAmount', 1);
  const [
    dartAmount,
    setdartAmount,
  ] = useSharedState(context, 'setdartAmount', 1);
  const {
    condi,
    chosenPillStyle,
    pillStyles = [],
    chosenPatchStyle,
    patchStyles = [],
  } = data;
  return (
    <LabeledList>
      {!condi && (<LabeledList.Item label="Тип таблетки">
        {pillStyles.map(pill => (
          <Button
            key={pill.id}
            width="30px"
            selected={pill.id === chosenPillStyle}
            textAlign="center"
            color="transparent"
            onClick={() => act('pillStyle', { id: pill.id })}>
            <Box mx={-1} className={pill.className} />
          </Button>
        ))}
                  </LabeledList.Item>
      )}
      {!condi && (<LabeledList.Item label="Тип пластыря">
        {patchStyles.map(patch => (
          <Button
            key={patch.id}
            width="30px"
            selected={patch.id === chosenPatchStyle}
            textAlign="center"
            color="transparent"
            onClick={() => act('patchStyle', { id: patch.id })}>
            <Box mx={-1} className={patch.className} />
          </Button>
        ))}
                  </LabeledList.Item>
      )}
      {!condi && (
        <PackagingControlsItem
          label="Таблетки"
          amount={pillAmount}
          amountUnit="pills"
          sideNote="max 50u"
          onChangeAmount={(e, value) => setPillAmount(value)}
          onCreate={() => act('create', {
            type: 'pill',
            amount: pillAmount,
            volume: 'auto',
          })} />
      )}
      {!condi && (
        <PackagingControlsItem
          label="Пластыри"
          amount={patchAmount}
          amountUnit="patches"
          sideNote="max 40u"
          onChangeAmount={(e, value) => setPatchAmount(value)}
          onCreate={() => act('create', {
            type: 'patch',
            amount: patchAmount,
            volume: 'auto',
          })} />
      )}
      {!condi && (
        <PackagingControlsItem
          label="Бутылочки"
          amount={bottleAmount}
          amountUnit="bottles"
          sideNote="max 30u"
          onChangeAmount={(e, value) => setBottleAmount(value)}
          onCreate={() => act('create', {
            type: 'bottle',
            amount: bottleAmount,
            volume: 'auto',
          })} />
      )}
      {!condi && (
        <PackagingControlsItem
          label="Гипоампулы"
          amount={vialAmount}
          amountUnit="vials"
          sideNote="max 60u"
          onChangeAmount={(e, value) => setvialAmount(value)}
          onCreate={() => act('create', {
            type: 'hypoVial',
            amount: vialAmount,
            volume: 'auto',
          })} />
      )}
      {!condi && (
        <PackagingControlsItem
          label="Смартдарты"
          amount={dartAmount}
          amountUnit="darts"
          sideNote="max 20u"
          onChangeAmount={(e, value) => setdartAmount(value)}
          onCreate={() => act('create', {
            type: 'smartDart',
            amount: dartAmount,
            volume: 'auto',
          })} />
      )}
      {!!condi && (
        <PackagingControlsItem
          label="Пакетики"
          amount={packAmount}
          amountUnit="packs"
          sideNote="max 10u"
          onChangeAmount={(e, value) => setPackAmount(value)}
          onCreate={() => act('create', {
            type: 'condimentPack',
            amount: packAmount,
            volume: 'auto',
          })} />
      )}
      {!!condi && (
        <PackagingControlsItem
          label="Бутылки"
          amount={bottleAmount}
          amountUnit="bottles"
          sideNote="max 50u"
          onChangeAmount={(e, value) => setBottleAmount(value)}
          onCreate={() => act('create', {
            type: 'condimentBottle',
            amount: bottleAmount,
            volume: 'auto',
          })} />
      )}
    </LabeledList>
  );
};

const AnalysisResults = (props, context) => {
  const { act, data } = useBackend(context);
  const { fermianalyze } = props;
  const { analyzeVars } = data;
  return (
    <Section
      title="Результаты анализа"
      buttons={(
        <Button
          icon="arrow-left"
          content="Назад"
          onClick={() => act('goScreen', {
            screen: 'home',
          })} />
      )}>

      <LabeledList>
        <LabeledList.Item label="Название">
          {analyzeVars.name}
        </LabeledList.Item>
        <LabeledList.Item label="Агрегатное сост.">
          {analyzeVars.state}
        </LabeledList.Item>
        <LabeledList.Item label="Цвет">
          <ColorBox color={analyzeVars.color} mr={1} />
          {analyzeVars.color}
        </LabeledList.Item>
        <LabeledList.Item label="Описание">
          {analyzeVars.description}
        </LabeledList.Item>
        <LabeledList.Item label="Метабол. усваиваем.">
          {analyzeVars.metaRate} u/minute
        </LabeledList.Item>
        <LabeledList.Item label="Порог дозировки">
          {analyzeVars.overD}
        </LabeledList.Item>
        <LabeledList.Item label="Порог зависимости">
          {analyzeVars.addicD}
        </LabeledList.Item>
        <LabeledList.Item label="Метаболизируется">
          {analyzeVars.processType}
        </LabeledList.Item>
        <LabeledList.Item label="Чистота">
          {analyzeVars.purityF}
        </LabeledList.Item>
        {!! data.fermianalyze && ( // why did you do that before? it's bad.
          <Fragment>
            <LabeledList.Item label="Inverse Ratio">
              {analyzeVars.inverseRatioF}
            </LabeledList.Item>
            <LabeledList.Item label="Purity E">
              {analyzeVars.purityE}
            </LabeledList.Item>
            <LabeledList.Item label="Нижний оптимум температуры">
              {analyzeVars.minTemp}
            </LabeledList.Item>
            <LabeledList.Item label="Высший оптимум температуры">
              {analyzeVars.maxTemp}
            </LabeledList.Item>
            <LabeledList.Item label="Температура детонации">
              {analyzeVars.eTemp}
            </LabeledList.Item>
            <LabeledList.Item label="Края значений pH">
              {analyzeVars.pHpeak}
            </LabeledList.Item>
          </Fragment>
        )}
      </LabeledList>
    </Section>
  );
};
