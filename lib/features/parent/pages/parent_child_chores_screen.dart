import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/l10n/app_localizations.dart';
import '../../child/models/chore_model.dart';
import '../../child/services/chore_service.dart';

class ParentChildChoresScreen extends StatefulWidget {
  final String childName;
  final String childId;
  final int parentId;

  const ParentChildChoresScreen({
    super.key,
    required this.childName,
    required this.childId,
    required this.parentId,
  });

  @override
  State<ParentChildChoresScreen> createState() =>
      _ParentChildChoresScreenState();
}

class _ParentChildChoresScreenState extends State<ParentChildChoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();
  late Future<List<ChoreModel>> _choresFuture;

  // --- Colors & Styles ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color bgColor = Color(0xFFF7FAFC);

  static const Color _tealMsg = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);

  final List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _choresFuture = _choreService.getChores(widget.childId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMessageBar(String message, {Color backgroundColor = _tealMsg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _choresFuture = _choreService.getChores(widget.childId);
    });
  }

  Future<void> _approveChore(String choreId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _choreService.updateChoreStatus(choreId, 'Completed');
      _refreshData();
      _showMessageBar(l10n.choreApproved, backgroundColor: _greenMsg);
    } catch (e) {
      _showMessageBar(l10n.failedToApprove, backgroundColor: _redMsg);
    }
  }

  Future<void> _confirmDeleteChore(String choreId) async {
    final l10n = AppLocalizations.of(context)!;
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              l10n.deleteChoreTitle,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(l10n.deleteChoreWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _choreService.deleteChore(choreId);
        _refreshData();
        _showMessageBar(
          l10n.choreDeletedSuccess,
          backgroundColor: Colors.red,
        );
      } catch (e) {
        _showMessageBar(l10n.failedToDeleteChore, backgroundColor: Colors.red);
      }
    }
  }

  void _showReviewDialog(ChoreModel chore) {
    final l10n = AppLocalizations.of(context)!;
    String imageUrl = chore.proofUrl ?? "";

    if (imageUrl.isNotEmpty && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.reviewProof,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.childCompletedTask(widget.childName, chore.title),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: hassalaGreen1,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.imageNotFound,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noProofImage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveChore(chore.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.approve, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChoreDialog() {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final keysController = TextEditingController();
    String selectedType = 'One-time';
    String? selectedDay;
    TimeOfDay? selectedTime;

    final Map<String, String> localizedDays = {
      'Sunday': l10n.sunday,
      'Monday': l10n.monday,
      'Tuesday': l10n.tuesday,
      'Wednesday': l10n.wednesday,
      'Thursday': l10n.thursday,
      'Friday': l10n.friday,
      'Saturday': l10n.saturday,
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: hassalaGreen1,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: hassalaGreen1, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                l10n.addNewChore,
                style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.choreTitle,
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keysController,
                      decoration: InputDecoration(
                        labelText: l10n.rewardKeysLabel,
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: l10n.choreType,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      value: selectedType,
                      items: [
                        DropdownMenuItem(
                          value: 'One-time',
                          child: Text(l10n.oneTime),
                        ),
                        DropdownMenuItem(
                          value: 'Weekly',
                          child: Text(l10n.weekly),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            selectedType = val;
                            if (val == 'One-time') {
                              selectedDay = null;
                              selectedTime = null;
                            }
                          });
                        }
                      },
                    ),
                    if (selectedType == 'Weekly') ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              value: selectedDay,
                              hint: Text(l10n.day, style: const TextStyle(fontSize: 14)),
                              items: _daysOfWeek
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(
                                        localizedDays[day] ?? day,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => selectedDay = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: hassalaGreen1,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) {
                                  setStateDialog(() => selectedTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  suffixIcon: Icon(Icons.access_time, size: 20),
                                  contentPadding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Text(
                                  selectedTime != null
                                      ? selectedTime!.format(context)
                                      : l10n.selectTime,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hassalaGreen1,
                  ),
                  onPressed: () async {
                    int keysValue = int.tryParse(keysController.text) ?? 0;
                    if (titleController.text.isEmpty || keysValue <= 0) {
                      _showMessageBar(
                        l10n.invalidInput,
                        backgroundColor: _redMsg,
                      );
                      return;
                    }
                    String? formattedTime;
                    if (selectedTime != null) {
                      formattedTime =
                          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
                    }
                    try {
                      await _choreService.createChore(
                        title: titleController.text,
                        description: descController.text,
                        keys: keysValue,
                        childId: widget.childId,
                        parentId: widget.parentId.toString(),
                        type: selectedType,
                        assignedDay: selectedDay,
                        assignedTime: formattedTime,
                      );
                      if (mounted) Navigator.pop(context);
                      _refreshData();
                      _showMessageBar(
                        l10n.choreAddedSuccess,
                        backgroundColor: _greenMsg,
                      );
                    } catch (e) {
                      _showMessageBar("${l10n.errorPrefix}: $e", backgroundColor: _redMsg);
                    }
                  },
                  child: Text(
                    l10n.create,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.childsChores(widget.childName),
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _showChoreDialog(),
          backgroundColor: hassalaGreen1,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      body: FutureBuilder<List<ChoreModel>>(
        future: _choresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: hassalaGreen1),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "${l10n.errorPrefix}: ${snapshot.error}",
                style: const TextStyle(color: _redMsg),
              ),
            );
          }

          final allChores = snapshot.data ?? [];
          final activeChores = allChores
              .where((c) => c.status != 'Completed')
              .toList();
          final historyChores = allChores
              .where((c) => c.status == 'Completed')
              .toList();

          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [hassalaGreen1, hassalaGreen2],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: l10n.activeTab),
                    Tab(text: l10n.historyTab),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    activeChores.isEmpty
                        ? Center(child: Text(l10n.noActiveChores))
                        : ListView.builder(
                            padding: const EdgeInsetsDirectional.all(20),
                            itemCount: activeChores.length,
                            itemBuilder: (context, index) => _buildChoreCard(
                              activeChores[index],
                              isActive: true,
                            ),
                          ),
                    historyChores.isEmpty
                        ? Center(child: Text(l10n.noHistoryYet))
                        : ListView.builder(
                            padding: const EdgeInsetsDirectional.all(20),
                            itemCount: historyChores.length,
                            itemBuilder: (context, index) => _buildChoreCard(
                              historyChores[index],
                              isActive: false,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChoreCard(ChoreModel chore, {required bool isActive}) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSubmitted =
        chore.status == 'Submitted' || chore.status == 'Waiting Approval';
    final bool isWeekly = chore.type == 'Weekly';

    // 💡 التعديل هنا: ترجمة حالة المهمة بناءً على القيمة المخزنة في الداتا بيز
    String displayStatus = chore.status;
    if (chore.status == 'Pending') {
      displayStatus = l10n.statusPending; // ستطبع: قيد الانتظار
    } else if (isSubmitted) {
      displayStatus = l10n.waitingReview; // ستطبع: بانتظار المراجعة
    } else if (chore.status == 'Completed') {
      displayStatus = l10n.completed; // ستطبع: مكتمل
    }

    return GestureDetector(
      onTap: (isActive && isSubmitted) ? () => _showReviewDialog(chore) : null,
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 16),
        padding: const EdgeInsetsDirectional.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSubmitted
              ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? (isSubmitted
                          ? Colors.orange.withOpacity(0.1)
                          : const Color(0xFFE0F2F1))
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isActive
                    ? (isSubmitted
                          ? Icons.visibility
                          : Icons.cleaning_services_outlined)
                    : Icons.check_circle_outline,
                color: isActive
                    ? (isSubmitted ? Colors.orange : hassalaGreen1)
                    : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chore.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isWeekly)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 6),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.weekly,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isActive && !isSubmitted) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDeleteChore(chore.id),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayStatus, // 💡 تم التعديل هنا ليعرض الحالة المترجمة
                    style: TextStyle(
                      fontSize: 12,
                      color: isSubmitted ? Colors.orange : Colors.grey,
                      fontWeight: isSubmitted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Row(
                children: [
                  Text(
                    "${chore.keys}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA000),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.vpn_key, size: 14, color: Color(0xFFFFA000)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}