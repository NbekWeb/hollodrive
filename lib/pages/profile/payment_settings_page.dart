import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  int _selectedPaymentIndex = 1; // Visa is selected by default

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'wallet',
      'name': 'Hola Wallet',
      'amount': 'CA\$2',
      'svg': 'assets/svg/hola.svg',
    },
    {
      'type': 'visa',
      'name': 'Visa',
      'number': '****1076',
      'svg': 'assets/svg/visa.svg',
    },
    {
      'type': 'amex',
      'name': 'Francis',
      'number': '****2088',
      'svg': 'assets/svg/amex.svg',
    },
    {
      'type': 'google_pay',
      'name': 'Google Pay',
      'svg': 'assets/svg/gpay.svg',
    },
    {
      'type': 'mastercard',
      'name': 'MasterCard',
      'number': '****3996',
      'svg': 'assets/svg/master.svg',
    },
    {
      'type': 'bitcoin',
      'name': 'Bitcoin',
      'number': '****7dyc',
      'svg': 'assets/svg/bitcoin.svg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section (User Info)
            const UserInfoHeader(),
            // Navigation Bar (Payment Settings Title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back arrow with circular background
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: surfaceColor,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Centered title
                  const Text(
                    'Payment Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Add button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // Handle add payment method
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: surfaceColor,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Payment Methods List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Payment methods
                  ...List.generate(_paymentMethods.length, (index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedPaymentIndex == index;
                    
                    return Column(
                      children: [
                        GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              // SVG Icon
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: SvgPicture.asset(
                                  method['svg'] ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name and details
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        method['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (method['amount'] != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        method['amount']?.toString() ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ]
                                    else if (method['number'] != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        method['number']?.toString() ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Info icon or checkmark
                              if (index == 0)
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20,
                                )
                              else if (isSelected)
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                        ),
                        // Separator line after Hola Wallet (index 0)
                        if (index == 0) ...[
                          const SizedBox(height: 15),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 15),
                        ]
                        else if (index < _paymentMethods.length - 1)
                          const SizedBox(height: 15),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  // Promos / Vouchers section
                  Text(
                    'Promos / Vouchers',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Add promo/voucher button
                  GestureDetector(
                    onTap: () {
                      // Handle add promo/voucher
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add promo/voucher code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

