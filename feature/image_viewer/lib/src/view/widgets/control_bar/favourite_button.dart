import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';

class FavouriteStarButton extends StatelessWidget {
  const FavouriteStarButton({
    this.selectedImage,
    this.debugBuildCount,
  });

  final ImageModel? selectedImage;

  /// When non-null (tests only), incremented each time the builder runs.
  final ValueNotifier<int>? debugBuildCount;

  @override
  Widget build(BuildContext context) {
    final uid = selectedImage?.uid ?? '';
    final theme = Theme.of(context);

    return BlocBuilder<FavouritesCubit, Set<String>>(
      buildWhen: (prev, curr) => prev.contains(uid) != curr.contains(uid),
      builder: (context, favourites) {
        debugBuildCount?.value = (debugBuildCount?.value ?? 0) + 1;
        final isFavourite = uid.isNotEmpty && favourites.contains(uid);
        final favouriteColor = theme.brightness == Brightness.light
            ? Colors.amber.shade800
            : Colors.yellow;
        return CustomIconButton(
          onTap: () {
            if (uid.isNotEmpty) {
              context.read<FavouritesCubit>().toggle(uid);
            }
          },
          icon: Assets.icons.star.designImage(
            height: 20,
            width: 20,
            color: isFavourite ? favouriteColor : theme.colorScheme.onSurface,
          ),
        );
      },
    );
  }
}
