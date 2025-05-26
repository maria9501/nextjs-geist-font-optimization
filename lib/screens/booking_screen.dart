import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_service.dart';
import '../services/professional_service.dart';
import '../utils/theme.dart';
import '../utils/responsive_builder.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String professionalId;

  const BookingScreen({
    super.key,
    required this.professionalId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedService;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildServiceSelection(Professional professional) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избор на услуга',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(
                labelText: 'Услуга',
                hintText: 'Изберете услуга',
              ),
              items: professional.services.map((service) {
                return DropdownMenuItem(
                  value: service.name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service.name),
                      Text(
                        '${service.price} лв.${service.priceType == 'per_hour' ? '/час' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Моля, изберете услуга';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избор на дата и час',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing_md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Изберете час',
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedTime == null)
              const Padding(
                padding: EdgeInsets.only(top: AppTheme.spacing_sm),
                child: Text(
                  'Моля, изберете час',
                  style: TextStyle(color: AppTheme.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Адрес',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адрес за посещение',
                hintText: 'Въведете пълен адрес',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Моля, въведете адрес';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Допълнителни бележки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Бележки (незадължително)',
                hintText: 'Въведете допълнителна информация',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking(Professional professional) async {
    if (!_formKey.currentState!.validate() || _selectedTime == null) {
      return;
    }

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final service = professional.services
          .firstWhere((service) => service.name == _selectedService);

      await ref.read(bookingServiceProvider).createBooking(
            clientId: 'TODO: Get current user ID',
            professionalId: widget.professionalId,
            serviceType: _selectedService!,
            dateTime: dateTime,
            address: _addressController.text,
            price: service.price,
            notes: _notesController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявката е изпратена успешно!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Резервация'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final professionalAsync =
              ref.watch(professionalProvider(widget.professionalId));

          return professionalAsync.when(
            data: (professional) => Form(
              key: _formKey,
              child: ResponsiveBuilder(
                mobile: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing_md),
                  child: Column(
                    children: [
                      _buildServiceSelection(professional),
                      const SizedBox(height: AppTheme.spacing_md),
                      _buildDateTimeSelection(),
                      const SizedBox(height: AppTheme.spacing_md),
                      _buildAddressInput(),
                      const SizedBox(height: AppTheme.spacing_md),
                      _buildNotesInput(),
                      const SizedBox(height: AppTheme.spacing_lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _submitBooking(professional),
                          child: const Text('Потвърди и изпрати заявка'),
                        ),
                      ),
                    ],
                  ),
                ),
                tablet: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        child: Column(
                          children: [
                            _buildServiceSelection(professional),
                            const SizedBox(height: AppTheme.spacing_md),
                            _buildDateTimeSelection(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        child: Column(
                          children: [
                            _buildAddressInput(),
                            const SizedBox(height: AppTheme.spacing_md),
                            _buildNotesInput(),
                            const SizedBox(height: AppTheme.spacing_lg),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _submitBooking(professional),
                                child: const Text('Потвърди и изпрати заявка'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        child: Column(
                          children: [
                            _buildServiceSelection(professional),
                            const SizedBox(height: AppTheme.spacing_md),
                            _buildDateTimeSelection(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        child: Column(
                          children: [
                            _buildAddressInput(),
                            const SizedBox(height: AppTheme.spacing_md),
                            _buildNotesInput(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing_md),
                        child: Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spacing_md),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Преглед на заявката',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing_lg),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _submitBooking(professional),
                                        child: const Text(
                                          'Потвърди и изпрати заявка',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}
