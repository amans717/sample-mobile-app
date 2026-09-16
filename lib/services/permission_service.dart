import 'package:permission_handler/permission_handler.dart';

class PermissionStatusResult {
  final bool isAllGranted;
  final List<Permission> deniedPermissions;
  final List<Permission> permanentlyDeniedPermissions;

  PermissionStatusResult({
    required this.isAllGranted,
    required this.deniedPermissions,
    required this.permanentlyDeniedPermissions,
  });
}

class PermissionService {
  static final PermissionService instance = PermissionService._();
  PermissionService._();

  final List<Permission> _requiredPermissions = [
    Permission.contacts,
    Permission.phone,
    Permission.microphone,
    Permission.audio,
    Permission.notification,
  ];

  Future<bool> hasAllRequiredPermissions() async {
    for (final perm in _requiredPermissions) {
      final status = await perm.status;
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }
    return true;
  }

  Future<PermissionStatusResult> requestAllPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await _requiredPermissions.request();

    final List<Permission> denied = [];
    final List<Permission> permanentlyDenied = [];

    statuses.forEach((permission, status) {
      if (status.isPermanentlyDenied) {
        permanentlyDenied.add(permission);
      } else if (!status.isGranted && !status.isLimited) {
        denied.add(permission);
      }
    });

    final bool allGranted = denied.isEmpty && permanentlyDenied.isEmpty;

    return PermissionStatusResult(
      isAllGranted: allGranted,
      deniedPermissions: denied,
      permanentlyDeniedPermissions: permanentlyDenied,
    );
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  String getPermissionName(Permission permission) {
    if (permission == Permission.contacts) return "Contacts Access";
    if (permission == Permission.phone) return "Phone & Call State";
    if (permission == Permission.microphone) return "Microphone";
    if (permission == Permission.audio) return "Device Audio Files";
    if (permission == Permission.notification) return "Notifications";
    return permission.toString();
  }
}
