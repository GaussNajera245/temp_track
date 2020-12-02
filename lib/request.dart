import 'dart:developer';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Employee.dart';
import 'AlcoholTest.dart';

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
      inspect(e);
      throw Exception('Something Failed:(, see inspect');
    }
  }

  Future saveNewEmployee( String rfid, AlcoholTest alco, Function callback ) async {
    String mutationString = "mutation{  addEmployee(  rfid:\"$rfid\", firstName:\"Anónimo\", dadSurname:\"X\", momSurname:\"Y\", companyName:\"${alco.company.companyName}\", companyId:\"${alco.company.companyId}\" ) {employeeId} }";
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
        // "mutation{ newalcoDocument(input: { alcoerature: ${alco.alcoholResult}, companyId: \"${alco.company.companyId}\", companyName: \"${alco.company.companyName}\", rfid: ${alco.employee.rfid}, employeeId: \"${alco.employee.companyEmployeeId}\", equipmentId: \"${alco.equipment.equipmentId}\"  }) { rfid } }";
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

}