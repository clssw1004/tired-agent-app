import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A pickable icon entry: a searchable [name] plus the [icon] to render.
class KeyIconEntry {
  /// Lowercase name used for search (e.g. `'play'`, `'code-branch'`).
  final String name;

  /// The icon glyph — renderable via `Icon(entry.icon)`.
  final IconData icon;

  const KeyIconEntry(this.name, this.icon);
}

/// Curated icon catalog for the key-icon picker.
///
/// Two families, matching the picker's two tabs:
/// - [material] — a hand-picked subset of Material Icons most useful on a
///   terminal-style keyboard.
/// - [fontAwesome] — a hand-picked subset of Font Awesome that includes every
///   icon used by the builtin presets (`play` / `broom` / `compress` /
///   `codeBranch`, see `pty_keyboard_presets/shell.dart`) so preset buttons
///   can be recreated in the editor.
abstract final class KeyIconCatalog {
  /// Hand-picked Material icons, in display order.
  static const material = <KeyIconEntry>[
    // Transport / play
    KeyIconEntry('play', Icons.play_arrow),
    KeyIconEntry('pause', Icons.pause),
    KeyIconEntry('stop', Icons.stop),
    KeyIconEntry('replay', Icons.replay),
    KeyIconEntry('skip-previous', Icons.skip_previous),
    KeyIconEntry('skip-next', Icons.skip_next),
    KeyIconEntry('fast-rewind', Icons.fast_rewind),
    KeyIconEntry('fast-forward', Icons.fast_forward),
    KeyIconEntry('play-circle', Icons.play_circle),
    KeyIconEntry('stop-circle', Icons.stop_circle),
    KeyIconEntry('pause-circle', Icons.pause_circle),

    // Refresh / restart
    KeyIconEntry('refresh', Icons.refresh),
    KeyIconEntry('sync', Icons.sync),
    KeyIconEntry('restart-alt', Icons.restart_alt),
    KeyIconEntry('bolt', Icons.bolt),
    KeyIconEntry('electric-bolt', Icons.electric_bolt),
    KeyIconEntry('power-settings', Icons.power_settings_new),
    KeyIconEntry('flash-on', Icons.flash_on),
    KeyIconEntry('flash-off', Icons.flash_off),

    // Edit / clipboard
    KeyIconEntry('edit', Icons.edit),
    KeyIconEntry('copy', Icons.content_copy),
    KeyIconEntry('cut', Icons.content_cut),
    KeyIconEntry('paste', Icons.content_paste),
    KeyIconEntry('delete', Icons.delete),
    KeyIconEntry('delete-outline', Icons.delete_outline),
    KeyIconEntry('clear', Icons.clear),
    KeyIconEntry('check', Icons.check),
    KeyIconEntry('done-all', Icons.done_all),
    KeyIconEntry('add', Icons.add),
    KeyIconEntry('remove', Icons.remove),
    KeyIconEntry('save', Icons.save),
    KeyIconEntry('save-alt', Icons.save_alt),
    KeyIconEntry('undo', Icons.undo),
    KeyIconEntry('redo', Icons.redo),

    // File / folder
    KeyIconEntry('folder', Icons.folder),
    KeyIconEntry('folder-open', Icons.folder_open),
    KeyIconEntry('file', Icons.insert_drive_file),
    KeyIconEntry('description', Icons.description),
    KeyIconEntry('terminal', Icons.terminal),
    KeyIconEntry('code', Icons.code),
    KeyIconEntry('data-object', Icons.data_object),
    KeyIconEntry('functions', Icons.functions),
    KeyIconEntry('calculate', Icons.calculate),

    // Shell / system
    KeyIconEntry('search', Icons.search),
    KeyIconEntry('settings', Icons.settings),
    KeyIconEntry('tune', Icons.tune),
    KeyIconEntry('bug-report', Icons.bug_report),
    KeyIconEntry('rocket-launch', Icons.rocket_launch),
    KeyIconEntry('cloud', Icons.cloud),
    KeyIconEntry('cloud-download', Icons.cloud_download),
    KeyIconEntry('cloud-upload', Icons.cloud_upload),
    KeyIconEntry('download', Icons.file_download),
    KeyIconEntry('upload', Icons.file_upload),
    KeyIconEntry('send', Icons.send),
    KeyIconEntry('home', Icons.home),
    KeyIconEntry('key', Icons.key),
    KeyIconEntry('lock', Icons.lock),
    KeyIconEntry('lock-open', Icons.lock_open),
    KeyIconEntry('fingerprint', Icons.fingerprint),
    KeyIconEntry('dns', Icons.dns),
    KeyIconEntry('storage', Icons.storage),
    KeyIconEntry('lan', Icons.lan),
    KeyIconEntry('hub', Icons.hub),
    KeyIconEntry('wifi', Icons.wifi),
    KeyIconEntry('public', Icons.public),
    KeyIconEntry('link', Icons.link),
    KeyIconEntry('history', Icons.history),
    KeyIconEntry('schedule', Icons.schedule),
    KeyIconEntry('timer', Icons.timer),
    KeyIconEntry('alarm', Icons.alarm),

    // Navigation
    KeyIconEntry('arrow-up', Icons.arrow_upward),
    KeyIconEntry('arrow-down', Icons.arrow_downward),
    KeyIconEntry('arrow-left', Icons.arrow_back),
    KeyIconEntry('arrow-right', Icons.arrow_forward),
    KeyIconEntry('north', Icons.north),
    KeyIconEntry('south', Icons.south),
    KeyIconEntry('west', Icons.west),
    KeyIconEntry('east', Icons.east),
    KeyIconEntry('chevron-left', Icons.chevron_left),
    KeyIconEntry('chevron-right', Icons.chevron_right),
    KeyIconEntry('keyboard-arrow-up', Icons.keyboard_arrow_up),
    KeyIconEntry('keyboard-arrow-down', Icons.keyboard_arrow_down),
    KeyIconEntry('keyboard-arrow-left', Icons.keyboard_arrow_left),
    KeyIconEntry('keyboard-arrow-right', Icons.keyboard_arrow_right),
    KeyIconEntry('first-page', Icons.first_page),
    KeyIconEntry('last-page', Icons.last_page),
    KeyIconEntry('navigate-before', Icons.navigate_before),
    KeyIconEntry('navigate-next', Icons.navigate_next),
    KeyIconEntry('exit-to-app', Icons.exit_to_app),
    KeyIconEntry('open-in-new', Icons.open_in_new),
    KeyIconEntry('swap-horiz', Icons.swap_horiz),
    KeyIconEntry('swap-vert', Icons.swap_vert),
    KeyIconEntry('trending-up', Icons.trending_up),
    KeyIconEntry('trending-down', Icons.trending_down),

    // Status / favorite
    KeyIconEntry('star', Icons.star),
    KeyIconEntry('star-border', Icons.star_border),
    KeyIconEntry('favorite', Icons.favorite),
    KeyIconEntry('favorite-border', Icons.favorite_border),
    KeyIconEntry('flag', Icons.flag),
    KeyIconEntry('notifications', Icons.notifications),
    KeyIconEntry('bookmark', Icons.bookmark),
    KeyIconEntry('bookmark-border', Icons.bookmark_border),
    KeyIconEntry('label', Icons.label),
    KeyIconEntry('local-offer', Icons.local_offer),
    KeyIconEntry('qr-code', Icons.qr_code),
    KeyIconEntry('tag', Icons.tag),

    // Layout / more
    KeyIconEntry('menu', Icons.menu),
    KeyIconEntry('list', Icons.list),
    KeyIconEntry('view-list', Icons.view_list),
    KeyIconEntry('view-module', Icons.view_module),
    KeyIconEntry('view-column', Icons.view_column),
    KeyIconEntry('grid-view', Icons.grid_view),
    KeyIconEntry('apps', Icons.apps),
    KeyIconEntry('widgets', Icons.widgets),
    KeyIconEntry('dashboard', Icons.dashboard),
    KeyIconEntry('category', Icons.category),
    KeyIconEntry('extension', Icons.extension),
    KeyIconEntry('more-horiz', Icons.more_horiz),
    KeyIconEntry('more-vert', Icons.more_vert),
    KeyIconEntry('drag-handle', Icons.drag_handle),
    KeyIconEntry('expand-more', Icons.expand_more),
    KeyIconEntry('expand-less', Icons.expand_less),
    KeyIconEntry('fullscreen', Icons.fullscreen),
    KeyIconEntry('share', Icons.share),
    KeyIconEntry('account-tree', Icons.account_tree),
    KeyIconEntry('filter-alt', Icons.filter_alt),
    KeyIconEntry('filter-list', Icons.filter_list),

    // Communication / media
    KeyIconEntry('question-answer', Icons.question_answer),
    KeyIconEntry('forum', Icons.forum),
    KeyIconEntry('email', Icons.email),
    KeyIconEntry('call', Icons.call),
    KeyIconEntry('mic', Icons.mic),
    KeyIconEntry('volume-up', Icons.volume_up),
    KeyIconEntry('volume-off', Icons.volume_off),
    KeyIconEntry('headphones', Icons.headphones),
    KeyIconEntry('gamepad', Icons.gamepad),
    KeyIconEntry('sports-esports', Icons.sports_esports),
    KeyIconEntry('music-note', Icons.music_note),
    KeyIconEntry('image', Icons.image),
    KeyIconEntry('photo-camera', Icons.photo_camera),
    KeyIconEntry('videocam', Icons.videocam),
    KeyIconEntry('visibility', Icons.visibility),
    KeyIconEntry('light-mode', Icons.light_mode),
    KeyIconEntry('dark-mode', Icons.dark_mode),
    KeyIconEntry('lightbulb', Icons.lightbulb),
    KeyIconEntry('keyboard', Icons.keyboard),
    KeyIconEntry('keyboard-alt', Icons.keyboard_alt),
  ];

