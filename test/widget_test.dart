import 'package:flutter_test/flutter_test.dart';
import 'package:exam_sprint/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ExamSprintApp());
  });
}
