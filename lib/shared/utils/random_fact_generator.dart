import 'dart:math';

String getRandomChattingAppTip() {
  List<String> chattingFunFacts = [
    "Over 3 billion people use messaging apps worldwide, making them one of the most popular app categories.",
    "WhatsApp alone has over 2.5 billion users, making it the most widely used chat app globally.",
    "People send over 100 billion messages daily on WhatsApp.",
    "The average user spends about 33.5 minutes per day on messaging apps.",
    "63% of people prefer chatting with a chatbot to communicate with businesses rather than calling customer service.",
    "98% of WhatsApp messages are read within 24 hours, showing extremely high engagement.",
    "In China, WeChat users open the app more than 10 times a day on average due to its all-in-one functionality.",
    "Emojis and memes have become essential tools for expressing emotion and humor in digital conversations.",
    "Many users rely on chat apps for sharing personal moments, coordinating work, planning events, and sending photos in real time.",
    "People often use chat apps during evenings and weekends, with peak activity on weekends, especially Saturday afternoons.",
    "Telegram and Signal have grown in popularity due to their focus on privacy and end-to-end encryption.",
    "In some countries, messaging apps like Line (Japan) and KakaoTalk (South Korea) dominate local communication."
  ];

  final random = Random();
  return chattingFunFacts[random.nextInt(chattingFunFacts.length)];
}