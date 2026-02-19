import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/widgets/magazine/magazine_cover.dart';

class MagazineFlow extends StatefulWidget {
  final List<ImageModel> images;
  final String initialImageUid;
  const MagazineFlow({
    super.key,
    required this.images,
    required this.initialImageUid,
  }) : assert(images.length > 0, 'MagazineFlow requires at least one image');

  @override
  State<MagazineFlow> createState() => _MagazineFlowState();
}

class _MagazineFlowState extends State<MagazineFlow> {
  late final PageController _pageController;

  int get _initialIndex {
    final index = widget.images.indexWhere(
      (i) => i.uid == widget.initialImageUid,
    );
    return index >= 0 ? index : 0;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        onPageChanged: (_) {
          HapticFeedback.mediumImpact();
        },
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return MagazineCover(image: widget.images[index]);
        },
      ),
    );
  }
}
