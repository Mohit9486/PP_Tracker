import 'package:flutter/material.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';

/// Resolves the serializable category fields ([BlogCategory.iconKey] and
/// [BlogCategory.colorValue]) into Flutter visuals. Kept out of the model so
/// the data layer stays Flutter-free and backend-friendly.
extension BlogCategoryStyle on BlogCategory {
  Color get color => Color(colorValue);

  IconData get icon => switch (iconKey) {
        'cycle' => Icons.autorenew_rounded,
        'hormones' => Icons.science_rounded,
        'nutrition' => Icons.restaurant_rounded,
        'mind' => Icons.self_improvement_rounded,
        'fitness' => Icons.fitness_center_rounded,
        'pcos' => Icons.favorite_rounded,
        'sleep' => Icons.bedtime_rounded,
        'fertility' => Icons.spa_rounded,
        'grid' => Icons.grid_view_rounded,
        _ => Icons.article_rounded,
      };
}
