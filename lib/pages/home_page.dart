import 'package:compra_venda_perto_casa/pages/configuracoes_page.dart';
import 'package:compra_venda_perto_casa/pages/produtos_page.dart';
import 'package:compra_venda_perto_casa/pages/pedidos_admin_page.dart'; // 👈 IMPORTANTE
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paginaAtual = 0;
  late PageController pc;

  bool isAdmin = false; // 👈 controla se é admin

  @override
  void initState() {
    super.initState();
    pc = PageController(initialPage: paginaAtual);
    verificarAdmin(); // 👈 chama aqui
  }

  Future<void> verificarAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuario')
        .doc(user.uid)
        .get();

    final admin = doc.data()?['role'] == 'admin';

    setState(() {
      isAdmin = admin;
    });
  }

  setPaginaAtual(pagina) {
    setState(() {
      paginaAtual = pagina;
    });
  }

  @override
  Widget build(BuildContext context) {

    // 🔹 Lista de páginas dinâmica
    final paginas = [
      ProdutosPage(),
      ConfiguracoesPage(),
      if (isAdmin) const PedidosAdminPage(), // 👈 só aparece se admin
    ];

    // 🔹 Itens do menu
    final itens = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: "Produtos",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Configurações',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    return Scaffold(
      body: PageView(
        controller: pc,
        children: paginas,
        onPageChanged: setPaginaAtual,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: paginaAtual,
        items: itens,
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