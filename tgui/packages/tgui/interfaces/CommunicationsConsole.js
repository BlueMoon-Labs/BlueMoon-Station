import { sortBy } from "common/collections";
import { capitalize } from "common/string";

import { useBackend, useLocalState } from "../backend";
import { Blink, Box, Button, Dimmer, Flex, Icon, Input, LabeledList, Modal, Section, TextArea } from "../components";
import { formatMoney } from '../format';
import { Window } from "../layouts";
import { sanitizeText } from "../sanitize";

const STATE_BUYING_SHUTTLE = "buying_shuttle";
const STATE_CALLING_ERT = "calling_ert";
const STATE_CHANGING_STATUS = "changing_status";
const STATE_MAIN = "main";
const STATE_MESSAGES = "messages";

// Used for whether or not you need to swipe to confirm an alert level change
const SWIPE_NEEDED = "SWIPE_NEEDED";

const sortByCreditCost = sortBy(shuttle => shuttle.creditCost);
const sortByCreditCostERT = sortBy(ert => ert.creditCost);

const AlertButton = (props, context) => {
  const { act, data } = useBackend(context);
  const { alertLevelTick, canSetAlertLevel } = data;
  const { alertLevel, setShowAlertLevelConfirm } = props;

  const thisIsCurrent = data.alertLevel === alertLevel;

  return (
    <Button
      icon="exclamation-triangle"
      color={thisIsCurrent && "good"}
      content={capitalize(alertLevel)}
      onClick={() => {
        if (thisIsCurrent) {
          return;
        }

        if (canSetAlertLevel === SWIPE_NEEDED) {
          setShowAlertLevelConfirm([alertLevel, alertLevelTick]);
        } else {
          act("changeSecurityLevel", {
            newSecurityLevel: alertLevel,
          });
        }
      }}
    />
  );
};

const MessageModal = (props, context) => {
  const { data } = useBackend(context);
  const { maxMessageLength } = data;

  const [input, setInput] = useLocalState(context, props.label, "");

  const longEnough = props.minLength === undefined
    || input.length >= props.minLength;

  return (
    <Modal>
      <Flex direction="column">
        <Flex.Item fontSize="16px" maxWidth="90vw" mb={1}>
          {props.label}:
        </Flex.Item>

        <Flex.Item mr={2} mb={1}>
          <TextArea
            fluid
            height="20vh"
            width="80vw"
            backgroundColor="black"
            textColor="white"
            onInput={(_, value) => {
              setInput(value.substring(0, maxMessageLength));
            }}
            value={input}
          />
        </Flex.Item>

        <Flex.Item>
          <Button
            icon={props.icon}
            content={props.buttonText}
            color="good"
            disabled={!longEnough}
            tooltip={!longEnough ? "Вам требуется более обоснованная причина." : ""}
            tooltipPosition="right"
            onClick={() => {
              if (longEnough) {
                setInput("");
                props.onSubmit(input);
              }
            }}
          />

          <Button
            icon="times"
            content="Cancel"
            color="bad"
            onClick={props.onBack}
          />
        </Flex.Item>

        {!!props.notice && (
          <Flex.Item maxWidth="90vw">{props.notice}</Flex.Item>
        )}
      </Flex>
    </Modal>
  );
};

const NoConnectionModal = () => {
  return (
    <Dimmer>
      <Flex direction="column" textAlign="center" width="300px">
        <Flex.Item>
          <Icon
            color="red"
            name="wifi"
            size={10}
          />

          <Blink>
            <div
              style={{
                background: "#db2828",
                bottom: "60%",
                left: "25%",
                height: "10px",
                position: "relative",
                transform: "rotate(45deg)",
                width: "150px",
              }}
            />
          </Blink>
        </Flex.Item>

        <Flex.Item fontSize="16px">
          A connection to the station cannot be established.
        </Flex.Item>
      </Flex>
    </Dimmer>
  );
};

