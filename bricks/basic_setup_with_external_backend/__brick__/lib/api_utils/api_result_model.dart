abstract class ApiResult<T, E> {
  bool get isDataPresent;
  bool get isErrorPresent;

  T? get getData;

  E? get getErrorMessage;
}

class ApiData<T, E> extends ApiResult<T, E> {
  ApiData({required this.data});
  final T data;

  @override
  bool get isDataPresent => true;

  @override
  bool get isErrorPresent => false;

  @override
  T get getData => data;

  @override
  E? get getErrorMessage => null;
}

class ApiError<T, E> extends ApiResult<T, E> {
  ApiError({required this.error});
  final E error;

  @override
  bool get isDataPresent => false;

  @override
  bool get isErrorPresent => true;

  @override
  T? get getData => null;

  @override
  E? get getErrorMessage => error;
}
