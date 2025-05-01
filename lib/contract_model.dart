class ContractModel {
  String? type;
  String? stateMutability;
  List<Inputs>? inputs;

  ContractModel({this.type, this.stateMutability, this.inputs});

  ContractModel.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    stateMutability = json['stateMutability'];
    if (json['inputs'] != null) {
      inputs = <Inputs>[];
      json['inputs'].forEach((v) {
        inputs!.add(Inputs.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['stateMutability'] = stateMutability;
    if (inputs != null) {
      data['inputs'] = inputs!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Inputs {
  String? type;
  String? name;
  String? internalType;

  Inputs({this.type, this.name, this.internalType});

  Inputs.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    name = json['name'];
    internalType = json['internalType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['name'] = name;
    data['internalType'] = internalType;
    return data;
  }
}
