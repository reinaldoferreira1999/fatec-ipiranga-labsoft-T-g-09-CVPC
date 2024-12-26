import 'package:compra_venda_perto_casa/models/produto.dart';

class ProdutoRepository {
  static List<Produto> tabela = [
    Produto(
      nome: 'PS5', 
      foto: 'images/PS5.jpg', 
      descricao: 'PS5 pouco usado', 
      preco: 2800.00),

    Produto(
      nome: 'PS5 Pro', 
      foto: 'images/ps5_pro.jpg', 
      descricao: 'PS5 PRO pouco usado', 
      preco: 6000.00),
  ];
}
