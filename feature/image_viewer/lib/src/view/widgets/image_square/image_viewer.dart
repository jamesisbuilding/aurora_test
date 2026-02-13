import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/cubit/cubit.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_body.dart';
import 'package:image_viewer/src/view/widgets/image_square/image_viewer_square.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({
    super.key,
    required this.image,
    this.isLoading = false,
    this.errorMessage,
    required this.selected,
    this.onTap,
    required this.disabled,
    required this.expanded,
  });

  final ImageModel image;
  final Function(bool)? onTap;
  final bool isLoading;
  final String? errorMessage;
  final bool selected;
  final bool disabled;
  final bool expanded;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> with AnimatedPressMixin {
  @override
  void onPressComplete() {
    widget.onTap?.call(!widget.disabled);
    setState(() {});
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selected != widget.selected) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: AnimatedOpacity(
        opacity: !widget.selected && widget.disabled ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),

          height: widget.expanded ? MediaQuery.sizeOf(context).height : 350,
          child: SingleChildScrollView(
            physics: widget.expanded ? null : NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: .center,
              children: [
                buildPressable(
                  child: DelayedDisplay(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ImageViewerSquare(
                          localPath: widget.image.localPath,
                          networkPath: widget.image.url,
                          imageUid: widget.image.uid,
                          lightestColor: widget.image.lightestColor,
                        ),
                      ),
                    ),
                  ),
                ),

                if (widget.expanded)
                  BlocBuilder<TtsCubit, TtsState>(
                    buildWhen: (prev, curr) =>
                        prev.currentWord != curr.currentWord,
                    builder: (context, ttsState) => ImageViewerBody(
                      title: widget.image.title,
                      description: widget.image.description,
                      colorPalette: widget.image.colorPalette,
                      currentWord: ttsState.currentWord,
                      lightestColor: widget.image.lightestColor,
                      darkestColor: widget.image.darkestColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
