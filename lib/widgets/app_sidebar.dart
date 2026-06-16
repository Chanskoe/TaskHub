import 'package:flutter/material.dart';
import 'package:task_hub/models/desk.dart';
import '../theme/theme.dart';
import 'sidebar_search_bar.dart';

class AppSidebar extends StatefulWidget {
  final String selectedItem;
  final List<DeskModel> desks; 
  final ValueChanged<String> onAddDeskSubmitted; 
  final void Function(String item, bool isBoard) onItemSelected;

  const AppSidebar({
    super.key, 
    required this.selectedItem,
    required this.desks,
    required this.onAddDeskSubmitted,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isAddingDesk = false; 
  final FocusNode _deskFocusNode = FocusNode();
  final TextEditingController _deskController = TextEditingController();

  @override
  void dispose() {
    _deskFocusNode.dispose();
    _deskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: isMobile ? double.infinity : 220,
      color: AppColors.olive,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SidebarSearchBar(onChanged: (text) {}),
            const SizedBox(height: 24),
            
            _buildSidebarHeader('Доски', onAddPressed: () {
              setState(() {
                _isAddingDesk = true;
              });
            }),
            
            ...widget.desks.map((desk) => _buildSidebarItem(desk.title, true)),
            
            if (_isAddingDesk)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Focus(
                  onFocusChange: (hasFocus) {

                    if (!hasFocus && _isAddingDesk) {
                      setState(() {
                        _isAddingDesk = false;
                        _deskController.clear();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.screenBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _deskController,
                      focusNode: _deskFocusNode,
                      autofocus: true,
                      style: const TextStyle(fontSize: AppSizes.search, color: AppColors.darkBlue),
                      decoration: const InputDecoration(
                        hintText: 'Название доски...',
                        hintStyle: TextStyle(color: AppColors.darkGray, fontSize: AppSizes.search),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onAddDeskSubmitted(val.trim());
                        }
                        setState(() {
                          _isAddingDesk = false;
                          _deskController.clear();
                        });
                      },
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            _buildSidebarHeader('Задачи'),
            // TODO: плюсик вернуть
            _buildSidebarItem('Сегодня', false),
            _buildSidebarItem('Завтра', false),
            _buildSidebarItem('Неделя', false),
            _buildSidebarItem('Всё время', false),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(String title, {VoidCallback? onAddPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: const TextStyle(fontSize: AppSizes.search, fontWeight: AppWeight.lightFontWeight, color: AppColors.mediumBlue)
        ),
        if (onAddPressed != null)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add, size: 14, color: AppColors.darkGray),
            onPressed: onAddPressed,
            splashRadius: 16,
          ),
      ],
    );
    }

  Widget _buildSidebarItem(String title, bool isBoard) {
    final isSelected = widget.selectedItem == title;
    return GestureDetector(
      onTap: () => widget.onItemSelected(title, isBoard),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkBrown : Colors.transparent, 
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: AppSizes.search, fontWeight: AppWeight.lightFontWeight, color: AppColors.darkBlue),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }
}