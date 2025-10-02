import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mystic_star_journey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher_string.dart';

String? urlWeb;
String? urlPush;
String? timestampUserId;
bool isPush = false;
String deepLink = "";
String idfv = '';
String idfa = '';

// Перевірка чи є інтернет
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

// ініціалізація OneSignal
Future<void> setUpOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(AppConstants.oneSignalAppId);


  final prefs = await SharedPreferences.getInstance();
  final granted = await OneSignal.Notifications.requestPermission(true);

  await prefs.setBool('permission_granted', granted);


  OneSignal.Notifications.addClickListener((openedEvent) {
    isPush = true;

    // Отримуємо дані з push
    urlPush = (openedEvent.notification.launchUrl as String?)?.trim();
  });
}

// Відправка тегу OneSignal
Future<void> sendTagByOneSignal(String tsId) async {
  await OneSignal.User.addTagWithKey('timestamp_user_id', tsId);
}

Future<String> _pollForOneSignalId({Duration interval = const Duration(milliseconds: 200), Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final id = await OneSignal.User.getOnesignalId();
    if (id != null) return id;
    await Future.delayed(interval);
  }
  throw Exception('Timed out waiting for OneSignal ID');
}

// Перевірка локації
Future<String> isLocationCorrect() async {
  final client = HttpClient();
  var uri = Uri.parse(
    'https://${AppConstants.baseDomain}/${AppConstants.verificationParam}',
  );
  const int maxHops = 1000;

  try {
    for (var hop = 0; hop < maxHops; hop++) {
      // debugPrint('isLocationCorrect → Hop #$hop → GET $uri');

      final request = await client.getUrl(uri)
        ..followRedirects = false;
      final resp = await request.close();

      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final loc = resp.headers.value(HttpHeaders.locationHeader);
        if (loc == null) break;
        uri = uri.resolve(loc);
        continue;
      }

      if (resp.statusCode == 200) {
        // debugPrint('Success 200 at $uri after $hop hops');
        return '200';
      }

      // debugPrint('Error ${resp.statusCode} at $uri; stopping');
      return 'Error: ${resp.statusCode}';
    }

    // debugPrint('Redirect limit exceeded after $maxHops hops');
    return 'Error: Redirect limit exceeded';
  } catch (e) {
    // debugPrint('isLocationCorrect – Error: $e');
    return 'Error: $e';
  } finally {
    client.close(force: true);
  }
}

// налаштування AppsFlyer
Future<AppsflyerSdk> setUpAppsFlyer() async {
  final options = AppsFlyerOptions(
    afDevKey: AppConstants.appsFlyerDevKey,
    appId: AppConstants.appID,
    showDebug: true,
    timeToWaitForATTUserAuthorization: 0,
  );
  final sdk = AppsflyerSdk(options);
  await sdk.initSdk(registerConversionDataCallback: true);
  return sdk;
}


// Отримання AppsFlyer UID
Future<void> getAppsflyerUserId(
    AppsflyerSdk sdk,
    SharedPreferences prefs,
    ) async {
  final id = await sdk.getAppsFlyerUID();
  await prefs.setString('appsflyer_id', id!);
}

// Отримання Conversion data та перевірка на Organic і інші статуси
Future<Map<String, String>> setUpConversionTimer(AppsflyerSdk sdk) {
  final completer = Completer<Map<String, String>>();

  void completeEmpty() {
    completer.complete({
      for (var i = 1; i <= 8; i++) 'swed_$i': '',
      'keyword': '',
    });
  }

  final timeout = Timer(const Duration(seconds: 10), () {
    if (!completer.isCompleted) completeEmpty();
  });

  sdk.onInstallConversionData((data) {
    if (completer.isCompleted) return;
    timeout.cancel();
    debugPrint('🔄 InstallConversionData: $data');
    final status = (data['status'] as String?)?.trim() ?? '';
    final payload = data['payload'] as Map<String, dynamic>?;
    final afStat = (payload?['af_status'] as String?)?.trim() ?? '';

    if (status != 'success' || payload == null || afStat == 'Organic') {
      completeEmpty();
      return;
    }

    final campaign = (payload['campaign'] as String?)?.trim() ?? '';
    final parts = campaign.isEmpty ? <String>[] : campaign.split('_');

    if (parts.length < 2) {
      completeEmpty();
      return;
    }

    final swed1 = parts[0];
    final swed2 = parts.length > 1 ? parts[1] : '';
    final swed3 = parts.length > 2 ? parts[2] : '';
    final swed4 = parts.length > 3 ? parts[3] : '';
    final swed5 = parts.length > 4 ? parts[4] : '';
    final swed6 = parts.length > 5 ? parts[5] : '';

    final swed7 = (payload['media_source'] as String?)?.trim() ?? '';
    final swed8 = (payload['af_channel'] as String?)?.trim() ?? '';
    final keyword = (payload['af_keywords'] as String?)?.trim() ?? '';

    completer.complete({
      'swed_1': swed1,
      'swed_2': swed2,
      'swed_3': swed3,
      'swed_4': swed4,
      'swed_5': swed5,
      'swed_6': swed6,
      'swed_7': swed7,
      'swed_8': swed8,
      'keyword': keyword,
    });
  });

  return completer.future;
}

