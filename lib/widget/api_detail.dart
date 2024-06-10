import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> fetchAnimeDetails(int animeId) async {
    try {
      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': '''
            query {
              Media(id: $animeId, type: ANIME) {
                title {
                  romaji
                }
                coverImage {
                  large
                }
                bannerImage
                description
                episodes
                format
                genres
                type
                status
                studios {
                  nodes {
                    name
                  }
                }
                popularity
                averageScore
                duration
                airingSchedule {
                  nodes {
                    airingAt
                  }
                }
                characters {
                  edges {
                    role
                    node {
                      id
                      name {
                        full
                      }
                      image {
                        large
                      }
                    }
                  }
                }
                staff {
                  edges {
                    role
                    node {
                      id
                      name {
                        full
                      }
                    }
                  }
                }
                relations {
                  edges {
                    relationType
                    node {
                      id
                      title {
                        romaji
                      }
                    }
                  }
                }
                recommendations {
                  edges {
                    node {
                      mediaRecommendation {
                        title {
                          romaji
                        }
                        id
                        coverImage {
                          large
                        }
                        description
                        averageScore
                      }
                    }
                  }
                }
              }
            }
          '''
        }),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        Map<String, dynamic> animeData = data['data']['Media'];
        // Rest of your code for extracting and returning relevant information...
        return animeData;
      } else {
        throw Exception(
            'Failed to load anime details from AniList for ID: $animeId');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch anime details');
    }
  }
}
