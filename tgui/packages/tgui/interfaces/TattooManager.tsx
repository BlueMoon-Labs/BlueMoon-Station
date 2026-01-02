import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Icon,
  Input,
  Modal,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

interface InkColor {
  name: string;
  color: string;
}

interface AvailableZone {
  id: string;
  name: string;
}

interface TattooData {
  zone: string;
  zone_name: string;
  tattoos: SingleTattoo[];
}

interface SingleTattoo {
  index: string;
  text: string;
  display_text: string;
  color: string;
  style: string;
  pending_removal: boolean;
}

interface TattooManagerData {
  tattoo_zones: TattooData[];
  has_tattoos: boolean;
  has_pending_removals: boolean;
  pending_removal_count: number;
  ink_colors: InkColor[];
  available_zones: AvailableZone[];
}

interface TattooFormData {
  zone: string;
  text: string;
  color: string;
  style: 'text' | 'description';
}

const getZoneIcon = (zone: string): string => {
  switch (zone) {
    case 'head':
      return 'user';
    case 'chest':
      return 'tshirt';
    case 'groin':
    case 'precise groin':
      return 'venus-mars';
    case 'l_arm':
    case 'r_arm':
      return 'hand-paper';
    case 'l_leg':
    case 'r_leg':
      return 'shoe-prints';
    case 'butt':
      return 'moon';
    case 'pussy':
    case 'testicles':
    case 'penis':
      return 'venus-mars';
    case 'breasts':
      return 'heart';
    case 'horns':
      return 'crown';
    case 'tail':
      return 'feather';
    case 'left_thigh':
    case 'right_thigh':
      return 'socks';
    case 'lips':
      return 'kiss';
    case 'ears':
      return 'assistive-listening-systems';
    case 'wings':
      return 'dove';
    case 'belly':
      return 'circle';
    case 'cheeks':
      return 'smile';
    case 'forehead':
      return 'brain';
    case 'chin':
      return 'user';
    case 'left_hand':
    case 'right_hand':
      return 'hand-paper';
    case 'left_foot':
    case 'right_foot':
      return 'shoe-prints';
    default:
      return 'palette';
  }
};