// Відправка urlWeb запиту
Future<http.Response?> sendUrlWebRequest(String initialUrl) async {
  final client = HttpClient();
  Uri uri = Uri.parse(initialUrl);
  const int maxHops = 1000;

  try {
    for (var hop = 0; hop < maxHops; hop++) {
      // debugPrint('sendUrlWebRequest → Hop #$hop → GET $uri');

      final request = await client.getUrl(uri)
        ..followRedirects = false;
      final resp = await request.close();

      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final loc = resp.headers.value(HttpHeaders.locationHeader);
        if (loc == null) break;
        uri = uri.resolve(loc);
        continue;
      }

      if (resp.statusCode >= 400) {
        final body = await resp.transform(utf8.decoder).join();
        final headersMap = <String, String>{};
        resp.headers.forEach((k, v) => headersMap[k] = v.join(','));
        // debugPrint('Error ${resp.statusCode} at $uri; stopping');
        return http.Response(body, resp.statusCode, headers: headersMap);
      }

      final body = await resp.transform(utf8.decoder).join();
      final headersMap = <String, String>{};
      resp.headers.forEach((k, v) => headersMap[k] = v.join(','));
      // debugPrint('Success ${resp.statusCode} at $uri after $hop hops');
      return http.Response(body, resp.statusCode, headers: headersMap);
    }

    // debugPrint('Redirect limit exceeded after $maxHops hops');
    return http.Response('Redirect limit exceeded', 599);
  } catch (e) {
    // debugPrint('Error sending urlWeb request: $e');
    return null;
  } finally {
    client.close(force: true);
  }
}

