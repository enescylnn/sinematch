import '../models/movie.dart';
import '../models/discovery_profile.dart';
import '../models/match_item.dart';
import '../models/chat_message.dart';

const demoMovies = <Movie>[
  Movie(id: 1, title: 'Interstellar', overview: 'İnsanlığın geleceği için yıldızlararası bir yolculuk.', type: 'movie', year: 2014, rating: 8.7, genres: ['Bilim Kurgu', 'Dram']),
  Movie(id: 2, title: 'Dune: Part Two', overview: 'Paul Atreides kaderiyle yüzleşirken Arrakis üzerindeki savaş büyür.', type: 'movie', year: 2024, rating: 8.6, genres: ['Bilim Kurgu', 'Macera']),
  Movie(id: 3, title: 'The Dark Knight', overview: 'Batman, Gotham’ın kaosa sürüklenmesini önlemek için Joker ile karşı karşıya gelir.', type: 'movie', year: 2008, rating: 9.0, genres: ['Aksiyon', 'Suç']),
  Movie(id: 4, title: 'Arrival', overview: 'Dünya dışı ziyaretçilerle iletişim kurmaya çalışan bir dilbilimcinin hikâyesi.', type: 'movie', year: 2016, rating: 7.9, genres: ['Bilim Kurgu', 'Dram']),
  Movie(id: 5, title: 'Dark', overview: 'Kayıp bir çocuk, dört ailenin zamanla örülü sırlarını açığa çıkarır.', type: 'series', year: 2017, rating: 8.7, genres: ['Bilim Kurgu', 'Gerilim']),
  Movie(id: 6, title: 'Severance', overview: 'İş ve özel hayat anılarının cerrahi olarak ayrıldığı rahatsız edici bir düzen.', type: 'series', year: 2022, rating: 8.7, genres: ['Bilim Kurgu', 'Gerilim']),
];

const demoProfiles = <DiscoveryProfile>[
  DiscoveryProfile(id: 101, name: 'Elif', compatibility: 94, city: 'İstanbul', age: 26, favoriteTitles: ['Interstellar', 'Dark', 'Fight Club'], bio: 'Bilim kurgu, kahve ve uzun film sohbetleri.'),
  DiscoveryProfile(id: 102, name: 'Zeynep', compatibility: 91, city: 'Ankara', age: 27, favoriteTitles: ['Dune', 'Arrival', 'Severance'], bio: 'Yeni yönetmenler keşfetmeye bayılırım.'),
  DiscoveryProfile(id: 103, name: 'Deniz', compatibility: 88, city: 'İzmir', age: 28, favoriteTitles: ['The Dark Knight', 'Prisoners', 'Dark'], bio: 'Gerilim ve suç filmlerinde iddialıyım.'),
];

const demoMatches = <MatchItem>[
  MatchItem(id: 1, userId: 101, name: 'Elif', compatibility: 94, lastMessage: 'Interstellar mı Dune mu? 🎬', unread: 2),
  MatchItem(id: 2, userId: 102, name: 'Zeynep', compatibility: 91, lastMessage: 'Bu akşam bir şeyler izleyelim mi?', unread: 0),
];

List<ChatMessage> demoMessages(int myUserId) => [
  ChatMessage(id: 1, senderId: 101, body: 'Bu akşam ne izleyelim? 🎬', createdAt: DateTime.now().subtract(const Duration(minutes: 12))),
  ChatMessage(id: 2, senderId: myUserId, body: 'Interstellar tekrar gider bence 😄', createdAt: DateTime.now().subtract(const Duration(minutes: 9))),
  ChatMessage(id: 3, senderId: 101, body: 'Tamamdır, film zevkine güveniyorum.', createdAt: DateTime.now().subtract(const Duration(minutes: 6))),
];
