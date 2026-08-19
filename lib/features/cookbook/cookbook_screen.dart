import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/auth_service.dart';
import '../auth/auth_screen.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_results_screen.dart';

class CookbookScreen extends StatefulWidget {
const CookbookScreen({super.key});

@override
State<CookbookScreen> createState() =>
_CookbookScreenState();
}

class _CookbookScreenState
extends State<CookbookScreen> {
final TextEditingController _searchController =
TextEditingController();

String _query = '';

@override
void initState() {
super.initState();

_searchController.addListener(
_handleSearch,
);
}

void _handleSearch() {
if (!mounted) return;

setState(() {
_query = _searchController.text
    .trim()
    .toLowerCase();
});
}

@override
void dispose() {
_searchController.removeListener(
_handleSearch,
);
_searchController.dispose();
super.dispose();
}

// ===========================================================================
// SIGN IN
// ===========================================================================

Future<void> _signIn() async {
final result =
await Navigator.push<bool>(
context,
MaterialPageRoute(
builder: (_) => const AuthScreen(),
),
);

if (!mounted) return;

if (result == true) {
setState(() {});
}
}

// ===========================================================================
// RECIPE CONVERTER
// ===========================================================================

Recipe _recipeFromDocument(
DocumentSnapshot<Map<String, dynamic>>
document,
) {
final data =
document.data() ?? {};

return Recipe.fromJson({
...data,
'imageUrl':
data['imageUrl']?.toString() ?? '',
});
}

// ===========================================================================
// OPEN RECIPE
// ===========================================================================

Future<void> _openRecipe(
DocumentSnapshot<Map<String, dynamic>>
document,
) async {
try {
HapticFeedback.selectionClick();

await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
RecipeDetailScreen(
recipe:
_recipeFromDocument(
document,
),
isUnlocked: true,
),
),
);
} catch (error) {
debugPrint(
'Cookbook recipe open error: $error',
);

if (!mounted) return;

_showMessage(
'Could not open this recipe.',
);
}
}

// ===========================================================================
// DELETE
// ===========================================================================

Future<void> _deleteRecipe(
DocumentSnapshot<Map<String, dynamic>>
document,
) async {
final data =
document.data() ?? {};

final rawName =
data['name']?.toString().trim();

final recipeName =
rawName == null ||
rawName.isEmpty
? 'this recipe'
    : rawName;

final confirmed =
await showModalBottomSheet<bool>(
context: context,
backgroundColor:
Colors.transparent,
isScrollControlled: true,
builder: (sheetContext) {
final colors =
Theme.of(sheetContext)
    .colorScheme;

return Container(
padding:
const EdgeInsets.fromLTRB(
22,
10,
22,
26,
),
decoration:
BoxDecoration(
color: colors.surface,
borderRadius:
const BorderRadius.vertical(
top: Radius.circular(30),
),
),
child: SafeArea(
top: false,
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
Container(
width: 42,
height: 4,
decoration:
BoxDecoration(
color: colors
    .onSurface
    .withValues(
alpha: 0.12,
),
borderRadius:
BorderRadius.circular(
99,
),
),
),

const SizedBox(
height: 24,
),

Container(
width: 64,
height: 64,
decoration:
BoxDecoration(
color: const Color(
0xFFB3261E,
).withValues(
alpha: 0.09,
),
shape:
BoxShape.circle,
),
child: const Icon(
Icons
    .delete_outline_rounded,
color: Color(
0xFFB3261E,
),
size: 30,
),
),

const SizedBox(
height: 16,
),

const Text(
'Remove recipe?',
style: TextStyle(
fontSize: 20,
fontWeight:
FontWeight.w900,
),
),

const SizedBox(
height: 7,
),

Text(
'Remove "$recipeName" '
'from your cookbook?',
textAlign:
TextAlign.center,
style: TextStyle(
color: colors
    .onSurfaceVariant,
fontSize: 12,
height: 1.45,
),
),

const SizedBox(
height: 22,
),

Row(
children: [
Expanded(
child:
OutlinedButton(
onPressed: () {
Navigator.pop(
sheetContext,
false,
);
},
style:
OutlinedButton
    .styleFrom(
minimumSize:
const Size(
0,
52,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
16,
),
),
),
child:
const Text(
'Cancel',
style: TextStyle(
fontWeight:
FontWeight
    .w800,
),
),
),
),

const SizedBox(
width: 12,
),

Expanded(
child:
FilledButton(
onPressed: () {
Navigator.pop(
sheetContext,
true,
);
},
style:
FilledButton
    .styleFrom(
backgroundColor:
const Color(
0xFFB3261E,
),
minimumSize:
const Size(
0,
52,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
16,
),
),
),
child:
const Text(
'Remove',
style: TextStyle(
fontWeight:
FontWeight
    .w900,
),
),
),
),
],
),
],
),
),
);
},
);

