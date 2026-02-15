import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:image_viewer/src/view/widgets/carousel/scroll_direction_toggle.dart';

void main() {
  late ScrollDirectionCubit scrollDirectionCubit;

  setUp(() {
    scrollDirectionCubit = ScrollDirectionCubit();
  });

  tearDown(() => scrollDirectionCubit.close());

  Widget buildTestHarness({required Widget child}) {
    return MaterialApp(
      home: BlocProvider<ScrollDirectionCubit>.value(
        value: scrollDirectionCubit,
        child: Scaffold(body: child),
      ),
    );
  }

  group('ScrollDirectionToggle', () {
    testWidgets('shows tooltip for horizontal when in horizontal mode', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(child: const ScrollDirectionToggle()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('Switch to vertical scroll'),
        findsOneWidget,
      );
    });

    testWidgets('tap toggles to vertical and updates tooltip', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(child: const ScrollDirectionToggle()),
      );
      await tester.pumpAndSettle();

      expect(scrollDirectionCubit.state, Axis.horizontal);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(scrollDirectionCubit.state, Axis.vertical);
      expect(
        find.byTooltip('Switch to horizontal scroll'),
        findsOneWidget,
      );
    });

    testWidgets('double tap returns to horizontal', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(child: const ScrollDirectionToggle()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(scrollDirectionCubit.state, Axis.vertical);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(scrollDirectionCubit.state, Axis.horizontal);
    });
  });
}
