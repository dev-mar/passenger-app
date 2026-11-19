import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_corridor_booking_page.dart';
import 'passenger_corridor_repository.dart';

const double _nearCityKm = 80;

class PassengerCorridorScreen extends ConsumerStatefulWidget {
  const PassengerCorridorScreen({super.key});

  @override
  ConsumerState<PassengerCorridorScreen> createState() => _PassengerCorridorScreenState();
}

class _PassengerCorridorScreenState extends ConsumerState<PassengerCorridorScreen> {
  CorridorLanes _lanes = const CorridorLanes(cities: [], destinations: []);
  List<CorridorBooking> _bookings = const [];
  List<CorridorDeparture> _departures = const [];
  String? _cityKey;
  String? _localityKey;
  CorridorDestination? _destination;
  final TextEditingController _query = TextEditingController();
  DateTime _date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int _seats = 1;
  bool _loading = true;
  bool _searching = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query.addListener(() {
      if (mounted) setState(() {});
    });
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  PassengerCorridorRepository get _repo =>
      PassengerCorridorRepository(ref.read(passengerApiClientProvider));

  String get _day {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '${_date.year}-$month-$day';
  }

  CorridorCity? get _city {
    for (final city in _lanes.cities) {
      if (city.key == _cityKey) return city;
    }
    return null;
  }

  List<CorridorDestination> get _visibleDestinations {
    final key = _cityKey;
    if (key == null) return const [];
    final needle = _query.text.trim().toLowerCase();
    final visible = <CorridorDestination>[];
    for (final item in _lanes.destinations) {
      if (item.cityKey != key) continue;
      final options = _localityKey == null
          ? item.options
          : item.options.where((option) => option.fromLocalityKey == _localityKey).toList();
      if (options.isEmpty) continue;
      final next = item.copyWith(options: options);
      if (needle.isNotEmpty) {
        final haystack = '${next.toName} ${next.toRegion} ${next.toLocality} ${next.options.map((option) => option.routeName).join(' ')}'
            .toLowerCase();
        if (!haystack.contains(needle)) continue;
      }
      visible.add(next);
    }
    return visible;
  }

