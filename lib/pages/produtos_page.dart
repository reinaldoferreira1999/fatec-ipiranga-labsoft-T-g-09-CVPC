import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:compra_venda_perto_casa/routes/app_routes.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  String _searchText = '';
  Position? _userPosition;

  Query _buildQuery() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance.collection('anuncios');

    if (_searchText.isEmpty) {
      return collection
          .where('userId', isNotEqualTo: uid)
          .where('vendido', isEqualTo: false)
          .where('reservado', isEqualTo: false)
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

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      _userPosition = position;
    });
  }

  double calcularDistancia(
    double lat1, double lon1, double lat2, double lon2) {

      const R = 6371;

      final dLat = (lat2 - lat1) * pi / 180;
      final dLon = (lon2 - lon1) * pi / 180;

      final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
        cos(lat2 * pi / 180) *
        sin(dLon / 2) *
        sin(dLon / 2);

      final c = 2 * atan2(sqrt(a), sqrt(1 - a));

      return R * c;
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
                    double? distancia;

                    if (_userPosition != null &&
                    anuncio['latitude'] != null &&
                    anuncio['longitude'] != null) {

                      distancia = calcularDistancia(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                        anuncio['latitude'],
                        anuncio['longitude'],
                      );
                    }

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
                          '${anuncio['bairro']} - ${anuncio['cidade']}\n'
                          + (distancia != null
                            ? '📏 ${distancia.toStringAsFixed(1)} km de você'
                            : '📍 Calculando distância...'),
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

  double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {

      const R = 6371;

      final dLat = (lat2 - lat1) * pi / 180;
      final dLon = (lon2 - lon1) * pi / 180;

      final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
        cos(lat2 * pi / 180) *
        sin(dLon / 2) *
        sin(dLon / 2);

      final c = 2 * atan2(sqrt(a), sqrt(1 - a));

      return R * c;
  }

  Future<double?> _calcularDistanciaUsuario() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition();

      if (anuncio['latitude'] == null ||
          anuncio['longitude'] == null) {
        return null;
      }

      return calcularDistancia(
        pos.latitude,
        pos.longitude,
        anuncio['latitude'],
        anuncio['longitude'],
      );
    } catch (e) {
      debugPrint("Erro ao calcular distância: $e");
      return null;
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anuncio['nome'] ?? 'Detalhes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (anuncio['imagemUrl'] != null)
              Center(
                child: Image.network(
                  anuncio['imagemUrl'],
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            Text(
              anuncio['nome'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'R\$ ${(anuncio['valor'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),

            const SizedBox(height: 20),

            Text(
              anuncio['descricao'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // 📏 DISTÂNCIA AQUI
            FutureBuilder<double?>(
              future: _calcularDistanciaUsuario(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('📍 Calculando distância...');
                }

                if (!snapshot.hasData) {
                  return const Text('📍 Não foi possível obter localização');
                }

                return Text(
                  '📏 ${snapshot.data!.toStringAsFixed(1)} km de você',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

            Container(
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.ESCOLHERENDERECO,
                    arguments: anuncio,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
          ],
        ),
      ),
    );
  }
}