import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/services/receipt_ocr_service.dart';
import 'package:project_base/utils/app_date_picker.dart';
import 'package:project_base/utils/category_visuals.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  bool isScanningReceipt = false;
  bool isSaving = false;
  DateTime selectedDate = DateTime.now();
  XFile? receiptImage;
  Uint8List? receiptImageBytes;
  ReceiptOcrResult? receiptResult;
  final ImagePicker imagePicker = ImagePicker();
  final ReceiptOcrService receiptOcrService = ReceiptOcrService();

  Future<void> pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final customCategoryController = TextEditingController();

  final List<String> categories = [
    "Food & Drink",
    "Shopping",
    "Transport",
    "Coffee",
    "Housing",
    "Entertainment",
    "Salary",
    "Other",
  ];
  String category = "Food & Drink";
  String account = "Main Card";

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    notesController.dispose();
    amountController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCategories() async {
    try {
      final loadedCategories = await ApiService().getCategories();
      if (!mounted) return;

      setState(() {
        for (final item in loadedCategories) {
          final matchesType =
              item.type == 'both' ||
              (isExpense && item.type == 'expense') ||
              (!isExpense && item.type == 'income');
          if (matchesType) {
            _addCategoryIfMissing(item.name);
          }
        }
      });
    } catch (_) {
      // The add form still works with default categories if loading fails.
    }
  }

  void _addCategoryIfMissing(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final exists = categories.any(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    if (!exists) {
      categories.add(normalized);
    }
  }

  Future<void> _addCustomCategory() async {
    final value = customCategoryController.text.trim();
    if (value.isEmpty) return;

    await ApiService().saveCategory(
      name: value,
      type: isExpense ? 'expense' : 'income',
    );

    if (!mounted) return;
    setState(() {
      _addCategoryIfMissing(value);
      category = categories.firstWhere(
        (item) => item.toLowerCase() == value.toLowerCase(),
        orElse: () => value,
      );
      customCategoryController.clear();
    });
  }

  Future<void> _showReceiptSourcePicker() async {
    if (isScanningReceipt) return;
    final t = context.read<LanguageController>().text;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('receipt_ocr'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(t('receipt_source_hint')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(sheetContext, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(t('take_photo')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pop(sheetContext, ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(t('choose_gallery')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;
    await _pickAndScanReceipt(source);
  }

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    final t = context.read<LanguageController>().text;
    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 2000,
      );
      if (image == null || !mounted) return;
      final imageBytes = await image.readAsBytes();

      setState(() {
        receiptImage = image;
        receiptImageBytes = imageBytes;
        receiptResult = null;
        isScanningReceipt = true;
      });

      final result = await receiptOcrService.scan(image);
      if (!mounted) return;

      final parsedDate = DateTime.tryParse(result.date);
      final detectedCategory = result.category.trim().isEmpty
          ? 'Other'
          : result.category.trim();

      setState(() {
        receiptResult = result;
        isScanningReceipt = false;
        isExpense = true;

        if (result.amount > 0) {
          amountController.text = NumberFormat.decimalPattern(
            'vi',
          ).format(result.amount.round());
        }
        if (result.merchant.isNotEmpty) {
          descriptionController.text = result.merchant;
        }
        final productNames = result.lineItems
            .map((item) => item.name)
            .where((name) => name.isNotEmpty)
            .join(', ');
        final noteParts = [
          if (productNames.isNotEmpty) 'Sản phẩm: $productNames',
          if (result.notes.isNotEmpty) result.notes,
        ];
        if (noteParts.isNotEmpty) {
          notesController.text = noteParts.join('\n');
        }
        if (parsedDate != null) {
          selectedDate = parsedDate;
        }

        _addCategoryIfMissing(detectedCategory);
        category = categories.firstWhere(
          (item) => item.toLowerCase() == detectedCategory.toLowerCase(),
          orElse: () => detectedCategory,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('receipt_scan_success'))));
    } catch (error) {
      if (!mounted) return;
      setState(() => isScanningReceipt = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(
            t('receipt_scan_failed').replaceAll('{error}', error.toString()),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageController>().text;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F6F8),

      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          t('add_transaction'),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.14),
                          primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.document_scanner_outlined,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('receipt_ocr'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    t('receipt_ocr_subtitle'),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: isScanningReceipt
                                  ? null
                                  : _showReceiptSourcePicker,
                              icon: isScanningReceipt
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                isScanningReceipt ? t('scanning') : t('scan'),
                              ),
                            ),
                          ],
                        ),
                        if (receiptImageBytes != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: Image.memory(
                                receiptImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        if (receiptResult != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  t('receipt_review_hint').replaceAll(
                                    '{confidence}',
                                    '${(receiptResult!.confidence * 100).round()}%',
                                  ),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// 💰 AMOUNT
                  Center(
                    child: Column(
                      children: [
                        Text(
                          t('amount').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.grey,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          ),
                          onChanged: (value) {
                            String numbers = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (numbers.isEmpty) return;

                            final formatted = NumberFormat.decimalPattern(
                              'vi',
                            ).format(int.parse(numbers));

                            amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TOGGLE
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[900]
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        /// EXPENSE
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isExpense = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpense
                                    ? (isDark ? Colors.grey[800] : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t('expense'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense ? primary : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// INCOME
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isExpense = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isExpense
                                    ? (isDark ? Colors.grey[800] : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t('income_type'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isExpense
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// DESCRIPTION
                  Text(
                    t('description'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: descriptionController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: t('enter_description'),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// CATEGORY SHORTCUTS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.take(5).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _categoryChip(item, isDark),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CATEGORY
                  Text(
                    t('category'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _card(
                    DropdownButtonFormField(
                      key: ValueKey(category),
                      dropdownColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      initialValue: category,
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => category = v!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCategoryController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addCustomCategory(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: t('custom_category'),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _addCustomCategory,
                          icon: const Icon(Icons.add),
                          label: Text(t('add')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            iconColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// DATE + ACCOUNT
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickDate,
                          child: _card(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _card(
                          DropdownButtonFormField(
                            key: ValueKey(account),
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            initialValue: account,
                            items: [
                              DropdownMenuItem(
                                value: "Main Card",
                                child: Text(t('main_card')),
                              ),
                              DropdownMenuItem(
                                value: "Cash",
                                child: Text(t('cash')),
                              ),
                            ],
                            onChanged: (v) => setState(() => account = v!),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// NOTES
                  Text(
                    t('notes_optional'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: t('add_note'),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(
                              amountController.text.replaceAll(".", ""),
                            ) ??
                            0;

                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t('amount_gt_zero'))),
                          );
                          return;
                        }

                        final data = {
                          "description": descriptionController.text,
                          "category": category,
                          "account": account,
                          "amount": amount,
                          "is_expense": isExpense ? 1 : 0,
                          "notes": notesController.text,
                          "date": selectedDate.toString(),
                        };

                        setState(() => isSaving = true);
                        try {
                          await ApiService().addTransaction(data);
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        } catch (error) {
                          if (!context.mounted) return;
                          final message = error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        } finally {
                          if (mounted) {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                icon: const Icon(Icons.check_circle),
                label: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        t('save_transaction'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String value, bool isDark) {
    final active = category.toLowerCase() == value.toLowerCase();
    final visual = categoryVisual(value);

    return ChoiceChip(
      avatar: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: active ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          visual.icon,
          size: 15,
          color: active ? visual.color : visual.color.withValues(alpha: 0.75),
        ),
      ),
      label: Text(visual.label),
      selected: active,
      onSelected: (_) => setState(() => category = value),
      selectedColor: isDark
          ? visual.color.withValues(alpha: 0.2)
          : const Color(0xFFE0E7FF),
      backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: active ? Theme.of(context).primaryColor : Colors.grey,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  /// CARD
  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
