import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// --- Alap konstansok és URL-ek ---
const String _baseUrl = 'https://dsapi.deskline.net';
const String _regionCode = 'kaernten';
const String _languageCode = 'de';
const String _dbCode = 'KTN';
const String _username = 'TTFHACKTL';
const String _password = '6VVuseYRz2VfCVvXpxgTGovGcHw8';

class DesklineAPIService {
  // --- Azonosítók és állapotok ---
  String? _bearerToken;
  String? filterObjectId;
  String? searchObjectId;
  String? shoppingListId;
  final Uuid _uuid = const Uuid();

  // --- Segédfüggvények ---

  // Létrehozza a standard headereket, beleértve a Tokent és a Session ID-t
  Map<String, String> get _headers {
    final Map<String, String> baseHeaders = {
      'Content-Type': 'application/json',
      'dw-source': 'desklineweb',
      'DW-SessionId': _uuid.v4(), // Új Session ID minden API híváshoz
    };

    if (_bearerToken != null) {
      baseHeaders['Authorization'] = 'Bearer $_bearerToken';
    }
    return baseHeaders;
  }

  // Ellenőrzi a válasz státuszát és dekódolja a JSON-t
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      // Hiba kezelése (pl. 401 Unauthorized, 404 Not Found)
      throw Exception('API hiba: ${response.statusCode}. Válasz: ${response.body}');
    }
  }

  // ====================================================================
  // 1. 🔐 Authentication
  // ====================================================================

  Future<bool> authenticate() async {
    final Uri url = Uri.parse('$_baseUrl/Auth?username=$_username&password=$_password');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        _bearerToken = response.body.trim();
        print('✅ Sikeres hitelesítés. Token: ${_bearerToken!.substring(0, 10)}...');
        return true;
      }
      print('❌ Hitelesítés sikertelen. Státusz: ${response.statusCode}');
      return false
      ;
    } catch (e) {
      print('❌ Hiba a hívás során: $e');
      return false;
    }
  }

  // ====================================================================
  // 2. 🗓️ Search (Keresés)
  // ====================================================================

  Future<String?> createSearch(DateTime dateFrom, DateTime dateTo) async {
    final Uri url = Uri.parse('$_baseUrl/searches');
    final Map<String, dynamic> body = {
      'searchObject': {
        'searchGeneral': {
          'dateFrom': dateFrom.toIso8601String(),
          'dateTo': dateTo.toIso8601String(),
        },
      },
    };
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      final data = _handleResponse(response);
      searchObjectId = data['id'];
      print('✅ Search objektum létrehozva: $searchObjectId');
      return searchObjectId;
    } catch (e) {
      print('❌ Hiba a Search létrehozásakor: $e');
      return null;
    }
  }

  // ====================================================================
  // 3. 🔎 Filter (Szűrő)
  // ====================================================================

  Future<String?> createOrUpdateFilter({
    List<String>? types,
    List<String>? locations,
    List<String>? holidayThemes,
    String? name,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/filters${filterObjectId != null ? '/$filterObjectId' : ''}');
    final String initialId = filterObjectId ?? '00000000-0000-0000-0000-000000000000';
    final String method = filterObjectId != null ? 'PUT' : 'POST';

    final Map<String, dynamic> body = {
      'filterObject': {
        'id': initialId,
        'filterGeneral': {},
        'filterAddServices': {
          'types': types,
          'holidayThemes': holidayThemes,
          'locations': locations,
          'guestCards': null,
          'name': name ?? '',
        },
        // A PUT kérésnél elküldheted az Accommodation szűrőt is, ha releváns
      },
    };

    try {
      http.Response response;
      if (method == 'POST') {
        response = await http.post(url, headers: _headers, body: json.encode(body));
      } else {
        response = await http.put(url, headers: _headers, body: json.encode(body));
      }

      final data = _handleResponse(response);
      filterObjectId = data['id'];
      print('✅ Filter $method sikeres: $filterObjectId');
      return filterObjectId;
    } catch (e) {
      print('❌ Hiba a Filter $method során: $e');
      return null;
    }
  }

  // ====================================================================
  // 4. 🧭 Experiences (Élmények listázása)
  // ====================================================================

  // 4a. Filter Options (Facetek) lekérése
  Future<dynamic> getFilterOptions() async {
    if (filterObjectId == null) throw Exception('Filter ID hiányzik a Filter Options lekéréséhez.');

    // A lekérdezett mezők megegyeznek a dokumentációban lévőkkel (types, locations)
    final String fields =
        'types{id,name,count},holidayThemes{id,name,count},locations(locTypes:[3]){id,name,count},guestCards{id,name,count,type,typeId,iconUrl,webLink}';

    final Uri url = Uri.parse('$_baseUrl/addservices/$_regionCode/$_languageCode/filterresults/$filterObjectId')
        .replace(queryParameters: {
      'fields': fields,
      'limAddSrvTHEME': '38723CC4-C5F0-4707-9401-5F598D892246',
      'limExAccShSPwoPr': 'false',
      'dbCode': _dbCode,
    });

    try {
      final response = await http.get(url, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      print('❌ Hiba a Filter Options lekérésekor: $e');
      return null;
    }
  }

  // 4b. Élmények listázása (Search és Filter alapján)
  Future<List<dynamic>?> listExperiences() async {
    if (searchObjectId == null || filterObjectId == null) {
      throw Exception('Search vagy Filter ID hiányzik az élmények listázásához.');
    }

    final Uri url = Uri.parse('$_baseUrl/addservices/$_regionCode/$_languageCode/searchresults/$searchObjectId')
        .replace(queryParameters: {
      'filterId': filterObjectId!,
      'currency': 'EUR',
      'pageNo': '1',
      'pageSize': '5000',
      'dbCode': _dbCode,
    });

    try {
      final response = await http.get(url, headers: _headers);
      final data = _handleResponse(response);
      return data['data'] as List<dynamic>?;
    } catch (e) {
      print('❌ Hiba az élmények listázásakor: $e');
      return null;
    }
  }

  // ====================================================================
  // 5. 🔍 Experience Detail (Termékek és Elérhetőség)
  // ====================================================================

  // 5a. Termékek listázása
  Future<dynamic> getServiceProducts(String spIdentity, String serviceId) async {
    final String fields = 'id,name,isFreeBookable,price{from,to,insteadFrom,insteadTo}';
    final Uri url = Uri.parse('$_baseUrl/addservices/$_regionCode/$_languageCode/$_dbCode/$spIdentity/services/$serviceId/products')
        .replace(queryParameters: {
      'fields': fields,
      'currency': 'EUR',
      'limAddSrvTHEME': '38723CC4-C5F0-4707-9401-5F598D892246',
      'limExAccShSPwoPr': 'false',
      'filterId': filterObjectId!,
    });

    try {
      final response = await http.get(url, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      print('❌ Hiba a Termékek lekérésekor: $e');
      return null;
    }
  }

  // 5b. Termék elérhetőségének lekérése (Availability)
  Future<dynamic> getProductAvailability(String spIdentity, String serviceId) async {
    if (searchObjectId == null) throw Exception('Search ID hiányzik az elérhetőség lekéréséhez.');

    // A hosszú 'fields' paraméter a dokumentáció alapján
    const String fields =
        'id,name,isFreeBookable,isOwnAvailability,priceChoosableByGuest{active,minPrice,maxPrice},bookInfo{date,startTime,duration,price,insteadPrice,availability,isBookable,isBookableOnRequest,isOfferable,paymentCancellationPolicy{cancellationPolicy{cancellationTextType,defaultHeaderTextNumber,hasFreeCancellation,lastFreeDate,lastFreeTime,textLines{cancellationCalculationType,cancellationNights,cancellationPercentage,defaultTextNumber,hasFreeTime,freeTime,cancellationDate}}}}';

    final Uri url = Uri.parse('$_baseUrl/addservices/$_regionCode/$_languageCode/$_dbCode/$spIdentity/services/$serviceId/searchresults/$searchObjectId')
        .replace(queryParameters: {
      'filterId': filterObjectId!,
      'fields': fields,
      'currency': 'EUR',
      'limAddSrvTHEME': '38723CC4-C5F0-4707-9401-5F598D892246',
      'limExAccShSPwoPr': 'false',
    });

    try {
      final response = await http.get(url, headers: _headers);
      // Itt a 'data' kulcsban jön vissza a lista a termékekről (products)
      final data = _handleResponse(response);
      return data;
    } catch (e) {
      print('❌ Hiba az Elérhetőség lekérésekor: $e');
      return null;
    }
  }


  // ====================================================================
  // 6. 🛒 Shopping List (Kosár)
  // ====================================================================

  Future<String?> createShoppingList() async {
    final Uri url = Uri.parse('$_baseUrl/shoppinglist/$_regionCode');
    try {
      final response = await http.post(url, headers: _headers);
      final data = _handleResponse(response);
      shoppingListId = data['id'];
      print('✅ Kosár létrehozva: $shoppingListId');
      return shoppingListId;
    } catch (e) {
      print('❌ Hiba a Kosár létrehozásakor: $e');
      return null;
    }
  }

  Future<dynamic> addProductToShoppingList(String productId, int quantity, String date, String startTime) async {
    if (shoppingListId == null) throw Exception('Kosár ID hiányzik a termék hozzáadásához.');

    final Uri url = Uri.parse('$_baseUrl/shoppinglist/$_regionCode/$shoppingListId/items/add');

    // A foglaláshoz szükséges adatok a Body-ban
    final Map<String, dynamic> body = {
      'addServiceItems': [
        {
          'productId': productId,
          'quantity': quantity,
          'date': date, // Pl: "2025-11-08T00:00:00"
          'startTime': startTime, // Pl: "15:00"
          'duration': null, // Opcionális
          'adults': quantity, // Feltételezve, hogy a quantity a felnőttek száma
          'children': 0,
          'infants': 0,
          'youngsters': 0,
        }
      ],
      'accommodationItems': [],
      'brochureItems': [],
      'packageItems': [],
      'tourItems': [],
    };

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      // Sikeres hozzáadás esetén a Kosár tartalma jön vissza (általában 200/201)
      return _handleResponse(response);
    } catch (e) {
      print('❌ Hiba a termék Kosárhoz adásakor: $e');
      return null;
    }
  }
}