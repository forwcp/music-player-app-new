import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_app/main.dart';

void main() {
  testWidgets('Music player loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicPlayerApp());
    await tester.pump();
    expect(find.text('Aura Music'), findsOneWidget);
  });
}
