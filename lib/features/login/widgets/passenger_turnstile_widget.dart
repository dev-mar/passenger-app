import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';

const String _kTurnstilePageBaseUrlDefault = 'https://api.prod.taxitexi.com/';

enum PassengerCaptchaContext { loginEntry, stepUp }

String _turnstilePageBaseUrl() {
  const override = String.fromEnvironment('TURNSTILE_PAGE_BASE_URL');
  final raw =
      override.trim().isNotEmpty ? override.trim() : _kTurnstilePageBaseUrlDefault;
  return raw.endsWith('/') ? raw : '$raw/';
}

enum _TurnstileUiState { loading, interactive, ready, error }

/// Turnstile embebido con estilo auth pasajero (login + step-up).
class PassengerTurnstileWidget extends StatefulWidget {
  const PassengerTurnstileWidget({
    super.key,
    required this.onToken,
    this.onError,
    this.captchaContext = PassengerCaptchaContext.stepUp,
  });

  final ValueChanged<String> onToken;
  final VoidCallback? onError;
  final PassengerCaptchaContext captchaContext;

  @override
  State<PassengerTurnstileWidget> createState() =>
      PassengerTurnstileWidgetState();
}

class PassengerTurnstileWidgetState extends State<PassengerTurnstileWidget> {
  WebViewController? _controller;
  _TurnstileUiState _state = _TurnstileUiState.loading;
  int _attempt = 0;
  Completer<String>? _pendingToken;

  @override
  void initState() {
    super.initState();
    _bootAttempt();
  }

  /// Reinicia el widget tras fallo server-side del captcha.
  Future<void> resetWidget() async {
    _pendingToken?.completeError(StateError('reset'));
    _pendingToken = null;
    setState(() => _attempt++);
    await _bootAttempt();
  }

  Future<String?> awaitFreshToken({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (_state == _TurnstileUiState.ready && _controller != null) {
      final completer = Completer<String>();
      _pendingToken = completer;
      try {
        await _controller!.runJavaScript(
          'if (window.turnstileWidgetId != null && window.turnstile) { turnstile.reset(window.turnstileWidgetId); }',
        );
      } catch (_) {}
      try {
        return await completer.future.timeout(timeout);
      } on TimeoutException {
        return null;
      }
    }
    if (_state == _TurnstileUiState.loading) {
      try {
        return await (_pendingToken ??= Completer<String>()).future.timeout(
          timeout,
        );
      } on TimeoutException {
        return null;
      }
    }
    return null;
  }

  Future<void> _bootAttempt() async {
    final siteKey = PassengerAppEnvironment.turnstileSiteKey.trim();
    if (siteKey.isEmpty) {
      if (mounted) setState(() => _state = _TurnstileUiState.error);
      widget.onError?.call();
      return;
    }

    setState(() {
      _state = _TurnstileUiState.loading;
      _controller = null;
    });

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1814))
      ..addJavaScriptChannel(
        'TurnstileChannel',
        onMessageReceived: (msg) {
          final payload = msg.message.trim();
          if (!mounted) return;
          if (payload == 'interactive') {
            setState(() => _state = _TurnstileUiState.interactive);
            return;
          }
          if (payload == 'error') {
            setState(() => _state = _TurnstileUiState.error);
            widget.onError?.call();
            _pendingToken?.completeError(StateError('turnstile error'));
            _pendingToken = null;
            return;
          }
          if (payload.isNotEmpty) {
            setState(() => _state = _TurnstileUiState.ready);
            widget.onToken(payload);
            if (_pendingToken != null && !_pendingToken!.isCompleted) {
              _pendingToken!.complete(payload);
            }
            _pendingToken = null;
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _state = _TurnstileUiState.error);
            widget.onError?.call();
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setMixedContentMode(MixedContentMode.alwaysAllow);
      final cookieManager = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      await cookieManager.setAcceptThirdPartyCookies(android, true);
    }

    await controller.loadHtmlString(
      _htmlForSiteKey(siteKey),
      baseUrl: _turnstilePageBaseUrl(),
    );

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  String _htmlForSiteKey(String siteKey) {
    final escaped = siteKey.replaceAll("'", "\\'");
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad&render=explicit" async defer></script>
  <style>
    html, body {
      margin: 0; padding: 0;
      background: transparent;
      overflow: hidden;
      min-height: 72px;
    }
    #turnstile-root {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 72px;
      width: 100%;
      padding: 4px 0;
    }
  </style>
</head>
<body>
  <div id="turnstile-root"></div>
  <script>
    function postError() {
      if (window.TurnstileChannel) TurnstileChannel.postMessage('error');
    }
    function postInteractive() {
      if (window.TurnstileChannel) TurnstileChannel.postMessage('interactive');
    }
    function onTurnstileSuccess(token) {
      if (window.TurnstileChannel) TurnstileChannel.postMessage(token);
    }
    function onTurnstileLoad() {
      if (!window.turnstile) { postError(); return; }
      window.turnstileWidgetId = turnstile.render('#turnstile-root', {
        sitekey: '$escaped',
        theme: 'dark',
        size: 'flexible',
        appearance: 'always',
        callback: onTurnstileSuccess,
        'error-callback': postError,
        'expired-callback': postError,
        'timeout-callback': postError
      });
      postInteractive();
    }
    setTimeout(function() { if (!window.turnstile) postError(); }, 15000);
  </script>
</body>
</html>
''';
  }

  String _hintForState(AppLocalizations l10n) {
    final isLogin = widget.captchaContext == PassengerCaptchaContext.loginEntry;
    return switch (_state) {
      _TurnstileUiState.loading =>
        isLogin ? l10n.loginCaptchaLoading : l10n.stepUpCaptchaLoading,
      _TurnstileUiState.interactive => isLogin
          ? l10n.loginCaptchaInteractiveHint
          : l10n.stepUpCaptchaInteractiveHint,
      _TurnstileUiState.ready =>
        isLogin ? l10n.loginCaptchaReady : l10n.stepUpCaptchaReady,
      _TurnstileUiState.error =>
        isLogin ? l10n.loginCaptchaLoadFailed : l10n.stepUpCaptchaLoadFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (PassengerAppEnvironment.turnstileSiteKey.trim().isEmpty) {
      return _messageBox(l10n.stepUpCaptchaLoadFailed);
    }

    final controller = _controller;
    final hintColor = _state == _TurnstileUiState.ready
        ? AppColors.success
        : _state == _TurnstileUiState.error
            ? AppColors.error.withValues(alpha: 0.92)
            : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null)
                  WebViewWidget(
                    key: ValueKey('turnstile-webview-$_attempt'),
                    controller: controller,
                  ),
                if (_state == _TurnstileUiState.loading)
                  ColoredBox(
                    color: const Color(0xFF1A1814).withValues(alpha: 0.92),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _hintForState(l10n),
            key: ValueKey(_state),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hintColor,
                  height: 1.35,
                  fontSize: 12.5,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_state == _TurnstileUiState.error) ...[
          const SizedBox(height: 2),
          Center(
            child: TextButton(
              onPressed: resetWidget,
              child: Text(l10n.stepUpCaptchaRetry),
            ),
          ),
        ],
      ],
    );
  }

  Widget _messageBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
