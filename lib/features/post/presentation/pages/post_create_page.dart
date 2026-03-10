import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/post_image.dart';
import '../../domain/entities/post.dart';
import '../bloc/post_bloc.dart';

const int _maxImageBytes = 3 * 1024 * 1024; // 3MB

class PostCreatePage extends StatefulWidget {
  const PostCreatePage({super.key});

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _type = 'post';
  String? _imageBase64;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지는 3MB 이하여야 해요.')),
        );
      }
      return;
    }
    setState(() {
      _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  void _removeImage() {
    setState(() => _imageBase64 = null);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목/내용을 입력해줘')),
      );
      return;
    }

    final post = Post(
      id: DateTime.now().microsecondsSinceEpoch,
      title: title,
      content: content,
      type: _type,
      author: 'me',
      createdAt: DateTime.now(),
      imageUrl: _imageBase64,
    );

    context.read<PostBloc>().add(AddPost(post));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시글 작성'),
        actions: [TextButton(onPressed: _submit, child: const Text('등록'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'post', label: Text('게시글')),
                ButtonSegment(value: 'question', label: Text('질문')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('이미지 추가'),
                ),
              ],
            ),
            if (_imageBase64 != null) ...[
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: PostImage(imageUrl: _imageBase64, width: double.infinity, height: 320),
                  ),
                  IconButton(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.white70),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: '내용',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
