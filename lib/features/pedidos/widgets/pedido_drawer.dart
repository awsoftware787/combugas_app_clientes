import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/external_urls.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_version_text.dart';
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
    if (session == null) {
      return Drawer(
        width: MediaQuery.sizeOf(context).width * 0.60,
        backgroundColor: AppColors.menuBackground,
        child: _PublicDrawerContent(
          onOpenPrivacy: () => _openPrivacy(context, ref),
        ),
      );
    }
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.60,
      backgroundColor: AppColors.menuBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              color: AppColors.menuBackgroundDark,
              child: Column(
                children: [
                  Image.asset(AppAssets.profileImage, width: 92, height: 92),
                  const SizedBox(height: 8),
                  Text(
                    session.nombreUsuario,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder:
                    (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _item(context, Icons.home, 'Pedido', '/pedido'),
                              _item(
                                context,
                                Icons.receipt_long,
                                'Mis pedidos',
                                '/mis-pedidos',
                              ),
                              _item(
                                context,
                                Icons.location_on,
                                'Mis direcciones',
                                '/direcciones',
                              ),
                              _item(context, Icons.person, 'Perfil', '/perfil'),
                              _divider(),
                              _item(
                                context,
                                Icons.local_gas_station,
                                'Carburaciones',
                                '/carburaciones',
                              ),
                              _AuthenticatedDrawerItem(
                                key: const ValueKey('drawer-item-privacy'),
                                icon: Icons.privacy_tip,
                                label: 'Aviso de privacidad',
                                onTap: () => _openPrivacy(context, ref),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: AppVersionText(),
                              ),
                              _divider(),
                              _AuthenticatedDrawerItem(
                                key: const ValueKey('drawer-logout'),
                                icon: Icons.logout,
                                label: 'Cerrar sesión',
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .logout();
                                  if (context.mounted) {
                                    context.go('/productos');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacy(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final opened = await ref.read(privacyNoticeLauncherProvider)();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el aviso.')),
      );
    }
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final currentRoute = GoRouter.maybeOf(context)?.state.uri.path ?? '';
    final selected =
        currentRoute == route || currentRoute.startsWith('$route/');
    return _AuthenticatedDrawerItem(
      key: ValueKey('drawer-item-$route'),
      icon: icon,
      label: label,
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        if (currentRoute == route) return;
        context.go(route);
      },
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(
      height: 17,
      thickness: 1,
      color: AppColors.white.withValues(alpha: 0.16),
    ),
  );
}

class _AuthenticatedDrawerItem extends StatelessWidget {
  const _AuthenticatedDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color:
            selected
                ? AppColors.white.withValues(alpha: 0.09)
                : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: AppColors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PublicDrawerContent extends StatelessWidget {
  const _PublicDrawerContent({required this.onOpenPrivacy});

  final Future<void> Function() onOpenPrivacy;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          color: AppColors.primary,
          child: Image.asset(AppAssets.logo, height: 64, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        _PublicDrawerItem(
          icon: Icons.local_gas_station,
          label: 'Carburaciones',
          onTap: () => _openRoute(context, '/carburaciones'),
        ),
        _PublicDrawerItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Aviso de privacidad',
          onTap: onOpenPrivacy,
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: AppVersionText(),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              key: const ValueKey('public-drawer-login'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => _openRoute(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión'),
            ),
          ),
        ),
      ],
    ),
  );

  void _openRoute(BuildContext context, String route) {
    final currentRoute = GoRouterState.of(context).uri.path;
    Navigator.of(context).pop();
    if (currentRoute == route) return;
    context.push(route);
  }
}

class _PublicDrawerItem extends StatelessWidget {
  const _PublicDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.white),
    title: Text(
      label,
      style: const TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    onTap: onTap,
  );
}
