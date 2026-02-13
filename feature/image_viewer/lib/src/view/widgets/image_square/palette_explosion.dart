import 'dart:math';

import 'package:delayed_display/delayed_display.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_analysis_service/image_analysis_service.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/utils/image_provider_utils.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PaletteInteraction extends StatefulWidget {
  final ImageModel image;
  final List<Color> colors;
  final Function(bool) onChanged;
  const PaletteInteraction({
    super.key,
    required this.colors,
    required this.onChanged,
    required this.image,
  });

  @override
  _PaletteInteractionState createState() => _PaletteInteractionState();
}

class _PaletteInteractionState extends State<PaletteInteraction>
    with TickerProviderStateMixin {
  // Updated to TickerProvider for the 2nd controller
  bool isExpanded = false;
  bool isExiting = false;
  late AnimationController _rotationController;
  late AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Speed of the machine-gun exit
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void triggerExit() async {
    setState(() => isExiting = true);
    await _exitController.forward();

    context.read<CollectedColorsCubit>().add(
          widget.image.uid,
          widget.colors,
        );

    setState(() {
      isExpanded = false;
      isExiting = false;
      _exitController.reset();
    });
    widget.onChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectedColorsCubit, Map<String, List<Color>>>(
      buildWhen: (prev, curr) =>
          prev.containsKey(widget.image.uid) != curr.containsKey(widget.image.uid),
      builder: (context, collected) {
        final isCollected = collected.containsKey(widget.image.uid);
        return _buildContent(context, isCollected);
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isCollected) {
    return Transform.translate(
      offset: Offset(0, !isExpanded ? 0 : -200),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          IgnorePointer(
            ignoring: isCollected,
            child: Opacity(
              opacity: isCollected ? 0.2 : 1,
              child: GestureDetector(
                onTap: () {
                  if (isExiting) return;
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                  widget.onChanged(isExpanded);
                },
                child: SizedBox(
              width:
                  250, // Increased slightly to prevent clipping during rotation
              height: isExpanded ? 100 : 12,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(widget.colors.length, (index) {
                  double angle = (index * 2 * pi) / widget.colors.length;

                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _rotationController,
                      _exitController,
                    ]),
                    builder: (context, child) {
                      double currentAngle =
                          angle + (_rotationController.value * 2 * pi);

                      // Logic for consecutive drop
                      // Staggers the start time based on the index
                      double start = (index * 0.1).clamp(0.0, 0.5);
                      double end = (start + 0.5).clamp(0.0, 1.0);
                      double verticalOffset =
                          CurvedAnimation(
                            parent: _exitController,
                            curve: Interval(
                              start,
                              end,
                              curve: Curves.easeInBack,
                            ),
                          ).value *
                          800; // 800 is the distance it falls downwards

                      return AnimatedAlign(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        alignment: isExpanded
                            ? Alignment(cos(currentAngle), sin(currentAngle))
                            : Alignment(-0.4 + (index * 0.2), 0.8),
                        child: Transform.translate(
                          // This moves them downward consecutively without breaking your rotation
                          offset: Offset(0, verticalOffset),
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(60),
                            child: DelayedDisplay(
                              delay: Duration(milliseconds: index * 100),
                              slidingBeginOffset: Offset(0, 0),
                              child: Material(
                                elevation: 10, 
                                shape: const CircleBorder(),

                                child: Shimmer(
                                  enabled: isExpanded,
                                  child: Container(
                                    width: isExpanded ? 60 : 12,
                                    height: isExpanded ? 60 : 12,
                                    decoration: BoxDecoration(
                                      color: widget.colors[index],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(alpha: isExpanded ? 0.1 : 1),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 10,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ),
        ),
          if (isExpanded) const SizedBox(height: 300),
          if (isExpanded && !isExiting && !isCollected)
            MainButton(
              backgroundImage: imageProviderForImage(widget.image),
              label: 'Collect Colors',
              onTap: triggerExit,
            ),
        ],
      ),
    );
  }
}
