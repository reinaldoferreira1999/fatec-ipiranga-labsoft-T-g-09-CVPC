import 'package:compra_venda_perto_casa/models/produto.dart';
import 'package:compra_venda_perto_casa/pages/produtos_detalhe_page.dart';
import 'package:compra_venda_perto_casa/repositories/favoritos_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProdutoCard extends StatefulWidget {
  Produto produto;

  ProdutoCard({Key? key, required this.produto}) : super(key: key);

  @override
  _ProdutoCardState createState() => _ProdutoCardState();
}

class _ProdutoCardState extends State<ProdutoCard> {
  NumberFormat real = NumberFormat.currency(locale: 'pt_BR', name: 'R\$');

  static Map<String, Color> precoColor = <String, Color>{
    'up': Colors.teal,
    'down': Colors.indigo,
  };

  abrirDetalhes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdotosDetalhePage(produto: widget.produto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => abrirDetalhes(),
        child: Padding(
          padding: EdgeInsets.only(top: 20, bottom: 20, left: 20),
          child: Row(
            children: [
              Image.asset(
                widget.produto.foto,
                height: 40,
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produto.nome,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.produto.nome,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: precoColor['down']!.withOpacity(0.05),
                  border: Border.all(
                    color: precoColor['down']!.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  real.format(widget.produto.preco),
                  style: TextStyle(
                    fontSize: 16,
                    color: precoColor['down'],
                    letterSpacing: -1,
                  ),
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      title: Text('Remover das Favoritas'),
                      onTap: () {
                        Navigator.pop(context);
                        Provider.of<FavoritosRepository>(context, listen: false)
                            .remove(widget.produto);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
