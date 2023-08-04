import 'dart:async';

import 'package:meta/meta.dart';
import 'package:neon/src/bloc/bloc.dart';
import 'package:neon/src/bloc/result.dart';
import 'package:neon/src/models/account.dart';
import 'package:neon/src/utils/request_manager.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:rxdart/rxdart.dart';

typedef Capabilities = CoreServerCapabilities_Ocs_Data;
typedef NextcloudTheme = CoreServerCapabilities_Ocs_Data_Capabilities_Theming;

abstract class CapabilitiesBlocEvents {}

abstract class CapabilitiesBlocStates {
  BehaviorSubject<Result<Capabilities>> get capabilities;
}

@internal
class CapabilitiesBloc extends InteractiveBloc implements CapabilitiesBlocEvents, CapabilitiesBlocStates {
  CapabilitiesBloc(
    this._requestManager,
    this._account,
  ) {
    unawaited(refresh());
  }

  final RequestManager _requestManager;
  final Account _account;

  @override
  void dispose() {
    unawaited(capabilities.close());
    super.dispose();
  }

  @override
  BehaviorSubject<Result<Capabilities>> capabilities = BehaviorSubject<Result<Capabilities>>();

  @override
  Future refresh() async {
    await _requestManager.wrapNextcloud<CoreServerCapabilities_Ocs_Data, CoreServerCapabilities>(
      _account.id,
      'capabilities',
      capabilities,
      () async => _account.client.core.getCapabilities(),
      (final response) => response.ocs.data,
    );
  }
}
