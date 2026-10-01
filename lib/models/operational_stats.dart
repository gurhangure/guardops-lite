/// Local demo values, never measurements from real devices.
class OperationalStats {
  const OperationalStats({this.online = 0, this.warning = 0, this.offline = 0});

  final int online;
  final int warning;
  final int offline;
  int get total => online + warning + offline;
}
