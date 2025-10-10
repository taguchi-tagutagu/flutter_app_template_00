import 'package:mockito/mockito.dart';

class Listener<T> extends Mock {
  void call(T? prev, T? value);
}
