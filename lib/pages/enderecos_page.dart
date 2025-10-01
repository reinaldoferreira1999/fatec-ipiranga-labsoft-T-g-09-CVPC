import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EnderecosPage extends StatefulWidget {
  const EnderecosPage({super.key});

  @override
  State<EnderecosPage> createState() => _EnderecosPageState();
}

class _EnderecosPageState extends State<EnderecosPage> {
  bool mostrarCampoEndereco = false;
  String? idEnderecoEdicao;

  final _formKey = GlobalKey<FormState>();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  /*void _toggleCampoEndereco() {
    setState(() {
      mostrarCampoEndereco = !mostrarCampoEndereco;
    });
  }*/

  Future<void> buscarEndereco(String cep) async {
    final uri = Uri.parse("https://viacep.com.br/ws/$cep/json/");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dados = json.decode(response.body);

      if (dados.containsKey('erro')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("CEP não encontrado")),
        );
        return;
      }

      setState(() {
        _ruaController.text = dados['logradouro'] ?? '';
        _bairroController.text = dados['bairro'] ?? '';
        _cidadeController.text = dados['localidade'] ?? '';
        _estadoController.text = dados['uf'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao buscar CEP")),
      );
    }
  }

  Future<void> _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final enderecoRef = FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('enderecos');
    if (idEnderecoEdicao == null) {
      // Criar novo
      await enderecoRef.add({
        'cep': _cepController.text.trim(),
        'rua': _ruaController.text.trim(),
        'numero': _numeroController.text.trim(),
        'complemento': _complementoController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim(),
        // ... outros campos
        'criadoEm': Timestamp.now(),
      });
    } else {
      // Editar existente
      await enderecoRef.doc(idEnderecoEdicao).update({
        'cep': _cepController.text.trim(),
      'rua': _ruaController.text.trim(),
      'numero': _numeroController.text.trim(),
      'complemento': _complementoController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'estado': _estadoController.text.trim(),
        // ... outros campos
      });
    }

// Resetar estado
    setState(() {
      idEnderecoEdicao = null;
      mostrarCampoEndereco = false;
    });

    _formKey.currentState!.reset();
    setState(() {
      mostrarCampoEndereco = false;
    });

    Navigator.pop(context); // Volta para a tela anterior após salvar
  }

  Stream<QuerySnapshot> getEnderecosStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('enderecos')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<void> apagarEndereco(String enderecoId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('enderecos')
        .doc(enderecoId)
        .delete();
  }

  void editarEndereco(String id, Map<String, dynamic> dados) {
    setState(() {
      mostrarCampoEndereco = true; // Exibe o formulário
      idEnderecoEdicao = id; // Salva o ID do endereço que será editado

      // Preenche os controladores com os dados existentes
      _cepController.text = dados['cep'] ?? '';
      _ruaController.text = dados['rua'] ?? '';
      _numeroController.text = dados['numero'] ?? '';
      _complementoController.text = dados['complemento'] ?? '';
      _bairroController.text = dados['bairro'] ?? '';
      _cidadeController.text = dados['cidade'] ?? '';
      _estadoController.text = dados['estado'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meus Endereços')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    mostrarCampoEndereco = !mostrarCampoEndereco;
                  });
                },
                icon: Icon(mostrarCampoEndereco ? Icons.close : Icons.add,
                    color: Colors.deepPurple),
                label: Text(
                  mostrarCampoEndereco ? 'Cancelar' : 'Adicionar novo endereço',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.deepPurple,
                      width: 3.5), // Borda roxa e mais grossa
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Arredondamento
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: 16, horizontal: 81), // Espaçamento interno
                ),
              ),

              if (mostrarCampoEndereco) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      campo(_cepController, 'CEP', isCep: true),
                      campo(_ruaController, 'Rua'),
                      campo(_numeroController, 'Número'),
                      campo(_complementoController, 'Complemento'),
                      campo(_bairroController, 'Bairro'),
                      campo(_cidadeController, 'Cidade'),
                      campo(_estadoController, 'Estado'),
                      SizedBox(height: 10),
                      Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.only(top: 24),
                        child: ElevatedButton(
                          onPressed: _salvarEndereco,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Salvar',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 30),
              ],

              // Lista de endereços salvos
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Meus Endereços:', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: getEnderecosStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return CircularProgressIndicator();

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return Text('Nenhum endereço cadastrado.');

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final endereco =
                          docs[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          //title: Text(endereco['destinatario'] ?? 'Sem nome'),
                          subtitle: Text(
                            '${endereco['rua'] ?? ''}, ${endereco['numero'] ?? ''}\n'
                            '${endereco['complemento'] ?? ''}\n'
                            '${endereco['bairro'] ?? ''} - ${endereco['cidade'] ?? ''}/${endereco['estado'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  editarEndereco(docs[index].id, docs[index].data() as Map<String, dynamic>);
                                },
                              ),
    
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  apagarEndereco(docs[index].id);
                                },
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
      ),
    );
  }

  Widget campo(TextEditingController controller, String label, {bool isCep = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isCep ? TextInputType.number : TextInputType.text,
        onChanged: (value) {
          if (isCep && value.length == 8) {
            buscarEndereco(value);
          }
        },
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}