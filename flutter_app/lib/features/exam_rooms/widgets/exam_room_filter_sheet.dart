import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExamRoomFilterSheet extends StatefulWidget {
  final String? currentStatus;
  final DateTime? currentDate;
  final String? currentTimeSlot;
  final Function({
    String? status,
    DateTime? date,
    String? timeSlot,
  }) onApply;

  const ExamRoomFilterSheet({
    super.key,
    this.currentStatus,
    this.currentDate,
    this.currentTimeSlot,
    required this.onApply,
  });

  @override
  State<ExamRoomFilterSheet> createState() => _ExamRoomFilterSheetState();
}

class _ExamRoomFilterSheetState extends State<ExamRoomFilterSheet> {
  String? _selectedStatus;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedDate = widget.currentDate;
    _selectedTimeSlot = widget.currentTimeSlot;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Status'),
          const SizedBox(height: 12),
          _buildStatusChips(),
          const SizedBox(height: 24),
          _buildSectionTitle('Date'),
          const SizedBox(height: 12),
          _buildDateField(),
          const SizedBox(height: 24),
          _buildSectionTitle('Time Slot'),
          const SizedBox(height: 12),
          _buildTimeSlotField(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Clear All Filters',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusChip('All', null),
        _buildStatusChip('Scheduled', 'scheduled'),
        _buildStatusChip('In Progress', 'in_progress'),
        _buildStatusChip('Completed', 'completed'),
      ],
    );
  }

  Widget _buildStatusChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    Color backgroundColor;
    Color textColor;

    if (isSelected) {
      if (status == null) {
        backgroundColor = Colors.grey[700]!;
        textColor = Colors.white;
      } else {
        switch (status) {
          case 'scheduled':
            backgroundColor = const Color(0xFF2196F3);
            textColor = Colors.white;
            break;
          case 'in_progress':
            backgroundColor = const Color(0xFFFF9800);
            textColor = Colors.white;
            break;
          case 'completed':
            backgroundColor = const Color(0xFF4CAF50);
            textColor = Colors.white;
            break;
          default:
            backgroundColor = Colors.grey[700]!;
            textColor = Colors.white;
        }
      }
    } else {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextField(
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        hintText: 'e.g., Jan 15',
        hintStyle: TextStyle(color: Colors.grey[400]),
        suffixIcon: _selectedDate != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() => _selectedDate = null),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      controller: TextEditingController(
        text: _selectedDate != null
            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
            : '',
      ),
    );
  }

  Widget _buildTimeSlotField() {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'e.g., 09:00 AM or AM/PM',
        hintStyle: TextStyle(color: Colors.grey[400]),
        suffixIcon: _selectedTimeSlot != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() => _selectedTimeSlot = null),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      controller: TextEditingController(text: _selectedTimeSlot ?? ''),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      status: _selectedStatus,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot,
    );
    Navigator.pop(context);
  }
}
