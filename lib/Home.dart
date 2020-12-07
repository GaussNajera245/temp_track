import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/User.dart';
import 'Interface.dart';
import 'request.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static String apiEndpoint = 'https://okku.herokuapp.com/';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isAuth = false;
  User _user;
  PageController pageController;
  int pageIndex = 0;
  var _req = Request(apiEndpoint: apiEndpoint);

  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _equipmentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  // Future<String> _token;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _prefs.then((SharedPreferences prefs) {
      var foundUser = prefs.getStringList('user') ?? [];
      print('found user: $foundUser');
      if (foundUser.isNotEmpty) {
        User loggedUser = User(
            token: foundUser[0],
            companyId: foundUser[1],
            companyName: foundUser[2],
            equipmentId: foundUser[3]);

        _user = loggedUser;
      } else {
        _user = null;
      }

      if (_user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Interface(user: _user)),
        );
      }
    });

  }


  createUserInFirestore() async {
  }

  @override
  void dispose() {
    _userController.dispose();
    _equipmentIdController.dispose();
    _passwordController.dispose();
    pageController.dispose();
    super.dispose();
  }
  // Example code for sign out.
  void _signOut() async {
    // await _auth.signOut();
  }

  Future<bool> _saveUserKeysToSP(User user) async {
    final SharedPreferences prefs = await _prefs;
    bool saveUserToSpSuccess = false;

    var userKeysList = [
      user.token,
      user.companyId,
      user.companyName,
      user.equipmentId
    ];

    saveUserToSpSuccess =
        await prefs.setStringList('user', userKeysList).then((bool success) {
      return success;
    });

    return saveUserToSpSuccess;
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(microseconds: 300), curve: Curves.easeInOut);
  }

  void _loginToCardiotrack(String username, String password) async {
    var loginResponse = await _req.loginRequest(username, password);
    inspect(loginResponse);

    if (loginResponse.contains('errors')) {
      _showSnackbar('Login not succesful, please try again', Colors.redAccent);
      print('_loginToCardiotrack has errors');
      setState(() {
        _formKey.currentState.reset();
      });
      return;
    }
    if (loginResponse.contains('data')) {
      print('_loginToCardiotrack was succesful');
      User loggedUser = User.fromJson(jsonDecode(loginResponse));
      loggedUser.equipmentId = _equipmentIdController.text;

      var saveUsertoSpSuccess = await _saveUserKeysToSP(loggedUser);

      if (saveUsertoSpSuccess) {
        setState(() {
          _user = loggedUser;
          _formKey.currentState.reset();
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Interface(user: _user)),
        );
      } else {
        _formKey.currentState.reset();
      }

      return;
    }
  }

  void _showSnackbar(String message, Color color) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(
        message,
      ),
      duration: Duration(seconds: 5),
    ));
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Image.asset('assets/cardiotrack_logo.png', fit: BoxFit.cover),
              Container(
                padding: EdgeInsets.all(20),
                child: Card(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Username',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: _userController,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(30.0),
                                    ),
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.grey[800]),
                                  hintText: "Enter your username",
                                  fillColor: Colors.white70),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Equipment ID',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: _equipmentIdController,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(30.0),
                                    ),
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.grey[800]),
                                  hintText: "Enter equipment ID",
                                  fillColor: Colors.white70),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Password',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(30.0),
                                    ),
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.grey[800]),
                                  hintText: "Enter your password",
                                  fillColor: Colors.white70),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RaisedButton(
                              onPressed: () {
                                if (_formKey.currentState.validate()) {
                                  _loginToCardiotrack(_userController.text,
                                      _passwordController.text);
                                }
                              },
                              child: Text('Log in'),
                              color: Colors.transparent,
                              elevation: 0,
                              textColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(color: Colors.white)),
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return buildUnAuthScreen();
  }
}
