import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_viewer/src/cubit/scroll_direction_cubit.dart';

void main() {
  late ScrollDirectionCubit cubit;

  setUp(() {
    cubit = ScrollDirectionCubit();
  });

  tearDown(() => cubit.close());

  group('ScrollDirectionCubit', () {
    test('initial state is horizontal', () {
      expect(cubit.state, Axis.horizontal);
    });

    test('toggle from horizontal emits vertical', () {
      cubit.toggle();

      expect(cubit.state, Axis.vertical);
    });

    test('toggle from vertical emits horizontal', () {
      cubit.toggle();
      cubit.toggle();

      expect(cubit.state, Axis.horizontal);
    });

    test('toggle alternates correctly multiple times', () {
      cubit.toggle();
      expect(cubit.state, Axis.vertical);

      cubit.toggle();
      expect(cubit.state, Axis.horizontal);

      cubit.toggle();
      expect(cubit.state, Axis.vertical);
    });
  });
}
