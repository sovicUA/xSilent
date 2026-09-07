# Публікація на Google Play — чек-лист

Тексти лістингу: [`listing-uk.md`](listing-uk.md), [`listing-en.md`](listing-en.md).
Політика приватності: [`privacy-policy.md`](privacy-policy.md) →
публікується як `docs/privacy-policy/index.html`.

## 1. Підпис (одноразово)

Upload-keystore вже згенеровано локально (PKCS12, alias `upload`, RSA-2048,
термін дії 10000 днів): `android/app/upload-keystore.jks` +
`android/key.properties`. Обидва — поза git (`.gitignore`).

Якщо треба відтворити:
```bash
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- **❗ Негайно зберегти резервну копію `upload-keystore.jks` і паролів поза
  цією машиною** (менеджер паролів + офлайн-носій). Втрата = неможливо
  оновлювати застосунок (якщо не ввімкнено Play App Signing з можливістю
  скидання ключа завантаження).
- SHA-256 сертифіката upload-ключа:
  `2B:ED:0E:7A:82:E7:58:3F:88:FD:8E:A7:4E:AA:B4:C9:0B:41:5B:75:BC:72:96:F1:C7:C8:EB:F8:E0:BA:C9:9B`

Для CI: `base64 -w0 android/app/upload-keystore.jks` → секрет `KEYSTORE_BASE64`;
паролі/alias — окремі секрети (див. `.github/workflows/`).

## 2. Збірка

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Перевірити підпис:
```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

## 3. GitHub Pages (політика приватності)

Settings → Pages → Source: **Deploy from a branch** → `main` / `/docs`.
URL: `https://sovicua.github.io/xSilent/privacy-policy/`

## 4. Play Console

### Створити застосунок
- Назва: «Хвилина мовчання» (uk) / «Moment of Silence» (en-US).
- Мова за замовчуванням: українська. Додати переклад en-US.

### Store listing
- Тексти — з `listing-uk.md` / `listing-en.md`.
- **Іконка 512×512** — `design/play_store_icon_512.png`.
- **Feature graphic 1024×500** — `design/feature-graphic.png`
  (джерело: `design/feature-graphic.html`, рендер через headless-браузер).
- **Скріншоти телефона** (укр., 1600×2680, з підключеного пристрою):
  - `design/screenshots/01-home.png` — список нагадувань
  - `design/screenshots/02-editor-builtin.png` — вбудована «Хвилина мовчання»
  - `design/screenshots/03-editor-custom.png` — власне нагадування (гучність, дні)
  - `design/screenshots/04-language.png` — вибір мови
  Англійський лістинг може використати ті самі (UI впізнаваний) або зроби
  окремі, перемкнувши мову в налаштуваннях.

### App content
- **Політика приватності:** URL з п.3.
- **Data safety:** нічого не збирається, нічого не передається (деталі в listing-*.md).
- **Ads:** немає.
- **Target audience:** дорослі / 18+ або 13+ (не для дітей).
- **Content rating:** заповнити анкету (застосунок-утиліта, без контенту 18+).
- **Government apps / фінанси / здоровʼя:** ні.
- **Use of exact alarms:** так — обґрунтування в listing-*.md.
- **Permissions declaration:** `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM` — пояснити
  (відновлення розкладу після перезавантаження; точний час нагадування).

### Release
- Почати з **Internal testing**, потім Closed → Production.
- Play App Signing — увімкнути (Google зберігає app-ключ, ти завантажуєш
  upload-ключем).
- versionCode/Name — з `pubspec.yaml` (`version: 1.0.0+1`). Кожен реліз — новий
  `+N`.

## 5. Автопублікація з CI (після ручного першого релізу)

Service account у Google Cloud → доступ у Play Console (Users & permissions →
Release manager для конкретного застосунку) → JSON-ключ → секрет
`PLAY_SERVICE_ACCOUNT_JSON`. Тег `v*` у git запускає
`.github/workflows/release.yml` → збірка підписаного AAB → завантаження на трек
`internal`. Перший AAB Google приймає лише через ручне завантаження в Console.
