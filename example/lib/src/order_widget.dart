import 'package:flutter/material.dart';

class OrderWidget extends StatelessWidget {
  const OrderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAIPFOOD LANCHES',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pedido: #12345\nData: 28/04/2025 14:32',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const Divider(thickness: 2),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Itens:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildItem('X-Burger', 2, 15.00),
            _buildItem('Batata Média', 1, 8.50),
            _buildItem('Refrigerante 350ml', 2, 6.00),
            _buildItem('Açaí 300ml', 1, 12.00),
            ...List.generate(50, (i) => _buildItem('Açaí 300ml', 1, 12.00)),
            const Divider(),
            const SizedBox(height: 8),
            _buildTotalRow('Subtotal', 62.50),
            _buildTotalRow('Taxa de Entrega', 5.00),
            const Divider(thickness: 2),
            _buildTotalRow('TOTAL', 67.50, isBold: true),
            const SizedBox(height: 16),
            const Text(
              'Observações:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sem cebola no X-Burger.\nBatata sem sal.',
              style: TextStyle(fontSize: 14),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Divider(thickness: 2),
                SizedBox(height: 8),
                Text(
                  'Obrigado pela preferência!',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Volte sempre :)',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String name, int qty, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$qty x $name',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'R\$ ${(price * qty).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'R\$ ${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
