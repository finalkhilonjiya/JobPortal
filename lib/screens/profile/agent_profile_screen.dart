import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';
import '../property/reviews_section.dart';

/// Public profile of an owner / agent / broker / builder.
class AgentProfileScreen extends StatefulWidget {
  final String userId;
  const AgentProfileScreen({super.key, required this.userId});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  late final Future<Json?> _p = Api.publicProfile(widget.userId);
  late final Future<List<Property>> _props = Api.byOwner(widget.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile', style: AppText.h3)),
      body: FutureBuilder<Json?>(
        future: _p,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          final p = snap.data;
          if (p == null) return const EmptyState(icon: Icons.person_off_rounded, title: 'Profile not found', message: 'This user may have deleted their account.');
          final name = (p['full_name'] ?? 'User').toString();
          final role = (p['role'] ?? '').toString();
          final agency = (p['agency_name'] ?? '').toString();
          final bio = (p['bio'] ?? '').toString();
          final verified = p['is_verified'] == true;
          final since = DateTime.tryParse((p['created_at'] ?? '').toString());
          final type = role == 'builder' ? 'builder' : (role == 'agent' || role == 'broker' ? 'agent' : null);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: softShadow()),
                child: Column(children: [
                  Avatar(name: name, url: (p['avatar_url'] ?? '').toString(), size: 84),
                  const SizedBox(height: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(name, style: AppText.h2, textAlign: TextAlign.center)),
                    if (verified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: AppColors.success, size: 22)),
                  ]),
                  const SizedBox(height: 4),
                  Text(agency.isNotEmpty ? '${kRoleLabel[role] ?? cap(role)} · $agency' : (kRoleLabel[role] ?? cap(role)), style: AppText.bodyM),
                  if ((p['agency_address'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(p['agency_address'].toString(), style: AppText.bodyS)),
                  if (since != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Member since ${dateLabel(since)}', style: AppText.bodyS)),
                  if (bio.isNotEmpty) ...[const SizedBox(height: 12), Text(bio, style: AppText.bodyM, textAlign: TextAlign.center)],
                ]),
              ),
              const SectionHeader('Active listings', padding: EdgeInsets.fromLTRB(2, 26, 2, 12)),
              PropertyRow(future: _props, emptyText: 'No active listings.'),
              const SizedBox(height: 10),
              if (type != null) ReviewsSection(targetType: type == 'builder' ? 'builder' : 'agent', targetId: widget.userId, title: 'Reviews', allowWrite: Api.uid != widget.userId),
            ],
          );
        },
      ),
    );
  }
}
