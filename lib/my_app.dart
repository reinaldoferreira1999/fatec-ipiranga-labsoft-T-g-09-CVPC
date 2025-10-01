import 'package:compra_venda_perto_casa/pages/anuncios_page.dart';
import 'package:compra_venda_perto_casa/pages/enderecos_page.dart';
import 'package:compra_venda_perto_casa/pages/pedidos_page.dart';
import 'package:compra_venda_perto_casa/pages/perfil_page.dart';
import 'package:compra_venda_perto_casa/pages/resert_senha_page.dart';
import 'package:compra_venda_perto_casa/routes/app_routes.dart';
import 'package:compra_venda_perto_casa/widgets/auth_check.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CVPC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, 
      ),
      home: AuthCheck(),
      routes: {
        AppRoutes.ANUNCIOS:(_) => AnunciosPage(),
        AppRoutes.PEDIDOS:(_) => PedidosPage(),
        AppRoutes.ENDERECOS: (_) => EnderecosPage(),
        AppRoutes.PERFIL: (_) => PerfilPage(),
        AppRoutes.SENHA: (_) => SenhaPage(),
      },
    );
  }
}