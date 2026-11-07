import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/nfc_tag_utils.dart';

class BraceletsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> checkNfcSupport() async {
    try {
      await NfcManager.instance.isAvailable();
    } catch (_) {}
  }

  Future<bool> checkIfBraceletExists(String uid) async {
    try {
      final response = await ApiClient.dio.get('/bracelets/$uid');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> registerBracelet(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiClient.dio.post('/bracelets/', data: {'uid_rfid': uid});
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();

      final responseData = e.response?.data;
      if (responseData is Map && responseData.containsKey('message')) {
        return responseData['message'].toString();
      }

      if (e.response?.statusCode == 409) {
        return 'Esta pulseira já está cadastrada no sistema.';
      }

      return 'Erro ao cadastrar pulseira. Tente novamente.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Erro de conexão com o servidor.';
    }
  }

  Future<String?> deleteBracelet(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanDio = Dio(BaseOptions(baseUrl: ApiClient.dio.options.baseUrl));
      await cleanDio.delete(
        '/bracelets/$uid',
        options: Options(headers: {}),
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();

      final responseData = e.response?.data;
      if (responseData is Map && responseData.containsKey('message')) {
        return responseData['message'].toString();
      }

      if (e.response?.statusCode == 404) {
        return 'Esta pulseira não está cadastrada no sistema.';
      }

      return 'Erro ao apagar pulseira. Tente novamente.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Erro de conexão com o servidor.';
    }
  }

  void startNfcScan(Function(String uid) onScanned) async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        debugPrint('NFC não está disponível ou desligado no aparelho.');
        return;
      }

      await NfcManager.instance.stopSession().catchError((_) {});

      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final tagId = extractNfcTagId(tag);

          if (tagId != null && tagId.isNotEmpty) {
            debugPrint('🔥 UID extraído com sucesso: $tagId');
            stopNfc();
            onScanned(tagId);
          } else {
            debugPrint('Cartão detectado, mas não foi possível extrair o ID: ${tag.data}');
          }
        },
      );
    } catch (e) {
      debugPrint('Erro ao iniciar sessão NFC: $e');
    }
  }

  void stopNfc() {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
  }
}