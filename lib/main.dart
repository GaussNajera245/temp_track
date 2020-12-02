import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:math'; // For testing purposes

import 'Company.dart';
import 'Employee.dart';
import 'Equipment.dart';
import 'AlcoholTest.dart';
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

  static RegExp exp = new RegExp(r'Tbody=(\d+\.\d+)', caseSensitive: false);
  static RegExp exp2 = new RegExp(r'===========', caseSensitive: false);
  static String apiEndpoint = 'https://okku.herokuapp.com/';
  bool _loading = false;
  String dataBuffer = '';
  Timer _timer = Timer(Duration(milliseconds: 1), () {});
  // double _alcoholTest.alcoholResult = 0.0;
  Color get _alcoColor {
    if (_alcoholTest.alcoholResult == AlcoholResult.alcoholFound) {
      return Colors.red;
    }
    if (_alcoholTest.alcoholResult == AlcoholResult.alcoholNotFound) {
      return Colors.green;
    }
    return Colors.lightBlue;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool get notEmptyPorts {
    if (_ports.length == 0) {
      setState(() {
        _status = "Disconnected";
      });
    }
    return _ports.length > 0;
  }

  FocusNode myFocusNode;

  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  static Company _company = Company(companyName: '', companyId: '');
  static Equipment _equipment = Equipment(equipmentId: 'ALCO--XXXXX');
  Employee _fetchedEmployee;
  AlcoholTest _alcoholTest =
      AlcoholTest(company: _company, equipment: _equipment);

  static const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFsY29Db21wYW55RGVtb0VxMSIsImVtYWlsIjoiYWRtaW5AY2FyZGlvdHJhY2subXgiLCJjb21wYW55SWQiOiI1ZWZlMzZiOTdiNzliYzBmMDc0NWQ4YTkiLCJfaWQiOiI1ZWZlMzc5MTZmMjgwOTBmMjY1OGI5MzMiLCJpYXQiOjE1OTM3MTg2NzMsImV4cCI6MzMxNTEzMTg2NzN9.XotPA8BWp-znRJa_xhTyoiHtmauwXbz6gFlsHl9vAi4';
  var _allRequest = Request(token: token, apiEndpoint: apiEndpoint);

  Future<bool> _connectTo(device) async {
    _serialData.clear();
    _alcoholTest.alcoholResult = AlcoholResult.notSet;

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
    await _port.setPortParameters( 9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE );

    _transaction = Transaction.stringTerminated(
        _port.inputStream, Uint8List.fromList([13, 10]));

    _subscription = _transaction.stream.listen((String line) async {
      var alcoStatus = line;

      if (line != 'TRUE' && line != 'FALSE') {
        _alcoholTest.alcoholResult = AlcoholResult.notSet;
      }

      if (alcoStatus == 'FALSE') {
        setState(() {
          _alcoholTest.alcoholResult = AlcoholResult.alcoholFound;
        });
      }

      if (alcoStatus == 'TRUE') {
        setState(() {
          _alcoholTest.alcoholResult = AlcoholResult.alcoholNotFound;
        });
      }

      // _changeAlcoStatus();

      _timer.cancel();
      _timer = Timer(Duration(seconds: 5), () {
        _resetValues();
      });

      if (_fetchedEmployee != null) {
        var saveAlcoResponse = await _saveAlcoholTest(_alcoholTest);
        if (saveAlcoResponse.toString().contains('errors')) {
          _showSnackbarAndReset(
              'Error al tratar de guardar registro', Colors.redAccent);
          return;
        }
        if (saveAlcoResponse.toString().contains('breathAlcoholTestId')) {
          _showSnackbar('Registro guardado', Colors.greenAccent);
          return;
        }
      } else {
        _showSnackbar("Por favor ingresa # de usuario antes de hacer la prueba",
            Colors.orange[900]);
      }
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }


  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    // print(devices);

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

  void _testAlcohol() async {
    Random random = new Random();
    List alcoResults = [
      AlcoholResult.alcoholFound,
      AlcoholResult.alcoholNotFound
    ];
    int randomBool = random.nextInt(2);

    setState(() {
      _alcoholTest.alcoholResult = alcoResults[randomBool];
    });

    // Set timer
    // TODO: Do we have to cancel timer?
    _timer.cancel();
    _timer = Timer(Duration(seconds: 5), () {
      _resetValues();
    });

    // // inspect(_alcoholTest);
    // var saveAlcoResponse = await _saveAlcoholTest(_alcoholTest);
    // // inspect(saveAlcoResponse);
    // // print(saveAlcoResponse.toString().contains('breathAlcoholTestId'));
    // // print(saveAlcoResponse.toString().contains('errors'));
    // if (saveAlcoResponse.toString().contains('errors')) {
    //   _showSnackbarAndReset(
    //       'Error al tratar de guardar registro', Colors.redAccent);
    // }
    // if (saveAlcoResponse.toString().contains('breathAlcoholTestId')) {
    //   _showSnackbar('Registro guardado', Colors.greenAccent);
    //   return;
    // }

    if (_fetchedEmployee != null) {
      var saveAlcoResponse = await _saveAlcoholTest(_alcoholTest);
      if (saveAlcoResponse.toString().contains('errors')) {
        _showSnackbarAndReset(
            'Error al tratar de guardar registro', Colors.redAccent);
        return;
      }
      if (saveAlcoResponse.toString().contains('breathAlcoholTestId')) {
        _showSnackbar('Registro guardado', Colors.greenAccent);
        return;
      }
    } else {
      _showSnackbar("Por favor ingresa # de usuario antes de hacer la prueba",
          Colors.orange[900]);
    }
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
      _showSnackbarAndReset(
          'Por favor conecta el dispositivo a internet', Colors.redAccent);
      return;
    }
    setState(() {
        _loading = true;
    }); 

    Employee foundEmployee = await _allRequest.fetchEmployee(employeeRfid, (){
      setState(() {
        _loading = false;
      }); 
    });

    _alcoholTest.employee = foundEmployee;
    if (foundEmployee == null) {
      _showSnackbar('Usuario no encontrado, Guardando nuevo usuario anónimo...',
          Colors.orangeAccent);
      try {
        setState(() {
          _loading = true;
        });
        var trySaveEmployee = await _allRequest.saveNewEmployee(employeeRfid, _alcoholTest, (){
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
        _showSnackbarAndReset('Error al guardar nuevo usuario anónimo', Colors.redAccent);
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
      _alcoholTest = AlcoholTest(
          company: _company,
          equipment: _equipment); // This resets the whole thing.
    });
    Timer(Duration(milliseconds: 50), () {
      myFocusNode.requestFocus();
    });
  }

  String _getAlcoResultText(AlcoholResult result) {
    return result == AlcoholResult.alcoholFound ? 'Fail' : 'Pass';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      key: _scaffoldKey,
      backgroundColor: _alcoColor,
      appBar: AppBar(
        title: Image.asset('assets/cardiotrack_logo.png', fit: BoxFit.cover),
        backgroundColor: Colors.white,
        // title: const Text('Alcotrack Demo App'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child:
                  Column(
                children: [
                  notEmptyPorts && _status == "Connected"
                      ? Text(
                          _alcoholTest.alcoholResult == AlcoholResult.notSet
                              ? _alcoholTest.employee != null
                                  ? 'Sopla en la boquilla para realizar la prueba'
                                  : 'Acerca tu tarjeta al lector o sopla en la boquilla para realizar la prueba'
                              : _getAlcoResultText(_alcoholTest.alcoholResult),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: _alcoholTest.alcoholResult ==
                                      AlcoholResult.notSet
                                  ? 25
                                  : 150))
                      : Text('Por favor conecta el alcoholímetro 📲',
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
                            hintText: '123456'),
                        onSubmitted: (value) {
                          _getEmployee(value);
                        },
                        focusNode: myFocusNode,
                        autofocus: true),
                    trailing: RaisedButton(
                        child: Text("Nuevo Usuario"),
                        onPressed: _resetValues),
                        
                    // onPressed: _testAlcohol),
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
            ))
          ],
        ),
      ),
    ));
  }
}
