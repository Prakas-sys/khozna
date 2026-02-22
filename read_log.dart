import 'dart:io';

void main() {
  try {
    final lines = File('build_out2.txt').readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Exception') || lines[i].contains('FAILURE:') || lines[i].contains('What went wrong')) {
        int start = (i - 10) < 0 ? 0 : i - 10;
        int end = (i + 40) >= lines.length ? lines.length : i + 40;
        for (int j = start; j < end; j++) {
          print(lines[j]);
        }
        return;
      }
    }
    print("No exception found.");
  } catch(e) {
    print(e);
  }
}
