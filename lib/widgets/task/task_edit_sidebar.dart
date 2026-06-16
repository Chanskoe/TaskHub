import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_hub/models/task.dart';
import 'package:task_hub/models/desk.dart';
import '../../theme/theme.dart';

class TaskEditSidebar extends StatefulWidget {
  final TaskModel task;
  final List<DeskModel> desks;
  final String currentUserId;
  final VoidCallback onClose;
  final Function(Map<String, dynamic> event) onUpdate;

  const TaskEditSidebar({
    super.key,
    required this.task,
    required this.desks,
    required this.currentUserId,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  State<TaskEditSidebar> createState() => _TaskEditSidebarState();
}

class _TaskEditSidebarState extends State<TaskEditSidebar> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _commentController;
  late FocusNode _titleFocusNode;
  late FocusNode _descriptionFocusNode;
  bool _isCheckboxHovered = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _titleFocusNode.addListener(_onTitleFocusChange);
    _descriptionFocusNode.addListener(_onDescriptionFocusChange);
  }

  @override
  void didUpdateWidget(TaskEditSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _descriptionFocusNode.removeListener(_onDescriptionFocusChange);
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _sendUpdate(String key, dynamic value) {
    widget.onUpdate({
      "action": "update_task",
      "id": widget.task.id,
      key: value,
    });
  }

  void _copyToClipboard() {
    final String text = '''
      Задача: ${widget.task.title}
      Описание: ${widget.task.description ?? 'Нет'}
      Статус: ${widget.task.isCompleted ? 'Выполнена' : 'В работе'}
      Важность: ${widget.task.importance ?? 'Не указана'}
      Сложность: ${widget.task.difficulty ?? 'Не указана'}
      Срок: ${widget.task.endDateTime != null ? DateFormat('dd.MM.yyyy HH:mm').format(widget.task.endDateTime!) : 'Не задан'}
      Время выполнения: ${widget.task.runtime != null ? '${widget.task.runtime} мин.' : 'Не задано'}
    ''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Данные задачи скопированы!', style: TextStyle(color: Colors.white))),
    );
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus) {
      final newTitle = _titleController.text.trim();
      if (newTitle != widget.task.title) {
        _sendUpdate("title", newTitle);
      }
    }
  }

  void _onDescriptionFocusChange() {
    if (!_descriptionFocusNode.hasFocus) {
      final newDesc = _descriptionController.text.trim();
      if (newDesc != (widget.task.description ?? '')) {
        _sendUpdate("description", newDesc.isEmpty ? null : newDesc);
      }
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.task.endDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: widget.task.endDateTime != null 
            ? TimeOfDay.fromDateTime(widget.task.endDateTime!) 
            : const TimeOfDay(hour: 23, minute: 59),
      );

      DateTime finalDateTime;
      if (pickedTime != null) {
        finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      } else {
        finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
      }
      _sendUpdate("end_date_time", finalDateTime.toIso8601String());
    }
  }

  Future<void> _pickRuntime() async {
    TextEditingController runtimeCtrl = TextEditingController(text: widget.task.runtime?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Время выполнения (мин)', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: runtimeCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Например: 15'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(runtimeCtrl.text);
              _sendUpdate("runtime", val);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getCurrentDeskMembers() {
    if (widget.task.idOfDesk == null) return [{"id": widget.currentUserId, "nickname": "Я"}];
    final desk = widget.desks.firstWhere(
      (d) => d.id == widget.task.idOfDesk,
      orElse: () => DeskModel(id: '', title: '', idOfAdmin: '', members: []),
    );
    
    if (desk.members.isEmpty) {
      return [{"id": widget.currentUserId, "nickname": "Я"}];
    }

    return desk.members.map((m) => {
      "id": m['id'].toString(), 
      "nickname": m['nickname'].toString()
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String creationDate = DateFormat('dd.MM.yyyy').format(widget.task.registrationDateTime);
    final members = _getCurrentDeskMembers();

    return Container(
      
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(left: BorderSide(color: AppColors.olive, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя панель
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12, top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      creationDate,
                      style: const TextStyle(
                        fontSize: AppSizes.search,
                        fontWeight: AppWeight.lightFontWeight,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.darkGray,
                      onPressed: widget.onClose,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 15)),
                    
                    // Название задачи
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: const TextStyle(fontSize: AppSizes.subHeader, fontWeight: AppWeight.lightFontWeight, color: AppColors.darkBlue, height: 1.2),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      onSubmitted: (val) => _sendUpdate("title", val.trim()),
                    ),
                    const SizedBox(height: 18),

                    // Иконки действий
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: widget.task.isCompleted ? 'Отменить выполнение' : 'Выполнить задачу',
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _isCheckboxHovered = true),
                              onExit: (_) => setState(() => _isCheckboxHovered = false),
                              child: InkWell(
                                onTap: () => _sendUpdate("isCompleted", !widget.task.isCompleted),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: widget.task.isCompleted ? AppColors.green : AppColors.darkGray, width: 2),
                                    color: widget.task.isCompleted ? AppColors.green : Colors.transparent,
                                  ),
                                  child: Center(child: _buildCheckboxIcon()),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Tooltip(
                            message: 'Удалить задачу',
                            child: InkWell(
                              onTap: () {
                                widget.onUpdate({"action": "delete_task", "id": widget.task.id});
                                widget.onClose();
                              },
                              child: const Icon(Icons.delete_outline_rounded, size: 24, color: AppColors.darkGray),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Tooltip(
                            message: 'Копировать задачу',
                            child: InkWell(
                              onTap: _copyToClipboard,
                              child: const Icon(Icons.content_copy_rounded, size: 22, color: AppColors.darkGray),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Описание задачи
                    TextField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      maxLines: null,
                      style: const TextStyle(fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight, color: AppColors.darkBlue),
                      decoration: const InputDecoration(hintText: 'Описание...', hintStyle: TextStyle(color: AppColors.darkGray, fontWeight: AppWeight.lightFontWeight, fontSize: AppSizes.body), border: InputBorder.none, isDense: true),
                      onSubmitted: (val) => _sendUpdate("description", val.isEmpty ? null : val),
                    ),
                    const SizedBox(height: 16),
                    
                    const Divider(color: AppColors.olive, thickness: 1, height: 1),
                    const SizedBox(height: 16),

                    // Характеристики
                    _buildPropertyRow(
                      'Дата', 
                      InkWell(
                        onTap: _pickDateTime,
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            widget.task.endDateTime != null 
                              ? DateFormat('dd.MM.yy HH:mm').format(widget.task.endDateTime!) 
                              : 'Выбрать...', 
                            style: _valueStyle(isPlaceholder: widget.task.endDateTime == null),
                          ),
                        ),
                      ),
                    ),

                    _buildPropertyRow(
                      'Сложность', 
                      _buildDifficultyDropdown()
                    ),

                    _buildPropertyRow(
                      'Важность', 
                      _buildImportanceDropdown(),
                    ),

                    _buildPropertyRow(
                      'Время', 
                      InkWell(
                        onTap: _pickRuntime,
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            widget.task.runtime != null ? '${widget.task.runtime} мин.' : 'Выбрать...', 
                            style: _valueStyle(isPlaceholder: widget.task.runtime == null),
                          ),
                        ),
                      ),
                    ),

                    _buildPropertyRow(
                      'Доска', 
                      _buildDropdown(
                        value: widget.task.idOfDesk,
                        items: {null: "Личные задачи", ...{for (var d in widget.desks) d.id: d.title}},
                        onChanged: (val) {
                          _sendUpdate("id_of_desk", val);
                          _sendUpdate("id_of_members", [widget.currentUserId]); 
                        },
                      ),
                    ),

                    _buildPropertyRow(
                      'Исполнители', 
                      _buildMembersSelector()
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.olive, thickness: 1, height: 1),
                    const SizedBox(height: 24),

                    // Комментарии
                    TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: AppSizes.body, color: AppColors.darkBlue, fontWeight: AppWeight.lightFontWeight),
                      decoration: InputDecoration(
                        hintText: 'Оставить комментарий...',
                        hintStyle: const TextStyle(color: AppColors.darkGray, fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.mediumBlue),
                          onPressed: () {
                            if (_commentController.text.trim().isNotEmpty) {
                              widget.onUpdate({
                                "action": "add_comment",
                                "id_of_task": widget.task.id,
                                "text": _commentController.text.trim()
                              });
                              _commentController.clear();
                            }
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onUpdate({"action": "add_comment", "id_of_task": widget.task.id, "text": val.trim()});
                          _commentController.clear();
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Список комментариев
                    ...widget.task.comments.map((comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TaskCommentWidget(
                        onUpdate: widget.onUpdate,
                        commentId: comment.id,
                        userName: comment.userNickname,
                        date: DateFormat('dd.MM HH:mm').format(comment.registrationDateTime),
                        commentText: comment.text,
                      ),
                    )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _valueStyle({bool isPlaceholder = false}) {
    return TextStyle(
      fontFamily: GoogleFonts.astaSans().fontFamily,
      fontSize: AppSizes.body,
      fontWeight: AppWeight.lightFontWeight,
      color: isPlaceholder ? AppColors.darkGray : AppColors.darkBlue,
    );
  }

  Widget _buildDropdown({required String? value, required Map<String?, String> items, required Function(String?) onChanged}) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: items.containsKey(value) ? value : null,
        hint: Text('Выбрать...', style: _valueStyle(isPlaceholder: true)),
        isDense: true,
        isExpanded: true,
        icon: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text("Выбрать...", style: TextStyle(color: AppColors.darkGray, fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight))),
          ...items.entries.where((e) => e.key != null).map((e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(
              e.value, 
              style: _valueStyle(),
              overflow: TextOverflow.ellipsis
            ),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImportanceDropdown() {
    Color getImportanceColor(String? val) {
      if (val == "high") return AppColors.red;
      if (val == "medium") return AppColors.yellow;
      if (val == "low") return AppColors.green;
      return Colors.transparent;
    }
    
    String getImportanceName(String? val) {
      if (val == "high") return "Высокая";
      if (val == "medium") return "Средняя";
      if (val == "low") return "Низкая";
      return "Выбрать...";
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: widget.task.importance?.name.toLowerCase(),
        hint: Text('Выбрать...', style: _valueStyle(isPlaceholder: true)),
        isDense: true,
        isExpanded: true,
        icon: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text("Выбрать...", style: TextStyle(color: AppColors.darkGray, fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight))),
          ...["low", "medium", "high"].map((val) => DropdownMenuItem<String?>(
            value: val,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: getImportanceColor(val), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(  
                  child: Text(
                    getImportanceName(val),
                    style: _valueStyle(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
        onChanged: (val) => _sendUpdate("importance", val),
      ),
    );
  }

  Widget _buildDifficultyDropdown() {
    Color getDifficultyColor(String? val) {
      if (val == "hard") return AppColors.red;
      if (val == "medium") return AppColors.yellow;
      if (val == "easy") return AppColors.green;
      return Colors.transparent;
    }
    
    String getDifficultyName(String? val) {
      if (val == "hard") return "Тяжёлая";
      if (val == "medium") return "Средняя";
      if (val == "easy") return "Лёгкая";
      return "Выбрать...";
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: widget.task.difficulty?.name.toLowerCase(),
        hint: Text('Выбрать...', style: _valueStyle(isPlaceholder: true)),
        isDense: true,
        isExpanded: true,
        icon: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text("Выбрать...", style: TextStyle(color: AppColors.darkGray, fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight))),
          ...["easy", "medium", "hard"].map((val) => DropdownMenuItem<String?>(
            value: val,
            child: Row(
              children: [
                Container(
                  width: 10, 
                  height: 10, 
                  decoration: BoxDecoration(
                    color: getDifficultyColor(val), 
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(  
                  child: Text(
                    getDifficultyName(val),
                    style: _valueStyle(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
        onChanged: (val) => _sendUpdate("difficulty", val),
      ),
    );
  }

  Widget _buildPropertyRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.body,
                fontWeight: AppWeight.lightFontWeight,
                color: AppColors.darkBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  Widget? _buildCheckboxIcon() {
    if (widget.task.isCompleted) return const Icon(Icons.check, size: 14, color: Colors.white);
    if (_isCheckboxHovered) return Icon(Icons.check, size: 14, color: AppColors.gray.withValues(alpha: 0.7));
    return null;
  }

  Widget _buildMembersSelector() {
    final members = _getCurrentDeskMembers();
    final selectedIds = List<String>.from(widget.task.idOfMembers);
    
    String displayText;
    if (selectedIds.isEmpty) {
      displayText = "Выбрать...";
    } else if (selectedIds.length == 1) {
      final member = members.firstWhere(
        (m) => m["id"] == selectedIds.first,
        orElse: () => {"nickname": "Неизвестный"},
      );
      displayText = member["nickname"]!;
    } else {
      displayText = "${selectedIds.length} исполнителя";
    }

    return InkWell(
      onTap: () => _showMembersDialog(members, selectedIds),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          displayText,
          style: _valueStyle(isPlaceholder: selectedIds.isEmpty),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _showMembersDialog(List<Map<String, String>> members, List<String> initialSelectedIds) async {
    Set<String> tempSelected = Set.from(initialSelectedIds);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выберите исполнителей"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final id = member["id"]!;
              final nickname = member["nickname"]!;
              return CheckboxListTile(
                title: Text(nickname),
                value: tempSelected.contains(id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      tempSelected.add(id);
                    } else {
                      tempSelected.remove(id);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              _sendUpdate("id_of_members", tempSelected.toList());
              Navigator.pop(context);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }
}

class TaskCommentWidget extends StatelessWidget {
  final String commentId;
  final String userName;
  final String date;
  final String commentText;
  final Function(Map<String, dynamic> event) onUpdate;

  const TaskCommentWidget({
    super.key,
    required this.commentId,
    required this.userName,
    required this.date,
    required this.commentText,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 14, 
              backgroundColor: AppColors.olive, 
              child: Icon(Icons.nature, size: 16, color: AppColors.screenBackground),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(
                  fontSize: AppSizes.search,
                  fontWeight: AppWeight.lightFontWeight,
                  color: AppColors.darkBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(
                fontSize: AppSizes.caption,
                fontWeight: AppWeight.lightFontWeight,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                onUpdate({
                  "action": "delete_comment",
                  "id": commentId,
                });
              },
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.screenBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              commentText,
              style: const TextStyle(
                fontSize: AppSizes.search,
                fontWeight: AppWeight.lightFontWeight,
                color: AppColors.darkBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}