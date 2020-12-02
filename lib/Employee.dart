class Employee {
  final String id;
  final String fullName;
  String companyName;
  final String companyEmployeeId;
  String rfid;

  Employee(
      {this.id,
      this.fullName,
      this.companyName,
      this.companyEmployeeId,
      this.rfid});

  factory Employee.fromJson(Map<String, dynamic> json) {
    // print(json);
    // print(json['data']);
    // print(json['data']['getEmployeeByRfid']);
    // print(json['data']['getEmployeeByRfid']['fullName']);
    var serializedJson = json['data']['getEmployeeByRfid'];
    return Employee(
        id: serializedJson['_id'],
        fullName: serializedJson['fullName'],
        companyName: serializedJson['companyName'],
        companyEmployeeId: serializedJson['companyEmployeeId'],
        rfid: serializedJson['rfid']);
  }

  factory Employee.newFromJson(Map<String, dynamic> json) {
    // print(json);
    // print(json['data']);
    // print(json['data']['getEmployeeByRfid']);
    // print(json['data']['getEmployeeByRfid']['fullName']);
    var serializedJson = json['data']['addEmployee'];
    return Employee(
        id: serializedJson['employeeId'],
        fullName: "Anónimo X Y",
        companyName: null,
        companyEmployeeId: null,
        rfid: null);
  }
}

// class Employee {
//   final int userId;
//   final int id;
//   final String title;

//   Employee({this.userId, this.id, this.title});

//   factory Employee.fromJson(Map<String, dynamic> json) {
//     return Employee(
//       userId: json['userId'],
//       id: json['id'],
//       title: json['title'],
//     );
//   }
// }