// Відправка івенту
Future<void> sendEvent(String eventName) async {
  if (timestampUserId == null) return;
  final Uri uri = Uri.https(
    AppConstants.baseDomain,
    AppConstants.verificationParam,
    {'dasfsa': eventName, 'fasfasda': timestampUserId!},
  );
  await sendUrlWebRequest(uri.toString());
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const MethodChannel _channel = MethodChannel('deferred_deeplink');

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      final shouldShowWhite = prefs.getBool('should_show_white_app') ?? false;

      // 1) Ініціалізація OneSignal
      await setUpOneSignal();

      // 2) Перевірка наявності інтернету
      if (!await hasInternetConnection()) {
        Navigator.of(context).pushReplacementNamed('/white');
        return;
      }

      // 3) Перевірка першого запуску
      if (isFirstLaunch) {
        // 4) Генерація timestamp_user_id
        final ms = DateTime
            .now()
            .millisecondsSinceEpoch;
        final rand = Random().nextInt(10000000).toString().padLeft(7, '0');
        timestampUserId = '$ms-$rand';
        await prefs.setString('timestamp_user_id', timestampUserId!);

        // 5) Відправка тегу OneSignal
        await sendTagByOneSignal(timestampUserId!);


        // 6)Івент 'uniq_visit'
        await sendEvent('uniq_visit');

        // 7) Перевірка локації
        final location = await isLocationCorrect();
        debugPrint('Location check returned: $location');
        if (location != '200') {
          await prefs.setBool('should_show_white_app', true);
          await prefs.setBool('is_first_launch', false);
          debugPrint('>>>> Location error: $location');
          Navigator.of(context).pushReplacementNamed('/white');
          return;
        }

        final iosInfo = await DeviceInfoPlugin().iosInfo;
        idfv = iosInfo.identifierForVendor ?? '';
        await prefs.setString('custom_user_id', idfv);

        // 10) AppsFlyer + setCustomerUserId(idfv)
        final sdk = await setUpAppsFlyer();

        await requestAtt();

        if (idfv != null) {
          sdk.setCustomerUserId(idfv);
        }

        // 10) Отримання AppsFlyer UID
        await getAppsflyerUserId(sdk, prefs);

        // 11) Отримання Conversion data та перевірка на Organic і інші статуси
        final swedMap = await setUpConversionTimer(sdk);

        // 12) Отримання one_signal_id
        final oneSignalId = await _pollForOneSignalId();
        await prefs.setString('one_signal_id', oneSignalId);

        // 13) Збереження даних у SharedPreferences та формування urlWeb
        final idFv = prefs.getString('custom_user_id') ?? '';
        final afId = prefs.getString('appsflyer_id') ?? '';
        final osId = prefs.getString('one_signal_id') ?? '';
        final tsId = timestampUserId!;
        final adFa = prefs.getString('advertising_id') ?? '';

        final swed1 = swedMap['swed_1']!;
        final swed2 = swedMap['swed_2']!;
        final swed3 = swedMap['swed_3']!;
        final swed4 = swedMap['swed_4']!;
        final swed5 = swedMap['swed_5']!;
        final swed6 = swedMap['swed_6']!;
        final swed7 = swedMap['swed_7']!;
        final swed8 = swedMap['swed_8']!;
        final keyword = swedMap['keyword']!;

        debugPrint('🔧 Params → googleId: $idFv, afId: $afId, osId: $osId, '
            'tsId: $tsId, adFa: $adFa, '
            'swed: [$swed1, $swed2, $swed3, $swed4, $swed5, $swed6, $swed7, $swed8]');

        urlWeb =
        'https://${AppConstants.baseDomain}/${AppConstants.verificationParam}'
            '?${AppConstants.verificationParam}=1'
            '&deqsfsa=$adFa'
            '&rtqsdad=$afId'
            '&adwerqsd=$osId'
            '&fasfasda=$tsId'
            '&sadweqq=$idFv'
            '&fsafsdaa=$idFv'
            '&swed_1=$swed1'
            '&swed_2=$swed2'
            '&swed_3=$swed3'
            '&swed_4=$swed4'
            '&swed_5=$swed5'
            '&swed_6=$swed6'
            '&swed_7=$swed7'
            '&swed_8=$swed8'
            '&keyword=$keyword';

        debugPrint('🌐 Built urlWeb: $urlWeb');
        await prefs.setString('url_web', urlWeb!);

        // 15) Відкриття UrlWebViewApp

        Navigator.of(context).pushReplacementNamed(
          '/webview',
          arguments: UrlWebViewArgs(urlWeb!, null, false),
        );
        return;
      }

      timestampUserId = prefs.getString('timestamp_user_id') ?? '';
      urlWeb = prefs.getString('url_web') ?? '';

      if (shouldShowWhite) {
        Navigator.of(context).pushReplacementNamed('/white');
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          final startUrl = isPush ? '$urlWeb&resq=true' : urlWeb!;
          Navigator.of(context).pushReplacementNamed(
            '/webview',
            arguments: UrlWebViewArgs(startUrl, urlPush, isPush),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: Image.asset(
            AppConstants.splashImagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class RootApp extends StatefulWidget {
  final String initialRoute;
  final Widget whiteScreen;

  const RootApp({
    Key? key,
    required this.initialRoute,
    required this.whiteScreen,
  }) : super(key: key);

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      routes: {
        '/white': (_) => widget.whiteScreen,
        '/verify': (_) => const VerificationScreen(),
        '/webview': (ctx) {
          final args =
          ModalRoute.of(ctx)!.settings.arguments as UrlWebViewArgs;
          return UrlWebViewApp(
            url: args.url,
            pushUrl: args.pushUrl,
            openedByPush: args.openedByPush,
          );
        },
      },
    );
  }
}

class UrlWebViewArgs {
  final String url;
  final String? pushUrl;
  final bool openedByPush;

  UrlWebViewArgs(this.url, this.pushUrl, this.openedByPush);
}

const _fallbackIdfa = '00000000-0000-0000-0000-000000000000';
const _prefsKey = 'advertising_id';

Future<void> requestAtt() async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if(status== TrackingStatus.notDetermined){
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
  getIDFA();
}

void getIDFA() async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  String idToSave;
  if(status == TrackingStatus.authorized){
    final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
    idToSave = idfa.isNotEmpty ? idfa : _fallbackIdfa;
    print("IDFA : $idfa");
  }else{
    idToSave = _fallbackIdfa;
    print("Tracking not authorized : $idToSave");
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, idToSave);
  print("Saved advertising_id: $idToSave");
}

// WEBVIEW

Future<void> _showAppNotFoundDialog(BuildContext ctx) => showDialog(
  context: ctx,
  builder: (dCtx) => AlertDialog(
    title: const Text('Application not found'),
    content: const Text('The required application is not installed on your device.'),
    actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('OK'))],
  ),
);

