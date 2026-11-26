import 'package:easy_localization/easy_localization.dart';
import 'package:Annujoom/src/data/constants/color_constants.dart';
import 'package:Annujoom/src/data/constants/style_constants.dart';
import 'package:Annujoom/src/interfaces/components/text_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Annujoom/src/data/providers/receipt_provider.dart';
import 'package:Annujoom/src/data/providers/file_opener_provider.dart';
import 'package:Annujoom/src/data/services/snackbar_service.dart';

class TransactionCard extends ConsumerStatefulWidget {
  final String id;
  final String type;
  final String date;
  final String amount;
  final String status;
  final String receipt;
  final String donorName;
  const TransactionCard({
    super.key,
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
    required this.receipt,
    this.donorName = '',
  });

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard> {
  bool _isDownloading = false;

  Future<void> _handleDownloadReceipt() async {
    if (_isDownloading || widget.receipt.isEmpty) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final filePath =
          await ref.read(downloadReceiptProvider(widget.receipt).future);
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
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.receipt.isEmpty ? null : _handleDownloadReceipt,
      child: Container(
        decoration: BoxDecoration(
          color: kCardBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextPill(
                  color: Color(0xFFDBDBDB),
                  text: "transactionId".tr(args: [widget.id]),
                  textStyle: kSmallerTitleR.copyWith(
                    fontSize: 10,
                  ),
                ),
                if (widget.receipt.isNotEmpty)
                  _isDownloading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kPrimaryColor,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _handleDownloadReceipt,
                          icon: const Icon(Icons.download),
                          color: kPrimaryColor,
                          tooltip: 'downloadReceipt'.tr(),
                          visualDensity: VisualDensity.compact,
                        ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.donorName.isNotEmpty) ...[
              _row("name".tr(), widget.donorName),
              const Divider(),
            ],
            _row("type".tr(), widget.type),
            const Divider(),
            _row("dateTime".tr(), widget.date),
            const Divider(),
            _row("amountPaid".tr(), widget.amount),
            const Divider(),
            _row("statusLabel".tr(), widget.status, isStatus: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String r, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: kSmallerTitleL),
        isStatus
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: r.toLowerCase() == 'pending'
                      ? Colors.amber
                      : Color(0xFF2E7D32), // Green for success/other statuses
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(r, style: kSmallTitleSB.copyWith(color: kWhite)),
              )
            : Text(r, style: kSmallerTitleM),
      ],
    );
  }
}
