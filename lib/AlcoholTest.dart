import 'dart:convert';
import 'Company.dart';
import 'Employee.dart';
import 'Equipment.dart';

class AlcoholTest {
  // final String id;
  AlcoholResult alcoholResult;
  Employee employee;
  final Company company;
  final Equipment equipment;

  AlcoholTest({
      this.alcoholResult = AlcoholResult.notSet,
      this.company,
      this.employee,
      this.equipment
  });

  String toJson(AlcoholTest temp) {
    var json = jsonEncode(temp);
    return json;
  }
}

enum AlcoholResult { alcoholFound, alcoholNotFound, notSet }
