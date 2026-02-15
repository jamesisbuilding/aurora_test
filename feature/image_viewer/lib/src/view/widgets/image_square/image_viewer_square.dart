import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:design_system/design_system.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ImageViewerSquare extends StatelessWidget {
  const ImageViewerSquare({
    super.key,
    required this.localPath,
    required this.networkPath,
    this.imageUid,
    this.lightestColor,
    this.darkestColor,
  });

  final String localPath;
  final String networkPath;
  final String? imageUid;
  final Color? lightestColor;
  final Color? darkestColor;

  @override
  Widget build(BuildContext context) {
    return _buildFavouriteOverlay(
      context,
      Material(
        elevation: 10,
        shadowColor: darkestColor ?? Theme.of(context).colorScheme.surface,

        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: _buildImageContent(context),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (localPath.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(localPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).primaryColor,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (networkPath.isNotEmpty && isNetworkURL(networkPath))
          CachedImage(
            url: networkPath,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
      ],
    );
  }

  Widget _buildFavouriteOverlay(BuildContext context, Widget child) {
    final uid = imageUid!;

    return BlocBuilder<FavouritesCubit, Set<String>>(
      buildWhen: (prev, curr) => prev.contains(uid) != curr.contains(uid),
      builder: (context, favourites) {
        final isFavourite = favourites.contains(uid);
        return ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(12),
          child: Shimmer(
            color: lightestColor ?? Colors.yellow,
            duration: const Duration(seconds: 10),
            colorOpacity: 0.5,
            enabled: isFavourite,
            child: child,
          ),
        );
      },
    );
  }
}
