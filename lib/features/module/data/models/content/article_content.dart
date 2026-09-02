import 'package:flutter/foundation.dart';

enum ArticleBlockType {
  paragraph,
  image,
  listItem,
  reference,
  unknown;

  static ArticleBlockType fromJson(Object? value) {
    return switch (value) {
      'paragraph' => ArticleBlockType.paragraph,
      'image' => ArticleBlockType.image,
      'list_item' => ArticleBlockType.listItem,
      'reference' => ArticleBlockType.reference,
      _ => ArticleBlockType.unknown,
    };
  }
}

@immutable
class ArticleBlock {
  const ArticleBlock({
    required this.id,
    required this.blockType,
    required this.text,
    required this.imageUrl,
    required this.altText,
    required this.order,
  });

  final String id;
  final ArticleBlockType blockType;
  final String? text;
  final String? imageUrl;
  final String? altText;
  final int order;

  factory ArticleBlock.fromJson(Map<String, dynamic> json) {
    return ArticleBlock(
      id: json['id'] as String,
      blockType: ArticleBlockType.fromJson(json['block_type']),
      text: json['text_article'] as String?,
      imageUrl: json['image_url'] as String?,
      altText: json['alt_text'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ArticleContent {
  const ArticleContent({
    required this.id,
    required this.title,
    required this.blocks,
  });

  final String id;
  final String title;
  final List<ArticleBlock> blocks;

  factory ArticleContent.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];
    return ArticleContent(
      id: json['id'] as String,
      title: json['title'] as String,
      blocks: rawBlocks is List
          ? rawBlocks
                .cast<Map<String, dynamic>>()
                .map(ArticleBlock.fromJson)
                .toList()
          : const [],
    );
  }
}
