import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';

class ImageGallery extends StatefulWidget {
  final List<ImageModel> images;
  const ImageGallery({super.key, required this.images});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListWheelScrollView.useDelegate(
        itemExtent: 250,
        squeeze: 0.9,
        perspective: 0.005,
        renderChildrenOutsideViewport: false,
        physics: const RangeMaintainingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.images.length,
          builder: (context, index) => Container(
            height: 250,
            width: 250,
            child: CachedImage(
              url: widget.images[index].url,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
