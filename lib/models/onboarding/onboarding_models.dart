class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? buttonText;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.buttonText,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'buttonText': buttonText,
      };

  factory OnboardingStep.fromMap(Map<String, dynamic> map) => OnboardingStep(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        imageUrl: map['imageUrl'] as String,
        buttonText: map['buttonText'] as String?,
      );
}