Future<void> _tryLaunchOrAlert(String url, BuildContext ctx) async {
  try {
    final success = await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!success) {
      await _showAppNotFoundDialog(ctx);
    }
  } catch (e) {
    await _showAppNotFoundDialog(ctx);
  }
}

Future<void> _silentLaunch(String url) async {
  try {
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  } catch (_) {
  }
}

final Map<String, String Function(Uri)> _appLinkBuilders = {
  'facebook.com': (u) => 'fb://facewebmodal/f?href=${u.toString()}',
  'instagram.com': (u) => 'instagram://user?username=${u.pathSegments.isNotEmpty ? u.pathSegments.first : ''}',
  'twitter.com': (u) => 'twitter://user?screen_name=${u.pathSegments.isNotEmpty ? u.pathSegments.first : ''}',
  'x.com': (u) => 'twitter://user?screen_name=${u.pathSegments.isNotEmpty ? u.pathSegments.first : ''}',
  'wa.me': (u) => 'whatsapp://send?phone=${u.pathSegments.first}',
  'whatsapp.com': (u) => 'whatsapp://send?phone=${u.pathSegments.first}',
};

Future<void> _openInAppOrBrowser(String url, BuildContext ctx) async {
  final uri = Uri.parse(url);
  for (final entry in _appLinkBuilders.entries) {
    if (uri.host.contains(entry.key)) {
      final appUrl = entry.value(uri);
      if (await canLaunchUrlString(appUrl)) {
        await launchUrlString(appUrl, mode: LaunchMode.externalApplication);
        return;
      }
      break;
    }
  }
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  } else {
    await _showAppNotFoundDialog(ctx);
  }
}

