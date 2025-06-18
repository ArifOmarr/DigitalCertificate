# True Copy Certificate Upload App

A Flutter application for uploading and processing true copy certificates using OCR (Optical Character Recognition) technology. The app automatically extracts metadata from certificate images and provides a clean, user-friendly interface for certificate management.

## 🚀 Features

- **📱 Modern UI**: Clean, responsive design optimized for mobile devices
- **📄 File Upload**: Support for JPEG and PNG certificate images
- **🔍 OCR Processing**: Automatic text extraction using Google ML Kit
- **📋 Metadata Extraction**: Automatically extracts:
  - Recipient Name
  - Certificate Type
  - Date Issued
  - Issuer Name
- **✏️ Editable Forms**: Review and edit extracted information
- **🎯 User-Friendly**: Simple, intuitive interface with clear feedback

## 📱 Screenshots

*Add screenshots of your app here*

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.2+
- **Language**: Dart
- **OCR**: Google ML Kit Text Recognition
- **File Picking**: file_picker package
- **UI Components**: flutter_spinkit for loading animations

## 📋 Prerequisites

Before running this project, make sure you have:

- **Flutter SDK**: 3.7.2 or higher
- **Dart SDK**: Latest stable version
- **Android Studio** or **VS Code** with Flutter extensions
- **Android Emulator** or **Physical Device** for testing

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/true-copy-upload.git
cd true-copy-upload
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

The app will launch on your connected device or emulator.

## 📁 Project Structure

```
true_copy_upload/
├── lib/
│   ├── main.dart                 # App entry point
│   └── screens/
│       └── certificate_upload_screen.dart  # Main upload screen
├── android/                      # Android-specific files
├── ios/                         # iOS-specific files
├── pubspec.yaml                 # Dependencies and project config
└── README.md                    # This file
```

## 🔧 Configuration

### Dependencies

The app uses the following key dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  file_picker: ^8.0.0+1          # File selection
  google_mlkit_text_recognition: ^0.12.0  # OCR processing
  flutter_spinkit: ^5.2.1        # Loading animations
```

## 📖 How to Use

1. **Launch the App**: Open the app on your device
2. **Upload Certificate**: Tap "Choose File" to select a certificate image
3. **Preview Image**: Review the selected certificate
4. **OCR Processing**: The app automatically extracts text from the image
5. **Review Data**: Check and edit the extracted information
6. **Submit**: Tap "Process Certificate" to complete

## 🔍 OCR Features

The app uses pattern matching to extract specific information:

- **Recipient Name**: Looks for patterns like "Name:", "Recipient:", "To:"
- **Certificate Type**: Identifies certificate types from text patterns
- **Date Issued**: Recognizes various date formats (DD/MM/YYYY, MM/DD/YYYY)
- **Issuer Name**: Extracts organization names from signature areas

## 🎨 UI/UX Design

- **Clean Interface**: Minimalist design with clear visual hierarchy
- **Responsive Layout**: Works on various screen sizes
- **Loading States**: Clear feedback during processing
- **Error Handling**: User-friendly error messages
- **Success Feedback**: Confirmation dialogs with extracted data

## 🔮 Future Enhancements

- [ ] Firebase integration for cloud storage
- [ ] Database storage for certificate history
- [ ] Multiple certificate types support
- [ ] Export functionality
- [ ] User authentication
- [ ] Certificate validation
- [ ] Batch processing
- [ ] Offline support

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test thoroughly
5. Commit your changes: `git commit -m 'Add some feature'`
6. Push to the branch: `git push origin feature/your-feature-name`
7. Submit a Pull Request

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Test your changes before submitting

### Areas for Contribution

- **Backend Integration**: Firebase setup and configuration
- **Database Design**: Firestore schema and queries
- **Additional Features**: New certificate types, export options
- **UI Improvements**: Better animations, themes, accessibility
- **Testing**: Unit tests, widget tests, integration tests
- **Documentation**: Code comments, API documentation

## 🐛 Known Issues

- OCR accuracy depends on image quality
- Some certificate formats may not be recognized
- Large images may take longer to process

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Your Name** - Initial development and UI design
- **Your Friends** - Backend integration and additional features

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/true-copy-upload/issues) page
2. Create a new issue with detailed information
3. Contact the development team

## 🔄 Version History

- **v1.0.0** - Initial release with OCR functionality
- **v1.1.0** - UI improvements and bug fixes
- **v1.2.0** - Added form validation and error handling

---

**Note**: This is a development version. For production use, additional security measures and Firebase integration should be implemented.
