import 'package:flutter/material.dart';
import 'package:open2fa/main.dart';
import 'package:otp/otp.dart';

class TwoFactorCircularProgressIndicator extends StatefulWidget {
  const TwoFactorCircularProgressIndicator({
    super.key,
    this.interval = 30,
    required this.onRestart,
  });

  final int interval;
  final void Function() onRestart;

  @override
  State<TwoFactorCircularProgressIndicator> createState() =>
      _TwoFactorCircularProgressIndicatorState();
}

class _TwoFactorCircularProgressIndicatorState
    extends State<TwoFactorCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _createController() {
    final interval = widget.interval;
    double lastValue = 0.0;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: interval),
    );
    _syncController();

    _controller.addListener(() {
      if (lastValue > 0.99 && _controller.value < 0.01) {
        widget.onRestart();
      }
      lastValue = _controller.value;
    });
  }

  void _syncController() {
    final interval = widget.interval;
    final remaining = OTP.remainingSeconds(interval: interval);
    final progress = 1 - (remaining / interval);

    _controller
      ..stop()
      ..reset()
      ..forward(from: progress)
      ..repeat();
      setState(() {});
  }

  @override
  void initState() {
    _createController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CircularProgressIndicator(
              value: _controller.value,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            );
          },
        ),
      ],
    );
  }
}
