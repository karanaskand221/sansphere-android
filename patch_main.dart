import 'file_io.dart' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Note: This temporary patch ensures your local emulators connect cleanly.
// We keep your existing imports and add emulator bindings right after initializeApp.
