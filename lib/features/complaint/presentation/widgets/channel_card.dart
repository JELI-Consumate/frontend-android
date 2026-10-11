import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/complaint_agency.dart';

IconData channelIcon(ComplaintChannelType type) => switch (type) {
  ComplaintChannelType.website => Icons.language,
  ComplaintChannelType.whatsapp => Icons.chat_outlined,
  ComplaintChannelType.phone => Icons.call_outlined,
  ComplaintChannelType.email => Icons.mail_outline,
  ComplaintChannelType.app => Icons.smartphone,
  ComplaintChannelType.address => Icons.location_on_outlined,
};

class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.channel, required this.onOpen});

  final ComplaintChannel channel;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final icon = channelIcon(channel.type);
    final url = channel.url;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.label.toUpperCase(),
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(channel.value, style: AppTypography.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          if (url != null) ...[
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: channel.actionLabel,
              trailingIcon: icon,
              onPressed: () => onOpen(url),
            ),
          ],
        ],
      ),
    );
  }
}
