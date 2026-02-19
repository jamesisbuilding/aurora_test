import 'package:design_system/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:image_viewer/src/view/widgets/parallax/custom_parallax.dart';

class MagazinePage extends StatelessWidget {
  const MagazinePage({
    super.key,
    required this.sentence,
    required this.isTextLeft,
    required this.imageUrl,
    required this.viewportHeight,
    required this.viewportWidth,
  });

  final String sentence;
  final bool isTextLeft;
  final String imageUrl;
  final double viewportHeight;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: viewportHeight,
      width: viewportWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: isTextLeft
            ? [
                _buildTextPane(sentence, alignLeft: true),
                _buildImagePane(),
              ]
            : [
                _buildImagePane(),
                _buildTextPane(sentence, alignLeft: false),
              ],
      ),
    );
  }

  Widget _buildTextPane(String value, {required bool alignLeft}) {
    return Expanded(
      child: ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              value,
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: FontFamily.raleway,
                package: 'design_system',
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePane() {
    return Expanded(
      child: CustomImageParallax(
        height: viewportHeight,
        width: viewportWidth / 2,
        imageUrl: imageUrl,
      ),
    );
  }
}