if (confirmed != true) {
return;
}

final user = FirebaseAuth.instance.currentUser;

if (user == null) {
_showMessage(
'Your sign-in session has expired. Please sign in again.',
);
return;
}

try {
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('savedRecipes')
    .doc(document.id)
    .delete();

if (!mounted) return;

HapticFeedback.mediumImpact();

_showMessage(
'Recipe removed from your cookbook.',
);
} on FirebaseException catch (
error) {
debugPrint(
'Delete recipe Firebase error: '
'${error.code} - ${error.message}',
);

if (!mounted) return;

if (error.code ==
'permission-denied') {
_showMessage(
'You do not have permission '
'to remove this recipe.',
);
} else {
_showMessage(
'Could not remove the recipe.',
);
}
} catch (error) {
debugPrint(
'Delete recipe error: $error',
);

if (!mounted) return;

_showMessage(
'Could not remove the recipe.',
);
}
}

// ===========================================================================
// MESSAGE
// ===========================================================================

void _showMessage(
String message,
) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior:
SnackBarBehavior.floating,
margin:
const EdgeInsets.fromLTRB(
16,
0,
16,
16,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
14,
),
),
),
);
}

// ===========================================================================
// BUILD
// ===========================================================================

@override
Widget build(
BuildContext context,
) {
final theme = Theme.of(context);

// Firebase restores a persisted Google session asynchronously.
// Listening to authStateChanges() prevents the cookbook from briefly
// showing the login screen while currentUser is still being restored.
return StreamBuilder<User?>(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const _AuthRestoringCookbook();
}

final user = snapshot.data;

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,
body: user == null
? _SignedOutCookbook(
onSignIn: _signIn,
)
    : _SignedInCookbook(
user: user,
searchController: _searchController,
query: _query,
onOpenRecipe: _openRecipe,
onDeleteRecipe: _deleteRecipe,
),
);
},
);
}
}

// =============================================================================
// SIGNED OUT
// =============================================================================

class _AuthRestoringCookbook extends StatelessWidget {
const _AuthRestoringCookbook();

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

return Scaffold(
backgroundColor: Theme.of(context).scaffoldBackgroundColor,
body: SafeArea(
child: Center(
child: Padding(
padding: const EdgeInsets.all(28),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 78,
height: 78,
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
colors.primary.withValues(alpha: 0.16),
colors.primary.withValues(alpha: 0.045),
],
),
shape: BoxShape.circle,
border: Border.all(
color: colors.primary.withValues(alpha: 0.10),
),
),
child: Padding(
padding: const EdgeInsets.all(22),
child: CircularProgressIndicator(
strokeWidth: 2.5,
color: colors.primary,
),
),
),
const SizedBox(height: 18),
const Text(
'Opening your cookbook',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w900,
letterSpacing: -0.3,
),
),
const SizedBox(height: 6),
Text(
'Restoring your account...',
textAlign: TextAlign.center,
style: TextStyle(
color: colors.onSurfaceVariant,
fontSize: 11.5,
fontWeight: FontWeight.w600,
),
),
],
),
),
),
),
);
}
}

// =============================================================================
// SIGNED OUT
// =============================================================================

