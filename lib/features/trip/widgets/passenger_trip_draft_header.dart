import 'package:flutter/material.dart';

import '../../../core/network/places_autocomplete_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'trip_request_shell_widgets.dart';

/// Fase implícita de búsqueda (origen hasta confirmar; luego destino).
enum PassengerDraftSearchRole { origin, destination }

/// Forzar búsqueda / GPS / guardados hacia origen o destino al editar con ambos puntos ya definidos.
enum PassengerDraftEditTarget { none, origin, destination }

/// Cabecera del borrador: primero solo origen; tras [originConfirmed], origen fijo + búsqueda de destino.
/// Iconos GPS y guardados van junto al campo de búsqueda (sin fila inferior de acciones rápidas).
class PassengerTripDraftHeader extends StatelessWidget {
  const PassengerTripDraftHeader({
    super.key,
    required this.originConfirmed,
    required this.originDisplayLine,
    required this.destinationDisplayLine,
    required this.hasDestinationSet,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.searchFieldHint,
    required this.showSuggestionsPanel,
    required this.loadingSuggestions,
    required this.suggestions,
    required this.onPickSuggestion,
    required this.recentPlaces,
    required this.onPickRecent,
    required this.recentSectionTitle,
    required this.onMyLocationIconTap,
    required this.onSavedIconTap,
    required this.myLocationTooltip,
    required this.savedPlacesTooltip,
    required this.showLocationSearchChrome,
    required this.highlightOrigin,
    required this.highlightDestination,
    required this.searchPriorityMode,
    this.onEditOrigin,
    this.onEditDestination,
    required this.editStopLabel,
    this.onSaveOriginToFavorites,
    this.saveOriginFavoritesTooltip,
    this.onSaveDestinationToFavorites,
    this.saveDestinationFavoritesTooltip,
  });

  final bool originConfirmed;
  final String originDisplayLine;
  final String destinationDisplayLine;
  final bool hasDestinationSet;

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final String searchFieldHint;

  final bool showSuggestionsPanel;
  final bool loadingSuggestions;
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onPickSuggestion;

  final List<TripRecentPlaceItem> recentPlaces;
  final ValueChanged<TripRecentPlaceItem> onPickRecent;
  final String recentSectionTitle;

  final VoidCallback onMyLocationIconTap;
  final VoidCallback onSavedIconTap;
  final String myLocationTooltip;
  final String savedPlacesTooltip;

