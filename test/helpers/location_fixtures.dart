import 'package:guardops_lite/models/continent_model.dart';
import 'package:guardops_lite/models/location_model.dart';

const europe = ContinentModel(code: 'EU', name: 'Europe');
const asia = ContinentModel(code: 'AS', name: 'Asia');
const germany = LocationModel(
  code: 'DE',
  name: 'Germany',
  emoji: '🇩🇪',
  continent: europe,
);
const japan = LocationModel(
  code: 'JP',
  name: 'Japan',
  emoji: '🇯🇵',
  continent: asia,
);
