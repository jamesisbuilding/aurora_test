import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_viewer/image_viewer.dart';

/// Debug overlay showing current [ImageViewerBloc] state.
/// Only rendered when [kDebugMode] is true.
class BlocStateDebugOverlay extends StatelessWidget {
  const BlocStateDebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BlocBuilder<ImageViewerBloc, ImageViewerState>(
        buildWhen: (prev, curr) => true,
        builder: (context, state) {
          return Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text('loading: ${state.loadingType.name}'),
                    Text('visible: ${state.visibleImages.length}'),
                    Text('fetched: ${state.fetchedImages.length}'),
                    Text(
                      'selected: ${state.selectedImage?.uid ?? "null"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('error: ${state.errorType.name}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
