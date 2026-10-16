import 'package:integration_test/integration_test.dart';
import '../test/live_teacher_flow_test.dart' as flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  flow.main();
}
