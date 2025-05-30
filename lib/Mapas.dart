import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'viagem_model.dart';

class Mapas extends StatefulWidget {
  final LatLng? localInicial;
  const Mapas({Key? key, this.localInicial}) : super(key: key);

  @override
  State<Mapas> createState() => _MapasState();
}

class _MapasState extends State<Mapas> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  LatLng? _buscaExterna;
  String _enderecoBusca = '';
  bool _isLoading = true;
  String _errorMessage = '';
  bool _mapInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _dadosBusca;

  @override
  void initState() {
    super.initState();
    if (widget.localInicial != null) {
      _buscaExterna = widget.localInicial;
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _buscarLocalPorTexto(String termo) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$termo&format=json&limit=1&addressdetails=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'minhas-viagens-app/1.0',
    });

    if (response.statusCode == 200) {
      final resultado = json.decode(response.body);
      if (resultado.isNotEmpty) {
        final lat = double.parse(resultado[0]['lat']);
        final lon = double.parse(resultado[0]['lon']);
        setState(() {
          _buscaExterna = LatLng(lat, lon);
          _enderecoBusca = resultado[0]['display_name'];
          _dadosBusca = resultado[0];
        });
        _mapController.move(_buscaExterna!, 10);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum local encontrado')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na busca: ${response.statusCode}')),
      );
    }
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Serviço de localização desabilitado';
        _isLoading = false;
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Permissão de localização negada';
          _isLoading = false;
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Permissão permanentemente negada. Ative nas configurações.';
        _isLoading = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!await _checkPermissions()) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      if (_mapInitialized) {
        _mapController.move(_currentLocation!, 16);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao obter localização: ${e.toString()}';
      });
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  Future<void> _salvarBuscaComoViagem() async {
    if (_buscaExterna == null || _dadosBusca == null) return;

    final controller = TextEditingController(
      text: _dadosBusca!['display_name'].split(',').first,
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Local'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome personalizado'),
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
      final endereco = _dadosBusca!['address'] ?? {};
      final novaViagem = Viagem(
        coordenadas: _buscaExterna!,
        nome: controller.text,
        endereco: _enderecoBusca,
        cidade:
            endereco['city'] ?? endereco['town'] ?? endereco['village'] ?? '',
        estado: endereco['state'] ?? '',
        pais: endereco['country'] ?? '',
        cep: endereco['postcode'] ?? '',
        bairro: endereco['suburb'] ?? endereco['neighbourhood'],
        referencia: endereco['amenity'] ?? endereco['building'],
      );

      Navigator.pop(context, novaViagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecione um Local"),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar país, estado ou cidade...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _buscarLocalPorTexto,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _buscarLocalPorTexto(_searchController.text),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMapContent()),
        ],
      ),
      floatingActionButton: _buscaExterna != null
          ? FloatingActionButton.extended(
              onPressed: _salvarBuscaComoViagem,
              icon: const Icon(Icons.save),
              label: const Text("Salvar local"),
            )
          : null,
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Tentar Novamente'),
            ),
            if (_errorMessage.contains('permanentemente'))
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Abrir Configurações'),
              ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            widget.localInicial ?? _currentLocation ?? const LatLng(0, 0),
        initialZoom: 16,
        onTap: _handleTap,
        onMapReady: () {
          setState(() => _mapInitialized = true);
          if (widget.localInicial != null) {
            _mapController.move(widget.localInicial!, 16);
          } else if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 16);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                child: const Icon(Icons.person_pin_circle,
                    size: 50, color: Colors.blue),
              ),
            ],
          ),
        if (_selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation!,
                child:
                    const Icon(Icons.location_pin, size: 50, color: Colors.red),
              ),
            ],
          ),
        if (_buscaExterna != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _buscaExterna!,
                child: const Icon(Icons.public,
                    size: 40, color: Colors.deepPurple),
              ),
            ],
          ),
        if (widget.localInicial != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.localInicial!,
                child: const Icon(Icons.location_on,
                    size: 48, color: Colors.orange),
              ),
            ],
          ),
      ],
    );
  }
}
