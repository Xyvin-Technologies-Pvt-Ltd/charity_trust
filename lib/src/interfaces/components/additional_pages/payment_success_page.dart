import 'package:Annujoom/src/data/constants/color_constants.dart';
import 'package:Annujoom/src/data/providers/file_opener_provider.dart';
import 'package:Annujoom/src/data/providers/receipt_provider.dart';
import 'package:Annujoom/src/data/services/snackbar_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentSuccessPage extends ConsumerStatefulWidget {
  final String? orderId;
  final String? paymentId;
  final double? amount;
  final String? receipt;
  const PaymentSuccessPage({
    super.key,
    this.orderId,
    this.paymentId,
    this.amount,
    this.receipt,
  });

  @override
  ConsumerState<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends ConsumerState<PaymentSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _cardSlideUp;
  late final Animation<double> _checkDraw;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _cardSlideUp = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
    );

    _checkDraw = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeInOut),
    );

    _pulse = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4F4F4),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: Icon(
                Icons.close,
                color: kPrimaryColor,
                size: 30,
              ))
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.45),
                        end: Offset.zero,
                      ).animate(_cardSlideUp),
                      child: _SuccessCard(
                        amount: widget.amount,
                        checkProgress: _checkDraw,
                        pulse: _pulse,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Receipt details fade-in
                    Opacity(
                      opacity: _pulse.value,
                      child: _ReceiptDetails(
                        orderId: widget.orderId,
                        paymentId: widget.paymentId,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Opacity(
                      opacity: _pulse.value,
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * _pulse.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShareButton(receiptUrl: widget.receipt),
                            const SizedBox(width: 15),
                            _DownloadButton(receiptUrl: widget.receipt),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

//
// SUCCESS CARD (WHITE THEME)
//
class _SuccessCard extends StatelessWidget {
  final Animation<double> checkProgress;
  final Animation<double> pulse;
  final double? amount;

  const _SuccessCard({
    required this.checkProgress,
    required this.pulse,
    this.amount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Check icon
            _AnimatedCheck(progress: checkProgress, pulse: pulse),

            const SizedBox(height: 18),

            const Text(
              "Payment Successful",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your payment was completed successfully.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 20),

            // Amount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "₹ ${(amount ?? 0).toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

//
// CHECK ANIMATION (WHITE THEME)
//
class _AnimatedCheck extends StatelessWidget {
  final Animation<double> progress;
  final Animation<double> pulse;

  const _AnimatedCheck({
    required this.progress,
    required this.pulse,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    final merged = Listenable.merge([progress, pulse]);

    return AnimatedBuilder(
      animation: merged,
      builder: (context, child) {
        final glow = Curves.easeOut.transform(progress.value);
        final p = Tween<double>(begin: 0.7, end: 1.0).transform(pulse.value);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow halo
            Container(
              width: size * (1 + glow * 0.08),
              height: size * (1 + glow * 0.08),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.35 * glow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // White circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),

            // Check mark
            SizedBox(
              width: size * 0.65,
              height: size * 0.65,
              child: CustomPaint(
                painter: _CheckPainter(progress.value),
              ),
            ),

            // Pulse outline
            Container(
              width: size * p,
              height: size * p,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withOpacity(0.10),
                  width: 4 * pulse.value,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

//
// CHECK DRAWING
//
class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kGreen
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.1, size.height * 0.55);
    final mid = Offset(size.width * 0.38, size.height * 0.78);
    final end = Offset(size.width * 0.88, size.height * 0.20);

    final l1 = (start - mid).distance;
    final l2 = (mid - end).distance;
    double draw = (l1 + l2) * progress;

    if (draw <= 0) return;

    if (draw <= l1) {
      canvas.drawLine(start, Offset.lerp(start, mid, draw / l1)!, paint);
      return;
    }

    canvas.drawLine(start, mid, paint);
    draw -= l1;

    canvas.drawLine(mid, Offset.lerp(mid, end, draw / l2)!, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

//
// RECEIPT DETAILS
//
class _ReceiptDetails extends StatelessWidget {
  final String? orderId;
  final String? paymentId;

  const _ReceiptDetails({
    super.key,
    this.orderId,
    this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  •  "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          children: [
            _row("Order ID", orderId ?? "N/A"),
            const SizedBox(height: 8),
            if (paymentId != null) ...[
              _row("Payment ID", paymentId!),
              const SizedBox(height: 8),
            ],
            _row("Date", date),
            const SizedBox(height: 8),
            _row("Status", "Completed"),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 15)),
      ],
    );
  }
}

//
// SHARE BUTTON
//
class _ShareButton extends ConsumerWidget {
  final String? receiptUrl;

  const _ShareButton({
    required this.receiptUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: receiptUrl == null
          ? null
          : () async {
              try {
                await ref.read(shareReceiptProvider(receiptUrl!).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Receipt shared successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to share: $e')),
                  );
                }
              }
            },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: kWhite,
        foregroundColor: kBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text("Share"),
    );
  }
}

//
// DOWNLOAD BUTTON
//
class _DownloadButton extends ConsumerStatefulWidget {
  final String? receiptUrl;

  const _DownloadButton({
    required this.receiptUrl,
    super.key,
  });

  @override
  ConsumerState<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<_DownloadButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (widget.receiptUrl == null || _isLoading)
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                final filePath =
                    await ref.read(downloadReceiptProvider(widget.receiptUrl!).future);
                await ref.read(openPdfProvider(filePath).future);
              } catch (e) {
                if (mounted) {
                  SnackbarService().showSnackBar(
                    'failedToOpenReceipt'.tr(args: [e.toString()]),
                    type: SnackbarType.error,
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kWhite,
              ),
            )
          : const Text("Download"),
    );
  }
}
