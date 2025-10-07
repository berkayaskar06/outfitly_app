import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/api_service.dart';
import '../../shared/application/library_controller.dart';
import '../../tryon/application/try_on_controller.dart';

class ProductUploadPage extends ConsumerStatefulWidget {
  const ProductUploadPage({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<ProductUploadPage> createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends ConsumerState<ProductUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _categories = <String>[
    'Dresses',
    'Tops',
    'Outerwear',
    'Bottoms',
    'Shoes',
    'Accessories',
  ];

  String? _selectedCategory;
  XFile? _personFile;
  XFile? _productFile;
  String? _prompt;
  bool _promptLoading = false;
  String? _promptError;

  @override
  void initState() {
    super.initState();
    // İlk seçim yok, kullanıcı seçmeli
    _selectedCategory = null;
    
    // Eğer person id varsa onu yükle
    if (widget.personId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPersonById(widget.personId!);
      });
    }
  }
  
  void _loadPersonById(String personId) {
    final library = ref.read(libraryControllerProvider);
    final person = library.persons.where((p) => p.id == personId).firstOrNull;
    if (person != null && person.imagePath.isNotEmpty) {
      setState(() {
        _personFile = XFile(person.imagePath);
      });
      ref.read(tryOnControllerProvider.notifier).state = 
          ref.read(tryOnControllerProvider.notifier).state.copyWith(
            personId: person.id,
          );
    }
  }

  Future<void> _pickPerson() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) {
      return;
    }
    setState(() => _personFile = file);
    await ref
        .read(tryOnControllerProvider.notifier)
        .uploadPerson(File(file.path), label: 'You');
  }

  Future<void> _pickProduct() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null) {
      return;
    }
    setState(() => _productFile = file);
    
    // Eğer category seçilmişse direkt upload et
    if (_selectedCategory != null) {
      await ref
          .read(tryOnControllerProvider.notifier)
          .uploadProduct(File(file.path), category: _selectedCategory!);
    }
    // Category seçilmemişse sadece fotoğrafı sakla, upload etme
  }

  Future<void> _loadPromptForCategory(String category) async {
    setState(() {
      _promptLoading = true;
      _promptError = null;
    });
    try {
      final prompt = await ref.read(apiServiceProvider).fetchPrompt(category);
      setState(() {
        _prompt = prompt.replaceAll('{category}', category);
        _promptLoading = false;
      });
    } catch (error) {
      setState(() {
        _promptLoading = false;
        _promptError = 'Prompt alınamadı';
        _prompt = null;
      });
    }
  }

  Future<void> _runTryOn() async {
    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir kategori seçin.'),
          ),
        );
      }
      return;
    }
    
    if (_promptLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt hazırlanıyor, lütfen bekleyin.'),
          ),
        );
      }
      return;
    }

    final prompt = _prompt;
    if (prompt == null || prompt.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt alınamadı, lütfen tekrar deneyin.'),
          ),
        );
      }
      return;
    }

    final controller = ref.read(tryOnControllerProvider.notifier);
    _showLoadingDialog();
    final result = await controller.generateTryOn(prompt: prompt);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (result != null && mounted) {
      context.push('/try-on/result', extra: result);
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 80),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'AI kompoziti hazırlanıyor...\nBu işlem birkaç saniye sürebilir.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCategoryChanged(String? value) async {
    if (value == null || value == _selectedCategory) {
      return;
    }
    setState(() {
      _selectedCategory = value;
      _prompt = null; // Prompt'u temizle
    });
    
    // Eğer product fotoğrafı seçilmişse ve henüz upload edilmemişse, şimdi upload et
    if (_productFile != null) {
      final state = ref.read(tryOnControllerProvider);
      if (state.productId == null) {
        await ref
            .read(tryOnControllerProvider.notifier)
            .uploadProduct(File(_productFile!.path), category: value);
      }
    }
    
    // Yeni kategori için prompt yükle
    await _loadPromptForCategory(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tryOnControllerProvider);
    final isBusy = state.isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload & style')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Follow the steps to create your try-on.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _InstructionCard(
                icon: Icons.person_outline,
                title: 'Upload person photo',
                description:
                    'Use the same capture tips from onboarding. Make sure the background is clean and the image is clear.',
                buttonLabel: _personFile == null
                    ? 'Upload portrait'
                    : 'Replace portrait',
                onPressed: isBusy ? null : _pickPerson,
                preview: _personFile != null
                    ? Image.file(File(_personFile!.path), fit: BoxFit.cover)
                    : null,
              ),
              const SizedBox(height: 20),
              _InstructionCard(
                icon: Icons.checkroom_outlined,
                title: 'Upload product photo',
                description: _selectedCategory == null
                    ? 'First select a category below, then upload your product.'
                    : 'Select the garment image in high resolution. A neutral background helps for clean compositing.',
                buttonLabel: _productFile == null
                    ? 'Upload product'
                    : 'Replace product',
                onPressed: isBusy ? null : _pickProduct,
                preview: _productFile != null
                    ? Image.file(File(_productFile!.path), fit: BoxFit.cover)
                    : null,
              ),
              const SizedBox(height: 20),
              _CategorySelector(
                categories: _categories,
                value: _selectedCategory,
                onChanged: isBusy ? null : _onCategoryChanged,
              ),
              if (_promptLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(),
                ),
              if (_promptError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _promptError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: isBusy ? null : _runTryOn,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Generate try-on'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () {
                        ref
                            .read(tryOnControllerProvider.notifier)
                            .resetSession();
                        setState(() {
                          _personFile = null;
                          _productFile = null;
                          _prompt = null;
                        });
                      },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.preview,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 32),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            if (preview != null)
              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: preview,
              ),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<String> categories;
  final String? value;
  final ValueChanged<String?>? onChanged;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dresses':
        return Icons.checkroom;
      case 'tops':
        return Icons.dry_cleaning;
      case 'outerwear':
        return Icons.ac_unit;
      case 'bottoms':
        return Icons.shopping_bag;
      case 'shoes':
        return Icons.ice_skating;
      case 'accessories':
        return Icons.watch;
      default:
        return Icons.checkroom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Product category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = category == value;
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(category),
                ],
              ),
              onSelected: onChanged == null
                  ? null
                  : (selected) {
                      if (selected) {
                        onChanged!(category);
                      }
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}