  /// Hand-picked Font Awesome icons, in display order.
  ///
  /// Not `const` because `FontAwesomeIcons.x.data` returns a fresh
  /// `IconData` each access. Includes every icon used by the builtin presets.
  static final fontAwesome = <KeyIconEntry>[
    // Icons used by the builtin presets (shell.dart) — keep in sync.
    KeyIconEntry('play', FontAwesomeIcons.play.data),
    KeyIconEntry('broom', FontAwesomeIcons.broom.data),
    KeyIconEntry('compress', FontAwesomeIcons.compress.data),
    KeyIconEntry('code-branch', FontAwesomeIcons.codeBranch.data),

    // Transport
    KeyIconEntry('stop', FontAwesomeIcons.stop.data),
    KeyIconEntry('pause', FontAwesomeIcons.pause.data),
    KeyIconEntry('forward', FontAwesomeIcons.forward.data),
    KeyIconEntry('backward', FontAwesomeIcons.backward.data),
    KeyIconEntry('fast-forward', FontAwesomeIcons.forwardFast.data),
    KeyIconEntry('fast-backward', FontAwesomeIcons.backwardFast.data),
    KeyIconEntry('shuffle', FontAwesomeIcons.shuffle.data),
    KeyIconEntry('repeat', FontAwesomeIcons.repeat.data),

    // Refresh / power
    KeyIconEntry('rotate-left', FontAwesomeIcons.rotateLeft.data),
    KeyIconEntry('rotate-right', FontAwesomeIcons.rotateRight.data),
    KeyIconEntry('refresh', FontAwesomeIcons.arrowsRotate.data),
    KeyIconEntry('power-off', FontAwesomeIcons.powerOff.data),
    KeyIconEntry('bolt', FontAwesomeIcons.bolt.data),

    // Edit / clipboard
    KeyIconEntry('eraser', FontAwesomeIcons.eraser.data),
    KeyIconEntry('trash', FontAwesomeIcons.trash.data),
    KeyIconEntry('trash-can', FontAwesomeIcons.trashCan.data),
    KeyIconEntry('copy', FontAwesomeIcons.copy.data),
    KeyIconEntry('scissors', FontAwesomeIcons.scissors.data),
    KeyIconEntry('paste', FontAwesomeIcons.paste.data),
    KeyIconEntry('save', FontAwesomeIcons.floppyDisk.data),
    KeyIconEntry('clipboard', FontAwesomeIcons.clipboard.data),
    KeyIconEntry('xmark', FontAwesomeIcons.xmark.data),
    KeyIconEntry('check', FontAwesomeIcons.check.data),
    KeyIconEntry('plus', FontAwesomeIcons.plus.data),
    KeyIconEntry('minus', FontAwesomeIcons.minus.data),

    // File / folder
    KeyIconEntry('folder', FontAwesomeIcons.folder.data),
    KeyIconEntry('folder-open', FontAwesomeIcons.folderOpen.data),
    KeyIconEntry('file', FontAwesomeIcons.file.data),
    KeyIconEntry('file-lines', FontAwesomeIcons.fileLines.data),
    KeyIconEntry('file-code', FontAwesomeIcons.fileCode.data),
    KeyIconEntry('terminal', FontAwesomeIcons.terminal.data),
    KeyIconEntry('code', FontAwesomeIcons.code.data),
    KeyIconEntry('code-fork', FontAwesomeIcons.codeFork.data),
    KeyIconEntry('bug', FontAwesomeIcons.bug.data),
    KeyIconEntry('rocket', FontAwesomeIcons.rocket.data),

    // Cloud / network
    KeyIconEntry('cloud', FontAwesomeIcons.cloud.data),
    KeyIconEntry('cloud-arrow-down', FontAwesomeIcons.cloudArrowDown.data),
    KeyIconEntry('cloud-arrow-up', FontAwesomeIcons.cloudArrowUp.data),
    KeyIconEntry('download', FontAwesomeIcons.download.data),
    KeyIconEntry('upload', FontAwesomeIcons.upload.data),
    KeyIconEntry('server', FontAwesomeIcons.server.data),
    KeyIconEntry('database', FontAwesomeIcons.database.data),
    KeyIconEntry('plug', FontAwesomeIcons.plug.data),
    KeyIconEntry('wifi', FontAwesomeIcons.wifi.data),
    KeyIconEntry('globe', FontAwesomeIcons.globe.data),
    KeyIconEntry('link', FontAwesomeIcons.link.data),
    KeyIconEntry('paper-plane', FontAwesomeIcons.paperPlane.data),
    KeyIconEntry('magnifying-glass', FontAwesomeIcons.magnifyingGlass.data),
    KeyIconEntry('gear', FontAwesomeIcons.gear.data),
    KeyIconEntry('sliders', FontAwesomeIcons.sliders.data),

    // Navigation
    KeyIconEntry('arrow-up', FontAwesomeIcons.arrowUp.data),
    KeyIconEntry('arrow-down', FontAwesomeIcons.arrowDown.data),
    KeyIconEntry('arrow-left', FontAwesomeIcons.arrowLeft.data),
    KeyIconEntry('arrow-right', FontAwesomeIcons.arrowRight.data),
    KeyIconEntry('caret-up', FontAwesomeIcons.caretUp.data),
    KeyIconEntry('caret-down', FontAwesomeIcons.caretDown.data),
    KeyIconEntry('caret-left', FontAwesomeIcons.caretLeft.data),
    KeyIconEntry('caret-right', FontAwesomeIcons.caretRight.data),
    KeyIconEntry('chevron-up', FontAwesomeIcons.chevronUp.data),
    KeyIconEntry('chevron-down', FontAwesomeIcons.chevronDown.data),
    KeyIconEntry('chevron-left', FontAwesomeIcons.chevronLeft.data),
    KeyIconEntry('chevron-right', FontAwesomeIcons.chevronRight.data),

    // Status / brand
    KeyIconEntry('star', FontAwesomeIcons.star.data),
    KeyIconEntry('heart', FontAwesomeIcons.heart.data),
    KeyIconEntry('flag', FontAwesomeIcons.flag.data),
    KeyIconEntry('bell', FontAwesomeIcons.bell.data),
    KeyIconEntry('square', FontAwesomeIcons.square.data),
    KeyIconEntry('circle', FontAwesomeIcons.circle.data),
    KeyIconEntry('square-check', FontAwesomeIcons.squareCheck.data),
    KeyIconEntry('comment', FontAwesomeIcons.comment.data),
    KeyIconEntry('message', FontAwesomeIcons.message.data),
    KeyIconEntry('robot', FontAwesomeIcons.robot.data),
    KeyIconEntry('user', FontAwesomeIcons.user.data),
    KeyIconEntry('key', FontAwesomeIcons.key.data),
    KeyIconEntry('lock', FontAwesomeIcons.lock.data),
    KeyIconEntry('unlock', FontAwesomeIcons.unlock.data),
    KeyIconEntry('house', FontAwesomeIcons.house.data),
    KeyIconEntry('lightbulb', FontAwesomeIcons.lightbulb.data),
    KeyIconEntry('music', FontAwesomeIcons.music.data),
    KeyIconEntry('image', FontAwesomeIcons.image.data),
    KeyIconEntry('camera', FontAwesomeIcons.camera.data),
    KeyIconEntry('video', FontAwesomeIcons.video.data),
    KeyIconEntry('eye', FontAwesomeIcons.eye.data),
    KeyIconEntry('sun', FontAwesomeIcons.sun.data),
    KeyIconEntry('moon', FontAwesomeIcons.moon.data),
    KeyIconEntry('fire', FontAwesomeIcons.fire.data),
    KeyIconEntry('water', FontAwesomeIcons.water.data),
    KeyIconEntry('wind', FontAwesomeIcons.wind.data),
    KeyIconEntry('cube', FontAwesomeIcons.cube.data),
    KeyIconEntry('infinity', FontAwesomeIcons.infinity.data),
    KeyIconEntry('at', FontAwesomeIcons.at.data),
    KeyIconEntry('hashtag', FontAwesomeIcons.hashtag.data),
    KeyIconEntry('dollar-sign', FontAwesomeIcons.dollarSign.data),
    KeyIconEntry('percent', FontAwesomeIcons.percent.data),
    KeyIconEntry('asterisk', FontAwesomeIcons.asterisk.data),
    KeyIconEntry('github', FontAwesomeIcons.github.data),
    KeyIconEntry('git', FontAwesomeIcons.git.data),
    KeyIconEntry('git-alt', FontAwesomeIcons.gitAlt.data),
  ];
}
