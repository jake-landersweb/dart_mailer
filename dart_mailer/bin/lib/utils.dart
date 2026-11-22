int getEpochDate({DateTime? date}) {
  late int epoch;
  if (date != null) {
    epoch = date.millisecondsSinceEpoch;
  } else {
    epoch = DateTime.now().millisecondsSinceEpoch;
  }
  return epoch;
}

String getIsoDate({DateTime? date}) {
  late String iso;
  if (date != null) {
    iso = date.toUtc().toIso8601String();
  } else {
    iso = DateTime.now().toUtc().toIso8601String();
  }
  return iso;
}

List<String> convertList(List<dynamic> list) {
  List<String> response = [];
  for (String i in list) {
    response.add(i);
  }
  return response;
}
