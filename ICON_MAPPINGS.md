# Cupertino → Material Icons Mapping

## Why Material Icons?
Cupertino icons have rendering issues on macOS desktop and sometimes iOS. Material Icons always work and still look great with Cupertino design.

## Icon Mappings Used

| CupertinoIcons | Material Icons | Usage |
|----------------|----------------|-------|
| `CupertinoIcons.back` | `Icons.arrow_back_ios` | Back button |
| `CupertinoIcons.house` | `Icons.home_outlined` | Home tab |
| `CupertinoIcons.house_fill` | `Icons.home` | Active home |
| `CupertinoIcons.gift` | `Icons.card_giftcard_outlined` | Rewards tab |
| `CupertinoIcons.gift_fill` | `Icons.card_giftcard` | Active rewards |
| `CupertinoIcons.book` | `Icons.school_outlined` | Learn tab |
| `CupertinoIcons.book_fill` | `Icons.school` | Active learn |
| `CupertinoIcons.textformat` | `Icons.translate` | Language |
| `CupertinoIcons.checkmark_circle_fill` | `Icons.check_circle` | Success |
| `CupertinoIcons.chevron_up_chevron_down` | `Icons.unfold_more` | Picker |
| `CupertinoIcons.doc_text` | `Icons.description` | Document |
| `CupertinoIcons.doc_on_clipboard` | `Icons.content_copy` | Copy |
| `CupertinoIcons.lightbulb` | `Icons.lightbulb_outline` | Idea |
| `CupertinoIcons.clock` | `Icons.history` | History |
| `CupertinoIcons.bookmark` | `Icons.bookmark` | Bookmark |
| `CupertinoIcons.delete` | `Icons.delete_outline` | Delete |
| `CupertinoIcons.chevron_up` | `Icons.expand_less` | Expand up |
| `CupertinoIcons.chevron_down` | `Icons.expand_more` | Expand down |
| `CupertinoIcons.star_fill` | `Icons.star` | Star |
| `CupertinoIcons.paintbrush_fill` | `Icons.palette` | Palette |
| `CupertinoIcons.mail` | `Icons.email` | Email |
| `CupertinoIcons.lock` | `Icons.lock` | Lock |
| `CupertinoIcons.eye` | `Icons.visibility` | Show password |
| `CupertinoIcons.eye_slash` | `Icons.visibility_off` | Hide password |
| `CupertinoIcons.person_circle` | `Icons.account_circle` | Profile |
| `CupertinoIcons.flame_fill` | `Icons.local_fire_department` | Streak |
| `CupertinoIcons.globe` | `Icons.language` | Language |
| `CupertinoIcons.square_arrow_right` | `Icons.logout` | Sign out |
| `CupertinoIcons.person` | `Icons.person` | Person |
| `CupertinoIcons.bell` | `Icons.notifications` | Notifications |
| `CupertinoIcons.moon` | `Icons.dark_mode` | Dark mode |
| `CupertinoIcons.arrow_down_doc` | `Icons.download` | Download |
| `CupertinoIcons.trash` | `Icons.delete` | Trash |
| `CupertinoIcons.info` | `Icons.info` | Info |
| `CupertinoIcons.shield` | `Icons.privacy_tip` | Privacy |
| `CupertinoIcons.question_circle` | `Icons.help_outline` | Help |
| `CupertinoIcons.exclamationmark_triangle` | `Icons.warning` | Warning |
| `CupertinoIcons.ellipsis_circle` | `Icons.more_horiz` | More menu |
| `CupertinoIcons.chevron_forward` | `Icons.chevron_right` | Forward |

## Implementation

Add this import to every file using icons:
```dart
import 'package:flutter/material.dart' show Icons;
```

This gives you Material Icons while keeping Cupertino components!

