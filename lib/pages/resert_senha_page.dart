import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SenhaPage extends StatefulWidget {
  @override
  _SenhaPageState createState() => _SenhaPageState();
}

class _SenhaPageState extends State<SenhaPage> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email de recuperação enviado!")),
      );

      Navigator.of(context).pop(); // volta pra tela de login
    } on FirebaseAuthException catch (e) {
      String msg = "Erro ao enviar email.";
      if (e.code == 'user-not-found') {
        msg = "Nenhum usuário encontrado com esse email.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recuperar Senha")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Informe seu email para redefinir a senha",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Digite seu email" : null,
              ),
              SizedBox(height: 20),
              Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          resetPassword();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Recuperar Senha',
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
      ),
    );
  }
}