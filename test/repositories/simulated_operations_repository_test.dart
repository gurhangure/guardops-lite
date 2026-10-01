import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/repositories/simulated_operations_repository.dart';

import '../helpers/location_fixtures.dart';

void main() {
  const repository = SimulatedOperationsRepository();
  test('empty input produces zero devices', () {
    expect(repository.summarize([]).total, 0);
  });
  test('counts are repeatable, order independent, and add up', () {
    final total = repository.summarize([germany, japan]);
    final reversed = repository.summarize([japan, germany]);
    expect(total.online, reversed.online);
    expect(total.warning, reversed.warning);
    expect(total.offline, reversed.offline);
    expect(
      total.total,
      repository.summarize([germany]).total +
          repository.summarize([japan]).total,
    );
    expect(total.total, total.online + total.warning + total.offline);
    expect(total.online, greaterThan(0));
  });
}
