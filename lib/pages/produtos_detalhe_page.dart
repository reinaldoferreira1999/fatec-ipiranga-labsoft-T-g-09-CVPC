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
    );
  }
}