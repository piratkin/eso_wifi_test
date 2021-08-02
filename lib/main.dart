import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const ESPPage(),
    );
  }
}

class ESPPage extends StatefulWidget {
  const ESPPage({Key? key}) : super(key: key);
  @override
  State<ESPPage> createState() => _ESPPageState();
}

class _ESPPageState extends State<ESPPage> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '5010');
  final _contentController = TextEditingController(
    text: 'This text will be converted to binary and sent to the server',
  );
  _sendMessage() async {
    final host = _hostController.text;
    final port = int.parse(_portController.text);
    List<int> buffer = utf8.encode(_contentController.text);
    final socket = await RawSocket.connect(host, port);
    socket.write(buffer);
    await Future.delayed(const Duration(seconds: 2));
    socket.close();
    // ignore: avoid_print
    print("Send: ${buffer.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ESP Demo"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              Container(
                margin: const EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        minLines: 10,
                        maxLines: null,
                        //expands: true,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'IP Address',
                            hintText: 'Enter IP address'),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Port',
                            hintText: 'Enter port number'),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 50,
                  width: 200,
                  child: TextButton(
                    onPressed: _sendMessage,
                    child: Text(
                      "Send Message",
                      textScaleFactor: 1.3,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
