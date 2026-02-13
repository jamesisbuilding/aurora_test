import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks collected color palettes by image UID.
/// Mirrors [FavouritesCubit] pattern for minimal rebuild scope.
class CollectedColorsCubit extends Cubit<Map<String, List<Color>>> {
  CollectedColorsCubit() : super({});

  void add(String imageUid, List<Color> colors) {
    if (imageUid.isEmpty) return;
    final next = Map<String, List<Color>>.from(state);
    next[imageUid] = List<Color>.from(colors);
    emit(next);
  }

  bool isCollected(String imageUid) => state.containsKey(imageUid);

  List<({String imageUid, List<Color> colors})> get collectedPalettes =>
      state.entries.map((e) => (imageUid: e.key, colors: e.value)).toList();
}