class _SignedOutCookbook
extends StatelessWidget {
final VoidCallback onSignIn;

const _SignedOutCookbook({
required this.onSignIn,
});

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

return SafeArea(
child: Center(
child:
SingleChildScrollView(
padding:
const EdgeInsets.all(
20,
),
child: Column(
children: [
const SizedBox(
height: 20,
),

// ---------------------------------------------------------------
// HEADER
// ---------------------------------------------------------------

Align(
alignment:
Alignment.centerLeft,
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
'MY COOKBOOK',
style:
TextStyle(
color:
colors.primary,
fontSize: 10,
fontWeight:
FontWeight
    .w900,
letterSpacing:
1.6,
),
),

const SizedBox(
height: 5,
),

const Text(
'Your saved recipes',
style: TextStyle(
fontSize: 28,
fontWeight:
FontWeight
    .w900,
letterSpacing:
-0.8,
),
),

const SizedBox(
height: 6,
),

Text(
'Keep all your favourite '
'recipes in one place.',
style: TextStyle(
color: colors
    .onSurfaceVariant,
fontSize: 12,
),
),
],
),
),

const SizedBox(
height: 28,
),

// ---------------------------------------------------------------
// PREMIUM SIGN IN CARD
// ---------------------------------------------------------------

Container(
width:
double.infinity,
padding:
const EdgeInsets
    .fromLTRB(
24,
28,
24,
24,
),
decoration:
BoxDecoration(
gradient:
LinearGradient(
begin:
Alignment.topLeft,
end:
Alignment.bottomRight,
colors: [
colors.primary
    .withValues(
alpha: 0.14,
),
colors.primary
    .withValues(
alpha: 0.035,
),
],
),
borderRadius:
BorderRadius.circular(
28,
),
border:
Border.all(
color: colors
    .primary
    .withValues(
alpha: 0.12,
),
),
),
child: Column(
children: [
Container(
width: 82,
height: 82,
decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha: 0.11,
),
shape:
BoxShape.circle,
),
child: Icon(
Icons
    .menu_book_rounded,
color:
colors.primary,
size: 39,
),
),

const SizedBox(
height: 18,
),

const Text(
'Build your cookbook',
textAlign:
TextAlign.center,
style:
TextStyle(
fontSize: 22,
fontWeight:
FontWeight
    .w900,
letterSpacing:
-0.4,
),
),

const SizedBox(
height: 8,
),

Text(
'Save recipes you love and '
'come back to them anytime.',
textAlign:
TextAlign.center,
style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize: 12,
height: 1.5,
),
),

const SizedBox(
height: 22,
),

SizedBox(
width:
double.infinity,
height: 52,
child:
FilledButton.icon(
onPressed:
onSignIn,
icon:
const Icon(
Icons
    .login_rounded,
size: 19,
),
label:
const Text(
'Continue with Google',
style:
TextStyle(
fontWeight:
FontWeight
    .w900,
),
),
style:
FilledButton
    .styleFrom(
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
16,
),
),
),
),
),
],
),
),

const SizedBox(
height: 22,
),

// ---------------------------------------------------------------
// BENEFITS
// ---------------------------------------------------------------

_FeatureRow(
icon:
Icons.bookmark_rounded,
title:
'Save your favourites',
subtitle:
'Never lose a recipe you love.',
colors: colors,
),

_FeatureRow(
icon:
Icons.devices_rounded,
title:
'Access anytime',
subtitle:
'Your cookbook stays with your account.',
colors: colors,
),

_FeatureRow(
icon:
Icons.restaurant_rounded,
title:
'Cook more, search less',
subtitle:
'Everything you love in one place.',
colors: colors,
),
],
),
),
),
);
}
}

// =============================================================================
// FEATURE ROW
// =============================================================================

class _FeatureRow
extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final ColorScheme colors;

const _FeatureRow({
required this.icon,
required this.title,
required this.subtitle,
required this.colors,
});

@override
Widget build(
BuildContext context,
) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 14,
),
child: Row(
children: [
Container(
width: 43,
height: 43,
decoration:
BoxDecoration(
color: colors.primary
    .withValues(
alpha: 0.08,
),
borderRadius:
BorderRadius.circular(
13,
),
),
child: Icon(
icon,
color:
colors.primary,
size: 20,
),
),

const SizedBox(
width: 12,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
title,
style:
const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.w800,
),
),
const SizedBox(
height: 2,
),
Text(
subtitle,
style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize: 10,
),
),
],
),
),
],
),
);
}
}

// =============================================================================
// SIGNED IN
// =============================================================================

