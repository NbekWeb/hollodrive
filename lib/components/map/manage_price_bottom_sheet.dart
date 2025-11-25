import 'package:flutter/material.dart';

class ManagePriceBottomSheet extends StatefulWidget {
  final double initialPrice;
  final VoidCallback? onBack;
  final Function(double)? onConfirm;

  const ManagePriceBottomSheet({
    super.key,
    required this.initialPrice,
    this.onBack,
    this.onConfirm,
  });

  @override
  State<ManagePriceBottomSheet> createState() => _ManagePriceBottomSheetState();
}

class _ManagePriceBottomSheetState extends State<ManagePriceBottomSheet> {
  late double _currentPrice;
  late double _sliderValue;
  final double _minPrice = 0.0;
  final double _maxPrice = 50.0;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.initialPrice;
    // Convert price to slider value (0-100)
    _sliderValue = ((_currentPrice - _minPrice) / (_maxPrice - _minPrice) * 100).clamp(0.0, 100.0);
  }

  void _decrementPrice() {
    setState(() {
      _currentPrice = (_currentPrice - 1.0).clamp(_minPrice, _maxPrice);
      _sliderValue = ((_currentPrice - _minPrice) / (_maxPrice - _minPrice) * 100).clamp(0.0, 100.0);
    });
  }

  void _incrementPrice() {
    setState(() {
      _currentPrice = (_currentPrice + 1.0).clamp(_minPrice, _maxPrice);
      _sliderValue = ((_currentPrice - _minPrice) / (_maxPrice - _minPrice) * 100).clamp(0.0, 100.0);
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
      _currentPrice = (_minPrice + (value / 100) * (_maxPrice - _minPrice)).clamp(_minPrice, _maxPrice);
    });
  }

  void _handleConfirm() {
    widget.onConfirm?.call(_currentPrice);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Manage the price',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Reduce or increase the price of the trip.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Price adjustment control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decrement button
                    GestureDetector(
                      onTap: _decrementPrice,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                    // Price display
                    Text(
                      '\$${_currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Increment button
                    GestureDetector(
                      onTap: _incrementPrice,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.yellow.shade600,
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: Colors.yellow.shade600,
                  overlayColor: Colors.yellow.shade600.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 0,
                  max: 100,
                  onChanged: _onSliderChanged,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Confirm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: GestureDetector(
                onTap: _handleConfirm,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE52A00),
                    borderRadius: BorderRadius.circular(50), // Pill-shaped button
                  ),
                  child: const Center(
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
