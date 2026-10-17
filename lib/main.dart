import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:excel/excel.dart';
import 'package:graphview/graphview.dart';
import 'dart:io';

void main() {
  runApp(const AslonasabApp());
}

class AslonasabApp extends StatelessWidget {
  const AslonasabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اصل و نسب',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}

class Person {
  final String id;
  String firstName;
  String lastName;
  String? nickname;
  String birthDateShamsi;
  String? fatherId;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nickname,
    required this.birthDateShamsi,
    this.fatherId,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Person> people = [
    Person(id: '1', firstName: 'بزرگ', lastName: 'علوی', nickname: 'حاج‌آقا میرزا', birthDateShamsi: '۱۳۰۰/۰۱/۰۱'),
    Person(id: '2', firstName: 'محمد', lastName: 'علوی', birthDateShamsi: '۱۳۳۰/۰۵/۱۲', fatherId: '1'),
    Person(id: '3', firstName: 'علی', lastName: 'علوی', nickname: 'امیر', birthDateShamsi: '۱۳۶۰/۱۰/۲۰', fatherId: '2'),
    Person(id: '4', firstName: 'رضا', lastName: 'علوی', birthDateShamsi: '۱۳۶۵/۰۲/۱۵', fatherId: '2'),
  ];

  final Graph graph = Graph()..isTree = true;
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _initGraph();
  }

  void _initGraph() {
    for (var person in people) {
      if (person.fatherId != null) {
        final parentNode = Node.Id(person.fatherId);
        final childNode = Node.Id(person.id);
        graph.addEdge(parentNode, childNode);
      }
    }
    builder
      ..siblingSeparation = (20)
      ..levelSeparation = (40)
      ..subtreeSeparation = (20)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  void exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetIndividuals = excel['افراد'];
    sheetIndividuals.appendRow([TextCellValue('شناسه'), TextCellValue('نام'), TextCellValue('نام خانوادگی'), TextCellValue('نام مستعار/لقب'), TextCellValue('تاریخ تولد شمسی')]);
    for (var p in people) {
      sheetIndividuals.appendRow([
        TextCellValue(p.id),
        TextCellValue(p.firstName),
        TextCellValue(p.lastName),
        TextCellValue(p.nickname ?? '-'),
        TextCellValue(p.birthDateShamsi),
      ]);
    }

    Sheet sheetFamilies = excel['روابط فامیلی'];
    sheetFamilies.appendRow([TextCellValue('شناسه فرزند'), TextCellValue('شناسه پدر')]);
    for (var p in people) {
      if (p.fatherId != null) {
        sheetFamilies.appendRow([TextCellValue(p.id), TextCellValue(p.fatherId!)]);
      }
    }

    excel.delete('Sheet1');

    try {
      var fileBytes = excel.save();
      String filePath = "/storage/emulated/0/Download/shajarenameh_export.xlsx";
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فایل اکسل با موفقیت در پوشه دانلودها ذخیره شد:\n$filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره فایل اکسل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شجره‌نامه اصل و نسب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: exportToExcel,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('تست انتخاب تاریخ شمسی'),
              onPressed: () async {
                Jalali? picked = await showPersianDatePicker(
                  context: context,
                  initialDate: Jalali.now(),
                  firstDate: Jalali(1300, 1),
                  lastDate: Jalali(1450, 12),
                );
                if (picked != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تاریخ انتخاب شده: ${picked.formatTypeFull()}')),
                  );
                }
              },
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 2
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  var value = node.key!.value as String;
                  var person = people.firstWhere((p) => p.id == value);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5)],
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${person.firstName} ${person.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (person.nickname != null)
                          Text(
                            '(${person.nickname})',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, style: FontStyle.italic),
                          ),
                        const SizedBox(height: 4),
                        Text('تولد: ${person.birthDateShamsi}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