const PageBuyingShuttle = (props, context) => {
  const { act, data } = useBackend(context);

  return (
    <Box>
      <Section>
        <Button
          icon="chevron-left"
          content="Назад"
          onClick={() => act("setState", { state: STATE_MAIN })}
        />
      </Section>

      <Section>
        Бюджет: <b>{data.budget.toLocaleString()}</b> кредитов
      </Section>

      {sortByCreditCost(data.shuttles).map(shuttle => (
        <Section
          title={(
            <span
              style={{
                display: "inline-block",
                width: "70%",
              }}>
              {shuttle.name}
            </span>
          )}
          key={shuttle.ref}
          buttons={(
            <Button
              content={`${shuttle.creditCost.toLocaleString()} кредитов`}
              disabled={data.budget < shuttle.creditCost}
              onClick={() => act("purchaseShuttle", {
                shuttle: shuttle.ref,
              })}
              tooltip={
                data.budget < shuttle.creditCost
                  ? `Требуется ещё ${shuttle.creditCost - data.budget} кредитов`
                  : undefined
              }
              tooltipPosition="left"
            />
          )}>
          <Box>{shuttle.description}</Box>
          {
            shuttle.prerequisites
              ? <b>Prerequisites: {shuttle.prerequisites}</b>
              : null
          }
        </Section>
      ))}
    </Box>
  );
};

const PageCallingERT = (props, context) => {
  const { act, data } = useBackend(context);

  return (
    <Box>
      <Section>
        <Button
          icon="chevron-left"
          content="Назад"
          onClick={() => act("setState", { state: STATE_MAIN })}
        />
      </Section>

      <Section>
        Бюджет: <b>{data.budget.toLocaleString()}</b> кредитов
      </Section>
      {sortByCreditCostERT(data.ert).map(ert => (
        <Section
          title={(
            <span
              style={{
                display: "inline-block",
                width: "70%",
              }}>
              {ert.name}
            </span>
          )}
          key={ert.ref}
          buttons={(
            <Button
              content={`${ert.creditCost.toLocaleString()} кредитов`}
              disabled={data.budget < ert.creditCost || !ert.available}
              onClick={() => act("purchaseERT", {
                ert: ert.ref,
              })}
              tooltip={
                data.budget < ert.creditCost
                  ? `Требуется ещё ${ert.creditCost - data.budget} кредитов`
                  : undefined
              }
              tooltipPosition="left"
            />
          )}>
          <Box>{ert.description}</Box>
        </Section>
      ))}
    </Box>
  );
};


const PageChangingStatus = (props, context) => {
  const { act, data } = useBackend(context);
  const { maxStatusLineLength } = data;

  const [lineOne, setLineOne] = useLocalState(context, "lineOne", data.lineOne);
  const [lineTwo, setLineTwo] = useLocalState(context, "lineTwo", data.lineTwo);

  return (
    <Box>
      <Section>
        <Button
          icon="chevron-left"
          content="Назад"
          onClick={() => act("setState", { state: STATE_MAIN })}
        />
      </Section>

      <Section>
        <Flex direction="column">
          <Flex.Item>
            <Button
              icon="times"
              content="Очистить"
              color="bad"
              onClick={() => act("setStatusPicture", { picture: "blank" })}
            />
          </Flex.Item>

          <Flex.Item mt={1}>
            <Button
              icon="check-square-o"
              content="Стандартный"
              onClick={() => act("setStatusPicture", { picture: "default" })}
            />

            <Button
              icon="bell-o"
              content="Тревога"
              onClick={() => act("setStatusPicture", { picture: "redalert" })}
            />

            <Button
              icon="exclamation-triangle"
              content="Локдаун"
              onClick={() => act("setStatusPicture", { picture: "lockdown" })}
            />

            <Button
              icon="exclamation-circle"
              content="Биоугроза"
              onClick={() => act("setStatusPicture", { picture: "biohazard" })}
            />

            <Button
              icon="space-shuttle"
              content="Shuttle ETA"
              onClick={() => act("setStatusPicture", { picture: "shuttle" })}
            />
          </Flex.Item>
        </Flex>
      </Section>

      <Section title="Сообщение">
        <Flex direction="column">
          <Flex.Item mb={1}>
            <Input
              maxLength={maxStatusLineLength}
              value={lineOne}
              width="200px"
              onChange={(_, value) => setLineOne(value)}
            />
          </Flex.Item>

          <Flex.Item mb={1}>
            <Input
              maxLength={maxStatusLineLength}
              value={lineTwo}
              width="200px"
              onChange={(_, value) => setLineTwo(value)}
            />
          </Flex.Item>

          <Flex.Item>
            <Button
              icon="comment-o"
              content="Установить"
              onClick={() => act("setStatusMessage", {
                lineOne,
                lineTwo,
              })}
            />
          </Flex.Item>
        </Flex>
      </Section>
    </Box>
  );
};

