import 'package:mp_chart/mp/dashed/image_store.dart';

class ChartState {
  Future<void> initialize() async {
    var imageStore = ImageStore();

    await imageStore.initialize();
  }
}