Future<NavigationActionPolicy> handleDeepLink({
  required Uri uri,
  required InAppWebViewController controller,
  required BuildContext ctx,
}) async {
  final urlStr = uri.toString();
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();

  const bankSchemes = {
    'rbcmobile',
    'cibcbanking',
    'scotiabank',
    'bmoolbb',
    'conexus',
    'pcfbanking',
    'tdct',
  };

  if (bankSchemes.contains(scheme)) {
    await _tryLaunchOrAlert(uri.toString(), ctx);
    return NavigationActionPolicy.CANCEL;
  }

  if (host == 'mobile.rbcroyalbank.com' && uri.queryParameters['emrf'] != null) {
    final token = uri.queryParameters['emrf']!;
    await _silentLaunch('rbcmobile://emrf_$token');
    return NavigationActionPolicy.ALLOW;
  }

  if (host.contains('cibconline.cibc.com')) {
    final frag   = uri.fragment;
    final params = Uri.splitQueryString(frag);
    if (params['emtId'] != null) {
      await _silentLaunch(
          'cibcbanking://requestetransfer?etransfertoken=${params['emtId']}'
      );
    }
    return NavigationActionPolicy.ALLOW;
  }

  if (host == 'secure.scotiabank.com' &&
      uri.queryParameters['requestRefNumber'] != null) {
    final ref = uri.queryParameters['requestRefNumber']!;
    await _silentLaunch(
        'scotiabank://?requestFlag=true&requestRefNumber=$ref'
    );
    return NavigationActionPolicy.ALLOW;
  }

  if (host == 'm.bmo.com' && uri.queryParameters['receiveFulfillToken'] != null) {
    final token = uri.queryParameters['receiveFulfillToken']!;
    await _silentLaunch('bmoolbb://id=$token&type=FULFILL');
    return NavigationActionPolicy.ALLOW;
  }

  if (host.contains('conexus.ca') &&
      uri.queryParameters['paymentId'] != null &&
      uri.queryParameters['type'] != null) {
    final id   = uri.queryParameters['paymentId']!;
    final type = uri.queryParameters['type']!;
    await _silentLaunch(
        'conexus://etransfers?type=$type&paymentId=$id'
    );
    return NavigationActionPolicy.ALLOW;
  }

  if (host == 'secure.pcfinancial.ca' &&
      uri.queryParameters['interacIssuedIncomingMoneyDemandNumber'] != null) {
    final num = uri.queryParameters['interacIssuedIncomingMoneyDemandNumber']!;
    await _silentLaunch(
        'pcfbanking://?interacIssuedIncomingMoneyDemandNumber=$num'
    );
    return NavigationActionPolicy.ALLOW;
  }

  if (host.contains('feeds.td.com') && uri.queryParameters['RMID'] != null) {
    final rmid = uri.queryParameters['RMID']!;
    await _silentLaunch('tdct://?RMID=$rmid');
    return NavigationActionPolicy.ALLOW;
  }

  if (host.contains('challenges.cloudflare.com')) return NavigationActionPolicy.ALLOW;

  if (urlStr.startsWith('about:') && scheme == 'about') return NavigationActionPolicy.ALLOW;

  if (scheme == 'javascript') return NavigationActionPolicy.CANCEL;

  const cryptoSchemes = [
    'ethereum',
    'bitcoin',
    'litecoin',
    'tron',
    'bsc',
    'dogecoin',
    'bitcoincash',
    'tether',
  ];
  if (cryptoSchemes.contains(scheme)) {
    await Clipboard.setData(ClipboardData(text: urlStr));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Address copied')));
    return NavigationActionPolicy.CANCEL;
  }

  if (_appLinkBuilders.keys.any((k) => host.contains(k))) {
    await _openInAppOrBrowser(urlStr, ctx);
    return NavigationActionPolicy.CANCEL;
  }

  if (scheme == 'http' || scheme == 'https' || scheme == 'file') return NavigationActionPolicy.ALLOW;

  if (await canLaunchUrlString(urlStr)) {
    await launchUrlString(urlStr, mode: LaunchMode.externalApplication);
  } else {
    await _showAppNotFoundDialog(ctx);
  }
  return NavigationActionPolicy.CANCEL;
}

class UrlWebViewApp extends StatefulWidget {
  final String url;
  final String? pushUrl;
  final bool openedByPush;

  const UrlWebViewApp({Key? key, required this.url, this.pushUrl, required this.openedByPush}) : super(key: key);

  @override
  State<UrlWebViewApp> createState() => _UrlWebViewAppState();
}

