import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

import 'dart:convert';

// import 'dart:math'; // For testing purposes

import 'Company.dart';
import 'Employee.dart';
import 'Equipment.dart';
import 'TemperatureDoc.dart';
import 'request.dart';

import 'package:flutter/services.dart';

import 'package:connectivity/connectivity.dart';

void main() => runApp(MyMaterialApp());

class MyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test",
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UsbPort _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  int _deviceId;
  TextEditingController _textController = TextEditingController();

  static String apiEndpoint = 'https://okku.herokuapp.com/';
  static const token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFsY29Db21wYW55RGVtb0VxMSIsImVtYWlsIjoiYWRtaW5AY2FyZGlvdHJhY2subXgiLCJjb21wYW55SWQiOiI1ZWZlMzZiOTdiNzliYzBmMDc0NWQ4YTkiLCJfaWQiOiI1ZWZlMzc5MTZmMjgwOTBmMjY1OGI5MzMiLCJpYXQiOjE1OTM3MTg2NzMsImV4cCI6MzMxNTEzMTg2NzN9.XotPA8BWp-znRJa_xhTyoiHtmauwXbz6gFlsHl9vAi4';
  var _allRequest = Request(token: token, apiEndpoint: apiEndpoint);

  bool _loading = false;
  String dataBuffer = '';
  Timer _timer = Timer(Duration(milliseconds: 1), () {});

  Color get _backColor {
    if ( _temp.temperature() == null || _temp.temperature() == 0 ) {
      return Colors.lightBlue;
    } else {
      if (_temp.temperature() < 36.8) {
        return Colors.green;
      } else if (_temp.temperature() >= 36.8 && _temp.temperature() < 37.3) {
        return Colors.yellow;
      } else if (_temp.temperature() >= 37.3) {
        return Colors.red;
      } else {
        return Colors.lightBlue;
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool get notEmptyPorts {
    if (_ports == null || _ports.length == 0) {
      setState(() {
        _status = "Disconnected";
      });
    }
    return _ports != null && _ports.length > 0;
  }

  FocusNode myFocusNode;

  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  static Company _company =
      Company(companyName: 'alcos', companyId: '5efe36b97b79bc0f0745d8a9');
  static Equipment _equipment = Equipment(equipmentId: 'TEMP--XXXXX');
  Employee _fetchedEmployee;
  TemperatureDoc _temp = TemperatureDoc(company: _company, equipment: _equipment);

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      _deviceId = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(
        9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port.inputStream, Uint8List.fromList([13, 10]));

    var buff = '';
    _subscription = _transaction.stream.listen((String line) {
      var currentData = line.split(" ").join("");
      RegExp exp = new RegExp(r'Tbody=(\d+\.\d+)', caseSensitive: false);
      buff = buff + currentData;

      var matches = exp.allMatches(buff);
      if (exp.hasMatch(currentData)) {
        _timer.cancel();

        _timer = Timer(Duration(milliseconds: 100), () {
          var found = matches.last.group(0);
          var passed = found.substring(6);
          log(passed);
          setState(() {
            _temp.temp = passed;
          });

          _testTemperature();
        });
      }
      if (currentData.substring(0, 4) == "Vbat") {
        buff = '';
      }
      log('.');
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text(device.productName),
          subtitle: Text(device.manufacturerName),
          trailing: RaisedButton(
            child:
                Text(_deviceId == device.deviceId ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_deviceId == device.deviceId ? null : device)
                  .then((res) {
                _getPorts();
              });
            },
          )));
    });

    setState(() {
      print(_ports);
    });
  }

  void _showSnackbar(String message, Color color) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(
        message,
      ),
      duration: Duration(seconds: 3),
    ));
  }

  void _showSnackbarAndReset(String message, Color color) {
    _showSnackbar(message, color);
    setState(() {
      _resetValues();
    });
  }

  void _getEmployee(employeeRfid) async {
    if (_connectionStatus == 'ConnectivityResult.none') {
      _showSnackbarAndReset( 'Por favor conecta el dispositivo a internet', Colors.redAccent );
      return;
    }
    setState(() {
      _loading = true;
    });

    Employee foundEmployee = await _allRequest.fetchEmployee(employeeRfid, () {
      setState(() {
        _loading = false;
      });
    });

    _temp.employee = foundEmployee;

    if (foundEmployee == null) {
      _showSnackbar('Usuario no encontrado, Guardando nuevo usuario anónimo...',
          Colors.orangeAccent);
      try {
        setState(() {
          _loading = true;
        });
        var trySaveEmployee =
            await _allRequest.saveNewEmployee(employeeRfid, _company, () {
          setState(() {
            _loading = false;
          });
        });
        inspect(trySaveEmployee);
        if (trySaveEmployee.toString().contains('employeeId')) {
          setState(() {
            _fetchedEmployee =
                Employee.newFromJson(jsonDecode(trySaveEmployee));
            _fetchedEmployee.companyName = _company.companyName;
            _fetchedEmployee.rfid = employeeRfid;
          });

          _showSnackbar('Nuevo usuario guardado', Colors.purpleAccent);
        }
      } catch (e) {
        print(e);
        _showSnackbarAndReset(
            'Error al guardar nuevo usuario anónimo', Colors.redAccent);
      }

      // return;
    } else {
      setState(() {
        _fetchedEmployee = foundEmployee;
      });
    }
  }

  void _resetValues() {
    _textController.text = '';
    setState(() {
      _loading = false;
      _fetchedEmployee = null;
      _temp =
          TemperatureDoc(company: _company, equipment: _equipment, temp: null);
      // This resets the whole thing.
    });
    Timer(Duration(milliseconds: 50), () {
      myFocusNode.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
    ]);

    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    myFocusNode = FocusNode();

    UsbSerial.usbEventStream.listen((UsbEvent event) {
      // print(event);
      _getPorts();
    });

    _getPorts();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _timer.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
    _connectivitySubscription.cancel();
    _connectTo(null);
  }

  void _testTemperature() async {
    // Random random = new Random();

    _timer.cancel();
    _timer = Timer(Duration(seconds: 5), () {
      _resetValues();
    });

    if (_fetchedEmployee != null) {
      var saveAlcoResponse = await _allRequest.saveTemperature(_temp);
      inspect(saveAlcoResponse);

      if (saveAlcoResponse.toString().contains('errors')) {
        _showSnackbarAndReset('Error al tratar de guardar registro', Colors.redAccent);
        return;
      }
      if (saveAlcoResponse.toString().contains('newTempDocument')) {
        _showSnackbar('Registro guardado', Colors.greenAccent);
        return;
      }
    } else {
      _showSnackbar(
        "Por favor ingresa # de usuario antes de hacer la prueba",
        Colors.orange[900],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _backColor,
        appBar: AppBar(
          title: Image.asset('assets/cardiotrack_logo.png', fit: BoxFit.cover),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
                    notEmptyPorts && _status == "Connected"
                        ? Text(
                            _temp.temperature() == 0
                                ? _temp.employee != null
                                    ? 'Acerca tu frente al sensor para la lectura'
                                    : 'Pasa tu tarjeta al lector o acerca tu frente al sensor'
                                : _temp.tempC,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _temp.temperature() == 0 ? 25 : 100,   
                            ),
                          )
                        : Text('Por favor conecta el termometro 📲',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.orange[900], fontSize: 45)),
                    if (_status != "Connected") ..._ports,
                  ],
                ),
              ),
              Spacer(),
              Center(
                child: Card(
                  child: Column(
                    children: [
                      if (_connectionStatus == 'ConnectivityResult.none')
                        Text(
                          'Please connect to Internet',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        Text(
                          'Internet Connection',
                          style: TextStyle(color: Colors.green),
                        ),
                      Text(notEmptyPorts
                          ? 'Device Status: $_status\n'
                          : 'Device Status: $_status\n'),
                      Row(children: [
                        SizedBox(
                          height: 35,
                          width: 250,
                          child: _loading
                              ? Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Text(
                                  _fetchedEmployee != null
                                      ? _fetchedEmployee.fullName
                                      : "Ingresa un # de usuario",
                                  style: Theme.of(context).textTheme.headline6,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        Expanded(
                          child: Text(
                            _equipment.equipmentId,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                      ListTile(
                        title: TextField(
                            enabled: _fetchedEmployee == null || _loading,
                            controller: _textController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '# de Usuario + Enter',
                              hintText: '123456',
                            ),
                            onSubmitted: (value) {
                              _getEmployee(value);
                            },
                            focusNode: myFocusNode,
                            autofocus: true),
                        trailing: RaisedButton(
                          child: Text("Nuevo Usuario"),
                          // onPressed: _resetValues),

                          onPressed: _testTemperature,
                        ),
                      ),
                      Text(_company.companyName,
                          style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold)),
                      Text(
                        'Al usar este equipo acepto los "Términos y condiciones" y el "Aviso de privacidad": cardiotrack.mx/ape',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 8),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
