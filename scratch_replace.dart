import 'dart:io';

void main() {
  final dir = Directory('C:/Users/jrdri/Documents/projects/Proyecto_JIC_tutorias_app/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int count = 0;
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      var newContent = content.replaceAllMapped(RegExp(r'\.withOpacity\((.*?)\)'), (match) {
        return '.withValues(alpha: ${match.group(1)})';
      });
      file.writeAsStringSync(newContent);
      print('Updated ${file.path}');
      count++;
    }
  }
  print('Total files updated: $count');
}
