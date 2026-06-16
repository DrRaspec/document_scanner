# Doc Scanner

A Flutter document scanner app built from a Figma design and wired with GetX routing/state.

The home screen is not static mock data anymore. Scanned and imported files are copied into the app's local documents directory, indexed in JSON, displayed dynamically, and can be opened or deleted from the UI.

## Features

- GetX app routing with `GetMaterialApp`, `GetPage`, and route bindings.
- Dynamic home dashboard for folders and files.
- Camera scanning through `image_picker`.
- File import through `file_selector` for `pdf`, `doc`, `docx`, `jpg`, `jpeg`, `png`, `heic`, and `webp`.
- Local app library stored under the app documents directory.
- Persisted metadata in `doc_scanner_library/library.json`.
- Search, file type filters, folder filtering, and list/grid view modes.
- Open saved local files with `open_filex`.
- Custom-painted file icons for PDF, Word, and image scans.
- Free offline OCR on Android using bundled Tesseract trained data, optimized for Khmer with English fallback.

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
      dialogs/
        home_dialogs.dart
      models/
        document_item.dart
        folder_item.dart
      screens/
        scanner_home_page.dart
      services/
        document_library_service.dart
        ocr_service.dart
      widgets/
        circle_icon.dart
        document_cards.dart
        document_collection.dart
        document_file_icon.dart
        empty_document_state.dart
        filter_controls.dart
        folder_strip.dart
        home_top_bar.dart
        quick_actions_panel.dart
  main.dart
```

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Analyze the project:

```sh
flutter analyze
```

## Notes

- The file list is created from real files saved by the app, not bundled sample assets.
- iOS camera/photo usage descriptions are set in `ios/Runner/Info.plist`.
- OCR runs on image files offline on Android. It uses `khm+eng`, so Khmer is the priority while English text is also supported.
- iOS scanning/import/opening still works, but free offline OCR is disabled on iOS because the available Tesseract iOS Flutter plugin breaks Apple Silicon simulator builds.
- PDF and Word files can be stored/opened, but they are not OCR-processed yet.
- `open_filex` currently prints a Flutter warning about iOS Swift Package Manager support. It is a warning, not an analyzer error.
- The app stores files in platform app storage, so deleting the app will remove its local library.
