import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    required this.name,
    this.url,
    this.radius = 24,
    this.ring = false,
  });

  final String name;
  final String? url;
  final double radius;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final image = url != null && url!.isNotEmpty
        ? CachedNetworkImageProvider(url!)
        : null;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join();

    return Container(
      padding: EdgeInsets.all(ring ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring ? const LinearGradient(colors: [SineColors.pink, SineColors.gold]) : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF242836),
        backgroundImage: image,
        child: image == null ? Text(initials, style: TextStyle(fontWeight: FontWeight.w900, fontSize: radius * .55)) : null,
      ),
    );
  }
}
