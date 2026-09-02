# Публікація на Google Play — чек-лист

Тексти лістингу: [`listing-uk.md`](listing-uk.md), [`listing-en.md`](listing-en.md).
Політика приватності: [`privacy-policy.md`](privacy-policy.md) →
публікується як `docs/privacy-policy/index.html`.

## 1. Підпис (одноразово)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Скопіювати `android/key.properties.example` → `android/key.properties`, заповнити паролями.
- **Зберегти резервну копію `upload-keystore.jks` і паролів поза репозиторієм.**
  Втрата = неможливо оновлювати застосунок (якщо не ввімкнено Play App Signing з
  можливістю скидання ключа завантаження).
- `.gitignore` уже виключає `key.properties` та `*.jks`.

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
- **Feature graphic 1024×500** — ❗ треба створити (немає).
- **Скріншоти телефона** — мін. 2, до 8, 16:9 або 9:16, від 320 px.
  Зараз є лише `design/screenshots/home-screen.png`. ❗ Треба:
  головний екран, редагування нагадування, налаштування (мова), приклад
  сповіщення на банері. Українською та (бажано) англійською.

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
