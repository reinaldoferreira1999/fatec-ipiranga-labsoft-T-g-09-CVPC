import 'package:compra_venda_perto_casa/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:compra_venda_perto_casa/services/auth_service.dart';
import 'package:provider/provider.dart';

class ConfiguracoesPage extends StatefulWidget {
  ConfiguracoesPage({Key? key}) : super(key: key);

  @override
  _ConfiguracoesPageState createState() => _ConfiguracoesPageState();
}

//void _onProfileButtonPressed() {}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.person),
              iconSize: 50.0,
              onPressed: () => {Navigator.of(context).pushNamed(AppRoutes.PERFIL)},
              tooltip: 'Perfil',
            ),

            OutlinedButton(
              onPressed: () => {
                Navigator.of(context).pushNamed(AppRoutes.ANUNCIOS),
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Meus Anúncios',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: () => {
                Navigator.of(context).pushNamed(AppRoutes.PEDIDOS),
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Meus Pedidos',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: () => {
                Navigator.of(context).pushNamed(AppRoutes.ENDERECOS),
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Meus Endereços',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: () => context.read<AuthService>().logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Sair do App',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
