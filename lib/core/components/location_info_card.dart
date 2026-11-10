import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/components/info_row.dart';
import 'package:sampriti/core/utils/helpers/helper_functions.dart';

/// Fixed icon set � "Unit", "Floor", "Building" ??????? ?????? ??? icon
/// ????? ??????, app-?? ?? page-? ??? ?? ????
class LocationInfoIcons {
  static const tenant = HugeIcons.strokeRoundedUser03;
  static const unit = HugeIcons.strokeRoundedHome12;
  static const building = HugeIcons.strokeRoundedBuilding03;
  static const floor = HugeIcons.strokeRoundedStairs01;
  static const type = HugeIcons.strokeRoundedChangeScreenMode;
  static const size = HugeIcons.strokeRoundedSquare;
  static const address = HugeIcons.strokeRoundedLocation01;
}

/// Tenant/Unit/Building/Location info ??????? ???? ???? shared card?
/// ?? field-?? value null, ???? automatically ????? ???? ???? �
/// ??????? page ???? ??? relevant fields ??? ?????
/// Row-?? order ?????? ??????: Tenant ? Unit ? Floor ? Building ? Type ? Size ? Address
class LocationInfoCard extends StatelessWidget {
  final String? tenantName;
  final String? unitName;
  final int? floorNo;
  final String? buildingName;
  final String? unitType;
  final double? sizeSqft;
  final String? address;

  const LocationInfoCard({
    super.key,
    this.tenantName,
    this.unitName,
    this.floorNo,
    this.buildingName,
    this.unitType,
    this.sizeSqft,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void addRow(List<List<dynamic>> icon, String label, String value) {
      if (rows.isNotEmpty) rows.add(const CustomDivider.dotted());
      rows.add(InfoRow(icon: icon, label: label, value: value));
    }

    if (tenantName != null) {
      addRow(LocationInfoIcons.tenant, 'Tenant', tenantName!);
    }
    if (unitName != null) {
      addRow(LocationInfoIcons.unit, 'Unit Name', unitName!);
    }
    if (floorNo != null) {
      addRow(LocationInfoIcons.floor, 'Floor No', 'Floor ${HelperFunctions.padNumber(floorNo!)}');
    }
    if (buildingName != null) {
      addRow(LocationInfoIcons.building, 'Building Name', buildingName!);
    }
    if (unitType != null) {
      addRow(LocationInfoIcons.type, 'Type', HelperFunctions.capitalize(unitType!));
    }
    if (sizeSqft != null) {
      addRow(LocationInfoIcons.size, 'Size', '${HelperFunctions.padNumber(sizeSqft!.round())} sqft');
    }
    if (address != null && address!.trim().isNotEmpty) {
      addRow(LocationInfoIcons.address, 'Address', address!);
    }

    if (rows.isEmpty) {
      rows.add(InfoRow(icon: LocationInfoIcons.unit, label: 'Unit Name', value: 'N/A'));
    }

    return CustomContainer(
      padding: EdgeInsets.zero,
      child: Column(children: rows),
    );
  }
}