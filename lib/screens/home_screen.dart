import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/contact_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/search_bar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            await context.read<ContactProvider>().loadContacts(forceSync: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Sticky or Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with App Title and Sync Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CRM Call Sample',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Consumer<ContactProvider>(
                                builder: (context, provider, _) {
                                  return Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${provider.totalCount} Contacts Available',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),

                          // Refresh Contacts Button
                          IconButton(
                            onPressed: () {
                              context.read<ContactProvider>().loadContacts(forceSync: true);
                            },
                            icon: const Icon(
                              Icons.sync_rounded,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                            tooltip: 'Sync Contacts',
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Search Bar
                      CrmSearchBar(
                        onChanged: (query) {
                          context.read<ContactProvider>().setSearchQuery(query);
                        },
                        onClear: () {
                          context.read<ContactProvider>().clearSearch();
                        },
                      ),

                      // In-call / Uploading Banner
                      _buildCallStatusBanner(context),
                    ],
                  ),
                ),
              ),

              // Contact List
              Consumer<ContactProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.contacts.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    );
                  }

                  if (provider.contacts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        isSearching: provider.searchQuery.isNotEmpty,
                        onSync: () => provider.loadContacts(forceSync: true),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final contact = provider.contacts[index];
                          return ContactCard(
                            contact: contact,
                            onCallPressed: () {
                              context.read<CallProvider>().initiateCall(context, contact);
                            },
                          );
                        },
                        childCount: provider.contacts.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallStatusBanner(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        if (!call.isCallInProgress && !call.isUploading && call.status != CallStatus.processingRecording) {
          return const SizedBox.shrink();
        }

        String label = 'Call in progress...';
        IconData icon = Icons.call_in_absense_rounded;
        Color color = AppColors.primaryGreen;

        if (call.status == CallStatus.dialing) {
          label = 'Dialing ${call.activeContact?.displayName ?? "Customer"}...';
          icon = Icons.ring_volume_rounded;
          color = AppColors.warning;
        } else if (call.status == CallStatus.processingRecording) {
          label = 'Processing call recording...';
          icon = Icons.hourglass_top_rounded;
          color = AppColors.info;
        } else if (call.status == CallStatus.uploading) {
          label = 'Uploading recording to Supabase...';
          icon = Icons.cloud_upload_rounded;
          color = AppColors.primaryGreen;
        }

        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (call.isCallInProgress)
                TextButton(
                  onPressed: () => call.completeCallManually(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'End Call',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool isSearching,
    required VoidCallback onSync,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.person_search_rounded : Icons.contacts_outlined,
                size: 48,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'No Matching Contacts' : 'No Contacts Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try searching with a different name or phone number.'
                  : 'Import your device contacts to start dialing customers directly.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Import Contacts'),
              ),
          ],
        ),
      ),
    );
  }
}
