class InputBody {
  late List<String> returnValues;
  late List<FilterObject> filters;
  int? pageSize;
  int? page;

  InputBody({
    required this.returnValues,
    required this.filters,
    this.pageSize,
    this.page,
  });

  InputBody.fromJson(dynamic json) {
    returnValues = [];
    for (var i in json['returnValues']) {
      returnValues.add(i);
    }
    filters = [];
    for (var i in json['filters']) {
      filters.add(FilterObject.fromJson(i));
    }
    pageSize = json['pageSize'];
    page = json['page'];
  }

  bool isValid() {
    for (var i in filters) {
      if (!i.isValid()) {
        return false;
      }
    }
    return true;
  }
}

class FilterObject {
  late String fieldName;
  late String operator;
  late dynamic value;
  String? chainCommand;

  FilterObject({
    required this.fieldName,
    required this.operator,
    required this.value,
    this.chainCommand,
  });

  FilterObject.fromJson(dynamic json) {
    fieldName = json['fieldName'];
    operator = json['operator'];
    value = json['value'];
    chainCommand = json['chainCommand'];
  }

  String composeSQL() {
    switch (operator) {
      case ">":
        return "$fieldName > '$value'";
      case "=":
        return "$fieldName <=> '$value'";
      case "<":
        return "$fieldName < '$value'";
      case "bw":
        return "$fieldName LIKE '$value%'";
      case "in":
        return "$fieldName LIKE '%$value%'";
      case "ew":
        return "$fieldName LIKE '%$value'";
      case "!=":
        return "$fieldName != '$value'";
      default:
        return "ERROR";
    }
  }

  String getChainCommand() {
    if (chainCommand == null) {
      return "AND";
    } else {
      switch (chainCommand!.toUpperCase()) {
        case ("AND"):
          return "AND";
        case "OR":
          return "OR";
        default:
          return "ERROR";
      }
    }
  }

  bool isValid() {
    if (composeSQL() == "ERROR") {
      return false;
    } else if (getChainCommand() == "ERROR") {
      return false;
    } else {
      return true;
    }
  }
}
