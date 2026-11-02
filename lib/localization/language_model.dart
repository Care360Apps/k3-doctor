class Language {
  final int id;
  final String name;
  final String flag;
  final String languageCode;

  Language(this.id, this.name, this.flag, this.languageCode);

  static List<Language> languageList() {
    return <Language>[
      Language(1, 'English', 'EN', 'en'),
      Language(2, 'Hausa', 'HA', 'ha'),
      Language(3, 'Igbo', 'IG', 'ig'),
      Language(4, 'Yorùbá', 'YO', 'yo'),
      Language(5, 'Français', 'FR', 'fr'),
    ];
  }
}
