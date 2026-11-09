import 'package:flutter/material.dart';

class StepFadeRoute<T> extends PageRouteBuilder<T> {
  StepFadeRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final value = Curves.easeOut.transform(animation.value);
                final opacity = animation.status == AnimationStatus.reverse
                    ? value
                    : 0.35 + 0.65 * value;
                return Opacity(opacity: opacity, child: child);
              },
            );
          },
        );
}

class StepFade extends StatefulWidget {
  const StepFade({super.key, required this.child, this.background});

  final Widget child;
  final Color? background;

  @override
  State<StepFade> createState() => _StepFadeState();
}

class _StepFadeState extends State<StepFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<double> _fade = Tween<double>(begin: 0.35, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void didUpdateWidget(StepFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!Widget.canUpdate(oldWidget.child, widget.child)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = FadeTransition(opacity: _fade, child: widget.child);
    final background = widget.background;
    if (background == null) return fade;
    return ColoredBox(color: background, child: fade);
  }
}
