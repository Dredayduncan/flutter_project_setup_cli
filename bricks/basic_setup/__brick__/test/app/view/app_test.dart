import 'package:flutter_test/flutter_test.dart';
import 'package:{{project-name}}/app/app.dart';
import 'package:{{project-name}}/home/home_screen.dart';

void main() {
  group('App', () {
    testWidgets('renders HomeScreen', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
