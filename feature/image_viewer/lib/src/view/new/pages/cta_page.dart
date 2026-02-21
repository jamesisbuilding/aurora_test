import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/view/new/widgets/button/liquid_glass_button.dart';
import 'package:image_viewer/src/view/widgets/background/image_viewer_background.dart';

class CTAPage extends StatefulWidget {
  final ImageModel image;
  const CTAPage({super.key, required this.image});

  @override
  State<CTAPage> createState() => _CTAPageState();
}

class _CTAPageState extends State<CTAPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        child: Stack(
          children: [
            // AnimatedBackground(imageColors: [Colors.white, Colors.white10, widget.image.lightestColor]),
            Container(
              height: MediaQuery.sizeOf(context).height,
              width: MediaQuery.sizeOf(context).width,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            Column(
              crossAxisAlignment: .center,
              children: [
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: 'color_key',
                      child: CachedImage(
                        url: widget.image.url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: Text(
                            widget.image.title,
                            style: TextStyle(
                              color: Colors.black,
                              letterSpacing: -3,
                              fontWeight: FontWeight.w600,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width / 1.3,
                          child: Text(
                            widget.image.description,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.2),
                              letterSpacing: -3,
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              height: 1,
                            ),
                          ),
                        ),

                        
                        // ColorSelector(image: widget.image),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: PurchaseButton(),
    );
  }
}

class ColorSelector extends StatefulWidget {
  final ImageModel image;
  const ColorSelector({super.key, required this.image});

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  _updateSelectedIndex(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Selected Color: ',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.2),
                  letterSpacing: -.2,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '#${widget.image.colorPalette[_selectedIndex].value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                style: TextStyle(
                  color: Colors.black,
                  letterSpacing: -.2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 30,
            child: Row(
              children: widget.image.colorPalette
                  .map(
                    (c) => ColorButton(
                      color: c,
                      onTap: (color) {
                        int index = widget.image.colorPalette.indexWhere(
                          (c_) => c_ == color,
                        );
                        _updateSelectedIndex(index);
                      },
                      selected:
                          _selectedIndex ==
                          widget.image.colorPalette.indexWhere((c_) => c_ == c),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorButton extends StatefulWidget {
  final Color color;
  final Function(Color) onTap;
  final bool selected;
  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.selected,
  });

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> with AnimatedPressMixin {
  @override
  void onPressComplete() {
    widget.onTap(widget.color);
  }

  @override
  void didUpdateWidget(covariant ColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selected != widget.selected) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          height: widget.selected ? 20 : 16,
          width: widget.selected ? 20 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(
              color: widget.selected ? Colors.black : Colors.transparent,
              width: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class PurchaseButton extends StatefulWidget {
  const PurchaseButton({super.key});

  @override
  State<PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends State<PurchaseButton>
    with AnimatedPressMixin {
  @override
  void onPressComplete() {
    // TODO: implement onPressComplete
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      child: Container(
        height: 60,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(60),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DONE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: -.2,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
