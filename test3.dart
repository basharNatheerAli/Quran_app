import 'dart:convert'; import 'dart:io'; void main() { var data = jsonDecode(File('assets/json/azkar.json').readAsStringSync()); print(data.keys.toList()); }