class _SignedInCookbook
extends StatelessWidget {
final User user;

final TextEditingController
searchController;

final String query;

final Future<void> Function(
DocumentSnapshot<
Map<String, dynamic>>
document,
) onOpenRecipe;

final Future<void> Function(
DocumentSnapshot<
Map<String, dynamic>>
document,
) onDeleteRecipe;

const _SignedInCookbook({
required this.user,
required this.searchController,
required this.query,
required this.onOpenRecipe,
required this.onDeleteRecipe,
});

@override
Widget build(
BuildContext context,
) {
final theme =
Theme.of(context);

final colors =
theme.colorScheme;

return StreamBuilder<
QuerySnapshot<
Map<String, dynamic>>>(
stream:
FirebaseFirestore
    .instance
    .collection('users')
    .doc(user.uid)
    .collection(
'savedRecipes',
)
    .orderBy(
'savedAt',
descending: true,
)
    .snapshots(),

builder: (
context,
snapshot,
) {
if (snapshot.hasError) {
debugPrint(
'Cookbook error: '
'${snapshot.error}',
);

return _CookbookError(
message:
snapshot.error.toString(),
);
}

if (snapshot.connectionState ==
ConnectionState.waiting) {
return const _CookbookLoading();
}

final documents =
snapshot.data?.docs ??
<DocumentSnapshot<
Map<String, dynamic>>>[];

final filtered =
documents.where(
(document) {
if (query.isEmpty) {
return true;
}

final data =
document.data() ?? {};

final name =
data['name']
    ?.toString()
    .toLowerCase() ??
'';

final description =
data['description']
    ?.toString()
    .toLowerCase() ??
'';

final difficulty =
data['difficulty']
    ?.toString()
    .toLowerCase() ??
'';

return name.contains(
query,
) ||
description.contains(
query,
) ||
difficulty.contains(
query,
);
},
).toList();

return CustomScrollView(
physics:
const BouncingScrollPhysics(),

slivers: [
// =================================================================
// HEADER
// =================================================================

SliverToBoxAdapter(
child: SafeArea(
bottom: false,
child: Padding(
padding:
const EdgeInsets
    .fromLTRB(
20,
18,
20,
0,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
'MY COOKBOOK',
style:
TextStyle(
color:
colors.primary,
fontSize: 10,
fontWeight:
FontWeight
    .w900,
letterSpacing:
1.6,
),
),

const SizedBox(
height: 5,
),

Row(
crossAxisAlignment:
CrossAxisAlignment
    .end,
children: [
Expanded(
child: Text(
'Your saved recipes',
style:
TextStyle(
fontSize: 27,
fontWeight:
FontWeight
    .w900,
letterSpacing:
-0.8,
),
),
),

const SizedBox(
width: 12,
),

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 11,
vertical: 8,
),
decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha: 0.09,
),
borderRadius:
BorderRadius
    .circular(
13,
),
),
child: Row(
mainAxisSize:
MainAxisSize
    .min,
children: [
Icon(
Icons
    .bookmark_rounded,
color:
colors.primary,
size: 15,
),
const SizedBox(
width: 5,
),
Text(
'${documents.length}',
style:
TextStyle(
color:
colors.primary,
fontSize: 11,
fontWeight:
FontWeight
    .w900,
),
),
],
),
),
],
),

const SizedBox(
height: 6,
),

Text(
documents.isEmpty
? 'Start saving recipes you want to cook again.'
    : '${documents.length} saved ${documents.length == 1 ? 'recipe' : 'recipes'} ready for your next meal.',
style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize: 11,
fontWeight:
FontWeight
    .w500,
),
),

const SizedBox(
height: 18,
),

// =======================================================
// SEARCH
// =======================================================

if (documents.isNotEmpty)
Container(
decoration:
BoxDecoration(
color:
colors.surface,
borderRadius:
BorderRadius
    .circular(
17,
),
border:
Border.all(
color: colors
    .outline
    .withValues(
alpha: 0.09,
),
),
boxShadow: [
BoxShadow(
color: Colors
    .black
    .withValues(
alpha: 0.025,
),
blurRadius:
16,
offset:
const Offset(
0,
5,
),
),
],
),
child:
TextField(
controller:
searchController,
textInputAction:
TextInputAction
    .search,
decoration:
InputDecoration(
hintText:
'Search saved recipes...',

prefixIcon:
Icon(
Icons
    .search_rounded,
size: 20,
color:
colors
    .onSurfaceVariant,
),

suffixIcon:
query.isNotEmpty
? IconButton(
onPressed:
searchController
    .clear,
icon:
const Icon(
Icons
    .close_rounded,
size: 18,
),
)
    : null,

filled: true,
fillColor:
Colors
    .transparent,

border:
InputBorder
    .none,

enabledBorder:
InputBorder
    .none,

focusedBorder:
InputBorder
    .none,

contentPadding:
const EdgeInsets
    .symmetric(
vertical: 16,
horizontal: 4,
),
),
),
),
],
),
),
),
),

