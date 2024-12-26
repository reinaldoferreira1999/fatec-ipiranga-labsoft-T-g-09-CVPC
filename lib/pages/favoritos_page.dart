import 'package:compra_venda_perto_casa/widgets/produto_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:compra_venda_perto_casa/repositories/favoritos_repository.dart';

class FavoritosPage extends StatefulWidget {
  FavoritosPage({Key? key}) : super(key: key);

  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(12.0),
        child: Consumer<FavoritosRepository>(
          builder: (context, favoritas, child) {
            return favoritas.lista.isEmpty
                ? ListTile(
                    leading: Icon(Icons.star),
                    title: Text('Ainda não há moedas favoritas'),
                  )
                : ListView.builder(
                    itemCount: favoritas.lista.length,
                    itemBuilder: (_, index) {
                      return ProdutoCard(produto: favoritas.lista[index]);
                    },
                  );
          },
        ),
      ),
    );
  }
}
