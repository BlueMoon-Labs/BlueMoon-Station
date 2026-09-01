/**
 * Тело внутриигрового справочника по атмосу.
 *
 * Один и тот же текст открывают приложение AtmoZphere на КПК, консоль
 * мониторинга атмосферики и газоанализатор. Компонент общий именно поэтому:
 * три копии разметки однажды разошлись бы, и игрок получал бы разный
 * справочник в зависимости от того, откуда его открыл.
 *
 * Весь текст приходит из DM: числа механики живут в дефайнах, и справочник
 * обязан пересчитываться вместе с ними.
 */
import type { BooleanLike } from 'common/react';
import type { ReactNode } from 'react';

import {
  Box,
  Collapsible,
  LabeledList,
  NoticeBox,
  Section,
  Tooltip,
} from '../../components';
import { getGasName } from '../../constants';

export type AtmosHandbookTopic = {
  title: string;
  paragraphs: string[];
};

export type AtmosHandbookCategory = {
  category: string;
  topics: AtmosHandbookTopic[];
};

export type AtmosHandbookFactor = {
  factor_name: string;
  factor_type?: string;
  factor_id?: string;
  desc?: string;
  tooltip?: string;
};

export type AtmosHandbookReaction = {
  id: string;
  name: string;
  description?: string;
  disabled?: BooleanLike;
  factors?: AtmosHandbookFactor[];
};

export type AtmosHandbookGas = {
  id: string;
  name: string;
  description?: string;
  specific_heat?: number;
  tier?: number;
  price?: number;
  reactions?: Record<string, string>;
};

export type AtmosHandbookData = {
  topicInfo?: AtmosHandbookCategory[];
  reactionInfo?: AtmosHandbookReaction[];
  gasInfo?: AtmosHandbookGas[];
};

/** Абзацы топика. Отдельными блоками, а не одной строкой с переносами:
 * переносы в Box схлопываются, и текст слипается в стену. */
const TopicBody = (props: { readonly paragraphs: string[] }) => (
  <>
    {props.paragraphs.map((paragraph, index) => (
      <Box key={index} mb={1}>
        {paragraph}
      </Box>
    ))}
  </>
);

const TopicSection = (props: { readonly section: AtmosHandbookCategory }) => {
  const { section } = props;
  if (!section.topics?.length) {
    return null;
  }
  return (
    <Section title={section.category}>
      {section.topics.map((topic) => (
        <Collapsible key={topic.title} title={topic.title} color="transparent">
          <TopicBody paragraphs={topic.paragraphs || []} />
        </Collapsible>
      ))}
    </Section>
  );
};

/** Подпись фактора. Газы подписываются русскими названиями из общей таблицы:
 * бэкенд шлёт их по-английски, и наружу это идти не должно. У факторов не-газов
 * есть пояснение, что вообще значит эта строка, - оно висит подсказкой, поэтому
 * подпись подчёркнута пунктиром, иначе о подсказке никто не узнает. */
const factorLabel = (factor: AtmosHandbookFactor): ReactNode => {
  const label =
    factor.factor_type === 'gas'
      ? getGasName(factor.factor_id, factor.factor_name)
      : factor.factor_name;
  if (!factor.tooltip) {
    return label;
  }
  return (
    <Tooltip content={factor.tooltip}>
      <Box as="span" style={{ borderBottom: '1px dotted' }}>
        {label}
      </Box>
    </Tooltip>
  );
};

const ReactionCard = (props: { readonly reaction: AtmosHandbookReaction }) => {
  const { reaction } = props;
  return (
    <Collapsible
      title={
        reaction.disabled ? `${reaction.name} (отключена)` : reaction.name
      }
      color="transparent">
      {!!reaction.description && (
        <Box mb={1} color="label">
          {reaction.description}
        </Box>
      )}
      <LabeledList>
        {(reaction.factors || []).map((factor, index) => (
          <LabeledList.Item
            key={`${reaction.id}-${index}`}
            label={factorLabel(factor)}>
            {factor.desc}
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Collapsible>
  );
};

/** Лестница сложности синтеза с серверной стороны (GAS_TIER_* в
 * code/__DEFINES/atmospherics.dm). Показывается вместе с ценой: без этого игрок
 * узнаёт, что за газ стоит браться, только с вики. */
const GAS_TIER_LABELS = [
  'Сырьё',
  'Базовый синтез',
  'Продвинутый синтез',
  'Вершина цепочки',
];

const GasCard = (props: { readonly gas: AtmosHandbookGas }) => {
  const { gas } = props;
  const reactions = Object.values(gas.reactions || {});
  const tierLabel =
    gas.tier === undefined ? undefined : GAS_TIER_LABELS[gas.tier];
  return (
    <Collapsible title={getGasName(gas.id, gas.name)} color="transparent">
      {/* Описание идёт первым и вне LabeledList: это главное,
          зачем игрок сюда пришёл, а ID и теплоёмкость - справка. */}
      {!!gas.description && (
        <Box mb={1} color="label">
          {gas.description}
        </Box>
      )}
      <LabeledList>
        <LabeledList.Item label="ID">{gas.id}</LabeledList.Item>
        <LabeledList.Item label="Теплоёмкость">
          {gas.specific_heat}
        </LabeledList.Item>
        {!!tierLabel && (
          <LabeledList.Item label="Сложность">{tierLabel}</LabeledList.Item>
        )}
        {gas.price !== undefined && (
          <LabeledList.Item label="Цена за моль">
            {gas.price > 0 ? `${gas.price} кр.` : 'не принимается'}
          </LabeledList.Item>
        )}
        {!!reactions.length && (
          <LabeledList.Item label="Реакции">
            {reactions.join(', ')}
          </LabeledList.Item>
        )}
      </LabeledList>
    </Collapsible>
  );
};

export const AtmosHandbookContent = (props: {
  readonly data: AtmosHandbookData;
}) => {
  const { data } = props;
  const topicInfo = data.topicInfo || [];
  const reactionInfo = data.reactionInfo || [];
  const gasInfo = data.gasInfo || [];

  if (!topicInfo.length && !reactionInfo.length && !gasInfo.length) {
    return <NoticeBox>Справочник не загружен.</NoticeBox>;
  }

  return (
    <>
      {topicInfo.map((section) => (
        <TopicSection key={section.category} section={section} />
      ))}
      {!!reactionInfo.length && (
        <Section title="Реакции">
          {reactionInfo.map((reaction) => (
            <ReactionCard key={reaction.id} reaction={reaction} />
          ))}
        </Section>
      )}
      {!!gasInfo.length && (
        <Section title="Газы">
          {gasInfo.map((gas) => (
            <GasCard key={gas.id} gas={gas} />
          ))}
        </Section>
      )}
    </>
  );
};
