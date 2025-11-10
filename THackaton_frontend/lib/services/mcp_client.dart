import 'dart:convert';
import 'package:http/http.dart' as http;

/// MCPClient – Flutter oldali kliens az MCP szerverhez.
class MCPClient {
  final String baseUrl;

  MCPClient({required this.baseUrl});

  /// Általános POST kérés az MCP szerver felé.
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('MCP request failed: ${response.statusCode} ${response.body}');
    }
  }


  /// Felső turisztikai látnivalók lekérése
  Future<List<dynamic>> getTopAttractions(String destination, {int limit = 5}) async {
    final result = await _post('/mcp/tourism', {
      "tool": "GetTopAttractions",
      "parameters": {
        "destination_name": destination,
        "limit": limit,
      }
    });

    return result['data'] ?? [];
  }

  /// Éttermek és kávézók lekérése
  Future<List<dynamic>> getRestaurants(String destination, {int limit = 5}) async {
    final result = await _post('/mcp/tourism', {
      "tool": "GetRestaurantsAndCafes",
      "parameters": {
        "destination_name": destination,
        "limit": limit,
      }
    });

    return result['data'] ?? [];
  }

  /// ATM keresés
  Future<List<dynamic>> findATMs(String city, {int distance = 2}) async {
    final result = await _post('/mcp/tourism', {
      "tool": "ATMLocator",
      "parameters": {
        "location": city,
        "distance": distance,
      }
    });

    return result['data'] ?? [];
  }



  /// Élmények keresése Kärnten régióban
  Future<List<dynamic>> searchExperiences({String? dateFrom, String? dateTo}) async {
    final result = await _post('/mcp/dsapi', {
      "tool": "SearchExperiences",
      "parameters": {
        if (dateFrom != null) "date_from": dateFrom,
        if (dateTo != null) "date_to": dateTo,
      }
    });

    return result['data'] ?? [];
  }

  /// Termék elérhetőségek lekérése
  Future<Map<String, dynamic>> getProductAvailability({
    required String spIdentity,
    required String serviceId,
    required String dateFrom,
    required String dateTo,
  }) async {
    final result = await _post('/mcp/dsapi', {
      "tool": "GetProductAvailability",
      "parameters": {
        "sp_identity": spIdentity,
        "service_id": serviceId,
        "date_from": dateFrom,
        "date_to": dateTo,
      }
    });

    return result;
  }
}
