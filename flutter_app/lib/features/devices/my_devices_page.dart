import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import 'my_devices_controller.dart';
import 'my_device_applications_controller.dart';
import 'my_device_applications_state.dart';

enum DeviceFilter { all, active, inactive }

final myDevicesFilterProvider =
    StateProvider<DeviceFilter>((_) => DeviceFilter.all);

enum ApplicationFilter { all, approved, rejected, pending }

final myApplicationsFilterProvider =
    StateProvider<ApplicationFilter>((_) => ApplicationFilter.all);

class MyDevicesPage extends ConsumerWidget {
  const MyDevicesPage({super.key});

  Future<String> _getCurrentDeviceSerial() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final androidInfo = await deviceInfo.androidInfo;
      final serial = androidInfo.id;
      if (serial != null && serial.isNotEmpty) return serial;
    } catch (_) {}

    try {
      final iosInfo = await deviceInfo.iosInfo;
      final serial = iosInfo.identifierForVendor;
      if (serial != null && serial.isNotEmpty) return serial;
    } catch (_) {}

    try {
      final windowsInfo = await deviceInfo.windowsInfo;
      final serial = windowsInfo.computerName;
      if (serial != null && serial.isNotEmpty) return serial;
    } catch (_) {}

    try {
      final macOsInfo = await deviceInfo.macOsInfo;
      final serial = macOsInfo.computerName;
      if (serial != null && serial.isNotEmpty) return serial;
    } catch (_) {}

    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(myDevicesControllerProvider);
    final deviceController = ref.read(myDevicesControllerProvider.notifier);
    final appState = ref.watch(myDeviceApplicationsControllerProvider);
    final appController =
        ref.read(myDeviceApplicationsControllerProvider.notifier);

    return FutureBuilder<String>(
      future: _getCurrentDeviceSerial(),
      builder: (context, snapshot) {
        final currentSerial = snapshot.data ?? '';

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.appBarOrange,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    GoRouter.of(context).pop();
                  } else {
                    GoRouter.of(context).go('/proctor-profile');
                  }
                },
              ),
              title: const Text(
                'My Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Devices'),
                  Tab(text: 'Submitted Applications'),
                ],
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundGradientStart,
                    AppColors.backgroundGradientEnd,
                  ],
                ),
              ),
              child: TabBarView(
                children: [
                  _buildDevicesTab(
                      context, ref, deviceState, deviceController, currentSerial),
                  _buildApplicationsTab(context, ref, appState, appController, currentSerial),
                ],
              ),
            ),
            bottomNavigationBar: const BottomNavBar(currentIndex: 3),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab(
    BuildContext context,
    WidgetRef ref,
    dynamic deviceState,
    dynamic deviceController,
    String currentSerial,
  ) {
    if (deviceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deviceState.error != null) {
      return _buildError(context, deviceState.error!, deviceController);
    }

    final selectedFilter = ref.watch(myDevicesFilterProvider);

    final allDevices = List<Map<String, dynamic>>.from(deviceState.devices);
    final filteredDevices = allDevices.where((device) {
      final isActive = device['isActive'] == true;
      if (selectedFilter == DeviceFilter.active) {
        return isActive;
      }
      if (selectedFilter == DeviceFilter.inactive) {
        return !isActive;
      }
      return true;
    }).toList();

    if (filteredDevices.isEmpty) {
      return Column(
        children: [
          _buildFilterRow(ref, selectedFilter),
          Expanded(
            child: Center(
              child: Text(
                'No devices for ${selectedFilter.name} filter.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFilterRow(ref, selectedFilter),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDevices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = filteredDevices[index];
              final name = device['name']?.toString() ?? 'Unknown';
              final serial = device['serial']?.toString() ?? 'Unknown';
              final alreadyActive = device['isActive'] == true;
              final isCurrentDevice = currentSerial.isNotEmpty &&
                  serial.toLowerCase() == currentSerial.toLowerCase();

              return _DeviceCard(
                name: name,
                serial: serial,
                isActive: alreadyActive,
                isCurrentDevice: isCurrentDevice,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(WidgetRef ref, DeviceFilter selectedFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: DeviceFilter.values.map((filter) {
          final title = filter == DeviceFilter.all
              ? 'All'
              : filter == DeviceFilter.active
                  ? 'Active'
                  : 'Inactive';
          final isSelected = selectedFilter == filter;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(myDevicesFilterProvider.notifier).state = filter;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? AppColors.appBarOrange : Colors.grey[300],
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(title),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApplicationFilterRow(
      WidgetRef ref, ApplicationFilter selectedFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ApplicationFilter.values.map((filter) {
          final title = filter == ApplicationFilter.all
              ? 'All'
              : filter == ApplicationFilter.approved
                  ? 'Approved'
                  : filter == ApplicationFilter.rejected
                      ? 'Rejected'
                      : 'Pending';
          final isSelected = selectedFilter == filter;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(myApplicationsFilterProvider.notifier).state = filter;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? AppColors.appBarOrange : Colors.grey[300],
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(title),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApplicationsTab(
    BuildContext context,
    WidgetRef ref,
    MyDeviceApplicationsState appState,
    dynamic appController,
    String currentSerial,
  ) {
    if (appState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appState.error != null) {
      return Center(
          child:
              Text(appState.error!, style: const TextStyle(color: Colors.red)));
    }

    final selectedAppFilter = ref.watch(myApplicationsFilterProvider);

    final allApplications = List<Map<String, dynamic>>.from(appState.applications);
    final filteredApplications = allApplications.where((app) {
      final status = app['status']?.toString().toUpperCase() ?? '';
      switch (selectedAppFilter) {
        case ApplicationFilter.approved:
          return status == 'APPROVED';
        case ApplicationFilter.rejected:
          return status == 'REJECTED';
        case ApplicationFilter.pending:
          return status == 'PENDING';
        case ApplicationFilter.all:
        default:
          return true;
      }
    }).toList();

    if (filteredApplications.isEmpty) {
      return Column(
        children: [
          _buildApplicationFilterRow(ref, selectedAppFilter),
          Expanded(
            child: Center(
              child: Text(
                'No applications for ${selectedAppFilter.name} filter.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildApplicationFilterRow(ref, selectedAppFilter),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredApplications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = filteredApplications[index];
              final status = app['status']?.toString() ?? 'UNKNOWN';
              final createdAt = app['createdAt']?.toString() ?? '';
              final updatedAt = app['updatedAt']?.toString() ?? '';
              final id = app['id']?.toString() ?? '';
              final rejectedReason = app['rejectedReason']?.toString();
              final deviceName = app['deviceName']?.toString();
              final deviceSerial = app['deviceSerial']?.toString();
              final isCurrentDevice = currentSerial.isNotEmpty &&
                  deviceSerial != null &&
                  deviceSerial.toLowerCase() == currentSerial.toLowerCase();

              Color statusColor;
              if (status == 'APPROVED') {
                statusColor = Colors.green;
              } else if (status == 'REJECTED') {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.orange;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device name (bold)
                          Text(
                            deviceName != null && deviceName.isNotEmpty
                                ? deviceName
                                : app['deviceId']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          // Serial
                          if (deviceSerial != null && deviceSerial.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Serial: $deviceSerial',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                          // CreatedAt
                          const SizedBox(height: 4),
                          Text('CreatedAt: $createdAt',
                              style: const TextStyle(fontSize: 13)),
                          // UpdatedAt
                          const SizedBox(height: 2),
                          Text('UpdatedAt: $updatedAt',
                              style: const TextStyle(fontSize: 13)),
                          // Rejected reason (only when REJECTED)
                          if (status == 'REJECTED' &&
                              rejectedReason != null &&
                              rejectedReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: $rejectedReason',
                              style: const TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        if (isCurrentDevice) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'THIS DEVICE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (status == 'PENDING')
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete Application'),
                                  content:
                                      const Text('Delete this application?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await appController.deleteApplication(id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Application deleted')),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    String message,
    MyDevicesController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.loadDevices(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBarOrange,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No devices found.',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.name,
    required this.serial,
    required this.isActive,
    required this.isCurrentDevice,
  });

  final String name;
  final String serial;
  final bool isActive;
  final bool isCurrentDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.devices,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Serial: $serial',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isCurrentDevice) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'THIS DEVICE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
