import 'package:flutter/material.dart';
import 'package:compra_venda_perto_casa/services/auth_service.dart';
import 'package:provider/provider.dart';

class ConfiguracoesPage extends StatefulWidget {
  ConfiguracoesPage({Key? key}) : super(key: key);

  @override
  _ConfiguracoesPageState createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: OutlinedButton(
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
      ),
	  );
  }
}