const PageMain = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    alertLevel,
    alertLevelTick,
    aprilFools,
    callShuttleReasonMinLength,
    canBuyShuttles,
    canCallERT,
    canMakeAnnouncement,
    canMessageAssociates,
    canRecallShuttles,
    canRequestNuke,
    canSendToSectors,
    canSetAlertLevel,
    canToggleEmergencyAccess,
    emagged,
    emergencyAccess,
    importantActionReady,
    sectors,
    shuttleCalled,
    shuttleCalledPreviously,
    shuttleCanEvacOrFailReason,
    shuttleLastCalled,
    shuttleRecallable,
    cargocredits,
    slaves,
  } = data;

  const [callingShuttle, setCallingShuttle] = useLocalState(
    context, "calling_shuttle", false);
  const [messagingAssociates, setMessagingAssociates] = useLocalState(
    context, "messaging_associates", false);
  const [messagingSector, setMessagingSector] = useLocalState(
    context, "messaing_sector", null);
  const [requestingNukeCodes, setRequestingNukeCodes] = useLocalState(
    context, "requesting_nuke_codes", false);

  const [
    [showAlertLevelConfirm, confirmingAlertLevelTick],
    setShowAlertLevelConfirm,
  ] = useLocalState(context, "showConfirmPrompt", [null, null]);

  return (
    <Box>
      <Section title="Шаттл Эвакуации">
        {shuttleCalled && (
          <Button.Confirm
            icon="space-shuttle"
            content="Отозвать Шаттл Эвакуации"
            color="bad"
            disabled={!canRecallShuttles || !shuttleRecallable}
            tooltip={(
              canRecallShuttles && (
                !shuttleRecallable && "Слишком поздно, чтобы отозвать шаттл эвакуции."
              ) || (
                "У вас нет возможности отозвать шаттл эвакуации."
              )
            )}
            tooltipPosition="bottom-end"
            onClick={() => act("recallShuttle")}
          />
        ) || (
            <Button
              icon="space-shuttle"
              content="Вызвать Шаттл Эвакуации"
              disabled={shuttleCanEvacOrFailReason !== 1}
              tooltip={
                shuttleCanEvacOrFailReason !== 1
                  ? shuttleCanEvacOrFailReason
                  : undefined
              }
              tooltipPosition="bottom-end"
              onClick={() => setCallingShuttle(true)}
            />
          )}
        {!!shuttleCalledPreviously && (
          shuttleLastCalled && (
            <Box>
              Most recent shuttle call/recall traced to:
              {" "}<b>{shuttleLastCalled}</b>
            </Box>
          ) || (
            <Box>Unable to trace most recent shuttle/recall signal.</Box>
          )
        )}
      </Section>

      {!!canSetAlertLevel && (
        <Section title="Уровень тревоги">
          <Flex justify="space-between">
            <Flex.Item>
              <Box>
                Текущий код: <b>{capitalize(alertLevel)}</b>
              </Box>
            </Flex.Item>

            <Flex.Item>
              <AlertButton
                alertLevel="green"
                showAlertLevelConfirm={showAlertLevelConfirm}
                setShowAlertLevelConfirm={setShowAlertLevelConfirm}
              />

              <AlertButton
                alertLevel="blue"
                showAlertLevelConfirm={showAlertLevelConfirm}
                setShowAlertLevelConfirm={setShowAlertLevelConfirm}
              />

              <AlertButton
                alertLevel="orange"
                showAlertLevelConfirm={showAlertLevelConfirm}
                setShowAlertLevelConfirm={setShowAlertLevelConfirm}
              />

              <AlertButton
                alertLevel="violet"
                showAlertLevelConfirm={showAlertLevelConfirm}
                setShowAlertLevelConfirm={setShowAlertLevelConfirm}
              />

              <AlertButton
                alertLevel="amber"
                showAlertLevelConfirm={showAlertLevelConfirm}
                setShowAlertLevelConfirm={setShowAlertLevelConfirm}
              />
            </Flex.Item>
          </Flex>
        </Section>
      )}

      <Section title="Функции">
        <Flex
          direction="column">
          {!!canMakeAnnouncement && <Button
            icon="bullhorn"
            content="Сделать объявление"
            onClick={() => act("makePriorityAnnouncement")}
          />}

          {!!aprilFools && !!canMakeAnnouncement && <Button
            icon="bullhorn"
            content="Созвать срочное совещание"
            onClick={() => act("emergency_meeting")}
          />}

          {!!canToggleEmergencyAccess && <Button.Confirm
            icon="id-card-o"
            content={`${emergencyAccess ? "Отключить" : "Включить"} аварийный доступ в тоннели`}
            color={emergencyAccess ? "bad" : undefined}
            onClick={() => act("toggleEmergencyAccess")}
          />}

          <Button
            icon="desktop"
            content="Установить текст на дисплеях"
            onClick={() => act("setState", { state: STATE_CHANGING_STATUS })}
          />

          <Button
            icon="envelope-o"
            content="Посмотреть список сообщений"
            onClick={() => act("setState", { state: STATE_MESSAGES })}
          />

          {(canBuyShuttles !== 0) && <Button
            icon="shopping-cart"
            content="Приобрести шаттл"
            disabled={canBuyShuttles !== 1}
            // canBuyShuttles is a string detailing the fail reason
            // if one can be given
            tooltip={canBuyShuttles !== 1 ? canBuyShuttles : undefined}
            tooltipPosition="right"
            onClick={() => act("setState", { state: STATE_BUYING_SHUTTLE })}
          />}

          {(canCallERT !== 0) && <Button
            icon="shopping-cart"
            content="Вызвать платное ОБР"
            disabled={canCallERT !== 1}
            tooltip={canCallERT !== 1 ? canCallERT : undefined}
            tooltipPosition="right"
            onClick={() => act("setState", { state: STATE_CALLING_ERT })}
          />}

          {!!canMessageAssociates && <Button
            icon="comment-o"
            content={`Отправить сообщение ${emagged ? "[НЕИЗВЕСТНЫМ]" : "ЦК"}`}
            disabled={!importantActionReady}
            onClick={() => setMessagingAssociates(true)}
          />}

          {!!canRequestNuke && <Button
            icon="radiation"
            content="Запросить коды Ядерной Аутентификации"
            disabled={!importantActionReady}
            onClick={() => setRequestingNukeCodes(true)}
          />}

          {!!emagged && <Button
            icon="bullhorn"
            content="Заявить о существовании Syndicate"
            onClick={() => act("declareTheExistenceOfSyndicate")}
          />}

          {!!emagged && <Button
            icon="undo"
            content="Восстановить данные маршрутизации"
            onClick={() => act("restoreBackupRoutingData")}
          />}
        </Flex>
      </Section>

      {!!slaves.length && (
        <Section title="Выкупить рабов">
          <LabeledList>
            <LabeledList.Item
              label="кредиты Карго">
              {formatMoney(cargocredits, null, true)}cr
            </LabeledList.Item>
            <LabeledList.Item
              label="Информация">
              {"Кредиты окончательно списываются после возвращения похищенных на станцию."}
            </LabeledList.Item>
          </LabeledList>

          <Flex
            direction="column"
            pt="1rem">
            {slaves.map(slave => (
              <Flex
                key={slave.name + slave.coords + slave.index}
                className="candystripe"
                align="center"
                p=".5rem">

                <Flex.Item
                  bold
                  grow
                  color="label">
                  {slave.name}
                </Flex.Item>

                <Flex.Item color="average">
                  {!slave.can_bought && !slave.bought
                    ? `${'Suspended: ' + slave.bought_timer}`
                    : slave.toggleransomfeedback}
                </Flex.Item>

                <Flex.Item
                  collapsing
                  align="right"
                  pl=".5rem"
                >
                  <Button
                    icon={slave.bought ? "times" : ""}
                    disabled={!slave.cantoggleransom || !slave.can_bought}
                    content={slave.bought
                      ? "Cancel"
                      : formatMoney(slave.price, null, true) + "cr"}
                    color={slave.bought ? "bad" : "default"}
                    onClick={() => act('toggleBought', {
                      id: slave.id,
                    })} />
                </Flex.Item>

              </Flex>
            ))}
          </Flex>
        </Section>
      )}

      {!!canMessageAssociates && messagingAssociates && <MessageModal
        label={`Сообщение для передачи на ${emagged ? "[НЕУСТАНОВЛЕННЫЕ ЧАСТОТЫ]" : "ЦК"} с помощью квантовой запутанности`}
        notice="Имейте ввиду, что данный процесс достаточно дорог. Не злоупотребляйте им. Ответное сообщение может не поступить."
        icon="bullhorn"
        buttonText="Отправить"
        onBack={() => setMessagingAssociates(false)}
        onSubmit={message => {
          setMessagingAssociates(false);
          act("messageAssociates", {
            message,
          });
        }}
      />}

      {!!canRequestNuke && requestingNukeCodes && <MessageModal
        label="Причина запроса кодов ядерной аутентификации"
        notice="Злоупотребление системой запроса кодов недопустимо ни при каких обстоятельствах. Ответное сообщение может не поступить."
        icon="bomb"
        buttonText="Запросить коды"
        onBack={() => setRequestingNukeCodes(false)}
        onSubmit={reason => {
          setRequestingNukeCodes(false);
          act("requestNukeCodes", {
            reason,
          });
        }}
      />}

      {!!callingShuttle && <MessageModal
        label="Причина"
        icon="space-shuttle"
        buttonText="Вызвать Шаттл"
        minLength={callShuttleReasonMinLength}
        onBack={() => setCallingShuttle(false)}
        onSubmit={reason => {
          setCallingShuttle(false);
          act("callShuttle", {
            reason,
          });
        }}
      />}

      {
        !!canSetAlertLevel
        && showAlertLevelConfirm
        && confirmingAlertLevelTick === alertLevelTick
        && (
          <Modal>
            <Flex
              direction="column"
              textAlign="center"
              width="300px">
              <Flex.Item fontSize="16px" mb={2}>
                Swipe ID to confirm change
              </Flex.Item>

              <Flex.Item mr={2} mb={1}>
                <Button
                  icon="id-card-o"
                  content="Проведите ID картой"
                  color="good"
                  fontSize="16px"
                  onClick={() => act("changeSecurityLevel", {
                    newSecurityLevel: showAlertLevelConfirm,
                  })}
                />

                <Button
                  icon="times"
                  content="Отменить"
                  color="bad"
                  fontSize="16px"
                  onClick={() => setShowAlertLevelConfirm(false)}
                />
              </Flex.Item>
            </Flex>
          </Modal>
        )
      }

      {
        !!canSendToSectors
        && sectors.length > 0
        && (
          <Section title="Соседние сектора">
            <Flex
              direction="column">
              {
                sectors.map(sectorName => (
                  <Flex.Item key={sectorName}>
                    <Button
                      content={
                        `Отправить сообщение в соседний сектор ${sectorName}.`
                      }
                      disabled={!importantActionReady}
                      onClick={() => setMessagingSector(sectorName)}
                    />
                  </Flex.Item>
                ))
              }

              {sectors.length > 2 && (
                <Flex.Item>
                  <Button
                    content="Отправить сообщение всем дружественным станциям"
                    disabled={!importantActionReady}
                    onClick={() => setMessagingSector("all")}
                  />
                </Flex.Item>
              )}
            </Flex>
          </Section>
        )
      }

      {
        !!canSendToSectors
        && sectors.length > 0
        && messagingSector
        && <MessageModal
          label="Сообщение для отправки союзным станциям"
          notice="Имейте ввиду, что данный процесс достаточно дорог. Не злоупотребляйте им."
          icon="bullhorn"
          buttonText="Send"
          onBack={() => setMessagingSector(null)}
          onSubmit={message => {
            act("sendToOtherSector", {
              destination: messagingSector,
              message,
            });

            setMessagingSector(null);
          }}
        />
      }
    </Box>
  );
};

