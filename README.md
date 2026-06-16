# Doc Scanner

A Flutter document scanner app built from a Figma design and wired with GetX routing/state.

The home screen is not static mock data anymore. Scanned and imported files are copied into the app's local documents directory, indexed in JSON, displayed dynamically, and can be opened or deleted from the UI.

## Features

- GetX app routing with `GetMaterialApp`, `GetPage`, and route bindings.
- Dynamic home dashboard for folders and files.
- Camera scanning through `image_picker`.
- File import through `file_picker` for `pdf`, `doc`, `docx`, `jpg`, `jpeg`, `png`, `heic`, and `webp`.
- Local app library stored under the app documents directory.
- Persisted metadata in `doc_scanner_library/library.json`.
- Search, file type filters, folder filtering, and list/grid view modes.
- Open saved local files with `open_filex`.
- Custom-painted file icons for PDF, Word, and image scans.
- Khmer OCR through Google Cloud Vision with Khmer (`km`) and English (`en`) language hints.

## Project Structure

```text
lib/
  app/
    core/
      app_colors.dart
      app_text_styles.dart
    routes/
      app_pages.dart
      app_routes.dart
  features/
    home/
      controllers/
        home_controller.dart
      models/
        document_item.dart
        folder_item.dart
      screens/
        scanner_home_page.dart
  main.dart
```

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Create a local env file:

```sh
cp .env.example .env
```

Then set:

```text
GOOGLE_VISION_API_KEY=your_api_key_here
```

Run the app:

```sh
flutter run
```

You can also pass the key without a file:

```sh
flutter run --dart-define=GOOGLE_VISION_API_KEY=your_api_key_here
```

Analyze the project:

```sh
flutter analyze
```

## Notes

- The file list is created from real files saved by the app, not bundled sample assets.
- `.env` is ignored by git. Commit `.env.example`, not real API keys.
- iOS camera/photo usage descriptions are set in `ios/Runner/Info.plist`.
- Khmer OCR runs on image files through Google Cloud Vision, so it requires internet access and a valid API key.
- PDF and Word files can be stored/opened, but they are not OCR-processed yet.
- `open_filex` currently prints a Flutter warning about iOS Swift Package Manager support. It is a warning, not an analyzer error.
- The app stores files in platform app storage, so deleting the app will remove its local library.