  List<CorridorLocality> get _localities {
    final key = _cityKey;
    if (key == null) return const [];
    return _lanes.localities.where((item) => item.cityKey == key).toList();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lanes = await _repo.lanes();
      final bookings = await _repo.mine();
      if (!mounted) return;
      setState(() {
        _lanes = lanes;
        _bookings = bookings;
        _loading = false;
      });
      await _locate(silent: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = corridorErrorText(error, l10n.texiRutaGenericError);
      });
    }
  }

  Future<void> _locate({bool silent = false}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _locating = true);
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.texiRutaCityFar)));
        }
        return;
      }
      final permission = await PassengerGeolocationPermissionCache.ensureLocationPermission(
        requestIfDenied: !silent,
      );
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (!mounted || position == null) return;
      CorridorCity? nearest;
      var best = double.infinity;
      for (final city in _lanes.cities) {
        final distance = _kilometers(position.latitude, position.longitude, city.latitude, city.longitude);
        if (distance < best) {
          best = distance;
          nearest = city;
        }
      }
      if (nearest != null && best <= _nearCityKm) {
        setState(() {
          _cityKey = nearest!.key;
          _localityKey = null;
          _destination = null;
          _departures = const [];
        });
        return;
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.texiRutaCityFar)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openDestination(CorridorDestination destination) async {
    HapticFeedback.lightImpact();
    setState(() {
      _destination = destination;
      _departures = const [];
      _searching = true;
      _error = null;
    });
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final l10n = AppLocalizations.of(context)!;
    final destination = _destination;
    if (destination == null) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final lists = await Future.wait(
        destination.options.map(
          (option) => _repo.departures(
            fromStopId: option.fromStopId,
            toStopId: destination.toStopId,
            date: _day,
          ),
        ),
      );
      if (!mounted || _destination?.toStopId != destination.toStopId) return;
      final items = lists.expand((list) => list).toList()
        ..sort((a, b) => (a.departureAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
              b.departureAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            ));
      setState(() {
        _departures = items;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = corridorErrorText(error, l10n.texiRutaGenericError);
      });
    }
  }

  List<CorridorBooking> get _openBookings {
    final items = _bookings.where((item) => item.isOpen).toList()
      ..sort((a, b) => (a.departureAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.departureAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ));
    return items;
  }

  Future<void> _book(CorridorDeparture item) async {
    final l10n = AppLocalizations.of(context)!;
    if (item.seatsLeft < _seats) return;
    HapticFeedback.lightImpact();
    setState(() => _searching = true);
    try {
      final created = await _repo.book(
        tripId: item.tripId,
        fromStopId: item.fromStopId,
        toStopId: item.toStopId,
        seatCount: _seats,
        idempotencyKey: '${item.tripId}-${item.fromStopId}-${item.toStopId}-$_seats-$_day',
      );
      final bookings = await _repo.mine();
      if (!mounted) return;
      CorridorBooking? saved;
      for (final booking in bookings) {
        if (booking.id == created.id || (created.id.isEmpty && booking.publicCode == created.publicCode)) {
          saved = booking;
          break;
        }
      }
      saved ??= CorridorBooking(
        id: created.id,
        publicCode: created.publicCode,
        seatCount: created.seatCount == 0 ? _seats : created.seatCount,
        status: created.status,
        fareAmount: created.fareAmount == 0 ? item.fareAmount : created.fareAmount,
        departureAt: item.departureAt,
        routeName: item.routeName,
        fromName: item.fromName,
        toName: item.toName,
        givenName: item.givenName,
        plate: item.plate,
        color: item.color,
        model: item.model,
        fromLatitude: item.fromLatitude,
        fromLongitude: item.fromLongitude,
      );
      setState(() {
        _bookings = bookings;
        _searching = false;
        _destination = null;
        _departures = const [];
      });
      await _openBooking(saved, justSaved: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = corridorErrorText(error, l10n.texiRutaGenericError);
      });
    }
  }

  void _pickCity(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _cityKey = key;
      _localityKey = null;
      _destination = null;
      _departures = const [];
      _query.clear();
    });
  }

  void _pickDay(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() => _date = DateTime(day.year, day.month, day.day));
    if (_destination != null) {
      _loadSchedules();
    }
  }

  String _clock(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _openBooking(CorridorBooking item, {bool justSaved = false}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => PassengerCorridorBookingPage(
          booking: item,
          justSaved: justSaved,
          onCancel: () => _repo.cancel(item.id),
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'again' || result == 'cancelled') {
      setState(() {
        _destination = null;
        _departures = const [];
      });
    }
    if (result == 'cancelled') {
      try {
        final bookings = await _repo.mine();
        if (!mounted) return;
        setState(() => _bookings = bookings);
      } catch (_) {}
    }
  }

  Future<void> _showBookings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PassengerCorridorBookingsPage(
          bookings: _bookings,
          onOpen: (item) {
            Navigator.of(context).pop();
            _openBooking(item);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final city = _city;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.texiRutaTitle),
        actions: [
          IconButton(
            tooltip: l10n.texiRutaMine,
            onPressed: _showBookings,
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateRail(selected: _date, onPick: _pickDay),
                if (_destination == null && _openBookings.isNotEmpty)
                  _OpenBookings(
                    items: _openBookings,
                    onOpen: _openBooking,
                    onAll: _showBookings,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, AppSpacing.md, AppSpacing.xxx, AppSpacing.md),
                  child: _CityBar(
                    label: city?.label ?? l10n.texiRutaPickCity,
                    caption: l10n.texiRutaLeaveFrom,
                    locating: _locating,
                    onLocate: () => _locate(),
                    onChoose: () => setState(() {
                      _cityKey = null;
                      _localityKey = null;
                      _destination = null;
                      _departures = const [];
                    }),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.draftSearchChromeReveal,
                    switchInCurve: AppMotion.standard,
                    child: _destination == null
                        ? _cityKey == null
                            ? _CityList(cities: _lanes.cities, onPick: _pickCity)
                            : _DestinationList(
                                title: l10n.texiRutaDestinations,
                                hint: l10n.texiRutaSearchPlace,
                                query: _query,
                                items: _visibleDestinations,
                                localities: _localities,
                                localityKey: _localityKey,
                                allLocalities: l10n.texiRutaAllLocalities,
                                onLocality: (value) => setState(() {
                                  _localityKey = value;
                                  _destination = null;
                                  _departures = const [];
                                }),
                                cityLabel: city?.label ?? '',
                                empty: l10n.texiRutaNoDestinations,
                                otherCity: l10n.texiRutaOtherCity,
                                fromFare: l10n.texiRutaFromFare,
                                onOpen: _openDestination,
                              )
                        : _ScheduleList(
                            destination: _destination!,
                            cityLabel: city?.label ?? '',
                            departures: _departures,
                            searching: _searching,
                            seats: _seats,
                            onSeats: (value) => setState(() => _seats = value),
                            onBack: () => setState(() {
                              _destination = null;
                              _departures = const [];
                            }),
                            onBook: _book,
                            clock: _clock,
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

double _kilometers(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0;
  final dLat = _radians(lat2 - lat1);
  final dLng = _radians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) * math.cos(_radians(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;

class _DateRail extends StatelessWidget {
  const _DateRail({required this.selected, required this.onPick});

  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final spanish = Localizations.localeOf(context).languageCode == 'es';
    const monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx, vertical: AppSpacing.md),
        itemCount: 21,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          final isSelected = day == selected;
          final months = spanish ? monthsEs : monthsEn;
          return AnimatedContainer(
            duration: AppMotion.draftSearchChromeReveal,
            curve: AppMotion.standard,
            width: isSelected ? 84 : 68,
            child: Material(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                onTap: () => onPick(day),
                child: Center(
                  child: Text(
                    index == 0 ? l10n.texiRutaToday : '${day.day} ${months[day.month - 1]}',
                    style: TextStyle(
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CityBar extends StatelessWidget {
  const _CityBar({
    required this.label,
    required this.caption,
    required this.locating,
    required this.onLocate,
    required this.onChoose,
  });

  final String label;
  final String caption;
  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: onChoose,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx, vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caption, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: AppSizes.buttonHeight,
          height: AppSizes.buttonHeight,
          child: IconButton.filled(
            tooltip: l10n.texiRutaUseLocation,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
            onPressed: locating ? null : onLocate,
            icon: locating
                ? const SizedBox(
                    width: AppIconSizes.md,
                    height: AppIconSizes.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _CityList extends StatelessWidget {
  const _CityList({required this.cities, required this.onPick});

  final List<CorridorCity> cities;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (cities.isEmpty) {
      return Center(child: Text(l10n.texiRutaNoDestinations));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, AppSpacing.md, AppSpacing.xxx, AppSpacing.section),
      itemCount: cities.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final city = cities[index];
        return _Rise(
          index: index,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => onPick(city.key),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxx),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: Text(city.label, style: Theme.of(context).textTheme.titleMedium)),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({
    required this.title,
    required this.hint,
    required this.query,
    required this.items,
    required this.localities,
    required this.localityKey,
    required this.allLocalities,
    required this.onLocality,
    required this.cityLabel,
    required this.empty,
    required this.otherCity,
    required this.fromFare,
    required this.onOpen,
  });

  final String title;
  final String hint;
  final TextEditingController query;
  final List<CorridorDestination> items;
  final List<CorridorLocality> localities;
  final String? localityKey;
  final String allLocalities;
  final ValueChanged<String?> onLocality;
  final String cityLabel;
  final String empty;
  final String otherCity;
  final String Function(String fare) fromFare;
  final ValueChanged<CorridorDestination> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, AppSpacing.md, AppSpacing.xxx, AppSpacing.md),
          child: TextField(
            controller: query,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
        if (localities.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
              itemCount: localities.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final selected = index == 0 ? localityKey == null : localityKey == localities[index - 1].key;
                final label = index == 0 ? allLocalities : localities[index - 1].label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onLocality(index == 0 ? null : localities[index - 1].key),
                );
              },
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(empty))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, 0, AppSpacing.xxx, AppSpacing.section),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final other = item.toRegion.isNotEmpty && item.toRegion.toLowerCase() != cityLabel.toLowerCase();
                    final place = [
                      if (other) otherCity,
                      if (other && item.toRegion.isNotEmpty) item.toRegion,
                      if (item.toLocality.isNotEmpty) item.toLocality,
                    ].join(' · ');
                    final fare = item.options.map((option) => option.baseFare).reduce(math.min);
                    final fromName = item.options.first.fromName;
                    return _Rise(
                      index: index,
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          onTap: () => onOpen(item),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxx),
                            child: Row(
                              children: [
                                const _LaneMark(),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$fromName → ${item.toName}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        place.isNotEmpty ? place : item.options.first.routeName,
                                        style: const TextStyle(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        children: [
                                          const Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            fromFare(fare.toStringAsFixed(0)),
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({
    required this.destination,
    required this.cityLabel,
    required this.departures,
    required this.searching,
    required this.seats,
    required this.onSeats,
    required this.onBack,
    required this.onBook,
    required this.clock,
  });

  final CorridorDestination destination;
  final String cityLabel;
  final List<CorridorDeparture> departures;
  final bool searching;
  final int seats;
  final ValueChanged<int> onSeats;
  final VoidCallback onBack;
  final ValueChanged<CorridorDeparture> onBook;
  final String Function(DateTime? value) clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final other = destination.toRegion.isNotEmpty && destination.toRegion.toLowerCase() != cityLabel.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.texiRutaSchedules, style: const TextStyle(color: AppColors.textSecondary)),
                    Text(
                      other ? '${destination.toName} · ${destination.toRegion}' : destination.toName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          child: Row(
            children: [
              Text(l10n.texiRutaSeats),
              const Spacer(),
              IconButton(
                onPressed: seats > 1 ? () => onSeats(seats - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$seats'),
              IconButton(
                onPressed: seats < 8 ? () => onSeats(seats + 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          child: Text(l10n.texiRutaCash, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: searching
              ? const Center(child: CircularProgressIndicator())
              : departures.isEmpty
                  ? Center(child: Text(l10n.texiRutaEmpty))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, 0, AppSpacing.xxx, AppSpacing.section),
                      itemCount: departures.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = departures[index];
                        final who = [
                          item.givenName,
                          item.plate,
                          [item.color, item.model].where((part) => part.isNotEmpty).join(' '),
                        ].where((part) => part.isNotEmpty).join(' · ');
                        final full = item.seatsLeft < seats;
                        final open = item.canBook && !full;
                        return _Rise(
                          index: index,
                          child: Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxx),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, color: AppColors.primary, size: 18),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        clock(item.departureAt),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Bs ${item.fareAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('${item.fromName} → ${item.toName}'),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    l10n.texiRutaSeatsLeft(item.seatsLeft),
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  if (who.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(who, style: const TextStyle(color: AppColors.textSecondary)),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  if (item.fromLatitude != 0 || item.fromLongitude != 0)
                                    SizedBox(
                                      width: double.infinity,
                                      height: AppSizes.buttonHeight,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openBoardMap(
                                          context,
                                          latitude: item.fromLatitude,
                                          longitude: item.fromLongitude,
                                          label: item.fromName,
                                        ),
                                        icon: const Icon(Icons.map_outlined),
                                        label: Text(l10n.texiRutaBoardMap),
                                      ),
                                    ),
                                  const SizedBox(height: AppSpacing.sm),
                                  SizedBox(
                                    width: double.infinity,
                                    height: AppSizes.buttonHeight,
                                    child: FilledButton.icon(
                                      onPressed: open && !searching
                                          ? () => _confirmBooking(context, item, seats, clock, onBook)
                                          : null,
                                      icon: Icon(open ? Icons.check_circle_outline : Icons.lock_outline),
                                      label: Text(
                                        full
                                            ? l10n.texiRutaFull
                                            : open
                                                ? l10n.texiRutaConfirm
                                                : l10n.texiRutaNotOpen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

Future<void> _confirmBooking(
  BuildContext context,
  CorridorDeparture item,
  int seats,
  String Function(DateTime? value) clock,
  ValueChanged<CorridorDeparture> onBook,
) async {
  final l10n = AppLocalizations.of(context)!;
  final total = (item.fareAmount * seats).toStringAsFixed(0);
  final yes = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheetTop)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.texiRutaConfirm, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Text('${item.fromName} → ${item.toName}'),
              const SizedBox(height: AppSpacing.xs),
              Text('${clock(item.departureAt)} · $seats · ${l10n.texiRutaTotal(total)}'),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.texiRutaCash, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxx),
              SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.texiRutaConfirm),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (yes == true) onBook(item);
}

void _openBoardMap(
  BuildContext context, {
  required double latitude,
  required double longitude,
  required String label,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PassengerCorridorBoardMap(latitude: latitude, longitude: longitude, label: label),
    ),
  );
}

class _OpenBookings extends StatelessWidget {
  const _OpenBookings({
    required this.items,
    required this.onOpen,
    required this.onAll,
  });

  final List<CorridorBooking> items;
  final ValueChanged<CorridorBooking> onOpen;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = items.length > 2 ? items.take(2).toList() : items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, 0, AppSpacing.xxx, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.texiRutaMine, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...visible.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  onTap: () => onOpen(item),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxx),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.fromName} → ${item.toName}'),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${corridorBookingWhen(item.departureAt)} · ${l10n.texiRutaSeatCount(item.seatCount)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.publicCode,
                          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (items.length > 2)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onAll, child: Text(l10n.texiRutaSeeAll)),
            ),
        ],
      ),
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 40 * index.clamp(0, 8);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.draftSearchChromeReveal + Duration(milliseconds: delay),
      curve: AppMotion.standard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
        );
      },
      child: child,
    );
  }
}

class _LaneMark extends StatelessWidget {
  const _LaneMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 52,
      child: CustomPaint(painter: _LanePainter()),
    );
  }
}

class _LanePainter extends CustomPainter {
  const _LanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(10, 8)
      ..quadraticBezierTo(size.width - 2, size.height / 2, 10, size.height - 8);
    canvas.drawPath(path, line);
    canvas.drawCircle(const Offset(10, 8), 4, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(10, size.height - 8), 4, Paint()..color = AppColors.secondary);
  }

  @override
  bool shouldRepaint(covariant _LanePainter oldDelegate) => false;
}