const PageMessages = (props, context) => {
  const { act, data } = useBackend(context);
  const messages = data.messages || [];
  const { printerCooldown } = data;

  const children = [];

  children.push((
    <Section>
      <Button
        icon="chevron-left"
        content="Назад"
        onClick={() => act("setState", { state: STATE_MAIN })}
      />
    </Section>
  ));

  const messageElements = [];

  for (const [messageIndex, message] of Object.entries(messages)) {
    let answers = null;

    if (message.possibleAnswers.length > 0) {
      answers = (
        <Box mt={1}>
          {message.possibleAnswers.map((answer, answerIndex) => (
            <Button
              content={answer}
              color={message.answered === answerIndex + 1 ? "good" : undefined}
              key={answerIndex}
              onClick={
                message.answered
                  ? undefined
                  : () =>
                    act("answerMessage", {
                      message: parseInt(messageIndex, 10) + 1,
                      answer: answerIndex + 1,
                    })
              }
            />
          ))}
        </Box>
      );
    }

    const textHtml = {
      __html: sanitizeText(message.content),
    };

    messageElements.push((
      <Section
        title={message.title}
        key={messageIndex}
        buttons={(
          <>
            <Button
              icon="print"
              content="Распечатать"
              disabled={printerCooldown}
              onClick={() => act("printMessage", {
                message: parseInt(messageIndex, 10) + 1,
              })}
            />
            <Button.Confirm
              icon="trash"
              content="Удалить"
              color="red"
              onClick={() => act("deleteMessage", {
                message: parseInt(messageIndex, 10) + 1,
              })}
            />
          </>
        )}>
        <Box
          dangerouslySetInnerHTML={textHtml} />

        {answers}
      </Section>
    ));
  }

  children.push(messageElements.reverse());

  return children;
};

