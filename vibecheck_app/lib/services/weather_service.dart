import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final double tempCelsius;
  final String condition; // "Clear", "Clouds", "Rain", "Drizzle", "Thunderstorm", etc.
  final String description;
  final String emoji;

  const WeatherData({
    required this.city,
    required this.tempCelsius,
    required this.condition,
    required this.description,
    required this.emoji,
  });

  static String conditionToEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':       return '☀️';
      case 'clouds':      return '☁️';
      case 'rain':        return '🌧️';
      case 'drizzle':     return '🌦️';
      case 'thunderstorm':return '⛈️';
      case 'snow':        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':        return '🌫️';
      default:            return '🌤️';
    }
  }
}

class WeatherService {
  static const String _apiKey = '2040dab089c11e5a9402feac29b97ec9';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // ขอ permission GPS และดึง location
  static Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low, // ประหยัด battery
    );
  }

  // ดึงข้อมูลอากาศจาก location จริง
  static Future<WeatherData?> fetchWeather() async {
    try {
      final position = await _getLocation();
      if (position == null) return null;

      final url = Uri.parse(
      '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}'
      '&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final condition = json['weather'][0]['main'] as String;
      final description = json['weather'][0]['description'] as String;
      final temp = (json['main']['temp'] as num).toDouble();
      final city = json['name'] as String;

      return WeatherData(
        city: city,
        tempCelsius: temp,
        condition: condition,
        description: description,
        emoji: WeatherData.conditionToEmoji(condition),
      );
    } catch (_) {
      return null;
    }
  }
}