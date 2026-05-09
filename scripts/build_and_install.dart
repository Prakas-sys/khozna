import 'dart:io';

void main() async {
  print('Starting build...');
  var result = await Process.run('flutter.bat', ['build', 'apk', '--debug']);
  print('Build output: ${result.stdout}');
  print('Build error: ${result.stderr}');

  if (result.exitCode == 0) {
    print('Build successful. Installing...');
    var installResult = await Process.run(
      'C:\\Users\\praka\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
      ['install', '-r', 'build\\app\\outputs\\flutter-apk\\app-debug.apk'],
    );
    print('Install output: ${installResult.stdout}');
    print('Install error: ${installResult.stderr}');

    if (installResult.exitCode == 0) {
      print('Launch successful. Starting app...');
      var launchResult = await Process.run(
        'C:\\Users\\praka\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
        [
          'shell',
          'am',
          'start',
          '-n',
          'com.khozna.khozna/com.khozna.khozna.MainActivity',
        ],
      );
      print('Launch output: ${launchResult.stdout}');
    }
  } else {
    print('Build failed with exit code ${result.exitCode}');
  }
}
