import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {

  Future<void> _confirmarEntrega(String pedidoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({
        'status': 'entregue',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega confirmada com sucesso!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar entrega: $e'),
        ),
      );
    }
  }

  String statusFormatado(String status) {
    switch (status) {
      case 'aguardando_pagamento':
        return 'Aguardando pagamento';

      case 'aprovado':
        return 'Pagamento aprovado';

      case 'recusado':
        return 'Pagamento recusado';

      case 'entregue':
        return 'Entrega confirmada';

      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Pedidos"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('userId', isEqualTo: uid)
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Nenhum pedido realizado."),
            );
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {

              final doc = pedidos[index];

              final pedido = doc.data() as Map<String, dynamic>;

              final descricao =
                  pedido['descricao'] ?? 'Produto sem nome';

              final valor =
                  (pedido['valor'] ?? 0).toDouble();

              final status =
                  pedido['status'] ?? '';

              final bool aprovado =
                  status == 'aprovado';

              final bool entregue =
                  status == 'entregue';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.shopping_bag_outlined,
                  ),

                  title: Text(descricao),

                  subtitle: Text(
                    'R\$ ${valor.toStringAsFixed(2)}\n'
                    'Status: ${statusFormatado(status)}',
                  ),

                  isThreeLine: true,

                  trailing: entregue
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Entrega confirmada',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )

                      : aprovado
                          ? ElevatedButton(
                              onPressed: () =>
                                  _confirmarEntrega(doc.id),

                              child: const Text(
                                'Confirmar entrega',
                              ),
                            )

                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}