// =================================================================
// CONTENT
// =================================================================

if (documents.isEmpty)
const SliverPadding(
padding:
EdgeInsets.fromLTRB(
20,
35,
20,
30,
),
sliver:
SliverToBoxAdapter(
child:
_EmptyCookbook(),
),
)
else if (filtered.isEmpty)
const SliverPadding(
padding:
EdgeInsets.fromLTRB(
20,
45,
20,
30,
),
sliver:
SliverToBoxAdapter(
child:
_NoResults(),
),
)
else
SliverPadding(
padding:
const EdgeInsets
    .fromLTRB(
20,
18,
20,
35,
),

sliver:
SliverList.separated(
itemCount:
filtered.length,

separatorBuilder:
(_, __) =>
const SizedBox(
height: 12,
),

itemBuilder:
(context, index) {
final document =
filtered[index];

return _SavedRecipeCard(
document:
document,
onTap: () =>
onOpenRecipe(
document,
),
onDelete: () =>
onDeleteRecipe(
document,
),
);
},
),
),
],
);
},
);
}
}

// =============================================================================
// SAVED RECIPE CARD
// =============================================================================

class _SavedRecipeCard
extends StatelessWidget {
final DocumentSnapshot<
Map<String, dynamic>> document;

final VoidCallback onTap;
final VoidCallback onDelete;

const _SavedRecipeCard({
required this.document,
required this.onTap,
required this.onDelete,
});

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

final data =
document.data() ?? {};

final name =
data['name']
    ?.toString()
    .trim()
    .isNotEmpty ==
true
? data['name']
    .toString()
    .trim()
    : 'Recipe';

final description =
data['description']
    ?.toString()
    .trim() ??
'';

final imageUrl =
data['imageUrl']
    ?.toString()
    .trim() ??
'';

final time =
data['timeMinutes']
    ?.toString()
    .trim() ??
'';

final difficulty =
data['difficulty']
    ?.toString()
    .trim() ??
'';

return Dismissible(
key: ValueKey(
document.id,
),

direction:
DismissDirection
    .endToStart,

confirmDismiss:
(_) async {
onDelete();
return false;
},

background:
Container(
alignment:
Alignment.centerRight,

padding:
const EdgeInsets.only(
right: 24,
),

decoration:
BoxDecoration(
color: const Color(
0xFFB3261E,
),
borderRadius:
BorderRadius.circular(
22,
),
),

child:
const Icon(
Icons
    .delete_outline_rounded,
color:
Colors.white,
size: 24,
),
),

child:
Material(
color:
Colors.transparent,

child:
InkWell(
onTap:
onTap,

borderRadius:
BorderRadius.circular(
22,
),

child:
Container(
height:
124,

decoration:
BoxDecoration(
color:
colors.surface,

borderRadius:
BorderRadius.circular(
22,
),

border:
Border.all(
color: colors
    .outline
    .withValues(
alpha: 0.09,
),
),

boxShadow: [
BoxShadow(
color: Colors
    .black
    .withValues(
alpha: 0.035,
),
blurRadius: 20,
offset:
const Offset(
0,
8,
),
),
],
),

clipBehavior:
Clip.antiAlias,

child:
Row(
children: [
// =============================================================
// IMAGE
// =============================================================

SizedBox(
width: 112,
height: 124,

child:
imageUrl.isEmpty
? _ImageFallback(
colors:
colors,
)
    : Image.network(
imageUrl,
fit:
BoxFit.cover,

loadingBuilder:
(
context,
child,
progress,
) {
if (progress ==
null) {
return child;
}

return _ImageLoading(
colors:
colors,
);
},

errorBuilder:
(
context,
error,
stackTrace,
) {
return _ImageFallback(
colors:
colors,
);
},
),
),

// =============================================================
// CONTENT
// =============================================================

Expanded(
child:
SizedBox(
height:
124,

child:
Padding(
padding:
const EdgeInsets
    .fromLTRB(
13,
11,
10,
11,
),

child:
Column(
mainAxisSize:
MainAxisSize
    .min,

crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
// ===================================================
// TITLE
// ===================================================

Row(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
Expanded(
child:
Text(
name,
maxLines:
2,
overflow:
TextOverflow
    .ellipsis,
style:
const TextStyle(
fontSize:
15,
height:
1.15,
fontWeight:
FontWeight
    .w900,
letterSpacing:
-0.25,
),
),
),

const SizedBox(
width:
5,
),

Container(
width:
32,
height:
32,
decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.08,
),
shape:
BoxShape
    .circle,
),
child:
Icon(
Icons
    .bookmark_rounded,
color:
colors
    .primary,
size:
16,
),
),
],
),

// ===================================================
// DESCRIPTION
// ===================================================

if (description
    .isNotEmpty) ...[
const SizedBox(
height:
4,
),

Text(
description,
maxLines:
2,
overflow:
TextOverflow
    .ellipsis,
style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize:
9.5,
height:
1.25,
fontWeight:
FontWeight
    .w500,
),
),
],

const SizedBox(
height:
8,
),

// ===================================================
// META
// ===================================================

Row(
children: [
if (time
    .isNotEmpty)
_MetaPill(
icon: Icons
    .schedule_rounded,
text:
'$time min',
color:
colors
    .primary,
),

if (time
    .isNotEmpty &&
difficulty
    .isNotEmpty)
const SizedBox(
width:
6,
),

if (difficulty
    .isNotEmpty)
Flexible(
child:
_MetaPill(
icon: Icons
    .bar_chart_rounded,
text:
difficulty,
color:
colors
    .primary,
),
),

const Spacer(),

Icon(
Icons
    .arrow_forward_ios_rounded,
size:
11,
color: colors
    .onSurfaceVariant
    .withValues(
alpha:
0.45,
),
),
],
),
],
),
),
),
),
],
),
),
),
),
);
}
}

