import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_theme.dart';

class LogoutButton extends StatelessWidget {
  final Color? color;
  final bool showConfirmDialog;

  const LogoutButton({
    super.key,
    this.color,
    this.showConfirmDialog = true,
  });

  Future<void> _handleSignOut(BuildContext context) async {
    if (showConfirmDialog) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: AppTheme.error),
                SizedBox(width: 10),
                Text('Déconnexion'),
              ],
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Se déconnecter',
      child: IconButton(
        icon: Icon(
          Icons.logout_rounded,
          color: color ?? Theme.of(context).colorScheme.error,
        ),
        onPressed: () => _handleSignOut(context),
      ),
    );
  }
}
