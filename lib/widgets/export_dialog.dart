import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

class ExportFilterOptions {
  final String reportType; // 'donations', 'expenses', 'both'
  final String? collectorId; // null = all
  final DateTime startDate;
  final DateTime endDate;

  ExportFilterOptions({
    required this.reportType,
    this.collectorId,
    required this.startDate,
    required this.endDate,
  });
}

class ExportDialog extends StatefulWidget {
  final List<UserModel> collectors;
  final String exportFormat; // 'PDF' or 'Excel'

  const ExportDialog({
    super.key,
    required this.collectors,
    required this.exportFormat,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _reportType = 'both';
  String? _selectedCollectorId;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export to ${widget.exportFormat}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Content',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _reportType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'both',
                  child: Text('Donations & Expenses'),
                ),
                DropdownMenuItem(
                  value: 'donations',
                  child: Text('Donations Only'),
                ),
                DropdownMenuItem(
                  value: 'expenses',
                  child: Text('Expenses Only'),
                ),
                DropdownMenuItem(
                  value: 'salaries',
                  child: Text('Salaries Only'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _reportType = val);
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Collector Filter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedCollectorId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Collectors'),
                ),
                ...widget.collectors.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedCollectorId = val);
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(
              context,
              ExportFilterOptions(
                reportType: _reportType,
                collectorId: _selectedCollectorId,
                startDate: _startDate,
                endDate: _endDate,
              ),
            );
          },
          icon: Icon(
            widget.exportFormat == 'PDF'
                ? Icons.picture_as_pdf
                : Icons.table_chart,
          ),
          label: const Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
