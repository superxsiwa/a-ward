import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opening and saving a case file through the system's own dialogs (Android's document picker
/// and "save to", a download on the web). No storage permission: the player picks the place.
abstract interface class CaseFiles {
  /// The chosen file's text; null when the player cancelled.
  Future<String?> pick();

  /// Saves [text] as [name]; false when the player cancelled.
  Future<bool> save(String name, String text);
}

class SystemCaseFiles implements CaseFiles {
  @override
  Future<String?> pick() async {
    // Any file: phones often label a .json download as a plain binary file; the reader decides.
    final file = await FilePicker.pickFile();
    return file?.xFile.readAsString();
  }

  @override
  Future<bool> save(String name, String text) async =>
      await FilePicker.saveFile(
        fileName: name,
        bytes: utf8.encode(text),
        mimeType: 'application/json',
      ) !=
      null;
}

final caseFilesProvider = Provider<CaseFiles>((ref) => SystemCaseFiles());
