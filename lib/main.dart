// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
//  await DesktopWindow.setWindowSize(Size(1000,40));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studio161',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 1000,
        height: 80,
        child: MainBar(),
      ),
    );
  }
}

class MainBar extends StatelessWidget {
  const MainBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow,
      height: 80,
      child: Row(
        children: [
          ClickButton(),
          ClickDragButton(value: 0.4),
          ClickDragButton(value: 0.8),
        ],
      ),
    );
  }
}

class ClickButton extends StatelessWidget {
  const ClickButton({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: const Icon(Icons.home),
      onTap: () {
        print('click');
      },
    );
  }
}

class ClickDragButton extends StatefulWidget {
  const ClickDragButton({super.key, this.value = 0.0});
  final double value;
  @override
  State<ClickDragButton> createState() => _ClickDragButtonState();
}

class _ClickDragButtonState extends State<ClickDragButton> {
  late double value = widget.value;

  // @override
  // void initState() {
  //   super.initState();
  //   value = widget.value;
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: const Icon(Icons.home),
      onVerticalDragStart: (details) {
        print('drag-Start'); print(details);
      },
      onVerticalDragUpdate: (details) {
        print('drag-Update'); print(details);
      },
      onVerticalDragEnd: (details) {
        print('drag-end'); print(details);
      },
      onTap: () {
        print('tap');
      },
    );
  }
}
