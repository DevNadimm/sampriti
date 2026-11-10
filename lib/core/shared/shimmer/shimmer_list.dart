import 'package:flutter/material.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'shimmer_container.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double itemWidth;
  final double spacing;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.itemWidth = double.infinity,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (_, _) {
        return CustomContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerContainer(height: 45, width: 45),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(height: 14, width: width / 4),
                      SizedBox(height: 8),
                      ShimmerContainer(height: 20, width: width / 3),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              ShimmerContainer(height: 14, width: width / 2),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ShimmerContainer(height: 14, width: width / 5),
                        SizedBox(height: 8),
                        ShimmerContainer(height: 20, width: width / 3.5),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ShimmerContainer(height: 14, width: width / 5),
                        SizedBox(height: 8),
                        ShimmerContainer(height: 20, width: width / 3.5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
