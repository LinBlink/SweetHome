/// "家" (home) widget library — a hand-crafted replacement for the
/// default Material chrome that the rest of the app was leaning on.
///
/// Every widget here shares a small visual vocabulary so the app
/// reads as one consistent "paper-on-wood" surface, not a stack of
/// Material defaults:
///
///   • Surfaces are cream/sand, not pure white, with hair-thin
///     terracotta borders and a soft drop shadow that mimics a card
///     resting on a wooden table.
///   • Primary actions are filled terracotta pills, not
///     rectangular buttons.
///   • The app bar is a kraft-paper strip with a stitched bottom
///     border, not the default blue-grey Material bar.
///   • Dividers are short dashes (· · ·), not a full-width line —
///     the kind of seam you'd see on a paper folder, not the
///     default 1px hairline.
///   • Section headers carry a small heart/leaf accent to set them
///     apart as "tab headings" rather than another line of text.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A subtle paper-fibre background. Drawn as a faint warm wash with
/// sparse speckle — a CustomPaint overlay so the texture stays
/// cheap to render and doesn't fight any text laid on top.
class PaperBackground extends StatelessWidget {
  final Widget child;
  final double speckleOpacity;
  const PaperBackground({
    super.key,
    required this.child,
    this.speckleOpacity = 0.025,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Warm wash — top slightly lighter than bottom, like light
        // falling on a sheet of paper.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.isDark
                    ? const Color(0xFF221C16)
                    : const Color(0xFFFFFCF6),
                AppColors.background,
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        // Faint speckle — drawn once, on top of the wash but under
        // the child. Cached by Flutter so re-builds don't repaint.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PaperSpecklePainter(opacity: speckleOpacity),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PaperSpecklePainter extends CustomPainter {
  final double opacity;
  _PaperSpecklePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Cheap deterministic speckle — same coordinates per (width,
    // height) so it doesn't dance around on scroll. 0.025 alpha
    // is barely visible on a 1080p screen; the eye reads "paper"
    // rather than "noise".
    final paint = Paint()..color = AppColors.wood.withValues(alpha: opacity);
    const cellSize = 36.0;
    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        // Hash-based deterministic offset.
        final h = (x * 12.9898 + y * 78.233).remainder(1000) / 1000;
        if (h > 0.6) {
          final dx = (h * 17) % cellSize;
          final dy = ((h * 23) % cellSize);
          canvas.drawCircle(Offset(x + dx, y + dy), 0.6, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperSpecklePainter old) =>
      old.opacity != opacity;
}

/// Hand-stamped kraft-paper app bar. Replaces the default Material
/// `AppBar` (which paints a flat blue-grey bar in M3). The bar is a
/// warm cream strip with a stitched dotted line at the bottom and
/// a small heart accent on the right, so the title looks printed
/// onto a page tab rather than floating in a generic chrome.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  // Either a localized string or a fully composed widget — the
  // latter lets the call site pass a `Consumer<X>` and stay
  // reactive without giving up the static "sub-title" placement
  // under the main title.
  final Object? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Color? backgroundColor;

  const HomeAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.backgroundColor,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : kToolbarHeight + 18);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              // Mirrors `preferredSize`'s own `+ 18` for the subtitle
              // case — without it this box stays a fixed 48px even
              // with a subtitle line added below the title, and the
              // inner Column overflows by a few pixels on narrow /
              // larger-font-scale devices.
              height: subtitle == null
                  ? kToolbarHeight - 8
                  : kToolbarHeight - 8 + 18,
              child: Row(
                children: [
                  if (leading != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: leading!,
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: subtitle is String
                                ? Text(
                                    subtitle as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.inkFaded,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : subtitle as Widget,
                          ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: actions)
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
            // Dotted stitched line — the seam at the bottom of the
            // page tab. Slightly inset from the edges so it doesn't
            // hit the device's corner radius.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 1,
                child: CustomPaint(
                  painter: _StitchedLinePainter(),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _StitchedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dash, size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _StitchedLinePainter old) => false;
}

/// A paper card with a hair-thin terracotta border and a soft
/// 2-step drop shadow. Replaces Material `Card` (which paints a
/// flat surface with a single offset shadow). Optional [accent]
/// paints a thin terracotta line under the top edge — the visual
/// shorthand for "this card was just placed on the table".
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final double radius;

  const HomeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.elevated = true,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final surface = color ?? AppColors.surface;
    final shape = _PaperCardShape(
      radius: radius,
      fill: surface,
      border: AppColors.primary.withValues(alpha: 0.10),
      accent: AppColors.primary,
      shadow: AppColors.shadow,
      elevated: elevated,
    );
    final body = Padding(padding: padding, child: child);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: CustomPaint(
          painter: shape,
          child: body,
        ),
      ),
    );
  }
}

class _PaperCardShape extends CustomPainter {
  final double radius;
  final Color fill;
  final Color border;
  final Color accent;
  final Color shadow;
  final bool elevated;
  _PaperCardShape({
    required this.radius,
    required this.fill,
    required this.border,
    required this.accent,
    required this.shadow,
    required this.elevated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    if (elevated) {
      // 2-step shadow — a tight + soft drop, so the card looks
      // like it was placed on linen and is gently catching the
      // light from above. Cheaper than a real elevation since
      // we draw it once here.
      final shadowPaint = Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);
    }

    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperCardShape old) =>
      old.fill != fill || old.border != border || old.radius != radius;
}

/// Filled pill button — the primary action. Soft terracotta gradient
/// (top lighter, bottom darker) so the button looks like a fabric
/// badge, not a flat Material elevation. Pressed state collapses
/// the gradient to the darker shade with a small downward nudge.
class HomePrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final double height;
  final double radius;
  final bool fullWidth;

