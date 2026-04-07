import 'dart:convert';
import 'package:compra_venda_perto_casa/pages/configuracoes_page.dart';
import 'package:compra_venda_perto_casa/pages/produtos_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int paginaAtual = 0;
  late PageController pc;

  @override
  void initState() {
    super.initState();
    pc = PageController(initialPage: paginaAtual);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pc.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarPagamentoAoVoltar();
    }
  }

  Future<void> _verificarPagamentoAoVoltar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pedidoId = prefs.getString('pedidoIdPendente');

      if (pedidoId == null || pedidoId.isEmpty) return;

      final response = await http.get(
        Uri.parse('http://192.168.15.2:3000/pedido/$pedidoId/status'),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (data['status'] == 'pago') {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final anuncioId = prefs.getString('anuncioId') ?? '';

        final pedidoDoc = await FirebaseFirestore.instance
            .collection('pedidos')
            .where('pedidoId', isEqualTo: pedidoId)
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (pedidoDoc.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('pedidos')
              .doc(pedidoDoc.docs.first.id)
              .update({'status': 'Pago'});
        }

        if (anuncioId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('anuncios')
              .doc(anuncioId)
              .update({'vendido': true});
        }

        await prefs.remove('pedidoIdPendente');
        await prefs.remove('produtoNome');
        await prefs.remove('produtoValor');
        await prefs.remove('anuncioId');
        await prefs.remove('enderecoId');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento aprovado com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao verificar pagamento ao voltar: $e');
    }
  }

  void setPaginaAtual(int pagina) {
    setState(() {
      paginaAtual = pagina;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pc,
        children: [
          ProdutosPage(),
          ConfiguracoesPage(),
        ],
        onPageChanged: setPaginaAtual,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: paginaAtual,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Produtos"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        onTap: (pagina) {
          pc.animateToPage(
            pagina,
            duration: const Duration(milliseconds: 400),
            curve: Curves.ease,
          );
        },
      ),
    );
  }
}