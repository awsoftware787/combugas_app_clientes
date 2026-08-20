import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/external_urls.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

final privacyNoticeLauncherProvider = Provider<Future<bool> Function()>(
  (_) =>
      () => launchUrl(
        ExternalUrls.privacidad,
        mode: LaunchMode.externalApplication,
      ),
);

class PedidoDrawer extends ConsumerWidget {
  const PedidoDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    return Drawer(
      backgroundColor: AppColors.menuBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 20,
                      ),
                      color: AppColors.menuBackgroundDark,
                      child: Column(
                        children: [
                          Image.asset(
                            AppAssets.profileImage,
                            width: 88,
                            height: 88,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            session?.nombreUsuario ?? 'Cliente',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _item(context, Icons.home, 'Pedido', '/pedido'),
                    _item(context, Icons.person, 'Perfil', '/perfil'),
                    _item(
                      context,
                      Icons.local_gas_station,
                      'Carburaciones',
                      '/carburaciones',
                    ),
                    _item(
                      context,
                      Icons.location_on,
                      'Mis direcciones',
                      '/direcciones',
                    ),
                    _item(
                      context,
                      Icons.receipt_long,
                      'Mis Pedidos',
                      '/mis-pedidos',
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Aviso de privacidad',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final opened =
                            await ref.read(privacyNoticeLauncherProvider)();
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No fue posible abrir el aviso.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/productos');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(label, style: const TextStyle(color: Colors.white)),
    onTap: () {
      final currentRoute = GoRouterState.of(context).uri.path;
      Navigator.of(context).pop();
      if (currentRoute == route) return;
      context.go(route);
    },
  );
}
