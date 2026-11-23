import 'package:flutter/material.dart';

import '../../../core/network/places_autocomplete_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'trip_request_shell_widgets.dart';

enum PassengerDraftSearchRole { origin, destination }

enum PassengerDraftEditTarget { none, origin, destination }

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
    this.attractDestinationTap = false,
    this.settledCompact = false,
    required this.searchPriorityMode,
    required this.searchRole,
    this.searchCollapseToken = 0,
    this.searchExpandToken = 0,
    this.onOpenSearchOrigin,
    this.onOpenSearchDestination,
    this.onSearchOnMap,
    this.searchOnMapLabel = '',
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

  final bool showLocationSearchChrome;
  final bool highlightOrigin;
  final bool highlightDestination;

  final bool attractDestinationTap;

  final bool settledCompact;
  final bool searchPriorityMode;

  final PassengerDraftSearchRole searchRole;

  final int searchCollapseToken;

  final int searchExpandToken;

  final VoidCallback? onOpenSearchOrigin;
  final VoidCallback? onOpenSearchDestination;
  final VoidCallback? onSearchOnMap;
  final String searchOnMapLabel;
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
            if (settledCompact)
              _SettledStopsCard(
                originLabel: l10n.tripOrigin,
                originValue: originDisplayLine,
                destinationLabel: l10n.tripDestination,
                destinationValue: destinationDisplayLine,
                onOpenSearchOrigin: onOpenSearchOrigin,
                onOpenSearchDestination: onOpenSearchDestination,
                openSearchTooltip: searchFieldHint,
                onEditOrigin: onEditOrigin,
                onEditDestination: onEditDestination,
                editTooltip: editStopLabel,
                onSaveOrigin: onSaveOriginToFavorites,
                onSaveDestination: onSaveDestinationToFavorites,
                saveOriginTooltip: saveOriginFavoritesTooltip,
                saveDestinationTooltip: saveDestinationFavoritesTooltip,
              )
            else
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E).withValues(alpha: 0.86),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PinnedRow(
                    label: l10n.tripOrigin,
                    value: originDisplayLine,
                    icon: Icons.place_rounded,
                    dotColor: AppColors.primary,
                    highlighted: highlightOrigin,
                    onSaveToFavorites: originConfirmed
                        ? onSaveOriginToFavorites
                        : null,
                    saveToFavoritesTooltip: saveOriginFavoritesTooltip,
                    onOpenSearch: onOpenSearchOrigin,
                    openSearchTooltip: searchFieldHint,
                    onEdit: originConfirmed ? onEditOrigin : null,
                    editTooltip: editStopLabel,
                  ),
                  _DestinationSectionCard(
                    attract: attractDestinationTap,
                    highlighted: highlightDestination,
                    onTap: onOpenSearchDestination,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1A1A1A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Tooltip(
                            message: onOpenSearchDestination != null
                                ? searchFieldHint
                                : '',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tripWhereTo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.05,
                                  ),
                                ),
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: hasDestinationSet
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: hasDestinationSet
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFF6A6A6A),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasDestinationSet &&
                            onSaveDestinationToFavorites != null)
                          IconButton(
                            tooltip: saveDestinationFavoritesTooltip ?? '',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: const Icon(
                              Icons.bookmark_add_outlined,
                              size: 22,
                              color: Color(0xFF1A1A1A),
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
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: Color(0xFF1A1A1A),
                            ),
                            onPressed: onEditDestination,
                          ),
                        if (!(hasDestinationSet &&
                                onSaveDestinationToFavorites != null) &&
                            !(onEditDestination != null &&
                                (hasDestinationSet ||
                                    !showLocationSearchChrome)))
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8A8A8A),
                            size: 26,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _DraftSearchChromeSlot(
              visible: showLocationSearchChrome,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _CollapsibleDraftSearchRow(
                    searchRole: searchRole,
                    searchCollapseToken: searchCollapseToken,
                    searchExpandToken: searchExpandToken,
                    searchController: searchController,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: onSearchChanged,
                    searchFieldHint: searchFieldHint,
                    onMyLocationIconTap: onMyLocationIconTap,
                    onSavedIconTap: onSavedIconTap,
                    myLocationTooltip: myLocationTooltip,
                    savedPlacesTooltip: savedPlacesTooltip,
                    onSearchOnMap: onSearchOnMap,
                    searchOnMapLabel: searchOnMapLabel,
                  ),
                  if (showSuggestionsPanel) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Material(

                        elevation: 12,
                        shadowColor: Colors.black.withValues(alpha: 0.28),
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
                                  color: AppColors.border.withValues(
                                    alpha: 0.25,
                                  ),
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (recentPlaces.isEmpty)
                                    Text(
                                      l10n.tripDraftNoRecentPlaces,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
          ),
        ],
      ),
    );
  }
}

class _CollapsibleDraftSearchRow extends StatefulWidget {
  const _CollapsibleDraftSearchRow({
    required this.searchRole,
    required this.searchCollapseToken,
    required this.searchExpandToken,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.searchFieldHint,
    required this.onMyLocationIconTap,
    required this.onSavedIconTap,
    required this.myLocationTooltip,
    required this.savedPlacesTooltip,
    this.onSearchOnMap,
    this.searchOnMapLabel = '',
  });