export const CommunicationsConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    authenticated,
    authorizeName,
    canLogOut,
    emagged,
    hasConnection,
    page,
    canRequestSafeCode,
    safeCodeDeliveryWait,
    safeCodeDeliveryArea,
  } = data;

  return (
    <Window
      width={450}
      height={650}
      theme={emagged ? "syndicate" : undefined}>
      <Window.Content overflow="auto">
        {!hasConnection && <NoConnectionModal />}

        {(canLogOut || !authenticated) && (
          <Section title="Аутентификация">
            <Button
              icon={authenticated ? "sign-out-alt" : "sign-in-alt"}
              content={authenticated ? `Отключиться${authorizeName ? ` (${authorizeName})` : ""}` : "Подключиться"}
              color={authenticated ? "bad" : "good"}
              onClick={() => act("toggleAuthentication")}
            />
          </Section>
        )}

        {/* {(!!canRequestSafeCode && (
          <Section title="Emergency Safe Code">
            <Button
              icon="key"
              content="Request Safe Code"
              color="good"
              onClick={() => act("requestSafeCodes")} />
          </Section>
        )) || (!!safeCodeDeliveryWait && (
          <Section title="Emergency Safe Code Delivery">
            {`Drop pod to ${safeCodeDeliveryArea} in \
            ${Math.round(safeCodeDeliveryWait/10)}s`}
          </Section>
        ))} */}

        {!!authenticated && (
          page === STATE_BUYING_SHUTTLE && <PageBuyingShuttle />
          || page === STATE_CALLING_ERT && <PageCallingERT />
          || page === STATE_CHANGING_STATUS && <PageChangingStatus />
          || page === STATE_MAIN && <PageMain />
          || page === STATE_MESSAGES && <PageMessages />
          || <Box>Page not implemented: {page}</Box>
        )}
      </Window.Content>
    </Window>
  );
};
