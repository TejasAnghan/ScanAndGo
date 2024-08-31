import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';
import 'package:flutter_svg/flutter_svg.dart';

Set<String> result = {};
String? selectedText;
String inputText = '';

String? filename;

int bgColor = 0xFFF4EAE0;
int selectedColor = 0xFFF4DFC8;

bool isShowingCopyright = false;

String buildBarcode(
  Barcode bc,
  String data, {
  String? filename,
  double? width,
  double? height,
  double? fontHeight,
}) {
  /// Create the Barcode
  final svg = bc.toSvg(
    data,
    width: width ?? 200,
    height: height ?? 80,
    fontHeight: 0,
  );
  return svg;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        // appBarTheme: AppBarTheme(backgroundColor: Color(bgColor)),
        scaffoldBackgroundColor: Color(bgColor),
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Scan & Go'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<Uri>? _linkSubscription;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      inputText = uri.toString().split("/").last;
      filename = buildBarcode(
        Barcode.code128(
          useCode128A: false,
          useCode128C: false,
        ),
        inputText,
        filename: 'code-128a',
      );
      // print("filename : $filename");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(bgColor),
          elevation: 0.7,
          title: Text(widget.title),
        ),
        body: inputText.isNotEmpty
            ? const OnlyBarcode()
            : const ScannerAndBarcode());
  }
}

class ScannerAndBarcode extends StatefulWidget {
  const ScannerAndBarcode({super.key});

  @override
  State<ScannerAndBarcode> createState() => _ScannerAndBarcodeState();
}

class _ScannerAndBarcodeState extends State<ScannerAndBarcode> {
  final StreamController<String> controller = StreamController<String>();

  void setText(value) {
    controller.add(value);
    print(isShowingCopyright);
  }

  @override
  void dispose() {
    super.dispose();
    controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureFlipCard(
            animationDuration: const Duration(milliseconds: 300),
            axis: FlipAxis.horizontal,
            enableController:
                false, // if [True] if you need flip the card using programmatically
            frontWidget: Center(
              child: ScalableOCR(
                  paintboxCustom: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4.0
                    ..color = const Color.fromARGB(153, 102, 160, 241),
                  boxLeftOff: 5,
                  boxBottomOff: 2.5,
                  boxRightOff: 5,
                  boxTopOff: 2.5,
                  boxHeight: MediaQuery.of(context).size.height / 3,
                  getRawData: (value) {
                    // inspect(value);
                  },
                  getScannedText: (value) {
                    setText(value);
                  }),
            ),
            backWidget: Padding(
              padding: EdgeInsets.all(
                  (MediaQuery.of(context).size.height / 100) * 3),
              child: CopyWriteCard(
                setText: setText,
              ),
            ),
          ),

          StreamBuilder<String>(
            stream: controller.stream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (isShowingCopyright) return const SizedBox();
              return Result(text: snapshot.data != null ? snapshot.data! : "");
            },
          ),
          // if (result.isNotEmpty)
          // barcode(),
        ],
      ),
    );
  }
}

class Result extends StatelessWidget {
  const Result({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isNotEmpty) {
      parseText();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: result.map((str) {
              return ElevatedButton(
                  onPressed: () {
                    filename = buildBarcode(
                      Barcode.code128(
                        useCode128A: false,
                        useCode128C: false,
                      ),
                      str,
                      filename: 'code-128a',
                    );
                    selectedText = str;
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0.5,

                    backgroundColor: str == selectedText
                        ? Colors.black.withOpacity(1)
                        : null, // Change this to your desired background color
                  ),
                  child: Text(str,
                      style: TextStyle(
                        letterSpacing: 1,
                        fontSize: 16,
                        color: str == selectedText ? Colors.white : null,
                      )) // Ch ),),
                  );
            }).toList(),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        if (filename != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: SvgPicture.string(
              filename!,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          deleteButton(),
        ],
      ],
    );
  }

  deleteButton() {
    return ElevatedButton(
        onPressed: () {
          result.clear();
          filename = null;
          selectedText = null;
        },
        style: ElevatedButton.styleFrom(elevation: 0.5),
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ));
  }

  void parseText() {
    RegExp regExp = RegExp(r'\b[A-Za-z]\d{5}\b');
    Iterable<Match> matches = regExp.allMatches(text);
    for (var match in matches) {
      result.add(match.group(0)!.toUpperCase());
    }
  }
}

class CopyWriteCard extends StatefulWidget {
  final Function(dynamic) setText;
  const CopyWriteCard({required this.setText, super.key});

  @override
  State<CopyWriteCard> createState() => _CopyWriteCardState();
}

class _CopyWriteCardState extends State<CopyWriteCard> {
  @override
  void initState() {
    isShowingCopyright = true;
    widget.setText("value");

    super.initState();
  }

  @override
  void dispose() {
    isShowingCopyright = false;
    widget.setText("value");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Copyright ©2024",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            ),
            Text(
              "Tejas Anghan",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class OnlyBarcode extends StatefulWidget {
  const OnlyBarcode({super.key});

  @override
  State<OnlyBarcode> createState() => _OnlyBarcodeState();
}

class _OnlyBarcodeState extends State<OnlyBarcode> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: filename != null
              ? SvgPicture.string(
                  filename!,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.contain,
                )
              : const Placeholder(),
        ),

        // ElevatedButton(
        //     onPressed: () {
        //       inputText = "";
        //       filename = null;
        //       setState(() {});
        //     },
        //     style: ElevatedButton.styleFrom(elevation: 0.5),
        //     child: const Icon(
        //       Icons.delete,
        //       color: Colors.red,
        //     ))
      ],
    );
  }
}
