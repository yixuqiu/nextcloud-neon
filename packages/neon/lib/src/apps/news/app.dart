library news;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rx_bloc/flutter_rx_bloc.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:intersperse/intersperse.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:neon/l10n/localizations.dart';
import 'package:neon/src/apps/news/blocs/articles.dart';
import 'package:neon/src/apps/news/blocs/news.dart';
import 'package:neon/src/blocs/accounts.dart';
import 'package:neon/src/blocs/apps.dart';
import 'package:neon/src/models/account.dart';
import 'package:neon/src/neon.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:settings/settings.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sort_box/sort_box.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock/wakelock.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'dialogs/add_feed.dart';
part 'dialogs/create_folder.dart';
part 'dialogs/feed_show_url.dart';
part 'dialogs/feed_update_error.dart';
part 'dialogs/move_feed.dart';
part 'options.dart';
part 'pages/article.dart';
part 'pages/feed.dart';
part 'pages/folder.dart';
part 'pages/main.dart';
part 'sort/articles.dart';
part 'sort/feeds.dart';
part 'sort/folders.dart';
part 'widgets/articles_view.dart';
part 'widgets/feed_icon.dart';
part 'widgets/feeds_view.dart';
part 'widgets/folder_select.dart';
part 'widgets/folder_view.dart';
part 'widgets/folders_view.dart';

class NewsApp extends AppImplementation<NewsBloc, NewsAppSpecificOptions> {
  NewsApp(super.sharedPreferences, super.requestManager, super.platform);

  @override
  String id = 'news';

  @override
  String nameFromLocalization(AppLocalizations localizations) => localizations.newsName;

  @override
  NewsAppSpecificOptions buildOptions(Storage storage) => NewsAppSpecificOptions(storage, platform);

  @override
  NewsBloc buildBloc(NextcloudClient client) => NewsBloc(
        options,
        requestManager,
        client,
      );

  @override
  Widget buildPage(BuildContext context, AppsBloc appsBloc) => NewsMainPage(
        bloc: appsBloc.getAppBloc(this),
      );

  @override
  BehaviorSubject<int>? getUnreadCounter(AppsBloc appsBloc) => appsBloc.getAppBloc<NewsBloc>(this).unreadCounter;
}