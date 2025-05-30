import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'geocoding_service.dart';
import 'viagem_model.dart';
import 'Mapas.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Viagem> _listaViagens = [];
  final TextEditingController _buscaController = TextEditingController();
  String _filtroTexto = '';
  bool _temaEscuro = false;

  Future<void> _adicionarLocal() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Mapas()),
    );

    if (resultado != null && resultado is Viagem) {
      setState(() => _listaViagens.add(resultado));
    } else if (resultado != null && resultado is LatLng) {
      await _adicionarViagemDaLocalizacao(resultado);
    }
  }

  Future<void> _adicionarViagemDaLocalizacao(LatLng location) async {
    try {
      final dadosLocal =
          await GeocodingService.getAddressFromCoordinates(location);

      final nomeController = TextEditingController(
        text: dadosLocal['name'] ??
            dadosLocal['address']['amenity'] ??
            'Novo Local',
      );

      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Local'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                    'Endereço: ${dadosLocal['display_name'] ?? 'Não identificado'}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nomeController,
                  decoration:
                      const InputDecoration(labelText: 'Nome para este local'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );

      if (confirmado == true) {
        final novaViagem = Viagem.fromJson(
          dadosLocal,
          nomePersonalizado: nomeController.text,
        );

        setState(() => _listaViagens.add(novaViagem));
      }
    } catch (e) {
      final nome = await _mostrarDialogoManual(location);
      if (nome != null) {
        setState(() => _listaViagens.add(
              Viagem(
                coordenadas: location,
                nome: nome,
                endereco:
                    'Coordenadas: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                cidade: 'Não identificada',
                estado: '',
                pais: '',
                cep: '',
              ),
            ));
      }
    }
  }

  Future<String?> _mostrarDialogoManual(LatLng location) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Local Manualmente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do local',
            hintText: 'Ex: Meu ponto favorito',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _excluirViagem(int index) {
    setState(() {
      _listaViagens.removeAt(index);
    });
  }

  void _ordenarPorDistancia() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _listaViagens.sort((a, b) {
          final distanciaA = const Distance().as(LengthUnit.Kilometer,
              LatLng(pos.latitude, pos.longitude), a.coordenadas);
          final distanciaB = const Distance().as(LengthUnit.Kilometer,
              LatLng(pos.latitude, pos.longitude), b.coordenadas);
          return distanciaA.compareTo(distanciaB);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ordenar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viagensFiltradas = _listaViagens.where((v) {
      final filtro = _filtroTexto.toLowerCase();
      return v.nome.toLowerCase().contains(filtro) ||
          v.cidade.toLowerCase().contains(filtro) ||
          v.estado.toLowerCase().contains(filtro) ||
          v.pais.toLowerCase().contains(filtro);
    }).toList();

    return MaterialApp(
      theme: _temaEscuro ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Minhas viagens"),
          actions: [
            if (_listaViagens.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _ordenarPorDistancia,
              ),
            IconButton(
              icon: Icon(_temaEscuro ? Icons.brightness_7 : Icons.brightness_4),
              onPressed: () => setState(() => _temaEscuro = !_temaEscuro),
              tooltip: 'Alternar tema',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: _adicionarLocal,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nome, cidade, estado ou país',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _buscaController.clear();
                      setState(() => _filtroTexto = '');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => setState(() => _filtroTexto = value),
              ),
            ),
            Expanded(
              child: viagensFiltradas.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma viagem adicionada\nClique no + para começar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: viagensFiltradas.length,
                      itemBuilder: (context, index) {
                        final viagem = viagensFiltradas[index];
                        final indexOriginal = _listaViagens.indexOf(viagem);

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                viagem.referencia == '⭐'
                                    ? Icons.star
                                    : Icons.star_border,
                                color: viagem.referencia == '⭐'
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _listaViagens[indexOriginal] = Viagem(
                                    coordenadas: viagem.coordenadas,
                                    nome: viagem.nome,
                                    endereco: viagem.endereco,
                                    cidade: viagem.cidade,
                                    estado: viagem.estado,
                                    pais: viagem.pais,
                                    cep: viagem.cep,
                                    bairro: viagem.bairro,
                                    referencia:
                                        viagem.referencia == '⭐' ? null : '⭐',
                                  );
                                });
                              },
                            ),
                            title: Text(
                              viagem.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (viagem.endereco.isNotEmpty)
                                  Text(viagem.endereco),
                                if (viagem.cidade.isNotEmpty)
                                  Text('${viagem.cidade}, ${viagem.estado}'),
                                if (viagem.pais.isNotEmpty) Text(viagem.pais),
                                if (viagem.cep.isNotEmpty)
                                  Text('CEP: ${viagem.cep}'),
                                Text(
                                  'Coordenadas: ${viagem.coordenadas.latitude.toStringAsFixed(4)}, '
                                  '${viagem.coordenadas.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _excluirViagem(indexOriginal),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Mapas(localInicial: viagem.coordenadas),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
