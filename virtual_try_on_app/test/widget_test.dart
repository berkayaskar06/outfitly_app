import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:virtual_try_on_app/app/app.dart';

void main() {
  testWidgets('renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VirtualTryOnApp()));

    expect(find.textContaining('Outfitly'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });
}