  final PassengerDraftSearchRole searchRole;
  final int searchCollapseToken;
  final int searchExpandToken;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final String searchFieldHint;
  final VoidCallback onMyLocationIconTap;
  final VoidCallback onSavedIconTap;
  final String myLocationTooltip;
  final String savedPlacesTooltip;
  final VoidCallback? onSearchOnMap;
  final String searchOnMapLabel;

  @override
  State<_CollapsibleDraftSearchRow> createState() =>
      _CollapsibleDraftSearchRowState();
}

class _CollapsibleDraftSearchRowState extends State<_CollapsibleDraftSearchRow>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _awaitingFocus = false;
  late final AnimationController _appearController;
  late final CurvedAnimation _appearCurved;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.addListener(_onFocusChanged);
    _appearController = AnimationController(
      vsync: this,
      duration: AppMotion.draftSearchChromeReveal,
    );
    _appearCurved = CurvedAnimation(
      parent: _appearController,
      curve: AppMotion.standard,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.searchExpandToken > 0) {
      _expanded = true;
      _appearController.value = 1;
      _awaitingFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_expanded) return;
        widget.searchFocusNode.requestFocus();
        _awaitingFocus = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _CollapsibleDraftSearchRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchFocusNode != widget.searchFocusNode) {
      oldWidget.searchFocusNode.removeListener(_onFocusChanged);
      widget.searchFocusNode.addListener(_onFocusChanged);
    }
    final expandRequested =
        oldWidget.searchExpandToken != widget.searchExpandToken;
    if (expandRequested) {
      _expand();
      return;
    }
    if (oldWidget.searchCollapseToken != widget.searchCollapseToken) {
      _collapse(clearText: true, unfocus: true);
    }
  }

  @override
  void dispose() {
    widget.searchFocusNode.removeListener(_onFocusChanged);
    _appearCurved.dispose();
    _appearController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || _awaitingFocus) return;
    if (!widget.searchFocusNode.hasFocus && _expanded) {
      _collapse(clearText: true, unfocus: false);
    }
  }

  void _collapse({required bool clearText, required bool unfocus}) {
    final wasExpanded = _expanded;
    if (wasExpanded) {
      _appearController.reverse().whenComplete(() {
        if (!mounted) return;
        if (_appearController.value <= 0) {
          setState(() => _expanded = false);
        }
      });
    }
    if (unfocus && widget.searchFocusNode.hasFocus) {
      widget.searchFocusNode.unfocus();
    }
    if (clearText && widget.searchController.text.isNotEmpty) {
      widget.searchController.clear();
      widget.onSearchChanged('');
    }
  }

  void _expand() {
    final alreadyVisible = _expanded && _appearController.value >= 1;
    _awaitingFocus = true;

    _expanded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_expanded) return;
      if (!alreadyVisible && _appearController.value < 1) {
        _appearController.value = 1;
      }
      widget.searchFocusNode.requestFocus();
      _awaitingFocus = false;
    });
  }

  Widget _circleAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(

        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return AnimatedBuilder(
      animation: widget.searchController,
      builder: (context, _) {
        return TextField(
          controller: widget.searchController,
          focusNode: widget.searchFocusNode,
          onChanged: widget.onSearchChanged,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            hintText: widget.searchFieldHint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
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
            suffixIcon: widget.searchController.text.isNotEmpty
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
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                  )
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: AppIconSizes.md,
                    ),
                    onPressed: () => _collapse(clearText: true, unfocus: true),
                  ),
            contentPadding: const EdgeInsets.fromLTRB(
              6,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, _) {
        final showFieldNow = _expanded || _appearController.value > 0;
        final reveal = _expanded && _appearController.value == 0
            ? const AlwaysStoppedAnimation<double>(1)
            : _appearCurved;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!showFieldNow)
              Align(
                alignment: Alignment.centerRight,
                child: _circleAction(
                  tooltip: widget.myLocationTooltip,
                  icon: Icons.my_location_rounded,
                  onTap: widget.onMyLocationIconTap,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: reveal,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(reveal),
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: _buildSearchField(theme),
                        ),
                      ),
                    ),
                  ),
                  _circleAction(
                    tooltip: widget.myLocationTooltip,
                    icon: Icons.my_location_rounded,
                    onTap: widget.onMyLocationIconTap,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _circleAction(
                    tooltip: widget.savedPlacesTooltip,
                    icon: Icons.bookmark_rounded,
                    onTap: widget.onSavedIconTap,
                  ),
                ],
              ),
            if (showFieldNow && widget.onSearchOnMap != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _SearchOnMapAction(
                label: widget.searchOnMapLabel,
                onTap: widget.onSearchOnMap!,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SearchOnMapAction extends StatelessWidget {
  const _SearchOnMapAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _DestinationSectionCard extends StatefulWidget {
  const _DestinationSectionCard({
    required this.attract,
    required this.highlighted,
    required this.onTap,
    required this.child,
  });

  final bool attract;
  final bool highlighted;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_DestinationSectionCard> createState() =>
      _DestinationSectionCardState();
}

class _DestinationSectionCardState extends State<_DestinationSectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.attract) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _DestinationSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attract == oldWidget.attract) return;
    if (widget.attract) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = widget.attract
            ? Curves.easeInOut.transform(_pulse.value)
            : 0.0;
        final borderColor = widget.attract
            ? Color.lerp(const Color(0xFFE2B100), const Color(0xFFFFE14A), t)!
            : widget.highlighted
            ? const Color(0xFFE2B100)
            : const Color(0xFFF0D56A);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.zero,
            splashColor: const Color(0xFFFFD600).withValues(alpha: 0.18),
            highlightColor: const Color(0xFFFFD600).withValues(alpha: 0.08),
            child: Ink(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3C4).withValues(alpha: 0.9),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: borderColor,
                  width: widget.highlighted && !widget.attract ? 1.6 : 1.4,
                ),
                boxShadow: widget.attract
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.12 + (0.28 * t),
                          ),
                          blurRadius: 12 + (10 * t),
                          spreadRadius: 0.4,
                        ),
                      ]
                    : widget.highlighted
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                    child: child,
                  ),
                  if (widget.attract)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.4 + (2.6 * t), -0.2),
                              end: Alignment(-0.2 + (2.6 * t), 0.2),
                              colors: [
                                const Color(0x00F9AB00),
                                AppColors.primary.withValues(alpha: 0.16),
                                const Color(0x00F9AB00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SettledStopsCard extends StatelessWidget {
  const _SettledStopsCard({
    required this.originLabel,
    required this.originValue,
    required this.destinationLabel,
    required this.destinationValue,
    required this.openSearchTooltip,
    required this.editTooltip,
    this.onOpenSearchOrigin,
    this.onOpenSearchDestination,
    this.onEditOrigin,
    this.onEditDestination,
    this.onSaveOrigin,
    this.onSaveDestination,
    this.saveOriginTooltip,
    this.saveDestinationTooltip,
  });

  final String originLabel;
  final String originValue;
  final String destinationLabel;
  final String destinationValue;
  final String openSearchTooltip;
  final String editTooltip;
  final VoidCallback? onOpenSearchOrigin;
  final VoidCallback? onOpenSearchDestination;
  final VoidCallback? onEditOrigin;
  final VoidCallback? onEditDestination;
  final VoidCallback? onSaveOrigin;
  final VoidCallback? onSaveDestination;
  final String? saveOriginTooltip;
  final String? saveDestinationTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E).withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactStopRow(
              label: originLabel,
              value: originValue,
              dotColor: AppColors.primary,
              openSearchTooltip: openSearchTooltip,
              onOpenSearch: onOpenSearchOrigin,
              onSave: onSaveOrigin,
              saveTooltip: saveOriginTooltip,
              onEdit: onEditOrigin,
              editTooltip: editTooltip,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            _CompactStopRow(
              label: destinationLabel,
              value: destinationValue,
              dotColor: const Color(0xFFFFE14A),
              openSearchTooltip: openSearchTooltip,
              onOpenSearch: onOpenSearchDestination,
              onSave: onSaveDestination,
              saveTooltip: saveDestinationTooltip,
              onEdit: onEditDestination,
              editTooltip: editTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStopRow extends StatelessWidget {
  const _CompactStopRow({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.openSearchTooltip,
    required this.editTooltip,
    this.onOpenSearch,
    this.onSave,
    this.saveTooltip,
    this.onEdit,
  });

  final String label;
  final String value;
  final Color dotColor;
  final String openSearchTooltip;
  final String editTooltip;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onSave;
  final String? saveTooltip;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Icon(Icons.place_rounded, color: dotColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: onOpenSearch,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Tooltip(
                message: openSearchTooltip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: dotColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onSave != null)
            IconButton(
              tooltip: saveTooltip ?? '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.bookmark_add_outlined,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
              onPressed: onSave,
            ),
          if (onEdit != null)
            IconButton(
              tooltip: editTooltip,
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
    this.onOpenSearch,
    this.openSearchTooltip,
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
  final VoidCallback? onOpenSearch;
  final String? openSearchTooltip;
  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showChevron = onSaveToFavorites == null && onEdit == null;
    return AnimatedContainer(
      duration: AppMotion.draftSearchChromeReveal,
      curve: AppMotion.standard,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: highlighted
            ? Border.all(color: dotColor.withValues(alpha: 0.9), width: 1.6)
            : null,
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
          Icon(icon, color: dotColor, size: 26),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenSearch,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                splashColor: dotColor.withValues(alpha: 0.14),
                highlightColor: dotColor.withValues(alpha: 0.06),
                child: Tooltip(
                  message: openSearchTooltip ?? '',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: dotColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onSaveToFavorites != null) ...[
            IconButton(
              tooltip: saveToFavoritesTooltip ?? '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(

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
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
              size: 26,
            ),
        ],
      ),
    );
  }
}
