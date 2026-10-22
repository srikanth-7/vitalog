import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../health_presentation.dart';
import 'health_subscreens.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../bloc/health_state.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        if (state is HealthInitial || state is HealthLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (state is HealthLoadFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load family health: ${state.message}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<HealthBloc>().add(LoadHealthData()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        final loaded = state as HealthLoaded;
        if (loaded.data.members.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('No family profiles yet.')));
        }
        final profile = loaded.data.members.firstWhere(
          (member) => member.id == loaded.selectedMemberId,
          orElse: () => loaded.data.members.first,
        );

        void openHistory(LabResult result) {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => TestDetailScreen(
                snapshot: loaded.data, result: result, profile: profile),
          ));
        }

        void openCategory(HealthCategory category) {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CategoryResultsScreen(
              snapshot: loaded.data,
              profile: profile,
              category: category,
              onResultTap: openHistory,
            ),
          ));
        }

        final pages = <Widget>[
          HomeScreen(
            snapshot: loaded.data,
            profile: profile,
            onProfileTap: () =>
                context.read<HealthBloc>().add(SelectNavigationTab(3)),
            onCategoryTap: openCategory,
            onResultTap: openHistory,
            onReportsTap: () =>
                context.read<HealthBloc>().add(SelectNavigationTab(2)),
          ),
          CategoriesScreen(
              snapshot: loaded.data,
              profile: profile,
              onCategoryTap: openCategory),
          ReportsScreen(profile: profile, snapshot: loaded.data),
          ProfileScreen(
            snapshot: loaded.data,
            selectedProfileId: profile.id,
            onSelect: (id) =>
                context.read<HealthBloc>().add(SelectFamilyMember(id)),
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: loaded.selectedTab, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: loaded.selectedTab,
            onDestinationSelected: (index) =>
                context.read<HealthBloc>().add(SelectNavigationTab(index)),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Categories'),
              NavigationDestination(
                  icon: Icon(Icons.folder_open_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: 'Reports'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: 'Family'),
            ],
          ),
        );
      },
    );
  }
}
