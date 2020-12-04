// import 'dart:convert';
import 'Company.dart';
import 'Employee.dart';
import 'Equipment.dart';

class TemperatureDoc {
  Employee employee;
  final Company company;
  final Equipment equipment;
  String temp;
  String equID;

  TemperatureDoc({
      this.company,
      this.employee,
      this.equipment,
      this.temp,
      this.equID
  });

  double temperature (){
    return ( temp == null )
      ? 0.0
      : double.parse(temp);
  }

  String get tempC {
    var _value = (temperature()).toStringAsFixed(2);
    return "$_value °C";
  }

  String get tempF {
    var F = (temperature()*(9/5))+32;
    return F.toString();
  }

  // String toJson(AlcoholTest temp) {
  //   var json = jsonEncode(temp);
  //   return json;
  // }
}

