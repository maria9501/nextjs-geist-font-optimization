import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1100) return DeviceType.desktop;
    if (width >= 650) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) => 
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) => 
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) => 
      getDeviceType(context) == DeviceType.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

// Extension methods for responsive padding and spacing
extension ResponsiveSpacing on num {
  double responsiveWidth(BuildContext context) {
    return this * MediaQuery.of(context).size.width / 100;
  }

  double responsiveHeight(BuildContext context) {
    return this * MediaQuery.of(context).size.height / 100;
  }

  EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(responsiveWidth(context));
  }

  EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: responsiveWidth(context));
  }

  EdgeInsets responsiveVerticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(vertical: responsiveHeight(context));
  }
}
