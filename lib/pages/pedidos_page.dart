import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  @override
  void initState() {
    super.initState();
    _sincronizarPedidosComBackend();
  }

  double _toDouble(dynamic valor) {
    if (valor is int) return valor.toDouble();
    if (valor is double) return valor;
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  Future<void> _verificarStatusPagamento(String docId, String pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.15.2:3000/pedido/$pedidoId/status'),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final statusBackend = (data['status'] ?? '').toString();

      String novoStatus = 'Pagamento pendente';

      if (statusBackend == 'pago') {
        novoStatus = 'Pago';
      } else if (statusBackend == 'aguardando_pagamento') {
        novoStatus = 'Pagamento pendente';
      } else if (statusBackend == 'nao_pago') {
        novoStatus = 'Não pago';
      }

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(docId)
          .update({'status': novoStatus});
    } catch (e) {
      debugPrint('Erro ao verificar pagamento: $e');
    }
  }

  Future<void> _sincronizarPedidosComBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        final pedido = doc.data();
        final pedidoId = (pedido['pedidoId'] ?? '').toString();

        if (pedidoId.isNotEmpty) {
          await _verificarStatusPagamento(doc.id, pedidoId);
        }
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar pedidos: $e');
    }
  }

  Future<void> _confirmarEntrega(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(docId)
          .update({'status': 'Entregue'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega confirmada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar entrega: $e')),
      );
    }
  }

  Color _corStatus(String status) {
    final s = status.toLowerCase();

    if (s == 'pago') return Colors.green;
    if (s == 'entregue') return Colors.green;
    if (s == 'pagamento pendente') return Colors.orange;
    if (s == 'não pago') return Colors.red;

    return Colors.grey;
  }

  Widget _buildTrailing(String status, String docId) {
    final statusLower = status.toLowerCase();

    if (statusLower == 'entregue') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (statusLower == 'pago') {
      return TextButton(
        onPressed: () => _confirmarEntrega(docId),
        child: const Text(
          'Confirmar entrega',
          style: TextStyle(color: Colors.green),
        ),
      );
    }

    if (statusLower == 'pagamento pendente') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Pendente',
            style: TextStyle(color: Colors.orange),
          ),
        ],
      );
    }

    if (statusLower == 'não pago') {
      return const Text(
        'Não pago',
        style: TextStyle(color: Colors.red),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atualizando pedidos...')),
          );
          await _sincronizarPedidosComBackend();
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pedidos')
              .where('userId', isEqualTo: user.uid)
              .orderBy('criadoEm', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 300),
                  Center(child: Text('Erro: ${snapshot.error}')),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: Text('Nenhum pedido realizado.')),
                ],
              );
            }

            final pedidos = snapshot.data!.docs;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final doc = pedidos[index];
                final pedido = doc.data() as Map<String, dynamic>;

                final pedidoId = (pedido['pedidoId'] ?? '').toString();
                final descricao =
                    (pedido['descricao'] ?? 'Produto sem nome').toString();
                final valor = _toDouble(pedido['valor']);
                final status = (pedido['status'] ?? 'Sem status').toString();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(descricao),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido: $pedidoId'),
                        const SizedBox(height: 4),
                        Text('R\$ ${valor.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: _corStatus(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: _buildTrailing(status, doc.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}