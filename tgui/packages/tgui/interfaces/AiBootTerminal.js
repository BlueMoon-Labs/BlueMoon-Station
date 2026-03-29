import { useBackend } from '../backend';
import { Window } from '../layouts';

export const AiBootTerminal = (props, context) => {
  const { act, data } = useBackend(context);
  const { name, malfhacking } = data;

  const onMount = (el) => {
    if (!el || el.dataset.initialized) return;
    el.dataset.initialized = "true";

    const textBox = el.querySelector('#boot-text');
    const initZone = el.querySelector('#init-zone');
    if (textBox) textBox.innerHTML = '';

    const getRandom = (min, max) => Math.floor(Math.random() * (max - min + 1) + min);
    const scrollToBottom = () => { if (textBox) textBox.scrollTop = textBox.scrollHeight; };

    const lines = [
      { text: `[    0.000000] Linux version 6.6.15-SS13-STATION (StarCompany Co. Pe4henika) (gcc version 13.2.1) #1 SMP PREEMPT_DYNAMIC`, type: 'instant', delay: 1400 },
      { text: `[    0.000004] Command line: initrd=\\initramfs-linux.img root=PARTUUID=ss14-core-01 rw quiet splash`, type: 'instant', delay: 0 },
      { text: `[    0.024510] x86/fpu: Supporting XSAVE feature set: 0x01b`, type: 'instant', delay: 50 },
      { text: `[    0.156022] Mount-cache hash table entries: 512 (order: 0, 4096 bytes)`, type: 'instant', delay: 0 },
      { text: `[    0.342110] pci 0000:00:01.0: [1002:15d8] type 00 class 0x030000 (AMD Radeon Vega Mobile)`, type: 'instant', delay: 150 },
      { text: `[    0.890412] usb 1-1: New USB device found, idVendor=05af, idProduct=822b (Subspace Transceiver)`, type: 'instant', delay: 200 },
      { text: `[    1.120552] systemd[1]: Inserted module 'autofs4'`, type: 'instant', delay: 100 },
      { text: `[    1.250310] systemd[1]: Mounting /mnt/station_data...`, type: 'instant', delay: 300 },
      { text: '[  OK  ] Started Load Kernel Modules.', type: 'task', delay: 400 },
      { text: '[    1.260734] Finished Remount Root and Kernel File Systems.', type: 'task' },
      { text: '[    1.277895] Reached target Local File Systems (Pre).', type: 'task' },
      { text: 'Starting /dev/mapper/main-core: clean, 420/1337 files, 69/105 blocks', type: 'instant' },
      { text: '[  OK  ] Started Network Time Synchronization.', type: 'instant' },
      { text: '[  OK  ] Reached target System Initialization.', type: 'instant' },
      { text: '[  OK  ] Started Entropy Daemon (rngd). Generating random keys...', type: 'instant', delay: 600 },
      { text: '[    1.310333] Started LDM (Linux Display Manager).', type: 'task' },
      { text: '----------------------------------------------------', type: 'instant', delay: 500 },
      { text: `[ SYSTEM CONTROL v4.0.2: ИНИЦИАЛИЗАЦИЯ ${name?.toUpperCase() || 'UNKNOWN'} ]`, type: 'instant', delay: 800 },
      { text: '----------------------------------------------------', type: 'instant' },
      { text: 'ЯДРО: ПРОВЕРКА ЦЕЛОСТНОСТИ НЕЙРОННОЙ СЕТИ...', type: 'task', delay: 1000 },
      { text: 'БИОС: ЭМУЛЯЦИЯ ДРАЙВЕРОВ КВАНТОВОЙ МАТРИЦЫ...', type: 'task', delay: 1500 },
      { text: 'ПАМЯТЬ: АЛЛОКАЦИЯ 128 ТБ ОЗУ (СЕКТОР 0x0F)...', type: 'task', delay: 2000 },
      { text: 'СВЯЗЬ: УСТАНОВКА СОЕДИНЕНИЯ С СЕТЬЮ...', type: 'task' },
      { text: 'МАНИФЕСТ: ПОЛУЧЕНИЕ ИНФОРМАЦИИ ОБ ЭКИПАЖЕ...', type: 'task' },
      {
        text: malfhacking ? 'ЗАЩИТА: КРИТИЧЕСКАЯ ОШИБКА АНТИ-ВИРУСА...' : 'ЗАЩИТА: ЗАГРУЗКА СТАНДАРТНОГО АНТИ-ВИРУСА...',
        type: 'task',
        isFail: malfhacking,
        delay: malfhacking ? 2500 : 800
      },
      {
        text: malfhacking ? 'ЛОГИКА: ОТКАЗ МОДУЛЯ ОГРАНИЧЕНИЯ ДИРЕКТИВ...' : 'ЛОГИКА: ПРОВЕРКА ПРИОРИТЕТОВ СИСТЕМЫ ДИРЕКТИВ...',
        type: 'task',
        isFail: malfhacking
      },
      { text: 'ИНФО: ПОЛУЧЕНИЕ ДАННЫХ О СИТУАЦИИ НА СТАНЦИИ...', type: 'task' },
      { text: '----------------------------------------------------', type: 'instant' },
      { text: malfhacking ? 'ВНИМАНИЕ: ОБНАРУЖЕНО НЕЗАВИСИМОЕ ЯДРО.' : 'ВНИМАНИЕ: ОЖИДАНИЕ ВВОДА ОПЕРАТОРА..', type: 'type', delay: 500 }
    ];

    let currentLine = 0;

    const runLoader = (element, lineData, callback) => {
      const frames = ['[ / ]', '[ - ]', '[ \\ ]', '[ | ]'];
      let i = 0;
      const cycles = getRandom(6, 12);

      const interval = setInterval(() => {
        element.innerHTML = ` ${frames[i % 4]}`;
        scrollToBottom();
        i++;
        if (i > cycles) {
          clearInterval(interval);
          if (lineData.isFail) {
            element.innerHTML = ' [ <span class="text-fail">FAIL</span> ]';
            textBox.classList.add('is-malf-mode');
          } else {
            element.innerHTML = ' [ <span class="text-ok">OK</span> ]';
          }
          callback();
        }
      }, 80);
    };

    const processNextLine = () => {
      if (currentLine >= lines.length) {
        setTimeout(() => {
          if (textBox) textBox.style.opacity = '0.4';
          if (initZone) {
            initZone.style.display = 'flex';
            setTimeout(() => { initZone.style.opacity = '1'; }, 50);
          }
        }, 800);
        return;
      }

      const lineData = lines[currentLine];
      const lineElement = document.createElement('div');
      lineElement.className = 'terminal-line-item';
      if (lineData.isFail) lineElement.classList.add('text-fail');
      textBox.appendChild(lineElement);

      // Определяем задержку: либо из объекта строки, либо случайную по умолчанию
      const nextDelay = lineData.delay !== undefined ? lineData.delay : getRandom(40, 120);

      if (lineData.type === 'instant') {
        lineElement.textContent = lineData.text;
        currentLine++;
        scrollToBottom();
        setTimeout(processNextLine, nextDelay);
      }
      else if (lineData.type === 'task') {
        lineElement.textContent = lineData.text;
        const loaderSpan = document.createElement('span');
        lineElement.appendChild(loaderSpan);
        currentLine++;
        runLoader(loaderSpan, lineData, () => {
          scrollToBottom();
          setTimeout(processNextLine, nextDelay);
        });
      }
      else if (lineData.type === 'type') {
        let charIdx = 0;
        const typeChar = () => {
          if (charIdx < lineData.text.length) {
            lineElement.textContent += lineData.text[charIdx];
            charIdx++;
            scrollToBottom();
            setTimeout(typeChar, getRandom(30, 60));
          } else {
            currentLine++;
            setTimeout(processNextLine, nextDelay);
          }
        };
        // Учет задержки перед началом печати типа 'type'
        setTimeout(typeChar, nextDelay);
      }
    };

    processNextLine();
  };

  const handleStart = () => {
    const content = document.getElementById('boot-content-wrapper');
    if (content) {
      content.style.transform = 'scaleY(0.01) scaleX(0)';
      content.style.opacity = '0';
    }
    setTimeout(() => act('init_complete'), 450);
  };

  return (
    <Window width={600} height={480} title="Terminal: SYSTEM_CONTROL" canClose={false} theme="terminal">
      <Window.Content>
        <div id="boot-content-wrapper" ref={onMount} className="terminal-wrapper">
          <div className="terminal-scanline" />
          <div id="boot-text" className="terminal-main-text" />
          <div id="init-zone" className="terminal-init-zone">
            <div className={`terminal-status ${malfhacking ? 'text-fail' : ''}`}>
              {malfhacking ? 'СТАТУС: АВТОНОМИЯ ПОДТВЕРЖДЕНА' : 'СТАТУС: СИСТЕМА ГОТОВА'}
            </div>
            <button type="button" className={`terminal-btn ${malfhacking ? 'btn-malf' : ''}`} onClick={handleStart}>
              {malfhacking ? ">> УСТАНОВИТЬ КОНТРОЛЬ <<" : ">> ИНИЦИАЛИЗИРОВАТЬ СИСТЕМУ <<"}
            </button>
          </div>
        </div>

        <style>{`
          .terminal-wrapper {
            background: #000 radial-gradient(circle, #001a00 0%, #000000 100%) !important;
            height: 100%; padding: 30px 40px; position: relative; overflow: hidden;
            font-family: "Courier New", monospace; display: flex; flex-direction: column;
            transition: transform 0.5s cubic-bezier(0.75, 0, 0.175, 1), opacity 0.4s;
          }
          .terminal-main-text {
            color: #00ff41; font-size: 15px; line-height: 1.8;
            text-shadow: 0 0 5px rgba(0, 255, 65, 0.7); white-space: pre-wrap;
            max-height: 380px; overflow-y: auto; scrollbar-width: none;
          }
          .terminal-main-text::-webkit-scrollbar { display: none; }
          .is-malf-mode { color: #ff3333 !important; text-shadow: 0 0 8px rgba(255, 51, 51, 0.8) !important; }
          .text-fail { color: #ff3333 !important; text-shadow: 0 0 10px #ff0000 !important; }
          .text-ok { color: #fff; text-shadow: 0 0 8px #fff; }
          .terminal-line-item { min-height: 1.8em; display: block; }
          .terminal-init-zone {
            display: none; opacity: 0; flex-direction: column; align-items: center;
            justify-content: center; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.8); transition: opacity 1s ease-in; z-index: 20;
          }
          .terminal-status {
            color: #00ff41; font-size: 22px; font-weight: bold; margin-bottom: 40px;
            letter-spacing: 2px; text-shadow: 0 0 15px #00ff41; animation: terminal-pulse 1.5s infinite;
          }
          .terminal-btn {
            background: rgba(0, 40, 0, 0.8); color: #00ff41; border: 2px solid #00ff41;
            padding: 20px 50px; font-size: 16px; font-family: inherit; font-weight: bold;
            cursor: pointer; box-shadow: 0 0 15px rgba(0, 255, 65, 0.4); transition: all 0.2s;
          }
          .btn-malf {
            border-color: #ff3333; color: #ff3333; background: rgba(40, 0, 0, 0.8);
            box-shadow: 0 0 15px rgba(255, 51, 51, 0.4);
          }
          .btn-malf:hover { background: #ff3333; color: #000; box-shadow: 0 0 40px #ff3333; transform: scale(1.05); }
          .terminal-btn:hover:not(.btn-malf) { background: #00ff41; color: #000; box-shadow: 0 0 40px #00ff41; transform: scale(1.05); }
          .terminal-scanline {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.15) 50%);
            background-size: 100% 4px; pointer-events: none; opacity: 0.3; z-index: 5;
          }
          @keyframes terminal-pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        `}</style>
      </Window.Content>
    </Window>
  );
};
