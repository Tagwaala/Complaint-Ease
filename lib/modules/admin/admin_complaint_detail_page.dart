import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class AdminComplaintDetailPage extends StatefulWidget {
  final Complaint complaint;

  const AdminComplaintDetailPage({super.key, required this.complaint});

  @override
  State<AdminComplaintDetailPage> createState() =>
      _AdminComplaintDetailPageState();
}

class _AdminComplaintDetailPageState extends State<AdminComplaintDetailPage> {
  final _supabaseService = SupabaseService();
  final _noteController = TextEditingController();
  String _selectedStatus = 'Pending';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _noteController.text = widget.complaint.adminNote ?? '';
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateComplaintStatus(
        widget.complaint.id!,
        _selectedStatus,
        _noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.complaint.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'From: ${widget.complaint.userName ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text('Category: ${widget.complaint.category}'),
            Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.complaint.createdAt)}',
            ),
            if (widget.complaint.imageUrl != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.complaint.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('Error loading image')),
                ),
              ),
            ],
            const Divider(height: 40),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(widget.complaint.description),
            const SizedBox(height: 30),
            const Text(
              'Update Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              items: ['Pending', 'In Progress', 'Resolved'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Admin Note:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Enter internal notes...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateStatus,
                    child: const Text('Save Changes'),
                  ),
          ],
        ),
      ),
    );
  }
}
