import 'dart:convert';
import 'package:Annujoom/src/data/providers/category_cover_images_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:Annujoom/src/data/constants/color_constants.dart';
import 'package:Annujoom/src/data/constants/style_constants.dart';
import 'package:Annujoom/src/data/constants/global_variables.dart';
import 'package:Annujoom/src/interfaces/components/cards/index.dart';
import 'package:Annujoom/src/data/providers/home_provider.dart';
import 'package:Annujoom/src/data/providers/notifications_provider.dart';
import 'package:Annujoom/src/data/services/secure_storage_service.dart';
import 'package:Annujoom/src/interfaces/components/cards/video_card.dart';
import 'package:Annujoom/src/interfaces/components/loading_indicator.dart';
import 'package:Annujoom/src/interfaces/animations/index.dart';
import 'package:Annujoom/src/interfaces/onboarding/create_user.dart';
import 'package:Annujoom/src/interfaces/main_pages/campaign_pages/category_campaign_detail.dart';
import 'package:Annujoom/src/interfaces/main_pages/news_bookmark/news_page.dart';
import 'package:Annujoom/src/interfaces/main_pages/notifications_page.dart';
import 'package:Annujoom/src/interfaces/main_pages/completed_campaigns_page.dart';
import 'package:Annujoom/src/interfaces/main_pages/videos_page.dart';
import 'package:Annujoom/src/data/router/nav_router.dart';
import 'package:Annujoom/src/data/utils/launch_url.dart';
import 'package:Annujoom/src/data/utils/date_formatter.dart';
import 'package:Annujoom/src/data/services/notification_service/get_fcm.dart';
import 'package:Annujoom/src/interfaces/components/primaryButton.dart';
import 'package:Annujoom/src/interfaces/components/home_quick_access_row.dart';
import 'package:Annujoom/src/interfaces/components/confirmation_dialog.dart';
import 'package:Annujoom/src/data/providers/auth_login_provider.dart';
import 'package:Annujoom/src/data/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late PageController _completedCampaignController;
  late PageController _videoController;
  late CarouselSliderController _categoryCarouselController;
  int _completedCampaignIndex = 0;
  int _videoIndex = 0;
  int _endingCampaignIndex = 0;
  int _categoryIndex = 0;
  bool _imagesPrecached = false;
  final _expandableFabKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    _completedCampaignController =
        PageController(initialPage: _completedCampaignIndex);
    _videoController = PageController(initialPage: _videoIndex);
    _categoryCarouselController = CarouselSliderController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _precacheImages();
      _imagesPrecached = true;
    }
  }

  void _precacheImages() {
    final categoryImages = [
      'assets/jpg/WelcomeBanner.jpeg',
      'assets/png/general_campaign.png',
      'assets/jpg/nofundingcampaigns.jpg'
    ];
    for (var image in categoryImages) {
      precacheImage(AssetImage(image), context);
    }
  }

  void _handleCategoryTap(BuildContext context, String category) {
    print('=== _handleCategoryTap called ===');
    print('Category: $category');

    if (category == 'General Campaign') {
      print('Navigating to Campaign with arguments: {category: $category}');
      Navigator.of(context).pushNamed(
        'Campaign',
        arguments: {'category': category},
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CategoryCampaignDetailPage(category: category),
        ),
      );
    }
  }

  @override
  void dispose() {
    _completedCampaignController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'logout'.tr(),
        message: 'logoutConfirmation'.tr(),
        confirmButtonText: 'logout'.tr(),
        onConfirm: () {
          _performLogout(context, ref);
        },
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      final authLoginApi = ref.read(authLoginApiProvider);
      final authProvider = ref.read(authProviderProvider);

      // Call logout API
      await authLoginApi.logout();

      // Clear local storage regardless of API response
      await authProvider.clearAllData();

      if (context.mounted) {
        // Navigate to Phone screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          'Phone',
          (route) => false,
        );
      }
    } catch (e) {
      // Clear local storage even if API fails
      try {
        final authProvider = ref.read(authProviderProvider);
        await authProvider.clearAllData();
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'logoutFailed'.tr()}: $e')),
        );
        // Still navigate to login even if there was an error
        Navigator.of(context).pushNamedAndRemoveUntil(
          'Phone',
          (route) => false,
        );
      }
    }
  }

  void _showCallSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: kWhite,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'callSupportTeam'.tr(),
                    style: kBodyTitleSB,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'callSupportMessage'.tr(),
                style: kBodyTitleL.copyWith(color: kSecondaryTextColor),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: primaryButton(
                      label: 'cancel'.tr(),
                      onPressed: () => Navigator.pop(context),
                      buttonColor: kWhite,
                      labelColor: kTextColor,
                      sideColor: kStrokeColor,
                      buttonHeight: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: primaryButton(
                      label: 'call'.tr(),
                      onPressed: () {
                        Navigator.pop(context);
                        launchPhone('+918891646431');
                      },
                      buttonColor: kPrimaryColor,
                      labelColor: kWhite,
                      buttonHeight: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan the QR to donate',
                style: kBodyTitleSB,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FutureBuilder<bool>(
                future: ref.read(secureStorageServiceProvider).isDemoAccount(),
                builder: (context, demoSnapshot) {
                  if (demoSnapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: LoadingAnimation(),
                      ),
                    );
                  }

                  if (demoSnapshot.data == true) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Text('QR code not available for demo account'),
                      ),
                    );
                  }

                  return FutureBuilder<String?>(
                    future: ref
                        .read(secureStorageServiceProvider)
                        .getUserData()
                        .then(
                          (userData) => userData?.qrCode,
                        ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: LoadingAnimation(),
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: Text('QR code not available'),
                          ),
                        );
                      }

                      final qrCodeDataUri = snapshot.data!;

                      // Extract base64 data from data URI
                      String base64Data = qrCodeDataUri;
                      if (qrCodeDataUri.contains(',')) {
                        base64Data = qrCodeDataUri.split(',').last;
                      }

                      try {
                        final imageBytes = base64Decode(base64Data);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kStrokeColor,
                              width: 1,
                            ),
                          ),
                          child: Image.memory(
                            imageBytes,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        );
                      } catch (e) {
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: Text('Error loading QR code'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: primaryButton(
                  label: 'close'.tr(),
                  onPressed: () => Navigator.pop(dialogContext),
                  buttonColor: kPrimaryColor,
                  labelColor: kWhite,
                  buttonHeight: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homePageDataProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      body: homeDataAsync.when(
        data: (homeData) =>
            _buildHomeContentWithSliverAppBar(context, ref, homeData),
        loading: () => Center(
          child: LoadingAnimation(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('errorLoadingHomeData'.tr()),
              Text(error.toString()),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(homePageProvider.notifier).refresh();
                },
                child: Text('retry'.tr()),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: Icon(Icons.logout),
                label: Text('logout'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kWhite,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _buildFloatingActionButton(context, ref),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    final userRole = GlobalVariables.getUserRole();
    final isAdmin = userRole != 'member';

    if (isAdmin) {
      return ExpandableFab(
        type: ExpandableFabType.up,
        distance: 70,
        openButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.menu, size: 20),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFED3C5F),
          shape: const CircleBorder(), // 👈 force round
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close, size: 20),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFED3C5F),
          shape: const CircleBorder(), // 👈 force round
        ),
        children: [
          FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(), // 👈 force round
            backgroundColor: const Color(0xFFED3C5F),
            onPressed: () {
              Navigator.of(context).pushNamed('CreateUser');
            },
            child: SvgPicture.asset(
              'assets/svg/add.svg',
              height: 20,
              width: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(), // 👈 force round
            backgroundColor: const Color(0xFFED3C5F),
            onPressed: () {
              Navigator.of(context).pushNamed('DonationCategories');
            },
            child: SvgPicture.asset(
              'assets/svg/donation.svg',
              height: 20,
              width: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: FloatingActionButton(
          heroTag: 'memberDonateButton',
          onPressed: () {
            Navigator.of(context).pushNamed('DonationCategories');
          },
          backgroundColor: const Color(0xFFED3C5F),
          child: SvgPicture.asset(
            'assets/svg/donation.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(kWhite, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContentWithSliverAppBar(
      BuildContext context, WidgetRef ref, HomePageData homeData) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: false,
          toolbarHeight: 60,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          shadowColor: Colors.black.withOpacity(0.08),
          title: SizedBox(
            height: 60,
            width: 100,
            child: Image.asset(
              'assets/png/annujoom_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: false,
          actions: [
            FutureBuilder<bool>(
              future: ref.read(secureStorageServiceProvider).isDemoAccount(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () {
                    _showQRCodeDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/qr.svg',
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () async {
                    final secureStorage =
                        ref.read(secureStorageServiceProvider);
                    final existingFcmToken = await secureStorage.getFcmToken();
                    if (existingFcmToken == null || existingFcmToken.isEmpty) {
                      await getFcmToken(context, ref);
                    }
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    }
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/bell.svg',
                    height: 20,
                    width: 20,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final notificationsAsync = ref.watch(notificationsProvider);
                    return notificationsAsync.when(
                      data: (state) {
                        final unreadCount =
                            state.notifications.where((n) => !n.isRead).length;
                        return unreadCount > 0
                            ? Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: kSmallerTitleR.copyWith(
                                      color: kWhite,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox.shrink();
                      },
                      loading: () => SizedBox.shrink(),
                      error: (_, __) => SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                _showCallSupportModal(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/svg/call.svg',
                    height: 20,
                    width: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _buildHomeContent(context, ref, homeData),
        ),
      ],
    );
  }

  Widget _buildHomeContent(
      BuildContext context, WidgetRef ref, HomePageData homeData) {
    return FutureBuilder<String?>(
      future: ref.read(secureStorageServiceProvider).getUserData().then(
            (userData) => userData?.name,
          ),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? '';

        // Filter endingCampaigns to only show "General Campaign" category
        final generalCampaigns = homeData.endingCampaigns
            .where((campaign) => campaign.category == 'General Campaign')
            .toList();
        final campaignCardHeight =
            HomeGradientCampaignCard.responsiveHeight(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 8, left: 16, right: 16),
              child: AnimatedWidgetWrapper(
                animationType: AnimationType.fadeSlideInFromBottom,
                duration: AnimationDuration.slow,
                curveType: AnimationCurveType.easeOut,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFFCFDBFF), Color(0xFFEFF3FF)],
                        begin: AlignmentGeometry.centerLeft,
                        stops: [.1, .7],
                        end: AlignmentGeometry.centerRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'greeting'.tr()}, $userName!',
                        style: kHeadTitleSB.copyWith(
                            fontSize: 20, color: kThirdTextColor),
                      ),
                      Text(
                        'tagline'.tr(),
                        style: kSmallTitleL.copyWith(color: kThirdTextColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/jpg/WelcomeBanner.jpeg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 0),
              child: Builder(
                builder: (context) {
                  final categoryItems = [
                    {
                      'title': 'generalCampaign'.tr(),
                      'category': 'General Campaign'
                    },
                    {
                      'title': 'generalFunding'.tr(),
                      'category': 'General Funding'
                    },
                    {'title': 'zakat'.tr(), 'category': 'Zakat'},
                    {'title': 'orphan'.tr(), 'category': 'Orphan'},
                    {'title': 'widow'.tr(), 'category': 'Widow'},
                    {'title': 'ghusalMayyit'.tr(), 'category': 'Ghusl Mayyit'},
                    {
                      'title': 'patientRelief'.tr(),
                      'category': 'Patient Relief'
                    },
                    {'title': 'foodKit'.tr(), 'category': 'Food Kit'},
                    {
                      'title': 'sadaqahJariyah'.tr(),
                      'category': 'Sadaqah Jariyah'
                    },
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: CarouselSlider(
                          carouselController: _categoryCarouselController,
                          options: CarouselOptions(
                            height: 120,
                            viewportFraction: 0.25,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                            enableInfiniteScroll: true,
                            initialPage: 0,
                            padEnds: false,
                            onPageChanged: (index, reason) {
                              setState(() => _categoryIndex = index);
                            },
                          ),
                          items: categoryItems.map((category) {
                            final categoryName = category['category'] as String;
                            return AnimatedWidgetWrapper(
                              animationType: AnimationType.fadeScaleUp,
                              duration: AnimationDuration.normal,
                              curveType: AnimationCurveType.easeOut,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: GestureDetector(
                                  onTap: () {
                                    _handleCategoryTap(context, categoryName);
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: _CategoryNetworkImage(
                                            category: categoryName,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          category['title'] as String,
                                          textAlign: TextAlign.center,
                                          style: kSmallTitleR.copyWith(
                                            fontSize: 10,
                                            color: kTextColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: PageViewDotIndicator(
                          size: Size(8, 8),
                          unselectedSize: Size(7, 7),
                          currentItem: _categoryIndex % categoryItems.length,
                          count: categoryItems.length,
                          unselectedColor: Color(0xFFAEB9E1),
                          selectedColor: Color(0xFF0D74BC),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (GlobalVariables.getUserRole() != 'member')
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('MyReferrals');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFCEE8F8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Row(
                      children: [
                        /// 🔹 LEFT : Referrals Received
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                homeData.referralsReceived.toString(),
                                style: kHeadTitleSB.copyWith(
                                  fontSize: 22,
                                  color: kThirdTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'referralsReceived'.tr(),
                                style: kSmallerTitleR,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        /// 🔸 Divider
                        Container(
                          width: 1,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: kThirdTextColor.withOpacity(0.2),
                        ),

                        /// 🔹 RIGHT : Pending Approvals + Review Now
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                homeData.pendingReferrals.toString(),
                                style: kHeadTitleSB.copyWith(
                                  fontSize: 22,
                                  color: kThirdTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    'pendingApprovals'.tr(),
                                    style: kSmallerTitleR,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushNamed('MyReferrals');
                                    },
                                    child: Text(
                                      'reviewNow'.tr(),
                                      style: kSmallerTitleM.copyWith(
                                        color: kThirdTextColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // if (homeData.endingCampaigns.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Expanded(
            //               child: Text(
            //                 'fundingCampaigns'.tr(),
            //                 style: kBodyTitleM,
            //                 softWrap: true,
            //               ),
            //             ),
            //             const SizedBox(width: 8),
            //             GestureDetector(
            //               onTap: () {
            //                 Navigator.of(context).pushNamed(
            //                   'Campaign',
            //                   arguments: {'category': 'All'},
            //                 );
            //               },
            //               child: Text(
            //                 'seeAll'.tr(),
            //                 style:
            //                     kSmallTitleM.copyWith(color: kThirdTextColor),
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         SizedBox(
            //           height: 470,
            //           child: CarouselSlider(
            //             options: CarouselOptions(
            //               height: 470,
            //               viewportFraction: 1,
            //               enableInfiniteScroll: true,
            //               autoPlay: false,
            //               onPageChanged: (index, reason) {
            //                 setState(() => _endingCampaignIndex = index);
            //               },
            //             ),
            //             items: homeData.endingCampaigns.map((campaign) {
            //               final preferredLanguage =
            //                   GlobalVariables.getPreferredLanguage();
            //               return Padding(
            //                 padding: const EdgeInsets.only(bottom: 16),
            //                 child: HomeGradientCampaignCard(
            //                   title: campaign.getTitle(preferredLanguage),
            //                   description:
            //                       campaign.getDescription(preferredLanguage),
            //                   image: campaign.coverImage,
            //                   raised: campaign.collectedAmount.toInt(),
            //                   goal: campaign.targetAmount.toInt(),
            //                   dueDate: formatDate(campaign.targetDate),
            //                   category: campaign.category,
            //                   onViewDetails: () {
            //                     Navigator.of(context).pushNamed(
            //                       'CampaignDetail',
            //                       arguments: {
            //                         '_id': campaign.id ?? '',
            //                         'title':
            //                             campaign.getTitle(preferredLanguage),
            //                         'description': campaign
            //                             .getDescription(preferredLanguage),
            //                         'category': campaign.category,
            //                         'date': formatDate(campaign.targetDate),
            //                         'image': campaign.coverImage,
            //                         'raised': campaign.collectedAmount.toInt(),
            //                         'goal': campaign.targetAmount.toInt(),
            //                       },
            //                     );
            //                   },
            //                   onDonate: () {},
            //                 ),
            //               );
            //             }).toList(),
            //           ),
            //         ),
            //         const SizedBox(height: 14),
            //         Center(
            //           child: PageViewDotIndicator(
            //             size: Size(8, 8),
            //             unselectedSize: Size(7, 7),
            //             currentItem: _endingCampaignIndex,
            //             count: homeData.endingCampaigns.length,
            //             unselectedColor: Color(0xFFAEB9E1),
            //             selectedColor: Color(0xFF0D74BC),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            if (generalCampaigns.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Main card with image background, overlaid content, and bottom text
                    Container(
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Image section with overlay
                          Container(
                            height:
                                GlobalVariables.getPreferredLanguage() == 'ml'
                                    ? 300
                                    : 250,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  // Background image - fills entire container
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/jpg/nofundingcampaigns.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Color(0xFFF5F5F5),
                                          child: Center(
                                            child: Icon(
                                              Icons.favorite,
                                              size: 60,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Right side - Content overlay
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            Color(0xFFF5F5F5),
                                            Color(0xFFF5F5F5).withOpacity(0.95),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'noFundingCampaignsTitle'.tr(),
                                              style: kBodyTitleSB.copyWith(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color: kTextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Text(
                                                'noFundingCampaignsSubtitle'
                                                    .tr(),
                                                style: kSmallTitleR.copyWith(
                                                  fontSize: 12,
                                                  color: kSecondaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              return SizedBox(
                                                width: constraints.maxWidth,
                                                child: primaryButton(
                                                  label: 'donateNow'.tr(),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                            'DonationCategories');
                                                  },
                                                  buttonColor: kPrimaryColor,
                                                  labelColor: kWhite,
                                                  buttonHeight: 44,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Bottom message text - part of the same container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: kWhite,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              'noFundingCampaignsDescription'.tr(),
                              style: kSmallTitleR.copyWith(
                                fontSize: 12,
                                color: kSecondaryTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (generalCampaigns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'fundingCampaigns'.tr(),
                            style: kBodyTitleM,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              'Campaign',
                              arguments: {'category': 'All'},
                            );
                          },
                          child: Text(
                            'seeAll'.tr(),
                            style:
                                kSmallTitleM.copyWith(color: kThirdTextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: campaignCardHeight,
                      child: CarouselSlider(
                        options: CarouselOptions(
                          height: campaignCardHeight,
                          viewportFraction: 1,
                          enableInfiniteScroll: true,
                          autoPlay: false,
                          onPageChanged: (index, reason) {
                            setState(() => _endingCampaignIndex = index);
                          },
                        ),
                        items: generalCampaigns.map((campaign) {
                          final preferredLanguage =
                              GlobalVariables.getPreferredLanguage();
                          return SizedBox.expand(
                            child: HomeGradientCampaignCard(
                              id: campaign.id ?? '',
                              title: campaign.getTitle(preferredLanguage),
                              description:
                                  campaign.getDescription(preferredLanguage),
                              image: campaign.coverImage,
                              raised: campaign.collectedAmount.toInt(),
                              goal: campaign.targetAmount?.toInt(),
                              dueDate: campaign.targetDate != null
                                  ? formatDate(campaign.targetDate)
                                  : '',
                              category: campaign.category,
                              onViewDetails: () {
                                Navigator.of(context).pushNamed(
                                  'CampaignDetail',
                                  arguments: {
                                    '_id': campaign.id ?? '',
                                    'title':
                                        campaign.getTitle(preferredLanguage),
                                    'description': campaign
                                        .getDescription(preferredLanguage),
                                    'category': campaign.category,
                                    'date': campaign.targetDate != null
                                        ? formatDate(campaign.targetDate)
                                        : '',
                                    'image': campaign.coverImage,
                                    'raised': campaign.collectedAmount.toInt(),
                                    'goal': campaign.targetAmount?.toInt(),
                                  },
                                );
                              },
                              onDonate: () {},
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: PageViewDotIndicator(
                        size: Size(8, 8),
                        unselectedSize: Size(7, 7),
                        currentItem: _endingCampaignIndex,
                        count: generalCampaigns.length,
                        unselectedColor: Color(0xFFAEB9E1),
                        selectedColor: Color(0xFF0D74BC),
                      ),
                    ),
                  ],
                ),
              ),
            const HomeQuickAccessRow(),
            if (homeData.posterPromotions.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'completedCampaigns'.tr(),
                          style: kBodyTitleM,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CompletedCampaignsPage(),
                            ),
                          );
                        },
                        child: Text(
                          'seeAll'.tr(),
                          style: kSmallTitleM.copyWith(color: kThirdTextColor),
                        ),
                      ),
                    ],
                  )),
            if (homeData.posterPromotions.isNotEmpty)
              const SizedBox(height: 12),
            if (homeData.posterPromotions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFCEAEA), Color(0xFFFFF9E4)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, top: 16),
                        child: Row(
                          children: [
                            Text('togetherWeDidIt'.tr(), style: kBodyTitleSB),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 280,
                            viewportFraction: 1,
                            enableInfiniteScroll: true,
                            autoPlay: false,
                            onPageChanged: (index, reason) {
                              setState(() => _completedCampaignIndex = index);
                            },
                          ),
                          items: homeData.posterPromotions.map((promotion) {
                            final preferredLanguage =
                                GlobalVariables.getPreferredLanguage();
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: HomeCompletedCampaignCard(
                                targetDate: promotion.endDate,
                                heading: promotion.getTitle(preferredLanguage),
                                subtitle:
                                    promotion.getDescription(preferredLanguage),
                                goal: promotion.targetAmount,
                                collected: promotion.collectedAmount,
                                posterImage: promotion.media ?? '',
                                isImagePoster: true,
                                onTap: () {},
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                        ),
                        child: Center(
                          child: PageViewDotIndicator(
                            size: Size(8, 8),
                            unselectedSize: Size(7, 7),
                            currentItem: _completedCampaignIndex,
                            count: homeData.posterPromotions.length,
                            unselectedColor: Color(0xFFAEB9E1),
                            selectedColor: Color(0xFF0D74BC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (homeData.latestNews.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'latestNews'.tr(),
                            style: kHeadTitleM.copyWith(fontSize: 18),
                            softWrap: true, // allows next line
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(selectedIndexProvider.notifier)
                                .updateIndex(3);
                          },
                          child: Text(
                            'seeAll'.tr(),
                            style:
                                kSmallTitleM.copyWith(color: kThirdTextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            if (homeData.latestNews.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                    height: 208,
                    viewportFraction: 0.55,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 600),
                    autoPlayCurve: Curves.easeInOut,
                    enlargeCenterPage: false,
                    padEnds: false,
                    initialPage: 0,
                    pauseAutoPlayOnTouch: true),
                items: homeData.latestNews.asMap().entries.map((entry) {
                  int index = entry.key;
                  var news = entry.value;
                  final preferredLanguage =
                      GlobalVariables.getPreferredLanguage();
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: HomeNewsCard(
                      title: news.getTitle(preferredLanguage),
                      subtitle: news.getSubtitle(preferredLanguage),
                      image: (news.media != null && news.media!.isNotEmpty)
                          ? news.media!.first
                          : '',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NewsDetailView(
                              news: homeData.latestNews,
                            ),
                          ),
                        );
                        Future.microtask(() {
                          ref.read(currentNewsIndexProvider.notifier).state =
                              index;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            if (homeData.videoPromotions.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'latestVideos'.tr(),
                          style: kBodyTitleM,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const VideosPage(),
                            ),
                          );
                        },
                        child: Text(
                          'seeAll'.tr(),
                          style: kSmallTitleM.copyWith(color: kThirdTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    ],
                  )),
            if (homeData.videoPromotions.isNotEmpty) const SizedBox(height: 12),
            if (homeData.videoPromotions.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView(
                  controller: _videoController,
                  onPageChanged: (page) {
                    setState(() => _videoIndex = page);
                  },
                  children: homeData.videoPromotions.map((video) {
                    final videoId = extractYouTubeVideoId(video.link ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: videoId != null
                          ? YoutubeVideoCard(
                              videoId: videoId,
                            )
                          : Center(
                              child: Text('Something went Wrong'),
                            ),
                    );
                  }).toList(),
                ),
              ),
            if (homeData.videoPromotions.isNotEmpty) const SizedBox(height: 22),
            if (homeData.videoPromotions.isNotEmpty)
              Center(
                child: PageViewDotIndicator(
                  unselectedSize: Size(8, 8),
                  size: Size(9, 9),
                  currentItem: _videoIndex,
                  count: homeData.videoPromotions.length,
                  unselectedColor: Color(0xFFAEB9E1),
                  selectedColor: Color(0xFF0D74BC),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _CategoryNetworkImage extends ConsumerWidget {
  final String category;

  const _CategoryNetworkImage({required this.category});

  Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category == 'General Campaign') {
      return Image.asset(
        'assets/png/general_campaign.png',
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final coversAsync = ref.watch(categoryCoverImagesProvider);

    return coversAsync.when(
      data: (covers) {
        final coverImage = covers[category] ?? '';
        if (coverImage.isEmpty) {
          return _placeholder();
        }

        return CachedNetworkImage(
          imageUrl: coverImage,
          fit: BoxFit.cover,
          width: 70,
          height: 70,
          memCacheWidth: 140,
          memCacheHeight: 140,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => _loadingPlaceholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        );
      },
      loading: () => _loadingPlaceholder(),
      error: (_, __) => _placeholder(),
    );
  }
}
