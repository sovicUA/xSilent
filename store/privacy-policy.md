# Політика приватності / Privacy Policy

Джерело для сторінки, що публікується через GitHub Pages
(`docs/privacy-policy/index.html`). Оновлювати обидва місця разом.

Чинна від / Effective: 2026-09-02
Контакт / Contact: v.sytnyk@sovic.org.ua

---

## Українською

**Застосунок:** «Хвилина мовчання» (`ua.org.sovic.xsilent`)

### Коротко

Застосунок працює повністю на пристрої й офлайн. Ми **не збираємо**, не
зберігаємо на серверах і не передаємо нікому жодних персональних даних.
Немає реклами, аналітики та сторонніх трекерів. Застосунок не звертається до
мережі.

### Які дані обробляються

- **Ваші нагадування** (час, дні тижня, назва, текст, налаштування озвучення)
  зберігаються в локальній базі даних на вашому пристрої. Вони не залишають
  пристрій.
- **Аудіофайли озвучення.** Текст нагадування синтезується в звуковий файл і
  зберігається у спільній теці пристрою `Notifications/xSilent` — інакше
  система не змогла б відтворити його як звук сповіщення. Файлами керує лише
  застосунок; вони видаляються при зміні тексту чи гучності та при видаленні
  нагадування. Через те, що тека спільна, інші застосунки з дозволом на
  доступ до медіа-аудіо технічно можуть прочитати ці файли, тому не вводьте
  конфіденційний текст у поле озвучення.
- **Налаштування** (мова інтерфейсу) зберігаються локально.

### Дозволи

- **Сповіщення** — щоб показувати нагадування.
- **Точні будильники** (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) — щоб
  нагадування спрацьовувало точно о заданому часі.
- **Запуск після перезавантаження** (`RECEIVE_BOOT_COMPLETED`) — щоб відновити
  заплановані нагадування після ввімкнення пристрою.
- **Вібрація.**
- **Синтез мовлення** — застосунок використовує рушій TTS, встановлений на
  пристрої; текст для синтезу не надсилається розробнику застосунку.

### Діти

Застосунок не орієнтований на дітей і не збирає жодних даних від будь-кого.

### Зміни

Про зміни цієї політики буде повідомлено оновленням цієї сторінки та дати
«Чинна від».

### Контакт

Питання щодо приватності: **v.sytnyk@sovic.org.ua**

---

## English

**App:** "Moment of Silence" (`ua.org.sovic.xsilent`)

### In short

The app runs entirely on your device and offline. We **do not collect**, store
on any server, or share with anyone any personal data. There are no ads, no
analytics, and no third-party trackers. The app makes no network requests.

### What data is processed

- **Your reminders** (time, weekdays, title, text, announcement settings) are
  stored in a local database on your device. They never leave the device.
- **Announcement audio files.** A reminder's text is synthesised into a sound
  file stored in the device's shared `Notifications/xSilent` folder — otherwise
  the system could not play it as a notification sound. Only the app manages
  these files; they are deleted when the text or volume changes and when a
  reminder is deleted. Because the folder is shared, other apps holding media
  audio permission can technically read these files, so do not enter
  confidential text in the announcement field.
- **Settings** (interface language) are stored locally.

### Permissions

- **Notifications** — to show reminders.
- **Exact alarms** (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) — so a reminder
  fires at exactly the scheduled time.
- **Run at startup** (`RECEIVE_BOOT_COMPLETED`) — to restore scheduled
  reminders after the device boots.
- **Vibration.**
- **Text-to-speech** — the app uses the TTS engine installed on the device;
  the text to synthesise is not sent to the app's developer.

### Children

The app is not directed at children and collects no data from anyone.

### Changes

Any changes to this policy will be announced by updating this page and the
"Effective" date.

### Contact

Privacy questions: **v.sytnyk@sovic.org.ua**
