import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AnunciosPage extends StatefulWidget {
  const AnunciosPage({super.key});

  @override
  State<AnunciosPage> createState() => _AnunciosPageState();
}

class _AnunciosPageState extends State<AnunciosPage> {
  bool mostrarCampoProduto = false;
  String? idProdutoEdicao;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  File? _imagemSelecionada;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() => _imagemSelecionada = File(imagem.path));
    }
  }

  Future<String?> _uploadImagem(String anuncioId) async {
    if (_imagemSelecionada == null) return null;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('usuario')
        .child(uid)
        .child('anuncios')
        .child('$anuncioId.jpg');

    await storageRef.putFile(_imagemSelecionada!);
    return storageRef.getDownloadURL();
  }

  String gerarCodigo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'PROD-$now';
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final produtoRef = FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('anuncios');

    if (idProdutoEdicao == null) {
      final codigo = gerarCodigo();
      final docRef = await produtoRef.doc();

      await docRef.set({
        'codigo': codigo,
        'nome': _nomeController.text.trim(),
        'valor': double.tryParse(_valorController.text.trim()) ?? 0,
        'descricao': _descricaoController.text.trim(),
        'criadoEm': Timestamp.now(),
      });

      final url = await _uploadImagem(docRef.id);
      if (url != null) {
        await docRef.update({'imagemUrl': url});
      }
    } else {
      // Editar existente
      await produtoRef.doc(idProdutoEdicao).update({
        'nome': _nomeController.text.trim(),
        'valor': double.tryParse(_valorController.text.trim()) ?? 0,
        'descricao': _descricaoController.text.trim(),
      });

      if (_imagemSelecionada != null) {
        final url = await _uploadImagem(idProdutoEdicao!);
        if (url != null) {
          await produtoRef.doc(idProdutoEdicao).update({'imagemUrl': url});
        }
      }
      Navigator.pop(context);
    }

    // Resetar estado
    setState(() {
      idProdutoEdicao = null;
      mostrarCampoProduto = false;
      _imagemSelecionada = null;
    });
    _formKey.currentState!.reset();
  }

  Stream<QuerySnapshot> getProdutosStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('anuncios')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<void> apagarProduto(String produtoId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('anuncios')
        .doc(produtoId)
        .delete();
  }

  void editarProduto(String id, Map<String, dynamic> dados) {
    setState(() {
      mostrarCampoProduto = true;
      idProdutoEdicao = id;
      _nomeController.text = dados['nome'] ?? '';
      _valorController.text = dados['valor']?.toString() ?? '';
      _descricaoController.text = dados['descricao'] ?? '';
      _imagemSelecionada = null; // não carregamos a imagem local aqui
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Anúncios')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() => mostrarCampoProduto = !mostrarCampoProduto);
              },
              icon: Icon(
                mostrarCampoProduto ? Icons.close : Icons.add,
                color: Colors.deepPurple,
              ),
              label: Text(
                mostrarCampoProduto ? 'Cancelar' : 'Adicionar novo produto',
                style: const TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple, width: 3.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
              ),
            ),
            if (mostrarCampoProduto) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    campo(_nomeController, 'Nome do produto'),
                    campo(_valorController, 'Valor', isNumber: true),
                    campo(_descricaoController, 'Descrição'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _selecionarImagem,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imagemSelecionada == null
                            ? const Center(
                                child: Text('Toque para selecionar imagem'),
                              )
                            : Image.file(_imagemSelecionada!,
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _salvarProduto,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Text('Salvar', style: TextStyle(fontSize: 20)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child:
                  const Text('Meus Produtos:', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: getProdutosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Nenhum produto cadastrado.');
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final produto = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: produto['imagemUrl'] != null
                            ? Image.network(produto['imagemUrl'],
                                width: 56, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                        title: Text('${produto['codigo'] ?? ''} \n ${produto['nome'] ?? 'Sem nome'}'),
                        subtitle: Text(
                          'R\$ ${produto['valor']?.toStringAsFixed(2) ?? '0.00'}\n'
                          '${produto['descricao'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editarProduto(docs[index].id,
                                  docs[index].data() as Map<String, dynamic>),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => apagarProduto(docs[index].id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget campo(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}
