import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/src/bloc/image_viewer_bloc.dart';
import 'package:image_viewer/src/bloc/image_viewer_state.dart';
import 'package:image_viewer/src/view/widgets/control_bar/control_bar_main_button.dart';
import 'package:image_viewer/src/view/widgets/control_bar/favourite_button.dart';
import 'package:image_viewer/src/view/widgets/helper_widgets/measure_size.dart';
import 'package:image_viewer/src/view/widgets/notch.dart';

const _collapsedVisiblePx = 62.5; // 50 * 1.25 for 25% taller collapsed sheet
const _snapDuration = Duration(milliseconds: 250);

class ControlBar extends StatefulWidget {
  final MainButtonMode mode;
  final Function onAnotherTap;
  final Function(bool) onPlayTapped;
  final void Function(ImageModel?)? onShareTap;
  final Color? backgroundColor;
  final bool carouselExpanded;

  const ControlBar({
    super.key,
    required this.onAnotherTap,
    required this.mode,
    required this.onPlayTapped,
    required this.backgroundColor,
    required this.carouselExpanded,
    this.onShareTap,
  });

  @override
  State<ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<ControlBar>
    with SingleTickerProviderStateMixin {
  double _slideOffsetPx = 0;
  double _contentHeight = 0;
  bool _controlBarExpanded = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  double get _collapseDistance =>
      (_contentHeight > 0) ? _contentHeight - _collapsedVisiblePx : 0;

  bool get _isCollapsed =>
      (_collapseDistance > 0) && (_slideOffsetPx >= (_collapseDistance - 0.5));

  /// Opacity aligned with scroll: 1 at max (expanded), 0 at min (collapsed),
  /// linear interpolation between.
  double get _contentOpacity {
    if (_collapseDistance <= 0) return 1.0;
    return (1.0 - (_slideOffsetPx / _collapseDistance)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: _snapDuration);
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _snapController.removeListener(_onSnapTick);
    _snapController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) _snapController.stop();
    setState(() {
      _slideOffsetPx += details.delta.dy;
      _slideOffsetPx = _slideOffsetPx.clamp(0.0, _collapseDistance);
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    HapticFeedback.lightImpact();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final threshold = _collapseDistance * 0.5;
    final velocity = details.velocity.pixelsPerSecond.dy;
    final expand =
        velocity < -100 || (velocity.abs() < 100 && _slideOffsetPx < threshold);
    final target = expand ? 0.0 : _collapseDistance;
    _controlBarExpanded = expand;

    HapticFeedback.heavyImpact();

    _snapAnimation = Tween<double>(begin: _slideOffsetPx, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
    _snapController.addListener(_onSnapTick);
  }

  void _onSnapTick() {
    setState(() {
      _slideOffsetPx = _snapAnimation.value;
    });
    if (_snapController.isCompleted) {
      _snapController.removeListener(_onSnapTick);
    }
  }

  Widget _buildSheetContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _controlBarExpanded ? 30 : 0,
            sigmaY: _controlBarExpanded ? 30 : 0,
          ),
          child: BlocBuilder<ImageViewerBloc, ImageViewerState>(
            builder: (context, state) {
              return Container(
                // Animate color/opacity background when collapsed
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (widget.backgroundColor ??
                              (state.selectedImage?.darkestColor ??
                                  Theme.of(context).colorScheme.surface))
                          .withValues(alpha: _contentOpacity.clamp(0, 0.1)),
                      (widget.backgroundColor ??
                              (state.selectedImage?.darkestColor ??
                                  Theme.of(context).colorScheme.surface))
                          .withValues(alpha: _contentOpacity.clamp(0, 0.1)),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color:
                          (widget.backgroundColor ??
                                  (state.selectedImage?.darkestColor ??
                                      Theme.of(context).colorScheme.surface))
                              .withValues(alpha: _contentOpacity.clamp(0, 0.5)),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20.0,
                    left: 20,
                    right: 20,
                    top: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        onVerticalDragStart: _onVerticalDragStart,
                        behavior: HitTestBehavior.opaque,
                        // NO ANIMATION: Notch is always visible!
                        child: const Padding(
                          padding: EdgeInsets.only(
                            bottom: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: Center(child: DraggableNotch()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _contentOpacity,
                        child: IgnorePointer(
                          ignoring: !_controlBarExpanded || _isCollapsed,
                          child: Row(
                            spacing: 24,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FavouriteStarButton(
                                selectedImage: state.selectedImage,
                              ),

                              ControlBarMainButton(
                                onAnotherTap: widget.onAnotherTap,
                                onPlayTapped: widget.onPlayTapped,
                                mode: widget.mode,
                                controlBarExpanded: _controlBarExpanded,
                                carouselExpanded: widget.carouselExpanded,
                              ),

                              CustomIconButton(
                                onTap: () {
                                  widget.onShareTap?.call(state.selectedImage);
                                },
                                icon: Assets.icons.send.designImage(
                                  height: 28,
                                  width: 28,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.transparent,
        child: RepaintBoundary(
          child: MeasureSize(
            onChange: (size) {
              if (size != null && _contentHeight != size.height) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _contentHeight = size.height;
                      if (!_controlBarExpanded) {
                        _slideOffsetPx = _collapseDistance;
                      }
                    });
                  }
                });
              }
            },
            child: Transform.translate(
              offset: Offset(0, _slideOffsetPx),
              child: _buildSheetContent(context),
            ),
          ),
        ),
      ),
    );
  }
}
