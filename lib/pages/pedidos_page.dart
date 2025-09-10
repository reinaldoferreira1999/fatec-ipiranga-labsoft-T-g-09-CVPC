import 'package:flutter/material.dart';

class PedidosPage extends StatefulWidget {
  /*Produto produto;

  AnunciosPage({Key? key, required this.produto}) : super(key: key);*/

  @override
  _PedidosPageState createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meus Pedidos"),
      ),
    );
  }
}