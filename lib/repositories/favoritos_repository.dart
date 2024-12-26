import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:compra_venda_perto_casa/models/produto.dart';

class FavoritosRepository extends ChangeNotifier {
  List<Produto> _lista = [];

  UnmodifiableListView<Produto> get lista => UnmodifiableListView(_lista);

  saveAll(List<Produto> produtos) {
    produtos.forEach((produto) {
      if (!_lista.contains(produto)) _lista.add(produto);
    });
    notifyListeners();
  }

  remove(Produto produto) {
    _lista.remove(produto);
    notifyListeners();
  }
}