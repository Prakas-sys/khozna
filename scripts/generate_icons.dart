import 'dart:io';

void main() async {
  final Map<String, int> mipmapSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  final sourceFile = File('assets/images/logo.png');
  if (!await sourceFile.exists()) {
    print('Source file assets/images/logo.png does not exist.');
    return;
  }

  final androidResDir = Directory('android/app/src/main/res');

  if (!await androidResDir.exists()) {
    print('Android res directory not found!');
    return;
  }

  for (final mipmap in mipmapSizes.keys) {
    final targetDir = Directory('${androidResDir.path}/$mipmap');
    if (!await targetDir.exists()) {
       await targetDir.create(recursive: true);
    }
    
    // We're just copying the large image to all folders. 
    // Android is capable of scaling down a large valid PNG if it's placed in the mipmap folders.
    final targetFile = File('${targetDir.path}/ic_launcher.png');
    await sourceFile.copy(targetFile.path);
    print('Copied logo to $mipmap/ic_launcher.png');
    
    // Also create the foreground/background for adaptive icons if they exist
    final targetForeground = File('${targetDir.path}/ic_launcher_foreground.png');
    await sourceFile.copy(targetForeground.path);
  }

  print('Successfully generated Android Launcher Icons manually!');
}
