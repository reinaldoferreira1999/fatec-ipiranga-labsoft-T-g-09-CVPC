import 'package:compra_venda_perto_casa/models/produto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProdotosDetalhePage extends StatefulWidget {
  Produto produto;

  ProdotosDetalhePage({Key? key, required this.produto}) : super(key: key);

  @override
  _ProdotosDetalhePageState createState() => _ProdotosDetalhePageState();
}

class _ProdotosDetalhePageState extends State<ProdotosDetalhePage> {
  NumberFormat real = NumberFormat.currency(locale: 'pt_BR', name: 'R\$');

  comprar(){}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto.nome),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: Image.asset(widget.produto.foto),
                    width: 50,
                  ),
                  Container(width: 10),
                  Text(
                    real.format(widget.produto.preco),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: comprar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Comprar',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ), 
      )
    );
  }
}