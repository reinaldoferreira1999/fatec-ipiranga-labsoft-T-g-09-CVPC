import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:compra_venda_perto_casa/routes/app_routes.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  String _searchText = '';

  Query _buildQuery() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance.collection('anuncios');

    if (_searchText.isEmpty) {
      return collection
          .where('userId', isNotEqualTo: uid)
          .where('vendido', isEqualTo: false)
          .orderBy('userId')
          .orderBy('criadoEm', descending: true);
    } else {
      final s = _searchText;
      return collection
          .orderBy('nomeLower')
          .startAt([_searchText])
          .endAt(['${_searchText}\uf8ff']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar produto...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchText = ''),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),

          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto disponível.'));
                }

                final uid = FirebaseAuth.instance.currentUser!.uid;

                
                final docsFiltered = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final docUserId = data['userId'] ?? data['userId'];
                  return docUserId != uid;
                }).toList();

                if (docsFiltered.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docsFiltered.length,
                  itemBuilder: (context, index) {
                    final doc = docsFiltered[index];
                    final anuncio = doc.data() as Map<String, dynamic>;
                    anuncio['id'] = doc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: anuncio['imagemUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  anuncio['imagemUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 40),
                        title: Text(anuncio['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'R\$ ${(anuncio['valor'] ?? 0).toStringAsFixed(2)}\n${anuncio['descricao'] ?? ''}\n'
                          '${anuncio['bairro'] ?? ''} - ${anuncio['cidade'] ?? ''}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetalhesAnuncioPage(anuncio: anuncio)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetalhesAnuncioPage extends StatelessWidget {
  final Map<String, dynamic> anuncio;
  const DetalhesAnuncioPage({super.key, required this.anuncio});

  Future<String?> _buscarNomeVendedor() async {
    try {
      final userId = anuncio['userId'];
      if (userId == null) return null;

      final perfilSnap = await FirebaseFirestore.instance
          .collection('usuario')
          .doc(userId)
          .collection('perfil')
          .limit(1)
          .get();

      if (perfilSnap.docs.isEmpty) return null;

      final data = perfilSnap.docs.first.data();
      return data['nome'] as String?;
    } catch (e) {
      debugPrint('Erro ao buscar nome do vendedor: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anuncio['nome'] ?? 'Detalhes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (anuncio['imagemUrl'] != null)
            Center(child: Image.network(anuncio['imagemUrl'], height: 250, fit: BoxFit.cover)),
          const SizedBox(height: 20),
          Text(anuncio['nome'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('R\$ ${(anuncio['valor'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green)),
          const SizedBox(height: 20),
          Text(anuncio['descricao'] ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 30),
          FutureBuilder<String?>(
            future: _buscarNomeVendedor(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Vendedor: carregando...');
              }

              final nomeVendedor = snapshot.data ?? 'Vendedor não informado';
              return Text(
                'Vendedor: $nomeVendedor',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),

            const SizedBox(height: 8),
          if (anuncio['bairro'] != null || anuncio['cidade'] != null)
          Text(
            'Localização: ${anuncio['bairro'] ?? ''} - ${anuncio['cidade'] ?? ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          Container(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: () => {
                  Navigator.of(context).pushNamed(AppRoutes.ESCOLHERENDERECO, arguments: anuncio),
                },
                child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Comprar',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

        ]),
      ),
    );
  }
}