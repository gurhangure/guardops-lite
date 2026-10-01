abstract final class LocationQueries {
  static const _countryFields = '''
    code
    name
    emoji
    capital
    currency
    continent { code name }
  ''';

  static const countries =
      '''
    query Countries {
      countries { $_countryFields }
    }
  ''';

  static const continents = '''
    query Continents {
      continents { code name }
    }
  ''';

  static const country =
      r'query Country($code: ID!) {'
      r'country(code: $code) {'
      '$_countryFields'
      '}}';
}
