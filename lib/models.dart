/// Data models for the bundled/remote content database.
/// Parsing is defensive: missing fields fall back to safe defaults so a
/// slightly-off remote content.json can never crash the app.
library;

String _s(dynamic v) => v is String ? v : '';
int _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);

List<String> _sl(dynamic v) =>
    v is List ? v.map((e) => _s(e)).where((e) => e.isNotEmpty).toList() : [];

class Story {
  final String id, series, theme, reference, tagline, title, summary, url;
  Story.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        series = _s(j['series']),
        theme = _s(j['theme']),
        reference = _s(j['reference']),
        tagline = _s(j['tagline']),
        title = _s(j['title']),
        summary = _s(j['summary']),
        url = _s(j['url']);
}

class Product {
  final String id, emoji, niche, badge, title, price, summary, payhipUrl, shopifyUrl;
  final List<String> features;
  // Present in content.json and used by vault_screen; the model just never
  // read them, so `product.image` and `product.format` did not exist.
  final String image, format;
  // In-app purchase: store product id, and where the buyer's file lives.
  // Both must be non-empty before a buy button appears. See Purchases.sellable.
  final String iapId, fulfillmentUrl;
  Product.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        emoji = _s(j['emoji']),
        niche = _s(j['niche']),
        badge = _s(j['badge']),
        title = _s(j['title']),
        price = _s(j['price']),
        summary = _s(j['summary']),
        features = _sl(j['features']),
        payhipUrl = _s(j['payhip_url']),
        shopifyUrl = _s(j['shopify_url']),
        image = _s(j['image']),
        format = _s(j['format']),
        iapId = _s(j['iap_id']),
        fulfillmentUrl = _s(j['fulfillment_url']);
}

/// One item from the full Shopify/Payhip catalog (115 of them). Deliberately
/// leaner than Product: this is a browse-and-buy row, not a hero card.
class CatalogItem {
  final String id, title, price, format, category, summary;
  final String shopifyUrl, payhipUrl, iapId, fulfillmentUrl;
  final bool bundle;
  CatalogItem.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        title = _s(j['title']),
        price = _s(j['price']),
        format = _s(j['format']),
        category = _s(j['category']),
        summary = _s(j['summary']),
        shopifyUrl = _s(j['shopify_url']),
        payhipUrl = _s(j['payhip_url']),
        iapId = _s(j['iap_id']),
        fulfillmentUrl = _s(j['fulfillment_url']),
        bundle = j['bundle'] == true;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final n = q.toLowerCase();
    return title.toLowerCase().contains(n) ||
        summary.toLowerCase().contains(n) ||
        category.toLowerCase().contains(n);
  }
}

class FreeResource {
  final String id, emoji, title, summary, url;
  FreeResource.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        emoji = _s(j['emoji']),
        title = _s(j['title']),
        summary = _s(j['summary']),
        url = _s(j['url']);
}

class Course {
  final String code, tag, title, summary, url;
  final List<String> skills;
  Course.fromJson(Map<String, dynamic> j)
      : code = _s(j['code']),
        tag = _s(j['tag']),
        title = _s(j['title']),
        summary = _s(j['summary']),
        skills = _sl(j['skills']),
        url = _s(j['url']);
}

class TechSkill {
  final String name, level;
  final int pct;
  TechSkill.fromJson(Map<String, dynamic> j)
      : name = _s(j['name']),
        level = _s(j['level']),
        pct = _i(j['pct']);
}

class Verse {
  final String id, reference, text;
  Verse.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        reference = _s(j['reference']),
        text = _s(j['text']);
  List<String> get words =>
      text.split(' ').where((w) => w.trim().isNotEmpty).toList();
}

class QuizQuestion {
  final String q;
  final List<String> options;
  final int answer;
  final String storyId;
  QuizQuestion.fromJson(Map<String, dynamic> j)
      : q = _s(j['q']),
        options = _sl(j['options']),
        answer = _i(j['answer']),
        storyId = _s(j['story_id']);
  bool get valid => options.isNotEmpty && answer >= 0 && answer < options.length;
}

class AuditQuestion {
  final String q, hint;
  AuditQuestion.fromJson(Map<String, dynamic> j)
      : q = _s(j['q']),
        hint = _s(j['hint']);
}

class ThisWeek {
  final String title, verse, reference, readTime, summary, url;
  ThisWeek.fromJson(Map<String, dynamic> j)
      : title = _s(j['title']),
        verse = _s(j['verse']),
        reference = _s(j['reference']),
        readTime = _s(j['read_time']),
        summary = _s(j['summary']),
        url = _s(j['url']);
}

