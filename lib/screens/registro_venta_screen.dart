import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/producto_model.dart';
// Asegúrate de importar tu modelo de Producto si está en un archivo separado


class RegistroVentaScreen extends StatefulWidget {
  const RegistroVentaScreen({super.key});

  @override
  State<RegistroVentaScreen> createState() => _RegistroVentaScreenState();
}

class _RegistroVentaScreenState extends State<RegistroVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _compradorController = TextEditingController();
  final TextEditingController _cantidadVendidaController = TextEditingController();

  List<Producto> _listaProductos = [];
  Producto? _productoSeleccionado;
  bool _isLoadingProductos = true;
  String? _errorCargaProductos;
  bool _isRegisteringVenta = false;

  // URL base de tu API
  final String _baseUrl = "http://localhost/tienda_sena_api";

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoadingProductos = true;
      _errorCargaProductos = null;
      _listaProductos = []; // Limpiar antes de cargar
      _productoSeleccionado = null; // Resetear selección
    });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/listar_productos.php'));
      print('Respuesta listar_productos: ${response.body}'); // Para depurar

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['productos'] != null) {
          List<dynamic> productosJson = responseData['productos'];
          setState(() {
            _listaProductos = productosJson.map((json) => Producto.fromJson(json)).toList();
            _isLoadingProductos = false;
          });
        } else {
          setState(() {
            _errorCargaProductos = responseData['message'] ?? 'No se pudieron cargar los productos.';
            _isLoadingProductos = false;
          });
        }
      } else {
        setState(() {
          _errorCargaProductos = 'Error del servidor (${response.statusCode}) al cargar productos.';
          _isLoadingProductos = false;
        });
      }
    } catch (e) {
      print('Error cargando productos: $e');
      setState(() {
        _errorCargaProductos = 'Error de conexión: $e';
        _isLoadingProductos = false;
      });
    }
  }

  Future<void> _registrarVenta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un producto')),
      );
      return;
    }

    setState(() {
      _isRegisteringVenta = true;
    });

    final String comprador = _compradorController.text;
    final String cantidadVendida = _cantidadVendidaController.text;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registrar_venta.php'),
        body: {
          'producto_id': _productoSeleccionado!.id.toString(),
          'cantidad_vendida': cantidadVendida,
          'comprador': comprador,
        },
      );
      
      print('Respuesta registrar_venta: ${response.body}'); // Para depurar

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Respuesta desconocida'),
            backgroundColor: responseData['status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
        if (responseData['status'] == 'success') {
          _formKey.currentState?.reset();
          _compradorController.clear();
          _cantidadVendidaController.clear();
          setState(() {
            _productoSeleccionado = null; // Resetear dropdown
          });
          _cargarProductos(); // Recargar lista de productos para actualizar stock
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor (${response.statusCode}) al registrar venta.')),
        );
      }
    } catch (e) {
      print('Error registrando venta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() {
        _isRegisteringVenta = false;
      });
    }
  }

  @override
  void dispose() {
    _compradorController.dispose();
    _cantidadVendidaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venta'),
        // backgroundColor: Colors.blueAccent, // O usa el theme
      ),
      body: _isLoadingProductos
          ? const Center(child: CircularProgressIndicator())
          : _errorCargaProductos != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorCargaProductos!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _cargarProductos, child: const Text('Reintentar'))
                      ],
                    ),
                  ),
                )
              : _listaProductos.isEmpty && !_isLoadingProductos
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No hay productos disponibles para la venta.', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              ElevatedButton(onPressed: _cargarProductos, child: const Text('Actualizar Productos'))
                            ]),
                      ))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextFormField(
                              controller: _compradorController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del Aprendiz o Documento',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el nombre o documento';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<Producto>(
                              decoration: const InputDecoration(
                                labelText: 'Producto Vendido',
                                prefixIcon: Icon(Icons.shopping_cart),
                                border: OutlineInputBorder(), // Asegura que el borde del tema se aplique
                              ),
                              value: _productoSeleccionado,
                              hint: const Text('Seleccione un producto'),
                              isExpanded: true,
                              items: _listaProductos.map<DropdownMenuItem<Producto>>((Producto producto) {
                                return DropdownMenuItem<Producto>(
                                  value: producto,
                                  child: Text("${producto.nombre} (Disp: ${producto.cantidad} - \$${producto.precio.toStringAsFixed(0)})"),
                                );
                              }).toList(),
                              onChanged: (Producto? newValue) {
                                setState(() {
                                  _productoSeleccionado = newValue;
                                  // Limpiar cantidad vendida si se cambia el producto para forzar revalidación
                                  _cantidadVendidaController.clear(); 
                                });
                              },
                              validator: (value) => value == null ? 'Seleccione un producto' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _cantidadVendidaController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad Vendida',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la cantidad vendida';
                                }
                                final cantidad = int.tryParse(value);
                                if (cantidad == null || cantidad <= 0) {
                                  return 'Cantidad debe ser un número mayor a 0';
                                }
                                if (_productoSeleccionado != null && cantidad > _productoSeleccionado!.cantidad) {
                                  return 'Stock insuficiente (Disp: ${_productoSeleccionado!.cantidad})';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Mostrar total dinámico
                            if (_productoSeleccionado != null && _cantidadVendidaController.text.isNotEmpty && int.tryParse(_cantidadVendidaController.text) != null && int.parse(_cantidadVendidaController.text) > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Total Venta: \$${(_productoSeleccionado!.precio * (int.tryParse(_cantidadVendidaController.text) ?? 0)).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                              ),
                            const SizedBox(height: 32),
                            _isRegisteringVenta
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.point_of_sale, color: Colors.white),
                                    label: const Text('Registrar Venta', style: TextStyle(color: Colors.white)),
                                    onPressed: _registrarVenta,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      textStyle: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}












