/// Unix time in **seconds** (matches SQLite INTEGER timestamps in Drift).
int unixNowSeconds() =>
    DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