class _UrlWebViewAppState extends State<UrlWebViewApp> {
  late InAppWebViewController _webViewController;
  late String _webUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);


    if (widget.openedByPush) {
      widget.pushUrl?.isEmpty ?? true ? sendEvent('push_open_webview') : sendEvent('push_open_browser');
      isPush = false;
    }

    _initialize();
    sendEvent('webview_open');

    _webUrl = widget.url;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pushUrl?.isNotEmpty == true) {
        launchUrlString(widget.pushUrl!, mode: LaunchMode.externalApplication);
      }
    });
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('is_first_launch') ?? true;
    if (isFirst) {
      if (prefs.getBool('permission_granted') ?? true) await sendEvent('push_subscribe');
      prefs.setBool('is_first_launch', false);

      await _identifyUserInOneSignal(timestampUserId!);
    }
  }

  Future<void> _identifyUserInOneSignal(String tsId) async {
    try {
      if (tsId != null && tsId.isNotEmpty) {
        await OneSignal.login(tsId);
        print('OneSignal External ID : $tsId');
      }
    } catch (e) {
      print('Error External ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          bottom: true,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              transparentBackground: false,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              allowsBackForwardNavigationGestures: true,
              javaScriptCanOpenWindowsAutomatically: true,
              supportMultipleWindows: true,
              useShouldOverrideUrlLoading: true,
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              cacheEnabled: true,
              clearCache: false,
              userAgent:
              "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) "
                  "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 "
                  "Mobile/15E148 Safari/604.1",
              resourceCustomSchemes: [],
              allowFileAccess: true,
              allowFileAccessFromFileURLs: false,
              allowUniversalAccessFromFileURLs: false,
            ),
            onWebViewCreated: (ctrl) => _webViewController = ctrl,
            onLoadStart: (_, __) => setState(() => _isLoading = true),
            onLoadStop: (_, __) => setState(() => _isLoading = false),
            onLoadError: (_, __, ___, ____) => setState(() => _isLoading = false),
            onPermissionRequest: (controller, request) async {
              final granted = <PermissionResourceType>[];
              if (request.resources.contains(PermissionResourceType.CAMERA)) {
                granted.add(PermissionResourceType.CAMERA);
              }
              if (request.resources.contains(PermissionResourceType.MICROPHONE)) {
                granted.add(PermissionResourceType.MICROPHONE);
              }
              return PermissionResponse(
                resources: granted,
                action: granted.isEmpty
                    ? PermissionResponseAction.DENY
                    : PermissionResponseAction.GRANT,
              );
            },

            shouldOverrideUrlLoading: (controller, nav) async {

              if (nav.request.url?.scheme == 'about' && !nav.isForMainFrame) {
                return NavigationActionPolicy.ALLOW;
              }

              final uri = nav.request.url!;
              final host = uri.host.toLowerCase();
              if ((host.contains('express-connect.com') || host.contains('mobile.rbcroyalbank.com')) &&
                  (uri.scheme == 'http' || uri.scheme == 'https')) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => WebPopupScreen(initialUrl: uri.toString())));
                return NavigationActionPolicy.CANCEL;
              }
              return handleDeepLink(uri: uri, controller: controller, ctx: context);
            },
            onCreateWindow: (controller, req) async {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => WebPopupScreen(
                    initialUrl: req.request.url?.toString() ?? 'about:blank',
                    windowId: req.windowId,
                  ),
                ),
              );
              return true;
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('Console: ${consoleMessage.message}');
            },
          ),
        ),
        bottomNavigationBar: _NavigationBar(controllerGetter: () => _webViewController),
      ),
    );
  }
}

class WebPopupScreen extends StatefulWidget {
  final String initialUrl;
  final int? windowId;
  const WebPopupScreen({Key? key, required this.initialUrl, this.windowId}) : super(key: key);

  @override
  State<WebPopupScreen> createState() => _WebPopupScreenState();
}

class _WebPopupScreenState extends State<WebPopupScreen> {
  late InAppWebViewController _ctrl;

  static const double _edgeWidth = 20.0;

  @override
  Widget build(BuildContext context) {
    final webview = InAppWebView(
      windowId: widget.windowId,
      initialUrlRequest: widget.windowId == null
          ? URLRequest(url: WebUri(widget.initialUrl))
          : null,
      initialSettings: InAppWebViewSettings(
        allowsBackForwardNavigationGestures: false,
        javaScriptCanOpenWindowsAutomatically: true,
        supportMultipleWindows: true,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (c) => _ctrl = c,
      shouldOverrideUrlLoading: (c, nav) =>
          handleDeepLink(uri: nav.request.url!, controller: c, ctx: context),
      onCloseWindow: (_) => Navigator.of(context).pop(),
    );

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(child: webview),

            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _edgeWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) {
                  if (d.primaryDelta != null && d.primaryDelta! > 12) {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _NavigationBar(
          controllerGetter: () => _ctrl,
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final InAppWebViewController Function() controllerGetter;

  final VoidCallback? onBackTap;

  const _NavigationBar({
    Key? key,
    required this.controllerGetter,
    this.onBackTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (onBackTap != null) {
                onBackTap!();
              } else {
                final c = controllerGetter();
                if (await c.canGoBack()) {
                  c.goBack();
                } else {
                  Navigator.of(context).maybePop();
                }
              }
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controllerGetter().reload(),
          ),
        ],
      ),
    );
  }
}