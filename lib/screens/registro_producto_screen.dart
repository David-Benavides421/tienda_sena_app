import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importa el paquete http
import 'dart:convert'; // Para jsonEncode y jsonDecode

class RegistroProductoScreen extends StatefulWidget {
  const RegistroProductoScreen({super.key});

  @override
  State<RegistroProductoScreen> createState() => _RegistroProductoScreenState();
}

class _RegistroProductoScreenState extends State<RegistroProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  bool _isLoading = false;

  // IMPORTANTE: Esta es la URL base para tu API PHP.
  // Si estás corriendo Flutter como aplicación WEB y tu XAMPP/PHP está en la misma máquina:
  final String _baseUrl = "http://localhost/app_tienda_SENA";

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) { // Valida el formulario
      setState(() {
        _isLoading = true;
      });

      final String nombre = _nombreController.text;
      final String precio = _precioController.text;
      final String cantidad = _cantidadController.text;

      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/guardar_producto.php'),
          headers: <String, String>{
            // PHP $_POST espera datos como 'application/x-www-form-urlencoded'
            // http.post con un Map en 'body' lo hace automáticamente si no se especifica 'Content-Type' como 'application/json'
          },
          body: { // Estos son los datos que PHP recibirá en $_POST
            'nombre': nombre,
            'precio': precio,
            'cantidad': cantidad,
          },
        );
        
        // Imprime para depuración
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Respuesta desconocida del servidor.'),
              backgroundColor: responseData['status'] == 'success' ? Colors.green : Colors.red,
            ),
          );
          if (responseData['status'] == 'success') {
            _nombreController.clear();
            _precioController.clear();
            _cantidadController.clear();
            // Opcional: Navegar a otra pantalla o recargar lista de productos si la tuvieras aquí.
          }
        } else {
          // Error del servidor (no 200)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error del servidor: ${response.statusCode}. Intente más tarde.')),
          );
        }
      } catch (e) {
        // Error de conexión o al procesar la petición/respuesta
        print('Error al guardar producto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e. Verifique el servidor PHP y la URL.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Producto SENA'),
        backgroundColor: Colors.orange, // Color institucional
      ),
      body: SingleChildScrollView( // Para evitar overflow si el teclado es grande
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio Unitario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Ingrese un precio válido (ej: 1500.50)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad Disponible',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la cantidad';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Ingrese una cantidad válida (ej: 10)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar Producto', style: TextStyle(color: Colors.white)),
                      onPressed: _guardarProducto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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