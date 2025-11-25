import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_pagamento_pix.dart';

class EscolherEnderecoPage extends StatefulWidget {
  final Map<String, dynamic> anuncio;

  const EscolherEnderecoPage({super.key, required this.anuncio});

  @override
  State<EscolherEnderecoPage> createState() => _EscolherEnderecoPageState();
}

class _EscolherEnderecoPageState extends State<EscolherEnderecoPage> {
  String? enderecoSelecionadoId;

  Stream<QuerySnapshot> _getEnderecos() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('enderecos')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher endereço de entrega'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getEnderecos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum endereço cadastrado.'),
            );
          }

          final enderecos = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: enderecos.length,
                  itemBuilder: (context, index) {
                    final doc = enderecos[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final enderecoCompleto =
                        "${data['rua']}, ${data['numero']} - ${data['bairro']}, ${data['cidade']}/${data['estado']}";

                    return RadioListTile<String>(
                      value: doc.id,
                      groupValue: enderecoSelecionadoId,
                      title: Text(enderecoCompleto),
                      subtitle: Text('CEP: ${data['cep']}'),
                      onChanged: (value) {
                        setState(() {
                          enderecoSelecionadoId = value;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: enderecoSelecionadoId == null
                      ? null
                      : () {
                          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaPagamentoPix(
                valor: (widget.anuncio['valor'] as num).toDouble(),
                descricao: widget.anuncio['nome'] ?? 'Produto sem nome',
                anuncioId: widget.anuncio['id'],
                enderecoId: enderecoSelecionadoId!,
                userId: FirebaseAuth.instance.currentUser!.uid,
              ),
            ),
          );
                        },
                  icon: const Icon(Icons.qr_code),
                  label: const Text(
                    'Ir para pagamento Pix',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
