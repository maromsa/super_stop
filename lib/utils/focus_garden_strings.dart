import '../l10n/app_localizations.dart';
import '../providers/focus_garden_provider.dart';

class FocusGardenStrings {
  static String stageName(AppLocalizations l10n, FocusGardenStageId id) {
    switch (id) {
      case FocusGardenStageId.seed:
        return l10n.focusGardenStageSeed;
      case FocusGardenStageId.sprout:
        return l10n.focusGardenStageSprout;
      case FocusGardenStageId.bloom:
        return l10n.focusGardenStageBloom;
      case FocusGardenStageId.tree:
        return l10n.focusGardenStageTree;
      case FocusGardenStageId.nova:
        return l10n.focusGardenStageNova;
    }
  }

  static String stageDescription(AppLocalizations l10n, FocusGardenStageId id) {
    switch (id) {
      case FocusGardenStageId.seed:
        return l10n.focusGardenStageSeedDescription;
      case FocusGardenStageId.sprout:
        return l10n.focusGardenStageSproutDescription;
      case FocusGardenStageId.bloom:
        return l10n.focusGardenStageBloomDescription;
      case FocusGardenStageId.tree:
        return l10n.focusGardenStageTreeDescription;
      case FocusGardenStageId.nova:
        return l10n.focusGardenStageNovaDescription;
    }
  }
}

