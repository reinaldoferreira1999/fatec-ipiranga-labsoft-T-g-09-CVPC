import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class AnunciosPage extends StatefulWidget {
  const AnunciosPage({super.key});

  @override
  State<AnunciosPage> createState() => _AnunciosPageState();
}

class _AnunciosPageState extends State<AnunciosPage> {
  bool mostrarCampoProduto = false;
  String? idProdutoEdicao;
  bool _salvando = false;
  bool _buscandoCep = false;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _cepController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  File? _imagemSelecionada;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    _cepController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() => _imagemSelecionada = File(imagem.path));
    }
  }

  Future<String?> _uploadImagem(String anuncioId) async {
    if (_imagemSelecionada == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('anuncios')
        .child('$anuncioId.jpg');

    await storageRef.putFile(_imagemSelecionada!);
    return storageRef.getDownloadURL();
  }

  String gerarCodigo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'PROD-$now';
  }

  double _parseValor(String texto) {
    final normalizado = texto.trim().replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0.0;
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP deve ter 8 dígitos numéricos')),
      );
      return;
    }

    try {
      setState(() => _buscandoCep = true);

      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);

        if (dados['erro'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CEP não encontrado')),
          );
          return;
        }

        setState(() {
          _bairroController.text = dados['bairro'] ?? '';
          _cidadeController.text = dados['localidade'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar CEP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _buscandoCep = false);
      }
    }
  }

  Future<Location?> _getLatLngFromCep() async {
    try {
      final cep = _cepController.text.trim();
      final bairro = _bairroController.text.trim();
      final cidade = _cidadeController.text.trim();

      final partes = [cep, bairro, cidade, 'Brasil']
          .where((e) => e.isNotEmpty)
          .join(', ');

      if (partes.isEmpty) return null;

      final locations = await locationFromAddress(partes);

      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      debugPrint('Erro ao converter endereço em coordenadas: $e');
    }
    return null;
  }

  void _limparFormulario() {
    _formKey.currentState?.reset();
    _nomeController.clear();
    _valorController.clear();
    _descricaoController.clear();
    _cepController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    _imagemSelecionada = null;
    idProdutoEdicao = null;
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _salvando = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final anunciosRef = FirebaseFirestore.instance.collection('anuncios');

      final nomeOriginal = _nomeController.text.trim();
      final nomeLower = nomeOriginal.toLowerCase();
      final valor = _parseValor(_valorController.text);
      final descricao = _descricaoController.text.trim();
      final cep = _cepController.text.trim();
      final bairro = _bairroController.text.trim();
      final cidade = _cidadeController.text.trim();

      final location = await _getLatLngFromCep();
      final double? latitude = location?.latitude;
      final double? longitude = location?.longitude;

      if (idProdutoEdicao == null) {
        final codigo = gerarCodigo();

        final docRef = await anunciosRef.add({
          'nome': nomeOriginal,
          'nomeLower': nomeLower,
          'userId': uid,
          'codigo': codigo,
          'valor': valor,
          'descricao': descricao,
          'criadoEm': FieldValue.serverTimestamp(),
          'vendido': false,
          'cep': cep,
          'bairro': bairro,
          'cidade': cidade,
          'latitude': latitude,
          'longitude': longitude,
        });

        final url = await _uploadImagem(docRef.id);
        if (url != null) {
          await docRef.update({'imagemUrl': url});
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
      } else {
        final updateData = {
          'nome': nomeOriginal,
          'nomeLower': nomeLower,
          'valor': valor,
          'descricao': descricao,
          'cep': cep,
          'bairro': bairro,
          'cidade': cidade,
          'latitude': latitude,
          'longitude': longitude,
        };

        await anunciosRef.doc(idProdutoEdicao!).update(updateData);

        if (_imagemSelecionada != null) {
          final url = await _uploadImagem(idProdutoEdicao!);
          if (url != null) {
            await anunciosRef.doc(idProdutoEdicao!).update({'imagemUrl': url});
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
      }

      setState(() {
        mostrarCampoProduto = false;
        _limparFormulario();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar produto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Stream<QuerySnapshot> getTodosAnunciosStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('anuncios')
        .where('userId', isEqualTo: uid)
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<void> apagarProduto(String produtoId) async {
    await FirebaseFirestore.instance
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
      _cepController.text = dados['cep'] ?? '';
      _bairroController.text = dados['bairro'] ?? '';
      _cidadeController.text = dados['cidade'] ?? '';
      _imagemSelecionada = null;
    });
  }

  Future<Map<String, dynamic>?> _buscarUltimoPedidoDoAnuncio(
    String anuncioId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('anuncioId', isEqualTo: anuncioId)
        .orderBy('criadoEm', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
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
                setState(() {
                  if (mostrarCampoProduto) {
                    _limparFormulario();
                  }
                  mostrarCampoProduto = !mostrarCampoProduto;
                });
              },
              icon: Icon(
                mostrarCampoProduto ? Icons.close : Icons.add,
                color: Colors.deepPurple,
              ),
              label: Text(
                mostrarCampoProduto ? 'Cancelar' : 'Adicionar novo produto',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple, width: 3.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 60,
                ),
              ),
            ),
            if (mostrarCampoProduto) ...[
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    campo(_nomeController, 'Nome do produto'),
                    campo(_valorController, 'Valor', isNumber: true),
                    campo(_descricaoController, 'Descrição'),
                    campo(_cepController, 'CEP', isNumber: true),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _buscandoCep ? null : _buscarCep,
                        child: Text(
                          _buscandoCep
                              ? 'Buscando CEP...'
                              : 'Buscar endereço pelo CEP',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        labelText: 'Bairro',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
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
                            : Image.file(
                                _imagemSelecionada!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvarProduto,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _salvando ? 'Salvando...' : 'Salvar',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Meus Produtos:',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: getTodosAnunciosStream(),
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
                    final doc = docs[index];
                    final produto = doc.data() as Map<String, dynamic>;
                    final anuncioId = doc.id;
                    final vendido = produto['vendido'] == true;

                    double valor = 0.0;
                    if (produto['valor'] is int) {
                      valor = (produto['valor'] as int).toDouble();
                    } else if (produto['valor'] is double) {
                      valor = produto['valor'] as double;
                    } else if (produto['valor'] is String) {
                      valor = double.tryParse(produto['valor']) ?? 0.0;
                    }

                    final Widget leadingWidget = produto['imagemUrl'] != null
                        ? Image.network(
                            produto['imagemUrl'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported);

                    final Widget titleWidget = Text(
                      '${produto['codigo'] ?? ''}\n${produto['nome'] ?? 'Sem nome'}',
                    );

                    final List<Widget> subtitleChildren = [
                      Text(
                        'R\$ ${valor.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(produto['descricao'] ?? ''),
                      if ((produto['bairro'] ?? '').toString().isNotEmpty ||
                          (produto['cidade'] ?? '').toString().isNotEmpty)
                        Text(
                          '${produto['bairro'] ?? ''} - ${produto['cidade'] ?? ''}',
                        ),
                      if (vendido)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '⚠️ Produto vendido',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ];

                    final ListTile baseTile = ListTile(
                      leading: leadingWidget,
                      title: titleWidget,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: subtitleChildren,
                      ),
                      isThreeLine: true,
                      trailing: vendido
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => editarProduto(
                                    anuncioId,
                                    produto,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => apagarProduto(anuncioId),
                                ),
                              ],
                            ),
                    );

                    if (!vendido) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: baseTile,
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: _buscarUltimoPedidoDoAnuncio(anuncioId),
                        builder: (context, snapPedido) {
                          if (snapPedido.connectionState ==
                              ConnectionState.waiting) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                baseTile,
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(),
                                ),
                              ],
                            );
                          }

                          final pedido = snapPedido.data;
                          final compradorNome =
                              (pedido != null &&
                                      pedido['compradorNome'] != null)
                                  ? pedido['compradorNome'] as String
                                  : 'Comprador não identificado';

                          final compradorTelefone =
                              (pedido != null &&
                                      pedido['compradorTelefone'] != null)
                                  ? pedido['compradorTelefone'] as String
                                  : 'Telefone não informado';

                          final enderecoEntrega =
                              (pedido != null &&
                                      pedido['enderecoEntrega'] != null)
                                  ? pedido['enderecoEntrega'] as String
                                  : 'Endereço não disponível';

                          final List<Widget> soldSubtitle = [
                            ...subtitleChildren,
                            const SizedBox(height: 8),
                            const Divider(),
                            Text(
                              'Comprador: $compradorNome',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('Telefone: $compradorTelefone'),
                            const SizedBox(height: 4),
                            const Text(
                              'Endereço de entrega:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(enderecoEntrega),
                          ];

                          return ListTile(
                            leading: leadingWidget,
                            title: titleWidget,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: soldSubtitle,
                            ),
                            isThreeLine: true,
                          );
                        },
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

  Widget campo(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo obrigatório';
          }

          if (label == 'Valor') {
            final valor = value.trim().replaceAll(',', '.');
            if (double.tryParse(valor) == null) {
              return 'Digite um valor válido';
            }
          }

          return null;
        },
      ),
    );
  }
}