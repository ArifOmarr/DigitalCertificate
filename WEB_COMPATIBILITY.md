# Web Compatibility Changes

This document outlines the changes made to ensure the Digital Certificate app works properly on web platforms with the same functionality as Android.

## Key Changes Made

### 1. File Upload Compatibility

**Problem**: The app was using `dart:io` and `File(_file!.path!)` which doesn't work on web platforms.

**Solution**: Updated all upload screens to handle web vs mobile differently:

#### Updated Files:
- `lib/screens/recipient_certificate_upload_screen.dart`
- `lib/screens/ca_create_certificate_screen.dart`
- `lib/screens/certificate_form_screen.dart`

#### Changes:
```dart
// Web: Use putData with Uint8List
if (kIsWeb) {
  if (_file!.bytes != null) {
    await ref.putData(_file!.bytes!);
  } else {
    throw Exception('File bytes not available');
  }
} else {
  // Mobile: Use putFile with File
  if (_file!.path != null) {
    final file = File(_file!.path!);
    await ref.putFile(file);
  } else {
    throw Exception('File path not available');
  }
}
```

### 2. PDF Generation and Upload

**Problem**: PDF generation was using `getTemporaryDirectory()` which doesn't work on web.

**Solution**: For web, directly use `putData()` with PDF bytes:

```dart
if (kIsWeb) {
  // Web: Use putData with Uint8List
  final pdfBytes = await pdf.save();
  await ref.putData(pdfBytes);
} else {
  // Mobile: Use putFile with File
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.pdf');
  await file.writeAsBytes(await pdf.save());
  await ref.putFile(file);
}
```

### 3. PDF Viewing/Downloading

**Problem**: PDF viewing was using local file operations that don't work on web.

**Solution**: Updated PDF viewing to handle web vs mobile:

#### Updated Files:
- `lib/screens/recipient_certificates_screen.dart`
- `lib/screens/shared_certificate_screen.dart`

#### Changes:
```dart
if (kIsWeb) {
  // Web: Open in new tab
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
} else {
  // Mobile: Download and open with local app
  final response = await http.get(Uri.parse(url));
  // ... local file handling
}
```

### 4. Dependencies Added

Added `http: ^1.1.0` to `pubspec.yaml` for web HTTP operations.

### 5. Web Configuration

#### Updated `web/index.html`:
- Added Firebase SDK scripts for web
- Added web-specific configurations for file uploads
- Enhanced PWA support

#### Created `web/manifest.json`:
- Added proper PWA manifest for web app functionality
- Configured app icons and theme colors

## Features Now Working on Web

✅ **File Upload**: Users can upload PDF, JPG, JPEG, PNG files
✅ **PDF Generation**: Auto-generated certificates work on web
✅ **PDF Viewing**: Certificates open in browser tabs
✅ **Certificate Management**: All CRUD operations work
✅ **Authentication**: Login/logout functionality
✅ **Sharing**: Certificate sharing with links
✅ **Dashboard**: All dashboard features work
✅ **Role-based Access**: Different user roles work properly

## Testing Web Functionality

To test the web version:

1. Run `flutter build web`
2. Serve the build: `flutter run -d chrome`
3. Test all upload and download features
4. Verify authentication works
5. Check certificate sharing functionality

## Platform-Specific Behavior

| Feature | Web | Mobile |
|---------|-----|--------|
| File Upload | Uses `putData()` with bytes | Uses `putFile()` with path |
| PDF Generation | Direct bytes upload | Temporary file creation |
| PDF Viewing | Opens in browser tab | Downloads and opens locally |
| File Picker | Browser file dialog | Native file picker |

## Notes

- The `open_file` package warnings are expected on macOS and don't affect web functionality
- All Firebase services work seamlessly across platforms
- The app maintains the same user experience on both web and mobile
- File size limits may vary between platforms due to browser restrictions

## Troubleshooting

If you encounter issues on web:

1. Check browser console for JavaScript errors
2. Verify Firebase configuration is correct
3. Ensure all dependencies are properly installed
4. Test with different browsers (Chrome, Firefox, Safari)
5. Check file size limits for uploads 