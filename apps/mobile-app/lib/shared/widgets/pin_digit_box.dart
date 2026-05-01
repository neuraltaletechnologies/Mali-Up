import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class PinDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final bool obscureText;
  final double size;
  final bool autoFocus;
  final VoidCallback? onComplete;

  const PinDigitBox({
    super.key,
    required this.controller,
    this.obscureText = true,
    this.size = 56,
    this.autoFocus = false,
    this.onComplete,
  });

  @override
  State<PinDigitBox> createState() => _PinDigitBoxState();
}

class _PinDigitBoxState extends State<PinDigitBox> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _isFocused 
            ? AppColors.primary.withValues(alpha: 0.08) 
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? AppColors.primary 
              : AppColors.border.withValues(alpha: 0.6),
          width: _isFocused ? 2 : 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          obscureText: widget.obscureText,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: (value) {
            if (value.isNotEmpty) {
              FocusScope.of(context).nextFocus();
              widget.onComplete?.call();
            } else {
              FocusScope.of(context).previousFocus();
            }
          },
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}