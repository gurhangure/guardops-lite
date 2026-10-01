import '../models/location_model.dart';
import '../models/operational_stats.dart';

/// Repeatable mock counts based on country codes; no network or device access.
class SimulatedOperationsRepository {
  const SimulatedOperationsRepository();

  OperationalStats summarize(Iterable<LocationModel> countries) {
    var online = 0;
    var warning = 0;
    var offline = 0;
    for (final country in countries) {
      final seed = country.code.codeUnits.fold(0, (sum, unit) => sum + unit);
      online += 8 + seed % 13;
      warning += seed % 3;
      offline += seed % 2;
    }
    return OperationalStats(online: online, warning: warning, offline: offline);
  }
}
