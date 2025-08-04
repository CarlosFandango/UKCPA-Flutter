import 'package:flutter/material.dart';
import '../../../../domain/entities/checkout.dart';

/// Billing address form for checkout
/// Collects billing address information for payment processing
class BillingAddressForm extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address) onAddressChanged;

  const BillingAddressForm({
    super.key,
    this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  State<BillingAddressForm> createState() => _BillingAddressFormState();
}

class _BillingAddressFormState extends State<BillingAddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _countyController;
  late final TextEditingController _postCodeController;
  String _countryCode = 'GB';

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    
    _nameController = TextEditingController(text: address?.name ?? '');
    _line1Controller = TextEditingController(text: address?.line1 ?? '');
    _line2Controller = TextEditingController(text: address?.line2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _countyController = TextEditingController(text: address?.county ?? '');
    _postCodeController = TextEditingController(text: address?.postCode ?? '');
    _countryCode = address?.countryCode ?? 'GB';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postCodeController.dispose();
    super.dispose();
  }

  void _notifyAddressChanged() {
    if (_formKey.currentState?.validate() ?? false) {
      final address = Address(
        name: _nameController.text.trim(),
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim().isEmpty ? null : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        county: _countyController.text.trim().isEmpty ? null : _countyController.text.trim(),
        postCode: _postCodeController.text.trim(),
        countryCode: _countryCode,
        country: _getCountryName(_countryCode),
      );
      widget.onAddressChanged(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing Address',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Name field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Address line 1
              _buildTextField(
                controller: _line1Controller,
                label: 'Address Line 1',
                hint: 'Street address, P.O. box, company name',
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Address line 2 (optional)
              _buildTextField(
                controller: _line2Controller,
                label: 'Address Line 2 (Optional)',
                hint: 'Apartment, suite, unit, building, floor, etc.',
              ),
              
              const SizedBox(height: 16),
              
              // City and County row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _countyController,
                      label: 'County',
                      hint: 'County',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Post code and Country row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _postCodeController,
                      label: 'Post Code',
                      hint: 'Post code',
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter post code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCountryDropdown(theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => _notifyAddressChanged(),
    );
  }

  Widget _buildCountryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _countryCode,
      decoration: InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      items: const [
        DropdownMenuItem(value: 'GB', child: Text('United Kingdom')),
        DropdownMenuItem(value: 'IE', child: Text('Ireland')),
        DropdownMenuItem(value: 'US', child: Text('United States')),
        DropdownMenuItem(value: 'CA', child: Text('Canada')),
        DropdownMenuItem(value: 'AU', child: Text('Australia')),
        DropdownMenuItem(value: 'FR', child: Text('France')),
        DropdownMenuItem(value: 'DE', child: Text('Germany')),
        DropdownMenuItem(value: 'ES', child: Text('Spain')),
        DropdownMenuItem(value: 'IT', child: Text('Italy')),
        DropdownMenuItem(value: 'NL', child: Text('Netherlands')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _countryCode = value;
          });
          _notifyAddressChanged();
        }
      },
    );
  }

  String _getCountryName(String countryCode) {
    switch (countryCode) {
      case 'GB': return 'United Kingdom';
      case 'IE': return 'Ireland';
      case 'US': return 'United States';
      case 'CA': return 'Canada';
      case 'AU': return 'Australia';
      case 'FR': return 'France';
      case 'DE': return 'Germany';
      case 'ES': return 'Spain';
      case 'IT': return 'Italy';
      case 'NL': return 'Netherlands';
      default: return countryCode;
    }
  }
}