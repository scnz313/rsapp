import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../shared/widgets/full_screen_image_gallery.dart';
import '../../../../shared/widgets/image_carousel.dart';
import '../../data/models/property_model.dart';
import '../providers/property_provider.dart';
import '../../../../core/constants/app_colors.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String id;

  const PropertyDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // Add favorite functionality
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        final property = provider.selectedProperty;
        
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (property == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Property Details')),
            body: const Center(
              child: Text('Property not found'),
            ),
          );
        }
        
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageCarousel(context, property),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Implement share functionality
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatPrice(property.price),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightColorScheme.primary,
                            ),
                          ),
                          _buildStatusChip(property.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location ?? 'Location not available',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Property Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(Icons.king_bed, '${property.bedrooms} Beds'),
                          _buildDetailItem(Icons.bathtub, '${property.bathrooms} Baths'),
                          _buildDetailItem(Icons.square_foot, '${property.area} sq ft'),
                          _buildDetailItem(
                            Icons.home_work, 
                            property.type.name.toUpperCase(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(property.description),
                      const SizedBox(height: 24),
                      Text(
                        'Contact Agent',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _contactOwner(property.owner?.email),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightColorScheme.primary,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Contact Owner'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildImageCarousel(BuildContext context, PropertyModel property) {
    if (property.images == null || property.images!.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Text('No Images Available'),
        ),
      );
    }
    
    final imageSliders = property.images?.map((item) {
      return Container(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          child: Image.network(
            item,
            fit: BoxFit.cover,
            width: 1000.0,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }).toList() ?? [];
    
    return CarouselSlider(
      items: imageSliders,
      options: CarouselOptions(
        autoPlay: true,
        aspectRatio: 16 / 9,
        enlargeCenterPage: true,
      ),
    );
  }
  
  Widget _buildLocationMap(BuildContext context, PropertyModel property) {
    final address = property.location ?? 'No Location Data';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 8),
              Expanded(
                child: Text(address),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green;
      case PropertyStatus.sold:
        return Colors.red;
      case PropertyStatus.rented:
        return Colors.blue;
      case PropertyStatus.pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildDetailItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.lightColorScheme.primary),
        const SizedBox(height: 8),
        Text(text),
      ],
    );
  }
  
  Widget _buildStatusChip(PropertyStatus status) {
    Color color;
    String label = status.toString().split('.').last;
    
    switch (status) {
      case PropertyStatus.available:
        color = Colors.green;
        break;
      case PropertyStatus.sold:
        color = Colors.red;
        break;
      case PropertyStatus.rented:
        color = Colors.orange;
        break;
      case PropertyStatus.pending:
        color = Colors.yellow;
        break;
    }
    
    return Chip(
      label: Text(
        label.substring(0, 1).toUpperCase() + label.substring(1),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color.withAlpha(220),
    );
  }
  
  Future<void> _contactOwner(String? ownerEmail) async {
    if (ownerEmail == null || ownerEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner email not available')),
      );
      return;
    }
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: ownerEmail,
      query: 'subject=Regarding your property listing&body=Hello, I am interested in your property.',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _openGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
  
  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    )}';
  }
}