class WhoAmI {
  final String answer, story, reference;
  final List<String> options, clues;
  WhoAmI.fromJson(Map<String, dynamic> j)
      : answer = _s(j['answer']),
        story = _s(j['story']),
        reference = _s(j['reference']),
        options = [for (final o in (j['options'] as List? ?? [])) o.toString()],
        clues = [for (final o in (j['clues'] as List? ?? [])) o.toString()];
}

class TriviaQ {
  final String q, pid;
  final List<String> options;
  TriviaQ.fromJson(Map<String, dynamic> j)
      : q = _s(j['q']),
        pid = _s(j['pid']),
        options = [for (final o in (j['options'] as List? ?? [])) o.toString()];
}

class BundledFile {
  final String file, emoji, title, format, niche, summary;
  BundledFile.fromJson(Map<String, dynamic> j)
      : file = _s(j['file']),
        emoji = _s(j['emoji']),
        title = _s(j['title']),
        format = _s(j['format']),
        niche = _s(j['niche']),
        summary = _s(j['summary']);
}

class TFItem {
  final String s, why;
  final bool a;
  TFItem.fromJson(Map<String, dynamic> j)
      : s = _s(j['s']),
        why = _s(j['why']),
        a = j['a'] == true;
}

class AppContent {
  final int version;
  final Map<String, String> urls;
  final ThisWeek thisWeek;
  final List<AuditQuestion> audit;
  final List<Story> stories;
  final List<Product> products;

  /// The full catalog — every product live on Shopify and Payhip.
  final List<CatalogItem> catalog;
  final List<FreeResource> freeResources;
  final List<Course> courses;
  final List<TechSkill> techSkills;
  final List<Verse> verses;
  final Map<String, List<QuizQuestion>> quizzes;
  final Map<String, List<TFItem>> tfDecks;
  final List<String> storyOrder;
  final List<WhoAmI> whoAmI;
  final List<TriviaQ> templateTrivia;
  final List<BundledFile> bundledFiles;
  final Map<String, List<String>> gameWords;

  /// Storefronts where linking out of the app to buy is permitted.
  /// Empty means "no restriction configured" — see AppConfig.canLinkOut.
  final List<String> linkOutRegions;

  /// Master switch for in-app purchase, flipped remotely once store products
  /// and fulfilment URLs exist.
  final bool iapEnabled;

  AppContent.fromJson(Map<String, dynamic> j)
      : version = _i(j['version']),
        urls = (j['urls'] is Map)
            ? (j['urls'] as Map)
                .map((k, v) => MapEntry(k.toString(), _s(v)))
            : {},
        thisWeek = ThisWeek.fromJson(
            j['this_week'] is Map ? Map<String, dynamic>.from(j['this_week']) : {}),
        audit = _list(j['stewardship_audit'], AuditQuestion.fromJson),
        stories = _list(j['stories'], Story.fromJson),
        products = _list(j['products'], Product.fromJson),
        catalog = _list(j['catalog'], CatalogItem.fromJson),
        freeResources = _list(j['free_resources'], FreeResource.fromJson),
        courses = _list(j['courses'], Course.fromJson),
        techSkills = _list(j['tech_skills'], TechSkill.fromJson),
        verses = _list(j['verses'], Verse.fromJson),
        quizzes = (j['quizzes'] is Map)
            ? (j['quizzes'] as Map).map((k, v) => MapEntry(
                k.toString(),
                _list(v, QuizQuestion.fromJson)
                    .where((q) => q.valid)
                    .toList()))
            : {},
        // The six fields below were declared but never initialized, which is
        // why the project did not compile. All six keys exist in content.json.
        tfDecks = (j['tf_decks'] is Map)
            ? (j['tf_decks'] as Map).map((k, v) =>
                MapEntry(k.toString(), _list(v, TFItem.fromJson)))
            : {},
        storyOrder = (j['story_order'] is List)
            ? (j['story_order'] as List).map((e) => _s(e)).toList()
            : [],
        whoAmI = _list(j['who_am_i'], WhoAmI.fromJson),
        templateTrivia = _list(j['template_trivia'], TriviaQ.fromJson),
        bundledFiles = _list(j['bundled_files'], BundledFile.fromJson),
        gameWords = (j['game_words'] is Map)
            ? (j['game_words'] as Map).map((k, v) => MapEntry(
                k.toString(),
                (v is List) ? v.map((e) => _s(e)).toList() : <String>[]))
            : {},
        linkOutRegions = (j['commerce'] is Map &&
                (j['commerce'] as Map)['link_out_regions'] is List)
            ? ((j['commerce'] as Map)['link_out_regions'] as List)
                .map((e) => _s(e).toUpperCase())
                .toList()
            : const [],
        iapEnabled = (j['commerce'] is Map) &&
            (j['commerce'] as Map)['iap_enabled'] == true;

  String url(String key) => urls[key] ?? 'https://analyticsbyshanikwa.com';
}

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) => v is List
    ? v
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList()
    : <T>[];
