import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/countries.dart';
import '../l10n/app_localizations.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  static String fullPhone(Country country, TextEditingController controller) {
    return '${country.dialCode}${controller.text.trim()}';
  }

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryPickerSheet(selected: selectedCountry),
    );
    if (picked != null) onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: l10n.phoneLabel,
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        prefixIcon: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickCountry(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  selectedCountry.dialCode,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Container(width: 1, height: 20, color: AppColors.divider),
              ],
            ),
          ),
        ),
      ),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return l10n.phoneRequired;
        if (!RegExp(r'^\d{6,15}$').hasMatch(value)) return l10n.phoneInvalid;
        return null;
      },
    );
  }
}

class _CountryPickerSheet extends StatelessWidget {
  final Country selected;
  const _CountryPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              l10n.countryPickerTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: Countries.all.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (ctx, i) {
                final country = Countries.all[i];
                final isSelected = country.nameKey == selected.nameKey &&
                    country.dialCode == selected.dialCode;
                return ListTile(
                  onTap: () => Navigator.pop(ctx, country),
                  leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    countryDisplayName(country, l10n),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
