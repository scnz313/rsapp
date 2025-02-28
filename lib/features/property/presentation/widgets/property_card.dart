import 'package:flutter/material.dart';
import '/features/property/data/models/property_model.dart';
import '/features/property/presentation/widgets/favorite_button.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool isGridItem;

  const PropertyCard({
    Key? key,
    required this.property,
    this.onTap,
    this.isGridItem = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('PropertyCard: Building card for property ${property.id}');
    
    if (isGridItem) {
      return _buildGridItem(context);
    }
    return _buildListItem(context);
  }

  Widget _buildGridItem(BuildContext context) {
    final imageUrl = property.images != null && property.images!.isNotEmpty
        ? property.images!.first 
        : 'https://via.placeholder.com/400x300?text=No+Image';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image
                Expanded(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 50)
                    ),
                  ),
                ),
                // Property Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${property.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location ?? 'No Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureItem(Icons.king_bed, '${property.bedrooms}'),
                          _buildFeatureItem(Icons.bathtub, '${property.bathrooms}'),
                          _buildFeatureItem(Icons.square_foot, '${property.area.toInt()}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Fix FavoriteButton instantiation
            Positioned(
              top: 8,
              right: 8,
              child: FavoriteButton(property: property),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    final imageUrl = property.images != null && property.images!.isNotEmpty
        ? property.images!.first 
        : 'https://via.placeholder.com/400x300?text=No+Image';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Property Image
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 40)
                    ),
                  ),
                ),
                // Property Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.location ?? 'No location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${property.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFeatureItem(Icons.king_bed, '${property.bedrooms}'),
                            const SizedBox(width: 16),
                            _buildFeatureItem(Icons.bathtub, '${property.bathrooms}'),
                            const SizedBox(width: 16),
                            _buildFeatureItem(Icons.square_foot, '${property.area.toInt()}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Fix FavoriteButton instantiation
            Positioned(
              top: 8,
              right: 8,
              child: FavoriteButton(property: property),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
