import 'dart:async';
import 'package:uni_links/uni_links.dart';

class DeepLinkService {
  StreamSubscription? _sub;

  void iniciar({
    required Function(Uri uri) onLinkRecebido,
  }) {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        onLinkRecebido(uri);
      }
    }, onError: (err) {
      print('Erro ao receber deep link: $err');
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}