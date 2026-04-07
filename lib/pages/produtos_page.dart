import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:compra_venda_perto_casa/routes/app_routes.dart';
import 'package:geolocator/geolocator.dart';

double calcularDistancia(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371.0;

  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double? toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  String _searchText = '';
  Position? _userPosition;
  bool _carregandoLocalizacao = true;

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
      return collection
          .where('vendido', isEqualTo: false)
          .orderBy('nomeLower')
          .startAt([_searchText])
          .endAt(['${_searchText}\uf8ff']);
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _carregandoLocalizacao = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _carregandoLocalizacao = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _carregandoLocalizacao = false;
      });
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      if (!mounted) return;
      setState(() {
        _carregandoLocalizacao = false;
      });
    }
  }

  String _textoDistancia(Map<String, dynamic> anuncio) {
    final lat = toDouble(anuncio['latitude']);
    final lon = toDouble(anuncio['longitude']);

    if (_carregandoLocalizacao) {
      return '📍 Calculando distância...';
    }

    if (_userPosition == null) {
      return '📍 Localização indisponível';
    }

    if (lat == null || lon == null) {
      return '📍 Distância indisponível';
    }

    final distancia = calcularDistancia(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lon,
    );

    return '📏 ${distancia.toStringAsFixed(1)} km de você';
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                  final docUserId = data['userId'];
                  final vendido = data['vendido'] == true;
                  return docUserId != uid && !vendido;
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

                    final valor = toDouble(anuncio['valor']) ?? 0.0;
                    final distanciaTexto = _textoDistancia(anuncio);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        title: Text(
                          anuncio['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'R\$ ${valor.toStringAsFixed(2)}\n'
                          '${anuncio['descricao'] ?? ''}\n'
                          '${anuncio['bairro'] ?? ''} - ${anuncio['cidade'] ?? ''}\n'
                          '$distanciaTexto',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalhesAnuncioPage(anuncio: anuncio),
                            ),
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

  Future<double?> _calcularDistanciaUsuario() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition();

      final lat = toDouble(anuncio['latitude']);
      final lon = toDouble(anuncio['longitude']);

      if (lat == null || lon == null) {
        return null;
      }

      return calcularDistancia(
        pos.latitude,
        pos.longitude,
        lat,
        lon,
      );
    } catch (e) {
      debugPrint("Erro ao calcular distância: $e");
      return null;
    }
  }

  Future<Position?> _getUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Erro localização: $e');
      return null;
    }
  }

  double _valorAnuncio() {
    final valor = anuncio['valor'];
    if (valor is int) return valor.toDouble();
    if (valor is double) return valor;
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final valor = _valorAnuncio();

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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              anuncio['descricao'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
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