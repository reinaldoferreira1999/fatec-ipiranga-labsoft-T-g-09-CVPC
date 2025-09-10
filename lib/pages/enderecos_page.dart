import 'package:flutter/material.dart';

class EnderecosPage extends StatefulWidget {
  const EnderecosPage({super.key});

  @override
  State<EnderecosPage> createState() => _EnderecosPageState();
}

class _EnderecosPageState extends State<EnderecosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Endereços'),
      )
    );
  }
}
