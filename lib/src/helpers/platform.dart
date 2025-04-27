import 'dart:io';
import 'package:flutter/foundation.dart';

bool get isWeb => kIsWeb;

bool get isAndroid => !kIsWeb && Platform.isAndroid;

bool get isWindows => !kIsWeb && Platform.isWindows;

bool get isLinux => !kIsWeb && Platform.isLinux;

bool get isMacOS => !kIsWeb && Platform.isMacOS;

bool get isFuchsia => !kIsWeb && Platform.isFuchsia;

bool get isIOS => !kIsWeb && Platform.isIOS;

bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
