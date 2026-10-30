import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma10CustomersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma10CustomersScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma10CustomersScreen> createState() => _Numma10CustomersScreenState();
}

class _Numma10CustomersScreenState extends ConsumerState<Numma10CustomersScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(nummaCustomersProvider);

    // Compute filter counts
    final totalCount = customers.length;
    final regularCount = customers.where((c) => c.type == CustomerType.regular).length;
    final newCount = customers.where((c) => c.type == CustomerType.newCustomer).length;
    final inactiveCount = customers.where((c) => c.type == CustomerType.inactive).length;

    final filtered = customers.where((c) {
      if (_selectedFilter == 'Regular' && c.type != CustomerType.regular) return false;
      if (_selectedFilter == 'New' && c.type != CustomerType.newCustomer) return false;
      if (_selectedFilter == 'Inactive' && c.type != CustomerType.inactive) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = c.name.toLowerCase().contains(q);
        final matchPhone = c.phone.toLowerCase().contains(q);
        if (!matchName && !matchPhone) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Customers',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: NummaSearchField(
                hintText: 'Search by name, phone number...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filters
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All', 'All ($totalCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Regular', 'Regular ($regularCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('New', 'New ($newCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Inactive', 'Inactive ($inactiveCount)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Customers List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 54, color: NummaColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text(
                            'No customers found',
                            style: TextStyle(color: NummaColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return _buildCustomerCard(customer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NummaColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NummaColors.primaryGreen : NummaColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NummaColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : NummaColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(NummaCustomer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: NummaColors.lightGreen,
                  child: Text(
                    customer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: NummaColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Type Badge
                NummaStatusBadge.customer(customer.type),
                const SizedBox(width: 8),

                const Icon(Icons.chevron_right, size: 20, color: NummaColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
