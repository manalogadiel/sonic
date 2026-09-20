import 'package:flutter_test/flutter_test.dart';
import 'package:sonic_mixer/main.dart';

void main() {
  testWidgets('Sonic Mixer smoke test - displays title and start button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SonicMixerApp());

    // Verify that the title and buttons are present
    expect(find.text('Sonic Mixer'), findsOneWidget);
    expect(find.text('START AUDIO OPTIMIZATION'), findsOneWidget);
    expect(find.text('Master Output Volume'), findsOneWidget);
    expect(find.text('100% [OPTIMAL]'), findsOneWidget);
  });
}
