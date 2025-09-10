import 'package:flutter/material.dart';
import 'package:validadores/Validador.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();

  Future<void> _salvarDadosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('perfil')
        .doc('dados')
        .set({
      'nome': _nome.text,
      'cpf': _cpf.text,
      'telefone': _telefone.text,
      'email': _email.text,
    });
    Navigator.pop(context);
  }

  Future<void> carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuario')
          .doc(user.uid)
          .collection('perfil')
          .doc('dados')
          .get();
      if (doc.exists) {
        _nome.text = doc.data()?['nome'] ?? '';
        _cpf.text = doc.data()?['cpf'] ?? '';
        _telefone.text = doc.data()?['telefone'] ?? '';
        _email.text = doc.data()?['email'] ?? '';
      }
    }
  }

  Future<void> atualizarDados() async {
    if (_formKey.currentState!.validate()) {
      await _salvarDadosUsuario();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados atualizados com sucesso!')));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> excluirPerfil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final perfilRef = FirebaseFirestore.instance
        .collection('usuario')
        .doc(uid)
        .collection('perfil');

    final snapshot = await perfilRef.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Perfil excluído com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Perfil"),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _nome,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Nome Completo",
                      labelStyle: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null) {
                        return "O nome não pode ser vazio";
                      }
                      if (value.length < 5) {
                        return "Digite o nome completo";
                      }
                      if (!value.contains(" ")) {
                        return "Digite o nome completo";
                      }
                      return null;
                    },
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  TextFormField(
                    controller: _cpf,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "CPF",
                      labelStyle: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                    ),
                    validator: (value) {
                      return Validador()
                          .add(Validar.CPF, msg: 'CPF Inválido')
                          .add(Validar.OBRIGATORIO, msg: 'Campo obrigatório')
                          .minLength(11)
                          .maxLength(11)
                          .valido(value, clearNoNumber: true);
                    },
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  TextFormField(
                    controller: _telefone,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Celular",
                      labelStyle: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null) {
                        return "O celular não pode ser vazio";
                      }
                      if (value.length < 11 || value.length > 11) {
                        return "Número inválido";
                      }
                      return null;
                    },
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  TextFormField(
                    controller: _email, // troque pelo seu controller de e-mail
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-mail",
                      labelStyle: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return "O e-mail não pode ser vazio";
                      }
                      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return "E-mail inválido";
                      }

                      return null;
                    },
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),

                  Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: _salvarDadosUsuario,
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
                  Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: excluirPerfil,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Excluir',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
        ));
  }
}
