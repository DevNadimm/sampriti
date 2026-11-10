import 'package:flutter/material.dart';
import 'package:sampriti/core/shared/shimmer/shimmer_list.dart';

typedef AsyncWidgetBuilder<T> = Widget Function(BuildContext context, T data);

class AsyncView<T> extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isEmpty;
  final T? data;
  final AsyncWidgetBuilder<T> builder;
  final Widget? shimmer;

  const AsyncView({
    super.key,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
    this.isEmpty = false,
    this.data,
    required this.builder,
    this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return shimmer ?? const ShimmerList();
    }

    if (hasError) {
      return Center(
        child: Text(
          errorMessage ?? "Something went wrong",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (isEmpty) {
      return const Center(child: Text("No data available"));
    }

    if (data != null) {
      return builder(context, data as T);
    }

    return const SizedBox.shrink();
  }
}

/// Example Usage with Cubit
// BlocBuilder<ItemsCubit, ItemsState>(
//   builder: (context, state) {
//     return AsyncView<List<String>>(
//       isLoading: state.isLoading,
//       hasError: state.hasError,
//       errorMessage: state.errorMessage,
//       isEmpty: state.items.isEmpty,
//       data: state.items,
//       shimmer: ShimmerList(itemCount: 5, itemHeight: 60),
//       builder: (context, items) => ListView.builder(
//         itemCount: items.length,
//         itemBuilder: (context, index) => ListTile(
//           title: Text(items[index]),
//         ),
//       ),
//     );
//   },
// )
