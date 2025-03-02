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

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;
  
  const PropertyDetailScreen({Key? key, required this.propertyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
      ),
      body: Center(
        child: Text('Property ID: $propertyId'),
      ),
    );
  }
}
