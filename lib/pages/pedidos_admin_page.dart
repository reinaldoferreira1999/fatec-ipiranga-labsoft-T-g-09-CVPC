import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PedidosAdminPage extends StatelessWidget {
  const PedidosAdminPage({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aguardando_pagamento':
        return Colors.orange;
      case 'aprovado':
        return Colors.green;
      case 'recusado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusTexto(String status) {
    switch (status) {
      case 'aguardando_pagamento':
        return 'Aguardando pagamento';
      case 'aprovado':
        return 'Pagamento aprovado';
      case 'recusado':
        return 'Pagamento recusado';
      default:
        return 'Status desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin - Pedidos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado'));
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final doc = pedidos[index];
              final pedido = doc.data() as Map<String, dynamic>;

              final pedidoId = doc.id;
              final anuncioId = pedido['anuncioId'];

              final compradorNome = pedido['compradorNome'] ?? 'Não informado';
              final vendedorNome = pedido['vendedorNome'] ?? 'Não informado';
              final vendedorPix = pedido['vendedorPix'] ?? 'Não informado';
              final valor = (pedido['valor'] ?? 0).toDouble();
              final status = pedido['status'] ?? 'aguardando_pagamento';
              final Timestamp timestamp = pedido['criadoEm'];
              final DateTime dataHora = timestamp.toDate();
              final horaPedido = DateFormat('dd/MM/yyyy HH:mm').format(dataHora);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Pedido: $pedidoId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Valor: R\$ ${valor.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _getStatusTexto(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(),
                      
                      Text('Comprador: $compradorNome'),
                      
                      Text('Vendedor: $vendedorNome'),

                      Text('Chave PIX: $vendedorPix'),

                      Text('Hora do pedido: $horaPedido'),

                      const SizedBox(height: 10),

                      /// 🔹 Botões (só aparece se estiver aguardando)
                      if (status == 'aguardando_pagamento')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                      .collection('anuncios')
                                      .doc(anuncioId)
                                      .update({
                                        'vendido': true,
                                        'reservado': false,
                                      });

                                    await FirebaseFirestore.instance
                                      .collection('pedidos')
                                      .doc(pedidoId)
                                      .update({
                                        'status': 'aprovado',
                                      });

                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                },
                                child: const Text('Aprovar'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                      .collection('anuncios')
                                      .doc(anuncioId)
                                      .update({
                                        'reservado': false,
                                        'vendido': false,
                                      });

                                    await FirebaseFirestore.instance
                                      .collection('pedidos')
                                      .doc(pedidoId)
                                      .update({
                                        'status': 'recusado',
                                      });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                },
                                child: const Text('Recusar'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}