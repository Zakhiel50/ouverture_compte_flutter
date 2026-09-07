import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/livret_a_provider.dart';
import '../services/manage-db.dart';
import '../theme/app_theme.dart';
import '../widgets/logout_button.dart';
import '../widgets/theme_toggle_button.dart';

class ProductItem {
  final String title;
  final String category;
  final String description;
  final String mainBadge;
  final String detail;
  final IconData icon;
  final bool isFeatured;

  const ProductItem({
    required this.title,
    required this.category,
    required this.description,
    required this.mainBadge,
    required this.detail,
    required this.icon,
    this.isFeatured = false,
  });
}

class ProductSelectionScreen extends ConsumerWidget {
  final VoidCallback? onSelectProduct;

  const ProductSelectionScreen({
    super.key,
    this.onSelectProduct,
  });

  static const List<ProductItem> products = [
    ProductItem(
      title: "Livret A",
      category: "Épargne Réglementée",
      description: "Épargne disponible à tout moment, 100% défiscalisée.",
      mainBadge: "3.0% net",
      detail: "Plafond : 22 950 €",
      icon: Icons.account_balance_wallet_rounded,
      isFeatured: true,
    ),
    ProductItem(
      title: "Livret d'Épargne Populaire",
      category: "Épargne Réserve",
      description: "Réservé aux personnes sous conditions de revenus.",
      mainBadge: "4.0% net",
      detail: "Plafond : 10 000 €",
      icon: Icons.savings_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "PEL",
      category: "Épargne Projet",
      description: "Préparez votre futur achat immobilier avec un taux garanti.",
      mainBadge: "2.25% brut",
      detail: "Plafond : 61 200 €",
      icon: Icons.home_work_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "Livret Jeune (3.0%)",
      category: "Épargne 12 - 25 ans",
      description: "Compte d'épargne idéal pour les jeunes actifs et étudiants.",
      mainBadge: "3.0% net",
      detail: "Plafond : 1 600 €",
      icon: Icons.school_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "Compte Etudiant Micro-Frais",
      category: "Compte & Carte",
      description: "Zéro frais de tenue de compte avec carte internationale.",
      mainBadge: "0 € / mois",
      detail: "Gestion 100% App Mobile",
      icon: Icons.credit_card_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "Compte Courant Pro",
      category: "Professionnels",
      description: "Pour les indépendants, freelances et petites entreprises.",
      mainBadge: "Offre Pro",
      detail: "Outils de facturation inclus",
      icon: Icons.business_center_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "Carte MasterCard Classic",
      category: "Moyen de Paiement",
      description: "Carte bancaire à débit immédiat ou différé.",
      mainBadge: "Internationale",
      detail: "Assurances voyages incluses",
      icon: Icons.payment_rounded,
      isFeatured: false,
    ),
    ProductItem(
      title: "Prêt Immobilier Taux Privilège",
      category: "Crédit & Emprunt",
      description: "Financement sur-mesure pour votre résidence principale.",
      mainBadge: "Taux Fixe",
      detail: "Étude personnalisée rapide",
      icon: Icons.real_estate_agent_rounded,
      isFeatured: false,
    ),
  ];

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
  );

  User? _getSafeUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = _getSafeUser();

    return Scaffold(
      appBar: AppBar(
        leading: const LogoutButton(),
        title: const Text("Offres & Livrets"),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: AppTheme.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Offres Bancaires & Épargne",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Sélectionnez le livret ou compte que vous souhaitez souscrire.",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Products Grid with StreamBuilder on Firestore BDD
            Expanded(
              child: currentUser == null
                  ? _buildProductsList(context, ref, isDark, [])
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: ManageDbService().streamUserRecord(currentUser.uid),
                      builder: (context, snapshot) {
                        List<Map<String, dynamic>> openedProducts = [];
                        if (snapshot.hasData && snapshot.data?.data() != null) {
                          final raw = snapshot.data!.data()!['produitsOuverts'];
                          if (raw is List) {
                            openedProducts = raw.map((item) {
                              if (item is Map) {
                                return Map<String, dynamic>.from(item);
                              }
                              return {
                                'nomProduit': item.toString(),
                                'soldeInitial': 0.0,
                                'dateOuverture': ''
                              };
                            }).toList();
                          }
                        }

                        return _buildProductsList(
                          context,
                          ref,
                          isDark,
                          openedProducts,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    List<Map<String, dynamic>> openedProducts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final openedInfo = _getOpenedInfo(product.title, openedProducts);
        return _buildProductCard(context, ref, product, isDark, openedInfo);
      },
    );
  }

  Map<String, dynamic>? _getOpenedInfo(
    String productTitle,
    List<Map<String, dynamic>> openedProducts,
  ) {
    final targetLower = productTitle.toLowerCase().trim();
    for (final item in openedProducts) {
      final name = (item['nomProduit'] ?? '').toString().toLowerCase().trim();
      if (name == targetLower) return item;
      if (targetLower == 'livret a' && name.contains('livret a')) return item;
      if (targetLower.contains('populaire') &&
          (name.contains('lep') || name.contains('populaire'))) {
        return item;
      }
      if (targetLower == 'pel' && name.contains('pel')) return item;
      if (targetLower.contains('jeune') && name.contains('jeune')) return item;
      if (targetLower.contains('etudiant') &&
          (name.contains('etudiant') || name.contains('étudiant'))) {
        return item;
      }
      if (targetLower.contains('pro') && name.contains('pro')) return item;
      if (targetLower.contains('mastercard') &&
          (name.contains('mastercard') || name.contains('visa'))) {
        return item;
      }
    }
    return null;
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    ProductItem product,
    bool isDark,
    Map<String, dynamic>? openedInfo,
  ) {
    final theme = Theme.of(context);
    final bool isOpened = openedInfo != null;

    final double solde = (openedInfo?['soldeInitial'] as num?)?.toDouble() ?? 0.0;
    final String dateOuverture = (openedInfo?['dateOuverture'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpened
              ? AppTheme.success
              : (product.isFeatured
                  ? AppTheme.accent
                  : (isDark ? AppTheme.darkBorder : AppTheme.border)),
          width: isOpened || product.isFeatured ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(livretAProvider.notifier).selectProduct(product.title);
            if (onSelectProduct != null) {
              onSelectProduct!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Icon, Category & Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isOpened
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : (product.isFeatured
                                ? AppTheme.accentGradient
                                : LinearGradient(
                                    colors: isDark
                                        ? [AppTheme.darkCard, AppTheme.darkSurface]
                                        : [
                                            const Color(0xFFF1F5F9),
                                            const Color(0xFFE2E8F0)
                                          ],
                                  )),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isOpened ? Icons.check_circle_rounded : product.icon,
                        color: (isOpened || product.isFeatured)
                            ? Colors.white
                            : AppTheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              if (isOpened)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "DÉJÀ OUVERT",
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (product.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Populaire",
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                  ),
                ),

                // Block d'informations BDD si le produit est déjà ouvert
                if (isOpened) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_rounded,
                              size: 16,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Solde : ${_currencyFormat.format(solde)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        if (dateOuverture.isNotEmpty)
                          Text(
                            "Ouvert le : $dateOuverture",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Bottom row with Badge details and Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isOpened
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpened ? "Actif" : product.mainBadge,
                              style: TextStyle(
                                color: isOpened ? AppTheme.success : AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOpened ? "Déjà ouvert" : "Ouvrir",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOpened
                                ? AppTheme.textSecondary
                                : (isDark ? AppTheme.accent : AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isOpened
                              ? Icons.lock_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: isOpened
                              ? AppTheme.textSecondary
                              : (isDark ? AppTheme.accent : AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
