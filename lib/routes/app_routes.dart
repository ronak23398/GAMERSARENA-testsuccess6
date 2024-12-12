import 'package:gamers_gram/modules/arena/bindings/arena_bindings.dart';
import 'package:gamers_gram/modules/arena/view/arena_view.dart';
import 'package:gamers_gram/modules/auth/bindings/auth_bindings.dart';
import 'package:gamers_gram/modules/auth/view/login_view.dart';
import 'package:gamers_gram/modules/auth/view/signup_view.dart';
import 'package:gamers_gram/modules/chat/bindings/chat_bindings.dart';
import 'package:gamers_gram/modules/home/bindings/home_bindings.dart';
import 'package:gamers_gram/modules/home/view/home_view.dart';
import 'package:gamers_gram/modules/marketplace/bindings/market_bindings.dart';
import 'package:gamers_gram/modules/marketplace/view/marketplace_view.dart';
import 'package:gamers_gram/modules/navigation/navigation_view.dart';
import 'package:gamers_gram/modules/profile/bindings/profile_bindings.dart';
import 'package:gamers_gram/modules/profile/bindings/team_bindings.dart';
import 'package:gamers_gram/modules/profile/view/team_view.dart';
import 'package:gamers_gram/modules/tournamnets_page/bindings/tournament_bindings.dart';
import 'package:gamers_gram/modules/tournamnets_page/view/tournament_view.dart';
import 'package:gamers_gram/modules/wallet/bindings/wallet_bindings.dart';
import 'package:gamers_gram/modules/wallet/view/wallet_view.dart';
import 'package:gamers_gram/routes/auth_guard.dart';
import 'package:get/get.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: '/login',
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/signup',
      page: () => SignUpView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/home',
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: '/wallet',
      page: () => const WalletView(),
      binding: WalletBindings(),
    ),
    GetPage(
      name: '/market',
      page: () => const MarketView(),
      binding: MarketBindings(),
    ),
    GetPage(
      name: '/arena',
      page: () => const ArenaView(),
      binding: ArenaBindings(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: '/tournament',
      page: () => const TournamentView(),
      binding: TournamentBinding(),
    ),
    GetPage(
      name: '/teamManagement',
      page: () => TeamManagementPage(),
      binding: TeamBindings(),
    ),
    GetPage(
      name: '/mainpage',
      page: () => const MainNavigationScreen(),
      // Add bindings for all modules used in navigation
      bindings: [
        HomeBinding(),
        ArenaBindings(),
        MarketBindings(),
        ChatBinding(),
        ProfileBindings(),
        TournamentBinding(),
        TeamBindings()
      ],
      middlewares: [AuthGuard()], // Add auth guard if needed
    ),
  ];
}
