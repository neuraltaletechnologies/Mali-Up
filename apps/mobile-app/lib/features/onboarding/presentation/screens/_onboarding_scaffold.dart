import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScaffold
// ─────────────────────────────────────────────────────────────────────────────

/// Shell used by every form screen in the onboarding flow.
/// Provides a sticky header (back + step progress), scrollable content,
/// and a bottom safe-area gutter so the Continue button is never
/// hidden by navigation bars.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    this.onBack,
  });

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ────────────────────────────────────────────────
            _HeaderBar(onBack: onBack),

            // ── Scrollable form content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          if (onBack != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: onBack,
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.navyPrimary,
                    size: 22,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingField  (labelled text input)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingField extends StatefulWidget {
  const OnboardingField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<OnboardingField> createState() => _OnboardingFieldState();
}

class _OnboardingFieldState extends State<OnboardingField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _focused ? AppColors.navyPrimary : AppColors.textMuted,
            letterSpacing: 0.2,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.navyPrimary,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.textDisabled,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: widget.suffix,
            prefixIcon: widget.prefix,
            filled: true,
            fillColor: _focused ? Colors.white : AppColors.surface,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.navyPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingPrimaryButton
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingPrimaryButton extends StatefulWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 110), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? AppColors.yellowBrand;
    final fg = widget.textColor ?? AppColors.navyPrimary;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _enabled ? bg : AppColors.disabled,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _enabled
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _enabled ? fg : AppColors.textMuted,
                ),
              )
            : Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _enabled ? fg : AppColors.textMuted,
                  letterSpacing: 0.1,
                ),
              ),
      ),
    );

    if (!_enabled) return content;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed!();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingErrorBanner
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingErrorBanner extends StatelessWidget {
  const OnboardingErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingOfflineBanner
// ─────────────────────────────────────────────────────────────────────────────

/// Inline "you're offline" banner shown above the CTA on onboarding screens
/// whose action needs the network (phone lookup, sign-in, registration, team
/// invite). Matches the app's standard neutral notification look
/// ([AppNotification.info]) — navy card, white text — so this persistent
/// banner and the toast fired when an offline user taps the button read as
/// the same thing.
class OnboardingOfflineBanner extends StatelessWidget {
  const OnboardingOfflineBanner({
    super.key,
    required this.message,
    this.title,
  });

  /// Optional bold heading shown above [message] (e.g. "Hakuna mtandao").
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.inverseText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inverseText,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inverseText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PinDotsInput  (4-circle PIN entry)
// ─────────────────────────────────────────────────────────────────────────────

/// Shows 4 animated circles backed by a hidden [TextField] that receives
/// actual input. Tap anywhere on the widget to request focus.
class PinDotsInput extends StatefulWidget {
  const PinDotsInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = true,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    this.onComplete,
    this.pinLength = 4,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onComplete;
  final int pinLength;

  @override
  State<PinDotsInput> createState() => _PinDotsInputState();
}

class _PinDotsInputState extends State<PinDotsInput>
    with TickerProviderStateMixin {
  late final FocusNode _focus;
  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>> _dotScales;

  int _prevLen = 0;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _dotCtrls = List.generate(
      widget.pinLength,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _dotScales = _dotCtrls.map((c) {
      return Tween<double>(begin: 1.0, end: 1.18)
          .animate(CurvedAnimation(parent: c, curve: Curves.elasticOut));
    }).toList();

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final len = widget.controller.text.length;
    if (len > _prevLen && len <= widget.pinLength) {
      // A digit was added — bounce the new dot
      _dotCtrls[len - 1].forward().then((_) => _dotCtrls[len - 1].reverse());
    }
    _prevLen = len;
    if (mounted) setState(() {});
    if (len == widget.pinLength) widget.onComplete?.call();
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    for (final c in _dotCtrls) {
      c.dispose();
    }
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.controller.text.length;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.enabled ? () => FocusScope.of(context).requestFocus(_focus) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 4 circles ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < len;
              final isActive = i == len && _focus.hasFocus;
              return AnimatedBuilder(
                animation: _dotCtrls[i],
                builder: (_, _) => Transform.scale(
                  scale: _dotScales[i].value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.navyPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.error
                            : isActive
                                ? AppColors.navyPrimary
                                : filled
                                    ? AppColors.navyPrimary
                                    : AppColors.border,
                        width: isActive || filled ? 2.0 : 1.5,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppColors.navyPrimary
                                    .withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: filled
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.yellowBrand,
                              ),
                            ),
                          )
                        : isActive
                            ? Center(
                                child: _BlinkingCursor(),
                              )
                            : null,
                  ),
                ),
              );
            }),
          ),

          // ── Hidden text input ─────────────────────────────────────────
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(
              focusNode: _focus,
              controller: widget.controller,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: widget.pinLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.dmSans(height: 0.01, color: Colors.transparent),
              showCursor: false,
              enableInteractiveSelection: false,
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.navyPrimary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepDots  (bottom indicator — used only by legacy screens, kept for compat)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: AnimatedSmoothIndicator(
          activeIndex: (currentStep - 1).clamp(0, totalSteps - 1),
          count: totalSteps,
          effect: ExpandingDotsEffect(
            expansionFactor: 2.2,
            spacing: 6,
            radius: 99,
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }
}
