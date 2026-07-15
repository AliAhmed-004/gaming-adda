import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_games.dart';
import '../models/game.dart';
import '../widgets/cartoon_ui/cartoon_assets.dart';
import '../widgets/cartoon_ui/cartoon_banner_title.dart';
import '../widgets/cartoon_ui/cartoon_buttons.dart';
import '../widgets/category_chips.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/game_grid_tile.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  String _selectedCategory = 'All';
  String _query = '';
  var _searchOpen = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Game> get _filteredGames {
    return mockGames.where((game) {
      final matchesCategory =
          _selectedCategory == 'All' || game.category == _selectedCategory;
      final matchesQuery = _query.isEmpty ||
          game.title.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final games = _filteredGames;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE5D4B0),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: FeaturedCarousel(
                    games: featuredGames,
                    height: 168,
                    overlay: _buildBannerBar(),
                  ),
                ),
                if (_searchOpen)
                  SliverToBoxAdapter(child: _buildSearchField()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(40, 0, 40, 12),
                    child: CartoonBannerTitle(
                      title: 'Categories',
                      height: 46,
                      fontSize: 20,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: CategoryChips(
                    categories: mockCategories,
                    selected: _selectedCategory,
                    onSelected: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                    child: CartoonBannerTitle(
                      title: _selectedCategory == 'All'
                          ? 'Popular games'
                          : _selectedCategory,
                      height: 46,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (games.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No games match your filters',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF5C2E0A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: GameIconStrip(
                        games: games,
                        iconSize: 92,
                        height: 136,
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

  Widget _buildBannerBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const Expanded(
            child: CartoonBannerTitle(
              title: 'Gaming Adda',
              height: 54,
              fontSize: 24,
            ),
          ),
          const SizedBox(width: 8),
          CartoonCircleButton(
            icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            label: _searchOpen ? 'Close' : 'Search',
            size: 52,
            showLabel: false,
            asset: CartoonAssets.btnCircleBlue,
            onTap: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _query = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(
              child: Image.asset(
                CartoonAssets.bannerWood,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.fredoka(
                  color: const Color(0xFFFFE566),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: const Color(0xFFFFE566),
                decoration: InputDecoration(
                  hintText: 'Search games…',
                  hintStyle: GoogleFonts.fredoka(
                    color: const Color(0xFFFFE566).withValues(alpha: 0.55),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
