import 'package:flutter/material.dart';

import '../../domain/entities/post_search_filter.dart';

/// 필터 3종: 타입, 작성자, 기간 (동시 적용 가능).
class PostFilterSheet extends StatefulWidget {
  final PostSearchFilter initial;

  const PostFilterSheet({super.key, this.initial = PostSearchFilter.empty});

  @override
  State<PostFilterSheet> createState() => _PostFilterSheetState();
}

class _PostFilterSheetState extends State<PostFilterSheet> {
  late String _type;
  late TextEditingController _authorController;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type ?? 'all';
    _authorController = TextEditingController(text: widget.initial.author ?? '');
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
  }

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  PostSearchFilter get _currentFilter => PostSearchFilter(
        type: _type == 'all' ? null : _type,
        author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '필터',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('유형', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('전체')),
              ButtonSegment(value: 'post', label: Text('게시글')),
              ButtonSegment(value: 'question', label: Text('질문')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          const Text('작성자', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              hintText: '예: me, other',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('기간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _dateFrom = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateFrom == null ? '시작일' : _formatDate(_dateFrom!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _dateTo = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateTo == null ? '종료일' : _formatDate(_dateTo!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _type = 'all';
                    _authorController.clear();
                    _dateFrom = null;
                    _dateTo = null;
                  });
                },
                child: const Text('초기화'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _currentFilter),
                  child: const Text('적용'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
