import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:split_view/split_view.dart';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HexTerm',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        appBarTheme: AppBarTheme(
          color: Colors.indigo,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        appBarTheme: AppBarTheme(
          color: Colors.indigo,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HexTermPage(),
    );
  }
}

class HexTermPage extends StatefulWidget {
  const HexTermPage({Key? key}) : super(key: key);
  @override
  State<HexTermPage> createState() => _HexTermPageState();
}

class _HexTermPageState extends State<HexTermPage> {
  RawSocket? socket;
  bool showProgress = false;
  final _hostController = TextEditingController(text: '');
  final _portController = TextEditingController(text: '');
  final _contentController = TextEditingController(text: '');
  final _outputController = TextEditingController(text: '');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _contentController.dispose();
    _outputController.dispose();
    _disconnectFromSocket();
    super.dispose();
  }

  _connectToSocket() async {
    if (socket != null) _disconnectFromSocket();
    final host = _hostController.text;
    final port = int.parse(_portController.text);
    await RawSocket.connect(host, port).then((sock) {
      setState(() {
        socket = sock;
        sock.listen(
          (RawSocketEvent event) {
            if (event == RawSocketEvent.read) {
              setState(() {
                showProgress = false;
              });
              Uint8List? data = sock.read();
              if (data != null) {
                if (data.isNotEmpty) {
                  String _content = "";
                  final hex = HEX.encode(data);
                  for (int i = 0; i < hex.length; i += 2) {
                    _content += hex.substring(i, i + 2) + ' ';
                  }
                  // final _content = String.fromCharCodes(data);
                  setState(() {
                    const limitSize = 10000;
                    if (_content.length > limitSize) {
                      _outputController.text =
                          _content.substring(_content.length - limitSize);
                    } else {
                      final tailSize = limitSize - _content.length;
                      final available =
                          min(tailSize, _outputController.text.length);
                      _outputController.text = _outputController.text.substring(
                              _outputController.text.length - available) +
                          (_outputController.text.isNotEmpty ? '\n' : '') +
                          _content;
                    }
                  });
                }
              }
            } else if (event == RawSocketEvent.readClosed) {
              _disconnectFromSocket();
            }
          },
          onError: (error, StackTrace trace) async {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: new Text('Socket Error'),
                content: Text(error.toString()),
                actions: <Widget>[
                  new TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: new Text('OK'),
                  ),
                ],
              ),
            );
          },
          onDone: () {
            _disconnectFromSocket();
          },
          cancelOnError: false,
        );
      });
    }).catchError((error) async {
      _disconnectFromSocket();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: new Text('Connect Error'),
          content: Text(error.toString()),
          actions: <Widget>[
            new TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: new Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  _disconnectFromSocket() {
    setState(() {
      if (socket != null) {
        socket!.close();
      }
      socket = null;
      showProgress = false;
    });
  }

  _sendMessage() async {
    if (socket == null) {
      _disconnectFromSocket();
      return;
    }
    setState(() {
      showProgress = true;
    });
    List<String> message = _contentController.text
        .replaceAll(RegExp('[^ 0-9abcdefABCDEF]'), ' ')
        .split(' ');
    List<int> buffer = [];
    for (String e in message) {
      if (e.isNotEmpty) {
        String hex = (e.length % 2 == 1) ? '0' + e : e;
        for (int i = 0; i < hex.length; i += 2) {
          String _hex = hex.substring(i, i + 2);
          buffer.addAll(HEX.decode(_hex));
        }
      }
    }
    socket!.write(buffer);
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return Scaffold(
      appBar: AppBar(
        // leading: GestureDetector(
        //   onTap: () {},
        //   child: Icon(
        //     Icons.menu,
        //   ),
        // ),
        title: const Text("HexTerm"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Exit',
              onPressed: () {
                exit(0);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              child: showProgress
                  ? LinearProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Container(
                    child: Expanded(
                      child: SplitView(
                        gripColorActive: Theme.of(context).primaryColor,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              textAlignVertical: TextAlignVertical.bottom,
                              controller: _outputController,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    (platform == TargetPlatform.windows
                                        ? EdgeInsets.only(
                                            left: 5.0,
                                            top: 8.0,
                                            bottom: 8.0,
                                          )
                                        : EdgeInsets.only(
                                            left: 5.0,
                                            top: 5.0,
                                            bottom: 0.0,
                                          )),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              textAlignVertical: TextAlignVertical.top,
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    (platform == TargetPlatform.windows
                                        ? EdgeInsets.only(
                                            left: 5.0,
                                            top: 8.0,
                                            bottom: 8.0,
                                          )
                                        : EdgeInsets.only(
                                            left: 5.0,
                                            top: 5.0,
                                            bottom: 0.0,
                                          )),
                              ),
                            ),
                          ),
                        ],
                        viewMode: SplitViewMode.Vertical,
                        indicator: SplitIndicator(
                          viewMode: SplitViewMode.Vertical,
                        ),
                        activeIndicator: SplitIndicator(
                          viewMode: SplitViewMode.Vertical,
                          isActive: true,
                        ),
                        controller: SplitViewController(
                          weights: [.618, 1 - .618],
                          limits: [
                            WeightLimit(max: .8),
                            WeightLimit(max: .8),
                          ],
                        ),
                        // onWeightChanged: (weightsView) {},
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Address',
                                  hintText: 'Address or DNS name'),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _portController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Port',
                                hintText: 'Port number'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            runAlignment: WrapAlignment.spaceBetween,
                            direction: Axis.horizontal,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 50,
                                width: 140,
                                child: TextButton(
                                  onPressed: socket == null
                                      ? _connectToSocket
                                      : _disconnectFromSocket,
                                  child: Text(
                                    socket == null ? "Open" : "Close",
                                    textScaleFactor: 1.3,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(.1)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                width: 140,
                                child: TextButton(
                                  onPressed:
                                      socket == null ? null : _sendMessage,
                                  child: Text(
                                    "Send",
                                    textScaleFactor: 1.3,
                                    style: TextStyle(
                                      color: socket == null
                                          ? Colors.grey
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(.1)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
