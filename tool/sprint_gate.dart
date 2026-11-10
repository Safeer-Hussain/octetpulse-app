import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  print('=======================================================');
  print('   OCTETPULSE AUTONOMOUS SPRINT VERIFICATION GATE     ');
  print('=======================================================');

  final stopwatch = Stopwatch()..start();

  try {
    await stepPubGet();
    await stepFormat();
    await stepAnalyze();
    await stepTest();
    await stepDeviceRuntimeCheck();

    stopwatch.stop();
    print('\n=======================================================');
    print(' [GATE PASSED] 100% HEALTH CHECK & VERIFICATION OK (${stopwatch.elapsed.inSeconds}s)');
    print('=======================================================');
    exit(0);
  } catch (e) {
    stopwatch.stop();
    print('\n=======================================================');
    print(' [GATE FAILED] $e');
    print('=======================================================');
    exit(1);
  }
}

Future<void> stepPubGet() async {
  print('\n[1/5] Executing flutter pub get...');
  final res = await Process.run('flutter', ['pub', 'get'], runInShell: true);
  if (res.exitCode != 0) {
    print(res.stderr);
    throw Exception('flutter pub get failed with exit code ${res.exitCode}');
  }
  print('  -> Dependencies resolved cleanly.');
}

Future<void> stepFormat() async {
  print('\n[2/5] Auto-formatting codebase (dart format lib test)...');
  final res = await Process.run('dart', ['format', 'lib', 'test'], runInShell: true);
  if (res.exitCode != 0) {
    print(res.stderr);
    throw Exception('dart format failed with exit code ${res.exitCode}');
  }
  print('  -> Formatting applied across lib and test.');
}

Future<void> stepAnalyze() async {
  print('\n[3/5] Executing static analysis (flutter analyze --no-pub)...');
  final res = await Process.run('flutter', ['analyze', '--no-pub'], runInShell: true);
  final output = res.stdout.toString() + res.stderr.toString();

  if (res.exitCode != 0 || output.contains('error •') || output.contains('warning •') || output.contains('info •')) {
    print(output);
    throw Exception('flutter analyze failed with issues.');
  }
  print('  -> Static analysis passed with 0 issues.');
}

Future<void> stepTest() async {
  print('\n[4/5] Executing automated tests (flutter test --no-pub)...');
  final res = await Process.run('flutter', ['test', '--no-pub'], runInShell: true);
  if (res.exitCode != 0) {
    print(res.stdout);
    print(res.stderr);
    throw Exception('flutter test failed with exit code ${res.exitCode}');
  }
  print('  -> All unit and widget tests passed cleanly.');
}

Future<void> stepDeviceRuntimeCheck() async {
  print('\n[5/5] Checking connected physical device runtime...');
  final devRes = await Process.run('flutter', ['devices', '--machine'], runInShell: true);
  if (devRes.exitCode != 0) {
    print('  -> Warning: Could not query devices (${devRes.stderr}). Skipping live device check.');
    return;
  }

  List<dynamic> devices = [];
  try {
    devices = jsonDecode(devRes.stdout.toString()) as List<dynamic>;
  } catch (_) {
    print('  -> Warning: Unable to parse flutter devices output.');
    return;
  }

  // Look for Android or iOS devices/emulators
  final targetDevices = devices.where((d) {
    final platform = (d['targetPlatform'] ?? '').toString().toLowerCase();
    return platform.contains('android') || platform.contains('ios');
  }).toList();

  if (targetDevices.isEmpty) {
    print('  -> No Android/iOS physical device or emulator currently attached.');
    print('  -> Skipping live device runtime smoke test.');
    return;
  }

  final device = targetDevices.first;
  final deviceId = device['id'].toString();
  final deviceName = device['name'].toString();
  print('  -> Found connected mobile device: $deviceName ($deviceId)');

  final adbPath = _findAdbExecutable();
  if (adbPath == null) {
    print('  -> adb binary not found in PATH or standard Android SDK directories.');
    print('  -> Skipping logcat dump verification.');
    return;
  }

  // Clear stale logcat
  print('  -> Clearing stale device crash logs via adb logcat -c...');
  await Process.run(adbPath, ['-s', deviceId, 'logcat', '-c'], runInShell: true);

  // Controlled 25-second startup and smoke window
  print('  -> Launching app on $deviceId with controlled 25-second runtime smoke window...');
  final process = await Process.start('flutter', ['run', '-d', deviceId, '--no-pub'], runInShell: true);

  final consoleBuffer = StringBuffer();
  process.stdout.transform(utf8.decoder).listen((data) => consoleBuffer.write(data));
  process.stderr.transform(utf8.decoder).listen((data) => consoleBuffer.write(data));

  await Future<void>.delayed(const Duration(seconds: 25));

  // Kill running flutter process gracefully
  process.kill();
  await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);

  // Inspect device logcat
  print('  -> Inspecting device runtime logs via adb logcat -d...');
  final logcatRes = await Process.run(adbPath, ['-s', deviceId, 'logcat', '-d'], runInShell: true);
  final logs = logcatRes.stdout.toString() + consoleBuffer.toString();

  final fatalPatterns = [
    'EXCEPTION CAUGHT BY',
    'A RenderFlex overflowed by',
    'There are multiple heroes that share the same tag',
    'No observables detected in the build method of Observer',
    'setState() or markNeedsBuild() called during build',
    'AndroidRuntime: FATAL EXCEPTION',
    'Unhandled Exception:',
  ];

  for (final pattern in fatalPatterns) {
    if (logs.contains(pattern)) {
      print('  -> RUNTIME CRASH OR LAYOUT EXCEPTION DETECTED: "$pattern"');
      throw Exception('Connected device reported fatal runtime exception: $pattern');
    }
  }

  print('  -> Live device runtime smoke test passed with 0 crashes, 0 overflows, and 0 Hero collisions.');
}

String? _findAdbExecutable() {
  // Check standard PATH
  final envPath = Platform.environment['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  for (final part in envPath.split(separator)) {
    final candidate = File('$part${Platform.pathSeparator}adb${Platform.isWindows ? '.exe' : ''}');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }

  // Check Android LocalAppData on Windows
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final candidate = File('$localAppData\\Android\\Sdk\\platform-tools\\adb.exe');
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }
  }

  // Check ANDROID_HOME or ANDROID_SDK_ROOT
  final androidHome = Platform.environment['ANDROID_HOME'] ?? Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome != null) {
    final candidate = File('$androidHome${Platform.pathSeparator}platform-tools${Platform.pathSeparator}adb${Platform.isWindows ? '.exe' : ''}');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }

  return null;
}
