/// Result of AI-generated image captioning (title + description).
class ImageCaptionResult {
  const ImageCaptionResult({
    required this.title,
    required this.description,
    required this.founderName,
    required this.founderDescription,
    required this.description2,
    required this.hypeBuildingTagline1,
    required this.hypeBuildingTagline2,
    required this.hypeBuildingTagline3,
    required this.hypeBuildingTagline4,
    required this.hypeBuildingTagline5,
  });

  final String title;
  final String description;
  final String founderName;
  final String founderDescription;
  final String description2;
  final String hypeBuildingTagline1;
  final String hypeBuildingTagline2;
  final String hypeBuildingTagline3;
  final String hypeBuildingTagline4;
  final String hypeBuildingTagline5;

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'founderName': founderName,
        'founderDescription': founderDescription,
        'description2': description2,
        'hypeBuildingTagline1': hypeBuildingTagline1,
        'hypeBuildingTagline2': hypeBuildingTagline2,
        'hypeBuildingTagline3': hypeBuildingTagline3,
        'hypeBuildingTagline4': hypeBuildingTagline4,
        'hypeBuildingTagline5': hypeBuildingTagline5,
      };
}
