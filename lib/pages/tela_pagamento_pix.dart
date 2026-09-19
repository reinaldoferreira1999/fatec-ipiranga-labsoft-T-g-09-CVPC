import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:compra_venda_perto_casa/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaPagamentoPix extends StatelessWidget {
  final double valor;
  final String descricao;
  final String anuncioId;
  final String enderecoId;
  final String userId;

  const TelaPagamentoPix({
    super.key,
    required this.valor,
    required this.descricao,
    required this.anuncioId,
    required this.enderecoId,
    required this.userId,
  });

  Future<void> _registrarPedido(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não autenticado");

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      /// 🔹 1. PERFIL DO COMPRADOR
      final perfilSnap = await firestore
          .collection('usuario')
          .doc(uid)
          .collection('perfil')
          .doc('dados')
          .get();

      final perfil = perfilSnap.data() ?? {};
      final compradorNome = perfil['nome'] ?? '';
      final compradorTelefone = perfil['telefone'] ?? '';

      /// 🔹 2. ENDEREÇO
      final endSnap = await firestore
          .collection('usuario')
          .doc(uid)
          .collection('enderecos')
          .doc(enderecoId)
          .get();

      final end = endSnap.data() ?? {};

      final enderecoEntrega =
          "${end['rua'] ?? ''}, ${end['numero'] ?? ''} - "
          "${end['bairro'] ?? ''}, ${end['cidade'] ?? ''}/${end['estado'] ?? ''}, "
          "CEP: ${end['cep'] ?? ''} ${end['complemento'] ?? ''}";

      /// 🔹 3. DADOS DO ANÚNCIO / VENDEDOR
      final anuncioDoc =
          await firestore.collection('anuncios').doc(anuncioId).get();

      if (!anuncioDoc.exists) {
        throw Exception("Anúncio não encontrado");
      }

      final anuncioData = anuncioDoc.data()!;
      final vendedorId = anuncioData['userId'];

      final vendedorSnap = await firestore
          .collection('usuario')
          .doc(vendedorId)
          .collection('perfil')
          .doc('dados')
          .get();

      final vendedorPerfil = vendedorSnap.data() ?? {};
      final vendedorNome = vendedorPerfil['nome'] ?? '';
      final vendedorTelefone = vendedorPerfil['telefone'] ?? '';

      // ⚠️ aqui corrigi: você usava chavePix, mas no perfil é "pix"
      final vendedorPix = vendedorPerfil['pix'] ?? '';

      /// 🔥 4. TRANSACTION (RESERVA + PEDIDO)
      await firestore.runTransaction((transaction) async {
        final anuncioRef = firestore.collection('anuncios').doc(anuncioId);
        final snap = await transaction.get(anuncioRef);

        if (!snap.exists) throw Exception("Anúncio não existe");

        final data = snap.data()!;

        if (data['vendido'] == true || data['reservado'] == true) {
          throw Exception("Produto indisponível");
        }

        // 🔒 RESERVA
        transaction.update(anuncioRef, {
          'reservado': true,
        });

        // 🧾 CRIA PEDIDO COMPLETO
        final pedidoRef = firestore.collection('pedidos').doc();

        transaction.set(pedidoRef, {
          'userId': uid,
          'anuncioId': anuncioId,
          'enderecoId': enderecoId,
          'valor': valor,
          'descricao': descricao,
          'status': 'aguardando_pagamento',
          'criadoEm': Timestamp.now(),

          // 🔽 DADOS IMPORTANTES
          'compradorNome': compradorNome,
          'compradorTelefone': compradorTelefone,
          'enderecoEntrega': enderecoEntrega,

          'vendedorId': vendedorId,
          'vendedorNome': vendedorNome,
          'vendedorTelefone': vendedorTelefone,
          'vendedorPix': vendedorPix,
        });
      });

      /// 🔹 5. SUCESSO
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.SUCESSO,
          arguments: {
            'descricao': descricao,
            'valor': valor,
            'enderecoId': enderecoId,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar compra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const String codigoPixFixo =
        '00020101021126580014br.gov.bcb.pix013625eda7d3-99c4-4880-b0ec-2c8850f218145204000053039865802BR5925REINALDO FERREIRA PAES SA6009SAO PAULO622905251K9WY91EBS23Y9JPK256PT4PN6304704B';

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via Pix')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Escaneie o QR Code abaixo e pague o valor de R\$ ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              valor.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: codigoPixFixo,
              version: QrVersions.auto,
              size: 250,
            ),
            const SizedBox(height: 20),
            SelectableText(
              codigoPixFixo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _registrarPedido(context),
              icon: const Icon(Icons.check),
              label: const Text('Já realizei o pagamento'),
            ),
          ],
        ),
      ),
    );
  }
}