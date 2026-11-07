import 'package:nfc_manager/nfc_manager.dart';


const _techKeys = [
  'nfca',
  'mifareclassic',
  'mifareultralight',
  'mifare',
  'isodep',
  'ndef',
  'nfcb',
  'nfcf',
  'nfcv',
];


String? extractNfcTagId(NfcTag tag) {
  try {
    final dynamic data = tag.data;

    if (data is Map) return _fromMap(data);

    try {
      if (data.id != null) return bytesToHex(List<int>.from(data.id));
      if (data.identifier != null) return bytesToHex(List<int>.from(data.identifier));
    } catch (_) {}

    for (final key in _techKeys) {
      try {
        final dynamic tech = data[key];
        if (tech == null) continue;
        if (tech['identifier'] != null) return bytesToHex(List<int>.from(tech['identifier']));
        if (tech.identifier != null) return bytesToHex(List<int>.from(tech.identifier));
      } catch (_) {}
    }
  } catch (_) {}
  return null;
}

String? _fromMap(Map data) {
  for (final key in _techKeys) {
    final tech = data[key];
    if (tech is Map && tech['identifier'] is List) {
      return bytesToHex(List<int>.from(tech['identifier']));
    }
  }
  return null;
}


String bytesToHex(List<int> bytes) {
  return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
}
