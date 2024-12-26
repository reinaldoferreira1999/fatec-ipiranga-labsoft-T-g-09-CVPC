import 'package:compra_venda_perto_casa/models/produto.dart';
import 'package:compra_venda_perto_casa/repositories/favoritos_repository.dart';
import 'package:flutter/material.dart';
import 'package:compra_venda_perto_casa/repositories/produto_repository.dart';
import 'package:intl/intl.dart';
import 'package:compra_venda_perto_casa/pages/produtos_detalhe_page.dart';
import 'package:provider/provider.dart';

class ProdutosPage extends StatefulWidget {
  ProdutosPage({Key? key}) : super(key: key);

  @override
  _ProdutosPageState createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final tabela = ProdutoRepository.tabela;
  NumberFormat real = NumberFormat.currency(locale: 'pt_BR', name: 'R\$');
  List<Produto> selecionadas = [];
  late FavoritosRepository favoritas;

  appBarDinamica() {
    if (selecionadas.isEmpty) {
      return AppBar(
        title: Text('Produtos'),
      );
    } else {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            limparSelecionadas();
          },
        ),
        title: Text('${selecionadas.length} selecionadas'),
        backgroundColor: Colors.deepPurple[50],
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      );
    }
  }

  mostrarDetalhes(Produto produto) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProdotosDetalhePage(produto: produto),
        ));
  }

  limparSelecionadas() {
    setState(() {
      selecionadas = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    favoritas = context.watch<FavoritosRepository>();

    return Scaffold(
      appBar: appBarDinamica(),
      body: ListView.separated(
          itemBuilder: (BuildContext context, int produto) {
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              leading: (selecionadas.contains(tabela[produto]))
                  ? CircleAvatar(
                      child: Icon(Icons.check),
                    )
                  : SizedBox(
                      child: Image.asset(tabela[produto].foto),
                      width: 40,
                    ),
              title: Row(
                children: [
                  Text(
                    tabela[produto].nome,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (favoritas.lista.contains(tabela[produto]))
                    Icon(Icons.circle, color: Colors.amber, size: 8),
                ],
              ),
              trailing: Text(
                real.format(tabela[produto].preco),
                style: TextStyle(fontSize: 15),
              ),
              selected: selecionadas.contains(tabela[produto]),
              selectedTileColor: Colors.indigo[50],
              onLongPress: () {
                setState(() {
                  (selecionadas.contains(tabela[produto]))
                      ? selecionadas.remove(tabela[produto])
                      : selecionadas.add(tabela[produto]);
                });
              },
              onTap: () => mostrarDetalhes(tabela[produto]),
            );
          },
          padding: EdgeInsets.all(16),
          separatorBuilder: (_, ___) => Divider(),
          itemCount: tabela.length,
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selecionadas.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                favoritas.saveAll(selecionadas);
                limparSelecionadas();
              },
              icon: Icon(Icons.star),
              label: Text(
                'Favoritar',
                style: TextStyle(
                  letterSpacing: 0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
