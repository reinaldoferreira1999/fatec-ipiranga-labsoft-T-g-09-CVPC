import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaPagamentoPix extends StatefulWidget {
  final double valor;
  final String descricao;
  final String anuncioId;
  final String enderecoId;
  final String userId;

  const TelaPagamentoPix({
    super.key,
    required this.valor,
    required this.descricao,
    required this.anuncioId,
    required this.enderecoId,
    required this.userId,
  });

  @override
  State<TelaPagamentoPix> createState() => _TelaPagamentoPixState();
}

class _TelaPagamentoPixState extends State<TelaPagamentoPix> {
  bool _carregando = false;

 Future<void> _abrirCheckoutMercadoPago() async {
  try {
    setState(() {
      _carregando = true;
    });

    final response = await http.post(
      Uri.parse('http://192.168.15.2:3000/criar-preferencia'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': widget.descricao,
        'preco': widget.valor,
        'anuncioId': widget.anuncioId,
        'enderecoId': widget.enderecoId,
        'userId': widget.userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao criar preferência: ${response.body}');
    }

    final data = jsonDecode(response.body);

    final String? pedidoId = data['pedidoId'];
    final String? url = data['init_point'] ?? data['sandbox_init_point'];

    if (pedidoId == null || pedidoId.isEmpty) {
      throw Exception('pedidoId não recebido');
    }

    if (url == null || url.isEmpty) {
      throw Exception('URL de pagamento não recebida');
    }

    final pedidoExistente = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('pedidoId', isEqualTo: pedidoId)
        .limit(1)
        .get();

    if (pedidoExistente.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('pedidos').add({
        'userId': widget.userId,
        'descricao': widget.descricao,
        'valor': widget.valor,
        'status': 'Pagamento pendente',
        'pedidoId': pedidoId,
        'anuncioId': widget.anuncioId,
        'enderecoId': widget.enderecoId,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pedidoIdPendente', pedidoId);
    await prefs.setString('produtoNome', widget.descricao);
    await prefs.setDouble('produtoValor', widget.valor);
    await prefs.setString('anuncioId', widget.anuncioId);
    await prefs.setString('enderecoId', widget.enderecoId);

    final theme = Theme.of(context);

    await launchUrl(
      Uri.parse(url),
      customTabsOptions: CustomTabsOptions(
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: theme.colorScheme.surface,
        ),
        shareState: CustomTabsShareState.on,
        urlBarHidingEnabled: true,
        showTitle: true,
        animations: const CustomTabsAnimations(
          startEnter: 'slide_up',
          startExit: 'android:anim/fade_out',
          endEnter: 'android:anim/fade_in',
          endExit: 'slide_down',
        ),
      ),
      safariVCOptions: const SafariViewControllerOptions(
        preferredBarTintColor: Colors.white,
        preferredControlTintColor: Colors.black,
        barCollapsingEnabled: true,
        entersReaderIfAvailable: false,
      ),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir pagamento: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.descricao,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Valor: R\$ ${widget.valor.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _carregando ? null : _abrirCheckoutMercadoPago,
              icon: _carregando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _carregando
                    ? 'Abrindo checkout...'
                    : 'Pagar com Mercado Pago',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Você será redirecionado para o checkout seguro do Mercado Pago.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}