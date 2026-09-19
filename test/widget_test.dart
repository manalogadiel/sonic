import 'package:flutter_test/flutter_test.dart';
import 'package:smart_volume_manager/main.dart';

void main() {
  testWidgets('renders the audio utility dashboard', (tester) async {
    await tester.pumpWidget(const SmartVolumeApp());

    expect(find.text('SONIC MANAGER'), findsOneWidget);
    expect(find.text('Audio overview'), findsOneWidget);
    expect(find.text('Start Optimization'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
  });

  testWidgets('navigates to settings', (tester) async {
    await tester.pumpWidget(const SmartVolumeApp());
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Audio preferences'), findsOneWidget);
    expect(find.text('Annoyance Prevention'), findsOneWidget);
  });
}
