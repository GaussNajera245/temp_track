import 'dart:developer';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Company.dart';
import 'Employee.dart';
import 'AlcoholTest.dart';
import 'TemperatureDoc.dart';

class Request {
  String token;
  String apiEndpoint;
  Request({ this.token, this.apiEndpoint });

  Future fetchEmployee( String rfid, Function callback ) async {

    String queryString = "query{ getEmployeeByRfid(rfid:\"$rfid\") { _id fullName companyName companyEmployeeId rfid } }";
    log(queryString);

    var headers = {
      'authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    try {
      final response = await http.post(apiEndpoint,
          headers: headers, body: jsonEncode({"query": queryString}));
      if (response.statusCode == 200) {
        print('Status code is 200');
        callback();
        return Employee.fromJson(jsonDecode(response.body));
      } else {
        callback();
        throw Exception('Failed to fetch Employee');
      }
    } catch (e) {
      print("Employee Not Found");
      inspect(e);
    }
  }

  Future saveNewEmployee( String rfid, Company company, Function callback ) async {
    String mutationString = "mutation{  addEmployee(  rfid:\"$rfid\", firstName:\"Anónimo\", dadSurname:\"X\", momSurname:\"Y\", companyName:\"${company.companyName}\", companyId:\"${company.companyId}\" ) {employeeId} }";
    print(mutationString);
    var headers = {
      'authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    try {
      final saveEmployeeResponse = await http.post(apiEndpoint,
          headers: headers, body: jsonEncode({"query": mutationString}));

      if (saveEmployeeResponse.statusCode == 200) {
        print('status code 200 from _saveNewEmployee');
        callback();
        return saveEmployeeResponse.body;
      } 
      else {
        callback();
        throw Exception('Failed to save anonymus employee');
      }
    } catch (e) {
      inspect(e);
      throw Exception('Something Wrong on saveNewEmployee');
    }
  }

  Future saveAlcoholTest(AlcoholTest alco) async {
    inspect(alco);
    String mutationString =
        "mutation{ addBreathAlcoholTest( elevatedBreathAlcoholLevel: ${alco.alcoholResult == AlcoholResult.alcoholFound ? true : false}, companyId: \"${alco.company.companyId}\" rfid: \"${alco.employee.rfid}\", employeeId: \"${alco.employee.id}\", equipmentId: \"${alco.equipment.equipmentId}\", companyName: \"${alco.company.companyName}\"  ) { breathAlcoholTestId } }";
    print(mutationString);
    var headers = {
      'authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    try {
      final saveAlcoResponse = await http.post(apiEndpoint,
          headers: headers, body: jsonEncode({"query": mutationString}));

      if (saveAlcoResponse.statusCode == 200) {
        print('status code 200 from _saveAlcoholTest');

        return saveAlcoResponse.body;
      } else {
        throw Exception('Failed to save alco test');
      }
    } catch (e) {
      print(e);
    }
  }

  Future saveTemperature(TemperatureDoc temp) async {
    inspect(temp);
    var equipmentID = ( temp.equID != null ) ? "equipmentId: \"${temp.equID}\"," : "";
    
    String mutationString =
        "mutation{ newTempDocument(input:{ temperature: ${temp.temperature()}, companyId: \"${temp.company.companyId}\", companyName: \"${temp.company.companyName}\", rfid: \"${temp.employee.rfid}\", $equipmentID employeeId: \"${temp.employee.id}\" }) { rfid }}";
    print(mutationString);
    var headers = {
      'authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    try {
      final saveAlcoResponse = await http.post(apiEndpoint,
          headers: headers, body: jsonEncode({"query": mutationString}));

      if (saveAlcoResponse.statusCode == 200) {
        print('status code 200 from _saveAlcoholTest');

        return saveAlcoResponse.body;
      } else {
        throw Exception('Failed to save temp');
      }
    } catch (e) {
      inspect(e);
      throw Exception('something wrong in saveTemp see inspect');
    }
  }


}