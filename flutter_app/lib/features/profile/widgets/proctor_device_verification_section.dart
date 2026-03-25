import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../proctor_profile_controller.dart';
import '../proctor_profile_state.dart';

class ProctorDeviceVerificationSection extends ConsumerWidget {
  const ProctorDeviceVerificationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(proctorProfileControllerProvider);
    final profileController =
        ref.read(proctorProfileControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.deviceRegistration,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  profileState.deviceStatus == DeviceRegistrationStatus.active
                      ? Colors.green.shade50
                      : profileState.deviceStatus ==
                              DeviceRegistrationStatus.pending
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    profileState.deviceStatus == DeviceRegistrationStatus.active
                        ? Colors.green.shade200
                        : profileState.deviceStatus ==
                                DeviceRegistrationStatus.pending
                            ? Colors.orange.shade200
                            : Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: profileState.deviceStatus ==
                            DeviceRegistrationStatus.active
                        ? Colors.green.shade100
                        : profileState.deviceStatus ==
                                DeviceRegistrationStatus.pending
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    profileState.deviceStatus == DeviceRegistrationStatus.active
                        ? Icons.verified
                        : profileState.deviceStatus ==
                                DeviceRegistrationStatus.pending
                            ? Icons.hourglass_top
                            : Icons.devices,
                    color: profileState.deviceStatus ==
                            DeviceRegistrationStatus.active
                        ? Colors.green
                        : profileState.deviceStatus ==
                                DeviceRegistrationStatus.pending
                            ? Colors.orange
                            : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.deviceRegistration,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: profileState.deviceStatus ==
                                      DeviceRegistrationStatus.active
                                  ? Colors.green
                                  : profileState.deviceStatus ==
                                          DeviceRegistrationStatus.pending
                                      ? Colors.orange
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profileState.deviceStatus ==
                                      DeviceRegistrationStatus.active
                                  ? l10n.active
                                  : profileState.deviceStatus ==
                                          DeviceRegistrationStatus.pending
                                      ? l10n.pending
                                      : l10n.notRegistered,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileState.deviceStatus ==
                                DeviceRegistrationStatus.active
                            ? l10n.deviceActiveDesc
                            : profileState.deviceStatus ==
                                    DeviceRegistrationStatus.pending
                                ? l10n.devicePendingDesc
                                : l10n.deviceRegistrationDesc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (profileState.deviceStatus == DeviceRegistrationStatus.none) ...[
            const SizedBox(height: 12),

            // Register Device Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final status =
                      await profileController.loadDeviceRegistrationStatus();
                  if (!context.mounted) {
                    return;
                  }

                  if (status != DeviceRegistrationStatus.none) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.deviceActiveDesc),
                      ),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.registerDeviceTitle),
                      content: Text(l10n.registerDeviceConfirm),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(l10n.confirm),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) {
                    return;
                  }

                  try {
                    await profileController.verifyNewDevice();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.deviceRegisteredSuccess),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.registerDeviceFailed(e.toString())),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add, color: Colors.blue),
                label: Text(
                  l10n.registerDeviceTitle,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.blue, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // My Device List Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => profileController.openMyDeviceList(context),
              icon: const Icon(Icons.list, color: AppColors.appBarOrange),
              label: Text(
                l10n.myDeviceList,
                style: const TextStyle(
                  color: AppColors.appBarOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(
                  color: AppColors.appBarOrange,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
