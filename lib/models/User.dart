class User {
  final String token;
  final String companyId;
  final String companyName;
  String equipmentId;

  User({this.token, this.companyId, this.companyName, this.equipmentId});

  factory User.fromJson(Map<String, dynamic> json) {
    var serializedJson = json['data']['signinEquipmentUser'];
    return User(
        token: serializedJson['token'],
        companyId: serializedJson['companyId'],
        companyName: serializedJson['companyName']);
  }
}