// =============================================================================
// META PILL
// =============================================================================

class _MetaPill extends StatelessWidget {
final IconData icon;
final String text;
final Color color;

const _MetaPill({
required this.icon,
required this.text,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
constraints: const BoxConstraints(
minWidth: 0,
maxWidth: 110,
),

padding: const EdgeInsets.symmetric(
horizontal: 7,
vertical: 5,
),

decoration: BoxDecoration(
color: color.withValues(
alpha: 0.08,
),
borderRadius: BorderRadius.circular(
9,
),
),

child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 11,
color: color,
),

const SizedBox(
width: 4,
),

Flexible(
child: Text(
text,
maxLines: 1,
overflow: TextOverflow.ellipsis,
softWrap: false,
style: TextStyle(
color: color,
fontSize: 8.5,
fontWeight: FontWeight.w800,
),
),
),
],
),
);
}
}
// =============================================================================
// IMAGE FALLBACK
// =============================================================================

class _ImageFallback
extends StatelessWidget {
final ColorScheme colors;

const _ImageFallback({
required this.colors,
});

@override
Widget build(
BuildContext context,
) {
return Container(
color: colors.primary
    .withValues(
alpha: 0.08,
),

child:
Center(
child:
Icon(
Icons
    .restaurant_rounded,
color: colors
    .primary
    .withValues(
alpha:
0.55,
),
size:
35,
),
),
);
}
}

// =============================================================================
// IMAGE LOADING
// =============================================================================

class _ImageLoading
extends StatelessWidget {
final ColorScheme colors;

const _ImageLoading({
required this.colors,
});

@override
Widget build(
BuildContext context,
) {
return Container(
color: colors.primary
    .withValues(
alpha: 0.07,
),

child:
Center(
child:
SizedBox(
width:
22,
height:
22,
child:
CircularProgressIndicator(
strokeWidth:
2,
color:
colors.primary,
),
),
),
);
}
}

// =============================================================================
// EMPTY COOKBOOK
// =============================================================================

class _EmptyCookbook
extends StatelessWidget {
const _EmptyCookbook();

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

return Container(
width:
double.infinity,

padding:
const EdgeInsets
    .fromLTRB(
24,
32,
24,
32,
),

decoration:
BoxDecoration(
color:
colors.surface,

borderRadius:
BorderRadius.circular(
25,
),

border:
Border.all(
color: colors
    .outline
    .withValues(
alpha:
0.09,
),
),
),

child:
Column(
children: [
Container(
width:
78,
height:
78,

decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.09,
),
shape:
BoxShape
    .circle,
),

child:
Icon(
Icons
    .menu_book_rounded,
color:
colors
    .primary,
size:
37,
),
),

const SizedBox(
height:
17,
),

const Text(
'Your cookbook is empty',
textAlign:
TextAlign.center,

style:
TextStyle(
fontSize:
19,
fontWeight:
FontWeight
    .w900,
letterSpacing:
-0.3,
),
),

const SizedBox(
height:
7,
),

Text(
'Save recipes you love and '
'they will appear here.',

textAlign:
TextAlign.center,

style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize:
11.5,
height:
1.45,
fontWeight:
FontWeight
    .w500,
),
),
],
),
);
}
}

