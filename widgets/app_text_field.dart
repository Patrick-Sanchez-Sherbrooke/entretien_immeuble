// lib/widgets/app_text_field.dart
// ============================================
// CHAMP TEXTE PERSONNALISÉ
// Place le curseur à l'endroit du tap sans sélectionner
// ============================================
import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _wasAlreadyFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Le champ vient de recevoir le focus
      // On attend un court instant puis on désélectionne si tout est sélectionné
      Future.delayed(const Duration(milliseconds: 50), () {
        if (widget.controller != null && mounted && _focusNode.hasFocus) {
          final ctrl = widget.controller!;
          final sel = ctrl.selection;
          // Si tout le texte est sélectionné automatiquement par Flutter
          if (sel.baseOffset == 0 &&
              sel.extentOffset == ctrl.text.length &&
              ctrl.text.isNotEmpty &&
              !_wasAlreadyFocused) {
            // Placer le curseur à la fin du texte
            ctrl.selection = TextSelection.collapsed(
              offset: ctrl.text.length,
            );
          }
        }
        _wasAlreadyFocused = true;
      });
    } else {
      // Le champ a perdu le focus
      _wasAlreadyFocused = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      // Désactiver la sélection automatique de tout le texte
      enableInteractiveSelection: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        alignLabelWithHint:
            widget.maxLines != null && widget.maxLines! > 1,
      ),
    );
  }
}