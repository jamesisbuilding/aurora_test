import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_viewer/src/view/widgets/control_bar/favourite_button.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidGlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isLoading;
  final VoidCallback onGalleryTap; 

  const LiquidGlassButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isLoading = false,
    required this.onGalleryTap,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with AnimatedPressMixin {
  bool _expanded = false;
  @override
  void onPressComplete() {
    if (!widget.isLoading) {
      widget.onTap();
    }
  }

  @override
  onLongPressComplete() {
    if (!_expanded) {
      _expanded = true;
      setState(() {});
    }
    print('long press');
  }

  _toggleExpanded({required bool value}) {
    _expanded = value;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant LiquidGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 10,
          glassColor: Color(0x33FFFFFF),
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Cubic(0.175, 0.885, 0.32, 1.1),
            height: _expanded ? 300 : 40,
            width: _expanded
                ? 50
                : widget.isLoading
                ? 40
                : 100,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 300,
                      width: 40,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          spacing: 8,
                          children: [
                            CustomIconButton(
                              onTap: () => _toggleExpanded(value: false),
                              icon: Assets.icons.x.designImage(
                                height: 20,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            ThemeSwitch(onThemeToggle: () {}),
                            FavouriteStarButton(),
                            const SizedBox(height: 0),
                            CustomIconButton(
                              onTap: () {},
                              icon: Assets.icons.send.designImage(
                                height: 20,
                                width: 20,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 0),
                            CustomIconButton(
                              onTap: () => widget.onGalleryTap(), 
                              icon: Assets.icons.gallery.designImage(
                                height: 20,
                                width: 20,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconButton(
                                onTap: () {},
                                icon: Icon(Icons.play_arrow_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : widget.isLoading
                ? SpinKitPianoWave(
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 12,
                  )
                : Center(
                    child: DelayedDisplay(
                      slidingBeginOffset: const Offset(0, 0),
                      child: Text(widget.label),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}