  const HomePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.height = 50,
    this.radius = 26,
    this.fullWidth = false,
  });

  @override
  State<HomePrimaryButton> createState() => _HomePrimaryButtonState();
}

class _HomePrimaryButtonState extends State<HomePrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: disabled
              ? [AppColors.divider, AppColors.divider]
              : _pressed
                  ? [AppColors.primaryDark, AppColors.wood]
                  : [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: disabled || _pressed
            ? const []
            : [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      transform: _pressed
          ? (Matrix4.identity()..translateByDouble(0.0, 1.5, 0.0, 1.0))
          : Matrix4.identity(),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leadingIcon != null) ...[
              Icon(
                widget.leadingIcon,
                size: 18,
                color: disabled ? AppColors.inkFaded : Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: disabled ? AppColors.inkFaded : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    final child = GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: btn,
    );

    if (widget.fullWidth) return child;
    return IntrinsicWidth(child: child);
  }
}

/// Secondary text action — terracotta with a soft underline that
/// thickens on press. Replaces Material `TextButton` (no border,
/// no fill, just the underline).
class HomeGhostButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? trailingIcon;
  const HomeGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.trailingIcon,
  });

  @override
  State<HomeGhostButton> createState() => _HomeGhostButtonState();
}

class _HomeGhostButtonState extends State<HomeGhostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.primary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: c.withValues(alpha: _pressed ? 1.0 : 0.0),
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c,
                letterSpacing: 0.3,
              ),
            ),
            if (widget.trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(widget.trailingIcon, size: 16, color: c),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row item with the home styling: avatar on the left, text in
/// the middle, optional trailing slot. Subtle hair-thin separator
/// below the row, like a ledger entry, not the default Material
/// 1px divider.
class HomeListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? trailingBadgeText;
  final bool showSeparator;

  const HomeListItem({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.trailingBadgeText,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                  if (trailingBadgeText != null) ...[
                    const SizedBox(width: 8),
                    _TrailingBadge(text: trailingBadgeText!),
                  ],
                ],
              ),
            ),
            if (showSeparator)
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Container(
                  height: 0.6,
                  color: AppColors.divider.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrailingBadge extends StatelessWidget {
  final String text;
  const _TrailingBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A small inline pill / chip — used for section tags, status
/// badges. Different from the danger badge above; this is the
/// neutral "tag" surface.
class HomePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  const HomePill({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.primaryLight.withValues(alpha: 0.18);
    final fg = foreground ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with a small "家" (home) heart/leaf accent on
/// the right and a hairline underneath. Use this instead of a bare
/// `Text` + `Divider` combo to give sections visual identity.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final IconData accentIcon;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.accentIcon = Icons.favorite_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(accentIcon, size: 12, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkFaded,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: HomeGhostButton(
                label: trailingLabel!,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// A short, decorative divider — three terracotta dots with
/// breathing room on either side. Replaces the default
/// full-width `Divider` (which is too loud for a paper-craft
/// aesthetic).
class HomeDottedDivider extends StatelessWidget {
  final double indent;
  const HomeDottedDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
