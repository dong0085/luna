/// The three supported story lengths. `apiValue` is what the backend contract
/// expects in the `length` field of `POST /stories/generate`.
enum StoryLength {
  short('Short', '~5 min', '600–700 words'),
  medium('Medium', '~10 min', '1,200–1,400 words'),
  long('Long', '~15 min', '1,800–2,100 words');

  const StoryLength(this.label, this.duration, this.wordHint);

  final String label;
  final String duration;
  final String wordHint;

  /// Value sent to / received from the backend (`short` | `medium` | `long`).
  String get apiValue => name;

  static StoryLength fromApi(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => StoryLength.short);
}
