import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Para formatear fechas y números

// Importa los modelos necesarios
import '../models/venta_detalle_model.dart';
import '../models/producto_model.dart'; // Usaremos el modelo de Producto para el Dropdown de filtro

class ConsultaVentasScreen extends StatefulWidget {
  const ConsultaVentasScreen({super.key});

  @override
  State<ConsultaVentasScreen> createState() => _ConsultaVentasScreenState();
}

class _ConsultaVentasScreenState extends State<ConsultaVentasScreen> {
  List<VentaDetalle> _listaVentas = [];
  double _totalVentasFiltradas = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // Controladores y variables para los filtros
  DateTime? _fechaSeleccionada;
  Producto? _productoFiltroSeleccionado;
  List<Producto> _listaProductosParaFiltro = []; // Para el dropdown de productos

  final String _baseUrl = "http://localhost/app_tienda_SENA";
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd'); // Para enviar al API
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy HH:mm'); // Para mostrar en UI
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);


  @override
  void initState() {
    super.initState();
    _cargarProductosParaFiltro(); // Cargar productos para el dropdown de filtro
    _consultarVentas(); // Cargar todas las ventas inicialmente
  }

  Future<void> _cargarProductosParaFiltro() async {
    // Similar a como se cargan en RegistroVentaScreen, pero sin la condición de cantidad > 0
    // ya que queremos poder filtrar por productos que quizás ya no tengan stock pero sí tuvieron ventas.
    try {
      final response = await http.get(Uri.parse('$_baseUrl/listar_productos.php?todos=true')); // Podrías añadir un param 'todos=true' a listar_productos.php para que no filtre por cantidad > 0, o usar una URL diferente.
                                                                                                // Por simplicidad, reusamos listar_productos.php; si no hay productos, el dropdown estará vacío.
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['productos'] != null) {
          List<dynamic> productosJson = data['productos'];
          setState(() {
            _listaProductosParaFiltro = productosJson.map((json) => Producto.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error cargando productos para filtro: $e");
      // No es crítico si esto falla, el filtro por producto simplemente no estará disponible.
    }
  }

  Future<void> _consultarVentas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Construir la URL con los parámetros de filtro
    Map<String, String> queryParams = {};
    if (_fechaSeleccionada != null) {
      queryParams['fecha'] = _dateFormat.format(_fechaSeleccionada!);
    }
    if (_productoFiltroSeleccionado != null) {
      queryParams['producto_id'] = _productoFiltroSeleccionado!.id.toString();
    }
    
    // Uri.http o Uri.https manejan la codificación de queryParams
    final uri = Uri.parse('$_baseUrl/consultar_ventas.php').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    
    print("Consultando ventas con URL: $uri"); // Para depurar

    try {
      final response = await http.get(uri);
      print("Respuesta consultar_ventas: ${response.body}"); // Para depurar

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> ventasJson = data['ventas'];
          setState(() {
            _listaVentas = ventasJson.map((json) => VentaDetalle.fromJson(json)).toList();
            _totalVentasFiltradas = (data['total_ventas_filtradas'] as num).toDouble();
            if (_listaVentas.isEmpty) {
              _errorMessage = data['message'] ?? 'No se encontraron ventas con los filtros aplicados.';
            }
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al obtener ventas del servidor.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error del servidor (${response.statusCode}).';
        });
      }
    } catch (e) {
      print("Error en _consultarVentas: $e");
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020), // Un rango razonable
      lastDate: DateTime.now().add(const Duration(days: 1)), // No permitir fechas futuras más allá de mañana (por si acaso)
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      // _consultarVentas(); // Opcional: consultar automáticamente al cambiar filtro
    }
  }

  void _aplicarFiltros() {
    _consultarVentas();
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaSeleccionada = null;
      _productoFiltroSeleccionado = null;
    });
    _consultarVentas(); // Cargar todas las ventas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Ventas'),
        // backgroundColor: Colors.teal, // O usa el theme
      ),
      body: Column(
        children: <Widget>[
          _buildFiltros(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ventas Encontradas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormat.format(_totalVentasFiltradas),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _listaVentas.isEmpty // Mostrar error solo si no hay ventas que mostrar
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                      ))
                    : _listaVentas.isEmpty
                        ? const Center(child: Text('No hay ventas para mostrar con los filtros actuales.'))
                        : ListView.builder(
                            itemCount: _listaVentas.length,
                            itemBuilder: (context, index) {
                              final venta = _listaVentas[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColorLight,
                                    child: Text(venta.cantidadVendida.toString(), style: TextStyle(color: Theme.of(context).primaryColorDark)),
                                  ),
                                  title: Text(venta.nombreProducto, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      'Comprador: ${venta.comprador}\nFecha: ${_displayDateFormat.format(venta.fecha)}\nPrecio Unit: ${_currencyFormat.format(venta.precioUnitarioEnVenta)}'),
                                  trailing: Text(
                                    _currencyFormat.format(venta.subtotalVenta),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: Text(
                          _fechaSeleccionada != null ? _dateFormat.format(_fechaSeleccionada!) : 'Todas',
                        ),
                      ),
                    ),
                  ),
                  if (_fechaSeleccionada != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() { _fechaSeleccionada = null; });
                        // _consultarVentas(); // Opcional
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Producto>(
                decoration: InputDecoration(
                  labelText: 'Producto',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  suffixIcon: _productoFiltroSeleccionado != null ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() { _productoFiltroSeleccionado = null; });
                        // _consultarVentas(); // Opcional
                      },
                    ) : null,
                ),
                value: _productoFiltroSeleccionado,
                hint: const Text('Todos los productos'),
                isExpanded: true,
                items: [
                  // Opción para "Todos los productos"
                  const DropdownMenuItem<Producto>(
                    value: null, // Representa "todos"
                    child: Text('Todos los productos'),
                  ),
                  // Resto de los productos
                  ..._listaProductosParaFiltro.map<DropdownMenuItem<Producto>>((Producto producto) {
                    return DropdownMenuItem<Producto>(
                      value: producto,
                      child: Text(producto.nombre),
                    );
                  }).toList(),
                ],
                onChanged: (Producto? newValue) {
                  setState(() {
                    _productoFiltroSeleccionado = newValue;
                  });
                  // _consultarVentas(); // Opcional
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Aplicar Filtros'),
                    onPressed: _aplicarFiltros,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar'),
                    onPressed: _limpiarFiltros,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}