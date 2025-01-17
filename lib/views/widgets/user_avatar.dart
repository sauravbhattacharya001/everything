import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;

  UserAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
