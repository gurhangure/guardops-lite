sealed class OperationsEvent {
  const OperationsEvent();
}

class OperationsLoadRequested extends OperationsEvent {
  const OperationsLoadRequested();
}

class OperationsSearchChanged extends OperationsEvent {
  const OperationsSearchChanged(this.query);
  final String query;
}

class OperationsContinentChanged extends OperationsEvent {
  const OperationsContinentChanged(this.code);
  final String code;
}