// =============================================================================
// NO RESULTS
// =============================================================================

class _NoResults
extends StatelessWidget {
const _NoResults();

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

return Column(
children: [
Container(
width:
70,
height:
70,

decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.08,
),
shape:
BoxShape
    .circle,
),

child:
Icon(
Icons
    .search_off_rounded,
color: colors
    .primary
    .withValues(
alpha:
0.65,
),
size:
32,
),
),

const SizedBox(
height:
13,
),

const Text(
'No recipes found',
style:
TextStyle(
fontSize:
17,
fontWeight:
FontWeight
    .w900,
),
),

const SizedBox(
height:
5,
),

Text(
'Try searching with another name or keyword.',
textAlign:
TextAlign.center,
style:
TextStyle(
color:
colors.onSurfaceVariant,
fontSize:
11,
),
),
],
);
}
}

// =============================================================================
// LOADING
// =============================================================================

class _CookbookLoading
extends StatelessWidget {
const _CookbookLoading();

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

return Scaffold(
backgroundColor:
Theme.of(context)
    .scaffoldBackgroundColor,

body:
Center(
child:
Column(
mainAxisSize:
MainAxisSize
    .min,

children: [
Container(
width:
58,
height:
58,

decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.08,
),
shape:
BoxShape
    .circle,
),

child:
Padding(
padding:
const EdgeInsets
    .all(
17,
),
child:
CircularProgressIndicator(
strokeWidth:
2.5,
color:
colors.primary,
),
),
),

const SizedBox(
height:
14,
),

Text(
'Loading your cookbook...',
style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize:
11.5,
fontWeight:
FontWeight
    .w600,
),
),
],
),
),
);
}
}

// =============================================================================
// ERROR
// =============================================================================

class _CookbookError
extends StatelessWidget {
final String message;

const _CookbookError({
required this.message,
});

@override
Widget build(
BuildContext context,
) {
final colors =
Theme.of(context)
    .colorScheme;

return Scaffold(
backgroundColor:
Theme.of(context)
    .scaffoldBackgroundColor,

body:
Center(
child:
Padding(
padding:
const EdgeInsets
    .all(
24,
),

child:
Container(
width:
double.infinity,

padding:
const EdgeInsets
    .fromLTRB(
24,
30,
24,
26,
),

decoration:
BoxDecoration(
color:
colors.surface,

borderRadius:
BorderRadius.circular(
24,
),

border:
Border.all(
color: colors
    .outline
    .withValues(
alpha:
0.09,
),
),
),

child:
Column(
mainAxisSize:
MainAxisSize
    .min,

children: [
Container(
width:
70,
height:
70,

decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.08,
),
shape:
BoxShape
    .circle,
),

child:
Icon(
Icons
    .cloud_off_rounded,
color:
colors.primary,
size:
34,
),
),

const SizedBox(
height:
16,
),

const Text(
'Could not load your cookbook',
textAlign:
TextAlign.center,

style:
TextStyle(
fontSize:
18,
fontWeight:
FontWeight
    .w900,
),
),

const SizedBox(
height:
7,
),

Text(
'Please check your connection '
'and try again.',

textAlign:
TextAlign.center,

style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize:
11.5,
height:
1.45,
),
),

// Keep the actual Firebase
// error available during development.
if (message.isNotEmpty) ...[
const SizedBox(
height:
16,
),

Container(
width:
double.infinity,

padding:
const EdgeInsets
    .all(
11,
),

decoration:
BoxDecoration(
color: colors
    .primary
    .withValues(
alpha:
0.035,
),

borderRadius:
BorderRadius
    .circular(
12,
),
),

child:
Text(
message,
maxLines:
5,
overflow:
TextOverflow
    .ellipsis,

style:
TextStyle(
color: colors
    .onSurfaceVariant,
fontSize:
8.5,
height:
1.35,
),
),
),
],
],
),
),
),
),
);
}
}
