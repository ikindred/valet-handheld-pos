enum ReceiptPartStatus { pending, printing, printed, failed }

class ReceiptPartState {
  const ReceiptPartState({
    required this.part,
    required this.label,
    required this.status,
  });

  final int part;
  final String label;
  final ReceiptPartStatus status;

  ReceiptPartState copyWith({ReceiptPartStatus? status}) => ReceiptPartState(
        part: part,
        label: label,
        status: status ?? this.status,
      );
}

const initialReceiptParts = [
  ReceiptPartState(
    part: 1,
    label: 'Attendant Copy',
    status: ReceiptPartStatus.pending,
  ),
  ReceiptPartState(
    part: 2,
    label: 'Customer Claim Stub',
    status: ReceiptPartStatus.pending,
  ),
  ReceiptPartState(
    part: 3,
    label: 'Key Tag',
    status: ReceiptPartStatus.pending,
  ),
];
