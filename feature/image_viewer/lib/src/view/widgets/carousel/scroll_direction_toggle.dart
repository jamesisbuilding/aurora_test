import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/src/cubit/scroll_direction_cubit.dart';

/// Toggle button that updates [ScrollDirectionCubit]. Listens exclusively to the cubit.
class ScrollDirectionToggle extends StatelessWidget {
  const ScrollDirectionToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScrollDirectionCubit, Axis>(
      builder: (context, scrollDirection) {
        final theme = Theme.of(context);
        return IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<ScrollDirectionCubit>().toggle();
          },
          style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
          icon: AnimatedRotation(
            turns: scrollDirection == Axis.vertical ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Assets.icons.arrowDownUp.designImage(
              height: 24,
              width: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
          tooltip: scrollDirection == Axis.vertical
              ? 'Switch to horizontal scroll'
              : 'Switch to vertical scroll',
        );
      },
    );
  }
}
