import 'package:get/get.dart';

import '../../features/home/controllers/home_controller.dart';
import '../../features/home/screens/scanner_home_page.dart';
import 'app_routes.dart';

abstract class AppPages {
  const AppPages._();

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.home,
      page: () => const ScannerHomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(HomeController.new);
      }),
    ),
  ];
}
