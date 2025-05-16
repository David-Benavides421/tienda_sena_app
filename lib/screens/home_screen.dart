import 'package:flutter/material.dart';
import 'registro_producto_screen.dart';
import 'registro_venta_screen.dart';
import 'consulta_ventas_screen.dart'; // Asegúrate de importar esta pantalla

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Aprendices SENA'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box, color: Colors.white),
                label: const Text('Registrar Producto', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistroProductoScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text('Registrar Venta', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistroVentaScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon( // BOTÓN PARA CONSULTAR VENTAS
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                label: const Text('Consultar Ventas', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConsultaVentasScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}