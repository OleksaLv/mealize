import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
  });

  final Widget? title;
  final Widget? leading; // The widget displayed on the left
  final List<Widget>? actions; // The list of widgets displayed on the right

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,      
      backgroundColor: Colors.transparent,      
      foregroundColor: Colors.black,
      automaticallyImplyLeading: false, 
      leading: leading,
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}