export const TattooManager = (props, context) => {
  const { act, data } = useBackend<TattooManagerData>(context);
  const {
    tattoo_zones,
    has_tattoos,
    has_pending_removals,
    pending_removal_count,
    ink_colors,
    available_zones,
  } = data;

  const [showAddModal, setShowAddModal] = useLocalState(
    context,
    'showAddModal',
    false,
  );

  const [editingTattoo, setEditingTattoo] = useLocalState<{
    zone: string;
    index: string;
    text: string;
    color: string;
    style: 'text' | 'description';
  } | null>(context, 'editingTattoo', null);

  return (
    <Window title="Управление татуировками" width={550} height={650}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {!!has_pending_removals && (
            <Stack.Item>
              <NoticeBox warning>
                <Icon name="exclamation-triangle" mr={1} />
                {pending_removal_count} татуировок
                {pending_removal_count === 1 ? 'а' : ''} помечено для удаления.
                Удаление произойдёт при следующем респауне персонажа.
              </NoticeBox>
            </Stack.Item>
          )}

          <Stack.Item>
            <Section
              title="Добавить татуировку"
              buttons={
                <Button
                  icon="plus"
                  color="good"
                  onClick={() => setShowAddModal(true)}
                >
                  Добавить
                </Button>
              }
            >
              <Box color="gray" fontSize="0.9em">
                <Icon name="info-circle" mr={1} />
                Добавляйте татуировки напрямую через редактор персонажа. Они
                будут применены при следующем респауне.
              </Box>
            </Section>
          </Stack.Item>

          {!has_tattoos ? (
            <Stack.Item grow>
              <Section fill>
                <Box textAlign="center" color="label" mt={4}>
                  <Icon name="paint-brush" size={4} mb={2} />
                  <Box fontSize="1.2em">У персонажа нет татуировок</Box>
                  <Box mt={1} color="gray">
                    Нажмите &quot;Добавить&quot; чтобы создать татуировку
                  </Box>
                </Box>
              </Section>
            </Stack.Item>
          ) : (
            <Stack.Item grow>
              <Section
                title="Татуировки персонажа"
                buttons={
                  <Button
                    icon="undo"
                    color="caution"
                    disabled={!has_pending_removals}
                    onClick={() => act('clear_pending')}
                  >
                    Отменить удаления
                  </Button>
                }
              >
                <Stack vertical>
                  {tattoo_zones.map((zone) => (
                    <Stack.Item key={zone.zone}>
                      <TattooZoneSection
                        zone={zone}
                        onEditTattoo={(tattoo) =>
                          setEditingTattoo({
                            zone: zone.zone,
                            index: tattoo.index,
                            text: tattoo.display_text,
                            color: tattoo.color,
                            style:
                              tattoo.style === 'description'
                                ? 'description'
                                : 'text',
                          })
                        }
                      />
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          <Stack.Item>
            <Section>
              <Box color="gray" fontSize="0.9em" textAlign="center">
                <Icon name="info-circle" mr={1} />
                Изменения татуировок вступят в силу при следующем появлении
                персонажа на станции.
              </Box>
            </Section>
          </Stack.Item>
        </Stack>

        {showAddModal && (
          <TattooFormModal
            title="Добавить татуировку"
            inkColors={ink_colors}
            availableZones={available_zones}
            onSubmit={(formData) => {
              act('add_tattoo', {
                zone: formData.zone,
                text: formData.text,
                color: formData.color,
                style: formData.style,
              });
              setShowAddModal(false);
            }}
            onClose={() => setShowAddModal(false)}
          />
        )}

        {editingTattoo && (
          <TattooFormModal
            title="Редактировать татуировку"
            inkColors={ink_colors}
            availableZones={available_zones}
            initialData={{
              zone: editingTattoo.zone,
              text: editingTattoo.text,
              color: editingTattoo.color,
              style: editingTattoo.style,
            }}
            isEditing
            onSubmit={(formData) => {
              act('edit_tattoo', {
                zone: editingTattoo.zone,
                index: editingTattoo.index,
                text: formData.text,
                color: formData.color,
                style: formData.style,
              });
              setEditingTattoo(null);
            }}
            onClose={() => setEditingTattoo(null)}
          />
        )}
      </Window.Content>
    </Window>
  );
};

interface TattooFormModalProps {
  title: string;
  inkColors: InkColor[];
  availableZones: AvailableZone[];
  initialData?: Partial<TattooFormData>;
  isEditing?: boolean;
  onSubmit: (data: TattooFormData) => void;
  onClose: () => void;
}

const TattooFormModal = (props: TattooFormModalProps, context) => {
  const {
    title,
    inkColors,
    availableZones,
    initialData,
    isEditing,
    onSubmit,
    onClose,
  } = props;

  const [formZone, setFormZone] = useLocalState(
    context,
    'formZone',
    initialData?.zone || availableZones[0]?.id || '',
  );

  const [formText, setFormText] = useLocalState(
    context,
    'formText',
    initialData?.text || '',
  );

  const [formColor, setFormColor] = useLocalState(
    context,
    'formColor',
    initialData?.color || '#4A4A4A',
  );

  const [formStyle, setFormStyle] = useLocalState<'text' | 'description'>(
    context,
    'formStyle',
    initialData?.style || 'text',
  );

  const selectedZoneName =
    availableZones.find((z) => z.id === formZone)?.name || formZone;
  const selectedColorName =
    inkColors.find((c) => c.color === formColor)?.name || 'Выбрать цвет';

  const isValid = formZone && formText.trim().length > 0 && formColor;

  const handleSubmit = () => {
    if (!isValid) return;
    onSubmit({
      zone: formZone,
      text: formText.trim(),
      color: formColor,
      style: formStyle,
    });
  };

  return (
    <Modal width="400px">
      <Box mb={1} fontSize="1.2em" bold>
        <Icon name="palette" mr={1} />
        {title}
      </Box>

      <Stack vertical>
        {!isEditing && (
          <Stack.Item>
            <Box mb={0.5} bold>
              Зона тела
            </Box>
            <Dropdown
              width="100%"
              selected={selectedZoneName}
              options={availableZones.map((z) => z.name)}
              onSelected={(value: string) => {
                const zone = availableZones.find((z) => z.name === value);
                if (zone) setFormZone(zone.id);
              }}
            />
          </Stack.Item>
        )}

        <Stack.Item>
          <Box mb={0.5} bold>
            Текст татуировки
          </Box>
          <Input
            fluid
            maxLength={150}
            placeholder="Введите текст (макс. 150 символов)"
            value={formText}
            onChange={(e, value) => setFormText(value)}
          />
          <Box mt={0.5} color="gray" fontSize="0.85em">
            {formText.length}/150 символов
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box mb={0.5} bold>
            Цвет чернил
          </Box>
          <Box
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '4px',
            }}
          >
            {inkColors.map((inkColor) => (
              <Box
                key={inkColor.color}
                backgroundColor={inkColor.color}
                width="28px"
                height="28px"
                title={inkColor.name}
                onClick={() => setFormColor(inkColor.color)}
                style={{
                  border:
                    formColor === inkColor.color
                      ? '2px solid white'
                      : '1px solid rgba(255,255,255,0.3)',
                  borderRadius: '3px',
                  cursor: 'pointer',
                  boxSizing: 'border-box',
                }}
              />
            ))}
          </Box>
          <Box mt={0.5} style={{ color: formColor }}>
            Выбрано: {selectedColorName}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box mb={0.5} bold>
            Стиль отображения
          </Box>
          <Tabs fluid>
            <Tabs.Tab
              selected={formStyle === 'text'}
              onClick={() => setFormStyle('text')}
            >
              <Icon name="quote-left" mr={1} />
              Надпись
            </Tabs.Tab>
            <Tabs.Tab
              selected={formStyle === 'description'}
              onClick={() => setFormStyle('description')}
            >
              <Icon name="image" mr={1} />
              Описание
            </Tabs.Tab>
          </Tabs>
          <Box mt={0.5} color="gray" fontSize="0.85em">
            {formStyle === 'text'
              ? 'Текст будет отображаться в кавычках: "ТЕКСТ"'
              : 'Текст будет отображаться как описание узора'}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box mb={0.5} bold>
            Предпросмотр
          </Box>
          <Box
            p={1}
            style={{
              background: 'rgba(255, 255, 255, 0.05)',
              borderRadius: '3px',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              color: formColor,
            }}
          >
            {formText ? (
              formStyle === 'text' ? (
                <span>&quot;{formText}&quot;</span>
              ) : (
                <span>{formText}</span>
              )
            ) : (
              <span style={{ color: 'gray', fontStyle: 'italic' }}>
                Введите текст для предпросмотра
              </span>
            )}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Stack justify="flex-end">
            <Stack.Item>
              <Button icon="times" onClick={onClose}>
                Отмена
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={isEditing ? 'save' : 'plus'}
                color="good"
                disabled={!isValid}
                onClick={handleSubmit}
              >
                {isEditing ? 'Сохранить' : 'Добавить'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Modal>
  );
};

interface TattooZoneSectionProps {
  zone: TattooData;
  onEditTattoo: (tattoo: SingleTattoo) => void;
}

const TattooZoneSection = (props: TattooZoneSectionProps, context) => {
  const { act } = useBackend<TattooManagerData>(context);
  const { zone, onEditTattoo } = props;

  const [confirmingIndex, setConfirmingIndex] = useLocalState<string | null>(
    context,
    `confirming_${zone.zone}`,
    null,
  );

  return (
    <Collapsible
      title={
        <Box inline>
          <Icon name={getZoneIcon(zone.zone)} mr={1} />
          {zone.zone_name}
          <Box inline ml={1} color="label">
            ({zone.tattoos.length})
          </Box>
        </Box>
      }
      open
    >
      <Box ml={2}>
        <Stack vertical>
          {zone.tattoos.map((tattoo) => (
            <Stack.Item key={tattoo.index}>
              <TattooItem
                tattoo={tattoo}
                zone={zone.zone}
                isConfirming={confirmingIndex === tattoo.index}
                onStartConfirm={() => setConfirmingIndex(tattoo.index)}
                onCancelConfirm={() => setConfirmingIndex(null)}
                onEdit={() => onEditTattoo(tattoo)}
              />
            </Stack.Item>
          ))}
        </Stack>
      </Box>
    </Collapsible>
  );
};

interface TattooItemProps {
  tattoo: SingleTattoo;
  zone: string;
  isConfirming: boolean;
  onStartConfirm: () => void;
  onCancelConfirm: () => void;
  onEdit: () => void;
}

const TattooItem = (props: TattooItemProps, context) => {
  const { act } = useBackend<TattooManagerData>(context);
  const { tattoo, zone, isConfirming, onStartConfirm, onCancelConfirm, onEdit } =
    props;

  const handleRemove = () => {
    if (!isConfirming) {
      onStartConfirm();
      return;
    }
    act('toggle_removal', { zone: zone, index: tattoo.index });
    onCancelConfirm();
  };

  const handleCancel = () => {
    onCancelConfirm();
  };

  const handleRestore = () => {
    act('toggle_removal', { zone: zone, index: tattoo.index });
  };

  return (
    <Box
      p={1}
      mb={1}
      style={{
        background: tattoo.pending_removal
          ? 'rgba(219, 40, 40, 0.15)'
          : 'rgba(255, 255, 255, 0.05)',
        borderRadius: '3px',
        border: tattoo.pending_removal
          ? '1px solid rgba(219, 40, 40, 0.3)'
          : '1px solid rgba(255, 255, 255, 0.1)',
        position: 'relative',
      }}
    >
      {!!tattoo.pending_removal && (
        <Box
          style={{
            position: 'absolute',
            top: '2px',
            right: '2px',
          }}
        >
          <Icon name="trash-alt" color="bad" />
        </Box>
      )}
      <Stack vertical>
        <Stack.Item>
          <Box
            style={{
              color: tattoo.color || '#4A4A4A',
              textDecoration: tattoo.pending_removal ? 'line-through' : 'none',
              opacity: tattoo.pending_removal ? 0.6 : 1,
            }}
          >
            {tattoo.style === 'text' ? (
              <span>&quot;{tattoo.display_text}&quot;</span>
            ) : (
              <span>{tattoo.display_text}</span>
            )}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Box color="label" fontSize="0.85em">
                <Icon
                  name={tattoo.style === 'text' ? 'quote-left' : 'image'}
                  mr={1}
                />
                {tattoo.style === 'text' ? 'Надпись' : 'Описание'}
              </Box>
            </Stack.Item>
            <Stack.Item>
              {tattoo.pending_removal ? (
                <Button icon="undo" color="good" onClick={handleRestore}>
                  Восстановить
                </Button>
              ) : isConfirming ? (
                <Stack>
                  <Stack.Item>
                    <Button icon="check" color="bad" onClick={handleRemove}>
                      Подтвердить
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="times" onClick={handleCancel}>
                      Отмена
                    </Button>
                  </Stack.Item>
                </Stack>
              ) : (
                <Stack>
                  <Stack.Item>
                    <Button icon="edit" onClick={onEdit}>
                      Изменить
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="trash-alt"
                      color="caution"
                      onClick={handleRemove}
                    >
                      Удалить
                    </Button>
                  </Stack.Item>
                </Stack>
              )}
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
