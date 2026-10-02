import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../core/constants/app_theme.dart';

/// Explicit tag styling for rendered article HTML (`News.contenu`, produced
/// by the old site's WYSIWYG editor). flutter_html doesn't reliably inherit
/// the app's [AppTheme] text colors/weights for headings on its own — left
/// unstyled, `<h1>` rendered at the same muted, low-contrast color as body
/// text. Shared between the feed preview and the full article screen so
/// both read consistently.
final Map<String, Style> newsHtmlStyle = {
  'body': Style(
    color: AppColors.textPrimary,
    fontSize: FontSize(15),
    lineHeight: LineHeight.number(1.5),
    margin: Margins.zero,
  ),
  'h1': Style(
    color: AppColors.textPrimary,
    fontSize: FontSize(22),
    fontWeight: FontWeight.w800,
    margin: Margins.only(bottom: 8),
  ),
  'h2': Style(
    color: AppColors.textPrimary,
    fontSize: FontSize(19),
    fontWeight: FontWeight.w700,
    margin: Margins.only(bottom: 6),
  ),
  'h3': Style(
    color: AppColors.textPrimary,
    fontSize: FontSize(17),
    fontWeight: FontWeight.w700,
    margin: Margins.only(bottom: 6),
  ),
  'p': Style(margin: Margins.only(bottom: 8)),
  'strong': Style(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
  'a': Style(color: AppColors.primary, textDecoration: TextDecoration.underline),
};
