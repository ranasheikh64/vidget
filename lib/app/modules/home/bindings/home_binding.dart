import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/services/extractor_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ExtractorService>(() => ExtractorService());
  }
}
