import 'package:flutter/material.dart';
import 'package:reflexo/features/colors/colors_page.dart';
import 'package:reflexo/features/trails/trails_page.dart';

class CustomizePage extends StatelessWidget {
  const CustomizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Cores'),
                  Tab(text: 'Rastros'),
                ],
              ),
              const Expanded(
                child: TabBarView(children: [ColorsPage(), TrailsPage()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
