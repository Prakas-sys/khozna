import 'dart:io';

void main() async {
  print('Running flutter devices...');
  var result = await Process.run(
    'D:\\STORE\\flutter sdk\\flutter\\bin\\flutter.bat',
    ['devices'],
  );
  print('STDOUT: ${result.stdout}');
  print('STDERR: ${result.stderr}');
  print('Exit code: ${result.exitCode}');
}
