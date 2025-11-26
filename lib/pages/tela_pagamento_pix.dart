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

      // 1️⃣ Buscar dados do perfil (nome, telefone)
      final perfilSnap = await FirebaseFirestore.instance
          .collection('usuario')
          .doc(uid)
          .collection('perfil')
          .doc('dados')
          .get();

      final perfil = perfilSnap.data() ?? {};
      final compradorNome = perfil['nome'] ?? '';
      final compradorTelefone = perfil['telefone'] ?? '';

      final endSnap = await FirebaseFirestore.instance
          .collection('usuario')
          .doc(uid)
          .collection('enderecos')
          .doc(enderecoId)
          .get();

      final end = endSnap.data() ?? {};
      final rua = end['rua'] ?? '';
      final numero = end['numero'] ?? '';
      final bairro = end['bairro'] ?? '';
      final cidade = end['cidade'] ?? '';
      final estado = end['estado'] ?? '';
      final cep = end['cep'] ?? '';
      final complemento = end['complemento'] ?? '';

      final enderecoEntrega =
          '$rua, $numero - $bairro, $cidade/$estado, CEP: $cep, $complemento';

      // 3️⃣ Criar o pedido no Firestore com endereço e dados do comprador
      await FirebaseFirestore.instance.collection('pedidos').add({
        'userId': uid,
        'anuncioId': anuncioId,
        'enderecoId': enderecoId,
        'enderecoEntrega': enderecoEntrega,
        'compradorNome': compradorNome,
        'compradorTelefone': compradorTelefone,
        'valor': valor,
        'descricao': descricao,
        'status': 'Realizado',
        'criadoEm': Timestamp.now(),
      });

      // 4️⃣ Marcar anúncio como vendido
      await FirebaseFirestore.instance
          .collection('anuncios')
          .doc(anuncioId)
          .update({'vendido': true});

      // 5️⃣ Ir para tela de sucesso
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