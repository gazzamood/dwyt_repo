import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../class/Place.dart';

class CarouselPage extends StatefulWidget {
  final List<Place> placesList;
  final Function(int, CarouselPageChangedReason) onPageChanged;
  final int currentIndex;

  const CarouselPage({
    super.key,
    required this.placesList,
    required this.onPageChanged,
    required this.currentIndex,
  });

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CarouselSlider.builder(
          itemCount: widget.placesList.length,
          itemBuilder: (context, index, realIndex) {
            if (index >= 0 && index < widget.placesList.length) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.placesList[index].name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              return const SizedBox(); // Gestisce il caso in cui l'indice non è valido
            }
          },
          options: CarouselOptions(
            height: 100,
            enlargeCenterPage: true,
            autoPlay: false,
            aspectRatio: 16 / 9,
            enableInfiniteScroll: false,
            viewportFraction: 0.85,
            onPageChanged: widget.onPageChanged,
          ),
        ),
      ],
    );
  }
}