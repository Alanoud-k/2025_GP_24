import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart';
import '../../child/models/chore_model.dart';
import '../../child/services/chore_service.dart';

class ParentChoresScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentChoresScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentChoresScreen> createState() => _ParentChoresScreenState();
}

class _ParentChoresScreenState extends State<ParentChoresScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  late TabController _tabController;
  final ChoreService _choreService = ChoreService();

  List<ChoreModel> _allChores = [];
  List<Map<String, dynamic>> _childrenList = [];

  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);
  static const Color textColor = Color(0xFF2C3E50);

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
    _loadAllData();
  }

  void _showMessageBar(
    String message, {
    Color backgroundColor = hassalaGreen1,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _loadAllData() async {
    await checkAuthStatus(context);
    try {
      final chores = await _choreService.getAllParentChores(
        widget.parentId.toString(),
      );
      final children = await _choreService.getChildren(
        widget.parentId.toString(),
      );

      if (mounted) {
        setState(() {
          _allChores = chores;
          _childrenList = children;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> _approveChore(String choreId, AppLocalizations l10n) async {
    try {
      await _choreService.updateChoreStatus(choreId, 'Completed');
      _loadAllData();
      _showMessageBar(l10n.choreApprovedSuccess, backgroundColor: _greenMsg);
    } catch (e) {
      _showMessageBar(l10n.failedToApprove, backgroundColor: _redMsg);
    }
  }

  Future<void> _rejectChore(String choreId, String reason, AppLocalizations l10n) async {
    try {
      await _choreService.rejectChore(choreId, reason);
      _loadAllData();
      _showMessageBar(
        l10n.choreRejected,
        backgroundColor: _redMsg,
      );
    } catch (e) {
      _showMessageBar(l10n.failedToReject, backgroundColor: _redMsg);
    }
  }

  String _getChildNameOnly(String id, AppLocalizations l10n) {
    for (var child in _childrenList) {
      if (child['childId'].toString() == id) {
        return child['firstName'] ?? l10n.unknown;
      }
    }
    return l10n.unknown;
  }

  void _showReviewDialog(ChoreModel chore) {
    final l10n = AppLocalizations.of(context)!;
    String imageUrl = chore.proofUrl ?? "";
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    final String cName = chore.childName ?? _getChildNameOnly(chore.childId, l10n);

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: hassalaGreen1,
            surface: Colors.white,
            onPrimary: Colors.white,
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.reviewProofTitle(cName),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.taskLabel(chore.title),
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
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 250,
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: hassalaGreen1,
                                ),
                              ),
                            ),
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 150,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      l10n.noProofProvided,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showRejectReasonDialog(chore);
              },
              child: Text(
                l10n.reject,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _approveChore(chore.id, l10n);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.approve,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectReasonDialog(ChoreModel chore) {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.red,
            surface: Colors.white,
            onPrimary: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.reasonForRejection,
            style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            cursorColor: Colors.red,
            decoration: InputDecoration(
              hintText: l10n.rejectionHint,
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  _rejectChore(chore.id, reasonController.text, l10n);
                }
              },
              child: Text(
                l10n.sendToChild,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChoreDialog({ChoreModel? choreToEdit}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = choreToEdit != null;
    final titleController = TextEditingController(
      text: choreToEdit?.title ?? '',
    );
    final descController = TextEditingController(
      text: choreToEdit?.description ?? '',
    );
    final keysController = TextEditingController(
      text: choreToEdit?.keys.toString() ?? '',
    );

    String selectedType = isEditing ? choreToEdit!.type : 'One-time';
    String? selectedDay;
    TimeOfDay? selectedTime;

    String? initialChildId = isEditing ? choreToEdit!.childId : null;
    if (initialChildId != null && _childrenList.isNotEmpty) {
      bool exists = _childrenList.any(
        (c) => c['childId'].toString() == initialChildId,
      );
      if (!exists) initialChildId = null;
    }
    String? selectedChildId = initialChildId;

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
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: hassalaGreen1,
                selectionHandleColor: hassalaGreen1,
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
                isEditing ? l10n.editChore : l10n.addNewChore,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.titleLabel,
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: l10n.descriptionChore,
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keysController,
                      decoration: InputDecoration(
                        labelText: l10n.rewardKeysInput,
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: l10n.choreTypeLabel,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      value: selectedType,
                      items: [
                        DropdownMenuItem(
                          value: 'One-time',
                          child: Text(l10n.oneTimeOption),
                        ),
                        DropdownMenuItem(
                          value: 'Weekly',
                          child: Text(l10n.weeklyOption),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setStateDialog(() {
                            selectedType = val;
                            if (val == 'One-time') {
                              selectedDay = null;
                              selectedTime = null;
                            }
                          });
                      },
                    ),

                    if (selectedType == 'Weekly' && !isEditing) ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                labelText: l10n.dayLabel,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              value: selectedDay,
                              items: _daysOfWeek
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(
                                        localizedDays[day]!,
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
                                if (time != null)
                                  setStateDialog(() => selectedTime = time);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.timeLabel,
                                  suffixIcon: const Icon(Icons.access_time, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Text(
                                  selectedTime != null
                                      ? selectedTime!.format(context)
                                      : l10n.selectTimeHint,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (!isEditing) ...[
                      const SizedBox(height: 15),
                      _childrenList.isEmpty
                          ? Text(
                              l10n.noChildrenFoundRed,
                              style: const TextStyle(color: Colors.red),
                            )
                          : DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                labelText: l10n.assignToChild,
                                prefixIcon: const Icon(Icons.face),
                              ),
                              value: selectedChildId,
                              items: _childrenList
                                  .map(
                                    (child) => DropdownMenuItem<String>(
                                      value: child['childId'].toString(),
                                      child: Text(
                                        child['firstName'] ?? l10n.unknown,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => selectedChildId = val),
                              hint: Text(l10n.selectChild),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    int keysValue = int.tryParse(keysController.text) ?? 0;
                    if (keysValue <= 0) {
                      _showMessageBar(
                        l10n.rewardMustBePositive,
                        backgroundColor: _redMsg,
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await _choreService.editChore(
                          choreId: choreToEdit!.id,
                          title: titleController.text,
                          description: descController.text,
                          keys: keysValue,
                        );
                        _showMessageBar(
                          l10n.choreUpdated,
                          backgroundColor: _greenMsg,
                        );
                      } else {
                        if (titleController.text.isEmpty ||
                            selectedChildId == null) {
                          _showMessageBar(
                            l10n.pleaseFillAllFields,
                            backgroundColor: _redMsg,
                          );
                          return;
                        }
                        String? formattedTime;
                        if (selectedTime != null)
                          formattedTime =
                              "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
                        await _choreService.createChore(
                          title: titleController.text,
                          description: descController.text,
                          keys: keysValue,
                          childId: selectedChildId!,
                          parentId: widget.parentId.toString(),
                          type: selectedType,
                          assignedDay: selectedDay,
                          assignedTime: formattedTime,
                        );
                        _showMessageBar(
                          l10n.choreCreated,
                          backgroundColor: _greenMsg,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      _loadAllData();
                    } catch (e) {
                      _showMessageBar(l10n.errorMsg(e.toString()), backgroundColor: _redMsg);
                    }
                  },
                  child: Text(
                    isEditing ? l10n.saveBtn : l10n.create,
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
              l10n.deleteChoreConfirmTitle,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          l10n.deleteChoreConfirmBody,
        ),
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
        _loadAllData(); 
        _showMessageBar(
          l10n.choreDeletedSuccess,
          backgroundColor: Colors.red,
        );
      } catch (e) {
        _showMessageBar(l10n.failedToDeleteChore, backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: hassalaGreen1)),
      );
    }

    List<ChoreModel> activeChores = _allChores
        .where((c) => c.status == 'In Progress' || c.status == 'Pending')
        .toList();
    List<ChoreModel> pendingChores = _allChores
        .where((c) => c.status == 'Submitted' || c.status == 'Waiting Approval')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      floatingActionButton: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _showChoreDialog(),
          backgroundColor: hassalaGreen1,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  l10n.allFamilyChores,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
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
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        hassalaGreen1,
                        Color.fromARGB(255, 53, 144, 169),
                      ],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: l10n.toReviewTab),
                    Tab(text: l10n.inProgressTab),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupedChoreList(pendingChores, isReview: true, l10n: l10n),
                    _buildGroupedChoreList(activeChores, isReview: false, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedChoreList(
    List<ChoreModel> chores, {
    required bool isReview,
    required AppLocalizations l10n,
  }) {
    if (chores.isEmpty) {
      return Center(
        child: Text(
          isReview ? l10n.nochoresToReview : l10n.noActiveChoresList,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    Map<String, List<ChoreModel>> groupedChores = {};
    for (var chore in chores) {
      if (!groupedChores.containsKey(chore.childId)) {
        groupedChores[chore.childId] = [];
      }
      groupedChores[chore.childId]!.add(chore);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedChores.keys.length,
      itemBuilder: (context, index) {
        String childId = groupedChores.keys.elementAt(index);
        List<ChoreModel> childChores = groupedChores[childId]!;

        String childName =
            childChores.first.childName ?? _getChildNameOnly(childId, l10n);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 15, bottom: 10, start: 5),
              child: Row(
                children: [
                  const Icon(Icons.face, color: hassalaGreen1, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n.childsChoresHeader(childName),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            ...childChores.map((c) => _buildChoreCard(c, isReview, l10n)).toList(),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildChoreCard(ChoreModel chore, bool isReview, AppLocalizations l10n) {
    final isWeekly = chore.type == 'Weekly';

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isReview
                ? Colors.orange.withOpacity(0.1)
                : Colors.teal.withOpacity(0.1),
            child: Icon(
              isReview ? Icons.rate_review : Icons.pending_actions,
              color: isReview ? Colors.orange : Colors.teal,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      chore.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isWeekly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.weeklyBadge,
                          style: const TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (!isReview)
                      GestureDetector(
                        onTap: () => _showChoreDialog(choreToEdit: chore),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _confirmDeleteChore(chore.id),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.rewardKeys(chore.keys),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isReview)
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.orange),
              onPressed: () => _showReviewDialog(chore),
            ),
        ],
      ),
    );
  }
}