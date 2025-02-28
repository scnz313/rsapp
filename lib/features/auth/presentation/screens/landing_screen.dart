import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/constants/app_colors.dart';
import '/core/navigation/route_names.dart';
import '/features/auth/presentation/providers/auth_provider.dart';
import '/features/property/data/models/property_model.dart';
import '/shared/widgets/image_carousel.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Navigate directly to home screen
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroSection(context),
              const SizedBox(height: 30),
              _buildFeaturedPropertiesSection(context),
              const SizedBox(height: 30),
              _buildGetStartedSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    // Use the ColorScheme from your AppColors class
    final theme = Theme.of(context);
    final primaryColor = AppColors.lightColorScheme.primary;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryColor.withAlpha(179)], // Using withAlpha instead of withOpacity
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Find Your Dream Home',
            style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Discover the perfect property that suits your lifestyle and preferences.',
            style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            // Change to navigate directly to home
            onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPropertiesSection(BuildContext context) {
    // Mock properties for carousel - using your property model structure with owner
    final List<PropertyModel> mockProperties = [
      PropertyModel(
        id: '1',
        title: 'Modern Apartment in City Center',
        description: 'Spacious apartment with amazing city views',
        price: 250000,
        location: 'Downtown',
        images: ['https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3'],
        bedrooms: 2,
        bathrooms: 1,
        area: 85,
        owner: PropertyOwner( // Using PropertyOwner instead of ownerId
          uid: 'owner1',
          name: 'John Doe', 
          email: 'john@example.com'
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'Apartment',  // Add these required parameters
        listingType: 'Sale',      // Add these required parameters
      ),
      PropertyModel(
        id: '2',
        title: 'Luxury Villa with Pool',
        description: 'Elegant villa with private garden and pool',
        price: 750000,
        location: 'Suburbs',
        images: ['https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3'],
        bedrooms: 4,
        bathrooms: 3,
        area: 250,
        owner: PropertyOwner( // Using PropertyOwner instead of ownerId
          uid: 'owner2',
          name: 'Jane Smith',
          email: 'jane@example.com'
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: PropertyType.house,  // Changed from villa to house since villa is not in enum
        status: PropertyStatus.available,
        propertyType: 'House',     // Add these required parameters
        listingType: 'Sale',      // Add these required parameters
      ),
      PropertyModel(
        id: '3',
        title: 'Cozy Family Home',
        description: 'Perfect for families with children, near schools',
        price: 320000,
        location: 'Residential Area',
        images: ['https://images.unsplash.com/photo-1513584684374-8bab748fbf90?ixlib=rb-4.0.3'],
        bedrooms: 3,
        bathrooms: 2,
        area: 150,
        owner: PropertyOwner( // Using PropertyOwner instead of ownerId
          uid: 'owner3',
          name: 'Bob Johnson',
          email: 'bob@example.com'
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'House',     // Add these required parameters
        listingType: 'Sale',      // Add these required parameters
      ),
    ];

    // Create list of carousel items for display
    final carouselItems = mockProperties.map((property) => 
      Stack(
        children: [
          Image.network(
            property.images?.first ?? 'https://via.placeholder.com/400x300?text=No+Image', // Add null check with fallback
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withAlpha(150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${property.bedrooms} bed | ${property.bathrooms} bath | \$${property.price}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Featured Properties',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.lightColorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 15),
        // Use the updated ImageCarousel that accepts Widget list
        ImageCarousel(
          items: carouselItems,
          height: 300,
          autoPlay: true,
        ),
      ],
    );
  }

  Widget _buildGetStartedSection(BuildContext context) {
    final primaryColor = AppColors.lightColorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          Text(
            'Ready to find your perfect home?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
