import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


enum AppTone { primary, success, warning, danger, info, accent, neutral }

extension AppToneColors on AppTone {
  Color get color {
    switch (this) {
      case AppTone.primary:
        return AppTheme.primary;
      case AppTone.success:
        return AppTheme.success;
      case AppTone.warning:
        return AppTheme.warning;
      case AppTone.danger:
        return AppTheme.danger;
      case AppTone.info:
        return const Color(0xFF1E88E5);
      case AppTone.accent:
        return AppTheme.accent;
      case AppTone.neutral:
        return AppTheme.textMuted;
    }
  }


  Color get on => this == AppTone.accent ? AppTheme.onAccent : Colors.white;

  Color get ink => this == AppTone.accent ? AppTheme.accentInk : color;

  Color get soft => color.withValues(alpha: 0.10);

  Color get edge => color.withValues(alpha: 0.24);
}


class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textSubtle,
        ),
      ),
    );
  }
}


class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.tone = AppTone.primary,
    this.size = 48,
    this.solid = false,
  });

  final IconData icon;
  final AppTone tone;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? tone.color : tone.soft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: solid ? tone.on : tone.ink,
      ),
    );
  }
}


class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppTone.success,
  });

  final String label;
  final IconData? icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: tone.ink),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppTheme.radiusLg,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? AppTheme.border),
        boxShadow: shadow ? AppTheme.softShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppTheme.textSubtle),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: emphasize ? 17 : 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}


class HintBanner extends StatelessWidget {
  const HintBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppTone.primary,
  });

  final String text;
  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}


class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
    this.titleSize = 24,
  });

  final double titleSize;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _WavePainter(),
      child: Container(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 46),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null) ...[
                      _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!),
                      const SizedBox(width: 14),
                    ] else
                      const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.display(size: titleSize, color: Colors.white),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                if (bottom != null) ...[
                  const SizedBox(height: 18),
                  bottom!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class WaveBand extends StatelessWidget {
  const WaveBand({super.key, this.title, this.subtitle, this.child});

  final String? title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _WavePainter(),
      child: Container(
        padding: const EdgeInsets.only(top: 0, bottom: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title!.toUpperCase(),
                  style: AppTheme.display(size: 27, color: Colors.white),
                ),
              ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    this.onTop = false,
    this.colors = const [AppTheme.primary, AppTheme.darkBlue],
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  final bool onTop;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _WaveClipper(onTop: onTop).getClip(size);
    final paint = Paint()
      ..shader = LinearGradient(begin: begin, end: end, colors: colors)
          .createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.onTop != onTop || old.colors != colors || old.begin != begin || old.end != end;
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper({this.onTop = false});

  final bool onTop;

  @override
  Path getClip(Size s) {
    const d = 28.0;
    final p = Path();
    if (onTop) {
      p.moveTo(0, d);
      p.cubicTo(s.width * 0.3, -d * 0.6, s.width * 0.65, d * 1.8, s.width, d * 0.4);
      p.lineTo(s.width, s.height);
      p.lineTo(0, s.height);
    } else {
      p.lineTo(0, s.height - d * 0.4);
      p.cubicTo(s.width * 0.35, s.height + d * 0.6, s.width * 0.7, s.height - d * 1.8, s.width, s.height - d);
      p.lineTo(s.width, 0);
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) => oldClipper.onTop != onTop;
}


class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    this.label,
  });


  final int current;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (i) {
            final active = i < current;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                height: 5,
                decoration: BoxDecoration(
                  color: active ? AppTheme.accent : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            'Etapa $current de $total · $label',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}


class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.tone = AppTone.accent,
    this.outlined = false,
    this.onDark = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppTone tone;
  final bool outlined;
  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = tone.color;
    const shape = StadiumBorder();
    final spinnerColor = outlined ? (onDark ? Colors.white : tone.ink) : tone.on;

    final content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(size: 17, weight: FontWeight.w700, height: 1.1),
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: onDark ? Colors.white : tone.ink,
                side: BorderSide(
                  color: onDark ? Colors.white.withValues(alpha: 0.55) : tone.edge,
                  width: 1.5,
                ),
                shape: shape,
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: tone.on,
                disabledBackgroundColor: color.withValues(alpha: 0.45),
                disabledForegroundColor: tone.on.withValues(alpha: 0.6),
                elevation: 0,
                shape: shape,
              ),
              child: content,
            ),
    );
  }
}


class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.dark = false,
  });

  final Widget primary;
  final Widget? secondary;


  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.transparent : Colors.white,
        border: dark ? null : const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            primary,
            if (secondary != null) ...[
              const SizedBox(height: 10),
              secondary!,
            ],
          ],
        ),
      ),
    );
  }
}


class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tone = AppTone.primary,
    this.filled = true,
    this.minHeight = 150,
    this.backgroundIcon,
    this.backgroundBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final AppTone tone;
  final bool filled;
  final double minHeight;


  final IconData? backgroundIcon;


  final Widget Function(double size, Color color)? backgroundBuilder;

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    final radius = BorderRadius.circular(24);
    final fg = filled ? Colors.white : AppTheme.textDark;
    final sub = filled ? Colors.white.withValues(alpha: 0.85) : AppTheme.textMuted;

    final body = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: filled ? AppTheme.accent : tone.soft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: filled ? AppTheme.onAccent : tone.ink),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filled ? Colors.white.withValues(alpha: 0.18) : tone.soft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: filled ? Colors.white : tone.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.display(size: 25, color: fg)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: sub, fontSize: 14, height: 1.4)),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: filled ? AppTheme.coloredShadow(c) : AppTheme.softShadow,
      ),
      child: Material(
        color: filled ? Colors.transparent : Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c, Color.lerp(c, AppTheme.navy, 0.45)!],
                  )
                : null,
            borderRadius: radius,
            border: filled ? null : Border.all(color: AppTheme.border),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // Ícone grande no fundo, à direita
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.maxHeight * 0.8;
                        final bgColor = filled ? Colors.white : c;
                        final bgOpacity = filled ? 0.12 : 0.07;
                        return Align(
                          alignment: const Alignment(1.0, 0),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: backgroundBuilder != null
                                ? Opacity(
                                    opacity: bgOpacity,
                                    child: backgroundBuilder!(size, bgColor),
                                  )
                                : Icon(
                                    backgroundIcon ?? icon,
                                    size: size,
                                    color: bgColor.withValues(alpha: bgOpacity),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = AppTone.success,
    this.action,
    this.onDark = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final AppTone tone;
  final Widget? action;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, size: 38, color: c),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.display(size: 25, color: onDark ? Colors.white : AppTheme.textDark),
        ),
        if (message != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: onDark ? Colors.white70 : AppTheme.textMuted,
              ),
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          action!,
        ],
      ],
    );
  }
}


class ScanBackdrop extends StatelessWidget {
  const ScanBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.scanGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WavePainter(
                  onTop: true,
                  colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.07)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}


class GlassHint extends StatelessWidget {
  const GlassHint({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ScrollFill extends StatelessWidget {
  const ScrollFill({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - padding.vertical,
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}


class ScanTopBar extends StatelessWidget {
  const ScanTopBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(size: 20, color: Colors.white),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
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


class DesktopHeader extends StatelessWidget {
  const DesktopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _WavePainter(begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 50),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.display(size: 28, color: Colors.white)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}


class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.onAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon, size: 22),
      label: Text(label, style: AppTheme.display(size: 17, weight: FontWeight.w700, height: 1.1)),
    );
  }
}