  /// Muestra fila buscador + GPS + guardados (se oculta con origen y destino listos hasta pulsar Editar).
  final bool showLocationSearchChrome;
  final bool highlightOrigin;
  final bool highlightDestination;
  final bool searchPriorityMode;
  final VoidCallback? onEditOrigin;
  final VoidCallback? onEditDestination;
  final String editStopLabel;
  final VoidCallback? onSaveOriginToFavorites;
  final String? saveOriginFavoritesTooltip;
  final VoidCallback? onSaveDestinationToFavorites;
  final String? saveDestinationFavoritesTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!searchPriorityMode) ...[
            // Bloque visual unificado: SIEMPRE mostramos `_PinnedRow` para origen
            // y la tarjeta para destino, también mientras se está apuntando con el
            // pin (la dirección apuntada llega como `originDisplayLine` /
            // `destinationDisplayLine`). Al confirmar no hay cambio de layout.
            _PinnedRow(
              label: l10n.tripOrigin,
              value: originDisplayLine,
              icon: Icons.place_rounded,
              dotColor: const Color(0xFFF9AB00),
              highlighted: highlightOrigin,
              // Solo permitimos guardar/editar tras confirmar el origen.
              onSaveToFavorites: originConfirmed
                  ? onSaveOriginToFavorites
                  : null,
              saveToFavoritesTooltip: saveOriginFavoritesTooltip,
              onEdit: originConfirmed ? onEditOrigin : null,
              editTooltip: editStopLabel,
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedContainer(
              duration: AppMotion.draftSearchChromeReveal,
              curve: AppMotion.standard,
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: highlightDestination
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : AppColors.primary.withValues(alpha: 0.14),
                  width: highlightDestination ? 1.6 : 1,
                ),
                boxShadow: highlightDestination
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF111111),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PhaseLabel(text: l10n.tripWhereTo.toUpperCase()),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          hasDestinationSet
                              ? destinationDisplayLine
                              : (destinationDisplayLine.isNotEmpty &&
                                        destinationDisplayLine !=
                                            l10n.tripTapMapDestination
                                    ? destinationDisplayLine
                                    : l10n.tripTapMapDestination),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: hasDestinationSet
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hasDestinationSet
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasDestinationSet && onSaveDestinationToFavorites != null)
                    IconButton(
                      tooltip: saveDestinationFavoritesTooltip ?? '',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        // bookmark_add_outlined: contorno con "+" para "guardar a favoritos".
                        // Antes: add_location_alt_rounded (pin de localización; se confundía con el marcador).
                        Icons.bookmark_add_outlined,
                        size: 22,
                        color: AppColors.primary.withValues(alpha: 0.95),
                      ),
                      onPressed: onSaveDestinationToFavorites,
                    ),
                  if (onEditDestination != null &&
                      (hasDestinationSet || !showLocationSearchChrome))
                    IconButton(
                      tooltip: editStopLabel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 22,
                        color: AppColors.primary.withValues(alpha: 0.95),
                      ),
                      onPressed: onEditDestination,
                    ),
                ],
              ),
            ),
          ],
          _DraftSearchChromeSlot(
            visible: showLocationSearchChrome,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: searchController,
                        builder: (context, _) {
                          return TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: onSearchChanged,
                            textInputAction: TextInputAction.search,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surface,
                              hintText: searchFieldHint,
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                maxWidth: 40,
                                minHeight: 40,
                                maxHeight: 40,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.primary.withValues(alpha: 0.9),
                                size: 22,
                              ),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: MaterialLocalizations.of(
                                        context,
                                      ).clearButtonTooltip,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: AppColors.textSecondary,
                                        size: AppIconSizes.md,
                                      ),
                                      onPressed: () {
                                        searchController.clear();
                                        onSearchChanged('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.fromLTRB(
                                6,
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.border.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Tamaño 42x42 para uniformar con la altura efectiva del
                    // search field (~40-44 px con `contentPadding` vertical
                    // = `AppSpacing.md`). Antes: 46x46 (sobresalían).
                    Tooltip(
                      message: myLocationTooltip,
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onMyLocationIconTap,
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: savedPlacesTooltip,
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onSavedIconTap,
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (showSuggestionsPanel) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Material(
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      color: AppColors.surface,
                      clipBehavior: Clip.antiAlias,
                      child: loadingSuggestions
                          ? const Center(
                              child: SizedBox(
                                width: AppSizes.progressSm,
                                height: AppSizes.progressSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : suggestions.isNotEmpty
                          ? ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              itemCount: suggestions.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: AppColors.border.withValues(alpha: 0.25),
                              ),
                              itemBuilder: (context, i) {
                                final s = suggestions[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.place_outlined,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.85,
                                    ),
                                    size: AppIconSizes.lg,
                                  ),
                                  title: Text(
                                    s.mainText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: s.secondaryText.isEmpty
                                      ? null
                                      : Text(
                                          s.secondaryText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () => onPickSuggestion(s),
                                );
                              },
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              children: [
                                Text(
                                  recentSectionTitle,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (recentPlaces.isEmpty)
                                  Text(
                                    l10n.tripDraftNoRecentPlaces,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  ...recentPlaces.map(
                                    (p) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.history_rounded,
                                        size: AppIconSizes.lg,
                                        color: AppColors.textSecondary,
                                      ),
                                      title: Text(
                                        p.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle:
                                          p.subtitle == null ||
                                              p.subtitle!.isEmpty
                                          ? null
                                          : Text(
                                              p.subtitle!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      onTap: () => onPickRecent(p),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expansión / colapso del bloque buscador con altura + opacidad + leve desliz (misma curva).
class _DraftSearchChromeSlot extends StatefulWidget {
  const _DraftSearchChromeSlot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_DraftSearchChromeSlot> createState() => _DraftSearchChromeSlotState();
}

class _DraftSearchChromeSlotState extends State<_DraftSearchChromeSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.draftSearchChromeReveal,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.visible) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_DraftSearchChromeSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _curved,
        axis: Axis.vertical,
        alignment: Alignment.topLeft,
        child: FadeTransition(
          opacity: _curved,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - _curved.value)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _PinnedRow extends StatelessWidget {
  const _PinnedRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.dotColor,
    required this.highlighted,
    this.onSaveToFavorites,
    this.saveToFavoritesTooltip,
    this.onEdit,
    this.editTooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color dotColor;
  final bool highlighted;
  final VoidCallback? onSaveToFavorites;
  final String? saveToFavoritesTooltip;
  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.draftSearchChromeReveal,
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: highlighted
              ? dotColor.withValues(alpha: 0.9)
              : AppColors.border.withValues(alpha: 0.35),
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: dotColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
          if (onSaveToFavorites != null) ...[
            IconButton(
              tooltip: saveToFavoritesTooltip ?? '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                // bookmark_add_outlined: contorno con "+" para "guardar a favoritos".
                // Antes: add_location_alt_rounded (pin; se confundía con el marcador del mapa).
                Icons.bookmark_add_outlined,
                size: 22,
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
              onPressed: onSaveToFavorites,
            ),
          ],
          if (onEdit != null) ...[
            IconButton(
              tooltip: editTooltip ?? '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }
}
