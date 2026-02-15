import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Single source of truth for carousel scroll direction.
/// Drives: scroll direction toggle, ImageCarousel, and ControlBar loading indicator.
class ScrollDirectionCubit extends Cubit<Axis> {
  ScrollDirectionCubit() : super(Axis.horizontal);

  void toggle() {
    emit(state == Axis.vertical ? Axis.horizontal : Axis.vertical);
  }
}
